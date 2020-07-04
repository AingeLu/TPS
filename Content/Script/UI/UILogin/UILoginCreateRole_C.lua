require "UnLua"

local UILoginCreateRole_C = Class()

function UILoginCreateRole_C:Initialize(Initializer)
end

function UILoginCreateRole_C:OnInitialized()
    self.Overridden.OnInitialized(self)

    self.CreateBtn.OnClicked:Add(self, UILoginCreateRole_C.OnClicked_CreateRole)
    self.RandomNameBtn.OnClicked:Add(self, UILoginCreateRole_C.OnClicked_RandomNameBtn)
    self.InputName:SetText("")

    LUIManager:RegisterMsg("UILoginCreateRole",Ds_UIMsgDefine.UI_SYSTEM_NETCONNECT_RET,
            function(...) self:OnConnectRet(...) end)
    LUIManager:RegisterMsg("UILoginCreateRole",Ds_UIMsgDefine.UI_SYSTEM_LOGIN_RET,
            function(...) self:OnLoginRet(...) end)
end

function UILoginCreateRole_C:PreConstruct(IsDesignTime)
end

function UILoginCreateRole_C:Construct()
end

--function UILoginCreateRole_C:Tick(MyGeometry, InDeltaTime)
--end

function UILoginCreateRole_C:OnShowWindow()

end

---------------------------------------------
--- UI Mgs Callback
---------------------------------------------
function UILoginCreateRole_C:OnConnectRet(retCode)
    print("UILoginCreateRole_C :OnConnectRet: " , retCode)

    if retCode == 0 then
        --GameLogicNetWorkMgr.GetNetLogicMsgHandler():OnLogicCreatePlayerReq(self.AccountID, "", self.RoleName, 1, 1);
        GameLogicNetWorkMgr:GetGameLogicNetConnect():OnLogicCreatePlayerReq(LUAPlayerDataMgr:GetPlayerID(),
                "", LUAPlayerDataMgr:GetPlayerName(), 1, 1)
    else

    end
end

function UILoginCreateRole_C:OnLoginRet(retCode , reason)

    if retCode == 0 then
        --- 转场景 ， 界面在下个场景的 playerController 中创建
        --- BP_MainMenuPlayerController_C
        ShooterGameInstance:GotoState("MainMenu");
    else
        if reason == "ErrNameBlackword" then

        elseif reason == "ErrNameConflict" then

        elseif reason == "ErrIncludeSpace" then

        else

        end
    end
end

---------------------------------------------
--- UI Event Callback
---------------------------------------------

function UILoginCreateRole_C:OnClicked_RandomNameBtn()

    local randomName = LUIManager:GetRdNameConfig():GetRandomName()
    self.InputName:SetText(randomName)
end

function UILoginCreateRole_C:OnClicked_CreateRole()

    LUAPlayerDataMgr:SetPlayerName(self.InputName:GetText())
    if LUAPlayerDataMgr:GetPlayerName() == "" then
        return;
    end

    print("LUAPlayerDataMgr.PlayerRoleName : " , LUAPlayerDataMgr.PlayerRoleName)

    local LoginAddress = GameLogicNetWorkMgr:GetGameLogicNetConnect():GetLoginAddress()
    local LoginPort = GameLogicNetWorkMgr:GetGameLogicNetConnect():GetLoginPort()

    GameLogicNetWorkMgr:GetGameLogicNetConnect():OnStartConnect(LoginAddress , LoginPort)
end


return UILoginCreateRole_C
