require "UnLua"

local UIBattleBottomLeftRightClass  = require("UI/UIBattle/UIBattleBottomLeftRight_C");
local UIBattleBottomMidClass        = require("UI/UIBattle/UIBattleBottomMid_C");
local UIBattleTopMidClass           = require("UI/UIBattle/UIBattleTopMid_C");
local UIBattleTopLeftClass          = require("UI/UIBattle/UIBattleTopLeft_C");
local UIBattleTopRightClass         = require("UI/UIBattle/UIBattleTopRight_C");

---@type UUserWidget
local UIBattleMain_C = Class()

function UIBattleMain_C:Initialize(Initializer)
end

function UIBattleMain_C:OnInitialized()
    self.Overridden.OnInitialized(self)

    self.UIBattleBottomLeftRight = UIBattleBottomLeftRightClass.new()
    if self.UIBattleBottomLeftRight then
        self.UIBattleBottomLeftRight:OnInitialized(self)
    end

    self.UIBattleBottomMid = UIBattleBottomMidClass.new()
    if self.UIBattleBottomMid then
        self.UIBattleBottomMid:OnInitialized(self)
    end

    self.UIBattleTopMid = UIBattleTopMidClass.new()
    if self.UIBattleTopMid then
        self.UIBattleTopMid:OnInitialized(self)
    end

    self.UIBattleTopLeft = UIBattleTopLeftClass.new()
    if self.UIBattleTopLeft then
        self.UIBattleTopLeft:OnInitialized(self)
    end

    self.UIBattleTopRight = UIBattleTopRightClass.new()
    if self.UIBattleTopRight then
        self.UIBattleTopRight:OnInitialized(self)
    end

    --self.DebugJoystick.OnClicked:Add(self, UIBattleMain_C.OnClicked_DebugJoystickBtn)

    --LUIManager:RegisterMsg("UIBattleMain_C",Ds_UIMsgDefine.UI_SYSTEM_NETCONNECT_RET,
    --        function(...) self:OnConnectRet(...) end)

    self:OnRegisterUIMgs()
    
    self.LastPawn = nil
end

function UIBattleMain_C:PreConstruct(IsDesignTime)
    self.Overridden.PreConstruct(self, IsDesignTime)

    if self.UIBattleBottomLeftRight ~= nil then
        self.UIBattleBottomLeftRight:PreConstruct(IsDesignTime)
    end

    if self.UIBattleBottomMid ~= nil then
        self.UIBattleBottomMid:PreConstruct(IsDesignTime)
    end

    if self.UIBattleTopMid ~= nil then
        self.UIBattleTopMid:PreConstruct(IsDesignTime)
    end

    if self.UIBattleTopLeft ~= nil then
        self.UIBattleTopLeft:PreConstruct(IsDesignTime)
    end

    if self.UIBattleTopRight ~= nil then
        self.UIBattleTopRight:PreConstruct(IsDesignTime)
    end
end

function UIBattleMain_C:Construct()
    self.Overridden.Construct(self)

    self.TickPerSecTimer = 0.0

    if self.UIBattleBottomMid ~= nil then
        self.UIBattleBottomMid:Construct()
    end

    if self.UIBattleBottomLeftRight ~= nil then
        self.UIBattleBottomLeftRight:Construct()
    end

    if self.UIBattleTopMid ~= nil then
        self.UIBattleTopMid:Construct()
    end

    if self.UIBattleTopLeft ~= nil then
        self.UIBattleTopLeft:Construct()
    end

    if self.UIBattleTopRight ~= nil then
        self.UIBattleTopRight:Construct()
    end
end

function UIBattleMain_C:OnShowWindow()
    if self.UIBattleBottomMid ~= nil and isLuaFunc(self.UIBattleBottomMid.OnShowWindow) then
        self.UIBattleBottomMid:OnShowWindow()
    end

    if self.UIBattleBottomLeftRight ~= nil and isLuaFunc(self.UIBattleBottomLeftRight.OnShowWindow) then
        self.UIBattleBottomLeftRight:OnShowWindow()
    end

    if self.UIBattleTopMid ~= nil and isLuaFunc(self.UIBattleTopMid.OnShowWindow) then
        self.UIBattleTopMid:OnShowWindow()
    end

    if self.UIBattleTopLeft ~= nil and isLuaFunc(self.UIBattleTopLeft.OnShowWindow) then
        self.UIBattleTopLeft:OnShowWindow()
    end

    if self.UIBattleTopRight ~= nil and isLuaFunc(self.UIBattleTopLeft.OnShowWindow) then
        self.UIBattleTopRight:OnShowWindow()
    end

    LUIManager:ShowWindow("UIBattleMiniMap")
end

function UIBattleMain_C:OnHideWindow()
    if self.UIBattleBottomMid ~= nil and isLuaFunc(self.UIBattleBottomMid.OnHideWindow) then
        self.UIBattleBottomMid:OnHideWindow()
    end

    if self.UIBattleBottomLeftRight ~= nil and isLuaFunc(self.UIBattleBottomLeftRight.OnHideWindow) then
        self.UIBattleBottomLeftRight:OnHideWindow()
    end

    if self.UIBattleTopMid ~= nil and isLuaFunc(self.UIBattleTopMid.OnHideWindow) then
        self.UIBattleTopMid:OnHideWindow()
    end

    if self.UIBattleTopLeft ~= nil and isLuaFunc(self.UIBattleTopLeft.OnHideWindow) then
        self.UIBattleTopLeft:OnHideWindow()
    end

    if self.UIBattleTopRight ~= nil and isLuaFunc(self.UIBattleTopLeft.OnHideWindow) then
        self.UIBattleTopRight:OnHideWindow()
    end
end

function UIBattleMain_C:Destruct()
    self.Overridden.Destruct(self)

    LUIManager:DestroyUI("UIBattleMiniMap")

    if self.UIBattleBottomLeftRight ~= nil then
        self.UIBattleBottomLeftRight:Destruct()
        self.UIBattleBottomLeftRight = nil
    end

    if self.UIBattleBottomMid ~= nil then
        self.UIBattleBottomMid:Destruct()
        self.UIBattleBottomMid = nil
    end

    if self.UIBattleTopMid ~= nil then
        self.UIBattleTopMid:Destruct()
        self.UIBattleTopMid = nil
    end

    if self.UIBattleTopLeft ~= nil then
        self.UIBattleTopLeft:Destruct()
        self.UIBattleTopLeft = nil
    end

    if self.UIBattleTopRight ~= nil then
        self.UIBattleTopRight:Destruct()
        self.UIBattleTopRight = nil
    end

    self.LastPawn = nil
    self.LastRightAreaCameraLocalCoord = nil
end

function UIBattleMain_C:Tick(MyGeometry, InDeltaTime)
    self.Overridden.Tick(self , MyGeometry , InDeltaTime)

    local bCallPerSec = false
    self.TickPerSecTimer = self.TickPerSecTimer + InDeltaTime
    if self.TickPerSecTimer >= 1.0 then
        self.TickPerSecTimer = 0.0
        bCallPerSec = true
    end

    if self.UIBattleBottomLeftRight ~= nil then
        self:CallTickHelper(self.UIBattleBottomLeftRight, MyGeometry, InDeltaTime ,bCallPerSec)
    end

    if self.UIBattleTopMid ~= nil then
        self:CallTickHelper(self.UIBattleTopMid, MyGeometry, InDeltaTime ,bCallPerSec)
    end

    if self.UIBattleBottomMid ~= nil then
        self:CallTickHelper(self.UIBattleBottomMid, MyGeometry, InDeltaTime ,bCallPerSec)
    end

    if self.UIBattleTopLeft ~= nil then
        self:CallTickHelper(self.UIBattleTopLeft, MyGeometry, InDeltaTime ,bCallPerSec)
    end

    if self.UIBattleTopRight ~= nil then
        self:CallTickHelper(self.UIBattleTopRight, MyGeometry, InDeltaTime ,bCallPerSec)
    end

    if self.LastPawn == nil and self:GetOwningPlayerPawn() ~= nil then
        self.LastPawn = self:GetOwningPlayerPawn()
        self:OnShowWindow()
    end

    if self.PingMs_Text ~= nil then
        self.PingMs_Text:SetText(self:GetPlayerPing() .. " ms")
    end
end

---------------------------------------------------
---注册消息
------------------------------------------------
function UIBattleMain_C:OnRegisterUIMgs()

    --- 战斗开始
    LUIManager:RegisterMsg("UIBattleMain",Ds_UIMsgDefine.UI_BATTLE_LEVEL_START,
    function(...) self:BattleGamePlayStart() end)

    --- 战场数据改变
    LUIManager:RegisterMsg("UIBattleMain",Ds_UIMsgDefine.UI_BATTLE_LEVEL_MATCHDATACHANGE,
        function(...) self:OnBattleLevelMatchDataChange() end)

    --- 击杀通知
    LUIManager:RegisterMsg("UIBattleMain",Ds_UIMsgDefine.UI_BATTLE_LEVEL_KILLDOWNMSG,
    function(...) self:OnPlayerBeKillDown(...) end)
        
    --- 复活消息
    LUIManager:RegisterMsg("UIBattleMain",Ds_UIMsgDefine.UI_BATTLE_CHARACTER_RESPAWN,
        function(...) self:OnBattleCharacterRespawn() end)

    --- 角色装备改变消息
    LUIManager:RegisterMsg("UIBattleMain",Ds_UIMsgDefine.UI_BATTLE_CHARACTER_EQUIPDATACHANGE,
    function(...)  self:OnCharacterEquipNotify() end)

    --- 角色瞄准状态改变
    LUIManager:RegisterMsg("UIBattleMain",Ds_UIMsgDefine.UI_BATTLE_CHARACTER_AIMINGCHANGE,
            function(...)  self:OnCharacterAimingTargetChange(...) end)
end

---------------------------------------------------
--- 辅助函数
---------------------------------------------------
function UIBattleMain_C:CallTickHelper(selfObj, MyGeometry, InDeltaTime ,bCallPerSec)
    local tickFunc = selfObj.Tick
    if tickFunc ~= nil and isLuaFunc(tickFunc) then
        tickFunc(selfObj,MyGeometry, InDeltaTime)

        tickFunc = selfObj.TickPerSec
        if bCallPerSec and isLuaFunc(selfObj.TickPerSec) then
            tickFunc(selfObj ,MyGeometry, InDeltaTime)
        end
    end
end

---------------------------------------------------
--- Is 判断接口
---------------------------------------------------
function UIBattleMain_C:IsEnableAutomaticFire()
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()

    local AutomaticFireSettings = UserConfigSettings.AutoFireSetting
    local IsCanAutomaticFire = false

    if UserConfigSettings ~= nil then
        IsCanAutomaticFire = UserConfigSettings:GetBool(AutomaticFireSettings.Section, AutomaticFireSettings.Key, AutomaticFireSettings.Value)
    end

    return IsCanAutomaticFire
end


---------------------------------------------------
--- Getter 数据接口
---------------------------------------------------
function UIBattleMain_C:GetCharacterBase()
    local CharacterBase = nil
    local playerPawn = self:GetOwningPlayerPawn()
    if playerPawn and playerPawn:IsValid() then
        CharacterBase = playerPawn:Cast(UE4.ABP_ShooterCharacterBase_C)
    end

    return CharacterBase
end

function UIBattleMain_C:GetPlayerController()
    local playerControllerBase = nil
    local playerController = self:GetOwningPlayer()
    if playerController and playerController:IsValid() then
        playerControllerBase = playerController:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    end

    return playerControllerBase
end

function UIBattleMain_C:GetPlayerState()
    local pController = self:GetPlayerController()
    if pController == nil or not pController:IsValid() then
        print("UIBattleMain_C:GetPlayerState Error: pController is nil .")
        return
    end

    if pController.PlayerState == nil then
        print("UIBattleMain_C:GetPlayerState Error: pController.PlayerState is nil .")
        return
    end

    local shooterPlayerState = pController.PlayerState:Cast(UE4.ABP_ShooterPlayerStateBase_C)
    if shooterPlayerState == nil then
        print("UIBattleMain_C:GetPlayerState Error: Cast Failed .")
        return nil
    end

    return shooterPlayerState
end

function UIBattleMain_C:GetPlayerGameState()
    local gameState = UE4.UGameplayStatics.GetGameState(self)

    if gameState ~= nil then
        return gameState:Cast(UE4.ABP_ShooterGameStateBase_C)
    end

    return nil
end

function UIBattleMain_C:GetPlayerPing()
    local playerState = self:GetPlayerState()

    if playerState ~= nil then
        return playerState.Ping
    end

    return 0.0
end

function UIBattleMain_C:GetMyTeamID()
    local pc = self:GetPlayerController()
    if pc ~= nil then
        return pc:GetTeamID()
    end

    return 0
end

function UIBattleMain_C:GetMyPlayerID()
    local pc = self:GetPlayerController()
    if pc ~= nil then
        return pc:GetPlayerID()
    end

    return 0
end

function UIBattleMain_C:GetEnemyID()

    local myTeamID = self:GetMyTeamID()

    local gameState = self:GetPlayerGameState()
    if gameState == nil then
        print("UIBattleMain_C:GetEnemyID() gameState is nil .")
        return
    end

    local playerStateLen = gameState:GetPlayerStateLength()

    for i = 1, playerStateLen do
        local playerState = gameState:GetPlayerStateByIndex(i)
        if playerState ~= nil then
            if playerState:GetTeamID() ~= myTeamID then
                return playerState:GetTeamID()
            end
        end
    end

    return 0
end

function UIBattleMain_C:GetMyRuntimeAttrData()
    local gameState = self:GetPlayerGameState()
    if gameState == nil then
        print("UIBattleMain_C:GetMyRuntimeAttrData() gameState is nil .")
        return
    end

    local myPlayerID =  self:GetMyPlayerID()

    local playerStateLen = gameState:GetPlayerStateLength()
    for i = 1, playerStateLen do
        local playerState = gameState:GetPlayerStateByIndex(i)
        if playerState ~= nil and myPlayerID == playerState:GetPlayerID() then            
            local runAttrData = playerState:GetRuntimeAttrData()
            if runAttrData ~= nil then
                return runAttrData
            end
        end
    end
end

function UIBattleMain_C:SetBattleMainControlPanelEnable(bEnable)
    if bEnable then
        self.BottomLeft_CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.BottomRight_CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        self.BottomMid_CanvasPanel:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    else
        self.BottomLeft_CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.BottomRight_CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
        self.BottomMid_CanvasPanel:SetVisibility(UE4.ESlateVisibility.Hidden)
    end
end

---------------------------------------------------
--- UI Event
---------------------------------------------------
--- 击杀通知转发
function UIBattleMain_C:OnPlayerBeKillDown(KillerPlayerState, BeKillerPlayerState)
    if self.UIBattleTopMid ~= nil then
        self.UIBattleTopMid:OnPlayerBeKillDown(KillerPlayerState, BeKillerPlayerState)
    end

    if self.UIBattleTopLeft ~= nil then
        self.UIBattleTopLeft:OnPlayerBeKillDown(KillerPlayerState, BeKillerPlayerState)
    end
end

--- 战斗开始转发
function UIBattleMain_C:BattleGamePlayStart()
    if self.UIBattleTopMid ~= nil then
        self.UIBattleTopMid:BattleGamePlayStart()
    end
end

--- 战场数据改变转发
function UIBattleMain_C:OnBattleLevelMatchDataChange()
    if self.UIBattleTopMid ~= nil then
        self.UIBattleTopMid:OnBattleLevelMatchDataChange()
    end
end

--- 复活消息转发
function UIBattleMain_C:OnBattleCharacterRespawn()
    if self.UIBattleTopMid ~= nil then
        self.UIBattleTopMid:OnBattleCharacterRespawn()
    end
end

--- 装备改变消息转发
function UIBattleMain_C:OnCharacterEquipNotify()
    if self.UIBattleBottomMid ~= nil then
        self.UIBattleBottomMid:OnCharacterEquipNotify()
    end
end

--- 瞄准状态改变
function UIBattleMain_C:OnCharacterAimingTargetChange()
    if self.UIBattleBottomLeftRight ~= nil then
        self.UIBattleBottomLeftRight:OnRefreshAimingState()
    end
end

return UIBattleMain_C