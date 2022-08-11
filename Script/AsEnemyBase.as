UCLASS()
class AAsEnemyBase : AAsCreature {
    UPROPERTY(DefaultComponent, Attach = CollisionCylinder)
    UBoxComponent CollisionBox;

    UPROPERTY(DefaultComponent, Attach = CollisionCylinder)
    UParticleSystemComponent ShieldEffect;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    EAsEnemyType EnemyType = EAsEnemyType::Wolf;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    int MaxHealth = 10;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    int SensingDistance = 800;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    float TurnBackDelayTime = 0.5;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    bool RangedAttack = false;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    float AttackStartDelay = 0.5;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    int AttackDistance = 100;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    int CollisionDamage = 1;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    int Damage = 1;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    EAsDamageType ValidDamageType = EAsDamageType::Both;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    TSubclassOf<AAsWave> RangeWeaponClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    TSubclassOf<AAsWave> PatrolWeaponClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    TSubclassOf<AAsLoot> LootClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Animations")
    TMap<FName, UPaperFlipbook> Animations;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Effects")
    UParticleSystem MeleeShieldParticleSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Effects")
    UParticleSystem RangedShieldParticleSystem;    

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Effects")
    UParticleSystem BeHitParticleSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundBase AttackSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundBase PatrolAttackSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundBase BeHitSound;

    int CurHealth = MaxHealth;
    
    bool IsRight = true;
    bool IsDead = false;
    bool BeHit = false;
    bool IsStopMove = false;
    bool IsAttacking = false;
    bool IsTruningBack = false;
    bool IsPatrolAttacking = false;
    bool IsPatrolAttackCooling = false;
    
    FTimerHandle TurnBackTimerHandle;
    FTimerHandle HurtColorTimerHandle;
    FTimerHandle DeathTimerHandle;
    FTimerHandle AttackDelayTimerHandle;
    FTimerHandle AttackAnimationTimerHandle;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        CurHealth = MaxHealth;
        IsRight = GetActorRotation().Yaw < 180;

        CollisionBox.OnComponentBeginOverlap.AddUFunction(this, n"OnBeginOverlap");
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason) {
        if(System::IsValidTimerHandle(TurnBackTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(TurnBackTimerHandle);
        }
        if(System::IsValidTimerHandle(HurtColorTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(HurtColorTimerHandle);
        }
        if(System::IsValidTimerHandle(DeathTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(DeathTimerHandle);
        }
        if(System::IsValidTimerHandle(AttackDelayTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(AttackDelayTimerHandle);
        }
        if(System::IsValidTimerHandle(AttackAnimationTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(AttackAnimationTimerHandle);
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds) {
        if(!IsDead) {
            if(EnemyType != EAsEnemyType::Golem) {
                if(!BeHit) {
                    if(PawnSensing()) {
                        if(!System::IsValidTimerHandle(AttackDelayTimerHandle)) {
                            AttackDelayTimerHandle = System::SetTimer(this, n"OnAttackDelayTimeout", AttackStartDelay, false);
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
            else {
                MainLogic();
            }
        }
    }

    UFUNCTION()
    void OnBeginOverlap(
        UPrimitiveComponent OverlappedComponent, AActor OtherActor,
        UPrimitiveComponent OtherComponent, int OtherBodyIndex,
        bool bFromSweep, const FHitResult&in Hit)
    {
        AAsPlayer player = Cast<AAsPlayer>(OtherActor);
        if(player != nullptr) {
            player.OnHitHandle(CollisionDamage, this, EAsDamageType::Both);
        }
    }


    void OnHitHandle(int damage, AActor damageCauser, EAsDamageType damageType) override {
        if(!IsDead) {
            FaceToPlayerWhenBeHit();
            if(ValidDamageType == EAsDamageType::Both || ValidDamageType == damageType) {
                BeHit = true;
                CurHealth = Math::Clamp(CurHealth - damage, 0, MaxHealth);
                ParticleSounds(BeHitSound, 0.1, BeHitParticleSystem, FRotator(0, 0, Math::RandRange(-180, 180)), FVector(1.0, 1.0, 1.0));
                if(CurHealth <= 0) {
                    Death();
                }
                else if(damageType == EAsDamageType::Melee) {
                    if(EnemyType != EAsEnemyType::Golem) {
                        FVector attackerPos = damageCauser.GetActorLocation();
                        FVector selfPos = GetActorLocation();
                        FVector direction = selfPos - attackerPos;
                        direction.Normalize(0.0001);
                        LaunchCharacter(FVector(direction.X * 1000, 0, 0), true, true);
                    }
                    else {
                        BossHpCheck();
                    }
                    Sprite.SetSpriteColor(FLinearColor::Red);
                    System::ClearAndInvalidateTimerHandle(HurtColorTimerHandle);
                    HurtColorTimerHandle = System::SetTimer(this, n"OnHurtColorTimeout", 0.2, false);
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
        BeHit = false;
    }

    private void ParticleSounds(USoundBase sound, float32 startTime, UParticleSystem particle, FRotator rotation, FVector scale) {
        if(EnemyType != EAsEnemyType::Golem) {
            Gameplay::SpawnEmitterAtLocation(particle, GetActorLocation(), rotation, scale);
        }
        Gameplay::SpawnSoundAtLocation(sound, GetActorLocation(), StartTime = startTime);
    }

    private void FaceToPlayerWhenBeHit() {
        if(EnemyType != EAsEnemyType::Golem) {
            FVector playerPos = Gameplay::GetPlayerCharacter(0).GetActorLocation();
            FVector selfPos = GetActorLocation();
            if(selfPos.X > playerPos.X) {
                if(IsRight) {
                    this.TurnBackDelayTime = 0.2;
                    TurnBack();
                }
            }
            else if(selfPos.X < playerPos.X) {
                if(!IsRight) {
                    this.TurnBackDelayTime = 0.2;
                    TurnBack();
                }
            }
        }
    }

    private void TurnBack() {
        if(!IsTruningBack) {
            IsTruningBack = true;
            IsStopMove = true;
            if(!IsPatrolAttackCooling) {
                if(!IsPatrolAttacking) {
                    IsPatrolAttacking = true;
                    PatrolAttack();
                }
            }
            TurnBackTimerHandle = System::SetTimer(this, n"OnTurnBackTimeout", TurnBackDelayTime, false);
        }
    }

    UFUNCTION()
    void OnTurnBackTimeout() {
        if(!IsDead) {
            IsStopMove = false;
            IsRight = !IsRight;
            SetActorRotation(FRotator(0.0, IsRight ? 0.0 : 180.0, 0.0));
            if(IsPatrolAttacking) {
                IsPatrolAttacking = false;
                ResetPatrolAttack();
            }
        }
        IsTruningBack = false;
    }

    void Death() {
        IsDead = true;

        AsUtil::GetPlayer().AddKillCount(1);

        ShieldEffect.Deactivate();
        CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Ignore);
        CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);
        CollisionBox.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Ignore);
        CollisionBox.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);
        UPaperFlipbook Animation = Animations[n"Death"];
        Sprite.SetFlipbook(Animation);
        DeathTimerHandle = System::SetTimer(this, n"OnDeathTimeout", Animation.TotalDuration, false);
    }

    UFUNCTION()
    void OnDeathTimeout() {
        Sprite.SetFlipbook(Animations[n"DeathLoop"]);
        ExtraTriggerAfterDeath();
        SetLifeSpan(5.0);
    }

    void ExtraTriggerAfterDeath() {
        if(EnemyType != EAsEnemyType::Golem) {
            if(LootClass != nullptr && Math::RandRange(0.0, 1.0) <= 0.3) {
                SpawnActor(LootClass, GetActorLocation() - FVector(0, 0, CapsuleComponent.GetScaledCapsuleHalfHeight()));
            }
        }
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
        if(!IsStopMove) {
            AddMovementInput(FVector(IsRight ? 1 : -1, 0, 0));
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
        if(System::LineTraceSingleForObjects(GetActorLocation(), GetActorLocation() + FVector(GetActorForwardVector().X * SensingDistance, 0, 0),
            objectTypes, false, TArray<AActor>(), EDrawDebugTrace::None, hitResult, true)) {
            AAsPlayer player = Cast<AAsPlayer>(hitResult.Actor);
            if(player != nullptr) {
                if(!player.IsDead) {
                    if(player.GetDistanceTo(this) <= AttackDistance) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    UFUNCTION()
    void OnAttackDelayTimeout() {
        System::ClearAndInvalidateTimerHandle(AttackDelayTimerHandle);
        DoOnceAttack();
    }

    void DoOnceAttack() {
        if(!IsAttacking) {
            IsStopMove = true;
            IsAttacking = true;

            UPaperFlipbook attackAnimation = Animations[n"Attack"];
            Sprite.SetFlipbook(attackAnimation);
            Gameplay::SpawnSoundAtLocation(AttackSound, GetActorLocation());

            System::SetTimer(this, n"OnAttackCheck", 0.1, false);
            System::SetTimer(this, n"OnAttackAnimationTimeout", attackAnimation.TotalDuration, false);
        }
    }

    UFUNCTION()
    void OnAttackCheck() {
        if(RangedAttack) {
            SpawnActor(RangeWeaponClass, 
            GetActorLocation() + FVector(GetActorForwardVector().X * 100, 0, 0),
            FRotator(0, IsRight ? 0 : 180, 0)
            );
        }
        else {
            TArray<EObjectTypeQuery> objectTypes;
            objectTypes.Add(EObjectTypeQuery::Pawn);
            FHitResult hitResult;
            if(System::LineTraceSingleForObjects(GetActorLocation(), GetActorLocation() + FVector(GetActorForwardVector().X * 100, 0, 0),
                objectTypes, false, TArray<AActor>(), EDrawDebugTrace::None, hitResult, true)) {
                AAsPlayer player = Cast<AAsPlayer>(hitResult.Actor);
                if(player != nullptr) {
                    player.OnHitHandle(Damage, this, EAsDamageType::Melee);
                }
            }
        }
    }

    UFUNCTION()
    void OnAttackAnimationTimeout() {
        IsStopMove = false;
        IsAttacking = false;
        this.ResetAttack();
    }

    void ResetAttack() {
    }

    void PatrolAttack() {
        if(EnemyType == EAsEnemyType::Witch) {
            for(int i = 0; i <= 2; ++i) {
                SpawnActor(PatrolWeaponClass, GetActorLocation(), FRotator(50 + 40 * i, 0, 0));
                Gameplay::SpawnSoundAtLocation(PatrolAttackSound, GetActorLocation(), VolumeMultiplier = 2.0, StartTime = 1.0);
            }
            IsPatrolAttackCooling = true;
            System::SetTimer(this, n"OnPatrolAttackTimeout", 5.0, false);
        }
    }

    UFUNCTION()
    void OnPatrolAttackTimeout() {
        IsPatrolAttackCooling = false;
    }

    void ResetPatrolAttack() {
        if(EnemyType == EAsEnemyType::Witch) {
        }
    }

    void MainLogic() {

    }

    void BossHpCheck() {
    }
}
