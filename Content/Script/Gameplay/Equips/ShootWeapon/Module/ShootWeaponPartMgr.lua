require "UnLua"

local ShootWeaponModule = require "Gameplay/Equips/ShootWeapon/Module/ShootWeaponModule"

local ShootWeaponPartMgr = class("ShootWeaponPartMgr", ShootWeaponModule)

-- 构造函数
function ShootWeaponPartMgr:ctor()
	ShootWeaponPartMgr.super.ctor(self)
    
end

-- 创建
function ShootWeaponPartMgr:OnCreate(ShootWeapon)
	ShootWeaponPartMgr.super.OnCreate(self, ShootWeapon)

end

-- 销毁
function ShootWeaponPartMgr:OnDestroy()
	ShootWeaponPartMgr.super.OnDestroy(self)

end

function ShootWeaponPartMgr:AddPart(iPartBarType, iResID)

end

return ShootWeaponPartMgr