UCLASS()
class UAsBattleUI: UUserWidget {
	UPROPERTY(BindWidget)
    UHorizontalBox HealthRow;

	UPROPERTY(BindWidget)
    UHorizontalBox PotionRow;

    UPROPERTY(BindWidget)
    UTextBlock PotionNumTextBlock;

    UPROPERTY(BindWidget)
    UTextBlock KillCountTextBlock;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    TSubclassOf<AAsHeart> HeartClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    FSlateBrush FullHeartImage;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    FSlateBrush HalfHeartImage;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration")
    FSlateBrush EmptyHeartImage;

    TArray<UImage> HeartImageArray;

    UFUNCTION(BlueprintOverride) 
    void Construct() {
        AAsPlayer player = Cast<AAsPlayer>(Gameplay::GetPlayerCharacter(0));
        HealthInitialize(player);
    }

    void HealthInitialize(AAsPlayer player) {
        for(int i = 0; i < Math::Clamp((player.mMaxHealth + 1) / 2, 0, 999); ++i) {
            AAsHeart heartWidget = Cast<AAsHeart>(WidgetBlueprint::CreateWidget(HeartClass, nullptr));
            UHorizontalBoxSlot slot = Cast<UHorizontalBoxSlot>(HealthRow.AddChild(heartWidget));
            slot.SetPadding(FMargin(0, 0, 20, 0));
            FSlateChildSize size;
            size.Value = 1.0;
            size.SizeRule = ESlateSizeRule::Automatic;
            slot.SetSize(size);
            heartWidget.mHPSprite.SetDesiredSizeOverride(FVector2D(40, 40));

            HeartImageArray.AddUnique(heartWidget.mHPSprite);
        }

        UpdateHP(player, player.mCurHealth);
    }

    void UpdateHP(AAsPlayer player, int currentHP) {
        int clampedHp = Math::Clamp(currentHP, 0, player.mMaxHealth);
        for(int i = 0; i < HeartImageArray.Num(); ++i) {
            UImage image = HeartImageArray[i];
            if(clampedHp <= i * 2) {
                image.SetBrush(EmptyHeartImage);                
            }
            else if(clampedHp == i * 2 + 1) {
                image.SetBrush(HalfHeartImage);
            }
            else {
                image.SetBrush(FullHeartImage);
            }
        }
    }

    void UpdatePotionNum(int curNum) {
        PotionNumTextBlock.SetText(FText::FromString(f"{curNum: 02d}"));
    }

    void UpdateKillCount(int curCount) {
        KillCountTextBlock.SetText(FText::FromString(f"{curCount: 02d}"));
    }
}
