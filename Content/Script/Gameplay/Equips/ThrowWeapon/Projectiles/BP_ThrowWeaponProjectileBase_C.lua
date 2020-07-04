require "UnLua"

local BP_ThrowWeaponProjectileBase_C = Class()

function BP_ThrowWeaponProjectileBase_C:Initialize(Initializer)
    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------
    -- self.bImpacted

    self.DefaultLifespan = 5.0
    self.DestroyLifespan = 0.5

    -------------------------------------------------------------------------
    --- Lua中定义的变量
    -------------------------------------------------------------------------
    self.ProjectileData = nil
end


function BP_ThrowWeaponProjectileBase_C:ReceiveBeginPlay()

end

function BP_ThrowWeaponProjectileBase_C:ReceiveEndPlay()
end


function BP_ThrowWeaponProjectileBase_C:ReceiveTick(DeltaSeconds)

    if self:HasAuthority() then
        if not self.bExplode and self.WeaponBase and self.WeaponBase:CanAutoExplode()  then

           -- print("ReceiveTick ProcessExplode===========")
           -- self:OnExplode();
        end
    end
end

function BP_ThrowWeaponProjectileBase_C:OnInit(WeaponBase, Origin, ShootDirection, ProjectileData)

    self.WeaponBase = WeaponBase;
    self.bExplode = false;
    self.ProjectileData = ProjectileData

    self.MovementComp.InitialSpeed = self.ProjectileData.InitialSpeed
    self.MovementComp.MaxSpeed = self.ProjectileData.MaxSpeed
    self.MovementComp.ProjectileGravityScale = self.ProjectileData.ProjectileGravityScale
    self.MovementComp.Velocity = ShootDirection * self.ProjectileData.InitialSpeed

    if self.StaticMesh then
        self.StaticMesh:SetActive(self.ProjectileData.bShowProjectile)
    end
   
    self:SetLifeSpan(self.DefaultLifespan)
end

function BP_ThrowWeaponProjectileBase_C:OnExplode()

    if self:HasAuthority() and not self.bExplode then
        
        print("OnExplode!!!")

        self.bExplode = true;
		self:ProcessExplode();
        
        if self.StaticMesh then
            self.StaticMesh:Deactivate()
        end

		self:SetLifeSpan(self.DestroyLifespan);
    end
end

---------------------RPC=================
function BP_ThrowWeaponProjectileBase_C:OnRep_bExplode()

    if self.bExplode then  
        self:ProcessExplode();

        print("OnExplode!!!")
        
        if self.StaticMesh then
            self.StaticMesh:Deactivate()
        end

    end
end



function BP_ThrowWeaponProjectileBase_C:ProcessExplode()


    print("ProcessExplode===========")

	if self:HasAuthority() then
		if self.ProjectileData.ExplosionDamage > 0 and self.ProjectileData.ExplosionRadius > 0  then
        
            --TODO
            UE4.UGameplayStatics.ApplyRadialDamage(self, self.ProjectileData.ExplosionDamage, self:K2_GetActorLocation(), 
                self.ProjectileData.ExplosionRadius,
				self.ProjectileData.DamageType, nil, self, nil);
        end
    end

	if self.RadialForce then
		self.RadialForce:FireImpulse();
    end

	local ProjDirection = self:GetActorForwardVector();

	local Offset = 150.0;
	local StartTrace = self:K2_GetActorLocation() - ProjDirection * Offset;
	local EndTrace = self:K2_GetActorLocation() + ProjDirection * Offset;

    local HitResult = UE4.FHitResult();
    local ActorsToIgnore = TArray(UE4.AActor)
    ActorsToIgnore:Add(self);
    ActorsToIgnore:Add(self.Instigator);

    if not UE4.UKismetSystemLibrary.SphereTraceSingle(self:GetWorld(), StartTrace, EndTrace, self.SphereRadius, 
        UE4.ETraceTypeQuery.Weapon, false, ActorsToIgnore, UE4.EDrawDebugTrace.None, HitResult, true) then

        HitResult.ImpactPoint = self:K2_GetActorLocation();
        HitResult.ImpactNormal = -self:GetActorForwardVector();
    end


	local NudgedImpactLocation = HitResult.ImpactPoint + HitResult.ImpactNormal * 10.0;

	if self.ExplosionTemplate then
	
        local SpawnTransform = UE4.FTransform(HitResult.ImpactNormal:ToQuat(), HitResult.ImpactPoint);
        
        local ImpactEffectActor = UE4.UGameplayStatics.BeginDeferredActorSpawnFromClass(self, self.ExplosionTemplate, SpawnTransform)
        if ImpactEffectActor then
            ImpactEffectActor.SurfaceHit = HitResult
            UE4.UGameplayStatics.FinishSpawningActor(ImpactEffectActor, SpawnTransform)
        end

    end
end


return BP_ThrowWeaponProjectileBase_C
