UCLASS()
class AAsEnemyBase : AAsCreature {
    bool mIsRight = true;
    float mTurnBackDelayTime = 0.5;
    bool mIsDead = false;
    bool mBeHit = false;
    int mMaxHealth = 10;
    int mHealth = mMaxHealth;
    bool mStopMove = false;
    bool mAttacking = false;
    bool mRangedAttack = false;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Config)
    float mAttackStartDelay = 0.5;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Config)
    int mPawSensingDistance = 800;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Config)
    int mAttackDistance = 100;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Config)
    EAsDamageType mValidDamageType = EAsDamageType::Both;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Animations)
    TMap<FName, UPaperFlipbook> Animations;

    UPROPERTY(DefaultComponent, Attach = CollisionCylinder, Category = Shields)
    UParticleSystemComponent ShieldEffect;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Shields)
    UParticleSystem MeleeShieldParticleSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Shields)
    UParticleSystem RangedShieldParticleSystem;    

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = BeHit)
    USoundBase BeHitSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = BeHit)
    UParticleSystem BeHitEffect;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Attack)
    USoundBase mAttackSound;

    bool mIsTruningBack = false;
    FTimerHandle mTurnBackTimerHandle;
    FTimerHandle mHurtColorTimerHandle;
    FTimerHandle mDeathTimerHandle;
    FTimerHandle mAttackDelayTimerHandle;
    FTimerHandle mAttackAnimationTimerHandle;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        mHealth = mMaxHealth;
        mIsRight = GetActorRotation().Yaw < 180;
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason) {
        if(System::IsValidTimerHandle(mTurnBackTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(mTurnBackTimerHandle);
        }
        if(System::IsValidTimerHandle(mHurtColorTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(mHurtColorTimerHandle);
        }
        if(System::IsValidTimerHandle(mDeathTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(mDeathTimerHandle);
        }
        if(System::IsValidTimerHandle(mAttackDelayTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(mAttackDelayTimerHandle);
        }
        if(System::IsValidTimerHandle(mAttackAnimationTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(mAttackAnimationTimerHandle);
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds) {
        if(!mIsDead) {
            if(!mBeHit) {
                if(PawnSensing()) {
                    if(!System::IsValidTimerHandle(mAttackDelayTimerHandle)) {
                        mAttackDelayTimerHandle = System::SetTimer(this, n"OnAttackDelayTimeout", mAttackStartDelay, false);
                    }
                }
                else {
                    HandleMovement();
                    ObstacleDetection();
                    CliffDetection();
                }
            }
            else {
            }
        }
    }

    void OnHitHandle(int damage, AActor damageCauser, EAsDamageType damageType) override {
        if(!mIsDead) {
            FaceToPlayerWhenBeHit();
            if(mValidDamageType == EAsDamageType::Both || mValidDamageType == damageType) {
                mBeHit = true;
                mHealth = Math::Clamp(mHealth - damage, 0, mMaxHealth);
                ParticleSounds(BeHitSound, 0.1, BeHitEffect, FRotator(0, 0, Math::RandRange(-180, 180)), FVector(1.0, 1.0, 1.0));
                if(mHealth <= 0) {
                    Death();
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
            else if(damageType == EAsDamageType::Melee) {
                ShieldEffect.SetTemplate(MeleeShieldParticleSystem);
            }
            else if(damageType == EAsDamageType::Ranged) {
                ShieldEffect.SetTemplate(RangedShieldParticleSystem);
            }
            //mIsRight = GetActorRotation().Yaw < 180;
        }
    }

    UFUNCTION()
    void OnHurtColorTimeout() {
        Sprite.SetSpriteColor(FLinearColor::White);
        mBeHit = false;
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

    void Death() {
        mIsDead = true;
        ShieldEffect.Deactivate();
        CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Ignore);
        CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);
        UPaperFlipbook Animation = Animations[n"Death"];
        Sprite.SetFlipbook(Animation);
        mDeathTimerHandle = System::SetTimer(this, n"OnDeathTimeout", Animation.TotalDuration, false);
    }

    UFUNCTION()
    void OnDeathTimeout() {
        Sprite.SetFlipbook(Animations[n"DeathLoop"]);
        ExtraTriggerAfterDeath();
    }

    void ExtraTriggerAfterDeath() {

    }

    void HandleMovement() {
        FVector direction;
        float length = 0;
        CharacterMovement.Velocity.ToDirectionAndLength(direction, length);
        if(length > 0) {
            Sprite.SetFlipbook(Animations[n"Run"]);
        }
        else {
            Sprite.SetFlipbook(Animations[n"Idle"]);
        }
        if(!mStopMove) {
            AddMovementInput(FVector(mIsRight ? 1 : -1, 0, 0));
        }
    }

    void ObstacleDetection() {
        FHitResult hitResult;
        if(System::LineTraceSingle(GetActorLocation(), GetActorLocation() + FVector(GetActorForwardVector().X * 80, 0, 0),
            ETraceTypeQuery::Visibility, false, TArray<AActor>(), EDrawDebugTrace::None, hitResult, true)) {
            TurnBack();
        }
    }

    void CliffDetection() {
        FHitResult hitResult;
        if(!System::LineTraceSingle(GetActorLocation(), GetActorLocation() + FVector(GetActorForwardVector().X * 80, 0, -100),
            ETraceTypeQuery::Visibility, false, TArray<AActor>(), EDrawDebugTrace::None, hitResult, true)) {
            TurnBack();
        }
    }
    
    bool PawnSensing() {
        TArray<EObjectTypeQuery> objectTypes;
        objectTypes.Add(EObjectTypeQuery::Pawn);
        FHitResult hitResult;
        if(System::LineTraceSingleForObjects(GetActorLocation(), GetActorLocation() + FVector(GetActorForwardVector().X * mPawSensingDistance, 0, 0),
            objectTypes, false, TArray<AActor>(), EDrawDebugTrace::None, hitResult, true)) {
            AAsPlayer player = Cast<AAsPlayer>(hitResult.Actor);
            if(player != nullptr) {
                if(!player.mIsDead) {
                    if(player.GetDistanceTo(this) <= mAttackDistance) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    UFUNCTION()
    void OnAttackDelayTimeout() {
        System::ClearAndInvalidateTimerHandle(mAttackDelayTimerHandle);
        DoOnceAttack();
    }

    void DoOnceAttack() {
        if(!mAttacking) {
            mStopMove = true;
            mAttacking = true;

            UPaperFlipbook attackAnimation = Animations[n"Attack"];
            Sprite.SetFlipbook(attackAnimation);
            Gameplay::SpawnSoundAtLocation(mAttackSound, GetActorLocation());

            System::SetTimer(this, n"OnAttackCheck", mAttackDistance, false);
            System::SetTimer(this, n"OnAttackAnimationTimeout", attackAnimation.TotalDuration, false);
        }
    }

    UFUNCTION()
    void OnAttackCheck() {
        if(mRangedAttack) {
        }
        else {
            TArray<EObjectTypeQuery> objectTypes;
            objectTypes.Add(EObjectTypeQuery::Pawn);
            FHitResult hitResult;
            if(System::LineTraceSingleForObjects(GetActorLocation(), GetActorLocation() + FVector(GetActorForwardVector().X * 100, 0, 0),
                objectTypes, false, TArray<AActor>(), EDrawDebugTrace::None, hitResult, true)) {
                AAsPlayer player = Cast<AAsPlayer>(hitResult.Actor);
                if(player != nullptr) {
                    player.OnHitHandle(1, this, EAsDamageType::Melee);
                }
            }
        }
    }

    UFUNCTION()
    void OnAttackAnimationTimeout() {
        mStopMove = false;
        mAttacking = false;
        this.ResetAttack();
    }

    void ResetAttack() {
    }
}
