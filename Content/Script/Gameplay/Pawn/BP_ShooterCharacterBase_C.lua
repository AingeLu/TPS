--[[
函数模块区分:
    1. 重写蓝图方法
        ReceiveBeginPlay
    2. 玩家输入监听
        MoveForward
    3. 远程调用函数
        ServerFunction_RPC()
    4. 属性同步通知
        OnRep_ + xxxx
    5. 设置数据接口
        Set + xxxx
    6. 获取数据接口
        Get + xxxx
    7. 判断状态接口
        Is + xxxx
        Can + xxxx
    8. 物理碰撞通知
        OnCapsuleBeginOverlap
        OnCapsuleEndOverlap
        
    9. 辅助函数和接口函数
]]

require "UnLua"

local CharacterMovementComponent = require "Gameplay/Pawn/Components/CharacterMovementComponent_C"

local BP_ShooterCharacterBase_C = Class()

function BP_ShooterCharacterBase_C:Initialize(Initializer)
    -------------------------------------------------------------------------
    --- Blueprint中定义的变量
    -------------------------------------------------------------------------
    -- 配置数据
    -- self.CharacterConfigData

    -- 同步属性
    -- self.PlayerID self.TeamID..所有同步
    -- self.Attrs  只同步自身
    -- self.CurHp self.CurHpMax 所有同步
    -- MoveMentBaseType MoveMentLayer1Type MoveMentLayer2Type 所有同步 

    self.CharacterMovementComponent  = CharacterMovementComponent.new()
    self.CharacterMovementComponent:Initialize(self);

    self.MoveMentBaseType = ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_STAND;
    self.MoveMentLayer1Type =  ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK;

    -- 动画瞄准偏移的参数
    self.InputAxisForward   = 0
    self.InputAxisRight     = 0
    self.InputAxisYaw       = 0
    self.InputAxisPitch     = 0


    -- 后坐力计算的参数
    self.FiringInputAxisPitch   = 0.0   -- 开火的时候手动调整的距离
    self.FiringRecoilAxisPitch  = 0.0  -- 开火的时候后坐力移动的距离

    --- Pawn 旋转归位
    self.IsResetPawnRotation = false    -- 是否进行旋转归位
    self.IsRolling           = false    -- 是否处于翻滚状态[用于动画]
    self.bInRollingCD        = false     -- 是否处于翻滚CD中

    self.RollDirection      = UE4.FVector()         -- 翻滚方向
    self.RollInputDirection      = UE4.FVector()     -- 翻滚方向输入方向[用于动画]

    self.IsInBeResurge   = false                 -- 是否被救
    self.bInResurgence = false                   -- 是否自救
    self.Resurgence_Timer = 0.0         -- 救援计时器

    self.bTriggerMortalBlows = false       -- 是否触发处决
    self.MortalBlowsTimer = 0.0            -- 处决计时器

    -------------------------------------------------------------------------
    --- Lua中定义的变量
    -------------------------------------------------------------------------
    -- 更新频率
    self.HalfSecInterval = 0.5
    self.SecInterval = 1.0

    self.LastTick_HalfSecTime = 0.0
    self.LastTick_SecTime = 0.0

    -- 输入 DeadZone
    self.DeadZone = 0.3
    -- 移动参数
    self.BaseTurnRate   = 45.0
    self.BaseLookUpRate = 45.0

    self.LastTakeHitTimeTimeout = 0;
    
    -- 上一次设置血条时间
    self.LastSetHpBarTime = 0.0
 
    -- 上一次伤害方向
    self.LastHitVector = UE4.FVector(0,0,0)

    -- 当前低血量警示百分比
    self.CurrHealPercent = 0.4

    --- 下落硬直计时器
    self.TimerHandle_FallingDown = nil


    ----- 角色倒地
    self.RescuerActor = nil             --救援者
    self.CacheBeRescuer = nil           --检测到可救援的角色
    self.MortalBlowsActor = nil            --处决角色

    --- 翻滚CD
    self.RollingCDTimer     = 0.0
    -- 是否处于冲锋按下状态（处理翻滚回来后是否执行冲锋）
    self.bPressRunBtn          = false
    -- Pawn 旋转归位
    self.ResetPawnRotateTimer  = 0.0


    -- 切换镜头旋转插值左端端点数值记录
    self.CameraUpdateLerpLeftRotate = UE4.FRotator(0 , 0 , 0)

    --- 队伍材质
    self.TeamMaterial = {[1] = "/Game/Characters/Hero/Hero02_01/Materials/M_Hero01_M_02_Cloth",
                         [2] = "/Game/Characters/Hero/Hero02_01/Materials/M_Hero01_M_02_Cloth_2_Red"}
end

--function BP_ShooterCharacterBase_C:UserConstructionScript()
--end

function BP_ShooterCharacterBase_C:ReceiveBeginPlay()
    self.Overridden.ReceiveBeginPlay(self)

    -- self.CapsuleComponent.OnComponentBeginOverlap:Add(self, BP_ShooterCharacterBase_C.OnCapsuleBeginOverlap)
    -- self.CapsuleComponent.OnComponentEndOverlap:AddDynamic(self, BP_ShooterCharacterBase_C.OnCapsuleEndOverlap)

    -- Mesh初始属性
    self.Mesh:SetOnlyOwnerSee(false)
    self.Mesh:SetOwnerNoSee(false)
    self.Mesh.bReceivesDecals = false

    local CharacterBase = UE4.UGameplayStatics.GetPlayerCharacter(self, 0)
    if CharacterBase then
        print("---------BP_ShooterCharacterBase_C:ReceiveBeginPlay ... materialtestTeamID",self.TeamID)
        if self:IsTeammate(CharacterBase) then
            local material = UE4.UObject.Load(self.TeamMaterial[1])
            if material then
                self.Mesh:SetMaterial(0,material)
                print("---------------------SetBuleMaterial",self.TeamID,"material",material)
            end
        else
            local material = UE4.UObject.Load(self.TeamMaterial[2])
            if material then
                self.Mesh:SetMaterial(0,material)
                print("---------------------SetRedMaterial",self.TeamID,"material",material)
            end
        end
    end

    
    -- Mesh1P初始属性
    self.Mesh1P:SetOnlyOwnerSee(true)
    self.Mesh1P:SetOwnerNoSee(false)
    self.Mesh1P.bCastDynamicShadow = false
    self.Mesh1P.CastShadow = false
    self.Mesh1P.bReceivesDecals = false
    -- 目前没有好的办法解决第一次开镜时候的动作混合过程。
    -- 第一次开镜的时候Mesh1P没有被渲染过，动作蓝图的状态机也没有运行过，就会从空状态直接跳到开镜状态
    -- self.Mesh1P.VisibilityBasedAnimTickOption = UE4.EVisibilityBasedAnimTickOption.OnlyTickPoseWhenRendered
    self.Mesh1P.VisibilityBasedAnimTickOption = UE4.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
    self.Mesh1P.PrimaryComponentTick.TickGroup = UE4.TG_PrePhysics

    self.CapsuleHalfHeight_Config = self.CapsuleComponent.CapsuleHalfHeight

    -- 第三人称相机
    self.TPPSpringArm.bUsePawnControlRotation = true
    self.TPPCamera.bUsePawnControlRotation = false

    self.TPP_Default_Back_CameraSpringData.TargetArmLength = self.TPPSpringArm.TargetArmLength;
    self.TPP_Default_Back_CameraSpringData.SocketOffset = self.TPPSpringArm.SocketOffset;
    self.TPP_Default_Back_CameraSpringData.TargetOffset = self.TPPSpringArm.TargetOffset;
    self.TPP_Start_CameraSpringData = UE4.FCharacterCameraSpringData()
    self.TPP_Target_CameraSpringData = nil;

    -- 第一人称相机
    self.FPPCamera.bUsePawnControlRotation = true

    self.CharacterStatus = UE4.ECharacterStatus.ECharacterStatus_ALIVE;
    self.CharacterLastStatus = UE4.ECharacterStatus.ECharacterStatus_ALIVE;

    self.LastBeHitTime = -99.0;

    self:UpdateCharacterCameraMode()

end

--function BP_ShooterCharacterBase_C:ReceiveEndPlay()
--end

function BP_ShooterCharacterBase_C:ReceiveTick(DeltaSeconds)
    self.Overridden.ReceiveTick(self, DeltaSeconds)

    self:ReceiveTick_CallInterval(DeltaSeconds)

    self:UpdateCameraAnimation(DeltaSeconds)
    self:UpdateRollCD(DeltaSeconds)
    self:UpdateResetPawnRotation(DeltaSeconds)
    self:UpdateResurgence(DeltaSeconds)
    self:UpdateMaterial() --- 添加测试角色材质错误打log 验证完删除
    self:UpdateMortalBlowsTime(DeltaSeconds)

    self.LastSetHpBarTime = self.LastSetHpBarTime + DeltaSeconds

    if not UE4.UKismetSystemLibrary.IsDedicatedServer(self) then
        self:UpdateHud()
    end



end

function BP_ShooterCharacterBase_C:ReceiveTick_CallInterval(DeltaSeconds)
    local curTime = UE4.UGameplayStatics.GetTimeSeconds(self)
    if curTime - self.LastTick_HalfSecTime >= self.HalfSecInterval then
        self.LastTick_HalfSecTime = curTime
        self:ReceiveTick_HalfSec()
    end

    if curTime - self.LastTick_SecTime >= self.SecInterval then
        self.LastTick_SecTime = curTime
        self:ReceiveTick_Sec()
    end
end

function BP_ShooterCharacterBase_C:ReceiveTick_HalfSec()
    if not UE4.UKismetSystemLibrary.IsDedicatedServer(self) then
        self:UpdateCheckBeRescuer()
    end
end

function BP_ShooterCharacterBase_C:ReceiveTick_Sec()

end

--function BP_ShooterCharacterBase_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function BP_ShooterCharacterBase_C:ReceiveActorBeginOverlap(OtherActor)
--end

--function BP_ShooterCharacterBase_C:ReceiveActorEndOverlap(OtherActor)
--end

function BP_ShooterCharacterBase_C:ReceivePawnClientRestart()

end


function BP_ShooterCharacterBase_C:ReceiveTakeDamage_Begin(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser 
    ,DamageEvent_TypeID, DamageEvent_OutHitInfo, DamageEvent_OutImpulseDir)
    
    if  self:GetHitDmgCalc() then
        return self:GetHitDmgCalc():DoStartDamage(self, Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser ,
         DamageEvent_TypeID, DamageEvent_OutHitInfo, DamageEvent_OutImpulseDir);
    else
        return 0;
    end
end

function BP_ShooterCharacterBase_C:ReceiveTakeDamage_End(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser , TypeID)
    
    if (Damage > 0) then	
        if self:GetHitDmgCalc() then
            self:GetHitDmgCalc():DoEndDamage(self, Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser , TypeID);
        end
        
        self:MakeNoise(1.0, AC_EventInstigator and  AC_EventInstigator:K2_GetPawn() or self);
    end
    
    return Damage;   
end

---@param EMovementMode PrevMovementMode
---@param EMovementMode NewMovementMode
---@param uint8 PrevCustomMode
---@param uint8 NewCustomMode
function BP_ShooterCharacterBase_C:K2_OnMovementModeChanged(PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)
    self.Overridden.K2_OnMovementModeChanged(self, PrevMovementMode, NewMovementMode, PrevCustomMode, NewCustomMode)

    if UE4.EMovementMode.MOVE_Falling == NewMovementMode then
        self.IsFallingDownFinish = false
    end

    if UE4.EMovementMode.MOVE_Falling == PrevMovementMode then
        self.TimerHandle_FallingDown = UE4.UKismetSystemLibrary.K2_SetTimerDelegate(
                {self, BP_ShooterCharacterBase_C.OnJumpEndFinish}, self.JumpEndDuration, false)
    end
end



--====================movement============

function BP_ShooterCharacterBase_C:Receive_MovementBeginPlay()
    if self.CharacterMovementComponent then
        self.CharacterMovementComponent:Receive_BeginPlay();
    end
end

function BP_ShooterCharacterBase_C:Receive_MovementEndPlay()
    if self.CharacterMovementComponent then
        self.CharacterMovementComponent:Receive_EndPlay();
    end
end

function BP_ShooterCharacterBase_C:Receive_MovementTickComponent(DeltaTime)
    if self.CharacterMovementComponent then
        self.CharacterMovementComponent:Receive_TickComponent(DeltaTime);
    end
end

function BP_ShooterCharacterBase_C:Receive_MovementGetMaxSpeed(MaxSpeed)
    if self.CharacterMovementComponent then
        return self.CharacterMovementComponent:Receive_GetMaxSpeed(MaxSpeed);
    end
    return MaxSpeed;
end

function BP_ShooterCharacterBase_C:Receive_MovementGetMaxAcceleration(MaxAcceleration)
    if self.CharacterMovementComponent then
        return self.CharacterMovementComponent:Receive_GetMaxAcceleration(MaxAcceleration);
    end
    return MaxAcceleration;
end
 
function BP_ShooterCharacterBase_C:ChangeMoveMentBaseType(NeweMoveMentBaseType)
    if self.CharacterMovementComponent then
        return self.CharacterMovementComponent:ChangeMoveMentBaseType(NeweMoveMentBaseType);
    end
end

--切换层级1状态(走/跑/跳)
function BP_ShooterCharacterBase_C:ChangeMoveMentLayer1Type(NewMoveMentLayer1Type)
    if self.CharacterMovementComponent then
        return self.CharacterMovementComponent:ChangeMoveMentLayer1Type(NewMoveMentLayer1Type);
    end
end

--切换层级2状态(武器瞄准/掩体探头/掩体QTE)
function BP_ShooterCharacterBase_C:ChangeMoveMentLayer2Type(NewMoveMentLayer2Type,inFlag)
    if self.CharacterMovementComponent then
        return self.CharacterMovementComponent:ChangeMoveMentLayer2Type(NewMoveMentLayer2Type, inFlag);
    end
end


function BP_ShooterCharacterBase_C:Receive_OnRep_MoveMentLayer2Type(PreMoveMentLayer2Type)
    if self.CharacterMovementComponent then
        return self.CharacterMovementComponent:Receive_OnRep_MoveMentLayer2Type(PreMoveMentLayer2Type);
    end
end

---开始下蹲
function BP_ShooterCharacterBase_C:K2_OnStartCrouch(HalfHeightAdjust,  ScaledHalfHeightAdjust)
    if self.CharacterMovementComponent then
        self.CharacterMovementComponent:ChangeMoveMentBaseType(ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_CROUCH,false);
    end
end

--结束下蹲
function BP_ShooterCharacterBase_C:K2_OnEndCrouch(HalfHeightAdjust,  ScaledHalfHeightAdjust)
    if self.CharacterMovementComponent then
        self.CharacterMovementComponent:ChangeMoveMentBaseType(ECharacterMoveMentBaseType.ECHARACTERMOVEMENTLAYERBASETYPE_STAND,false);
    end
end

--- 下落硬直结束
function BP_ShooterCharacterBase_C:OnJumpEndFinish()
    self.IsFallingDownFinish = true
end

--- 战术翻滚开始
function BP_ShooterCharacterBase_C:OnHandleRollingStart()
    self.bUseControllerRotationYaw = false
    self.IsRolling = true
end

--- 战术翻滚结束
function BP_ShooterCharacterBase_C:OnHandleRollingEnd()
    self.bUseControllerRotationYaw = true
	self.IsRolling = false


    if self:HasAuthority() then
        if UE4.UKismetSystemLibrary.IsStandalone(self) then
            self:OnHandleRollingCDStart_S()
        else
            self:ServerOnHandleRollingCDStart()
        end
    end
end

--- 战术翻滚 CD开始
function BP_ShooterCharacterBase_C:OnHandleRollingCDStart_S()
    self.bInRollingCD = true
    self.RollingCDTimer = 0.0
end

--- 战术翻滚冷却 CD结束
function BP_ShooterCharacterBase_C:OnHandleRollCDEnd()
    self.bInRollingCD = false
    self.RollingCDTimer = 0.0
end

----------------------------------------

function BP_ShooterCharacterBase_C:AttachToPlayerControl(ShooterPlayerControllerBase)
    self.TeamID = ShooterPlayerControllerBase:GetTeamID();
    self.PlayerID = ShooterPlayerControllerBase:GetPlayerID();
    self.PlayerIndex = ShooterPlayerControllerBase:GetPlayerIndex();
    self.PlayerName = ShooterPlayerControllerBase:GetPlayerName();
    -- 初始化属性数组
    self.Attrs:Resize(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX)
    for iAttrID = Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN + 1, Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX do
        self.Attrs:Set(iAttrID, 0)
    end

    -- 初始化属性管理器
    if self:HasAuthority() then
        local AttrMgr = self:GetAttrMgr()
        if AttrMgr then
            AttrMgr:OnInit()
            
            for iAttrID = Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN + 1, Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX do
                self.Attrs:Set(iAttrID, AttrMgr:GetAttr(iAttrID))
            end 
            self.CurHp = AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP)
            self.CurHpMax = AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP)
        end
    end

    if self.EquipComponent then
        self.EquipComponent:OnInit()
    end
end

function BP_ShooterCharacterBase_C:DetachFromPlayerControl()

end

-------------------------------------------------------------------------
-- module Event
-------------------------------------------------------------------------
---死亡--
function BP_ShooterCharacterBase_C:OnDie_S(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser , DamageTypeID)
	if self:IsDying() or not self:HasAuthority() then					
		return;
    end

    self.CharacterLastStatus = self.CharacterStatus
    self.CharacterStatus = ECharacterStatus.ECharacterStatus_DYING;

    local CurGameMode = UE4.UGameplayStatics.GetGameMode(self);
    CurGameMode = CurGameMode and CurGameMode:Cast(UE4.ABP_ShooterGameModeBase_C) or nil;
    if CurGameMode then
        CurGameMode:OnKillPlayerNoitfy(AC_EventInstigator, self.Controller)
    end

    --- 救援者解除救援
    self:OnHandleClearRescuer()

    --DestroyInventory
    if self.EquipComponent then
        self.EquipComponent:OnUnInit()
    end

    local PawnInstigator = AC_EventInstigator and AC_EventInstigator:K2_GetPawn() or nil;
	self:ReplicateHit(Damage, DamageEvent, PawnInstigator, AA_DamageCauser, self.CharacterStatus,DamageTypeID);

    self.bReplicateMovement = false;
    self:TearOff();
    self:DetachFromControllerPendingDestroy();

    --蓝图
    self:BP_ReceivePawnDead();
end


function BP_ShooterCharacterBase_C:OnDie_C(Damage, DamageEvent, AP_PawnInstigator, AA_DamageCauser)

    self.CharacterStatus = ECharacterStatus.ECharacterStatus_DYING;

    if self.EquipComponent then
        self.EquipComponent:StopFire()
        --DestroyInventory
        self.EquipComponent:OnUnInit()
    end

    -- 切换到第三人称模式
    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if PlayerController then
        PlayerController:SetCharacterCameraMode(UE4.ECharacterCameraMode.ThirdPerson);
    end
    --- 退出开镜
    if self:IsWeaponAim() then
        self.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM, false)
    end

    --- 退出掩体
    if self:IsEnteringCover() or self:IsCovering() then
        self.CoverComponent:LeaveCover()
    end

    --- 退出蹲
    if self.CharacterMovementComponent:IsCrouching() then
        self:UnCrouch(true)
    end

    --- 死亡动画
    if self.CharacterLastStatus == ECharacterStatus.ECharacterStatus_DOWN then
        --- 倒地死亡
        print("DownToDeadMontage ...")
        self:PlayMeshAnimation(self.DownToDeadMontage , false)
    else
        --- 站立死亡
        print("DeadAnimMontage ...")
        self:PlayMeshAnimation(self.DeadAnimMontage , false)
    end

    self.bReplicateMovement = false;
    self:TearOff();
    self:DetachFromControllerPendingDestroy();

    --蓝图
    self:BP_ReceivePawnDead();
end

--受到了攻击
function BP_ShooterCharacterBase_C:OnBeHit_S(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser , DamageTypeID)

    local PawnInstigator = AC_EventInstigator and AC_EventInstigator:K2_GetPawn() or nil;
    if PawnInstigator then
        self:ReplicateHit(Damage, DamageEvent, PawnInstigator, AA_DamageCauser, self.CharacterStatus ,DamageTypeID);

        self.LastBeHitTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
    end
end

function BP_ShooterCharacterBase_C:OnBeHit_C(Damage, DamageEvent, AP_PawnInstigator, AA_DamageCauser)
    if AP_PawnInstigator then
        local HitResult = UE4.FHitResult()
        DamageEvent:GetBestHitInfo(self,AP_PawnInstigator,HitResult,self.LastHitVector)

        self.LastBeHitTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
    end
end

--造成了攻击伤害
function BP_ShooterCharacterBase_C:OnAttackDamage_S(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser)

end


--倒地
function BP_ShooterCharacterBase_C:OnDown_S(Damage, DamageEvent, AC_EventInstigator, AA_DamageCauser,DamageTypeID)
    self.CharacterLastStatus = self.CharacterStatus
    self.CharacterStatus = ECharacterStatus.ECharacterStatus_DOWN;

    local PawnInstigator = AC_EventInstigator and AC_EventInstigator:K2_GetPawn() or nil;
    if PawnInstigator then
        self:ReplicateHit(Damage, DamageEvent, PawnInstigator, AA_DamageCauser, self.CharacterStatus,DamageTypeID);
    end

    self:OnHandleResurgenceStart()
end

function BP_ShooterCharacterBase_C:OnDown_C(Damage, DamageEvent, AP_PawnInstigator, AA_DamageCauser)

    self.CharacterLastStatus = self.CharacterStatus
    self.CharacterStatus = ECharacterStatus.ECharacterStatus_DOWN;

    if self.EquipComponent then
        self.EquipComponent:StopFire()
        self.EquipComponent:StopReload()
    end

    -- 切换到第三人称模式
    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if PlayerController then
        PlayerController:SetCharacterCameraMode(UE4.ECharacterCameraMode.ThirdPerson);
    end



    --- 退出掩体
    if self:IsEnteringCover() or self:IsCovering() then
        self.CoverComponent:LeaveCover()
    end

    --- 退出蹲
    if self.CharacterMovementComponent:IsCrouching() then
        self:UnCrouch(true)
    end

    if self:GetLocalRole() == UE4.ENetRole.ROLE_AutonomousProxy or UE4.UKismetSystemLibrary.IsStandalone(self) then

        --- 退出开镜
        if self:IsWeaponAim() then
            self.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM, false)
        end

        self:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_DOWN)
    end
end

function BP_ShooterCharacterBase_C:OnResurgence_S()

    if not self:IsValid() then
        return
    end

    if self:HasAuthority() then
        self.CharacterLastStatus = self.CharacterStatus
        self.CharacterStatus = ECharacterStatus.ECharacterStatus_ALIVE;

        self:SetCharacterDownTotalTimes()

        local AttrMgr = self:GetAttrMgr()
        if AttrMgr then
            local maxHp = AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP);
            local resurgenceHp = AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_RESURGENCE_HP);
            resurgenceHp = math.min(resurgenceHp , maxHp)
            AttrMgr:AttrOpeSet(Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP, resurgenceHp, Ds_ATTRADDTYPE.ATTRADD_BASE);
        end

        self:ClientOnResurgence()

        if UE4.UKismetSystemLibrary.IsStandalone(self) then
            self:OnResurgence_C()
        end
    end
end

function BP_ShooterCharacterBase_C:OnResurgence_C()
    self.CharacterStatus = ECharacterStatus.ECharacterStatus_ALIVE;

    self:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)
end


-------------------------------------------------------------------------
-- Input Event
-------------------------------------------------------------------------
-- 前后移动
function BP_ShooterCharacterBase_C:MoveForward(AxisValue)
    if not self:CanMove() then
        return
    end

    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if PlayerController then
        if PlayerController:GetIsVirtualGamePad() then
            return
        end
    end

    self:LogicMoveForward(AxisValue) 
end

function BP_ShooterCharacterBase_C:LogicMoveForward(AxisValue)
    self.InputAxisForward = AxisValue

    if AxisValue ~= 0.0 and self.Controller then        
        -- -- Limit pitch when walking or falling
        -- local bLimitRotation = self.CharacterMovement:IsMovingOnGround() or self.CharacterMovement:IsFalling()
        -- local Rotation = (bLimitRotation == true) and self:K2_GetActorRotation() or self.Controller:GetControlRotation()

        local Rotation = self.Controller:GetControlRotation()
        Rotation:Set(0, Rotation.Yaw, 0)
        local Direction = Rotation:GetForwardVector()

        if self:IsEnteringCover() then
            Direction, AxisValue = self.CoverComponent:PerformEnteringMove(Direction, AxisValue)
        elseif self:IsCovering() then
            Direction, AxisValue = self.CoverComponent:PerformCoveringMove(Direction, AxisValue)
        elseif self:IsVaultingCover() or self:IsChangingCover() then
            AxisValue = 0
        end

        self:AddMovementInput(Direction, AxisValue)
    end

end

-- 左右移动
function BP_ShooterCharacterBase_C:MoveRight(AxisValue)
    if not self:CanMove() then
        return
    end

    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if PlayerController then
        if PlayerController:GetIsVirtualGamePad() then
            return
        end
    end

    self:LogicMoveRight(AxisValue)
end

function BP_ShooterCharacterBase_C:LogicMoveRight(AxisValue) 
    self.InputAxisRight = AxisValue

    if AxisValue ~= 0.0 and self.Controller then
        local Rotation = self.Controller:GetControlRotation()
        Rotation:Set(0, Rotation.Yaw, 0)
        local Direction = Rotation:GetRightVector()

        if self:IsEnteringCover() then
            Direction, AxisValue = self.CoverComponent:PerformEnteringMove(Direction, AxisValue)
        elseif self:IsCovering() then
            Direction, AxisValue = self.CoverComponent:PerformCoveringMove(Direction, AxisValue)
        elseif self:IsVaultingCover() or self:IsChangingCover() then
            AxisValue = 0
        end
        
        self:AddMovementInput(Direction, AxisValue)
    end
end

-- 左右旋转视角
function BP_ShooterCharacterBase_C:Turn(AxisValue)
    if not self:CanTurnCamera(false) then
        return
    end

    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if not PlayerController or PlayerController.bShowMouseCursor then
        return
    end

    if AxisValue ~= 0.0 then
        --- 瞄准敌人转向减速效果
        if self:IsAimSlowMode() then
            AxisValue = AxisValue * self:GetCameraSlowDownInputScale()
        end

        self:AddControllerYawInput(AxisValue)

        --- 在掩体中
        if self.CoverComponent and self.CoverComponent:IsCovering() then
            self.CoverComponent:PerformCoveringTurn()
        end
    end

    self.InputAxisYaw = AxisValue
end

-- 左右旋转视角(控制速率)
function BP_ShooterCharacterBase_C:TurnRate(AxisValue)
    if not self:CanTurnCamera(false) then
        return
    end

    if AxisValue ~= 0.0 then
        local DeltaSeconds = UE4.UGameplayStatics.GetWorldDeltaSeconds(self)
        AxisValue = AxisValue * DeltaSeconds * self.BaseTurnRate
        self:AddControllerYawInput(AxisValue)

        --- 在掩体中
        if self.CoverComponent and self.CoverComponent:IsCovering() then
            self.CoverComponent:PerformCoveringTurn()
        end
    end

    self.InputAxisYaw = AxisValue
end

-- 上下旋转视角
function BP_ShooterCharacterBase_C:LookUp(AxisValue)
    if not self:CanTurnCamera(true) then
        return
    end

    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if not PlayerController or PlayerController.bShowMouseCursor then
        return
    end

    if AxisValue ~= 0.0 then
        
        if self:IsFiring() then
            self.FiringInputAxisPitch = self.FiringInputAxisPitch + AxisValue
        end

        --- 瞄准敌人转向减速效果
        if self:IsAimSlowMode() then
            AxisValue = AxisValue * self:GetCameraSlowDownInputScale()
        end

        self:AddControllerPitchInput(AxisValue)
    end

    self.InputAxisPitch = AxisValue
end

-- 上下旋转视角(控制速率)
function BP_ShooterCharacterBase_C:LookUpRate(AxisValue)
    if not self:CanTurnCamera(true) then
        return
    end

    if AxisValue ~= 0.0 then
        local DeltaSeconds = UE4.UGameplayStatics.GetWorldDeltaSeconds(self)
        AxisValue = AxisValue * DeltaSeconds * self.BaseLookUpRate

        if self:IsFiring() then
            self.FiringInputAxisPitch = self.FiringInputAxisPitch + AxisValue
        end

        self:AddControllerPitchInput(AxisValue)
    end

    self.InputAxisPitch = AxisValue
end

-- 后坐力-向上旋转视角
function BP_ShooterCharacterBase_C:LookUpRecoil(AxisValue)
    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if not PlayerController or PlayerController.bShowMouseCursor then
        return
    end

    if AxisValue ~= 0.0 then
     
        --固定速度
        AxisValue = AxisValue  * self.BaseLookUpRate / 30.0;
        self.FiringRecoilAxisPitch = self.FiringRecoilAxisPitch + AxisValue

        self:AddControllerPitchInput(AxisValue)
    end
end

-------------------------------------------------------------------------
-------------------------------------------------------------------------
-- 跑(按下)
function BP_ShooterCharacterBase_C:Run_Pressed()
    self.bPressRunBtn = true
    if not self:CanMove() then
        return
    end

    if not self:CanRun() then
        return
    end

    -- 冲锋时, 取消开火
    if self.EquipComponent and self.EquipComponent:IsFiring() then
        self.EquipComponent:StopFire()
    end
    
    -- 冲锋时, 取消开镜
    if self:IsWeaponAim() then
        self.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM, false)
    end
    
    --掩体中探头冲锋
    -- if self:IsCovering() and self.CoverComponent:IsReadyForRun() then
    --     self.CoverComponent:LeaveCover()
    -- end

    local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if PlayerController and PlayerController:IsGameInputAllowed() then
        if self.CharacterMovementComponent then
            self.CharacterMovementComponent:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RUN)
        end
    end
end

-- 跑(松开)
function BP_ShooterCharacterBase_C:Run_Released()
    self.bPressRunBtn = false
    if not self:CanMove() then
        return
    end

    if not self:CanRun() then
        return
    end

    if self.CharacterMovementComponent then
        self.CharacterMovementComponent:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)
    end
end

-- jump
function BP_ShooterCharacterBase_C:Jump_Pressed()

    self:RollAction_Pressed()
    --if not self:CanMove() then
    --    return
    --end
    --
    --local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    --if PlayerController and PlayerController:IsGameInputAllowed() then
    --
    --    self:Jump();
    --
    --    --关闭瞄准
    --    if self:IsWeaponAim() then
    --        self.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM, false)
    --    end
    --
    --    if self.CharacterMovementComponent then
    --        self.CharacterMovementComponent:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_JUMP)
    --    end
    --end
end

function BP_ShooterCharacterBase_C:Jump_Released()
    --self:RollAction_Released()
    --self:StopJumping();
    --
    --if self.CharacterMovementComponent then
    --    self.CharacterMovementComponent:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)
    --end
end

-- 瞄准(按下)
function BP_ShooterCharacterBase_C:Aim_Pressed()
    if not self:CanAim() then
        return
    end

    --查询武器是否可瞄准
    local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if PlayerController and PlayerController:IsGameInputAllowed() and self.EquipComponent and self.CharacterMovementComponent then

        local bWeaponAim = self:IsWeaponAim();
        if not bWeaponAim then
            --武器不支持
            local curEquipActor = self:GetCurEquipActor();
            local EquipAimMode = curEquipActor and curEquipActor:GetEquipAimMode() or EEquipAimMode.EEquipAimMode_NONE;
            if EquipAimMode == EEquipAimMode.EEquipAimMode_NONE then
                return
            elseif EquipAimMode == EEquipAimMode.EEquipAimMode_TPP then
                PlayerController:SetCharacterCameraMode(UE4.ECharacterCameraMode.ThirdPerson);
            elseif EquipAimMode == EEquipAimMode.EEquipAimMode_FPP then
                PlayerController:SetCharacterCameraMode(UE4.ECharacterCameraMode.FirstPerson);
            end
            
            -- 瞄准的时候结束跑的状态
            if self:IsRunning() then
                self.CharacterMovementComponent:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)
            end

            self.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM, true)

            --- 在掩体中朝向掩体开镜，需要站起来
            if self.CoverComponent and self.CoverComponent:IsCovering() and self.CoverComponent:GetPlayerFaceToCoverCrossZ() > 0 then
                if self.CharacterMovementComponent:IsCrouching() then
                    self:UnCrouch(true)
                end
            end
        else
        
            PlayerController:SetCharacterCameraMode(UE4.ECharacterCameraMode.ThirdPerson);

            self.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM, false)

            --- 在矮掩体中关闭开镜，需要蹲下
            if self.CoverComponent and self.CoverComponent:IsCovering() and self.CoverComponent:GetCoverHeightType() == UE4.ECoverHeightType.ECoverHeightType_Low then
                if not self.CharacterMovementComponent:IsCrouching() then
                    self:Crouch(true)
                end
            end
        end
    end
    
end

-- 瞄准(松开)
function BP_ShooterCharacterBase_C:Aim_Released()
    
end

-- 开火(按下)
function BP_ShooterCharacterBase_C:Fire_Pressed()
    if self:CanFire() then
        if self.EquipComponent then
            self.EquipComponent:StartFire()
        end
    end
end

-- 开火(松开)
function BP_ShooterCharacterBase_C:Fire_Released()
    if self.EquipComponent and self.EquipComponent:IsFiring() then
        self.EquipComponent:StopFire()
    end
end 

-- 换弹(按下)
function BP_ShooterCharacterBase_C:Reload_Pressed()
    if self.EquipComponent then
        self.EquipComponent:StartReload()

        if self:IsFiring() then
            self.EquipComponent:StopFire()
        end

    end
end

-- 掩体(按下)
function BP_ShooterCharacterBase_C:Cover_Pressed()
    --拾取道具
    local PickRangeSq = g_GamePickRange * g_GamePickRange;
    local AllActors = UE4.UGameplayStatics.GetAllActorsOfClass(self, ShooterGameInstance.LevelDropItemClass)
    for i = 1, AllActors:Length() do

        local item = AllActors:Get(i)
        local Direction = item:K2_GetActorLocation() - self:K2_GetActorLocation();
        local DistSq = Direction:SizeSquared();
        
        if DistSq <= PickRangeSq then
            self:ServerPickDropItem_F();
            return;
        end    
    end

    if not self:CanCover() then
        return
    end

    if self:IsCovering() then
        if self.CoverComponent then
            if self.CoverComponent:IsReadyVaultCover() then
                -- 翻越掩体
                self.CoverComponent:VaultCover() 
            elseif self.CoverComponent:IsReadyChangeCover() then
                -- 切换掩体
                self.CoverComponent:ChangeCover()
            else
                -- 退出掩体
                self.CoverComponent:LeaveCover()
            end
        end
    else    
        if self.CoverComponent then
            self.CoverComponent:EnterCover(false)
        end
    end
end


function BP_ShooterCharacterBase_C:ResurgeTeammate_Pressed()

    if not self:IsAlive() then
        return
    end
    
    if not self:IsResurgeTeammate() then
        local rescuer = self:GetCheckBeRescuer()
        if rescuer then
            self.CharacterMovementComponent:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RESURGETEAMMATE)
        end
    else
        self.CharacterMovementComponent:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)
        return
    end
    
    local MortalBlowsActor = self:GetMortalBlowsActor()
    if MortalBlowsActor then
        self:OnMortalBlowsEnemy_C()
    end
end

function BP_ShooterCharacterBase_C:ResurgeTeammate_Released()

end

-- 战术翻滚(按下)
function BP_ShooterCharacterBase_C:RollAction_Pressed()
    if not self:CanRolling() then
        return
    end

    local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if PlayerController and PlayerController:IsValid() and PlayerController:IsGameInputAllowed() then

        -- 战术翻滚，取消行为
        self:RollCancelBehavior()

        if self.CharacterMovementComponent then

            local Rotation = self.Controller:GetControlRotation()
            Rotation:Set(0, Rotation.Yaw, 0)
            local Direction = Rotation:GetForwardVector()

            local DirY  , DirX = 0 , 0
            local inputX , inputY = self.InputAxisForward , self.InputAxisRight

            DirY = self:InputDirStandardized(inputX)
            DirX = self:InputDirStandardized(inputY)
            if DirY == 0 and DirX == 0 then
                DirY = 1
            end

            Direction = self:GetRollDirection(DirX,DirY)
            self.RollDirection = Direction

            self:OnSetRollAnimeDirection(DirX,DirY)
            self:ServerOnSetRollAnimeDirection(DirX,DirY)

            self.CharacterMovementComponent:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_ROLL)
        end
    end
end

function BP_ShooterCharacterBase_C:GetRollDirection(DirX , DirY)
    local PawnDir = UE4.FVector(0,0,0)
    local Rotation = self.Controller:GetControlRotation()
    Rotation:Set(0, Rotation.Yaw, 0)

    local Direction = UE4.FVector()
    local ForwardVector = Rotation:GetForwardVector()
    local RightVector = Rotation:GetRightVector()

    if DirY < 0 then
        ForwardVector.X = -ForwardVector.X
        ForwardVector.Y = -ForwardVector.Y
    elseif DirY == 0 then
        ForwardVector.X = 0
        ForwardVector.Y = 0
    end

    if DirX < 0 then
        RightVector.X = -RightVector.X
        RightVector.Y = -RightVector.Y
    elseif DirX == 0 then
        RightVector.X = 0
        RightVector.Y = 0
    end

    ForwardVector.Z = 0
    RightVector.Z = 0

    if DirX == 0 and DirY == 0 then
        Direction = ForwardVector
    else
        Direction = ForwardVector + RightVector
    end

    return Direction
end

function BP_ShooterCharacterBase_C:OnSetRollAnimeDirection(DirX , DirY)
    self.RollInputDirection.X = DirX
    self.RollInputDirection.Y = DirY
end

function BP_ShooterCharacterBase_C:InputDirStandardized(InputValue)

    if InputValue > self.DeadZone then
        return 1
    elseif InputValue < -self.DeadZone then
        return -1
    else
        return 0
    end
end

-- 战术翻滚(松开)
function BP_ShooterCharacterBase_C:RollAction_Released()

end

-- 武器切换(按下)
function BP_ShooterCharacterBase_C:NextWeapon_Pressed()
    self:ServerChangeCurEquipBarType(Ds_EquipBarType.EQUIPBARTYPE_NONE, true);
end

-- 武器切换(按下)
function BP_ShooterCharacterBase_C:PrevWeapon_Pressed()

    self:ServerChangeCurEquipBarType(Ds_EquipBarType.EQUIPBARTYPE_NONE, true);
end

function BP_ShooterCharacterBase_C:Num1_Pressed()
    self:ServerChangeCurEquipBarType(Ds_EquipBarType.EQUIPBARTYPE_WEAPON1, false);
end

function BP_ShooterCharacterBase_C:Num2_Pressed()
   self:ServerChangeCurEquipBarType(Ds_EquipBarType.EQUIPBARTYPE_WEAPON2, false);
end

function BP_ShooterCharacterBase_C:Num3_Pressed()
    self:ServerChangeCurEquipBarType(Ds_EquipBarType.EQUIPBARTYPE_THROW, false);
end


--C
function BP_ShooterCharacterBase_C:Crouch_Pressed()

    if not self.CharacterMovementComponent:IsCrouching() then
        self:Crouch(true)
    else
        self:UnCrouch(true)
    end
end

-------------------------------------------------------------------------
-- Replicated Notify
-------------------------------------------------------------------------
-- 角色属性同步
function BP_ShooterCharacterBase_C:OnRep_Attrs(RepCharacterAttr)
    self:OnAttrChange_C()
end

-- 服务端修改角色属性
function BP_ShooterCharacterBase_C:OnAttrChange_S(iAttrID)
    if self:HasAuthority() then
        local AttrMgr = self:GetAttrMgr()
        if AttrMgr then
            self.Attrs:Set(iAttrID, AttrMgr:GetAttr(iAttrID))
        end
        if iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_HP then
            self.CurHp = AttrMgr:GetAttr(iAttrID)
        elseif iAttrID == Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_HP then
            self.CurHpMax = AttrMgr:GetAttr(iAttrID)
        end

        -- 通知UI刷新
        LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_ATTRDATACHAGNE)
    end
end

-- 客户端同步角色属性
function BP_ShooterCharacterBase_C:OnAttrChange_C()
    if self:HasAuthority() then
        return
    end
    -- 收到服务器属性同步给客户端记录
    local AttrMgr = self:GetAttrMgr()
    if AttrMgr then
        for iAttrID = Ds_ResCharacterAttrType.EN_CHARACTERATTR_MIN + 1, Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX do
            AttrMgr:SetAttr_C(iAttrID, self.Attrs:Get(iAttrID))
        end
    end

    -- 通知UI刷新
    LUIManager:PostMsg(Ds_UIMsgDefine.UI_BATTLE_CHARACTER_ATTRDATACHAGNE)
end

--伤害RPC
function BP_ShooterCharacterBase_C:OnRep_LastTakeHitInfo()
    
	if self.LastTakeHitInfo.CharacterStatus == ECharacterStatus.ECharacterStatus_DYING then
		self:OnDie_C(self.LastTakeHitInfo.ActualDamage, self.LastTakeHitInfo.GeneralDamageEvent, self.LastTakeHitInfo.PawnInstigator,
            self.LastTakeHitInfo.DamageCauser);	
	elseif self.LastTakeHitInfo.CharacterStatus == ECharacterStatus.ECharacterStatus_DOWN then
        self:OnDown_C(self.LastTakeHitInfo.ActualDamage, self.LastTakeHitInfo.GeneralDamageEvent, self.LastTakeHitInfo.PawnInstigator,
                self.LastTakeHitInfo.DamageCauser);
    else
        self:OnBeHit_C(self.LastTakeHitInfo.ActualDamage, self.LastTakeHitInfo.GeneralDamageEvent, self.LastTakeHitInfo.PawnInstigator,
                self.LastTakeHitInfo.DamageCauser);
    end

end

--伤害
function BP_ShooterCharacterBase_C:ReplicateHit(Damage, DamageEvent, AP_PawnInstigator, AA_DamageCauser, CharacterStatus,DamageTypeID)

	local TimeoutTime = UE4.UGameplayStatics.GetTimeSeconds(self:GetWorld()) + 0.5;

	if AP_PawnInstigator == self.LastTakeHitInfo.PawnInstigator and
		self.LastTakeHitInfo.DamageEventClassID == DamageEvent:GetTypeID() and
		self.LastTakeHitTimeTimeout == TimeoutTime then
	
		if (CharacterStatus == ECharacterStatus.ECharacterStatus_DYING and self.LastTakeHitInfo.CharacterStatus == ECharacterStatus.ECharacterStatus_DYING) then
			return;
        end

		-- otherwise, accumulate damage done this frame
		Damage = Damage + self.LastTakeHitInfo.ActualDamage;
    end
    
	self.LastTakeHitInfo.ActualDamage = Damage;
	self.LastTakeHitInfo.PawnInstigator = AP_PawnInstigator;
	self.LastTakeHitInfo.DamageCauser = AA_DamageCauser;
    --self.LastTakeHitInfo.DamageEventClassID = DamageEvent:GetTypeID()
    self.LastTakeHitInfo.DamageEventClassID = DamageTypeID
    self.LastTakeHitInfo.GeneralDamageEvent = DamageEvent;
	self.LastTakeHitInfo.CharacterStatus = CharacterStatus;

	self.LastTakeHitTimeTimeout = TimeoutTime;
end

--拾取道具(服务器)
function BP_ShooterCharacterBase_C:PickDropItem_F_S()
    local equipMgr = self:GetEquipMgr();
    if equipMgr == nil then
        return;
    end

    local CurGameMode = UE4.UGameplayStatics.GetGameMode(self);
    CurGameMode = CurGameMode and CurGameMode:Cast(UE4.ABP_ShooterGameModeBase_C) or nil;
    if CurGameMode == nil then
        return;
    end

    --拾取道具
    local LevelItemPawnMgr = CurGameMode:GetLevelItemPawnMgr();
    local FindLevelItem =  LevelItemPawnMgr:GetClosestBestDropItem(self);
    if FindLevelItem ~= nil then

        local ResItemDesc =  GameResMgr:GetGameResDataByResID("ItemDesc_Res", FindLevelItem.ItemResID)
        if not ResItemDesc then
            print("-----Error: BP_ShooterCharacterBase_C::ServerPickDropItem_F ResItemDesc is null resID = ", ResItemDesc.ItemResID)
            return
        end
 
        equipMgr:RequsetEquip(ResItemDesc, FindLevelItem.BulletNum);
        FindLevelItem:PickItem();
          
    end

end

--切换武器栏(服务器)
function BP_ShooterCharacterBase_C:ChangeCurEquipBarType_S(EquipBarType, bNextWeapon)

    local equipMgr = self:GetEquipMgr();
    if equipMgr == nil then
        return;
    end

    local changeEquipBarType = EquipBarType;
    local curEquipBarType = equipMgr:GetCurEquipBarType();
    if EquipBarType == Ds_EquipBarType.EQUIPBARTYPE_NONE or bNextWeapon then
        changeEquipBarType = equipMgr:GetPreEquipBarType();
    end

    --- 当前使用的枪械不应该把其放回背上
    if changeEquipBarType == curEquipBarType then
        return
    end

    local equipElement = self.EquipComponent:GetWeaponByBarType(curEquipBarType)
    local newEquipElement = self.EquipComponent:GetWeaponByBarType(changeEquipBarType)
    if equipElement == nil or newEquipElement == nil then
        return;
    else
        if equipElement:IsEquipDowning() or equipElement:IsEquipUping() or
            newEquipElement:IsEquipDowning() or newEquipElement:IsEquipUping() then
            return
        end
    end

    if self.EquipComponent then
        self.EquipComponent:StopReload()
    end

    equipMgr:RequsetChangeCurEquipBarType(changeEquipBarType);
end


--------------------------------------------------------
--- Character Resurgence 角色自救 角色被救
--------------------------------------------------------
--- 角色自救开始 Server
function BP_ShooterCharacterBase_C:OnHandleResurgenceStart()
    self.bInResurgence = true
    self.Resurgence_Timer = 0.0

    if self:GetRescuerActor() then
        self:SetRescuerActor(nil)
    end
end

--- 角色自救结束 Server
function BP_ShooterCharacterBase_C:OnHandleResurgenceEnd()
    self.bInResurgence = false
    self.Resurgence_Timer = 0.0

    --- 救援完成解除救援
    self:OnHandleClearRescuer()
    self:OnResurgence_S()
end

--- 清除救援者
function BP_ShooterCharacterBase_C:OnHandleClearRescuer()

    if self:HasAuthority() then
        if self:IsBeResurge() then
            local rescuerActor = self:GetRescuerActor()
            if rescuerActor and rescuerActor:IsValid() and rescuerActor:IsAlive() then
                rescuerActor:ClientChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)
                rescuerActor:SetCheckBeRescuer(nil)
            end

            self:SetRescuerActor(nil)
        elseif self:IsResurgeTeammate() then
            self:ClientChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)

            local  beRescuer = self:GetCheckBeRescuer()
            if beRescuer then
                beRescuer:SetRescuerActor(nil)
            end

            self:SetCheckBeRescuer(nil)
        end
    end
end

--- 救援队友
function BP_ShooterCharacterBase_C:ResurgeTeammate_C(bCancel)
    if not self:HasAuthority() then
        self:ServerResurgeTeammate(bCancel)
    else
        if UE4.UKismetSystemLibrary.IsStandalone(self) then
            self:ResurgeTeammate_S(bCancel)
        end
    end
end

--- 救援队友 (Server)
function BP_ShooterCharacterBase_C:ResurgeTeammate_S(bCancel)
    if not self:GetCheckBeRescuer() then
        self:SetCheckBeRescuer(self:GetBeRescuerActor())
    end

    local beRescuer = self:GetCheckBeRescuer()
    if beRescuer then
        if bCancel then
            self:OnHandleClearRescuer()
        else
            beRescuer:SetRescuerActor(self)
        end
    end
end

---
function BP_ShooterCharacterBase_C:UpdateCheckBeRescuer()
    self:SetCheckBeRescuer(self:GetBeRescuerActor())
end

--- 再起自救、被救逻辑
function BP_ShooterCharacterBase_C:UpdateResurgence(deltaTime)
    if self:HasAuthority() then
        if self.bInResurgence then

            local rescuerActor = self:GetRescuerActor()
            if not rescuerActor then
                --- TODO: 自救
                self.Resurgence_Timer = self.Resurgence_Timer + (self:GetSelfRescueSpeed() * deltaTime)
                --UE4.UKismetSystemLibrary.PrintString(self , "自救")
            else
                --- TODO: 被救
                if rescuerActor:IsAlive() then
                    --UE4.UKismetSystemLibrary.PrintString(self , "被救")
                    self.Resurgence_Timer = self.Resurgence_Timer + (rescuerActor:GetRescueSpeed() * deltaTime)
                else
                    --- 救助者倒地或者死亡
                    self:OnHandleClearRescuer()
                end
            end

            if self.Resurgence_Timer >= self:GetResurgenceTime() then
                self:OnHandleResurgenceEnd()
            end
        end
    end
end

--------------------------------------------------------
--- Character MortalBlows 处决
--------------------------------------------------------
function BP_ShooterCharacterBase_C:OnMortalBlowsEnemy_S()
    local MortalBlowsActor = self:GetMortalBlowsActor()
    if MortalBlowsActor and MortalBlowsActor:IsValid() and not MortalBlowsActor:IsMortalBlows() then
        self:OnHandleMortalBlowsEnemyStart(MortalBlowsActor)
    end
end

function BP_ShooterCharacterBase_C:OnMortalBlowsEnemy_C()
    local MortalBlowsActor = self:GetMortalBlowsActor()
    if MortalBlowsActor then
        if not UE4.UKismetSystemLibrary.IsStandalone(self) then
            self:ServerMortalBlowsEnemy()
        end
    end
end

function BP_ShooterCharacterBase_C:OnTriggerMortalBlows_C(iFlag , bKiller)
    UE4.UKismetSystemLibrary.PrintString(self , "OnHandleTriggerMortalBlows_C ...")

    self.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_MortalBlows, iFlag)
end

function BP_ShooterCharacterBase_C:UpdateMortalBlowsTime(DeltaSeconds)

    if self.bTriggerMortalBlows then
        self.MortalBlowsTimer = self.MortalBlowsTimer + DeltaSeconds

        if self.MortalBlowsTimer >= self:GetAllMortalBlowsTime() then
            --- Take Down Finished
            self:OnHandleMortalBlowsEnemyEnd()
        end
    end
end

function BP_ShooterCharacterBase_C:OnHandleMortalBlowsEnemyStart(MortalBlowsActor)
    UE4.UKismetSystemLibrary.PrintString(self , "OnHandleMortalBlowsEnemyStart ...")

    --- 开始计时
    --- 通知客户端切换状态、通知QTE状态
    self.bTriggerMortalBlows = true
    self.MortalBlowsTimer = 0.0    

    self:ClientTriggerMortalBlows(true , true)
    MortalBlowsActor:ClientTriggerMortalBlows(true , false)

    self:SetTakingDownActor(MortalBlowsActor)

end

function BP_ShooterCharacterBase_C:OnHandleMortalBlowsEnemyEnd()
    UE4.UKismetSystemLibrary.PrintString(self , "OnHandleMortalBlowsEnemyEnd ...")
    self.bTriggerMortalBlows = false
    self.MortalBlowsTimer = 0.0
    
    self:ClientTriggerMortalBlows(false , true)

    local MortalBlowsActor = self:GetInMortalBlowsActor()
    if MortalBlowsActor and MortalBlowsActor:IsValid() then

        UE4.UGameplayStaticsExt.ApplyMortalBlowsDamage(MortalBlowsActor , 99999 , self:GetController() , nil , self.MortalBlowsDamageType)

        MortalBlowsActor:ClientTriggerMortalBlows(false , false)
    end

    self:SetTakingDownActor(nil)
end

function BP_ShooterCharacterBase_C:SetTakingDownActor(MortalBlowsActor)
    self.MortalBlowsActor = MortalBlowsActor
end

function BP_ShooterCharacterBase_C:GetInMortalBlowsActor()
    return self.MortalBlowsActor
end

function BP_ShooterCharacterBase_C:GetAllMortalBlowsTime()
    return self:GetMortalBlowsQTETime() + self:GetMortalBlowsAnimeTime()
end

--- 处决动画时间
function BP_ShooterCharacterBase_C:GetMortalBlowsAnimeTime()
    return 5.0
end

--- 处决QTE时间
function BP_ShooterCharacterBase_C:GetMortalBlowsQTETime()
    return 1.0
end

--------------------------------------------------------
--- Reset Pawn Rotation
--------------------------------------------------------
--- 触发 BeginResetPawnRotation 动画通知时候调用
function BP_ShooterCharacterBase_C:BeginResetPawnRotation()
    if not self:HasAuthority() or UE4.UKismetSystemLibrary.IsStandalone(self) then
        self:OnResetPawnRotation()
    end
end

--- 触发旋转重置 Pawn
function BP_ShooterCharacterBase_C:OnResetPawnRotation()
    if self.IsResetPawnRotation then
        return
    end

    self.IsResetPawnRotation = true
    self.ResetPawnRotateTimer = 0.0
    self.bUseControllerRotationYaw = false
    self.ResetPawnRotationStart = self:K2_GetActorRotation()

    --if not self:HasAuthority() and self:GetLocalRole() == UE4.ENetRole.ROLE_AutonomousProxy then
    --    self:ServerOnResetPawnRotation()
    --end
end

--- 重置 Pawn 旋转更新
function BP_ShooterCharacterBase_C:UpdateResetPawnRotation(deltaTime)
    if not self.Controller or not self.Controller:IsValid() then
        return
    end

    self:UpdateResetPawnYawRotation(deltaTime)
end

--- 获取旋转 Pawn Yaw
function BP_ShooterCharacterBase_C:GetResetRotationYaw(controllerYaw)
    local ResetPawnRotation = self.ResetPawnRotationStart
    if not ResetPawnRotation then
        return 0.0
    end

    local LeftBounderYaw , RightBounderYaw = controllerYaw - 180 , controllerYaw + 180
    local PawnRotationYaw = ResetPawnRotation.Yaw

    if PawnRotationYaw < LeftBounderYaw then
        PawnRotationYaw = PawnRotationYaw + 180
    elseif PawnRotationYaw > RightBounderYaw then
        PawnRotationYaw = PawnRotationYaw - 180
    end

    return PawnRotationYaw
end

--- 更新旋转 Pawn Yaw
function BP_ShooterCharacterBase_C:UpdateResetPawnYawRotation(deltaTime)
    if not self:HasAuthority() or UE4.UKismetSystemLibrary.IsStandalone(self) then
        if self.IsResetPawnRotation then
            self.ResetPawnRotateTimer = self.ResetPawnRotateTimer + deltaTime

            local Alpha = self.ResetPawnRotationCurve:GetFloatValue(self.ResetPawnRotateTimer)
            Alpha = math.min(Alpha , 1)
            local ControllerRotation = self.Controller:K2_GetActorRotation()
            local ControllerYaw = ControllerRotation.Yaw
            local PawnRotationYaw = self:GetResetRotationYaw(ControllerYaw)

            PawnRotationYaw = UE4.UKismetMathLibrary.Lerp(PawnRotationYaw ,ControllerYaw , Alpha)
            local bResetFinish = math.abs(PawnRotationYaw - ControllerYaw)  <= 0.1
            if bResetFinish then
                self:OnExitResetPawnRotation()

                --if UE4.UKismetSystemLibrary.IsStandalone(self) then
                --    self:OnExitResetPawnRotation()
                --end
            else
                --- 设置旋转
                self:UpdateSetPawnRotation(PawnRotationYaw)
                self:ServerUpdateResetPawnRotation(PawnRotationYaw)
            end
        end
    end
end

--- 设置 Pawn Yaw
function BP_ShooterCharacterBase_C:UpdateSetPawnRotation(Yaw)
    local newRotator = UE4.FRotator(0, Yaw, 0)
    self:K2_SetActorRotation(newRotator , false)
end

--- 退出旋转
function BP_ShooterCharacterBase_C:OnExitResetPawnRotation()
    if not self:HasAuthority() then
        self.bUseControllerRotationYaw = true
        self.IsResetPawnRotation = false
        self.ResetPawnRotateTimer = 0.0
    else
        self.bUseControllerRotationYaw = true
        self.IsResetPawnRotation = false
    end
end


-------------------------------------------------------------------------
-- 设置数据接口
-------------------------------------------------------------------------
-- 切换相机
function BP_ShooterCharacterBase_C:UpdateCharacterCameraMode()

    local bFirstPerson = self:IsFirstPerson()
    if bFirstPerson then
        self.TPPCamera:Deactivate()
        self.FPPCamera:Activate(true)
    else
        self.FPPCamera:Deactivate()
        self.TPPCamera:Activate(true)

        --- 第一层逻辑区分：站、蹲
        --- 第二层逻辑区分：开镜、冲刺、翻滚
        --- 第二层逻辑区分：掩体边缘、掩体状态
        if self:IsCrouching() then
            --- 开镜
            if self:IsWeaponAim() then
                local CurEquipActor = self:GetCurEquipActor()
                if CurEquipActor then
                    self.TPP_Target_CameraSpringData = self:IsCovering() and CurEquipActor.TPP_Cover_CrouchAim_CameraSpringData or CurEquipActor.TPP_CrouchAim_CameraSpringData
                    self.TPP_Target_CameraSpringData.CameraFov = CurEquipActor:GetTargetingFOV()
                end
            --- 冲刺
            elseif self:IsRunning() then
                self.TPP_Target_CameraSpringData = self.TPP_Crouch_CameraSpringData --- 暂用蹲，策划目前无需求
            --- 翻滚
            elseif self:IsInRolling() then
                self.TPP_Target_CameraSpringData = self.TPP_Crouch_CameraSpringData --- 暂用蹲，策划目前无需求
            --- 切换掩体
            elseif self:IsChangingCover() then
                self.TPP_Target_CameraSpringData = self.TPP_Crouch_ChangeCover_CameraSpringData
            else
                self.TPP_Target_CameraSpringData = self.TPP_Crouch_CameraSpringData
            end
        else
            --- 开镜
            if self:IsWeaponAim() then
                local CurEquipActor = self:GetCurEquipActor()
                if CurEquipActor then
                    self.TPP_Target_CameraSpringData = self:IsCovering() and CurEquipActor.TPP_Cover_Aim_CameraSpringData or CurEquipActor.TPP_Aim_CameraSpringData
                    self.TPP_Target_CameraSpringData.CameraFov = CurEquipActor:GetTargetingFOV()
                end
            --- 冲刺
            elseif self:IsRunning() then
                self.TPP_Target_CameraSpringData = self:IsCovering() and self.TPP_Default_Back_CameraSpringData or self.TPP_Running_CameraSpringData
            --- 翻滚
            elseif self:IsInRolling() then
                self.TPP_Target_CameraSpringData = self:IsCovering() and self.TPP_Default_Back_CameraSpringData or self.TPP_Roll_CameraData
            --- 倒地
            elseif self:IsDown() then
                self.TPP_Target_CameraSpringData = self:IsDown() and self.TPP_Down_CameraSpringData or self.TPP_Default_Back_CameraSpringData
            --- 进入掩体
            --elseif self:IsEnteringCover() then
            --    self.TPP_Target_CameraSpringData = self:IsCovering() and self.TPP_Default_Cover_CameraSpringData or self.TPP_EnterCover_CameraData
            --- 切换掩体
            elseif self:IsChangingCover() then
                self.TPP_Target_CameraSpringData = self.TPP_Default_ChangeCover_CameraSpringData
            else
                self.TPP_Target_CameraSpringData = self:IsCovering() and self.TPP_Default_Cover_CameraSpringData or self.TPP_Default_Back_CameraSpringData
            end
        end

        if self.TPP_Target_CameraSpringData then
            if  self.TPP_Target_CameraSpringData.CameraAnimaTime < 0.01 or self.TPP_Target_CameraSpringData.CameraAnimaCurve == nil then
                self.TPPSpringArm.TargetArmLength = self.TPP_Target_CameraSpringData.TargetArmLength
                self.TPPSpringArm.SocketOffset = self.TPP_Target_CameraSpringData.SocketOffset
                self.TPPSpringArm.TargetOffset = self.TPP_Target_CameraSpringData.TargetOffset

                if self.Controller and self.Controller.PlayerCameraManager then
                    self.Controller.PlayerCameraManager:SetFOV(self.TPP_Target_CameraSpringData.CameraFov)
                end

                self.TPP_Target_CameraSpringData = nil;
                self.CameraAnimationTime = 0.0;
            else
                self.TPP_Start_CameraSpringData.TargetArmLength = self.TPPSpringArm.TargetArmLength
                self.TPP_Start_CameraSpringData.SocketOffset = self.TPPSpringArm.SocketOffset
                self.TPP_Start_CameraSpringData.TargetOffset = self.TPPSpringArm.TargetOffset

                if self.Controller and self.Controller.PlayerCameraManager then
                    self.TPP_Start_CameraSpringData.CameraFov = self.Controller.PlayerCameraManager:GetFOVAngle()
                else
                    self.TPP_Start_CameraSpringData.CameraFov = 90.0
                end

                self.CameraAnimationTime = 0.0;
            end
        end
    end

    -- 用于记录旋转插值端点

    self.CameraUpdateLerpLeftRotate.Pitch = self.TPPCamera.RelativeRotation.Pitch
    self.CameraUpdateLerpLeftRotate.Yaw = self.TPPCamera.RelativeRotation.Yaw
    self.CameraUpdateLerpLeftRotate.Roll = self.TPPCamera.RelativeRotation.Roll

    self.Mesh1P:SetOwnerNoSee(not bFirstPerson)

    self.Mesh.VisibilityBasedAnimTickOption = bFirstPerson and UE4.EVisibilityBasedAnimTickOption.OnlyTickPoseWhenRendered or UE4.EVisibilityBasedAnimTickOption.AlwaysTickPoseAndRefreshBones
    self.Mesh:SetOwnerNoSee(bFirstPerson)

    if self.EquipComponent then
        self.EquipComponent:UpdateMeshes()
    end
end

function BP_ShooterCharacterBase_C:UpdateCameraAnimation(DeltaSeconds)
   
    if self.TPP_Target_CameraSpringData ~= nil then

        self.CameraAnimationTime = self.CameraAnimationTime + DeltaSeconds;
        local Alpha = self.TPP_Target_CameraSpringData.CameraAnimaCurve:GetFloatValue(self.CameraAnimationTime)
        Alpha = math.min(Alpha, 1.0)

        self.TPPSpringArm.TargetArmLength = UE4.UKismetMathLibrary.Lerp(self.TPP_Start_CameraSpringData.TargetArmLength, 
            self.TPP_Target_CameraSpringData.TargetArmLength, Alpha)

        local TargetOffset = UE4.FVector(self.TPP_Target_CameraSpringData.TargetOffset.X, self.TPP_Target_CameraSpringData.TargetOffset.Y,
                self.TPP_Target_CameraSpringData.TargetOffset.Z)
        local SocketOffset = UE4.FVector(self.TPP_Target_CameraSpringData.SocketOffset.X, self.TPP_Target_CameraSpringData.SocketOffset.Y,
                self.TPP_Target_CameraSpringData.SocketOffset.Z)

        --- 计算掩体中视角旋转、掩体边缘的偏移量
        local FaceToAxisAngleTargetOffsetY = 0
        local FaceToAxisAngleSocketOffsetY = 0
        if self.CoverComponent and self.CoverComponent:IsCovering() and not self:IsWeaponAim() then
            local FaceToAxisAnglePercent = 0

            --- 在掩体中旋转（左手持枪向右转、右手持枪向左转）
            if self.TPP_Turn_CameraSpringData then
                local FaceToAxisCrossZ = self.CoverComponent:GetLocalPlayerFaceToAxisCrossZ()
                if (FaceToAxisCrossZ < 0 and self:IsHoldEquipLeft()) or (FaceToAxisCrossZ >= 0 and not self:IsHoldEquipLeft()) then
                    --- 与掩体轴线的夹角
                    local FaceToAxisAngle = self.CoverComponent:GetLocalPlayerFaceToAxisAngle()
                    FaceToAxisAnglePercent = self.TPP_Turn_CameraSpringData.CameraAnimaCurve:GetFloatValue(FaceToAxisAngle)
                    FaceToAxisAnglePercent = math.min(1.0, math.max(0, FaceToAxisAnglePercent / MATH_SCALE_10K))

                    FaceToAxisAngleTargetOffsetY = (TargetOffset.Y * 2.0) * FaceToAxisAnglePercent
                    FaceToAxisAngleSocketOffsetY = (SocketOffset.Y * 2.0) * FaceToAxisAnglePercent
                end
            end


            if self.CoverComponent and self.CoverComponent:IsAllowChangeAxis() then
                --- 在掩体边缘，增加左右移动的范围
                if self.TPP_CoverEdge_CameraSpringData then
                    --- 距离掩体边缘的距离
                    local DistanceEdge = self.CoverComponent:GetDistanceEdgeAlongSpline()
                    local DistanceEdgePercent = self.TPP_CoverEdge_CameraSpringData.CameraAnimaCurve:GetFloatValue(DistanceEdge)
                    DistanceEdgePercent = math.min(1.0, math.max(0, DistanceEdgePercent / 100))

                    FaceToAxisAngleTargetOffsetY = (TargetOffset.Y * 2.0 + self.TPP_CoverEdge_CameraSpringData.TargetOffset.Y * DistanceEdgePercent) * FaceToAxisAnglePercent
                    FaceToAxisAngleSocketOffsetY = (SocketOffset.Y * 2.0 + self.TPP_CoverEdge_CameraSpringData.TargetOffset.Y * DistanceEdgePercent) * FaceToAxisAnglePercent

                    TargetOffset = TargetOffset + self.TPP_CoverEdge_CameraSpringData.TargetOffset * DistanceEdgePercent
                    SocketOffset = SocketOffset + self.TPP_CoverEdge_CameraSpringData.SocketOffset * DistanceEdgePercent
                end
            end
        end

        --- 左手持装备时相机的 Y轴取反
        if self:IsHoldEquipLeft() then
            TargetOffset = UE4.FVector(TargetOffset.X, -TargetOffset.Y + FaceToAxisAngleTargetOffsetY, TargetOffset.Z)
            SocketOffset = UE4.FVector(SocketOffset.X, -SocketOffset.Y + FaceToAxisAngleSocketOffsetY, SocketOffset.Z)
        else
            TargetOffset = UE4.FVector(TargetOffset.X, TargetOffset.Y - FaceToAxisAngleTargetOffsetY, TargetOffset.Z)
            SocketOffset = UE4.FVector(SocketOffset.X, SocketOffset.Y - FaceToAxisAngleSocketOffsetY, SocketOffset.Z)
        end

        self.TPPSpringArm.TargetOffset = UE4.UKismetMathLibrary.VLerp(self.TPP_Start_CameraSpringData.TargetOffset, TargetOffset, Alpha)
        self.TPPSpringArm.SocketOffset = UE4.UKismetMathLibrary.VLerp(self.TPP_Start_CameraSpringData.SocketOffset, SocketOffset, Alpha)

        --- 镜头旋转偏移
        if self.TPP_Target_CameraSpringData.CameraRotateAnimeCurve then

            if self.TPPCamera.bUsePawnControlRotation then
                self.TPPCamera.bUsePawnControlRotation = false
            end


            local AlphaForCamRotate = self.TPP_Target_CameraSpringData.CameraRotateAnimeCurve:GetFloatValue(self.CameraAnimationTime)

            AlphaForCamRotate = math.min(AlphaForCamRotate, 1.0)

            local hit = UE4.FHitResult()
            --- 为了满足可以往返插值需求 ，插值左边为记录旋转起始值self.CameraUpdateLerpLeftRotate UE4.FRotator(0 , 0 , 0)self.CameraUpdateLerpLeftRotate
            --local newRotator = UE4.UKismetMathLibrary.RLerp(UE4.FRotator(0 , 0 , 0), self.TPP_Target_CameraSpringData.CameraRotate, AlphaForCamRotate, false)
            --local newRotator = UE4.UKismetMathLibrary.RLerp(self.TPPCamera.RelativeRotation , self.TPP_Target_CameraSpringData.CameraRotate, AlphaForCamRotate, false)
            local newRotator = UE4.UKismetMathLibrary.RLerp(self.CameraUpdateLerpLeftRotate , self.TPP_Target_CameraSpringData.CameraRotate, AlphaForCamRotate, false)
            self.TPPCamera:K2_SetRelativeRotation(newRotator , false , hit , false)
        end

        if self.Controller and self.Controller.PlayerCameraManager then
            local cameraFov =  UE4.UKismetMathLibrary.Lerp(self.TPP_Start_CameraSpringData.CameraFov, self.TPP_Target_CameraSpringData.CameraFov, Alpha)
            self.Controller.PlayerCameraManager:SetFOV(cameraFov)
        end

        --if self.CameraAnimationTime >= self.TPP_Target_CameraSpringData.CameraAnimaTime then
        if Alpha >= 1.0 then
            self.TPP_Target_CameraSpringData = nil;
            self.CameraAnimationTime = 0.0;
        end
    end

end

--- 战术翻滚冷却计时刷新
function BP_ShooterCharacterBase_C:UpdateRollCD(deltaTime)
    if self:HasAuthority() then
        if self.bInRollingCD then
            self.RollingCDTimer = self.RollingCDTimer + deltaTime
            if self.RollingCDTimer >= self:GetRollCD() then
                self:OnHandleRollCDEnd()
            end
        end
    end
end

--- 竖直方向重置
function BP_ShooterCharacterBase_C:UpdateResetControlPitch(bReset)
    local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if PlayerController and PlayerController:IsGameInputAllowed() then
        PlayerController:ResetCharacterCameraPitch(bReset)
    end
end

function BP_ShooterCharacterBase_C:ClearFiringAxisPitch()
    self.FiringInputAxisPitch = 0.0
    self.FiringRecoilAxisPitch = 0.0
end

function BP_ShooterCharacterBase_C:UpdateRollMovement_C(bFinished)
    if not self:IsInRolling() then
        return
    end

    if not self:HasAuthority() then
        self:ClientUpdateRollMovement(bFinished)
    else
        if UE4.UKismetSystemLibrary.IsStandalone(self) then
            self:ClientUpdateRollMovement(bFinished)
        end
    end
end

function BP_ShooterCharacterBase_C:ClientUpdateRollMovement(bFinished)
    if self:GetLocalRole() == UE4.ENetRole.ROLE_AutonomousProxy or UE4.UKismetSystemLibrary.IsStandalone(self) then
        if not bFinished then
            if self.RollDirection then
                self:AddMovementInput(self.RollDirection, 1)
            end
        else
            if not self:HasAuthority() or UE4.UKismetSystemLibrary.IsStandalone(self) then
                if self.InputAxisForward ~= 0.0  then
                    self:OnResetPawnVelocity(true)
                    self:ServerOnResetPawnVelocity(true)
                else
                    self:OnResetPawnVelocity(false)
                    self:ServerOnResetPawnVelocity(false)
                end
            end

            -- 翻滚结束后，根据当时的操作来决定后续的行为
            if self:IsPressRunBtn() then
                self:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_RUN)
            else
                self:ChangeMoveMentLayer1Type(ECharacterMoveMentLayer1Type.ECHARACTERMOVEMENTLAYER1TYPE_WALK)
            end
        end
    end
end

-- 战术翻滚取消行为
function BP_ShooterCharacterBase_C:RollCancelBehavior()
    --- 退出开镜
    if self:IsWeaponAim() then
        self.CharacterMovementComponent:ChangeMoveMentLayer2Type(ECharacterMoveMentLayer2Type.ECHARACTERMOVEMENTLAYER2TYPE_WEAPONAIM, false)
    end

    --- 屏蔽开火
    if self:IsFiring() then
        if self.EquipComponent then
            self.EquipComponent:StopFire()
        end
    end

    if self:IsEnteringCover() or self:IsCovering() then
        self.CoverComponent:LeaveCover()
    end

end

function BP_ShooterCharacterBase_C:OnResetPawnVelocity(bClearVelocity)
    if not self.CharacterMovement then
        return
    end

    if self:HasAuthority() then
        if self.CharacterMovement:BP_HasPredictionData_Server() then
            self.CharacterMovement:BP_ResetPredictionData_Server()
        end
    else
        if self.CharacterMovement:BP_HasPredictionData_Client() then
            self.CharacterMovement:BP_ResetPredictionData_Client()
        end
    end

    local Rotation = self:GetControlRotation()
    local Direction = Rotation:GetForwardVector()
    if Direction then
        Direction.Z = 0
        Direction = Direction:GetSafeNormal()
        Direction = Direction * self.CharacterMovement.Velocity:Size()
    end

    if bClearVelocity then
        self.CharacterMovement.Velocity = Direction
    else
        self.CharacterMovement.Velocity = UE4.FVector(0.0 , 0.0 , 0.0)
    end

end

function BP_ShooterCharacterBase_C:SetCharacterDownTotalTimes()
    if self.DownTotalTimes > 0 then
        self.DownTotalTimes = self.DownTotalTimes - 1
    end
end


--- 设置救援者
function BP_ShooterCharacterBase_C:SetRescuerActor(rescuerActor)
    if rescuerActor and rescuerActor:Cast(UE4.ABP_ShooterCharacterBase_C) then
        self.RescuerActor = rescuerActor:Cast(UE4.ABP_ShooterCharacterBase_C)
    else
        self.RescuerActor = nil
    end

    self.IsInBeResurge = self.RescuerActor and true or false
end

function BP_ShooterCharacterBase_C:SetCheckBeRescuer(actor)
    self.CacheBeRescuer = actor
end

-------------------------------------------------------------------------
-- 获取数据接口
-------------------------------------------------------------------------
-- 获取指定的Mesh
function BP_ShooterCharacterBase_C:GetSpecificMesh(bFirstPerson)
    return bFirstPerson and self.Mesh1P or self.Mesh
end

-- 获取正在使用的Mesh
function BP_ShooterCharacterBase_C:GetUsingMesh()
	return self:IsFirstPerson() and self.Mesh1P or self.Mesh
end

-- 获取当前的相机
function BP_ShooterCharacterBase_C:GetUsingCamera()
    return self:IsFirstPerson() and self.FPPCamera or self.TPPCamera
end


-- 获取属性管理器
function BP_ShooterCharacterBase_C:GetAttrMgr()
    if not self.Controller then
        return nil
    end

    local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if PlayerController then
        return PlayerController:GetAttrMgr()
    end

    return nil
end

-- 获取装备管理器
function BP_ShooterCharacterBase_C:GetEquipMgr()
    if not self.Controller then
        return nil
    end

    local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if PlayerController then
        return PlayerController:GetEquipMgr()
    end

    return nil
end

function BP_ShooterCharacterBase_C:GetCurEquipActor()
    return self.EquipComponent and self.EquipComponent:GetCurEquipActor() or nil
end

-- 获取装备管理器
function BP_ShooterCharacterBase_C:GetHitDmgCalc()
    if not self.Controller then
        return nil
    end

    local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
    if PlayerController then
        return PlayerController:GetHitDmgCalc()
    end

    return nil
end

-- 获取角色的配置数据
function BP_ShooterCharacterBase_C:GetCharacterConfigData()
    return self.CharacterConfigData
end

function BP_ShooterCharacterBase_C:GetTeamID()
    return self.TeamID
end

function BP_ShooterCharacterBase_C:GetPlayerID()
    return self.PlayerID
end

function BP_ShooterCharacterBase_C:GetPlayerName()
    return self.PlayerName
end


-- 获取角色的属性数据
function BP_ShooterCharacterBase_C:GetRepAttr(AttrID)
    if not self.Attrs then
        return 0.0
    end

    return self.Attrs:Get(AttrID)
end

function BP_ShooterCharacterBase_C:GetHp()
    return self.CurHp
end

function BP_ShooterCharacterBase_C:GetMaxHp()
    return self.CurHpMax
end

function BP_ShooterCharacterBase_C:GetShield()
    if not self.Attrs then
        return 0.0
    end

    return self.Attrs:Get(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SHIELD)
end

function BP_ShooterCharacterBase_C:GetMaxShield()
    if not self.Attrs then
        return 0.0
    end

    return self.Attrs:Get(Ds_ResCharacterAttrType.EN_CHARACTERATTR_MAX_SHIELD)
end

function BP_ShooterCharacterBase_C:GetArmorHead()
    if not self.Attrs then
        return 0.0
    end

    return self.Attrs:Get(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORHEAD)
end

function BP_ShooterCharacterBase_C:GetArmorNeck()
    if not self.Attrs then
        return 0.0
    end

    return self.Attrs:Get(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORNECK)
end

function BP_ShooterCharacterBase_C:GetArmorTorso()
    if not self.Attrs then
        return 0.0
    end

    return self.Attrs:Get(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORTORSO)
end


function BP_ShooterCharacterBase_C:GetArmorStomach()
    if not self.Attrs then
        return 0.0
    end

    return self.Attrs:Get(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORSTOMACH)
end


function BP_ShooterCharacterBase_C:GetArmorLimbs()
    if not self.Attrs then
        return 0.0
    end

    return self.Attrs:Get(Ds_ResCharacterAttrType.EN_CHARACTERATTR_ARMORLIMBS)
end

function BP_ShooterCharacterBase_C:GetFiringInputAxisPitch()
    return self.FiringRecoilAxisPitch
end

function BP_ShooterCharacterBase_C:GetFiringRecoilAxisPitch()
    return self.FiringRecoilAxisPitch
end

--根据ID查找动画
function BP_ShooterCharacterBase_C:FindAnimationByID(AnimationID)
    return self.AnimationPool:Find(AnimationID);
end

function BP_ShooterCharacterBase_C:GetCharacterStatus()
    return self.CharacterStatus;
end

function BP_ShooterCharacterBase_C:GetPlayerFaceToCoverAngle()
    local FaceToCoverAngle = self.CoverComponent and self.CoverComponent:GetPlayerFaceToCoverAngle() or 0.0
    return FaceToCoverAngle
end

function BP_ShooterCharacterBase_C:GetPlayerFaceToCoverCrossZ()
    local FaceToCoverCrossZ = self.CoverComponent and self.CoverComponent:GetPlayerFaceToCoverCrossZ() or 0.0
    return FaceToCoverCrossZ
end

--上次被攻击时间
function BP_ShooterCharacterBase_C:GetLastBeHitTime()
    return self.LastBeHitTime
end

-- 翻滚冷却时间
function BP_ShooterCharacterBase_C:GetRollCD()
    return self.RollCD
end


function BP_ShooterCharacterBase_C:GetCameraSlowDownInputScale()
    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if not PlayerController or PlayerController.bShowMouseCursor then
        return 1.0
    end

    local curHUD = PlayerController:GetHUD()
    local curShooterHUD = nil
    if curHUD and curHUD:IsValid() then
        curShooterHUD = curHUD:Cast(UE4.ABP_ShooterPlayerHUD_C)

        if curShooterHUD and type(curShooterHUD.AimSlowDownInputScale) == "number" then
            return curShooterHUD.AimSlowDownInputScale
        end
    end

    return 1.0
end

function BP_ShooterCharacterBase_C:GetCharacterDownTotalTimes()
    return self.DownTotalTimes
end


--- 获取救援者
--- @return  BP_ShooterCharacterBase_C type
function BP_ShooterCharacterBase_C:GetRescuerActor()
    return self.RescuerActor
end

--- 获取自救速度
function BP_ShooterCharacterBase_C:GetSelfRescueSpeed()
    local AttrMgr = self:GetAttrMgr()
    if AttrMgr then
        return AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_SELFRESCUESPEED) / MATH_SCALE_10K
    end

    return 10000 / MATH_SCALE_10K;
end

--- 获取救援速度
function BP_ShooterCharacterBase_C:GetRescueSpeed()
    local AttrMgr = self:GetAttrMgr()
    if AttrMgr then
        return AttrMgr:GetAttr(Ds_ResCharacterAttrType.EN_CHARACTERATTR_RESCUESPEED) / MATH_SCALE_10K
    end

    return 10000 / MATH_SCALE_10K;
end

--- 获取自救时间 【蓝图变量】
function BP_ShooterCharacterBase_C:GetResurgenceTime()
    return 500
    --return self.ResurgenceTime / MATH_SCALE_10K
end

function BP_ShooterCharacterBase_C:GetResurgenceProcessTime()
    return self.Resurgence_Timer
end

--- 获取救援角色
function BP_ShooterCharacterBase_C:GetBeRescuerActor()

    local Range = 120.0;
    local ResurgeDistanceSq = g_GameResurgeRange * g_GameResurgeRange
    local nearestDissq = math.huge
    local Center = self:K2_GetActorLocation()
    local Forward = self:GetActorForwardVector()
    local LimitDot = math.cos((Range / 2) * math.pi / 180);

    local rescuerActor = nil

    local AllActors = UE4.UGameplayStatics.GetAllActorsOfClass(self, UE4.ABP_ShooterCharacterBase_C)

    for i = 1, AllActors:Length() do
        local character = AllActors:GetRef(i)

        if character:IsValid() and character:IsDown() and self:IsTeammate(character) and not character:IsBeResurge() and character:GetPlayerID() ~= self:GetPlayerID() then

            local Direction = character:K2_GetActorLocation() - Center;
            local DistSq = Direction:SizeSquared();

            if DistSq <= ResurgeDistanceSq then
                
                local Dot = Direction:Dot(Forward);
                
                Dot = Dot / (Direction:Size() * Forward:Size())
                
                if Dot >= LimitDot then
                    
                    if DistSq < nearestDissq then
                        --- need more filter
                        --- Cover or IsInResurge
                        nearestDissq = DistSq;
                        rescuerActor = character;
                    end
                end
            end
        end
    end

    return rescuerActor
end

--- 获取检测到可救援的角色
--- 为空时候，不存在救援者
--- see UpdateCheckBeRescuer() ResurgeTeammate_S()
function BP_ShooterCharacterBase_C:GetCheckBeRescuer()
    return self.CacheBeRescuer
end

--- 获取处决角色
function BP_ShooterCharacterBase_C:GetMortalBlowsActor()

    local Range = 120.0;
    local ResurgeDistanceSq = g_GameMortalBlowsRange * g_GameMortalBlowsRange
    local nearestDissq = math.huge
    local Center = self:K2_GetActorLocation()
    local Forward = self:GetActorForwardVector()
    local LimitDot = math.cos((Range / 2) * math.pi / 180);

    local beMortalBlowsActor = nil

    local AllActors = UE4.UGameplayStatics.GetAllActorsOfClass(self, UE4.ABP_ShooterCharacterBase_C)

    for i = 1, AllActors:Length() do
        local character = AllActors:GetRef(i)
        
        if character:IsValid() and character:IsDown() and self:IsEnemy(character) and not character:IsMortalBlows() then

            local Direction = character:K2_GetActorLocation() - Center;
            local DistSq = Direction:SizeSquared();
            
            if DistSq <= ResurgeDistanceSq then

                local Dot = Direction:Dot(Forward);

                Dot = Dot / (Direction:Size() * Forward:Size())
                
                if Dot >= LimitDot then
                    if DistSq < nearestDissq then
                        nearestDissq = DistSq;
                        beMortalBlowsActor = character;
                    end
                end
            end
        end
    end

    return beMortalBlowsActor
end

-------------------------------------------------------------------------
-- 判断状态接口
-------------------------------------------------------------------------
-- 是否为第一人称
function BP_ShooterCharacterBase_C:IsFirstPerson()
    if self:IsAlive() and self:IsLocallyControlled() then
        local PlayerController = self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C)
        if PlayerController then
            return PlayerController:GetCharacterCameraMode() == UE4.ECharacterCameraMode.FirstPerson
        end
    end
    
    return false
end

-- 是否活着
function BP_ShooterCharacterBase_C:IsAlive()
    return self.CharacterStatus == ECharacterStatus.ECharacterStatus_ALIVE and true or false;
end

function BP_ShooterCharacterBase_C:IsDying()
    return self.CharacterStatus == ECharacterStatus.ECharacterStatus_DYING and true or false;
end


-- 判断是否在敌人右方
function BP_ShooterCharacterBase_C:IsOnRight(Direction,OutImpulseDir)
    local a = Direction:Cross(OutImpulseDir)

    if a.Z < 0 then
        return true
    end
    return false
end

-- 瞄准减速
function BP_ShooterCharacterBase_C:IsAimSlowMode()
    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if not PlayerController or PlayerController.bShowMouseCursor then
        return false
    end

    local curHUD = PlayerController:GetHUD()
    local curShooterHUD = nil
    if curHUD and curHUD:IsValid() then
        curShooterHUD = curHUD:Cast(UE4.ABP_ShooterPlayerHUD_C)

        if curShooterHUD then
            return curShooterHUD:IsAimSlowMode()
        end
    end

    return false
end

-- 是否可以移动
function BP_ShooterCharacterBase_C:CanMove()
    if not self.Controller then
        return false;
    end

    if self:IsInRolling() or self:IsFallingDown() or
        self:IsInResetPawnRotation() or
        self:IsBeResurge() or self:IsResurgeTeammate() or
        self:IsMortalBlows() then
        return false
    end

    if self:IsVaultingCover() or self:IsChangingCover() then
        return false
    end

    return true
end


-- 是否可以转镜头
function BP_ShooterCharacterBase_C:CanTurnCamera(isLookUp)
    if not self.Controller then
        return false;
    end

    if self:IsMortalBlows() then
        return false;
    end

    if isLookUp then
        if self:IsRunning() then
            return false
        end
    end
    ------- (翻滚) 时, 不能进行镜头转向
    --if self:IsInRolling() then
    --    return false
    --end

    if self:IsVaultingCover() then
        return false
    end
    
    return true
end

-- 是否可以瞄准
function BP_ShooterCharacterBase_C:CanAim()
    --- (进掩体/翻滚/冲锋/倒地) 时, 不能进行瞄准
    if self:IsRunning() or self:IsEnteringCover() or
        self:IsInRolling() or self:IsInResetPawnRotation() or
        self:IsDown() or self:IsBeResurge() or
        self:IsResurgeTeammate() then
        return false
    end

    if self:IsVaultingCover() or self:IsChangingCover() then
        return false
    end

    -- 掩体中
    if self:IsCovering() then
        if self.CoverComponent and not self.CoverComponent:CanAim() then
            return false
        end
    end

    return true
end

-- 是否可以开火
function BP_ShooterCharacterBase_C:CanFire()
    --- (进掩体/翻滚/冲锋/等待换弹/倒地) 时, 不能进行开火
    if self:IsEnteringCover() or self:IsInRolling() or
        self:IsPendingReload() or self:IsRunning() or
        self:IsInResetPawnRotation() or self:IsDown() or
        self:IsBeResurge() or self:IsResurgeTeammate() or
        self:IsMortalBlows() then
        return false
    end

    if self:IsVaultingCover() or self:IsChangingCover() then
        return false
    end

    -- 掩体中
    if self:IsCovering() then
        if self.CoverComponent and not self.CoverComponent:CanFire() then
            return false
        end
    end

    return true
end

-- 是否可以战术翻滚
function BP_ShooterCharacterBase_C:CanRolling()
    --- (进掩体/翻滚中/战术翻滚CD中/Pawn转向/倒地) 时, 不能进行翻滚
    if self:IsEnteringCover() or
        self:IsInRolling() or
        self:IsInRollingCD() or
        self:IsInResetPawnRotation() or
        self:IsDown() or
        self:IsBeResurge() or
        self:IsResurgeTeammate() or 
        self:IsMortalBlows() then
        return false
    end

    --- 掩体中
    if self:IsCovering() or self:IsVaultingCover() or self:IsChangingCover() then
        if not self.CoverComponent:IsReadyForRoll() then
            return false
        end
    end

    return true
end

-- 是否可以冲锋
function BP_ShooterCharacterBase_C:CanRun()
    if self:IsEnteringCover() or
        self:IsInRolling() or
        self:IsInResetPawnRotation() or
        self:IsDown() or
        self:IsBeResurge() or
        self:IsResurgeTeammate() or
        self:IsMortalBlows() then
        return false
    end

    if self:IsVaultingCover() or self:IsChangingCover() then
        return false
    end

    return true
end

-- 是否可以贴靠掩体
function BP_ShooterCharacterBase_C:CanCover()
    if self:IsInRolling() or self:IsInResetPawnRotation() or
        self:IsDown() or self:IsBeResurge() or
        self:IsResurgeTeammate() or 
        self:IsMortalBlows() then
        return false
    end

    if self:IsVaultingCover() then
        return false
    end

    return true
end

function BP_ShooterCharacterBase_C:IsCrouching()
    return self.CharacterMovementComponent and self.CharacterMovementComponent:IsCrouching()
end

-- 判断是否在跑
function BP_ShooterCharacterBase_C:IsRunning()
    return self.CharacterMovementComponent and self.CharacterMovementComponent:IsRunning()
end

-- 是否倒地
function BP_ShooterCharacterBase_C:IsDown()
    return self.CharacterMovementComponent and self.CharacterMovementComponent:IsDown()
end

-- 是否正在瞄准
function BP_ShooterCharacterBase_C:IsWeaponAim()
    return self.CharacterMovementComponent and self.CharacterMovementComponent:IsWeaponAim()
end

-- 判读是否左手持装备
function BP_ShooterCharacterBase_C:IsHoldEquipLeft()
    return self.CharacterMovementComponent and self.CharacterMovementComponent:IsHoldEquipLeft()
end

-- 是否正在开火
function BP_ShooterCharacterBase_C:IsFiring()
    return self.EquipComponent and self.EquipComponent:IsFiring()
end

-- 是否等待换弹
function BP_ShooterCharacterBase_C:IsPendingReload()
    return self.EquipComponent and self.EquipComponent:IsPendingReload()
end

-- 是否正在掩体中
function BP_ShooterCharacterBase_C:IsCovering()
    return self.CoverComponent and self.CoverComponent:IsCovering()
end

-- 是否正在移动到掩体
function BP_ShooterCharacterBase_C:IsEnteringCover()
    return self.CoverComponent and self.CoverComponent:IsEnteringCover()
end

-- 是否正在翻越掩体
function BP_ShooterCharacterBase_C:IsVaultingCover()
    return self.CoverComponent and self.CoverComponent:IsVaultingCover()
end

-- 是否正在切换掩体
function BP_ShooterCharacterBase_C:IsChangingCover()
    return self.CoverComponent and self.CoverComponent:IsChangingCover()
end

--是否持有武器
function BP_ShooterCharacterBase_C:IsRifle()
    return self.EquipComponent and self.EquipComponent:IsRifle() or false;
end

-- 判断是否为队友
function BP_ShooterCharacterBase_C:IsTeammate(CharacterBase)
    return (self.TeamID == CharacterBase.TeamID) and true or false
end

-- 判断是否为敌人
function BP_ShooterCharacterBase_C:IsEnemy(CharacterBase)
    return (self.TeamID ~= CharacterBase.TeamID) and true or false
end

-- 判断战术翻滚CD是否结束
function BP_ShooterCharacterBase_C:IsInRollingCD()
    return self.bInRollingCD
end

-- 是否处于下落硬直状态
function BP_ShooterCharacterBase_C:IsFallingDown()
    return false
    -- 这里暂时屏蔽，防止影响A1录像
    --return not self.IsFallingDownFinish
end

-- 是否按下冲锋
function BP_ShooterCharacterBase_C:IsPressRunBtn()
    return self.bPressRunBtn
end

-- 是否翻滚
function BP_ShooterCharacterBase_C:IsInRolling()
    return self.CharacterMovementComponent and self.CharacterMovementComponent:IsInRolling()
end

function BP_ShooterCharacterBase_C:IsInResetPawnRotation()
    return self.IsResetPawnRotation
end

function BP_ShooterCharacterBase_C:IsCanEnterCover()
    return self.CoverComponent and self.CoverComponent:CanEnterCover()
end

--- 是否处于再起状态
function BP_ShooterCharacterBase_C:IsInResurgence()
    return self.bInResurgence
end

--- 是否处于被救
function BP_ShooterCharacterBase_C:IsBeResurge()
    return self.IsInBeResurge
end

--- 是否正在救人
function BP_ShooterCharacterBase_C:IsResurgeTeammate()
    return self.CharacterMovementComponent and self.CharacterMovementComponent:IsResurgeTeammate()
end

--- 是否正在处决
function BP_ShooterCharacterBase_C:IsMortalBlows()
    return self.CharacterMovementComponent and self.CharacterMovementComponent:IsMortalBlows()
end

--- 是否处于布娃娃
function BP_ShooterCharacterBase_C:IsRagdoll()
    return self.CharacterMovementComponent and self.CharacterMovementComponent:IsRagdoll()
end

-------------------------------------------------------------------------
-- Collision Notify
-------------------------------------------------------------------------
-- 碰撞开始
-- @params: (class UPrimitiveComponent*, class AActor*, class UPrimitiveComponent*, int32, bool, const FHitResult&)
function BP_ShooterCharacterBase_C:OnCoverCapsuleBeginOverlap(OverlappedComp, OtherActor, OtherComp, OtherBodyIndex, bFromSweep, SweepResult)
	if OtherActor and OtherActor ~= self and OtherComp then
		-- if OtherActor:GetClass():IsChildOf(ARebirthBase:StaticClass()) then
		-- 	m_RebirthPoint = OtherActor:Cast(ARebirthBase)
        -- 	m_bInRebirthArea = true
        
        -- end
	end
end

-- 碰撞结束
-- @params: (class UPrimitiveComponent*, class AActor*, class UPrimitiveComponent*, int32)
function BP_ShooterCharacterBase_C:OnCapsuleEndOverlap(OverlappedComp, OtherActor, OtherComp, OtherBodyIndex)
	if OtherActor and OtherActor ~= self and OtherComp then
		-- if OtherActor:GetClass():IsChildOf(ARebirthBase:StaticClass()) then
		-- 	m_RebirthPoint = nil
        --     m_bInRebirthArea = false
            
        -- end
	end
end


-------------------------------------------------------------------------
-- 辅助接口
-------------------------------------------------------------------------
-- 播放动画蒙太奇
-- @params (class UAnimMontage, float, FName)
function BP_ShooterCharacterBase_C:PlayAnimMontage(AnimMontage, InPlayRate, StartSectionName)
    if not AnimMontage then
        return 0
    end
    
    local UseMesh = self:GetUsingMesh()
    if UseMesh and UseMesh.AnimScriptInstance then
        local Duration = UseMesh.AnimScriptInstance:Montage_Play(AnimMontage, InPlayRate)
        if Duration > 0 then
            UseMesh.AnimScriptInstance:Montage_JumpToSection(StartSectionName, AnimMontage)
            return Duration
        end
    end

    return 0
end

-- 结束动画蒙太奇
-- @params (class UAnimMontage)
function BP_ShooterCharacterBase_C:StopAnimMontageLua(AnimMontage1P, AnimMontage3P , bReset)
    --if not AnimMontage then
    --    return 0
    --end

	local UseMesh = self:GetUsingMesh()
    if bReset then

        if self.Mesh1P and self.Mesh1P.AnimScriptInstance and self.Mesh1P.AnimScriptInstance:Montage_IsPlaying(AnimMontage1P) then
            self.Mesh1P.AnimScriptInstance:Montage_Stop(AnimMontage1P.BlendOut.BlendOutTime, AnimMontage1P)
        end

        if self.Mesh and self.Mesh.AnimScriptInstance and self.Mesh.AnimScriptInstance:Montage_IsPlaying(AnimMontage3P) then
            self.Mesh.AnimScriptInstance:Montage_Stop(AnimMontage3P.BlendOut.BlendOutTime, AnimMontage3P)
        end
    else

        if self.Mesh1P and self.Mesh1P.AnimScriptInstance and self.Mesh1P.AnimScriptInstance:Montage_IsPlaying(AnimMontage1P) then
            self.Mesh1P.AnimScriptInstance:Montage_Stop(0, AnimMontage1P)
        end

        if self.Mesh and self.Mesh.AnimScriptInstance and self.Mesh.AnimScriptInstance:Montage_IsPlaying(AnimMontage3P) then
            self.Mesh.AnimScriptInstance:Montage_Stop(0, AnimMontage3P)
        end
    end

    --if UseMesh and UseMesh.AnimScriptInstance and UseMesh.AnimScriptInstance:Montage_IsPlaying(AnimMontage) then
		--UseMesh.AnimScriptInstance:Montage_Stop(AnimMontage.BlendOut:GetBlendTime(), AnimMontage)
    --end
end

function BP_ShooterCharacterBase_C:PlayMeshAnimation(NewAnimToPlay , bLoop)

    if NewAnimToPlay then
        local UseMesh = self:GetUsingMesh()
        if UseMesh and UseMesh.AnimScriptInstance then
            UseMesh:PlayAnimation(NewAnimToPlay , bLoop)
            return 1
        end
    end

    return -1
end

-------------------------------------------------------------------------
-- HpFloatingBar
-------------------------------------------------------------------------
--更新HUD
function BP_ShooterCharacterBase_C:UpdateHud()
    local CharacterBase = UE4.UGameplayStatics.GetPlayerCharacter(self, 0)
    if CharacterBase  then
        local CameraLocation = CharacterBase.TPPCamera:K2_GetComponentLocation()
        local HudWorkdLocation = self.HUD:K2_GetComponentLocation()
        local LookAtRotation = UE4.UKismetMathLibrary.FindLookAtRotation(HudWorkdLocation, CameraLocation)
        self.HUD:K2_SetWorldRotation(LookAtRotation, false, nil, false)
        if CharacterBase == self or self:IsDying() then     -- 判断是否为自己
            self.Friend:SetVisibility(false)
            self.Enemy:SetVisibility(false)
            self.ResurgeWidget:SetVisibility(false)
            CharacterBase:OnAimAtEnemy()
        else
            if  self:IsTeammate(CharacterBase) then -- 判断是否为队友
                self:UpdateFriendHud(CharacterBase)
            elseif self:IsEnemy(CharacterBase) then -- 判断是否为敌人
                self:UpdateEnemyHud(CharacterBase)
            end
        end
    else
       self.Friend:SetVisibility(false)
       self.Enemy:SetVisibility(false)
    end
end

-- 瞄准敌人显示血条
function BP_ShooterCharacterBase_C:OnAimAtEnemy()

    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if not PlayerController then
        return
    end
    local OutCamLoc = PlayerController.PlayerCameraManager:GetCameraLocation();
    local OutCamRot = PlayerController.PlayerCameraManager:GetCameraRotation();
    local Direction = OutCamRot:ToVector();

    local StartLocation = OutCamLoc;
    local EndLocation = StartLocation + Direction * 10000.0
    local HitResult = UE4.FHitResult()
    --local ActorsToIgnore = TArray(UE4.AStaticMeshActor)
    --ActorsToIgnore:Add()
    local bResult = UE4.UKismetSystemLibrary.LineTraceSingle(self,StartLocation,EndLocation, UE4.ETraceTypeQuery.WorldDynamic, false, nil,
    UE4.EDrawDebugTrace.None, HitResult, true)
    if HitResult.Actor and bResult then
        local BeHitCharacter = HitResult.Actor:Cast(UE4.ABP_ShooterCharacterBase_C)
        if BeHitCharacter and  BeHitCharacter:IsEnemy(self) then  --射线瞄准敌人
            local UserWidgetObject = BeHitCharacter.Enemy:GetUserWidgetObject();
            if UserWidgetObject == nil then 
                return;
            end
        
            local EnemyHUD = UserWidgetObject:Cast(UE4.UUIBattleHpFloatingBar_C)
            if EnemyHUD == nil then
                print("BP_ShooterCharacterBase_C:OnAimAtEnemy error EnemyHUD")
                return;
            end
            EnemyHUD.Name_TextBlock:SetText(BeHitCharacter:GetPlayerName())
            BeHitCharacter.Friend:SetVisibility(false)
            BeHitCharacter.Enemy:SetVisibility(true)
            BeHitCharacter:OnRefreshEnemyHp(EnemyHUD)
            BeHitCharacter:OnRefreshHpBarScale(EnemyHUD, self)
        end
    end

end

--更新队友HUD
function BP_ShooterCharacterBase_C:UpdateFriendHud(CharacterBase)

    local UserWidgetObject = self.Friend:GetUserWidgetObject();
    if UserWidgetObject == nil then
        return;
    end

    if self:IsDown() and not CharacterBase:GetCheckBeRescuer() then
        self.ResurgeWidget:SetVisibility(true)
    else
        self.ResurgeWidget:SetVisibility(false)
    end

    local FriendHUD = UserWidgetObject:Cast(UE4.UUIBattleHpFloatingBar_C)
    if FriendHUD == nil then
        print("BP_ShooterCharacterBase_C:UpdateHud error .HeadFriendHUD")
        return
    end

    FriendHUD.Name_TextBlock:SetText(self:GetPlayerName())
    self.Friend:SetVisibility(true)
    self.Enemy:SetVisibility(false)
    self:OnRefreshFriendHp(FriendHUD)
    self:OnRefreshHpBarScale(FriendHUD, CharacterBase)
end

--更新敌人HUD
function BP_ShooterCharacterBase_C:UpdateEnemyHud(CharacterBase)

    local UserWidgetObject = self.Enemy:GetUserWidgetObject();
    if UserWidgetObject == nil then
        return;
    end

    local EnemyHUD = UserWidgetObject:Cast(UE4.UUIBattleHpFloatingBar_C)
    if EnemyHUD == nil then
        print("BP_ShooterCharacterBase_C:UpdateEnemyHud error EnemyHUD")
        return;
    end

    EnemyHUD.Name_TextBlock:SetText(self:GetPlayerName())
 
    local CurrentTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
    local LastBeHitTime = self:GetLastBeHitTime()
    local DeltaTime = CurrentTime - LastBeHitTime --   减去上次被攻击时间
    local ShowTime = 3

    if DeltaTime > 0 and DeltaTime <= ShowTime or self.beAim then
        self.Friend:SetVisibility(false)
        self.Enemy:SetVisibility(true)
        self:OnRefreshEnemyHp(EnemyHUD)
        self:OnRefreshHpBarScale(EnemyHUD, CharacterBase)
    else
        self.Friend:SetVisibility(false)  --敌方血条默认不显示
        self.Enemy:SetVisibility(false)
    end     

end

-- 血条缩放
function BP_ShooterCharacterBase_C:OnRefreshHpBarScale(HUD, CharacterBase)
    local Distance = CharacterBase:GetDistanceTo(self) / 100
    local MaxDistance = 100.0  --血条缩放的最大距离
    local MinScaleRatio = 0.5  --最小缩放比例
    local Scale = 1.0
    if Distance >= 0 and Distance <= MaxDistance then
        Scale = math.min(1, 1 - (MinScaleRatio * Distance) / MaxDistance)     
    elseif Distance > MaxDistance then
        Scale = 0.5
    end
    HUD.Hp_CanvasPanel:SetRenderScale(UE4.FVector2D(Scale,Scale))
end

-- 刷新队友血条
function BP_ShooterCharacterBase_C:OnRefreshFriendHp(HUD)
    if HUD == nil then
        return
    end
    local currHpPercent = self:GetMaxHp() > 0 and (self:GetHp() / self:GetMaxHp())  or 0.0
    HUD.Enemy_ProgressBar:SetVisibility(UE4.ESlateVisibility.Hidden) 
    HUD.Friend_ProgressBar:SetPercent(currHpPercent)

    if self.LastSetHpBarTime >= 0.35 then
        self.LastSetHpBarTime = self.LastSetHpBarTime - 0.35
        self:DelaySetHitHpBar(HUD, currHpPercent)
    end
end

-- 刷新敌人血条
function BP_ShooterCharacterBase_C:OnRefreshEnemyHp(HUD)
    if HUD == nil then
        return
    end
    local currHpPercent = self:GetMaxHp() > 0 and (self:GetHp() / self:GetMaxHp())  or 0.0
    HUD.Friend_ProgressBar:SetVisibility(UE4.ESlateVisibility.Hidden) 
    HUD.Enemy_ProgressBar:SetPercent(currHpPercent)
    
    if self.LastSetHpBarTime >= 0.35 then
        self.LastSetHpBarTime = self.LastSetHpBarTime - 0.35
        self:DelaySetHitHpBar(HUD, currHpPercent)
    end
end

-- 血条延迟
function BP_ShooterCharacterBase_C:DelaySetHitHpBar(HUD, hp_percent)
        HUD.Bottom_ProgressBar:SetPercent(hp_percent)
end

-- 受击警示
function BP_ShooterCharacterBase_C:DrawHitIndicator(HudCanvas,ScaleRatio)
    local Center = UE4.FVector2D(HudCanvas.ClipX * 0.5, HudCanvas.ClipY * 0.5)
    if self.HitIndicator == nil then
    return
    end

    local Radius = 200 * ScaleRatio
    local TextureSize = UE4.FVector2D(self.HitIndicator:Blueprint_GetSizeX(),self.HitIndicator:Blueprint_GetSizeY()) * ScaleRatio * 2
    local HitIndicatorPos = UE4.FVector2D(Center.X - TextureSize.X * 0.5 , Center.Y - TextureSize.Y - Radius)

    local CurrentTime = UE4.UKismetSystemLibrary.GetGameTimeInSeconds(self:GetWorld())
    local LastBeHitTime = self:GetLastBeHitTime()
    local DeltaTime = CurrentTime - LastBeHitTime 
    local ShowTime = 1
    local FadeOutTime = 0.25
    if DeltaTime >= 0 and DeltaTime <= ShowTime then  
        local Alpha = 1.0
        if DeltaTime >= ShowTime - FadeOutTime then
                Alpha = math.min(1.0, 1 - ((DeltaTime - ShowTime + FadeOutTime)/ FadeOutTime))
        end

        local beHitAngle =  self:CalculateHitAngle()
        HudCanvas:K2_DrawTexture(self.HitIndicator,HitIndicatorPos,TextureSize ,UE4.FVector2D(0,0),UE4.FVector2D(1,1),UE4.FLinearColor(1,0,0,Alpha),UE4.EBlendMode.BLEND_Translucent,beHitAngle,UE4.FVector2D(0.5,(TextureSize.Y + Radius) / TextureSize.Y))
    end
end

-- 计算受击角度
function BP_ShooterCharacterBase_C:CalculateHitAngle()
    local PlayerController = self.Controller and self.Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C) or nil;
    if not PlayerController then
        return
    end

    local OutCamRot = PlayerController.PlayerCameraManager:GetCameraRotation();
    local Direction = OutCamRot:ToVector();
    if self.LastHitVector ~= UE4.FVector.ZeroVector then
        --local a = Direction:Dot(-OutImpulseDir)
        local Dot = UE4.FVector2D(Direction.X,Direction.Y):Dot(-UE4.FVector2D(self.LastHitVector.X,self.LastHitVector.Y))
        local Norm = math.sqrt((Direction.X * Direction.X + Direction.Y * Direction.Y) * (self.LastHitVector.X * self.LastHitVector.X + self.LastHitVector.Y * self.LastHitVector.Y))
        
        if self:IsOnRight(Direction,self.LastHitVector) then
            return  math.deg(math.acos(Dot/Norm))
        else
            return 360 - math.deg(math.acos(Dot/Norm)) 
        end
    end
end

-- 低血量警告
function BP_ShooterCharacterBase_C:DrawLowHPIndicator(newMat)

    local currHpPercent = self:GetMaxHp() > 0 and (self:GetHp() / self:GetMaxHp())  or 0.0

    local healIndicatorPercent = 0.4
    if currHpPercent <= healIndicatorPercent then 
        self.CurrHealPercent = UKismetMathLibrary.Lerp(self.CurrHealPercent, currHpPercent,0.05) 
        
        -- 左右遮罩
        local f_POWER = (self.CurrHealPercent * (20 - 12)/ healIndicatorPercent) + 12
        -- 上下遮罩
        local f_POWER_gao = (self.CurrHealPercent * (20 - 5) / healIndicatorPercent) + 5
        
        if newMat ~= nil then
            newMat:SetScalarParameterValue("f_POWER" ,f_POWER )
            newMat:SetScalarParameterValue("f_POWER_gao" ,f_POWER_gao)

            local Opacity =  - self.CurrHealPercent / healIndicatorPercent + 1
            newMat:SetScalarParameterValue("Opacity" ,UE4.math.max(0,Opacity))
        end
    elseif newMat ~= nil then
        local Opacity = newMat:K2_GetScalarParameterValue("Opacity") - UE4.UGameplayStatics.GetWorldDeltaSeconds(self) * 0.35
        if Opacity >= 0 then
            self.CurrHealPercent = healIndicatorPercent
            newMat:SetScalarParameterValue("Opacity", Opacity)
        end
    end
    
end

function BP_ShooterCharacterBase_C:UpdateMaterial()
    local CharacterBase = UE4.UGameplayStatics.GetPlayerCharacter(self, 0)
    if CharacterBase then
        if self:IsEnemy(CharacterBase) then
            local curMaterialName = UE4.UKismetSystemLibrary.GetDisplayName(self.Mesh:GetMaterial(0))
            if  curMaterialName ~= "M_Hero01_M_02_Cloth_2_Red" then
                print("=========================EnemyMaterialIsNotRed===================",self.TeamID)
            end
        end
    end
end

return BP_ShooterCharacterBase_C
