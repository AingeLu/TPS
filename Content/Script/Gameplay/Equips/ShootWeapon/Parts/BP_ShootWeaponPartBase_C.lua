--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local BP_ShootWeaponPartBase_C = Class()

--function BP_ShootWeaponPartBase_C:Initialize(Initializer)
--end

--function BP_ShootWeaponPartBase_C:UserConstructionScript()
--end

--function BP_ShootWeaponPartBase_C:ReceiveBeginPlay()
--end

--function BP_ShootWeaponPartBase_C:ReceiveEndPlay()
--end

-- function BP_ShootWeaponPartBase_C:ReceiveTick(DeltaSeconds)
-- end

--function BP_ShootWeaponPartBase_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function BP_ShootWeaponPartBase_C:ReceiveActorBeginOverlap(OtherActor)
--end

--function BP_ShootWeaponPartBase_C:ReceiveActorEndOverlap(OtherActor)
--end

function BP_ShootWeaponPartBase_C:OnInit(ShootWeapon, AttachPoint)
    self.ShootWeapon = ShootWeapon

    self:AttachMeshToPawn(ShootWeapon.Mesh1P, ShootWeapon.Mesh3P, AttachPoint)
    self:UpdateMeshes()
end

function BP_ShootWeaponPartBase_C:OnUnInit()
    self:SetLifeSpan(0.2)
end

-- @params: (FName)
function BP_ShootWeaponPartBase_C:AttachMeshToPawn(Parent1P, Parent3P, AttachPoint)
    self.Mesh1P:K2_AttachToComponent(Parent1P, AttachPoint, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, true)
    self.Mesh1P:SetHiddenInGame(true)

    self.Mesh3P:K2_AttachToComponent(Parent3P, AttachPoint, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, true)
    self.Mesh3P:SetHiddenInGame(false)
end

function BP_ShootWeaponPartBase_C:DetachMeshFromPawn()
    self.Mesh1P:K2_DetachFromComponent(UE4.EAttachmentRule.KeepRelative)
    self.Mesh1P:SetHiddenInGame(true)

    self.Mesh3P:K2_DetachFromComponent(UE4.EAttachmentRule.KeepRelative)
    self.Mesh3P:SetHiddenInGame(true)
end

function BP_ShootWeaponPartBase_C:UpdateMeshes()
    if self.ShootWeapon then

        local CharacterBase = self.ShootWeapon:GetOwnerPawn()
        local bFirstPerson = (CharacterBase:IsFirstPerson()) and true or false

        self.Mesh1P.VisibilityBasedAnimTickOption = (not bFirstPerson) and UE4.EVisibilityBasedAnimTickOption.OnlyTickPoseWhenRendered or UE4.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
        self.Mesh1P:SetOwnerNoSee(not bFirstPerson)

        self.Mesh3P.VisibilityBasedAnimTickOption = bFirstPerson and UE4.EVisibilityBasedAnimTickOption.OnlyTickPoseWhenRendered or UE4.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
        self.Mesh3P:SetOwnerNoSee(bFirstPerson)
    end
end

return BP_ShootWeaponPartBase_C
