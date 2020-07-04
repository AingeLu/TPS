--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local BP_ShootWeaponPartComponent_C = Class()

function BP_ShootWeaponPartComponent_C:Initialize(Initializer)
    -- 同步属性: 配件列表
    -- self.Parts
end

function BP_ShootWeaponPartComponent_C:OnInit()
    -- 初始化装备数组
    self.Parts:Resize(Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_MAX)
    for iPartBarType = Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_NONE + 1, Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_MAX do
        self.Parts:Set(iPartBarType, nil)
    end

    self:InitParts()
end

function BP_ShootWeaponPartComponent_C:OnUnInit()
    for iPartBarType = Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_NONE + 1, Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_MAX do
        local Part = self.Parts:Get(iPartBarType)
        if Part then
            --Part:K2_DestroyActor()
            Part:OnUnInit()
        end
    end
end

function BP_ShootWeaponPartComponent_C:InitParts()
    --local ShootWeapon = self:GetOwner():Cast(UE4.ABP_ShootWeapon_C)
    --print("----------------------- ShootWeapon:GetLocalRole() ", ShootWeapon:GetLocalRole())
    --if not ShootWeapon or not ShootWeapon:HasAuthority() then
    --    return
    --end

    -- 弹夹
    if self.PartClass_Clip and self.PartSocket_Clip then
        self:AddPart(Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_CLIP, self.PartClass_Clip, self.PartSocket_Clip)
    end
end

function BP_ShootWeaponPartComponent_C:AddPart(iPartBarType, PartClass, PartSocket)
    local ShootWeapon = self:GetOwner():Cast(UE4.ABP_ShootWeapon_C)
    if not ShootWeapon or not ShootWeapon.ShootWeaponPartMgr then
        return
    end

    local PartActor = self:SpawnPartActor(PartClass)
    if PartActor then
        PartActor:OnInit(ShootWeapon, PartSocket)

        self.Parts:Set(iPartBarType, PartActor)

        ShootWeapon.ShootWeaponPartMgr:AddPart(Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_CLIP)
    end
end

function BP_ShootWeaponPartComponent_C:GetPart(iPartBarType)
    return self.Parts and self.Parts:Get(iPartBarType) or nil
end


-------------------------------------------------------------------------
-- Animation Notify
-------------------------------------------------------------------------
function BP_ShootWeaponPartComponent_C:HandleAttachMagin()
    local ShootWeapon = self:GetOwner():Cast(UE4.ABP_ShootWeapon_C)
    if not ShootWeapon or not ShootWeapon.CharacterBase then
        return
    end

    local Part_Clip = self:GetPart(Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_CLIP)
    if Part_Clip then
        Part_Clip:AttachMeshToPawn(ShootWeapon.CharacterBase.Mesh1P, ShootWeapon.CharacterBase.Mesh, self.PartSocket_Clip)
    end
end

function BP_ShootWeaponPartComponent_C:HandleAttachMagout()
    local ShootWeapon = self:GetOwner():Cast(UE4.ABP_ShootWeapon_C)
    if not ShootWeapon then
        return
    end

    local Part_Clip = self:GetPart(Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_CLIP)
    if Part_Clip then
        Part_Clip:AttachMeshToPawn(ShootWeapon.Mesh1P, ShootWeapon.Mesh3P, self.PartSocket_Clip)
    end
end

-------------------------------------------------------------------------
-- Replicated Notify
-------------------------------------------------------------------------
-- 装备配件同步
function BP_ShootWeaponPartComponent_C:OnRep_Parts()

end


-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------
-- 获取装备管理器
function BP_ShootWeaponPartComponent_C:GetShootWeaponPartMgr()
    local ShootWeapon = self:GetOwnerShootWeapon()
    if not ShootWeapon then
        return nil
    end

    return ShootWeapon.ShootWeaponPartMgr
end

function BP_ShootWeaponPartComponent_C:GetOwnerShootWeapon()
    return self:GetOwner() and self:GetOwner():Cast(UE4.ABP_ShootWeapon_C) or nil
end

-------------------------------------------------------------------------
-- 辅助接口
-------------------------------------------------------------------------
-- 孵化配件
-- @Params: (Ds_EquipBarType)
-- @Return: BP_EquipBase_C
function BP_ShootWeaponPartComponent_C:SpawnPartActor(PartClass)
    local SpawnTransform = UE4.FTransform()
    local PartActor = UE4.UGameplayStatics.BeginDeferredActorSpawnFromClass(self, PartClass, SpawnTransform)
    if PartActor then
        UE4.UGameplayStatics.FinishSpawningActor(PartActor, SpawnTransform)

        return PartActor:Cast(UE4.ABP_ShootWeaponPartBase_C)
    end

    return nil
end


return BP_ShootWeaponPartComponent_C
