UCLASS()
class AAsBattleLayout: UUserWidget {
	UPROPERTY(BindWidget)
    UHorizontalBox HPRow;

	UPROPERTY(BindWidget)
    UHorizontalBox PotionRow;

    UPROPERTY(BindWidget)
    UTextBlock TXT_PotionNum;

    UPROPERTY(BindWidget)
    UTextBlock TXT_KillCount;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    TSubclassOf<AAsHeart> mHeartClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FSlateBrush mFullHeart;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FSlateBrush mHalfHeart;

    UPROPERTY(EditAnywhere, BlueprintReadWrite)
    FSlateBrush mEmptyHeart;

    TArray<UImage> mHeartArray;

    UFUNCTION(BlueprintOverride) 
    void Construct() {
        AAsPlayer player = Cast<AAsPlayer>(Gameplay::GetPlayerCharacter(0));
        HealthInitialize(player);
    }

    void HealthInitialize(AAsPlayer player) {
        for(int i = 0; i < Math::Clamp((player.mMaxHealth + 1) / 2, 0, 999); ++i) {
            AAsHeart heartWidget = Cast<AAsHeart>(WidgetBlueprint::CreateWidget(mHeartClass, nullptr));
            UHorizontalBoxSlot slot = Cast<UHorizontalBoxSlot>(HPRow.AddChild(heartWidget));
            slot.SetPadding(FMargin(0, 0, 20, 0));
            FSlateChildSize size;
            size.Value = 1.0;
            size.SizeRule = ESlateSizeRule::Automatic;
            slot.SetSize(size);
            heartWidget.mHPSprite.SetDesiredSizeOverride(FVector2D(40, 40));

            mHeartArray.AddUnique(heartWidget.mHPSprite);
        }

        UpdateHP(player, player.mCurHealth);
    }

    void UpdateHP(AAsPlayer player, int currentHP) {
        int clampedHp = Math::Clamp(currentHP, 0, player.mMaxHealth);
        for(int i = 0; i < mHeartArray.Num(); ++i) {
            UImage image = mHeartArray[i];
            if(clampedHp <= i * 2) {
                image.SetBrush(mEmptyHeart);                
            }
            else if(clampedHp == i * 2 + 1) {
                image.SetBrush(mHalfHeart);
            }
            else {
                image.SetBrush(mFullHeart);
            }
        }
    }

    void UpdatePotionNum(int CurNum) {
        TXT_PotionNum.SetText(FText::FromString(f"{CurNum: 02d}"));
    }

    void UpdateKillCount(int CurCount) {
        TXT_KillCount.SetText(FText::FromString(f"{CurCount: 02d}"));
    }
}
