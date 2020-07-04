require "UnLua"

---@type AHUD
local BP_ShooterPlayerHUD_C = Class()

--- Module
local AimAssistMgr = require("Gameplay/Levels/Debug/Module/AimAssistMgr")


function BP_ShooterPlayerHUD_C:Initialize(Initializer)
    print("||BP_ShooterPlayerHUD_C:Initialize ... ...")

    -------------------------------------------------------------------------
    --- Lua中定义的变量
    -------------------------------------------------------------------------
    self.newMat = nil    
end

function BP_ShooterPlayerHUD_C:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)
    print("|| BP_ShooterPlayerHUD_C:ReceiveBeginPlay ... ...")

    self:OnCreatLowHpIndicator()
end

function BP_ShooterPlayerHUD_C:UserConstructionScript()
    --self.Overridden.UserConstructionScript(self)

    --- 自动开火辅助瞄准
    self.AimAssistMgr = AimAssistMgr.new()
    self.AimAssistMgr:OnCreate(self)
end

function BP_ShooterPlayerHUD_C:ReceiveDrawHUD()
    self.Overridden.ReceiveDrawHUD(self)

    local  character = self:GetOwningPawn()
    if character ~= nil and character:IsAlive() and character:IsValid() then
        self.Canvas:PopSafeZoneTransform()   

        local ScaleRatio =  self.Canvas.ClipY / RESOLUTIONFACTOR_HEIGHT
        character:DrawHitIndicator(self.Canvas,ScaleRatio)
        if self.newMat then
            character:DrawLowHPIndicator(self.newMat)
        end
        
        local CurEquipBarType = character.EquipComponent:GetCurEquipBarType()
        local CurShootWeapon = character.EquipComponent:GetWeaponByBarType(CurEquipBarType)
        if not UE4.UKismetSystemLibrary.IsValid(CurShootWeapon)  then
            return
        end

        if CurShootWeapon ~= nil and CurShootWeapon.DrawCrosshair ~= nil then
            local bCanHit = true
            if character:IsCovering() and not character:IsWeaponAim() then
                bCanHit = false
            end
            CurShootWeapon:DrawCrosshair(self.Canvas,ScaleRatio,bCanHit,true,true,self.AimAssistMgr.AimObjectState)
        end
        
        self.Canvas:ApplySafeZoneTransform()
    end
end


--function BP_ShooterPlayerHUD_C:ReceiveEndPlay()
--end

function BP_ShooterPlayerHUD_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self , DeltaSeconds)

    if self.AimAssistMgr ~= nil then
        self.AimAssistMgr:Tick(DeltaSeconds)
    end
end

--function BP_ShooterPlayerHUD_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function BP_ShooterPlayerHUD_C:ReceiveActorBeginOverlap(OtherActor)
--end

--function BP_ShooterPlayerHUD_C:ReceiveActorEndOverlap(OtherActor)
--end

function BP_ShooterPlayerHUD_C:ReceiveDestroyed()
    self.Overridden.ReceiveDestroyed(self)
    print("BP_ShooterPlayerHUD_C:ReceiveDestroyed ...")
    if self.AimAssistMgr ~= nil then
        self.AimAssistMgr:OnDestroy()
    end

    LUIManager:DestroyAllWindow()
end

-----------------------------------------
--- IS 判断接口
-----------------------------------------

function BP_ShooterPlayerHUD_C:IsAimSlowMode()
    if self.AimAssistMgr then
        return self.AimAssistMgr:IsAimTurnSlowDown()
    end

    return false
end


-----------------------------------------
--- Getter 获取数据接口
-----------------------------------------

function BP_ShooterPlayerHUD_C:GetMouseMovSensitivityScale()
    local mouseMovSensitivityScale = 1.0

    if self:IsValid() then
        mouseMovSensitivityScale = self.Owner.FrictionSpeed
    end

    return mouseMovSensitivityScale
end

-- 创建低血量提示材质
function BP_ShooterPlayerHUD_C:OnCreatLowHpIndicator()
    self.newMat = UE4.UMGLuaUtils.UMG_GetMaterial("Material'/Game/Effects/Materials/Additional/f1_blood_01.f1_blood_01'", self)
    if self.newMat then
        self.newMat:SetScalarParameterValue("Opacity" ,0)
        local Weight = UE4.FWeightedBlendable()
        Weight.Object = self.newMat
        Weight.Weight = 1
        self.LowHPIndicator.Settings.WeightedBlendables.Array:Add(Weight)
    end
end

return BP_ShooterPlayerHUD_C
