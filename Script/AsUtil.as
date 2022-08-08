namespace AsUtil {
    UAsBattleUI GetBattleUI() {
        AAsHUDInGame hud = Cast<AAsHUDInGame>(Gameplay::GetPlayerController(0).GetHUD());
        if(hud != nullptr) {
            return hud.BattleUI;
        }
        else {
            return nullptr;
        }
    }

    AAsPlayer GetPlayer() {
        return Cast<AAsPlayer>(Gameplay::GetPlayerCharacter(0));
    }
}
