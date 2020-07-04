require "UnLua"

local BP_EquipBase_C = Class()

local DOUBLE_EQUUP_TIME = 0.2

function BP_EquipBase_C:Initialize(Initializer)
    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------
    -- 配置数据: 装备资源ID
    -- self.ResID

    -- 同步属性: 装备孵化
    -- self.EquipSpawn

    -- 装备的拥有者
    -- self.CharacterBase

    -- 装备状态
    self.EquipState = UE4.EEquipState.EquipState_None
end

-- @params: (BP_ShooterCharacterBase_C, tagEquipBarType, int8, FName, FName)
function BP_EquipBase_C:OnInit(NewOwner, iEquipBarType, iEquipState, AttachPoint)
    self.Instigator = NewOwner
    self.CharacterBase = NewOwner
    -- net owner for RPC calls
    self:SetOwner(NewOwner)

    if self.ResID <= 0 then
        print("-----Error: BP_EquipBase_C::OnInit self.ResID is illegal, resID = ", self.ResID)
        return
    end

    self.ResWeaponDesc = GameResMgr:GetGameResDataByResID("WeaponDesc_Res", self.ResID)
    if not self.ResWeaponDesc then
        print("-----Error: BP_EquipBase_C::OnInit WeaponDesc_Res is null, resID = ", self.ResID)
        return
    end

    self.WeaponAnimIDs = {};
    self.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_NONE] = 0;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPUP_L] = self.ResWeaponDesc.LEquipUpAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPUP_R] = self.ResWeaponDesc.REquipUpAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPDOWN_L] = self.ResWeaponDesc.LEquipDownAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPDOWN_R] = self.ResWeaponDesc.REquipDownAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPRELOAD] = self.ResWeaponDesc.ReloadAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_FIRE] = self.ResWeaponDesc.FireAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_TARGETING] = self.ResWeaponDesc.TargetingAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_PULLBOLT] = self.ResWeaponDesc.PullBoltAnimID;
    --- 蹲
    self.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPUP_L] = self.ResWeaponDesc.Crouch_LEquipUpAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPUP_R] = self.ResWeaponDesc.Crouch_REquipUpAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPDOWN_L] = self.ResWeaponDesc.Crouch_LEquipDownAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPDOWN_R] = self.ResWeaponDesc.Crouch_REquipDownAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPRELOAD] = self.ResWeaponDesc.Crouch_ReloadAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_FIRE] = self.ResWeaponDesc.Crouch_FireAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_TARGETING] = self.ResWeaponDesc.Crouch_TargetingAnimID;
    self.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_PULLBOLT] = self.ResWeaponDesc.Crouch_PullBoltAnimID;

    self.EquipState = iEquipState

    if self:HasAuthority() then
        self.EquipSpawn.Pawn = NewOwner
        self.EquipSpawn.EquipBarType = iEquipBarType
        self.EquipSpawn.EquipState = iEquipState
        self.EquipSpawn.AttachPoint = AttachPoint
    end

    self:AttachMeshToPawn(AttachPoint)
    self:UpdateMeshes()
end

function BP_EquipBase_C:OnUnInit()
    if self:HasAuthority() then
        --self.Instigator = nil
        --self.CharacterBase = nil
        --self:SetOwner(nil)
        --
        --self.EquipSpawn.Pawn = nil

        self:SetLifeSpan(0.2)
    end
end

-- 装上
function BP_EquipBase_C:OnEquipUp(AttachPoint, WeaponUpAnimationType, WeaponDownAnimationType)
    self.EquipState = UE4.EEquipState.EquipState_EquipUping

    local WeaponUpAnimation =  self.CharacterBase:FindAnimationByID(self.WeaponAnimIDs[WeaponUpAnimationType]);
    local WeaponDownAnimation =  self.CharacterBase:FindAnimationByID(self.WeaponAnimIDs[WeaponDownAnimationType]);

    local Duration = DOUBLE_EQUUP_TIME;
    if WeaponUpAnimation ~= nil then
        Duration = WeaponUpAnimation.Param1

        if WeaponDownAnimation ~= nil then
            Duration = Duration + WeaponDownAnimation.Param1
            --播放收武器动作
            self:PlayWeaponAnimation(WeaponDownAnimation.Pawn1P,WeaponDownAnimation.Pawn3P,
                WeaponUpAnimation.Pawn1P,WeaponUpAnimation.Pawn3P);
        else
            --播放装备武器动作
            self:PlayWeaponAnimation(WeaponUpAnimation.Pawn1P,WeaponUpAnimation.Pawn3P, nil, nil);
        end
    
    end

    if Duration < 0.01 then
        Duration = DOUBLE_EQUUP_TIME;
    end

    local co = coroutine.create(BP_EquipBase_C.OnEquipUpFinished)
    coroutine.resume(co, self, Duration, AttachPoint)

end

-- 装上完成
function BP_EquipBase_C:OnEquipUpFinished(Duration, AttachPoint)
    UE4.UKismetSystemLibrary.Delay(self, Duration)

    self:AttachMeshToPawn(AttachPoint)
    self:UpdateMeshes()

    self.EquipState = UE4.EEquipState.EquipState_EquipUped
end

-- 卸下
function BP_EquipBase_C:OnEquipDown(AttachPoint, WeaponDownAnimationType)
    self.EquipState = UE4.EEquipState.EquipState_EquipDowning

    local Duration = DOUBLE_EQUUP_TIME;
    if WeaponDownAnimationType ~= Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_NONE then
        local WeaponDownAnimation =  self.CharacterBase:FindAnimationByID(self.WeaponAnimIDs[WeaponDownAnimationType]);
        if WeaponDownAnimation ~= nil then
            Duration = Duration + WeaponDownAnimation.Param1

             --播放收武器动作
             self:PlayWeaponAnimation(WeaponDownAnimation.Pawn1P,WeaponDownAnimation.Pawn3P, nil, nil);
        end
    end

    local co = coroutine.create(BP_EquipBase_C.OnEquipDownFinished)
    coroutine.resume(co, self, Duration, AttachPoint)
end

-- 卸到身上完成
function BP_EquipBase_C:OnEquipDownFinished(Duration, AttachPoint)
    UE4.UKismetSystemLibrary.Delay(self, Duration)

    self:AttachMeshToPawn(AttachPoint)
    self:UpdateMeshes()

    self.EquipState = UE4.EEquipState.EquipState_EquipDowned
end

-------------------------------------------------------------------------
-- @params: (FName)
function BP_EquipBase_C:AttachMeshToPawn(AttachPoint)

end

function BP_EquipBase_C:DetachMeshFromPawn()
    
end

function BP_EquipBase_C:UpdateMeshes()

end

-------------------------------------------------------------------------
-- Input Event
-------------------------------------------------------------------------
-- 开火
function BP_EquipBase_C:StartFire()
    
end

-- 停火
function BP_EquipBase_C:StopFire()
    
end

-- 开始重载
function BP_EquipBase_C:StartReload()

end

-- 结束重载
function BP_EquipBase_C:StopReload()

end

function BP_EquipBase_C:HandleReload()

end

function BP_EquipBase_C:HandleAttachMagin()

end

function BP_EquipBase_C:HandleAttachMagout()

end

function BP_EquipBase_C:DrawCrosshair()

end

-------------------------------------------------------------------------
-- Replicated Notify
-------------------------------------------------------------------------
function BP_EquipBase_C:OnRep_EquipSpawn()
	if self.EquipSpawn and self.EquipSpawn.Pawn then
		self:OnInit(self.EquipSpawn.Pawn, self.EquipSpawn.EquipBarType, self.EquipSpawn.EquipState, self.EquipSpawn.AttachPoint)
	else
		self:OnUnInit()
    end
end

-------------------------------------------------------------------------
-- event Notify
-------------------------------------------------------------------------

function BP_EquipBase_C:OnEquipData_S()
    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_EQUIPDATACHANGE)
end

function BP_EquipBase_C:OnEquipData_C()
    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_EQUIPDATACHANGE)
end

------------------------------------------------------------------------
-- 设置数据接口
------------------------------------------------------------------------
-- 设置拥有者
-- @params: BP_ACharacterBase_C
function BP_EquipBase_C:SetOwningPawn(NewOwner)
	if self.CharacterBase ~= NewOwner then
		self.Instigator = NewOwner
		self.CharacterBase = NewOwner
		-- net owner for RPC calls
		self:SetOwner(NewOwner)
    end
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------
function BP_EquipBase_C:GetUsingMesh()
    return self.Mesh1P
end

function BP_EquipBase_C:GetOwnerPawn()
    return self.CharacterBase
end

function BP_EquipBase_C:GetOwnerController()
    if self.CharacterBase and self.CharacterBase.Controller then
        return self.CharacterBase.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    end

    return nil
end

function BP_EquipBase_C:GetOwnerPawnRotation()
	local PlayerController = self:GetOwnerController()
	if PlayerController and PlayerController.PlayerCameraManager then
        return PlayerController.PlayerCameraManager:GetCameraRotation()
    end

	return  self.CharacterBase and self.CharacterBase:K2_GetActorRotation() or UE4.FRotator()
end

function BP_EquipBase_C:GetPawnSocketLocation(AttachPoint)
	local PawnMesh = self.CharacterBase:GetUsingMesh();
	if PawnMesh then
		return  PawnMesh:GetSocketLocation(AttachPoint);
    end

	return UE4.FVector();
end

--获取瞄准模式
function BP_EquipBase_C:GetEquipAimMode()
    return EEquipAimMode.EEquipAimMode_NONE;
end

function BP_EquipBase_C:GetTargetingFOV()
    return 90;
end

function BP_EquipBase_C:IsAllowAiming()
    return false;
end

-------------------------------------------------------------------------
-- 判断状态接口
-------------------------------------------------------------------------
--- 是否正在装备
function BP_EquipBase_C:IsEquipUping()
    return (self.EquipState == UE4.EEquipState.EquipState_EquipUping) and true or false
end

-- 是否装上了
function BP_EquipBase_C:IsEquipUped()
    return (self.EquipState == UE4.EEquipState.EquipState_EquipUped) and true or false
end

-- 是否证正在卸载
function BP_EquipBase_C:IsEquipDowning()
    return (self.EquipState == UE4.EEquipState.EquipState_EquipDowning) and true or false
end

-- 是否卸下了
function BP_EquipBase_C:IsEquipDowned()
    return (self.EquipState == UE4.EEquipState.EquipState_EquipDowned) and true or false
end

-- 是否绑定了角色身上
function BP_EquipBase_C:IsAttachedToPawn()
    return self:IsEquipUped() or self:IsEquipDowned()
end

function BP_EquipBase_C:IsPendingReload()
    return false
end

-------------------------------------------------------------------------
-- 辅助接口
-------------------------------------------------------------------------
-- 播放骨骼动画
-- @params: (UAnimationAsset)
function BP_EquipBase_C:PlaySkeletalAnimation(NewAnimToPlay)
	local UsingMesh = self:GetUsingMesh()
	if UsingMesh then
		UsingMesh:PlayAnimation(NewAnimToPlay, false)
    end
end

return BP_EquipBase_C
