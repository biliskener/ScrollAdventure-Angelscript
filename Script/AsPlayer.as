UCLASS()
class AAsPlayer : AAsCreature {
    UPROPERTY(DefaultComponent)
    UInputComponent ScriptInputComponent;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Animations)
    TMap<FName, UPaperFlipbook> Animations;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Sounds)
    USoundCue JumpSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Sounds)
    USoundCue RollingSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Sounds)
    USoundCue GuardSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Sounds)
    USoundCue AttackSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Sounds)
    USoundCue GuardHitSound;

    UPROPERTY(DefaultComponent, Attach = CollisionCylinder, Category = Effects)
    UParticleSystemComponent GuardEffect;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Effects)
    UParticleSystem GuardOverParticleSystem;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Effects)
    TSubclassOf<AAsWave> WaveClass;

    bool bIsRight = true;

    bool bCanJump = false;

    bool mIsDead = false;
    bool mIsGuarding = false;
    bool mIsRolling = false;
    bool bAttacking = false;
    bool mIsHit = false;
    bool bGuardCooling = false;

    bool bSprint = false;

    FTimerHandle GuardPrepareTimerHandle;
    FTimerHandle GuardLoopTimerHandle;
    FTimerHandle GuardCoolDownTimerHandle;
    FTimerHandle AttackTimerHandle;
    FTimerHandle RollTimerHandle;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
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
    }

	UFUNCTION()
	void MoveRight(float32 AxisValue) {
        if(CanMove()) {
            if(!bAttacking) {
                this.AddMovementInput(FVector(1.0, 0.0, 0.0), AxisValue);
                HandleOrientation(AxisValue);
                if(this.mIsRolling) {
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
        if(!bSprint && CanSprint()) {
            bSprint = true;
            CharacterMovement.MaxWalkSpeed = 1000.0;
            //this.Sprite.SetPlayRate(1.5);
        }
    }

    UFUNCTION()
    void OnSprintReleased(FKey Key) {
        if(bSprint/* && CanSprint()*/) {
            bSprint = false;
            CharacterMovement.MaxWalkSpeed = 600.0;
            //this.Sprite.SetPlayRate(1.0);
        }
    }

    UFUNCTION()
    void OnRollPressed(FKey Key) {
        if(CanRoll()) {
            this.mIsRolling = true;
            LaunchCharacter(FVector(bIsRight ? 3000.0: -3000.0, 0.0, 0.0), false, false);
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
        this.mIsRolling = false;
        this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Overlap);
        this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);
    }

    UFUNCTION()
    void OnGuardPressed(FKey Key) {
        if(CanGuard()) {
            Print("OnGuardPressed");
            if(bAttacking) { // 最好是攻击中不能防御
                System::ClearAndInvalidateTimerHandle(AttackTimerHandle);
                bAttacking = false;
            }
            mIsGuarding = true;
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
        if(mIsGuarding) {
            mIsGuarding = false;
            GuardEffect.Deactivate();
            bGuardCooling = true;
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
        bGuardCooling = false;
        Gameplay::SpawnEmitterAtLocation(GuardOverParticleSystem, GetActorLocation(), Scale = FVector(2.0, 2.0, 2.0));
    }

    UFUNCTION()
    void OnAttackPressed(FKey Key) {
        if(CanAttack()) {
            bAttacking = true;
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
            SpawnActor(WaveClass, End, FRotator(bIsRight ? 0: 180, 0, 0));
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
    void OnAttackTimeout() {
        bAttacking = false;
    }

    void HandleOrientation(float32 AxisValue) {
        if(AxisValue > 0.0) {
            bIsRight = true;
            this.Sprite.SetWorldRotation(FRotator(0.0, 0.0, 0.0));
        }
        else if(AxisValue < 0.0) {
            bIsRight = false;
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
        if(AnimationName.IsEqual(n"Run") && bSprint) {
            this.Sprite.SetPlayRate(1.5);
        }
        else {
            this.Sprite.SetPlayRate(1.0);
        }
    }

    bool CanJump() {
        return !CharacterMovement.IsFalling() && !mIsDead && !mIsGuarding && !mIsRolling && !bAttacking && !mIsHit;
    }

    bool CanMove() {
        return !mIsDead && !mIsGuarding && !mIsHit;
    }

    bool CanSprint() {
        return !mIsDead && !mIsGuarding && !mIsRolling && !bAttacking && !mIsHit;
    }
    
    bool CanRoll() {
        return !CharacterMovement.IsFalling() && !mIsDead && !mIsGuarding && !mIsRolling && !bAttacking && !mIsHit;
    }

    bool CanGuard() {
        return !CharacterMovement.IsFalling() && !mIsDead && !bGuardCooling && !mIsRolling && !mIsHit;
    }

    bool CanAttack() {
        return !CharacterMovement.IsFalling() && !mIsDead && !mIsGuarding && !mIsRolling && !bAttacking && !mIsHit;
    }

    void OnHitHandle(int damage, AActor damageCauser, EAsDamageType damageType) override {
        if(!mIsDead) {
            if(!mIsRolling) {
                if(mIsGuarding) {
                    Gameplay::SpawnSoundAtLocation(GuardHitSound, GetActorLocation());
                    KnockBack(damageCauser);
                }
                else {
                    mIsHit = true;
                    // cost hp
                }
            }
        }
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
}

