require "UnLua"

local ShootWeaponAttrMgr = require "Gameplay/Equips/ShootWeapon/Module/ShootWeaponAttrMgr"
local ShootWeaponPartMgr = require "Gameplay/Equips/ShootWeapon/Module/ShootWeaponPartMgr"

local BP_ShootWeapon_C = Class("Gameplay/Equips/BP_EquipBase_C")

function BP_ShootWeapon_C:Initialize(Initializer)
    self.Super.Initialize(self, Initializer)
    
    -------------------------------------------------------------------------
    --- Lua中定义的变量
    -------------------------------------------------------------------------
    self.LastHitCharacterTime = 0.0

    self.ShootWeaponAttrMgr = ShootWeaponAttrMgr.new()
    self.ShootWeaponAttrMgr:OnCreate(self)

    self.ShootWeaponPartMgr = ShootWeaponPartMgr.new()
    self.ShootWeaponPartMgr:OnCreate(self)
end

function BP_ShootWeapon_C:ReceiveBeginPlay()
    self.NetWeaponAttr:Resize(Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX)
    for iAttrID = Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN + 1, Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX do
        self.NetWeaponAttr:Set(iAttrID, 0)
    end

    if self:HasAuthority() then
        self.ShootWeaponAttrMgr:OnInit();
        self.ShootWeaponAttrMgr:AttrOpeSet(Ds_ResWeaponAttrType.EN_WEAPONATTR_AMMOPERCLIP, self.WeaponConfigData.AmmoInClip, Ds_ATTRADDTYPE.ATTRADD_BASE);
        self.ShootWeaponAttrMgr:AttrOpeSet(Ds_ResWeaponAttrType.EN_WEAPONATTR_TARGETINGFOV, self.WeaponConfigData.TargetingFOV * MATH_SCALE_10K, Ds_ATTRADDTYPE.ATTRADD_BASE);
        self.ShootWeaponAttrMgr:AttrOpeSet(Ds_ResWeaponAttrType.EN_WEAPONATTR_TIMEBETWEENONCESHOTS, self.WeaponConfigData.TimeBetweenOnceShots, Ds_ATTRADDTYPE.ATTRADD_BASE);
        self.ShootWeaponAttrMgr:AttrOpeSet(Ds_ResWeaponAttrType.EN_WEAPONATTR_TIMEBETWEENCONTINUESHOTS, self.WeaponConfigData.TimeBetweenContinueShots, Ds_ATTRADDTYPE.ATTRADD_BASE);
    end
end

function BP_ShootWeapon_C:ReceiveEndPlay()
    if self.ShootWeaponAttrMgr then
        self.ShootWeaponAttrMgr:OnDestroy()
    end

    if self.ShootWeaponPartMgr then
        self.ShootWeaponPartMgr:OnDestroy()
    end
end

function BP_ShootWeapon_C:ReceiveTick(DeltaSeconds)
    if self:HasAuthority() then
        if self.ShootWeaponAttrMgr then
            self.ShootWeaponAttrMgr:Tick(DeltaSeconds)
        end
    end
end

-- @params: (BP_ShooterCharacterBase_C, tagEquipBarType, int8, FName, FName)
function BP_ShootWeapon_C:OnInit(NewOwner, iEquipBarType, iEquipState, EquipUpAttachPoint, EquipDownAttachPoint)
    self.Super.OnInit(self, NewOwner, iEquipBarType, iEquipState, EquipUpAttachPoint, EquipDownAttachPoint)

    if self.FireComponent then
        self.FireComponent:OnInit()
    end

    if self.RecoilComponent then
        self.RecoilComponent:OnInit()
    end

    if self.PartComponent then
        self.PartComponent:OnInit()
    end
end

function BP_ShootWeapon_C:OnUnInit()
    if self.PartComponent then
        self.PartComponent:OnUnInit()
    end

    self.Super.OnUnInit(self)
end


-------------------------------------------------------------------------
-- @params: (FName)
function BP_ShootWeapon_C:AttachMeshToPawn(AttachPoint)
    self.Super.AttachMeshToPawn(self, AttachPoint)

    if self.CharacterBase then
        self.Mesh1P:K2_AttachToComponent(self.CharacterBase.Mesh1P, AttachPoint, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, true)
        self.Mesh1P:SetHiddenInGame(false)

        self.Mesh3P:K2_AttachToComponent(self.CharacterBase.Mesh, AttachPoint, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, UE4.EAttachmentRule.KeepRelative, true)
        self.Mesh3P:SetHiddenInGame(false)
    end
end

function BP_ShootWeapon_C:DetachMeshFromPawn()
    self.Super.DetachMeshFromPawn(self)

    self.Mesh1P:K2_DetachFromComponent(UE4.EAttachmentRule.KeepRelative)
    self.Mesh1P:SetHiddenInGame(true)

    self.Mesh3P:K2_DetachFromComponent(UE4.EAttachmentRule.KeepRelative)
    self.Mesh3P:SetHiddenInGame(true)
end

function BP_ShootWeapon_C:UpdateMeshes()
    self.Super.UpdateMeshes(self)

    -- for i = 1, Ds_WeaponPartsBarType.WEAPONPARTSBARTYPE_MAX do
    -- 	local PartsBarInfo = self.WeaponParts[i]
    -- 	if PartsBarInfo.Weapon_Part then
    -- 		PartsBarInfo.Weapon_Part:UpdateMeshes()
    --     end
    -- end

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
function BP_ShootWeapon_C:StartFire()
   
    if self.FireComponent then
        self.FireComponent:StartFire()
    end

end

-- 停火
function BP_ShootWeapon_C:StopFire()
   
    if self.FireComponent then
        self.FireComponent:StopFire()
    end

end


function BP_ShootWeapon_C:StartReload()

    if self.FireComponent then
        self.FireComponent:StartReload()
    end
end

function BP_ShootWeapon_C:StopReload()
    if self.FireComponent then
        self.FireComponent:StopReload()
    end
end

function BP_ShootWeapon_C:HandleReload()
    if self.FireComponent then
        self.FireComponent:HandleReload()
    end
end

function BP_ShootWeapon_C:HandleAttachMagin()
    if self.PartComponent then
        self.PartComponent:HandleAttachMagin()
    end
end

function BP_ShootWeapon_C:HandleAttachMagout()
    if self.PartComponent then
        self.PartComponent:HandleAttachMagout()
    end
end

-------------------------------------------------------------------------
-- Replicated Notify
-------------------------------------------------------------------------
function BP_ShootWeapon_C:OnRep_NetWeaponAttr()
    self:OnAttrChange_C()
end


function BP_ShootWeapon_C:OnRep_HitCharacterFlag()
    self:NotifyWeponHitCharacter()
end

-- 属性修改(服务端)
-- @params: (Ds_ResWeaponAttrType)
function BP_ShootWeapon_C:OnAttrChange_S(iAttrID)
    if self:HasAuthority() then
        self.NetWeaponAttr:Set(iAttrID, self.ShootWeaponAttrMgr:GetAttr(iAttrID))
    end
end

function BP_ShootWeapon_C:OnAttrChange_C()

    if self:HasAuthority() then
        return
    end

    -- 收到服务器属性同步给客户端记录
    if self.ShootWeaponAttrMgr then
        for iAttrID = Ds_ResWeaponAttrType.EN_WEAPONATTR_MIN + 1, Ds_ResWeaponAttrType.EN_WEAPONATTR_MAX do
           self.ShootWeaponAttrMgr:SetAttr_C(iAttrID, self.NetWeaponAttr:Get(iAttrID))
        end
    end
end

function BP_ShootWeapon_C:NotifyWeponHitCharacter()
    self.LastHitCharacterTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
    --改变标记 强制通知给客户端
    if  self:HasAuthority() then
        self.HitCharacterFlag = (self.HitCharacterFlag > 100) and 1 or self.HitCharacterFlag + 1;
    end
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------
-- 获取武器属性管理
function BP_ShootWeapon_C:GetShootWeaponAttrMgr()
    return self.ShootWeaponAttrMgr
end

-- 获取正在使用的Mesh
function BP_ShootWeapon_C:GetUsingMesh()
    if self.CharacterBase then
        return self.CharacterBase:IsFirstPerson() and self.Mesh1P or self.Mesh3P
    end

    return nil
end


--获取当前弹夹中子弹数目
function BP_ShootWeapon_C:GetCurrentAmmoInClip()
    return self.FireComponent and self.FireComponent:GetCurrentAmmoInClip() or 0;
end

--获取备弹数目
function BP_ShootWeapon_C:GetCurrentAmmo()
    return self.FireComponent and self.FireComponent:GetCurrentAmmo() or 0;
end

--获取弹夹容量
function BP_ShootWeapon_C:GetAmmoPerClip()
    return self.ShootWeaponAttrMgr:GetAttr(Ds_ResWeaponAttrType.EN_WEAPONATTR_AMMOPERCLIP);
end

--武器开镜倍数
function BP_ShootWeapon_C:GetTargetingFOV()
	return self.ShootWeaponAttrMgr:GetAttr(Ds_ResWeaponAttrType.EN_WEAPONATTR_TARGETINGFOV) / MATH_SCALE_10K;
end

--获取[单发]射击速度间隔时间
function BP_ShootWeapon_C:GetTimeBetweenOnceShots()
	return self.ShootWeaponAttrMgr:GetAttr(Ds_ResWeaponAttrType.EN_WEAPONATTR_TIMEBETWEENONCESHOTS) / 1000.0;
end

--获取[连续]射击速度间隔时间
function BP_ShootWeapon_C:GetTimeBetweenContinueShots()
	return self.ShootWeaponAttrMgr:GetAttr(Ds_ResWeaponAttrType.EN_WEAPONATTR_TIMEBETWEENCONTINUESHOTS) / 1000.0;
end

--获取散射值
function BP_ShootWeapon_C:GetCurrentSpread()
    return self.FireComponent and self.FireComponent:GetCurrentSpread() or 0;
end

--获取瞄准模式
function BP_ShootWeapon_C:GetEquipAimMode()
    return self.WeaponConfigData.EquipAimMode
end

function BP_ShootWeapon_C:IsAllowAiming()
    return (self.WeaponConfigData.EquipAimMode == EEquipAimMode.EEquipAimMode_NONE) and false or true;
end


--上次击中角色时间
function BP_ShootWeapon_C:GetLastHitCharacterTime()
    return self.LastHitCharacterTime
end


-------------------------------------------------------------------------
-- 条件判断接口
-------------------------------------------------------------------------
-- 是否可以开火
function BP_ShootWeapon_C:CanFire()
    if self.CharacterBase == nil or not self.CharacterBase:IsAlive() then
        return false
   end

    --未装备完成
    if self.EquipState ~= UE4.EEquipState.EquipState_EquipUped then
        return false;
    end

    if self.FireComponent then
        if self.FireComponent.PendingReload  then  --装弹中
            return false;
        end

        return self.FireComponent:GetCurrentAmmoInClip() > 0 and true or false;
    end

    return false
end


-- 是否可以装弹
function BP_ShootWeapon_C:CanReload()
    if self.CharacterBase == nil or not self.CharacterBase:IsAlive() then
         return false
    end

      --未装备完成
    if self.EquipState ~= UE4.EEquipState.EquipState_EquipUped then
        return false;
    end

    if self.FireComponent then
        if self.FireComponent.PendingReload  then  --装弹中
            return false;
        end
    
        return self.FireComponent:GetCurrentAmmoInClip() < self:GetAmmoPerClip() and 
            self.FireComponent:GetCurrentAmmo() > 0
    end

    return false;
end

function BP_ShootWeapon_C:IsPendingReload()
    return self.FireComponent and self.FireComponent:IsPendingReload()
end

-------------------------------------------------------------------------
-- 条件判断接口
-------------------------------------------------------------------------


--绘制准心
function BP_ShootWeapon_C:DrawCrosshair(HudCanvas, ScaleRatio, bCanHit, bShowHitTarget, bShowKillTarget, AimObjectState)
    if self.CharacterBase == nil or not self.CharacterBase:IsAlive() then
        return 
    end

    self.CanvasCenterPos = UE4.FVector2D(HudCanvas.ClipX * 0.5, HudCanvas.ClipY * 0.5)

    local CrosshairScale = ScaleRatio
    if self.CrosshairScale ~= 0 then
        CrosshairScale = ScaleRatio * self.CrosshairScale
    end
    
    if bCanHit then 
        local offset = self:CalculatingOffset() 

        local LinearColor = self:CaluCrosshairColor(AimObjectState)
        if self.CrosshairMode == 0  then
            self:DrawCross(HudCanvas, CrosshairScale, offset-37, LinearColor)   --37 准星素材的原始偏移位移 
        elseif self.CrosshairMode == 1  then
            self:DrawArc(HudCanvas, CrosshairScale, offset, LinearColor)
        end
    elseif not bCanHit then   
        local LinearColor = UE4.FLinearColor(1,0,0,1)
        self:ShowIcon(HudCanvas, CrosshairScale, self.NoAiniming, LinearColor)           
    end

    --   self:ShowIcon(HudCanvas,CrosshairScale,self.HitCrosshair)        --绘制自动射击准星
    if bShowHitTarget then
        self:DrawHitCross(HudCanvas, CrosshairScale)   
        self:DrawKillCross(HudCanvas, CrosshairScale) 
    end 
end

--绘制十字准星
function BP_ShootWeapon_C:DrawCross(HudCanvas, ScaleRatio, offset, LinearColor)
    if self.Crosshair ~= nil  then 
        local TextureSize = UE4.FVector2D(self.Crosshair:GetRef(1):Blueprint_GetSizeX(), self.Crosshair:GetRef(1):Blueprint_GetSizeY()) * ScaleRatio
        local CrossHairDrawPosition = UE4.FVector2D(self.CanvasCenterPos.X - (TextureSize.X * 0.5) , self.CanvasCenterPos.Y - TextureSize.Y - offset * ScaleRatio)
        HudCanvas:K2_DrawTexture(self.Crosshair:GetRef(1),CrossHairDrawPosition,TextureSize ,UE4.FVector2D(0,0),UE4.FVector2D(1,1),LinearColor,UE4.EBlendMode.BLEND_Translucent,0,UE4.FVector2D(0.5,(TextureSize.Y + offset * ScaleRatio) / TextureSize.Y))
        HudCanvas:K2_DrawTexture(self.Crosshair:GetRef(1),CrossHairDrawPosition,TextureSize ,UE4.FVector2D(0,0),UE4.FVector2D(1,1),LinearColor,UE4.EBlendMode.BLEND_Translucent,90,UE4.FVector2D(0.5,(TextureSize.Y + offset * ScaleRatio) / TextureSize.Y))
        HudCanvas:K2_DrawTexture(self.Crosshair:GetRef(1),CrossHairDrawPosition,TextureSize ,UE4.FVector2D(0,0),UE4.FVector2D(1,1),LinearColor,UE4.EBlendMode.BLEND_Translucent,180,UE4.FVector2D(0.5,(TextureSize.Y + offset * ScaleRatio) / TextureSize.Y))
        HudCanvas:K2_DrawTexture(self.Crosshair:GetRef(1),CrossHairDrawPosition,TextureSize ,UE4.FVector2D(0,0),UE4.FVector2D(1,1),LinearColor,UE4.EBlendMode.BLEND_Translucent,270,UE4.FVector2D(0.5,(TextureSize.Y + offset * ScaleRatio) / TextureSize.Y))
    end
end

--绘制圆弧准星
function BP_ShootWeapon_C:DrawArc(HudCanvas, ScaleRatio, offset, LinearColor)
    if self.Crosshair ~= nil  then
        local TextureSize = UE4.FVector2D(self.Crosshair:GetRef(2):Blueprint_GetSizeX(), self.Crosshair:GetRef(2):Blueprint_GetSizeY()) * (ScaleRatio + offset * ScaleRatio )
        local CrossHairDrawPosition = UE4.FVector2D(self.CanvasCenterPos.X - (TextureSize.X * 0.5 ), self.CanvasCenterPos.Y - (TextureSize.Y * 0.5))
        HudCanvas:K2_DrawTexture(self.Crosshair:GetRef(2), CrossHairDrawPosition, TextureSize, UE4.FVector2D(0,0), UE4.FVector2D(1,1), LinearColor, UE4.EBlendMode.BLEND_Translucent, 0, UE4.FVector2D(0.5,0.5))
    end
end

--绘制击中准星
function BP_ShootWeapon_C:DrawHitCross(HudCanvas,CrosshairScale)
    local CurrentTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
    local LastHitCharacterTime = self:GetLastHitCharacterTime()
    local DeltaTime = CurrentTime - LastHitCharacterTime
    local FadeOutTime = 0.5
    if DeltaTime >= 0 and DeltaTime <= FadeOutTime then    
        local Alpha = math.min(1.0, 1 - (DeltaTime / FadeOutTime)) 
        local LinearColor = UE4.FLinearColor(1,1,1,Alpha)
        self:ShowIcon(HudCanvas,CrosshairScale,self.HitCrosshair,LinearColor) 
    end
end

--绘制击杀准星 
function BP_ShootWeapon_C:DrawKillCross(HudCanvas, CrosshairScale)
    local CurrentTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
    local ControllerBase = self:GetOwnerController()
    local LastHitCharacterTime = ControllerBase:GetLastKillPlayerTime()
    local DeltaTime = CurrentTime - LastHitCharacterTime
    local FadeOutTime = 0.5
    if DeltaTime >= 0 and DeltaTime <= FadeOutTime then    
        local Alpha = math.min(1.0, 1 - (DeltaTime / FadeOutTime))  
        local LinearColor = UE4.FLinearColor(1,0,0,Alpha)
        self:ShowIcon(HudCanvas, CrosshairScale, self.HitCrosshair, LinearColor)  
    end
end

--显示Icon
function BP_ShootWeapon_C:ShowIcon(HudCanvas, ScaleRatio, Crosshair,LinearColor)
    if Crosshair ~= nil  then
        local TextureSize = UE4.FVector2D(Crosshair:Blueprint_GetSizeX(), Crosshair:Blueprint_GetSizeY()) * ScaleRatio
        local CrossHairDrawPosition = UE4.FVector2D(self.CanvasCenterPos.X - (TextureSize.X * 0.5 ), self.CanvasCenterPos.Y - (TextureSize.Y * 0.5))
        HudCanvas:K2_DrawTexture(Crosshair, CrossHairDrawPosition, TextureSize, UE4.FVector2D(0,0), UE4.FVector2D(1,1), LinearColor, UE4.EBlendMode.BLEND_Translucent, 0, UE4.FVector2D(0.5,0.5))
    end
end

--准星偏移值计算
function BP_ShootWeapon_C:CalculatingOffset()
    local offset = self:GetCurrentSpread() * self.OffsetRatio  

    if self.CharacterBase:IsWeaponAim() then
        if offset <= (self.AimingOffset * self.OffsetRatio) then
            offset = self.AimingOffset * self.OffsetRatio
        end
    elseif not self.CharacterBase:IsWeaponAim() then
        if offset <= (self.BaseOffset * self.OffsetRatio) then
            offset = self.BaseOffset * self.OffsetRatio
        end
    end
    return offset
end

function BP_ShootWeapon_C:CaluCrosshairColor(AimObjectState)
    if AimObjectState == -1 then
        return  UE4.FLinearColor(1,1,1,1)
    elseif AimObjectState == 0 then
        return  UE4.FLinearColor(1,0.1529262,0.1499598,1)
    elseif AimObjectState == 1 then
        return  UE4.FLinearColor(0.2501584,0.7011021,1,1)
    end
end

return BP_ShootWeapon_C
