require "UnLua"


local BP_ThrowWeapon_C = Class("Gameplay/Equips/BP_EquipBase_C")

function BP_ThrowWeapon_C:Initialize(Initializer)
    self.Super.Initialize(self, Initializer)

    self.StartThrowTime = 0;
    self.bMouseRelease = false;
end

function BP_ThrowWeapon_C:ReceiveBeginPlay()

end

function BP_ThrowWeapon_C:ReceiveEndPlay()
   
end

function BP_ThrowWeapon_C:ReceiveTick(DeltaSeconds)
    self:HandleManualThrow();
	self:HandleAutoExplode();
end

-- @params: (BP_ShooterCharacterBase_C, tagEquipBarType, int8, FName, FName)
function BP_ThrowWeapon_C:OnInit(NewOwner, iEquipBarType, iEquipState, EquipUpAttachPoint, EquipDownAttachPoint)
    self.Super.OnInit(self, NewOwner, iEquipBarType, iEquipState, EquipUpAttachPoint, EquipDownAttachPoint)

end


function BP_ThrowWeapon_C:DetachMeshFromPawn()
    self.Super.DetachMeshFromPawn(self)

    self.Mesh1P:K2_DetachFromComponent(UE4.EAttachmentRule.KeepRelative)
    self.Mesh1P:SetHiddenInGame(true)

    self.Mesh3P:K2_DetachFromComponent(UE4.EAttachmentRule.KeepRelative)
    self.Mesh3P:SetHiddenInGame(true)
end

function BP_ThrowWeapon_C:UpdateMeshes()
    self.Super.UpdateMeshes(self)

    if self.CharacterBase then
        local bFirstPerson = (self.CharacterBase:IsFirstPerson()) and true or false

        self.Mesh1P.VisibilityBasedAnimTickOption = (not bFirstPerson) and UE4.EVisibilityBasedAnimTickOption.OnlyTickPoseWhenRendered or UE4.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
        self.Mesh1P:SetOwnerNoSee(not bFirstPerson)

        self.Mesh3P.VisibilityBasedAnimTickOption = bFirstPerson and UE4.EVisibilityBasedAnimTickOption.OnlyTickPoseWhenRendered or UE4.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
        self.Mesh3P:SetOwnerNoSee(bFirstPerson)
    end
end


-------------------------------------------------------------------------
-- Input Event
-------------------------------------------------------------------------
-- 开火
function BP_ThrowWeapon_C:StartFire()
   
    self.StartThrowTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld());
    self.bMouseRelease = false;
    self.ThrowProcess = EWeaponThrowProcess.EThrowProcess_Start;

    --蓝图
    self:OnStartThrow_BP();
end

-- 停火
function BP_ThrowWeapon_C:StopFire()
   
    self.bMouseRelease = true;

    self:NotifyStartThrow();
end

function BP_ThrowWeapon_C:HandleManualThrow()
	if self:HadThrowSuccess() then
        return;
    end

	if self.ThrowProcess == EWeaponThrowProcess.EThrowProcess_Start  and self:CanManualThrow() then

        self.ThrowProcess = EWeaponThrowProcess.EThrowProcess_ThrowOut;
        self:OnThrowOut_BP();
    end
end

--自爆
function BP_ThrowWeapon_C:HandleAutoExplode()
	if self:HadThrowSuccess() then
        return;
    end
        
	if self.ThrowProcess == EWeaponThrowProcess.EThrowProcess_Start and self:CanAutoExplode() then
	
        self.ThrowProcess = EWeaponThrowProcess.EThrowProcess_AutoExplode;		
        self:OnAutoExplode_BP();

        if self.CharacterBase and self.CharacterBase:IsLocallyControlled() then 
            self:StartThrowWeapon();
        end
     end
end

--蓝图动作结束 通知扔
function BP_ThrowWeapon_C:NotifyStartThrow()

    print("NotifyStartThrow===============")

    if self.CharacterBase and self.CharacterBase:IsLocallyControlled() then
        self:StartThrowWeapon();
    end
    
end

function BP_ThrowWeapon_C:StartThrowWeapon()
	local Origin = self:GetPawnSocketLocation(self.WeaponThrowConfigData.ThrowOutPoint);
    local ShootDir = self:GetOwnerPawnRotation():ToVector() + self.WeaponThrowConfigData.ThrowOutDirection;
    
   -- print("Origin x:"..Origin.X..",Y:"..Origin.Y..",Z:"..Origin.Z)
   -- print("ShootDir x:"..ShootDir.X..",Y:"..ShootDir.Y..",Z:"..ShootDir.Z)

	self:ServerThrowWeapon(Origin, ShootDir);
end

function BP_ThrowWeapon_C:ThrowWeapon(Origin, ShootDir)

    local Quat = ShootDir:ToRotator():ToQuat()
    local SpawnTransform = UE4.FTransform(Quat, Origin)

    local Projectile = UE4.UGameplayStatics.BeginDeferredActorSpawnFromClass(self, self.WeaponThrowConfigData.ProjectileClass, SpawnTransform)
    if Projectile then
        Projectile:OnInit(self, Origin, ShootDir, self.WeaponThrowConfigData.ProjectileData)

        UE4.UGameplayStatics.FinishSpawningActor(Projectile, SpawnTransform)
    end

end

-------------------------------------------------------------------------
-- Replicated Notify
-------------------------------------------------------------------------

function BP_ThrowWeapon_C:OnRep_ThrowProcess()
    --其他玩家
    if self.ThrowProcess == EWeaponThrowProcess.EThrowProcess_Start then
        self:OnStartThrow_BP();
    elseif self.ThrowProcess == EWeaponThrowProcess.EThrowProcess_ThrowOut then
        self:OnThrowOut_BP();
    elseif self.ThrowProcess == EWeaponThrowProcess.EThrowProcess_AutoExplode then
        self:OnAutoExplode_BP();
    end
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------

-- 获取正在使用的Mesh
function BP_ThrowWeapon_C:GetUsingMesh()
    if self.CharacterBase then
        return self.CharacterBase:IsFirstPerson() and self.Mesh1P or self.Mesh3P
    end

    return nil
end


-------------------------------------------------------------------------
-- 条件判断接口
-------------------------------------------------------------------------
-- 是否可以开火
function BP_ThrowWeapon_C:CanFire()
    if self.CharacterBase == nil or not self.CharacterBase:IsAlive() then
        return false
   end

    --未装备完成
    if self.EquipState ~= UE4.EEquipState.EquipState_EquipUped then
        return false;
    end

    return false
end

--能否投掷
function BP_ThrowWeapon_C:CanManualThrow()
    return (self.bMouseRelease and (UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld()) - self.StartThrowTime
         >= self.WeaponThrowConfigData.ReadyThrowTime)) and true or false;
end

--能否自爆
function BP_ThrowWeapon_C:CanAutoExplode()
    return (self.WeaponThrowConfigData.bAutoExplode and (UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld()) -
         self.StartThrowTime) >= self.WeaponThrowConfigData.AutoExplodeTime) and true or false;
end

function BP_ThrowWeapon_C:HadThrowSuccess()
	return (self.ThrowProcess == EWeaponThrowProcess.EThrowProcess_ThrowOut or
        self.ThrowProcess == EWeaponThrowProcess.EThrowProcess_AutoExplode) and true or false;
end


return BP_ThrowWeapon_C
