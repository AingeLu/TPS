require "UnLua"

local BP_ShooterPlayerCameraManagerBase_C = Class()

function BP_ShooterPlayerCameraManagerBase_C:Initialize(Initializer)
    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------
    self.NormalFOV = 90.0
end

--function BP_ShooterPlayerCameraManagerBase_C:UserConstructionScript()
--end

function BP_ShooterPlayerCameraManagerBase_C:ReceiveBeginPlay()    
    self.ViewPitchMin = -60.0
    self.ViewPitchMax = 60.0
end

--function BP_ShooterPlayerCameraManagerBase_C:ReceiveEndPlay()
--end

function BP_ShooterPlayerCameraManagerBase_C:ReceiveTick(DeltaSeconds)
   
end

--function BP_ShooterPlayerCameraManagerBase_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function BP_ShooterPlayerCameraManagerBase_C:ReceiveActorBeginOverlap(OtherActor)
--end

--function BP_ShooterPlayerCameraManagerBase_C:ReceiveActorEndOverlap(OtherActor)
--end

function BP_ShooterPlayerCameraManagerBase_C:Lua_BlueprintUpdateCamera(CharacterBase)
   
    --APlayerCameraManager::UpdateViewTargetInternal
    --下蹲 未瞄准
    if CharacterBase.CharacterMovementComponent:IsCrouching() and not CharacterBase:IsWeaponAim() then
        local Location = CharacterBase.TPPCamera:K2_GetComponentLocation()
        local Rotation = CharacterBase.TPPCamera:K2_GetComponentRotation()
        local Offset = CharacterBase.CapsuleHalfHeight_Config  -CharacterBase.CharacterMovement.CrouchedHalfHeight
        Location = Location + UE4.FVector(0, 0, Offset);
        return true, Location, Rotation,self:GetFOVAngle()
    end

    return false, UE4.FVector(), UE4.FRotator(), 0
end

return BP_ShooterPlayerCameraManagerBase_C
