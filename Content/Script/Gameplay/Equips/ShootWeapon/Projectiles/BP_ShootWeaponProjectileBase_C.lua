require "UnLua"

local BP_ShootWeaponProjectileBase_C = Class()

function BP_ShootWeaponProjectileBase_C:Initialize(Initializer)
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


function BP_ShootWeaponProjectileBase_C:ReceiveBeginPlay()

end

-- @params (FVector, FWeaponProjectileData)
function BP_ShootWeaponProjectileBase_C:OnInit(WeaponBase, Origin, ShootDirection, ShootWeaponConfigData)

    self.WeaponBase = WeaponBase;
    self.Origin = Origin;
    self.ProjectileData = ShootWeaponConfigData.ProjectileData
    self.WeaponRange = ShootWeaponConfigData.WeaponRange;

    self.MovementComp.InitialSpeed = self.ProjectileData.ProjectilePhysicsData.InitialSpeed
    self.MovementComp.MaxSpeed = self.ProjectileData.ProjectilePhysicsData.MaxSpeed
    self.MovementComp.ProjectileGravityScale = self.ProjectileData.ProjectilePhysicsData.ProjectileGravityScale
    self.MovementComp.Velocity = ShootDirection * self.ProjectileData.ProjectilePhysicsData.InitialSpeed

    self.MovementComp.OnProjectileStop:Add(self, BP_ShootWeaponProjectileBase_C.OnImpact)

    if self.StaticMesh then
        self.StaticMesh:SetActive(self.ProjectileData.ProjectilePhysicsData.bShowProjectile)
    end
   
    self:SetLifeSpan(self.DefaultLifespan)

    --print("ReceiveBeginPlay ShootDir X:"..self.MovementComp.Velocity.X..",Y:"..self.MovementComp.Velocity.Y..",Z:"..self.MovementComp.Velocity.Z)
end

-- @params (FHitResult)
function BP_ShootWeaponProjectileBase_C:OnImpact(HitResult)
    if self:HasAuthority() and not self.bImpacted then

        --超过了有效距离
        local flyDistance = math.max(0.1, self.Origin:Dist(self:K2_GetActorLocation()));
        if flyDistance <= self.WeaponRange then
            self.bImpacted = true
            self:ProcessImpacted(HitResult)
            self:SimulateImpactEffect()
        end
        
        local AudioComponent = self:GetComponentByClass(UE4.UAudioComponent.StaticClass)
        if AudioComponent and AudioComponent:IsPlaying() then
            AudioComponent:FadeOut(0.1, 0)
        end

        if self.StaticMesh then
            self.StaticMesh:SetVisibility(false, true)
            self.StaticMesh:SetHiddenInGame(true, true)
        end

        if self.ParticleSystem then
            self.ParticleSystem:Deactivate()
        end

        if self.ProjectileMovement then
            self.ProjectileMovement:StopMovementImmediately()
        end

        -- give clients some time to show effect
        self:SetLifeSpan(self.DestroyLifespan)
    end
end

function BP_ShootWeaponProjectileBase_C:OnRep_bImpacted()
    if self.bImpacted then
        self:SimulateImpactEffect()
        
        if self.StaticMesh then
            self.StaticMesh:SetVisibility(false, true)
            self.StaticMesh:SetHiddenInGame(true, true)
        end

        if self.ParticleSystem then
            self.ParticleSystem:Deactivate()
        end
    end
end

function BP_ShootWeaponProjectileBase_C:ProcessImpacted(HitResult)
    if self:HasAuthority() and self.ProjectileData.DamageType then

        local ProjectileType = self.ProjectileData.ProjectileType
        if ProjectileType == EShootWeaponProjectileType.EShootWeaponProjectileType_Physics then

            local baseDamage = self.ProjectileData.BaseDamage

            if self.ProjectileData.RangeDamageCurve then
                local flyDistance = math.max(1.0, self.Origin:Dist(self:K2_GetActorLocation()));
                local rangeRatio = self.ProjectileData.RangeDamageCurve:GetFloatValue(flyDistance)
                baseDamage = math.floor(baseDamage * rangeRatio);
            end

            for i = 1, #g_CharacterBoneNames do
                if HitResult.BoneName == g_CharacterBoneNames[i] then
                    local BodyType = i - 1
                    -- 根据部位计算伤害
                    if BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_HEAD then
                        baseDamage = math.floor(baseDamage * self.ProjectileData.HeadDamageRatio)
                    elseif BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_NECK then
                        baseDamage = math.floor(baseDamage * self.ProjectileData.NeckDamageRatio)
                    elseif BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_TORSO then
                        baseDamage = math.floor(baseDamage * self.ProjectileData.TorsoDamageRatio)
                    elseif BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_STOMACH then
                        baseDamage = math.floor(baseDamage * self.ProjectileData.StomachDamageRatio)
                    elseif BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_LIMBS then
                        baseDamage = math.floor(baseDamage * self.ProjectileData.LimbsDamageRatio)
                    end
                end
            end

            UE4.UGameplayStatics.ApplyPointDamage(HitResult.Actor, baseDamage, self:GetActorForwardVector(), HitResult,
                    self:GetInstigatorController(), self, self.ProjectileData.DamageType)

            --记录时间 给客户端
            if HitResult.Actor then
                local BeHitCharacter = HitResult.Actor:Cast(UE4.ABP_ShooterCharacterBase_C)
                if  BeHitCharacter and BeHitCharacter:IsAlive() and
                        self.Instigator and BeHitCharacter:GetTeamID() ~= self.Instigator:GetTeamID()  then
                    self.WeaponBase:NotifyWeponHitCharacter();
                end
            end
        end
    end
end

-- 模拟碰撞效果
function BP_ShootWeaponProjectileBase_C:SimulateImpactEffect()
    local ProjDirection = self:GetActorForwardVector()

    local Offset = 30.0
    local StartTrace = self:K2_GetActorLocation() - ProjDirection * Offset
    local EndTrace = self:K2_GetActorLocation() + ProjDirection * Offset

    local HitResult = UE4.FHitResult()
    local ActorsToIgnore = TArray(UE4.AActor)
    ActorsToIgnore:Add(self);
    ActorsToIgnore:Add(self.Instigator);

    if not UE4.UKismetSystemLibrary.SphereTraceSingle(self:GetWorld(), StartTrace, EndTrace, self.SphereRadius,
            UE4.ETraceTypeQuery.Weapon, false, ActorsToIgnore, UE4.EDrawDebugTrace.None, HitResult, true) then
        -- failsafe
        HitResult.ImpactPoint = self:K2_GetActorLocation()
        HitResult.ImpactNormal = -self:GetActorForwardVector()
    end

    if self.ImpactEffectClass then
        local Rotation = UE4.UKismetMathLibrary.Conv_VectorToRotator(HitResult.ImpactNormal)
        local SpawnTransform = UE4.FTransform(Rotation:ToQuat(), HitResult.ImpactPoint)
        local ImpactEffectActor = UE4.UGameplayStatics.BeginDeferredActorSpawnFromClass(self, self.ImpactEffectClass, SpawnTransform)
        if ImpactEffectActor then
            ImpactEffectActor.SurfaceHit = HitResult
            UE4.UGameplayStatics.FinishSpawningActor(ImpactEffectActor, SpawnTransform)
        end
    end

    if self.ImpactSound_2D and self.Instigator and self.Instigator:IsLocallyControlled() and HitResult.Actor then
        local BeHitCharacter = HitResult.Actor:Cast(UE4.ABP_ShooterCharacterBase_C)
        if  BeHitCharacter and self.Instigator and BeHitCharacter:GetTeamID() ~= self.Instigator:GetTeamID()  then
            UE4.UGameplayStatics.PlaySound2D(self,self.ImpactSound_2D)
        end
    end
end

return BP_ShootWeaponProjectileBase_C
