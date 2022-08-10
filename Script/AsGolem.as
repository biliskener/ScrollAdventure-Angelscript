UCLASS()
class AAsGolem: AAsEnemyBase {
    UPROPERTY(DefaultComponent, Attach = CollisionCylinder)
    USphereComponent Sphere;
}
