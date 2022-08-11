UCLASS()
class AAsBattleLevel: ALevelScriptActor {
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    ACameraActor CameraActor;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    APaperSpriteActor BackgroundActor;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    APaperTileMapActor TileMap_FirstLayer;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    APaperTileMapActor TileMap_SecondLayer;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    AAsGolem BossActor;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    ATriggerBox DeathLine;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    ATargetPoint LeftLightningTargetPoint;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    ATargetPoint RightLightningTargetPoint;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    ATargetPoint MiddleLightningTargetPoint;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    ATriggerBox BossStartTriggerBox;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    AAsMovingWall BlockInMovingWall;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    AAsMovingWall BlockOutMovingWall;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    UParticleSystem GolemAttackEffect;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    USoundBase GolemAttackSound;

    UPaperTileMapComponent TileMapComponent;
    UPaperTileLayer TileLayer;

    FVector CameraInitLocation;
    FVector CameraInitOffset;
    FVector BossInitPosition;

    float BossBattleStartBlockDuration = 0;
    bool BossBattleStartBlockActive = false;

    float BossBattleEndBlockDuration = 0;
    bool BossBattleEndBlockActive = false;

    TArray<UParticleSystemComponent> LightningActorList;

    AActor GetFirstActorWithTag(FName Tag) {
        TArray<AActor> Actors;
        Gameplay::GetAllActorsOfClassWithTag(AActor::StaticClass(), Tag, Actors);
        return Actors.Num() > 0 ? Actors[0] : nullptr;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        TileMapComponent = Cast<UPaperTileMapComponent>(TileMap_FirstLayer.GetComponentByClass(UPaperTileMapComponent::StaticClass()));
        TileLayer = TileMapComponent.TileMap.TileLayers[0].Get();

        if(BackgroundActor == nullptr) {
            BackgroundActor = Cast<APaperSpriteActor>(GetFirstActorWithTag(n"T_Background_Sprite"));
        }
        if(CameraActor == nullptr) {
            CameraActor = Cast<ACameraActor>(Gameplay::GetActorOfClass(ACameraActor::StaticClass()));
        }

        CameraInitLocation = CameraActor.GetActorLocation();
        FVector BackgroundLocation = BackgroundActor.GetActorLocation();
        CameraInitOffset = BackgroundLocation - CameraInitLocation;

        BossInitPosition = BossActor.GetActorLocation();

        DeathLine.OnActorBeginOverlap.AddUFunction(this, n"OnDeathLineBeginOverlap");

        BossStartTriggerBox.OnActorBeginOverlap.AddUFunction(this, n"OnBossStartBeginOverlap");

        BossActor.SpawnLightningEvent.AddUFunction(this, n"OnSpawnLightning");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds) {
        FVector PlayerLocation = Gameplay::GetPlayerCharacter(0).GetActorLocation();
        if(PlayerLocation.X < BossInitPosition.X && PlayerLocation.X > CameraInitLocation.X) {
            CameraActor.SetActorLocation(FVector(PlayerLocation.X, CameraInitLocation.Y, CameraInitLocation.Z));
            FVector BackgroundLocation = BackgroundActor.GetActorLocation();
            BackgroundActor.SetActorLocation(FVector(CameraActor.GetActorLocation().X + CameraInitOffset.X, BackgroundLocation.Y, BackgroundLocation.Z));
            FVector SecondLayerLocation = TileMap_SecondLayer.GetActorLocation();
            TileMap_SecondLayer.SetActorLocation(FVector(CameraActor.GetActorLocation().X * 0.5, SecondLayerLocation.Y, SecondLayerLocation.Z));
        }

        if(BossBattleStartBlockActive) {
            BossBattleStartBlockDuration += DeltaSeconds;
            if(BossBattleStartBlockDuration >= 0.5) {
                BossBattleStartBlockDuration = 0.5;
                BossBattleStartBlockActive = false;
            }
            FVector Location = BlockInMovingWall.GetActorLocation();
            Location.Z = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.5), FVector2D(-650, -350), BossBattleStartBlockDuration);
            BlockInMovingWall.SetActorLocation(Location);

            Location = BlockOutMovingWall.GetActorLocation();
            Location.Z = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.5), FVector2D(-650, -350), BossBattleStartBlockDuration);
            BlockOutMovingWall.SetActorLocation(Location);
        }

        if(BossBattleEndBlockActive) {
            BossBattleEndBlockDuration += DeltaSeconds;
            if(BossBattleEndBlockDuration >= 0.5) {
                BossBattleEndBlockDuration = 0.5;
                BossBattleEndBlockActive = false;
            }
            FVector Location = BlockOutMovingWall.GetActorLocation();
            Location.Z = Math::GetMappedRangeValueClamped(FVector2D(0.0, 0.5), FVector2D(-350, -650), BossBattleEndBlockDuration);
            BlockOutMovingWall.SetActorLocation(Location);
        }
    }

    UFUNCTION()
    void OnDeathLineBeginOverlap(AActor OverlappedActor, AActor OtherActor) {
        AAsCreature creature = Cast<AAsCreature>(OtherActor);
        if(creature != nullptr) {
            creature.OnHitHandle(999, this, EAsDamageType::Both);
        }
        else {
            OtherActor.DestroyActor();
        }
    }

    UFUNCTION()
    void OnBossStartBeginOverlap(AActor OverlappedActor, AActor OtherActor) {
        AAsPlayer player = Cast<AAsPlayer>(OtherActor);
        if(player != nullptr && !BossActor.IsBossStart) {
            BossActor.IsBossStart = true;
            BossBattleStartBlockActive = true;
            BossBattleStartBlockDuration = 0;
            OverlappedActor.DestroyActor();
        }
    }

    UFUNCTION()
    void OnSpawnLightning(AAsGolem golem, EAsSideOfBoss side) {
        FVector location = golem.GetActorLocation();
        switch(side) {
            case EAsSideOfBoss::Left:
                location = LeftLightningTargetPoint.GetActorLocation();
                break;
            case EAsSideOfBoss::Right:
                location = RightLightningTargetPoint.GetActorLocation();
                break;
            default:
                location = MiddleLightningTargetPoint.GetActorLocation();
                break;
        }
        Gameplay::SpawnSoundAtLocation(nullptr, location);
        UParticleSystemComponent effect = Gameplay::SpawnEmitterAtLocation(GolemAttackEffect, location, Scale = FVector(5.0, 5.0, 5.0));
        LightningActorList.Add(effect);
        System::SetTimer(this, n"DestroyLightning", 0.2, false);
    }

    UFUNCTION()
    void DestroyLightning() {
        if(LightningActorList.Num() > 0) {
            LightningActorList[0].DestroyComponent(LightningActorList[0].Owner);
            LightningActorList.RemoveAt(0);
        }
    }

    void OnBossDead() {
        BossBattleEndBlockActive = true;
        BossBattleEndBlockDuration = 0;
    }
}
