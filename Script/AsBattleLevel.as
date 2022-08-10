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

    UPaperTileMapComponent TileMapComponent;
    UPaperTileLayer TileLayer;

    FVector CameraInitLocation;
    FVector CameraInitOffset;
    FVector BossInitPosition;

    AActor GetFirstActorWithTag(FName Tag) {
        TArray<AActor> Actors;
        Gameplay::GetAllActorsOfClassWithTag(AActor::StaticClass(), Tag, Actors);
        return Actors.Num() > 0 ? Actors[0] : nullptr;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
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

        DeathLine.OnActorBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
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
    }

    UFUNCTION()
    void OnBeginOverlap(AActor OverlappedActor, AActor OtherActor) {
        AAsCreature creature = Cast<AAsCreature>(OtherActor);
        if(creature != nullptr) {
            creature.OnHitHandle(999, this, EAsDamageType::Both);
        }
        else {
            OtherActor.DestroyActor();
        }
    }
}
