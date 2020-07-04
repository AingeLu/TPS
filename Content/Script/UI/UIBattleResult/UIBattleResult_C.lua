require "UnLua"

---@type UUserWidget
local UIBattleResult_C = Class()

function UIBattleResult_C:Initialize(Initializer)
end

function UIBattleResult_C:OnInitialized()
    self.Overridden.OnInitialized(self)

    --self.DebugBtn.OnClicked:Add(self, BP_Test_C.OnClicked_TestBtn)

    --LUIManager:RegisterMsg("UIBattleResult_C",Ds_UIMsgDefine.UI_SYSTEM_NETCONNECT_RET,
    --        function(...) self:OnConnectRet(...) end)
end

function UIBattleResult_C:PreConstruct(IsDesignTime)
    self.Overridden.PreConstruct(self, IsDesignTime)
end

function UIBattleResult_C:Construct()
    self.Overridden.Construct(self)

    self.BackToLobby_1_Button.OnClicked:Add(self, UIBattleResult_C.OnClicked_BackToLobby_1_Button)
    self.BackToLobby_2_Button.OnClicked:Add(self, UIBattleResult_C.OnClicked_BackToLobby_2_Button)
    self.BackToLobby_3_Button.OnClicked:Add(self, UIBattleResult_C.OnClicked_BackToLobby_3_Button)
end

function UIBattleResult_C:Destruct()
    self.Overridden.Destruct(self)
end

function UIBattleResult_C:OnShowWindow()

end

function UIBattleResult_C:OnHideWindow()

end

--function UIBattleResult_C:Tick(MyGeometry, InDeltaTime)
--end
-------------------------------------------------------
--- 辅助函数
-------------------------------------------------------
function UIBattleResult_C:GetShooterGameInstance()
    local gameInstance = self:GetGameInstance()
    if gameInstance ~= nil then
        return gameInstance:Cast(UE4.UBP_ShooterGameInstance_C)
    end

    return nil
end

function UIBattleResult_C:GetPlayerController()
    local playerControllerBase = nil
    local playerController = self:GetOwningPlayer()
    if playerController ~= nil then
        playerControllerBase = playerController:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    end

    return playerControllerBase
end

-------------------------------------------------------
--- UI Event
-------------------------------------------------------
function UIBattleResult_C:OnClicked_BackToLobby_1_Button()
    print("UIBattleResult_C OnClicked_BackToLobby_1_Button ...")
    local shooterGameIns = self:GetShooterGameInstance()
    if shooterGameIns == nil then
        print("shooterGameIns is nil ...")
        return
    end

    shooterGameIns:RequestFinishAndExitToMainMenu()

    shooterGameIns:GotoState("MainMenu")
    --LUIManager:DestroyAllWindow();
end

function UIBattleResult_C:OnClicked_BackToLobby_2_Button()
    print("UIBattleResult_C OnClicked_BackToLobby_2_Button ...")
    local shooterGameIns = self:GetShooterGameInstance()
    if shooterGameIns == nil then
        print("shooterGameIns is nil ...")
        return
    end

    shooterGameIns:RequestFinishAndExitToMainMenu()

    UE4.MapChangeLuaUtils.MapServerTravel("/Game/Maps/MainMenu")
end

function UIBattleResult_C:OnClicked_BackToLobby_3_Button()
    print("UIBattleResult_C OnClicked_BackToLobby_3_Button ...")
    local shooterGameIns = self:GetShooterGameInstance()
    if shooterGameIns == nil then
        print("shooterGameIns is nil ...")
        return
    end

    shooterGameIns:RequestFinishAndExitToMainMenu()

    UE4.MapChangeLuaUtils.MapClientTravel("/Game/Maps/MainMenu")
end

--function UIBattleResult_C:OnClicked_TestBtn()
--  print("OnClicked_TestBtn ...")
--    LUIManager:ShowWindow("UIMainEnterMain")
--end

return UIBattleResult_C