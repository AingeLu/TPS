require "UnLua"

local BP_ImpactEffect_C = Class()

function BP_ImpactEffect_C:ReceiveBeginPlay()
    local HitPhysMat = nil
    if self.SurfaceHit then
       HitPhysMat = self.SurfaceHit.PhysMaterial;
    end

    local HitSurfaceType = HitPhysMat and HitPhysMat.SurfaceType or UE4.EPhysicalSurface.SurfaceType_Default

    -- show particles
    local ImpactFX = self:GetImpactFX(HitSurfaceType)
    if ImpactFX then
        --local DefalutNormal = UE4.FVector(0, 0, 1)
        --local DefaultRotator = DefalutNormal:ToRotator()
        local DefaultRotator = UE4.FRotator(90, 0, 0)
        local ImpactRotator = self.SurfaceHit.ImpactNormal:ToRotator()
        local NeedRotator = ImpactRotator - DefaultRotator  -- 需要旋转的角度
        UE4.UGameplayStatics.SpawnEmitterAtLocation(self, ImpactFX, self:K2_GetActorLocation(), NeedRotator)
    end

    -- play sound
    local ImpactSound = self:GetImpactSound(HitSurfaceType)
    if ImpactSound then
        UE4.UGameplayStatics.PlaySoundAtLocation(self, ImpactSound, self:K2_GetActorLocation())
    end

    if self.SurfaceHit and self.SurfaceHit.Component then
        local ImpactDecal = self:GetImpactDecal(HitSurfaceType)
        if ImpactDecal and ImpactDecal.DecalMaterial then
            local RandomDecalRotation = self.SurfaceHit.ImpactNormal:ToRotator()
            RandomDecalRotation.Roll = math.random(-180.0, 180.0)

            UE4.UGameplayStatics.SpawnDecalAttached(ImpactDecal.DecalMaterial,
                    UE4.FVector(ImpactDecal.DecalSize, ImpactDecal.DecalSize, ImpactDecal.DecalSize),
                    self.SurfaceHit.Component, self.SurfaceHit.BoneName, self.SurfaceHit.ImpactPoint,
                    RandomDecalRotation, UE4.EAttachLocation.KeepWorldPosition, ImpactDecal.LifeSpan)
        end
    end

    self:SetLifeSpan(1.0)
end

--- @params (TEnumAsByte<EPhysicalSurface> )
function BP_ImpactEffect_C:GetImpactFX(SurfaceType)
	local ImpactFX = nil

        if SurfaceType == UE4.EPhysicalSurface.SurfaceType1 then
            ImpactFX = self.ConcreteFX
        elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType2 then
            ImpactFX = self.DirtFX
        elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType3 then
            ImpactFX = self.WaterFX
        elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType4 then
            ImpactFX = self.MetalFX
        elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType5 then
            ImpactFX = self.WoodFX
        elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType6 then
            ImpactFX = self.GrassFX
        elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType7 then
            ImpactFX = self.GlassFX
        elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType8 then
            ImpactFX = self.FleshFX
        else
            ImpactFX = self.DefaultFX
        end

	return ImpactFX
end

--- @params (TEnumAsByte<EPhysicalSurface> )
function BP_ImpactEffect_C:GetImpactSound(SurfaceType)
	local ImpactSound = nil

    if SurfaceType == UE4.EPhysicalSurface.SurfaceType1 then
        ImpactSound = self.ConcreteSound
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType2 then
		ImpactSound = self.DirtSound
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType3 then
        ImpactSound = self.WaterSound
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType4 then
        ImpactSound = self.MetalSound
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType5 then
        ImpactSound = self.WoodSound
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType6 then
        ImpactSound = self.GrassSound
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType7 then
        ImpactSound = self.GlassSound
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType8 then
        ImpactSound = self.FleshSound
    else
        ImpactSound = self.DefaultSound
	end

	return ImpactSound
end

--- @params (TEnumAsByte<EPhysicalSurface> )
function BP_ImpactEffect_C:GetImpactDecal(SurfaceType)
    local ImpactDecal = nil

    if SurfaceType == UE4.EPhysicalSurface.SurfaceType1 then
        ImpactDecal = self.ConcreteDecal
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType2 then
        ImpactDecal = self.DirtDecal
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType3 then
        ImpactDecal = self.WaterDecal
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType4 then
        ImpactDecal = self.MetalDecal
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType5 then
        ImpactDecal = self.WoodDecal
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType6 then
        ImpactDecal = self.GrassDecal
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType7 then
        ImpactDecal = self.GlassDecal
    elseif SurfaceType == UE4.EPhysicalSurface.SurfaceType8 then
        ImpactDecal = self.FleshDecal
    else
        ImpactDecal = self.DefaultDecal
    end

    return ImpactDecal
end

return BP_ImpactEffect_C
