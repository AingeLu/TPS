require "UnLua"

local BP_CharacterEquipComponent_C = Class()

function BP_CharacterEquipComponent_C:Initialize(Initializer)
    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------

    -- 配置数据: 装备挂点
    -- self.Weapon1AttachPoint
    -- self.Weapon2AttachPoint
    -- self.FistAttachPoint
    -- self.ThrowAttachPoint
    -- self.PropAttachPoint
    -- self.ArmorAttachPoint
    -- self.HelmetAttachPoint
    -- self.DownshiledAttachPoint

    -- 同步属性: 装备列表
    -- self.Equips
    -- 同步属性: 当前装备
    -- self.CurrentEquip

    self.bWantsToFire = false
end

--function BP_CharacterEquipComponent_C:ReceiveBeginPlay()
--end

--function BP_CharacterEquipComponent_C:ReceiveEndPlay()
--end

--function BP_CharacterEquipComponent_C:ReceiveTick(DeltaSeconds)
--end

function BP_CharacterEquipComponent_C:OnInit()
    -- 初始化装备数组
    self.Equips:Resize(Ds_EquipBarType.EQUIPBARTYPE_MAX)
    for iEquipBarType = Ds_EquipBarType.EQUIPBARTYPE_NONE + 1, Ds_EquipBarType.EQUIPBARTYPE_MAX do
        self.Equips:Set(iEquipBarType, nil)
    end

    -- 初始化装备管理器
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase:HasAuthority() then
        local EquipMgr = self:GetEquipMgr()
        if EquipMgr then
            EquipMgr:OnInit()
        end
    end
end

function BP_CharacterEquipComponent_C:OnUnInit()
    for iEquipBarType = Ds_EquipBarType.EQUIPBARTYPE_NONE + 1, Ds_EquipBarType.EQUIPBARTYPE_MAX do
        local Weapon = self.Equips:Get(iEquipBarType)
        if Weapon then
            Weapon:OnUnInit()
        end
    end
    self.CurrentEquip = nil
end

-- 添加装备
-- @params: (Ds_EquipBarType)
function BP_CharacterEquipComponent_C:AddEquip(iEquipBarType, EquipActor, EquipState)
    if not iEquipBarType or not EquipActor or iEquipBarType <= Ds_EquipBarType.EQUIPBARTYPE_NONE or iEquipBarType > Ds_EquipBarType.EQUIPBARTYPE_MAX then
        return
    end

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase:HasAuthority() then
        return
    end

    local AttachPoint = self:GetEquipAttachPoint(iEquipBarType, EquipState)
    EquipActor:OnInit(CharacterBase, iEquipBarType, EquipState, AttachPoint)

    -- 缓存装备对象
    self.Equips:Set(iEquipBarType, EquipActor)
end

-- 移除装备
-- @params: (Ds_EquipBarType)
function BP_CharacterEquipComponent_C:RemoveEquip(iEquipBarType)

end

-- 设置装备
-- @params: (Ds_EquipBarType)
function BP_CharacterEquipComponent_C:SetEquip(iEquipBarType)

end

function BP_CharacterEquipComponent_C:GetEquip(iEquipBarType)
    if not iEquipBarType or iEquipBarType <= Ds_EquipBarType.EQUIPBARTYPE_NONE or iEquipBarType > Ds_EquipBarType.EQUIPBARTYPE_MAX then
        return nil
    end

    return self.Equips:Get(iEquipBarType)
end

-- 设置成当前装备栏 只刷新数据
-- @params: (Ds_EquipBarType)
function BP_CharacterEquipComponent_C:SetCurrentEquip(iEquipBarType)

    local CurEquip = self.Equips:Get(iEquipBarType)
    if CurEquip then
        local EquipState = UE4.EEquipState.EquipState_EquipUped
        local AttachPoint = self:GetEquipAttachPoint(iEquipBarType, EquipState)
        
        self.CurrentEquip.EquipActor = CurEquip
        self.CurrentEquip.EquipBarType = iEquipBarType
        self.CurrentEquip.EquipState = UE4.EEquipState.EquipState_None
        self.CurrentEquip.EquipUpAnimType = Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_NONE
        self.CurrentEquip.EquipDownAnimType =  Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_NONE

        self.CurrentEquip.LastEquipActor = nil;
    end
end

-- 切换武器装备栏
-- @params: (Ds_EquipBarType)
function BP_CharacterEquipComponent_C:ChangeCurrentNewEquip(newEquipBarType)
 
    self.CurrentEquip.LastEquipActor = nil;

    local OldEquip = self.CurrentEquip.EquipActor

    local WeaponDownAnimationType = Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_NONE;
    local PreEquipBarType = self.CurrentEquip.EquipBarType;

    --收起武器
    if newEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_NONE then

        if OldEquip then

            WeaponDownAnimationType = (PreEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2) and
                Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPDOWN_L or Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPDOWN_R;
                    
            local AttachPoint = self:GetEquipAttachPoint(PreEquipBarType, UE4.EEquipState.EquipState_EquipDowned)

            OldEquip:OnEquipDown(AttachPoint, WeaponDownAnimationType)

            self.CurrentEquip.EquipActor = nil
            self.CurrentEquip.EquipBarType = Ds_EquipBarType.EQUIPBARTYPE_NONE
            self.CurrentEquip.EquipState = UE4.EEquipState.EquipState_EquipDowned
            self.CurrentEquip.EquipUpAnimType = Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_NONE
            self.CurrentEquip.EquipDownAnimType = WeaponDownAnimationType

            self.CurrentEquip.LastEquipActor = OldEquip;
            self.CurrentEquip.LastEquipBarType = PreEquipBarType;
        end

    else

        -- 先卸下旧的当前装备
        if OldEquip then
            WeaponDownAnimationType = (PreEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2) and
                Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPDOWN_L or Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPDOWN_R;
                                
            local EquipState = UE4.EEquipState.EquipState_EquipDowned
            local AttachPoint = self:GetEquipAttachPoint(self.CurrentEquip.EquipBarType, UE4.EEquipState.EquipState_EquipDowned)

            OldEquip:OnEquipDown(AttachPoint, Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_NONE)

            self.CurrentEquip.LastEquipActor = OldEquip;
            self.CurrentEquip.LastEquipBarType = self.CurrentEquip.EquipBarType;
        end

        -- 再装上新的当前装备
        local CurEquip = self.Equips:Get(newEquipBarType)
        if CurEquip then

            local WeaponUpAnimationType = (newEquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2) and
                Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPUP_L or Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPUP_R;
                        
            local EquipState = UE4.EEquipState.EquipState_EquipUped
            local AttachPoint = self:GetEquipAttachPoint(newEquipBarType, EquipState)
            
            CurEquip:OnEquipUp(AttachPoint, WeaponUpAnimationType, WeaponDownAnimationType)

            self.CurrentEquip.EquipActor = CurEquip
            self.CurrentEquip.EquipBarType = newEquipBarType
            self.CurrentEquip.EquipState = EquipState
            self.CurrentEquip.EquipUpAnimType = WeaponUpAnimationType
            self.CurrentEquip.EquipDownAnimType = WeaponDownAnimationType
        end
    end

end

function BP_CharacterEquipComponent_C:SetCurrentEquipHand()
    local CurEquipActor = self:GetCurEquipActor()
    if CurEquipActor then
        local CurEquipBarType = self:GetCurEquipBarType()
        local AttachPoint = self:GetEquipHandAttachPoint(CurEquipBarType, self.bEquipRightHand)
        CurEquipActor:AttachMeshToPawn(AttachPoint)
    end

end

--- 切换装备的左右手
function BP_CharacterEquipComponent_C:ChangeCurrentEquipHand(bRightHand)
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase:IsAlive() then
        return
    end

    self.bEquipRightHand = bRightHand

    self:SetCurrentEquipHand()
    --local CurEquipActor = self:GetCurEquipActor()
    --if CurEquipActor then
    --    local CurEquipBarType = self:GetCurEquipBarType()
    --    local AttachPoint = self:GetEquipHandAttachPoint(CurEquipBarType, bRightHand)
    --    CurEquipActor:AttachMeshToPawn(AttachPoint)
    --end

    -- 请求服务器
    if CharacterBase:GetLocalRole() < UE4.ENetRole.ROLE_Authority then
        --- 切换视角到右手
        self:ServerChangeCurrentEquipHand(bRightHand)
    end
end

function BP_CharacterEquipComponent_C:UpdateMeshes()
    if self.CurrentEquip.EquipActor then
        self.CurrentEquip.EquipActor:UpdateMeshes()
    end
end

-------------------------------------------------------------------------
-- Input Event
-------------------------------------------------------------------------
-- 开火
function BP_CharacterEquipComponent_C:StartFire()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase:IsAlive() then
        return
    end

    local PlayerController = CharacterBase.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
	if PlayerController and PlayerController:IsGameInputAllowed() then
		--if PlayerController.bShowMouseCursor then
        --    return
        --end

		CharacterBase.FiringInputAxisPitch = 0
		CharacterBase.FiringRecoilAxisPitch = 0

		if  CharacterBase:IsRunning() then
			CharacterBase:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)
        end

        if not self.bWantsToFire then
            self.bWantsToFire = true
    
            if self.CurrentEquip.EquipActor then
                self.CurrentEquip.EquipActor:StartFire()
            end
        end
    end
end

-- 停火
function BP_CharacterEquipComponent_C:StopFire()
	if self.bWantsToFire then
        self.bWantsToFire = false
        
		if self.CurrentEquip.EquipActor then
			self.CurrentEquip.EquipActor:StopFire()
        end
    end
end

--换弹夹
function BP_CharacterEquipComponent_C:StartReload()
    if self.CurrentEquip.EquipActor then
        --- 换弹时候如果处于开火状态，取消开火状态
        if self.bWantsToFire then
            self.bWantsToFire = false
        end
        self.CurrentEquip.EquipActor:StartReload()
    end
end

function BP_CharacterEquipComponent_C:StopReload()
    if self.CurrentEquip.EquipActor then
        self.CurrentEquip.EquipActor:StopReload()
    end
end

function BP_CharacterEquipComponent_C:HandleReload()
    if self.CurrentEquip.EquipActor then
        self.CurrentEquip.EquipActor:HandleReload()
    end
end

function BP_CharacterEquipComponent_C:HandleAttach()
    if self.CurrentEquip.EquipActor then
        self.CurrentEquip.EquipActor:HandleReload()
    end
end

function BP_CharacterEquipComponent_C:HandleAttachMagin()
    if self.CurrentEquip.EquipActor then
        self.CurrentEquip.EquipActor:HandleAttachMagin()
    end
end

function BP_CharacterEquipComponent_C:HandleAttachMagout()
    if self.CurrentEquip.EquipActor then
        self.CurrentEquip.EquipActor:HandleAttachMagout()
    end
end


-------------------------------------------------------------------------
-- Replicated Notify
-------------------------------------------------------------------------
-- 角色装备同步
function BP_CharacterEquipComponent_C:OnRep_Equips()
    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_EQUIPDATACHANGE)
end

-- 当前装备同步
-- @params: (FRepCurrentEquip)
function BP_CharacterEquipComponent_C:OnRep_CurrentEquip()

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_EQUIPDATACHANGE)

    if not self.CurrentEquip then
        return
    end

    --旧装备放下
    if self.CurrentEquip.LastEquipActor ~= nil then

        local AttachPoint = self:GetEquipAttachPoint(self.CurrentEquip.LastEquipBarType, UE4.EEquipState.EquipState_EquipDowned)
        local WeaponDownAnimationType = self.CurrentEquip.EquipDownAnimType;

        if  self.CurrentEquip.EquipState ~= UE4.EEquipState.EquipState_EquipDowned then
            WeaponDownAnimationType = Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_NONE
        end
  
        self.CurrentEquip.LastEquipActor:OnEquipDown(AttachPoint, WeaponDownAnimationType);
    end

    if  not self.CurrentEquip.EquipActor then
        return
    end

    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if CharacterBase then
        self.CurrentEquip.EquipActor:SetOwningPawn(CharacterBase)
    end

    if CharacterBase:IsWeaponAim() then
        local Weapon = self.CurrentEquip.EquipActor:Cast(UE4.ABP_ShootWeapon_C)
        if Weapon then
           CharacterBase:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM,
             Weapon:IsAllowAiming())
        end
    end

    if self.CurrentEquip.EquipState == UE4.EEquipState.EquipState_EquipUped then

        local AttachPoint = self:GetEquipAttachPoint(self.CurrentEquip.EquipBarType, UE4.EEquipState.EquipState_EquipUped)

        self.CurrentEquip.EquipActor:OnEquipUp(AttachPoint, self.CurrentEquip.EquipUpAnimType, 
            self.CurrentEquip.EquipDownAnimType)
    end
end

-- 服务器：装备数据改变
-- @Parames: Ds_EquipBarType
function BP_CharacterEquipComponent_C:OnEquipDataChange_S(iBarType)
    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_EQUIPDATACHANGE)
end

--- 左右手状态同步給其它玩家
function BP_CharacterEquipComponent_C:OnRep_bEquipRightHand()
    self:SetCurrentEquipHand()
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------
-- 获取装备管理器
function BP_CharacterEquipComponent_C:GetEquipMgr()
    local CharacterBase = self:GetOwner():Cast(UE4.ABP_ShooterCharacterBase_C)
    if not CharacterBase or not CharacterBase.Controller then
        return nil
    end

    local PlayerController = CharacterBase.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if PlayerController then
        return PlayerController:GetEquipMgr()
    end

    return nil
end

-- 获取武器
-- @params: (Ds_EquipBarType)
-- @return: BP_ShootWeapon_C
function BP_CharacterEquipComponent_C:GetWeaponByBarType(iBarType)

    if self.Equips == nil then
        return
    end

    if iBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 or iBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 then
        return self.Equips[iBarType] and self.Equips[iBarType]:Cast(ABP_ShootWeapon_C) or nil
    end

    return nil
end

function BP_CharacterEquipComponent_C:GetCurEquipBarType()
    return self.CurrentEquip and self.CurrentEquip.EquipBarType or Ds_EquipBarType.EQUIPBARTYPE_NONE
end

function BP_CharacterEquipComponent_C:GetCurEquipActor()
    return self.CurrentEquip and self.CurrentEquip.EquipActor or nil
end

function BP_CharacterEquipComponent_C:GetCurEquipWeaponCtn()
    local WeaponGunCtn = 0

    if self:GetEquip(Ds_EquipBarType.EQUIPBARTYPE_WEAPON1) ~= nil then
        WeaponGunCtn = WeaponGunCtn + 1
    end

    if self:GetEquip(Ds_EquipBarType.EQUIPBARTYPE_WEAPON2) ~= nil then
        WeaponGunCtn = WeaponGunCtn + 1
    end

    return WeaponGunCtn
end

function BP_CharacterEquipComponent_C:GetWeaponByBarType(EquipBarType)

    if EquipBarType <= Ds_EquipBarType.EQUIPBARTYPE_NONE or EquipBarType > Ds_EquipBarType.EQUIPBARTYPE_WEAPON2 then
        return nil
    end

    return self:GetEquip(EquipBarType)
end

-------------------------------------------------------------------------
-- 判断状态接口
-------------------------------------------------------------------------
-- 是否为第一人称
function BP_CharacterEquipComponent_C:IsFiring()
    return self.bWantsToFire
end

function BP_CharacterEquipComponent_C:IsRifle()
    return (self.CurrentEquip.EquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON1 or 
        self.CurrentEquip.EquipBarType == Ds_EquipBarType.EQUIPBARTYPE_WEAPON2) and true or false;
end

function BP_CharacterEquipComponent_C:IsPendingReload()

    if self.CurrentEquip and self.CurrentEquip.EquipActor then
        local Equip = self.CurrentEquip.EquipActor:Cast(UE4.ABP_EquipBase_C)
        return Equip and Equip:IsPendingReload()
    end

    return false
end

return BP_CharacterEquipComponent_C
