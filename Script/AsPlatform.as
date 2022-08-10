UCLASS()
class AAsPlatform: AActor {
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent RootSceneComponent;

    UPROPERTY(DefaultComponent, Attach = RootSceneComponent)
    UPaperSpriteComponent PaperSprite;

    UPROPERTY(DefaultComponent, Attach = RootSceneComponent)
    UBoxComponent Box;

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds) {
        FVector location = GetActorLocation();
        SetActorLocation(FVector(location.X, location.Y, location.Z + Math::Sin(System::GetGameTimeInSeconds()) * 3.5));
    }
}
