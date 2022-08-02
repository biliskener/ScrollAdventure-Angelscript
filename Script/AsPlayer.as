UCLASS()
class AAsPlayer : APaperCharacter {
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

    UPROPERTY(DefaultComponent, Attach = CollisionCylinder, Category = Effects)
    UParticleSystemComponent GuardEffect;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = Effects)
    UParticleSystem GuardOverParticleSystem;

    bool bIsRight = true;

    bool bCanJump = false;

    bool bDead = false;
    bool bGuarding = false;
    bool bRolling = false;
    bool bAttacking = false;
    bool bHit = false;
    bool bGuardCooling = false;

    FTimerHandle ForceReleaseGuardTimerHandle;

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
    }

	UFUNCTION()
	void MoveRight(float32 AxisValue) {
        if(CanMove()) {
            this.AddMovementInput(FVector(1.0, 0.0, 0.0), AxisValue);
            HandleOrientation(AxisValue);
            if(this.bRolling) {
                this.HandleRolling();
            }
            else {
                if(CharacterMovement.IsFalling()) {
                    this.HandleJumpOrFalling();
                }
                else {
                    this.HandleIdleOrRunning(AxisValue);
                }
            }
        }
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
        if(CanSprint()) {
            CharacterMovement.MaxWalkSpeed = 1000.0;
            this.Sprite.SetPlayRate(1.5);
        }
    }

    UFUNCTION()
    void OnSprintReleased(FKey Key) {
        if(CanSprint()) {
            CharacterMovement.MaxWalkSpeed = 600.0;
            this.Sprite.SetPlayRate(1.0);
        }
    }

    UFUNCTION()
    void OnRollPressed(FKey Key) {
        if(CanRoll()) {
            this.bRolling = true;
            LaunchCharacter(FVector(bIsRight ? 3000.0: -3000.0, 0.0, 0.0), false, false);
            this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Ignore);
            this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Ignore);
            Gameplay::SpawnSoundAtLocation(RollingSound, GetActorLocation());
            System::SetTimer(this, n"OnRollingTimeout", Animations[n"Rolling"].TotalDuration, false);
        }
    }

    UFUNCTION()
    void OnRollReleased(FKey Key) {
    }
    
    UFUNCTION()
    void OnRollingTimeout() {
        this.bRolling = false;
        this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_WorldDynamic, ECollisionResponse::ECR_Overlap);
        this.CapsuleComponent.SetCollisionResponseToChannel(ECollisionChannel::ECC_Pawn, ECollisionResponse::ECR_Overlap);
    }

    UFUNCTION()
    void OnGuardPressed(FKey Key) {
        if(CanGuard()) {
            bGuarding = true;
            UPaperFlipbook GuardAnimation = Animations[n"Guard"];
            Sprite.SetFlipbook(GuardAnimation);
            System::SetTimer(this, n"OnGuardTimeout", GuardAnimation.TotalDuration, false);
        }
    }

    UFUNCTION()
    void OnGuardReleased(FKey Key) {
        OnGuardReleasedEx();
    }

    void OnGuardReleasedEx() {
        if(System::IsValidTimerHandle(ForceReleaseGuardTimerHandle)) {
            System::ClearAndInvalidateTimerHandle(ForceReleaseGuardTimerHandle);
        }
        bGuarding = false;
        GuardEffect.Deactivate();
        bGuardCooling = true;
        System::SetTimer(this, n"OnGuardCoolingTimeout", 5.0, false);
    }
    
    UFUNCTION()
    void OnGuardTimeout() {
        Sprite.SetFlipbook(Animations[n"GuardLoop"]);
        GuardEffect.Activate(true);
        ForceReleaseGuardTimerHandle = System::SetTimer(this, n"OnForceReleaseGuardTimeout", 5.0, false);
        Gameplay::SpawnSoundAtLocation(GuardSound, GetActorLocation(), StartTime = 0.1);
    }

    UFUNCTION()
    void OnGuardCoolingTimeout() {
        bGuardCooling = false;
        Gameplay::SpawnEmitterAtLocation(GuardOverParticleSystem, GetActorLocation(), Scale = FVector(2.0, 2.0, 2.0));
    }

    UFUNCTION()
    void OnForceReleaseGuardTimeout() {
        OnGuardReleasedEx();
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
            this.Sprite.SetFlipbook(Animations[n"Run"]);
        }
        else {
            this.Sprite.SetFlipbook(Animations[n"Idle"]);
        }
    }

    void HandleJumpOrFalling() {
        if(CharacterMovement.Velocity.Z > 0) {
            this.Sprite.SetFlipbook(Animations[n"Jump"]);
        }
        else {
            this.Sprite.SetFlipbook(Animations[n"Falling"]);
        }
    }

    void HandleRolling() {
        this.Sprite.SetFlipbook(Animations[n"Rolling"]);
    }

    bool CanJump() {
        return !CharacterMovement.IsFalling() && !bDead && !bGuarding && !bRolling && !bAttacking && !bHit;
    }

    bool CanMove() {
        return !bDead && !bGuarding && !bHit;
    }

    bool CanSprint() {
        return !bDead && !bGuarding && !bRolling && !bAttacking && !bHit;
    }
    
    bool CanRoll() {
        return !CharacterMovement.IsFalling() && !bDead && !bGuarding && !bRolling && !bAttacking && !bHit;
    }

    bool CanGuard() {
        return !CharacterMovement.IsFalling() && !bDead && !bGuardCooling && !bRolling && !bHit;
    }
}
