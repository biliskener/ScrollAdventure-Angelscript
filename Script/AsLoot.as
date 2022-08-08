UCLASS()
class AAsLoot: AActor {
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent RootSceneComponent;

    UPROPERTY(DefaultComponent, Attach = RootSceneComponent)
    USphereComponent Sphere;

    UPROPERTY(DefaultComponent, Attach = RootSceneComponent)
    UPaperSpriteComponent PaperSprite;
    default PaperSprite.SetRelativeScale3D(FVector(2.0, 2.0, 2.0));
    default PaperSprite.SetRelativeLocation(FVector(0, 0, 10));

    UPROPERTY(DefaultComponent, Attach = RootSceneComponent)
    UParticleSystemComponent ParticleSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    UPaperSprite HeartSprite;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    UPaperSprite PotionSprite;

    bool IsHeart = false;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        IsHeart = Math::RandBool();
        if(IsHeart) {
            PaperSprite.SetSprite(HeartSprite);
            PaperSprite.SetRelativeScale3D(FVector(2.0, 2.0, 2.0));
        }
        else {
            PaperSprite.SetSprite(PotionSprite);
            PaperSprite.SetRelativeScale3D(FVector(0.2, 0.2, 0.2));
        }

        Sphere.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
    }


    UFUNCTION()
    void OnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
        AAsPlayer player = Cast<AAsPlayer>(OtherActor);
        if(player != nullptr) {
            if(IsHeart) {
                player.PickUpHeart();
            }
            else {
                player.PickUpPotion();
            }
            DestroyActor();
        }
    }
}
