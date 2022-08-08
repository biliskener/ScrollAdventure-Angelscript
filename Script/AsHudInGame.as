UCLASS()
class AAsHudInGame: AHUD {
    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TSubclassOf<UAsBattleUI> mLayoutClass;

    UAsBattleUI mLayout;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        mLayout = Cast<UAsBattleUI>(WidgetBlueprint::CreateWidget(mLayoutClass, nullptr));
        mLayout.AddToViewport();
    }
}
