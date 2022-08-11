event void SpawnLightningEvent(AAsGolem golem, EAsSideOfBoss side);

UCLASS()
class AAsGolem: AAsEnemyBase {
    UPROPERTY(DefaultComponent, Attach = CollisionCylinder)
    USphereComponent Sphere;

    bool IsBossStart;
    EAsSideOfBoss SideOfBoss = EAsSideOfBoss::Middle;

    bool IsActive_AttackDoOnce = false;

    SpawnLightningEvent SpawnLightningEvent;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() override {
        Super::BeginPlay();
        RetryStart();
    }

    UFUNCTION()
    void RetryStart() {
        AAsPlayer player = AsUtil::GetPlayer();
        if(player != nullptr) {
        }
        else {
            System::SetTimer(this, n"RetryStart", 0.2, false);
        }
    }

    void MainLogic() override {
        UpdateSideOfBoss(AsUtil::GetPlayer());
        if(IsBossStart) {
            if(!IsActive_AttackDoOnce) {
                IsActive_AttackDoOnce = true;
                switch(SideOfBoss) {
                    case EAsSideOfBoss::Left: {
                        if(IsRight) {
                            SetActorRotation(FRotator(0, 180, 0));
                            IsRight = false;
                        }
                        UPaperFlipbook animation = Animations[n"RightAttack"];
                        Sprite.SetFlipbook(animation);
                        System::SetTimer(this, n"OnAttackCheckLeft", 2.5, false);
                        System::SetTimer(this, n"OnGolemAttackTimeout", animation.TotalDuration, false);
                        break;
                    }
                    case EAsSideOfBoss::Right: {
                        if(!IsRight) {
                            SetActorRotation(FRotator(0, 0, 0));
                            IsRight = true;
                        }
                        UPaperFlipbook animation = Animations[n"RightAttack"];
                        Sprite.SetFlipbook(animation);
                        System::SetTimer(this, n"OnAttackCheckRight", 2.5, false);
                        System::SetTimer(this, n"OnGolemAttackTimeout", animation.TotalDuration, false);
                        break;
                    }
                    default: {
                        UPaperFlipbook animation = Animations[n"MiddleAttack"];
                        Sprite.SetFlipbook(animation);
                        System::SetTimer(this, n"OnAttackCheckMiddle", 1.0, false);
                        System::SetTimer(this, n"OnGolemAttackTimeout", animation.TotalDuration, false);
                        break;                        
                    }
                }
            }
        }
    }

    UFUNCTION()
    void OnAttackCheckLeft() {
        CostDamage(AsUtil::GetPlayer(), EAsSideOfBoss::Left);
    }

    UFUNCTION()
    void OnAttackCheckRight() {
        CostDamage(AsUtil::GetPlayer(), EAsSideOfBoss::Right);
    }

    UFUNCTION()
    void OnAttackCheckMiddle() {
        CostDamage(AsUtil::GetPlayer(), EAsSideOfBoss::Middle);
    }

    UFUNCTION()
    void OnGolemAttackTimeout() {
        ResetAnim();
    }

    void ResetAnim() {
        IsActive_AttackDoOnce = false;
    }

    void UpdateSideOfBoss(AAsPlayer player) {
        if(System::IsValid(player)) {
            FVector playerLocation = player.GetActorLocation();
            FVector selfLocation = GetActorLocation();
            float width = RootComponent.GetBounds().BoxExtent.X;
            if(playerLocation.X >= selfLocation.X + width / 2) {
                SideOfBoss = EAsSideOfBoss::Right;
            }
            else if(playerLocation.X <= selfLocation.X - width / 2) {
                SideOfBoss = EAsSideOfBoss::Left;
            }
            else {
                SideOfBoss = EAsSideOfBoss::Middle;
            }
        }
    }

    UFUNCTION()
    void CostDamage(AAsPlayer player, EAsSideOfBoss side) {
        SpawnLightningEvent.Broadcast(this, side);
        if(System::IsValid(player)) {
            if(side == SideOfBoss) {
                player.OnHitHandle(3, this, EAsDamageType::Both);
            }
        }
    }
}
