namespace AsUtil {
    AAsBattleLayout GetLayout() {
        AAsHudInGame hud = Cast<AAsHudInGame>(Gameplay::GetPlayerController(0).GetHUD());
        if(hud != nullptr) {
            return hud.mLayout;
        }
        else {
            return nullptr;
        }
    }
}
