require "UnLua"

local BP_ShootWeaponFireComponent_C = Class()

function BP_ShootWeaponFireComponent_C:Initialize(Initializer)
    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------
    -- 配置数据:

    -- 属性同步: 开火计数
    -- self.FireCounter
    -- self.PendingReload  --装弹状态

    -------------------------------------------------------------------------
    --- Lua中定义的变量
    -------------------------------------------------------------------------
    self.bWantsToFire = false
    self.LastFireTime = 0
    self.PullBoltTime = 0
    self.CurrentFiringSpread = 0 --散射
    self.MoveBackSpreadInc = 0

    self.TimerHandle_HandleFiring = nil
    self.TimerHandle_StartReload = nil
    self.TimerHandle_StopSimulatingWeaponFire_Effect = nil

    self.MuzzlePSC = nil
    self.MuzzlePSCSecondary = nil

    self.FireAnimTime = 0.2
    self.bPlayingFireAnim = false

    self.FireAudioComponent = nil
end

function BP_ShootWeaponFireComponent_C:OnInit()

    --填充默认子弹 
    local ShootWeaponBase = self:GetOwner():Cast(UE4.ABP_ShootWeapon_C)
    if  ShootWeaponBase and ShootWeaponBase:HasAuthority() then
        self.CurrentAmmoInClip = ShootWeaponBase:GetAmmoPerClip();
        self.CurrentAmmo = ShootWeaponBase.WeaponConfigData.InitAmmo;
    end

    self.ShootWeaponBase = ShootWeaponBase;
end

function BP_ShootWeaponFireComponent_C:ReceiveTick(DeltaSeconds)
    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return 
    end

    local Velocity = ShootWeaponBase.CharacterBase.CharacterMovement:GetVelocity():Size()

    self:MovingAffectSpread()

     -- 散射值恢复
    if self.CurrentFiringSpread > 0.1 and ShootWeaponBase and ShootWeaponBase.CharacterBase and 
        ShootWeaponBase.CharacterBase:IsLocallyControlled() then    
        self.CurrentFiringSpread = self.CurrentFiringSpread - ShootWeaponBase.WeaponConfigData.FiringBackSpreadInc * DeltaSeconds ;       
        self.CurrentFiringSpread  = math.max(0.0, self.CurrentFiringSpread);
    elseif self.CurrentFiringSpread <= 0.1 then
        self.MoveBackSpreadInc = 0
    end

     -- 移动散射恢复
    if Velocity == 0 and self.bWantsToFire == false then
        self.CurrentFiringSpread = self.CurrentFiringSpread - self.MoveBackSpreadInc * DeltaSeconds;
        self.CurrentFiringSpread  = math.max(0.0, self.CurrentFiringSpread);
    end
end

function BP_ShootWeaponFireComponent_C:StartFire()

    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase and ShootWeaponBase:CanFire() and not self.bWantsToFire then

        self.bWantsToFire = true

        if ShootWeaponBase.CharacterBase:IsLocallyControlled() then

            local curWroldTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
            local FireCD = math.max(self.PullBoltTime, ShootWeaponBase:GetTimeBetweenOnceShots())
           
            if self.LastFireTime > 0 and FireCD > 0 and (self.LastFireTime + FireCD) > curWroldTime then

                local FireInterval = (self.LastFireTime + FireCD) - curWroldTime;
                self.TimerHandle_HandleFiring = UE4.UKismetSystemLibrary.K2_SetTimerDelegate(
                    {self, BP_ShootWeaponFireComponent_C.HandleFiring}, FireInterval, false)
            else
               
                self:HandleFiring()
            end

            if ShootWeaponBase.RecoilComponent then
                ShootWeaponBase.RecoilComponent:StartShootRecoil()
            end
        end

        -- 本地客户端调用远程服务器
        if not ShootWeaponBase:HasAuthority() then
            self:ServerStartFire()
        end

    else
        
        if self:GetCurrentAmmoInClip() <= 0  then
            self:PlayFireSound(ShootWeaponBase.FireNoAmmoSound)
        end
    end
    
end

function BP_ShootWeaponFireComponent_C:StopFire()
    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase == nil then
        return;
    end

    if not self.bWantsToFire then
        return;
    end
    
    self.bWantsToFire = false
    self.FireCounter = 0

    self:StopFireWeapon_Locally();
   
    -- 本地客户端调用远程服务器
    if not ShootWeaponBase:HasAuthority() then
        self:ServerStopFire()
    end

end

function BP_ShootWeaponFireComponent_C:HandleFiring()
    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return
    end

    local bCanFire = true;
    local bRefiring = false;
    self.MoveBackSpreadInc = 0;

    if ShootWeaponBase:CanFire() then
        
        self.LastFireTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
        self.FireCounter = self.FireCounter + 1;
        self.CurrentFiringSpread = math.min(ShootWeaponBase.WeaponConfigData.FiringSpreadMax, 
            self.CurrentFiringSpread + ShootWeaponBase.WeaponConfigData.FiringSpreadIncrement);
        
        local ProjectileType = ShootWeaponBase.WeaponConfigData.ProjectileData.ProjectileType

        --蓝图RPC
        for i = 1, ShootWeaponBase.WeaponConfigData.SingleShootNumber do

            local Physics_Origin, Physics_ShootDir, RayImpactPoint, Ray_Origin, Ray_ShootDir = self:GetProjectile_FireInfo(ShootWeaponBase)

            self:ServerStartFireWeapon(Physics_Origin, Physics_ShootDir, i==1 and true or false)

            if ProjectileType == EShootWeaponProjectileType.EShootWeaponProjectileType_Ray then
                --客户端表现
                if not ShootWeaponBase:HasAuthority()  then
                    self:Ray_ProcessImpacted(Ray_Origin, Ray_ShootDir);  
                end
            end

            --开枪蓝图事件
            if i==1 then
                ShootWeaponBase:LocalHandleFiringEvent(Physics_Origin, RayImpactPoint)
            end
          
        end

        self:SimulateWeaponFire_Effect()

    else
        --子弹不够
        if self:GetCurrentAmmoInClip() <= 0  then
            self:PlayFireSound(ShootWeaponBase.FireNoAmmoSound)
        end

        bCanFire = false;
    end

      --自动装弹    
    self:StartAutoReload();

    if bCanFire then

        --射击间隔时间
        local timeBetweenShots = ShootWeaponBase:GetTimeBetweenContinueShots();
        local ShootType =  ShootWeaponBase.WeaponConfigData.ShootType;
    
        if ShootType == EWeaponShootType.EShootType_Single then

        elseif ShootType == EWeaponShootType.EShootType_Continue then

            if self.FireCounter < ShootWeaponBase.WeaponConfigData.ShootContinueNumber and self:GetCurrentAmmoInClip() > 0 then

                bRefiring = (self.bWantsToFire and timeBetweenShots > 0.0) and true or false
                if bRefiring then
                    self.TimerHandle_HandleFiring = UE4.UKismetSystemLibrary.K2_SetTimerDelegate(
                        {self, BP_ShootWeaponFireComponent_C.HandleFiring}, timeBetweenShots, false)
                end

            end

        elseif ShootType == EWeaponShootType.EShootType_Automatic then

            bRefiring = (self.bWantsToFire and timeBetweenShots > 0.0 and self:GetCurrentAmmoInClip() > 0) and true or false
            if bRefiring then
                self.TimerHandle_HandleFiring = UE4.UKismetSystemLibrary.K2_SetTimerDelegate(
                    {self, BP_ShootWeaponFireComponent_C.HandleFiring}, timeBetweenShots, false)
            end
        
        end
    end

    --停止射击
    if not bCanFire or not bRefiring then
        self:StopFireWeapon_Server();
        self:StopFireWeapon_Locally();
    end
end

--开始武器射击(服务器)
function BP_ShootWeaponFireComponent_C:StartFireWeapon(Origin, ShootDir,bOnce)

    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return
    end

    if ShootWeaponBase:HasAuthority() then
        self:SpawnProjectile(Origin, ShootDir);

        local ProjectileType = ShootWeaponBase.WeaponConfigData.ProjectileData.ProjectileType
        if ProjectileType == EShootWeaponProjectileType.EShootWeaponProjectileType_Ray then
            -- 服务器计算伤害和表现
            self:Ray_ProcessImpacted(Origin, ShootDir);
        end

        if bOnce then
            self:RemoveAmmoInClip(1);
            self.FireCounter = self.FireCounter + 1
        end
    end
end

--停止射击(RPC)
function BP_ShootWeaponFireComponent_C:StopFireWeapon_Server()
   
    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase  then
        return
    end


    if not ShootWeaponBase:HasAuthority() then
        self:ServerStopFireWeapon_Server();
    else
        self.FireCounter = 0;
    end

end

--停止射击(RPC)
function BP_ShootWeaponFireComponent_C:StopFireWeapon_Locally()
   
    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase  then
        return
    end

    if ShootWeaponBase.CharacterBase:IsLocallyControlled() then

        local ShootType =  ShootWeaponBase.WeaponConfigData.ShootType;

        if ShootType == EWeaponShootType.EShootType_Single then

            --单次射击 表现消失 延迟
            local  elapsedTime =  UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld()) -  self.LastFireTime;
            if elapsedTime >= self.FireAnimTime then  
                self:StopSimulatingWeaponFire_Effect()
            else
                local NeedTime = math.max(0.2, self.FireAnimTime - elapsedTime);
                self.TimerHandle_StopSimulatingWeaponFire_Effect = UE4.UKismetSystemLibrary.K2_SetTimerDelegate(
                    {self, BP_ShootWeaponFireComponent_C.StopSimulatingWeaponFire_Effect}, NeedTime, false)
            end

            --拉栓
            local WeaponPullBoltAnimation = ShootWeaponBase.CharacterBase:FindAnimationByID(ShootWeaponBase.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_PULLBOLT]);
            if ShootWeaponBase.CharacterBase.CharacterMovementComponent:IsCrouching() then
                WeaponPullBoltAnimation = ShootWeaponBase.CharacterBase:FindAnimationByID(ShootWeaponBase.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_PULLBOLT]);
            end

            if WeaponPullBoltAnimation ~= nil then
                self.PullBoltTime = WeaponPullBoltAnimation.Param1;
                ShootWeaponBase:PlayWeaponAnimation(WeaponPullBoltAnimation.Pawn1P, WeaponPullBoltAnimation.Pawn3P, nil, nil);
            end
        
        elseif ShootType == EWeaponShootType.EShootType_Continue then
            self:StopSimulatingWeaponFire_Effect()
        elseif ShootType == EWeaponShootType.EShootType_Automatic then
            self:StopSimulatingWeaponFire_Effect()
        else
            self:StopSimulatingWeaponFire_Effect()
        end

        UE4.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle_HandleFiring)

        --停止后坐力
        if ShootWeaponBase.RecoilComponent then		
            ShootWeaponBase.RecoilComponent:StopShootRecoil()
        end

    end
end

-- 服务器端使用
function BP_ShootWeaponFireComponent_C:SpawnProjectile(Origin, ShootDir)
    if not Origin or not ShootDir then
        return
    end
    
    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase then
        return
    end

    local ProjectileClass = ShootWeaponBase.WeaponConfigData.ProjectileData.ProjectilePhysicsData.ProjectileClass;
    if ProjectileClass then
       
        local Quat = ShootDir:ToRotator():ToQuat()
        local SpawnTransform = UE4.FTransform(Quat, Origin)

        local Projectile = UE4.UGameplayStatics.BeginDeferredActorSpawnFromClass(self.ShootWeaponBase, ProjectileClass, SpawnTransform)
        if Projectile then
            Projectile:OnInit(ShootWeaponBase, Origin, ShootDir, ShootWeaponBase.WeaponConfigData)

            UE4.UGameplayStatics.FinishSpawningActor(Projectile, SpawnTransform)
        end

    end
end

--射线射击计算
function BP_ShootWeaponFireComponent_C:Ray_ProcessImpacted(Origin, ShootDir)

    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return
    end

    local StartTrace = Origin;
    local EndTrace = StartTrace + ShootDir * ShootWeaponBase.WeaponConfigData.ShootRayRange

    local HitResult = UE4.FHitResult()
    local ActorsToIgnore = TArray(UE4.AActor)
    ActorsToIgnore:Add(self.ShootWeaponBase.CharacterBase);

    local bResult = UE4.UKismetSystemLibrary.LineTraceSingle(self, StartTrace, EndTrace, UE4.ETraceTypeQuery.Weapon, false, ActorsToIgnore,
        UE4.EDrawDebugTrace.None, HitResult, true)
    if not bResult then
        return;
    end

    local WeaponConfigData  = ShootWeaponBase.WeaponConfigData

    if ShootWeaponBase:HasAuthority()  then
        
        if WeaponConfigData.ProjectileData.DamageType then
            
            local baseDamage = WeaponConfigData.ProjectileData.BaseDamage

            if WeaponConfigData.ProjectileData.RangeDamageCurve then
                local flyDistance = math.max(1.0, Origin:Dist(HitResult.ImpactPoint));
                local rangeRatio = WeaponConfigData.ProjectileData.RangeDamageCurve:GetFloatValue(flyDistance)
                baseDamage = math.floor(baseDamage * rangeRatio);
            end

            for i = 1, #g_CharacterBoneNames do
                if HitResult.BoneName == g_CharacterBoneNames[i] then
                    local BodyType = i - 1
                    -- 根据部位计算伤害
                    if BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_HEAD then
                        baseDamage = math.floor(baseDamage * WeaponConfigData.ProjectileData.HeadDamageRatio)
                    elseif BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_NECK then
                        baseDamage = math.floor(baseDamage * WeaponConfigData.ProjectileData.NeckDamageRatio)
                    elseif BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_TORSO then
                        baseDamage = math.floor(baseDamage * WeaponConfigData.ProjectileData.TorsoDamageRatio)
                    elseif BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_STOMACH then
                        baseDamage = math.floor(baseDamage * WeaponConfigData.ProjectileData.StomachDamageRatio)
                    elseif BodyType == Ds_CharacterBodyType.CHARACTERBODYTYPE_LIMBS then
                        baseDamage = math.floor(baseDamage * WeaponConfigData.ProjectileData.LimbsDamageRatio)
                    end
                end
            end

            UE4.UGameplayStatics.ApplyPointDamage(HitResult.Actor, baseDamage, ShootDir, HitResult,
                ShootWeaponBase:GetInstigatorController(), ShootWeaponBase, WeaponConfigData.ProjectileData.DamageType)

            --记录时间 给客户端
            if HitResult.Actor then
                local BeHitCharacter = HitResult.Actor:Cast(UE4.ABP_ShooterCharacterBase_C)
                if  BeHitCharacter and BeHitCharacter:IsAlive() and 
                    ShootWeaponBase.CharacterBase and BeHitCharacter:GetTeamID() ~= ShootWeaponBase.CharacterBase:GetTeamID()  then
                    ShootWeaponBase:NotifyWeponHitCharacter();
                end
            end
        end

    end

    --表现
    if WeaponConfigData.ProjectileData.ProjectileRayData.ImpactEffectClass then
        local Rotation = UE4.UKismetMathLibrary.Conv_VectorToRotator(HitResult.ImpactNormal)
        local SpawnTransform = UE4.FTransform(Rotation:ToQuat(), HitResult.ImpactPoint)
        local ImpactEffectActor = UE4.UGameplayStatics.BeginDeferredActorSpawnFromClass(self,
             WeaponConfigData.ProjectileData.ProjectileRayData.ImpactEffectClass, SpawnTransform)
        if ImpactEffectActor then
            ImpactEffectActor.SurfaceHit = HitResult
            UE4.UGameplayStatics.FinishSpawningActor(ImpactEffectActor, SpawnTransform)
        end
    end

    if WeaponConfigData.ProjectileData.ProjectileRayData.ImpactSound_2D and ShootWeaponBase.CharacterBase:IsLocallyControlled() then
        UE4.UGameplayStatics.PlaySound2D(ShootWeaponBase,WeaponConfigData.ProjectileData.ProjectileRayData.ImpactSound_2D)
    end
   
end

--装弹
function BP_ShootWeaponFireComponent_C:StartReload()
    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase == nil or ShootWeaponBase.CharacterBase == nil then
        return;
    end

    if not ShootWeaponBase:CanReload() then
        return;
    end

    if not ShootWeaponBase:HasAuthority() then
        --蓝图
        self:ServerStartReload();
    end

    self.PendingReload = true;

    local ReloadInterval = self:SimulateWeaponReload_Effect();
    ReloadInterval = math.max(0.2, ReloadInterval)


    self.TimerHandle_StartReload = UE4.UKismetSystemLibrary.K2_SetTimerDelegate(
                        {self, BP_ShootWeaponFireComponent_C.HandleReload}, ReloadInterval, false)

    -- 在掩体中开启瞄准镜了, 换弹的时候关闭瞄准镜
    if ShootWeaponBase.CharacterBase:IsCovering() and ShootWeaponBase.CharacterBase:IsWeaponAim() then
        ShootWeaponBase.CharacterBase:Aim_Pressed()
    end
end

function BP_ShootWeaponFireComponent_C:StopReload()
    if self.PendingReload then
        self.PendingReload = false;

        UE4.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle_StartReload)

        self:StopSimulateWeaponReload_Effect()
    end
end


function BP_ShootWeaponFireComponent_C:HandleReload()

    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase == nil then
        return;
    end

    self.PendingReload = false;

    UE4.UKismetSystemLibrary.K2_ClearTimerHandle(self, self.TimerHandle_StartReload)

    self:StopSimulateWeaponReload_Effect()

    if self.ShootWeaponBase:HasAuthority() then
        local ClipDelta = math.min(self.ShootWeaponBase:GetAmmoPerClip() - self.CurrentAmmoInClip, self.CurrentAmmo);
        if ClipDelta > 0 then
            self.CurrentAmmoInClip = self.CurrentAmmoInClip + ClipDelta;
            self.CurrentAmmo = self.CurrentAmmo - ClipDelta;

            self.ShootWeaponBase:OnEquipData_S()
        end
    end

end

--自动装弹
function BP_ShootWeaponFireComponent_C:StartAutoReload()

    if self:GetCurrentAmmoInClip() <= 0 and self:GetCurrentAmmo() > 0 and 
        self.ShootWeaponBase.CharacterBase and self.ShootWeaponBase.CharacterBase:IsLocallyControlled() then
        self:StartReload();
    end
end


-------------------------------------------------------------------------
-- Replicated Notify
-------------------------------------------------------------------------
-- 开火计数同步
function BP_ShootWeaponFireComponent_C:OnRep_FireCounter()
    if self.FireCounter > 0 then
        self:SimulateWeaponFire_Effect()
    else
        self:StopSimulatingWeaponFire_Effect()
    end
end

function BP_ShootWeaponFireComponent_C:OnRep_PendingReload()
    if self.PendingReload then
        self:SimulateWeaponReload_Effect()
    else
        self:StopSimulateWeaponReload_Effect()
    end
end

function BP_ShootWeaponFireComponent_C:OnRep_CurrentAmmoInClip()
    if self.ShootWeaponBase  then
        self.ShootWeaponBase:OnEquipData_C()
    end

    self:StartAutoReload();
end

function BP_ShootWeaponFireComponent_C:OnRep_CurrentAmmo()
    if self.ShootWeaponBase  then
        self.ShootWeaponBase:OnEquipData_C()
    end
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------
---
function BP_ShootWeaponFireComponent_C:GetCurrentSpread()
    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return 0.0
    end

	local FinalSpread = ShootWeaponBase.WeaponConfigData.WeaponSpread + self.CurrentFiringSpread
	if ShootWeaponBase.CharacterBase:IsWeaponAim() then
		FinalSpread = FinalSpread * ShootWeaponBase.WeaponConfigData.AimingSpreadMod
    end

	return FinalSpread
end

function BP_ShootWeaponFireComponent_C:GetMuzzleLocation()
    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase then
        local UsingMesh = ShootWeaponBase:GetUsingMesh()
        return UsingMesh:GetSocketLocation(ShootWeaponBase.MuzzleAttachPoint)
    end

    return UE4.FVector()
end

function BP_ShootWeaponFireComponent_C:GetMuzzleDirection()
    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase then
        local UsingMesh = ShootWeaponBase:GetUsingMesh()
        return UsingMesh:GetSocketRotation(ShootWeaponBase.MuzzleAttachPoint):ToVector()
    end

    return UE4.FVector()
end

function BP_ShootWeaponFireComponent_C:GetAdjustedAim()
    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase  then
        local PlayerController = ShootWeaponBase:GetOwnerController()
        if PlayerController then
            local CameraRot = PlayerController.PlayerCameraManager:GetCameraRotation()
            return CameraRot:ToVector()
        end

        --=AI
        local AIController = nil;
        if AIController then
            return AIController:GetControlRotation():Vector();
        elseif ShootWeaponBase.CharacterBase then    
            return ShootWeaponBase.CharacterBase:GetBaseAimRotation().Vector();
        end
    end

	return UE4.FVector()
end

function BP_ShootWeaponFireComponent_C:GetCameraDamageStartLocation(AimDir)

    local OutStartTrace = self:GetMuzzleLocation();

    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase and self.ShootWeaponBase.CharacterBase then

        local PlayerController = ShootWeaponBase:GetOwnerController()
        if PlayerController then
      
            local CameraLocation = PlayerController.PlayerCameraManager:GetCameraLocation()
            OutStartTrace = CameraLocation + AimDir * 
		            (self.ShootWeaponBase.CharacterBase:K2_GetActorLocation() - CameraLocation):Dot(AimDir);
        end

    end

	return OutStartTrace;
end

--获取开火信息
function BP_ShootWeaponFireComponent_C:GetProjectile_FireInfo(ShootWeaponBase)

    --散射角度
    local CurrentSpread = self:GetCurrentSpread();

    local AimDir = self:GetAdjustedAim()
    local Origin = self:GetMuzzleLocation()
    local Physics_ShootDir = UE4.FVector();
    
    local StartTrace = self:GetCameraDamageStartLocation(AimDir);
    local ShootDir =  UE4.UKismetMathLibrary.RandomUnitVectorInConeInDegrees(AimDir, CurrentSpread * 0.5);
    local EndTrace = StartTrace + ShootDir * ShootWeaponBase.WeaponConfigData.ShootRayRange
    Physics_ShootDir = ShootDir;

    local HitResult = UE4.FHitResult()
    local ActorsToIgnore = TArray(UE4.AActor)
    ActorsToIgnore:Add(self.ShootWeaponBase.CharacterBase);

    local bResult = UE4.UKismetSystemLibrary.LineTraceSingle(self, StartTrace, EndTrace, UE4.ETraceTypeQuery.Weapon, false, ActorsToIgnore,
        UE4.EDrawDebugTrace.None, HitResult, true)
    if bResult then

        local AdjustedDir = (HitResult.ImpactPoint - Origin):GetSafeNormal();
        local bWeaponPenetration = false;

        local DirectionDot = AdjustedDir:Dot(ShootDir);

		if DirectionDot < 0.0 then
		
			--shooting backwards = weapon is penetrating
			bWeaponPenetration = true;
		
		elseif DirectionDot < 0.5 then
		
			--check for weapon penetration if angle difference is big enough
			-- raycast along weapon mesh to check if there's blocking hit
			local MuzzleStartTrace = Origin - self:GetMuzzleDirection() * 150.0;
            local MuzzleEndTrace = Origin;

            local MuzzleImpact = UE4.FHitResult()
            local MuzzleHit = UE4.UKismetSystemLibrary.LineTraceSingle(self, MuzzleStartTrace, MuzzleEndTrace, UE4.ETraceTypeQuery.Weapon,
             false, ActorsToIgnore, UE4.EDrawDebugTrace.None, HitResult, true)
			if MuzzleHit then
				bWeaponPenetration = true;
            end
        end

		if (bWeaponPenetration) then
			--spawn at crosshair position
			Origin = HitResult.ImpactPoint - ShootDir * 10.0;		
		else
			--adjust direction to hit
			ShootDir = AdjustedDir;
        end
    end

    local RayImpactPoint = HitResult.ImpactPoint
    if not bResult then
         RayImpactPoint =  Origin + ShootDir * ShootWeaponBase.WeaponConfigData.ShootRayRange
    end

    return Origin, ShootDir, RayImpactPoint, StartTrace, Physics_ShootDir
end


function BP_ShootWeaponFireComponent_C:GetWeaponTraceInfo()
    local TraceLocation = UE4.FVector()
    local TraceDirection = UE4.FVector()

    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase and ShootWeaponBase.CharacterBase then
        local Camera = ShootWeaponBase.CharacterBase:GetUsingCamera()
        if Camera then
            TraceLocation = Camera:K2_GetComponentLocation()
            TraceDirection = Camera:GetForwardVector()
        end
    end

    return TraceLocation, TraceDirection
end

function BP_ShootWeaponFireComponent_C:GetActorForwardVector()
    local ShootWeaponBase = self.ShootWeaponBase
    if ShootWeaponBase and ShootWeaponBase.CharacterBase then
        return ShootWeaponBase.CharacterBase:GetActorForwardVector()
    end
    return UE4.FVector()
end

-------------------------------------------------------------------------
-- 条件判断接口
-------------------------------------------------------------------------
function BP_ShootWeaponFireComponent_C:IsPendingReload()
	return self.PendingReload
end


--扣除子弹
function BP_ShootWeaponFireComponent_C:RemoveAmmoInClip(Num)
     self.CurrentAmmoInClip = math.max(0, self.CurrentAmmoInClip - Num);

     if self.ShootWeaponBase  then
        self.ShootWeaponBase:OnEquipData_S()
    end
end

--获取当前弹夹中子弹数目
function BP_ShootWeaponFireComponent_C:GetCurrentAmmoInClip()
    return self.CurrentAmmoInClip
end

--获取备弹数目
function BP_ShootWeaponFireComponent_C:GetCurrentAmmo()
    return self.CurrentAmmo
end

-------------------------------------------------------------------------
-- 辅助函数
-------------------------------------------------------------------------

function BP_ShootWeaponFireComponent_C:SimulateWeaponFire_Effect()

    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return
    end

	if ShootWeaponBase.MuzzleFX then
		if not ShootWeaponBase.bLoopedMuzzleFX or not self.MuzzlePSC then
		
			-- Split screen requires we create 2 effects. One that we see and one that the other player sees.
			if ShootWeaponBase.CharacterBase and ShootWeaponBase.CharacterBase:IsLocallyControlled() then
			
				local bFirstPerson = ShootWeaponBase.CharacterBase:IsFirstPerson()

				self.MuzzlePSC = UE4.UGameplayStatics.SpawnEmitterAttached(ShootWeaponBase.MuzzleFX, ShootWeaponBase.Mesh1P, ShootWeaponBase.MuzzleAttachPoint)
				self.MuzzlePSC:SetOwnerNoSee(not bFirstPerson)
				self.MuzzlePSC:SetOnlyOwnerSee(bFirstPerson)

				self.MuzzlePSCSecondary = UE4.UGameplayStatics.SpawnEmitterAttached(ShootWeaponBase.MuzzleFX, ShootWeaponBase.Mesh3P, ShootWeaponBase.MuzzleAttachPoint)
				self.MuzzlePSCSecondary:SetOwnerNoSee(bFirstPerson)
				self.MuzzlePSCSecondary:SetOnlyOwnerSee(not bFirstPerson)
            else
				-- 其他人永远显示的第三人称模型
				self.MuzzlePSC = UE4.UGameplayStatics.SpawnEmitterAttached(ShootWeaponBase.MuzzleFX, ShootWeaponBase.Mesh3P, ShootWeaponBase.MuzzleAttachPoint)
			end
		end
	end

    if ShootWeaponBase.bLoopedFireAnim or not self.bPlayingFireAnim then

        local WeaponFireAnimation = ShootWeaponBase.CharacterBase:FindAnimationByID(ShootWeaponBase.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_FIRE]);
        if ShootWeaponBase.CharacterBase.CharacterMovementComponent:IsCrouching() then
            WeaponFireAnimation = ShootWeaponBase.CharacterBase:FindAnimationByID(ShootWeaponBase.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_FIRE]);
        end

        if WeaponFireAnimation ~= nil  then
            self.FireAnimTime = WeaponFireAnimation.Param1;
            self.bPlayingFireAnim = true

            if WeaponFireAnimation.Pawn1P and WeaponFireAnimation.Pawn3P then
                ShootWeaponBase:PlayWeaponAnimation(WeaponFireAnimation.Pawn1P, WeaponFireAnimation.Pawn3P, nil, nil);
            end
        end

	end

    local ShootType =  ShootWeaponBase.WeaponConfigData.ShootType;
    if ShootType == EWeaponShootType.EShootType_Single or self.FireCounter == 1 then
        self:PlayFireSound(ShootWeaponBase.FireFirstSound)
    else
        if not self.FireAudioComponent then
			self.FireAudioComponent = self:PlayFireSound(ShootWeaponBase.FireLoopSound)
        end
    end

	if ShootWeaponBase.CharacterBase and ShootWeaponBase.CharacterBase:IsLocallyControlled() then
		local PlayerController = ShootWeaponBase.CharacterBase.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
        if PlayerController then
            
            if ShootWeaponBase.RecoilComponent then		
                ShootWeaponBase.RecoilComponent:SimulateShootRecoil(self.FireCounter)
            end

			if ShootWeaponBase.FireCameraShake then
				PlayerController:ClientPlayCameraShake(ShootWeaponBase.FireCameraShake, 1)
            end

			if ShootWeaponBase.FireForceFeedback and PlayerController:IsVibrationEnabled() then
				PlayerController:ClientPlayForceFeedback(ShootWeaponBase.FireForceFeedback, false, false, "Weapon")
            end
		end
    end
end

function BP_ShootWeaponFireComponent_C:StopSimulatingWeaponFire_Effect()
    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return
    end

	if self.MuzzlePSC then
		self.MuzzlePSC:EndTrails()
		self.MuzzlePSC = nil
    end

	if self.MuzzlePSCSecondary then
		self.MuzzlePSCSecondary:EndTrails()
		self.MuzzlePSCSecondary = nil
    end

    if ShootWeaponBase.bLoopedFireAnim or self.bPlayingFireAnim then
        if ShootWeaponBase.CharacterBase and ShootWeaponBase.CharacterBase:IsWeaponAim() then
           -- self:StopFireAnimation()
        end
		self.bPlayingFireAnim = false
    end

	if self.FireAudioComponent then
		self.FireAudioComponent:FadeOut(0.1, 0.0)
		self.FireAudioComponent = nil

		self:PlayFireSound(ShootWeaponBase.FireFinishSound)
    end
end

function BP_ShootWeaponFireComponent_C:PlayFireSound(SoundCube)
    if not SoundCube then
        return nil
    end

    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase then
        return nil
    end

	local AudioComponent = nil
	if ShootWeaponBase.CharacterBase then
		AudioComponent = UE4.UGameplayStatics.SpawnSoundAttached(SoundCube, ShootWeaponBase.CharacterBase:K2_GetRootComponent())
    end

	return AudioComponent
end

function BP_ShootWeaponFireComponent_C:SimulateWeaponReload_Effect()
    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return 0
    end

    local ReloadInterval = 0.2;

    local WeaponReloadAnimation = ShootWeaponBase.CharacterBase:FindAnimationByID(ShootWeaponBase.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPRELOAD]);
    --- 目前这里只使用站立资源
    --if ShootWeaponBase.CharacterBase.CharacterMovementComponent:IsCrouching() or ShootWeaponBase.CharacterBase:IsCovering() then
    --    WeaponReloadAnimation = ShootWeaponBase.CharacterBase:FindAnimationByID(ShootWeaponBase.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPRELOAD]);
    --end

    if WeaponReloadAnimation ~= nil then
        ReloadInterval = WeaponReloadAnimation.Param1;
        ShootWeaponBase:PlayWeaponAnimation(WeaponReloadAnimation.Pawn1P, WeaponReloadAnimation.Pawn3P, nil, nil);
    end

    return ReloadInterval
end

function BP_ShootWeaponFireComponent_C:StopSimulateWeaponReload_Effect()
    local ShootWeaponBase = self.ShootWeaponBase
    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return 0
    end

    local WeaponReloadAnimation = ShootWeaponBase.CharacterBase:FindAnimationByID(ShootWeaponBase.WeaponAnimIDs[Ds_WeaponAnimationType.WEAPONANIMATIONTYPE_EQUIPRELOAD]);
    if ShootWeaponBase.CharacterBase.CharacterMovementComponent:IsCrouching() or ShootWeaponBase.CharacterBase:IsCovering() then
        WeaponReloadAnimation = ShootWeaponBase.CharacterBase:FindAnimationByID(ShootWeaponBase.WeaponAnimIDs[Ds_WeaponAnimationType.CROUCH_WEAPONANIMATIONTYPE_EQUIPRELOAD]);
    end

    if WeaponReloadAnimation ~= nil then
        ShootWeaponBase.CharacterBase:StopAnimMontageLua(WeaponReloadAnimation.Pawn1P, WeaponReloadAnimation.Pawn3P , true)
    end

    --- 弹夹退出
    ShootWeaponBase:HandleAttachMagout()

    --ShootWeaponBase:StopWeaponAnimation(nil, nil)
end

--- 移动散射值
function BP_ShootWeaponFireComponent_C:MovingAffectSpread()
    local ShootWeaponBase = self.ShootWeaponBase

    if not ShootWeaponBase or not ShootWeaponBase.CharacterBase then
        return 
    end

    local Velocity = ShootWeaponBase.CharacterBase.CharacterMovement:GetVelocity():Size() 

    if Velocity > 0 then
        self.MoveBackSpreadInc = 50
        self.CurrentFiringSpread = math.min(ShootWeaponBase.WeaponConfigData.FiringSpreadMax, 
        self.CurrentFiringSpread + Velocity / 200)
    end
    
end

return BP_ShootWeaponFireComponent_C
