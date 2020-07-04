require "UnLua"

local ShootWeaponModule = class("ShootWeaponModule")

-- 构造函数
function ShootWeaponModule:ctor()
    self.ShootWeapon = nil
end

-- 创建
function ShootWeaponModule:OnCreate(AA_ShootWeapon)
    self.ShootWeapon = AA_ShootWeapon
end

-- 销毁
function ShootWeaponModule:OnDestroy()
    self.ShootWeapon = nil
end

-- 获取拥有者的Pawn
-- @Return: BP_ShooterCharacterBase_C
function ShootWeaponModule:GetOwnerPawn()
    return self.ShootWeapon and self.ShootWeapon:GetOwnerPawn() or nil
end

function ShootWeaponModule:GetOwnerController()
    return self.ShootWeapon and self.ShootWeapon:GetOwnerController() or nil
end


return ShootWeaponModule