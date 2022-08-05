UCLASS()
class AAsEnemyBase : APaperCharacter {
    bool mIsRight = true;
    float mTurnBackDelayTime = 2.0;
    bool mIsDead = false;
    bool mHit = false;
    int mMaxHealth = 10;
    int mHealth = mMaxHealth;
    bool mStopMove = false;

    EAsDamageType mValidDamageType = EAsDamageType::Both;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = BeHit)
    USoundBase BeHitSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = BeHit)
    UParticleSystem BeHitEffect;

    bool mIsTruningBack = false;
    FTimerHandle mTurnBackTimerHandle;
    FTimerHandle mHurtColorTimerHandle;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        mHealth = mMaxHealth;
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason) {
        if(System::IsValidTimerHandle(mTurnBackTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(mTurnBackTimerHandle);
        }
        if(System::IsValidTimerHandle(mHurtColorTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(mHurtColorTimerHandle);
        }
    }

    void OnHitHandle(int damage, AActor damageCauser, EAsDamageType damageType) {
        if(!mIsDead) {
            FaceToPlayerWhenBeHit();
            if(mValidDamageType == EAsDamageType::Both || mValidDamageType == damageType) {
                mHit = true;
                mHealth = Math::Clamp(mHealth - damage, 0, mMaxHealth);
                ParticleSounds(BeHitSound, 0.1, BeHitEffect, FRotator(0, 0, Math::RandRange(-180, 180)), FVector(1.0, 1.0, 1.0));
                if(mHealth <= 0) {
                }
                else if(damageType == EAsDamageType::Melee) {
                    FVector attackerPos = damageCauser.GetActorLocation();
                    FVector selfPos = GetActorLocation();
                    FVector direction = selfPos - attackerPos;
                    direction.Normalize(0.0001);
                    LaunchCharacter(FVector(direction.X * 1000, 0, 0), true, true);
                    Sprite.SetSpriteColor(FLinearColor::Red);
                    System::ClearAndInvalidateTimerHandle(mHurtColorTimerHandle);
                    mHurtColorTimerHandle = System::SetTimer(this, n"OnHurtColorTimeout", 0.2, false);
                }
                else {
                }
            }
        }
    }

    UFUNCTION()
    void OnHurtColorTimeout() {
        Sprite.SetSpriteColor(FLinearColor::White);
        mHit = false;
    }

    private void ParticleSounds(USoundBase sound, float32 startTime, UParticleSystem particle, FRotator rotation, FVector scale) {
        Gameplay::SpawnEmitterAtLocation(particle, GetActorLocation(), rotation, scale);
        Gameplay::SpawnSoundAtLocation(sound, GetActorLocation(), StartTime = startTime);
    }

    private void FaceToPlayerWhenBeHit() {
        if(true) {
            FVector playerPos = Gameplay::GetPlayerCharacter(0).GetActorLocation();
            FVector selfPos = GetActorLocation();
            if(selfPos.X > playerPos.X) {
                if(mIsRight) {
                    this.mTurnBackDelayTime = 0.2;
                    TurnBack();
                }
            }
            else if(selfPos.X < playerPos.X) {
                if(!mIsRight) {
                    this.mTurnBackDelayTime = 0.2;
                    TurnBack();
                }
            }
        }
    }

    private void TurnBack() {
        if(!mIsTruningBack) {
            mIsTruningBack = true;
            mStopMove = true;
            mTurnBackTimerHandle = System::SetTimer(this, n"OnTurnBackTimeout", mTurnBackDelayTime, false);
        }
    }

    UFUNCTION()
    void OnTurnBackTimeout() {
        if(!mIsDead) {
            mStopMove = false;
            mIsRight = !mIsRight;
            SetActorRotation(FRotator(0.0, mIsRight ? 0.0 : 180.0, 0.0));
        }
        mIsTruningBack = false;
    }
}
