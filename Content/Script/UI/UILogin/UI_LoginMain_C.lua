require "UnLua"

--local LUIManager =   require "Core/UI/UIManager"

---@type UUserWidget
local UI_LoginMain_C = Class()

function UI_LoginMain_C:Initialize(Initializer)

end

function UI_LoginMain_C:OnInitialized()
    self.Overridden.OnInitialized(self)

    --- Register UI EventBP_ReceiveTick
    self.EnterGameBtn.OnClicked:Add(self, UI_LoginMain_C.OnClicked_LoginInBtn)
    self.RandomIDBtn.OnClicked:Add(self, UI_LoginMain_C.OnClicked_RandomID)

    self.DebugStandalone_1_Button.OnClicked:Add(self, UI_LoginMain_C.OnClicked_DebugStandalone_1_Button)
    self.DebugStandalone_2_Button.OnClicked:Add(self, UI_LoginMain_C.OnClicked_DebugStandalone_2_Button)

    LUIManager:RegisterMsg("UILoginMain",Ds_UIMsgDefine.UI_SYSTEM_NETCONNECT_RET,
            function(...) self:OnConnectRet(...) end)

    LUIManager:RegisterMsg("UILoginMain",Ds_UIMsgDefine.UI_SYSTEM_LOGIN_RET,
            function(...) self:OnLoginRet(...) end)
end

--function UI_LoginMain_C:PreConstruct(IsDesignTime)
--end

--function UI_LoginMain_C:Construct()
--end

--function UI_LoginMain_C:Tick(MyGeometry, InDeltaTime)
--end

function UI_LoginMain_C:OnShowWindow()
end

---------------------------------------------
--- UI Mgs Callback
---------------------------------------------

function UI_LoginMain_C:OnConnectRet(retCode)
    if retCode == 0 then
        GameLogicNetWorkMgr:GetGameLogicNetConnect():OnC2sLogicLoginReq(LUAPlayerDataMgr:GetPlayerID())
    else

    end
end

function UI_LoginMain_C:OnLoginRet(retCode,reason)
    --- 登录成功 ，没角色创建角色
    print("UI_LoginMain_C:OnLoginRet ... ...")
    print(debug.traceback())
    if retCode == 0 then


        ShooterGameInstance:GotoState("MainMenu");

        --LUIManager:ShowWindow("UIMainEnterMain")
        --LUIManager:DestroyWindow("UILoginMain");
    else
        if reason == "ErrPlayerNotExist" then
            LUIManager:ShowWindow("UILoginCreateRole")
        else

        end
    end
end

---------------------------------------------
--- UI Event Callback
---------------------------------------------

function UI_LoginMain_C:OnClicked_TestMap()
    print("UI_LoginMain_C:OnClicked_TestMap ... ")
end

function UI_LoginMain_C:OnClicked_TestMap2()
    print("UI_LoginMain_C:OnClicked_TestMap2 ... ")
end

function UI_LoginMain_C:OnClicked_TestBigMap()
    print("UI_LoginMain_C:OnClicked_TestBigMap ... ")
end

function UI_LoginMain_C:OnClicked_TestBigMap2()
    print("UI_LoginMain_C:OnClicked_TestBigMap2 ... ")
end

function UI_LoginMain_C:OnClicked_RandomID()
    local random_ID = "zznh" ..math.random(100,10000);
    self.InputAccIDEdiText:SetText(random_ID)
end

function UI_LoginMain_C:OnClicked_LoginInBtn()
    local AccountID = self.InputAccIDEdiText:GetText();


    if AccountID == "" then
        return
    end

    LUAPlayerDataMgr:SetPlayerID(AccountID)

    local LoginAddress = GameLogicNetWorkMgr:GetGameLogicNetConnect():GetLoginAddress()
    local LoginPort = GameLogicNetWorkMgr:GetGameLogicNetConnect():GetLoginPort()

    GameLogicNetWorkMgr:GetGameLogicNetConnect():OnStartConnect(LoginAddress , LoginPort)

end

function UI_LoginMain_C:OnClicked_DebugStandalone_1_Button()
    print("OnClicked_DebugStandalone_1_Button ...")
    UE4.MapChangeLuaUtils.MapServerTravel("/Game/Maps/BattleDebug?Standalone=1?RoleResID=1001")
end

function UI_LoginMain_C:OnClicked_DebugStandalone_2_Button()
    print("OnClicked_DebugStandalone_2_Button ...")
    UE4.MapChangeLuaUtils.MapServerTravel("/Game/Maps/Training_Ground/Training_Ground?Standalone=1?RoleResID=1001")
end

return UI_LoginMain_C
