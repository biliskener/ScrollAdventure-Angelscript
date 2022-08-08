UCLASS()
class AAsHUDInGame: AHUD {
    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    TSubclassOf<UAsBattleUI> BattleUIClass;

    UAsBattleUI BattleUI;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        BattleUI = Cast<UAsBattleUI>(WidgetBlueprint::CreateWidget(BattleUIClass, nullptr));
        BattleUI.AddToViewport();
    }
}
