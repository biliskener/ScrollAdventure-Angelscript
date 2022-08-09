UCLASS()
class AAsWave: AActor {
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent RootSceneComponent;

    UPROPERTY(DefaultComponent, Attach = RootSceneComponent)
    UBoxComponent Box;
    
    UPROPERTY(DefaultComponent, Attach = RootSceneComponent)
    UPaperSpriteComponent PaperSprite;    

    UPROPERTY(DefaultComponent)
    UProjectileMovementComponent ProjectileMovement;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    EAsWeaponType WeaponType = EAsWeaponType::Wave;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    USoundCue HitWallSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    UParticleSystem HitWallEffect;

    float Duration = 0;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        Box.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds) {
        Duration += DeltaSeconds;
        if(WeaponType == EAsWeaponType::Wave) {
            float Scale = Math::Lerp(5, 1, Math::Min(1.0, Duration / 0.5));
            this.RootSceneComponent.RelativeScale3D = FVector(Scale, Scale, Scale);
            if(Duration >= 0.5) {
                DestroyActor();
            }
        }
        else if(WeaponType == EAsWeaponType::WitchWeapon) {
            float Scale = Math::Lerp(1, 2, Math::Min(1.0, Duration / 1.0));
            this.RootSceneComponent.RelativeScale3D = FVector(Scale, Scale, Scale);
            this.RootSceneComponent.AddLocalRotation(FRotator(900.0 * DeltaSeconds, 0, 0)); 
        }
        else if(WeaponType == EAsWeaponType::WitchPatrolWeapon) {
            float Scale = Math::Lerp(1, 3, Math::Min(1.0, Duration / 10.0));
            this.RootSceneComponent.RelativeScale3D = FVector(Scale, Scale, Scale);
        }
    }

    UFUNCTION()
    void OnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
        if(WeaponType == EAsWeaponType::Wave) {
            AAsEnemyBase enemy = Cast<AAsEnemyBase>(OtherActor);
            if(enemy != nullptr) {
                Gameplay::SpawnEmitterAtLocation(HitWallEffect, GetActorLocation(), Scale = FVector(2.0, 2.0, 2.0));
                enemy.OnHitHandle(1, this, EAsDamageType::Ranged);
                DestroyActor();
                return;
            }
        }
        else {
            AAsPlayer player = Cast<AAsPlayer>(OtherActor);
            if(player != nullptr) {
                Gameplay::SpawnEmitterAtLocation(HitWallEffect, GetActorLocation(), Scale = FVector(2.0, 2.0, 2.0));
                player.OnHitHandle(1, this, EAsDamageType::Ranged);
                DestroyActor();
                return;
            }
        }

        if(WeaponType != EAsWeaponType::WitchPatrolWeapon) {
            APaperTileMapActor tileMapActor = Cast<APaperTileMapActor>(OtherActor);
            if(tileMapActor != nullptr) {
                Gameplay::SpawnSoundAtLocation(HitWallSound, GetActorLocation());
                Gameplay::SpawnEmitterAtLocation(HitWallEffect, GetActorLocation(), Scale = FVector(2.0, 2.0, 2.0));
                DestroyActor();
                return;
            }
        }
    }
}
