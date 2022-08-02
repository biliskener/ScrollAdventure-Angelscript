UCLASS()
class AAsLevel: ALevelScriptActor {
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Actors)
    ACameraActor CameraActor;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Actors)
    APaperSpriteActor BackgroundActor;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Actors)
    APaperTileMapActor TileMapActor;

    UPaperTileMapComponent TileMapComponent;
    UPaperTileLayer TileLayer;

    FVector CameraInitLocation;
    FVector CameraInitOffset;

    AActor GetFirstActorWithTag(FName Tag) {
        TArray<AActor> Actors;
        Gameplay::GetAllActorsOfClassWithTag(AActor::StaticClass(), Tag, Actors);
        return Actors.Num() > 0 ? Actors[0] : nullptr;
    }

    UFUNCTION(BlueprintOverride)
    void BeginPlay()
    {
        TileMapComponent = Cast<UPaperTileMapComponent>(TileMapActor.GetComponentByClass(UPaperTileMapComponent::StaticClass()));
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
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds) {
        FVector PlayerLocation = Gameplay::GetPlayerCharacter(0).GetActorLocation();
        if(PlayerLocation.X > CameraInitLocation.X) {
            CameraActor.SetActorLocation(FVector(PlayerLocation.X, CameraInitLocation.Y, CameraInitLocation.Z));
            FVector BackgroundLocation = BackgroundActor.GetActorLocation();
            BackgroundActor.SetActorLocation(FVector(CameraActor.GetActorLocation().X + CameraInitOffset.X, BackgroundLocation.Y, BackgroundLocation.Z));
        }
    }
}
