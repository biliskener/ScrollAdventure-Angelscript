UCLASS()
class AAsPlayer : AAsCreature {
    UPROPERTY(DefaultComponent)
    UInputComponent ScriptInputComponent;

    UPROPERTY(DefaultComponent, Attach = CollisionCylinder)
    USphereComponent OptimizationSphere;

    UPROPERTY(DefaultComponent, Attach = CollisionCylinder, Category = Effects)
    UParticleSystemComponent GuardEffect;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    int MaxHealth = 32;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    TSubclassOf<UCameraShakeBase> CameraShakeClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    TSubclassOf<UUserWidget> DefeatWidgetClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Data")
    TSubclassOf<AAsWave> WaveClass;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Animations")
    TMap<FName, UPaperFlipbook> Animations;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundCue JumpSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundCue RollingSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundCue GuardSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundCue AttackSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundCue GuardHitSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundCue HurtSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundBase DeathSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundBase RecoverSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Sounds")
    USoundBase PickUpSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Effects")
    UParticleSystem BeHitParticleSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Effects")
    UParticleSystem GuardOverParticleSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Effects")
    UParticleSystem RecoverParticleSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = "Configuration - Effects")
    UParticleSystem StartParticleSystem;

    int PotionNum = 2;

    int CurHealth = MaxHealth;
    int KillCount;

    bool IsCanJump = false;

    bool IsRight = true;
    bool IsDead = false;
    bool IsRolling = false;
    bool IsAttacking = false;
    bool BeHit = false;
    bool IsGuarding = false;
    bool IsGuardCooling = false;
    bool IsSprint = false;

    FTimerHandle GuardPrepareTimerHandle;
    FTimerHandle GuardLoopTimerHandle;
    FTimerHandle GuardCoolDownTimerHandle;
    FTimerHandle AttackTimerHandle;
    FTimerHandle RollTimerHandle;
    FTimerHandle HurtColorTimerHandle;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        Initialize();
    }

    UFUNCTION(BlueprintOverride)
    void EndPlay(EEndPlayReason EndPlayReason) {
        if(System::IsValidTimerHandle(GuardPrepareTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(GuardPrepareTimerHandle);
        }
        if(System::IsValidTimerHandle(GuardLoopTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(GuardLoopTimerHandle);
        }
        if(System::IsValidTimerHandle(GuardCoolDownTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(GuardCoolDownTimerHandle);
        }
        if(System::IsValidTimerHandle(AttackTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(AttackTimerHandle);
        }
        if(System::IsValidTimerHandle(RollTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(RollTimerHandle);
        }
        if(System::IsValidTimerHandle(HurtColorTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(HurtColorTimerHandle);
        }
    }

    UFUNCTION(BlueprintOverride)
    void Tick(float DeltaSeconds) {
        
    }

    void Initialize() {
        CurHealth = MaxHealth;
        AsUtil::GetBattleUI().UpdateHP(this, CurHealth);
        AsUtil::GetBattleUI().UpdatePotionNum(PotionNum);
        AsUtil::GetBattleUI().UpdateKillCount(KillCount);

        ScriptInputComponent.BindAxis(n"Move", FInputAxisHandlerDynamicSignature(this, n"MoveRight"));
        ScriptInputComponent.BindAction(n"Jump", EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"OnJumpPressed"));
        ScriptInputComponent.BindAction(n"Jump", EInputEvent::IE_Released, FInputActionHandlerDynamicSignature(this, n"OnJumpReleased"));
        ScriptInputComponent.BindAction(n"Sprint", EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"OnSprintPressed"));
        ScriptInputComponent.BindAction(n"Sprint", EInputEvent::IE_Released, FInputActionHandlerDynamicSignature(this, n"OnSprintReleased"));
        ScriptInputComponent.BindAction(n"Roll", EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"OnRollPressed"));
        ScriptInputComponent.BindAction(n"Roll", EInputEvent::IE_Released, FInputActionHandlerDynamicSignature(this, n"OnRollReleased"));
        ScriptInputComponent.BindAction(n"Guard", EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"OnGuardPressed"));
        ScriptInputComponent.BindAction(n"Guard", EInputEvent::IE_Released, FInputActionHandlerDynamicSignature(this, n"OnGuardReleased"));
        ScriptInputComponent.BindAction(n"Attack", EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"OnAttackPressed"));
        ScriptInputComponent.BindAction(n"Attack", EInputEvent::IE_Released, FInputActionHandlerDynamicSignature(this, n"OnAttackReleased"));
        ScriptInputComponent.BindAction(n"Recover", EInputEvent::IE_Pressed, FInputActionHandlerDynamicSignature(this, n"OnRecoverPressed"));
        ScriptInputComponent.BindAction(n"Recover", EInputEvent::IE_Released, FInputActionHandlerDynamicSignature(this, n"OnRecoverReleased"));

        Gameplay::SpawnEmitterAtLocation(StartParticleSystem, GetActorLocation() - FVector(0, 0, CapsuleComponent.GetScaledCapsuleHalfHeight()));
    }

	UFUNCTION()
	void MoveRight(float32 AxisValue) {
        if(CanMove()) {
            if(!IsAttacking) {
                this.AddMovementInput(FVector(1.0, 0.0, 0.0), AxisValue);
                HandleOrientation(AxisValue);
                if(this.IsRolling) {
                    //this.HandleRolling();
                }
                else if(CharacterMovement.IsFalling()) {
                    this.HandleJumpOrFalling();
                }
                else {
                    this.HandleIdleOrRunning(AxisValue);
                }
            }
            else {
                //HandleAttack();
            }
        }
        /*
        if(bSprint && CanSprint()) { // 暂时先这样，没有其它动作时加速动画
            this.Sprite.SetPlayRate(1.5);
        }
        else {
            this.Sprite.SetPlayRate(1.0);
        }
        */
    }

    UFUNCTION()
    void OnJumpPressed(FKey Key) {
        if(CanJump()) {
            this.Jump();
            Gameplay::SpawnSoundAtLocation(JumpSound, GetActorLocation(), StartTime = 0.6, VolumeMultiplier = 2.0);
        }
    }

    UFUNCTION()
    void OnJumpReleased(FKey Key) {
        this.StopJumping();
    }

    UFUNCTION()
    void OnSprintPressed(FKey Key) {
        if(!IsSprint && CanSprint()) {
            IsSprint = true;
            CharacterMovement.MaxWalkSpeed = 1000.0;
            //this.Sprite.SetPlayRate(1.5);
        }
    }

    UFUNCTION()
    void OnSprintReleased(FKey Key) {
        if(IsSprint/* && CanSprint()*/) {
            IsSprint = false;
            CharacterMovement.MaxWalkSpeed = 600.0;
            //this.Sprite.SetPlayRate(1.0);
        }
    }

    UFUNCTION()
    void OnRollPressed(FKey Key) {
        if(CanRoll()) {
            this.IsRolling = true;
            LaunchCharacter(FVector(IsRight ? 3000.0: -3000.0, 0.0, 0.0), false, false);
            this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Ignore);
            this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);
            Gameplay::SpawnSoundAtLocation(RollingSound, GetActorLocation());
            HandleRolling();
            RollTimerHandle = System::SetTimer(this, n"OnRollTimeout", Animations[n"Rolling"].TotalDuration, false);
        }
    }

    UFUNCTION()
    void OnRollReleased(FKey Key) {
    }
    
    UFUNCTION()
    void OnRollTimeout() {
        this.IsRolling = false;
        this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Overlap);
        this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);
    }

    UFUNCTION()
    void OnGuardPressed(FKey Key) {
        if(CanGuard()) {
            Print("OnGuardPressed");
            if(IsAttacking) { // 最好是攻击中不能防御
                System::ClearAndInvalidateTimerHandle(AttackTimerHandle);
                IsAttacking = false;
            }
            IsGuarding = true;
            UPaperFlipbook GuardAnimation = Animations[n"Guard"];
            //Sprite.SetFlipbook(GuardAnimation);
            SetAnimation(n"Guard");
            GuardPrepareTimerHandle = System::SetTimer(this, n"OnGuardPrepareTimeout", GuardAnimation.TotalDuration, false);
        }
    }

    UFUNCTION()
    void OnGuardReleased(FKey Key) {
        Print("OnGuardReleased");
        OnGuardReleasedEx();
    }

    void OnGuardReleasedEx() {
        if(System::IsValidTimerHandle(GuardPrepareTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(GuardPrepareTimerHandle);
        }
        if(System::IsValidTimerHandle(GuardLoopTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(GuardLoopTimerHandle);
        }
        if(IsGuarding) {
            IsGuarding = false;
            GuardEffect.Deactivate();
            IsGuardCooling = true;
            GuardCoolDownTimerHandle = System::SetTimer(this, n"OnGuardCoolDownTimeout", 5.0, false);
        }
    }
    
    UFUNCTION()
    void OnGuardPrepareTimeout() {
        Print("OnGuardPrepareTimeout");
        //Sprite.SetFlipbook(Animations[n"GuardLoop"]);
        SetAnimation(n"GuardLoop");
        GuardEffect.Activate(true);
        Gameplay::SpawnSoundAtLocation(GuardSound, GetActorLocation(), StartTime = 0.1);
        GuardLoopTimerHandle = System::SetTimer(this, n"OnGuardLoopTimeout", 5.0, false);
    }

    UFUNCTION()
    void OnGuardLoopTimeout() {
        Print("OnGuardLoopTimeout");
        OnGuardReleasedEx();
    }

    UFUNCTION()
    void OnGuardCoolDownTimeout() {
        Print("OnGuardCoolDownTimeout");
        IsGuardCooling = false;
        Gameplay::SpawnEmitterAtLocation(GuardOverParticleSystem, GetActorLocation(), Scale = FVector(2.0, 2.0, 2.0));
    }

    UFUNCTION()
    void OnAttackPressed(FKey Key) {
        if(CanAttack()) {
            IsAttacking = true;
            TArray<EObjectTypeQuery> ObjectTypes;
            ObjectTypes.Add(EObjectTypeQuery::Pawn);
            FVector Location = GetActorLocation();
            FVector End(Location.X + Sprite.GetForwardVector().X * 160.0, Location.Y, Location.Z);
            FHitResult HitResult;
            if(System::LineTraceSingleForObjects(Location, End, ObjectTypes, false, TArray<AActor>(), EDrawDebugTrace::None, HitResult, true)) {
                AAsEnemyBase enemy = Cast<AAsEnemyBase>(HitResult.Actor);
                if(enemy != nullptr) {
                    enemy.OnHitHandle(1, this, EAsDamageType::Melee);
                }
            }
            SpawnActor(WaveClass, End, FRotator(IsRight ? 0: 180, 0, 0));
            Gameplay::SpawnSoundAtLocation(AttackSound, GetActorLocation());
            UPaperFlipbook AttackAnimation = Animations[n"Attack"];
            HandleAttack();
            AttackTimerHandle = System::SetTimer(this, n"OnAttackTimeout", AttackAnimation.TotalDuration, false);
        }
    }

    UFUNCTION()
    void OnAttackReleased(FKey Key) {
    }

    UFUNCTION()
    void OnRecoverPressed(FKey Key) {
        if(CanRecover()) {
            UsePotion();
        }
    }

    UFUNCTION()
    void OnRecoverReleased(FKey Key) {
    }

    UFUNCTION()
    void OnAttackTimeout() {
        IsAttacking = false;
    }

    void HandleOrientation(float32 AxisValue) {
        if(AxisValue > 0.0) {
            IsRight = true;
            this.Sprite.SetWorldRotation(FRotator(0.0, 0.0, 0.0));
        }
        else if(AxisValue < 0.0) {
            IsRight = false;
            this.Sprite.SetWorldRotation(FRotator(0.0, 180.0, 0.0));
        }
    }

    void HandleIdleOrRunning(float32 AxisValue) {
        if(AxisValue != 0) {
            //this.Sprite.SetFlipbook(Animations[n"Run"]);
            SetAnimation(n"Run");
        }
        else {
            //this.Sprite.SetFlipbook(Animations[n"Idle"]);
            SetAnimation(n"Idle");
        }
    }

    void HandleJumpOrFalling() {
        if(CharacterMovement.Velocity.Z > 0) {
            //this.Sprite.SetFlipbook(Animations[n"Jump"]);
            SetAnimation(n"Jump");
        }
        else {
            //this.Sprite.SetFlipbook(Animations[n"Falling"]);
            SetAnimation(n"Falling");
        }
    }

    void HandleRolling() {
        //this.Sprite.SetFlipbook(Animations[n"Rolling"]);
        SetAnimation(n"Rolling");
    }

    void HandleAttack() {
        //this.Sprite.SetFlipbook(Animations[n"Attack"]);
        SetAnimation(n"Attack");
    }

    void SetAnimation(FName AnimationName) {
        this.Sprite.SetFlipbook(Animations[AnimationName]);
        if(AnimationName.IsEqual(n"Run") && IsSprint) {
            this.Sprite.SetPlayRate(1.5);
        }
        else {
            this.Sprite.SetPlayRate(1.0);
        }
    }

    bool CanJump() {
        return !CharacterMovement.IsFalling() && !IsDead && !IsGuarding && !IsRolling && !IsAttacking && !BeHit;
    }

    bool CanMove() {
        return !IsDead && !IsGuarding && !BeHit;
    }

    bool CanSprint() {
        return !IsDead && !IsGuarding && !IsRolling && !IsAttacking && !BeHit;
    }
    
    bool CanRoll() {
        return !CharacterMovement.IsFalling() && !IsDead && !IsGuarding && !IsRolling && !IsAttacking && !BeHit;
    }

    bool CanGuard() {
        return !CharacterMovement.IsFalling() && !IsDead && !IsGuardCooling && !IsRolling && !BeHit;
    }

    bool CanAttack() {
        return !CharacterMovement.IsFalling() && !IsDead && !IsGuarding && !IsRolling && !IsAttacking && !BeHit;
    }

    bool CanRecover() {
        return !CharacterMovement.IsFalling() && !IsDead && !IsGuarding && !IsRolling && !IsAttacking && !BeHit && PotionNum > 0 && CurHealth < MaxHealth;
    }

    void OnHitHandle(int damage, AActor damageCauser, EAsDamageType damageType) override {
        if(!IsDead) {
            if(!IsRolling) {
                if(IsGuarding) {
                    Gameplay::SpawnSoundAtLocation(GuardHitSound, GetActorLocation());
                    KnockBack(damageCauser);
                }
                else {
                    BeHit = true;
                    CostHealth(damage, damageCauser);
                    Sprite.SetSpriteColor(FLinearColor::Red);
                    System::ClearAndInvalidateTimerHandle(HurtColorTimerHandle);
                    HurtColorTimerHandle = System::SetTimer(this, n"OnHurtColorTimeout", 0.2, false);
                }
            }
        }
    }

    UFUNCTION()
    void OnHurtColorTimeout() {
        Sprite.SetSpriteColor(FLinearColor::White);
        BeHit = false;
    }

    void KnockBack(AActor damageCauser) {
        if(System::IsValid(damageCauser)) {
            FVector direction;
            float length = 0;
            (GetActorLocation() - damageCauser.GetActorLocation()).ToDirectionAndLength(direction, length);
            direction.Normalize(0.0001);
            LaunchCharacter(FVector(direction.X * 1000, 0, 0), false, false);
        }
    }

    void CostHealth(int damage, AActor damageCauser) {
        CurHealth = Math::Clamp(CurHealth - damage, 0, MaxHealth);
        AsUtil::GetBattleUI().UpdateHP(this, CurHealth);
        if(damage > 0) {
            Gameplay::SpawnEmitterAtLocation(BeHitParticleSystem, GetActorLocation(), FRotator(Math::RandRange(-180.0, 180.0), 0, 0));
            Gameplay::SpawnSoundAtLocation(HurtSound, GetActorLocation());
        }
        if(CurHealth > 0) {
            Gameplay::GetPlayerCameraManager(0).StartCameraShake(CameraShakeClass);
            KnockBack(damageCauser);
        }
        else {
            Death();
        }
    }

    void Death() {
        IsDead = true;
        Gameplay::SpawnSoundAtLocation(DeathSound, GetActorLocation(), VolumeMultiplier = 3.0, StartTime = 0.5);
        this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Ignore);
        this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);
        SetAnimation(n"Death");
        System::SetTimer(this, n"OnDeathTimeout", Animations[n"Death"].TotalDuration, false);
    }

    UFUNCTION()
    void OnDeathTimeout() {
        SetAnimation(n"DeathLoop");
        UUserWidget defeatWidget = WidgetBlueprint::CreateWidget(DefeatWidgetClass, nullptr);
        defeatWidget.AddToViewport();
        System::SetTimer(this, n"OnRestartLevel", 2.5, false);
    }

    UFUNCTION()
    void OnRestartLevel() {
        Gameplay::OpenLevel(n"CombatStage");
    }

    void PickUpHeart() {
        CostHealth(-2, this);
        Gameplay::SpawnSoundAtLocation(RecoverSound, GetActorLocation(), VolumeMultiplier = 1.5, StartTime = 0.7);
        Gameplay::SpawnEmitterAtLocation(RecoverParticleSystem, GetActorLocation() - FVector(0, 0, CapsuleComponent.GetScaledCapsuleHalfHeight()));
    }

    void UsePotion() {
        PotionNum -= 1;
        AsUtil::GetBattleUI().UpdatePotionNum(PotionNum);
        CostHealth(-2, this);
        Gameplay::SpawnSoundAtLocation(RecoverSound, GetActorLocation(), VolumeMultiplier = 1.5, StartTime = 0.7);
        Gameplay::SpawnEmitterAtLocation(RecoverParticleSystem, GetActorLocation() - FVector(0, 0, CapsuleComponent.GetScaledCapsuleHalfHeight()));
    }

    void PickUpPotion() {
        PotionNum += 1;
        AsUtil::GetBattleUI().UpdatePotionNum(PotionNum);
        Gameplay::SpawnSoundAtLocation(PickUpSound, GetActorLocation(), VolumeMultiplier = 0.8);
    }

    void AddKillCount(int AddCount) {
        KillCount += AddCount;
        AsUtil::GetBattleUI().UpdateKillCount(KillCount);
    }
}

