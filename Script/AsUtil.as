namespace AsUtil {
    UAsBattleUI GetLayout() {
        AAsHudInGame hud = Cast<AAsHudInGame>(Gameplay::GetPlayerController(0).GetHUD());
        if(hud != nullptr) {
            return hud.mLayout;
        }
        else {
            return nullptr;
        }
    }

    AAsPlayer GetPlayer() {
        return Cast<AAsPlayer>(Gameplay::GetPlayerCharacter(0));
    }
}
