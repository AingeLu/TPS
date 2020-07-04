require "UnLua"

local CharacterModule = class("CharacterModule")

-- 构造函数
function CharacterModule:ctor()
    self.Controller = nil;
end

-- 创建
function CharacterModule:OnCreate(AA_Control)
    self.Controller = AA_Control
end

-- 销毁
function CharacterModule:OnDestroy()
    self.Controller = nil
end

-- 获取拥有者的Pawn
-- @Return: BP_ShooterCharacterBase_C
function CharacterModule:GetOwnerPawn()
    if self.Controller then
        local Pawn = self.Controller:K2_GetPawn()
        return Pawn and Pawn:Cast(ABP_ShooterCharacterBase_C) or nil
    end

    return nil
end

return CharacterModule