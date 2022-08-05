UCLASS()
class AAsEnemyBase : APaperCharacter {
    bool mIsDead = false;
    bool mHit = false;
    int mMaxHealth = 10;
    int mHealth = mMaxHealth;
    EAsDamageType mValidDamageType = EAsDamageType::Both;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = BeHit)
    USoundBase BeHitSound;

    UPROPERTY(EditAnywhere, BlueprintReadWrite, Category = BeHit)
    UParticleSystem BeHitEffect;

    UFUNCTION(BlueprintOverride)
    void BeginPlay() {
        mHealth = mMaxHealth;
    }

    void OnHitHandle(int damage, AActor damageCauser, EAsDamageType damageType) {
        if(!mIsDead) {
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
                    System::SetTimer(this, n"OnHitTimeout", 0.2, false);
                }
                else {

                }
            }
        }
    }

    UFUNCTION()
    void OnHitTimeout() {
        Sprite.SetSpriteColor(FLinearColor::White);
        mHit = false;
    }

    private void ParticleSounds(USoundBase sound, float32 startTime, UParticleSystem particle, FRotator rotation, FVector scale) {
        Gameplay::SpawnEmitterAtLocation(particle, GetActorLocation(), rotation, scale);
        Gameplay::SpawnSoundAtLocation(sound, GetActorLocation(), StartTime = startTime);
    }
}
