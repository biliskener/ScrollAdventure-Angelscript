UCLASS()
class AAsHudInGame: AHUD {
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TSubclassOf<AAsBattleLayout> mLayoutClass;

    AAsBattleLayout mLayout;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        mLayout = Cast<AAsBattleLayout>(WidgetBlueprint::CreateWidget(mLayoutClass, nullptr));
        mLayout.AddToViewport();
    }
}
