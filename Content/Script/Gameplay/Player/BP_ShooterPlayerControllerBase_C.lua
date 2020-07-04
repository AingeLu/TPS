require "UnLua"

local CharacterAttrMgr = require "Gameplay/Player/Module/CharacterAttrMgr"
local CharacterEquipMgr = require "Gameplay/Player/Module/CharacterEquipMgr"
local CharacterHitDmgCalc = require "Gameplay/Player/Module/CharacterHitDmgCalc"

local BP_ShooterGameStateBase_C = require "Gameplay/Game/BP_ShooterGameStateBase_C"

---@type APlayerController
local BP_ShooterPlayerControllerBase_C = Class()

function BP_ShooterPlayerControllerBase_C:Initialize(Initializer)
    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------
    -- self.bAllowGameActions   = false
    -- self.bInfiniteAmmo       = false
    -- self.bInfiniteClip       = false
    -- self.bHealthRegen        = false
    -- self.CharacterCameraMode = UE4.ECharacterCameraMode.ThirdPerson

    self.bResetCameraRotate = false

    -------------------------------------------------------------------------
    --- Lua中定义的变量
    -------------------------------------------------------------------------
    self.LastKillPlayerTime = -99.0
    self.IsVirtualGamePad  = false
    -- 镜头竖直方向重置
    self.ResetCameraPitchTimer = 0.0
    self.bResetCamera = false
    self.ResetCameraRotateTimer = 0.0
    self.ResetCameraRotateCallback = nil
    self.ResetCameraRotateCaller = nil
end

function BP_ShooterPlayerControllerBase_C:UserConstructionScript()
    self.AttrMgr = CharacterAttrMgr.new()
    self.AttrMgr:OnCreate(self)

    self.EquipMgr = CharacterEquipMgr.new()
    self.EquipMgr:OnCreate(self)

    self.HitDmgCalc = CharacterHitDmgCalc.new()
    self.HitDmgCalc:OnCreate(self)
end

--function BP_ShooterPlayerControllerBase_C:ReceiveBeginPlay()
--end

--function BP_ShooterPlayerControllerBase_C:ReceiveEndPlay()
--end

function BP_ShooterPlayerControllerBase_C:ReceiveTick(DeltaSeconds)
    if self:HasAuthority() then
        if self.AttrMgr then
            self.AttrMgr:Tick(DeltaSeconds)
        end

        if self.EquipMgr then
            self.EquipMgr:Tick(DeltaSeconds)
        end

        if UE4.UKismetSystemLibrary.IsStandalone(self) then
            self:UpdateResetCameraPitch(DeltaSeconds)
            self:UpdateResetCameraRotate(DeltaSeconds)
        end
    else
        self:UpdateResetCameraPitch(DeltaSeconds)
        self:UpdateResetCameraRotate(DeltaSeconds)
    end
end

function BP_ShooterPlayerControllerBase_C:ReceivePossess(InPawn)
    if not InPawn then
        return
    end

    local CharacterBase = InPawn:Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase and CharacterBase:GetController() then
		CharacterBase:AttachToPlayerControl(self)
    end
end

function BP_ShooterPlayerControllerBase_C:ReceiveUnPossess(UnpossessedPawn)
    if not UnpossessedPawn then
        return
    end

    local CharacterBase = UnpossessedPawn:Cast(UE4.ABP_ShooterCharacterBase_C)
	if CharacterBase and CharacterBase:GetController() then
		CharacterBase:DetachFromPlayerControl()
    end
end

-------------------------------------------------------------------------
-- 通知客户端游戏开始
-------------------------------------------------------------------------
---游戏正式开始
function BP_ShooterPlayerControllerBase_C:OnGameStarted()

    print("BP_ShooterPlayerControllerBase_C OnGameStarted ...")

    --通知客户端
    self:ClientGameStarted();
end


---游戏结束
function BP_ShooterPlayerControllerBase_C:OnGameEnded()
    print("BP_ShooterPlayerControllerBase_C OnGameEnded ...")

end

--客户端游戏开始
function BP_ShooterPlayerControllerBase_C:ClientGameStartedNotify()

    print("BP_ShooterPlayerControllerBase_C ClientGameStartedNotify ...")

    if not UE4.UKismetSystemLibrary.IsDedicatedServer(self) then
        if ShooterGameInstance then
            ShooterGameInstance:SetLoadingScreenEnable(false)
        end
        LUIManager:ShowWindow("UIBattleMain")
    end
end

--客户端游戏结束 (C_GameHasEnded 接口内部RPC触发)
function BP_ShooterPlayerControllerBase_C:Receive_ClientGameEnded()
    print("BP_ShooterPlayerControllerBase_C Receive_ClientGameEnded ...")

    if not UE4.UKismetSystemLibrary.IsDedicatedServer(self) then
        LUIManager:DestroyUI("UIBattleMain")

        LUIManager:ShowWindow("UIBattleResult")
    end
end

--状态变成Inactive
function BP_ShooterPlayerControllerBase_C:Receive_BeginInactiveState()
    print("BP_ShooterPlayerControllerBase_C Receive_BeginInactiveState ...")

    if not self:HasAuthority() then
        return;
    end

    local GameState = UE4.UGameplayStatics.GetGameState(self)
    if  GameState  then
        local ShooterGameState =  GameState:Cast(UE4.ABP_ShooterGameStateBase_C)
        if ShooterGameState then
            local MinRespawnTime  = ShooterGameState:GetMinRespawnTime()

            print("MinRespawnTime:",MinRespawnTime)
            local resPawnTime = math.max(1.0, MinRespawnTime)
            UE4.UKismetSystemLibrary.K2_SetTimerDelegate({self, BP_ShooterGameStateBase_C.BeginRespawn}, resPawnTime, false)
        end
	end

end

--复活
function BP_ShooterGameStateBase_C:BeginRespawn()

    local CurGameMode = UE4.UGameplayStatics.GetGameMode(self);
    CurGameMode = CurGameMode and CurGameMode:Cast(UE4.ABP_ShooterGameModeBase_C) or nil;
    if CurGameMode == nil then
        print("BP_ShooterGameStateBase_C BeginRespawn CurGameMode is nil")
        return;
    end

    CurGameMode:BeginRespawn(self);
end

-------------------------------------------------------------------------
-- Input Event
-------------------------------------------------------------------------
-- 鼠标显示事件
function BP_ShooterPlayerControllerBase_C:MouseCursor_Pressed()
    self.bShowMouseCursor = not self.bShowMouseCursor
end

-------------------------------------------------------------------------
-- RPC Function
-------------------------------------------------------------------------

-------------------------------------------------------------------------
-- Replicated Notify
-------------------------------------------------------------------------

--单位复活通知
function BP_ShooterPlayerControllerBase_C:ServerResPawnStartedNotify()
    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_RESPAWN)
end

function BP_ShooterPlayerControllerBase_C:ClientResPawnStartedNotify(PlayStateRuntimeAttrData)
    --客户端提前改变数据
    local shooterPlayerState = self:GetShooterPlayerState()
    if shooterPlayerState then
        shooterPlayerState:Client_SetRuntimeAttrData(PlayStateRuntimeAttrData)
    end

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_RESPAWN)
end

--击杀单位通知
function BP_ShooterPlayerControllerBase_C:ServerKillPlayerNotify(KillerPlayerState, BeKillerPlayerState)
    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_LEVEL_KILLDOWNMSG)
    self.LastKillPlayerTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
end

function BP_ShooterPlayerControllerBase_C:ClientKillPlayerNotify(KillerPlayerState, BeKillerPlayerState,BeKillerRuntimeAttrData)

    --客户端提前改变数据
    if BeKillerPlayerState then
        BeKillerPlayerState:Client_SetRuntimeAttrData(BeKillerRuntimeAttrData)
    end

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_LEVEL_KILLDOWNMSG, KillerPlayerState, BeKillerPlayerState)

    if KillerPlayerState:GetPlayerID() == self:GetPlayerID() then
        self.LastKillPlayerTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
    end
end


-------------------------------------------------------------------------
-- 设置数据接口
-------------------------------------------------------------------------
-- @params (bool)
function BP_ShooterPlayerControllerBase_C:SetIsVibrationEnabled(bEnable)
	self.bIsVibrationEnabled = bEnable
end

-- @params (bool)
function BP_ShooterPlayerControllerBase_C:SetInfiniteAmmo(bEnable)
    self.bInfiniteAmmo = bEnable
end

-- @params (bool)
function BP_ShooterPlayerControllerBase_C:SetInfiniteClip(bEnable)
	self.bInfiniteClip = bEnable
end

-- @params (bool)
function BP_ShooterPlayerControllerBase_C:SetHealthRegen(bEnable)
	self.bHealthRegen = bEnable
end

-- @params (bool)
function BP_ShooterPlayerControllerBase_C:SetGodMode(bEnable)
	self.bGodMode = bEnable
end

-- @params (bool)
function BP_ShooterPlayerControllerBase_C:SetIsVirtualGamePad(bVirtualGamePad)
    self.IsVirtualGamePad = bVirtualGamePad
end

-- @prams (ECharacterCameraMode)
function BP_ShooterPlayerControllerBase_C:SetCharacterCameraMode(newCameraMode)
	if newCameraMode ~= self.CharacterCameraMode then
        self.CharacterCameraMode = newCameraMode
    end
end

-- @params (bool)
function BP_ShooterPlayerControllerBase_C:ResetCharacterCameraPitch(bResetCamera)
    if not self.bResetCamera and bResetCamera then
        self.ResetCameraPitchTimer = 0.0
    end

    self.bResetCamera = bResetCamera
end


function BP_ShooterPlayerControllerBase_C:UpdateResetCameraRotate(DeltaSeconds)
    if self.bResetCameraRotate then
        self.ResetCameraRotateTimer = self.ResetCameraRotateTimer + DeltaSeconds
        --self:ResetCameraRotate(self.ResetCameraRotateTimer)
        local curve = self.ResetCameraRotateCurve
        if curve then
            local alpha = math.min(curve:GetFloatValue(self.ResetCameraRotateTimer) , 1)

            local controlRotation =  self:GetControlRotation()
            local controlPawn = self:K2_GetPawn()
            if controlPawn then
                local pawnRotation = self:K2_GetActorRotation()
                pawnRotation = UE4.FRotator(controlRotation.Pitch , pawnRotation.Yaw , controlRotation.Roll)

                local newRotator = UE4.UKismetMathLibrary.RLerp(controlRotation ,pawnRotation , alpha, false)
                self:SetControlRotation(newRotator)
            else
                self:OnResetControllerCameraEnd()
            end

            if alpha >= 1 then
                self:OnResetControllerCameraEnd()
            end
        else
            self:OnResetControllerCameraEnd()
        end
    end
end

function BP_ShooterPlayerControllerBase_C:OnResetControllerCameraEnd()
    self.bResetCameraRotate = false
    self.ResetCameraRotateTimer = 0.0

    if self.ResetCameraRotateCallback and type(self.ResetCameraRotateCallback) == "function" then
        self.ResetCameraRotateCallback(self.ResetCameraRotateCaller)

        self.ResetCameraRotateCallback = nil
        self.ResetCameraRotateCaller = nil
    end
end

function BP_ShooterPlayerControllerBase_C:OnResetControllerCameraStart(caller,finishCallback)
    if self.bResetCameraRotate then
        return
    end

    self.bResetCameraRotate = true
    self.ResetCameraRotateTimer = 0.0

    if caller then
        self.ResetCameraRotateCaller = caller

        if finishCallback and type(finishCallback) == 'function' then
            self.ResetCameraRotateCallback = finishCallback
        end
    end
end

function BP_ShooterPlayerControllerBase_C:UpdateResetCameraPitch(DeltaSeconds)
    if self.bResetCamera then
        self.ResetCameraPitchTimer = self.ResetCameraPitchTimer + DeltaSeconds
        local rotator = self:K2_GetActorRotation()

        local step = 0.0
        if self.bUseResetCameraPitchCurve then
            if self.ResetCameraPitchCurve then
                step = self.ResetCameraPitchCurve:GetFloatValue(self.ResetCameraPitchTimer)
            else
                step = self.ResetCameraPitchSpeed
            end
        else
            step = self.ResetCameraPitchSpeed
        end

        if math.abs(rotator.Pitch) <= step then
            step = math.abs(rotator.Pitch)
        end

        local newPitch = rotator.Pitch

        if newPitch > 0 then
            newPitch = newPitch - step
        else
            newPitch = newPitch + step
        end

        local resetRotator = UE4.FRotator(newPitch , rotator.Yaw , rotator.Roll)

        self:SetControlRotation(resetRotator)
    end
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------
-- 获取角色属性管理器
function BP_ShooterPlayerControllerBase_C:GetAttrMgr()
    return self.AttrMgr
end

-- 获取角色装备管理器
function BP_ShooterPlayerControllerBase_C:GetEquipMgr()
    return self.EquipMgr
end

function BP_ShooterPlayerControllerBase_C:GetHitDmgCalc()
    return self.HitDmgCalc
end

function BP_ShooterPlayerControllerBase_C:GetCharacterCameraMode()
    return self.CharacterCameraMode
end

function BP_ShooterPlayerControllerBase_C:GetPlayerID()
    local shooterPlayerState = self:GetShooterPlayerState()
    if shooterPlayerState ~= nil then
        return shooterPlayerState:GetPlayerID()
    else
        print("BP_ShooterPlayerControllerBase_C:GetPlayerID Warning: PlayerState is nil")
    end

    return 0
end

function BP_ShooterPlayerControllerBase_C:GetRoleResID()
    local shooterPlayerState = self:GetShooterPlayerState()
    if shooterPlayerState ~= nil then
        return shooterPlayerState:GetRoleResID()
    else
        print("BP_ShooterPlayerControllerBase_C:GetRoleResID Warning: PlayerState is nil")
    end

    return 0
end

function BP_ShooterPlayerControllerBase_C:GetTeamID()
    local shooterPlayerState = self:GetShooterPlayerState()
    if shooterPlayerState ~= nil then
        return shooterPlayerState:GetTeamID()
    else
        print("BP_ShooterPlayerControllerBase_C:GetTeamID Warning: PlayerState is nil")
    end

    return 0
end

function BP_ShooterPlayerControllerBase_C:GetPlayerIndex()
    local shooterPlayerState = self:GetShooterPlayerState()
    if shooterPlayerState ~= nil then
        return shooterPlayerState:GetPlayerIndex()
    else
        print("BP_ShooterPlayerControllerBase_C:GetTeamID Warning: PlayerState is nil")
    end

    return 0
end

function BP_ShooterPlayerControllerBase_C:GetPlayerName()
    local shooterPlayerState = self:GetShooterPlayerState()

    if shooterPlayerState ~= nil then
        return shooterPlayerState:GetRuntimePlayerName()
    else
        print("BP_ShooterPlayerControllerBase_C:GetPlayerName Warning: PlayerState is nil")
    end

    return ""
end

function BP_ShooterPlayerControllerBase_C:GetShooterPlayerState()
    if self.PlayerState == nil then
        print("BP_ShooterGameStateBase_C:GetShooterPlayerState Error: self.PlayerState is nil.")
        return nil
    end

    local shooterPlayerState = self.PlayerState:Cast(UE4.ABP_ShooterPlayerStateBase_C)
    if shooterPlayerState == nil then
        print("BP_ShooterGameStateBase_C:GetShooterPlayerState Error: Cast Failed .")
        return nil
    end

    return shooterPlayerState
end

function BP_ShooterPlayerControllerBase_C:GetShooterCharacter()
    local Pawn = self:K2_GetPawn()
    return Pawn and Pawn:Cast(UE4.ABP_ShooterCharacterBase_C) or nil;
end

function BP_ShooterPlayerControllerBase_C:GetLastKillPlayerTime()
    return self.LastKillPlayerTime
end

function BP_ShooterPlayerControllerBase_C:GetIsVirtualGamePad()
    return self.IsVirtualGamePad  
end
-------------------------------------------------------------------------
-- 判断状态接口
-------------------------------------------------------------------------
function BP_ShooterPlayerControllerBase_C:IsVibrationEnabled()
	return self.bIsVibrationEnabled
end

-- @return bool
function BP_ShooterPlayerControllerBase_C:HasInfiniteAmmo()
	return self.bInfiniteAmmo
end

-- @return bool
function BP_ShooterPlayerControllerBase_C:HasInfiniteClip()
	return self.bInfiniteClip
end

-- @return bool
function BP_ShooterPlayerControllerBase_C:HasHealthRegen()
	return self.bHealthRegen
end

-- @return bool
function BP_ShooterPlayerControllerBase_C:HasGodMode()
    return self.bGodMode
end

-- @params (bool)
function BP_ShooterPlayerControllerBase_C:IsResetCharacterCameraPitch()
    return self.bResetCamera
end

return BP_ShooterPlayerControllerBase_C
