UCLASS()
class AAsMovingWall: AActor {
    UPROPERTY(DefaultComponent, RootComponent)
    USceneComponent RootSceneComponent;

    UPROPERTY(DefaultComponent, Attach = RootSceneComponent)
    UPaperSpriteComponent PaperSprite;

    UPROPERTY(DefaultComponent, Attach = RootSceneComponent)
    UBoxComponent Box;
}
