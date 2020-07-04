require "UnLua"

local AimAssistMgr = class("AimAssistMgr")
local AutomaticFireEnums = require("Gameplay/Levels/Debug/Module/AutomaticFireEnums")

function AimAssistMgr:ctor()
    --------------------------------------------------------
    --- 检测数据
    --------------------------------------------------------
    self.CurrAutoFireState = AutomaticFireEnums.AutomaticFireState.NONE_TARGET      --- 当前自动开火状态
    self.LastAutoFireState = AutomaticFireEnums.AutomaticFireState.NONE_TARGET      --- 上一帧自动开火状态
    self.CacheOutHitRef = nil
    self.AutoLockTimerSwitch = false        -- 锁定状态开关
    self.AutoLockTimerCounter = 0.0

    self.AutoFireSocketTb = {"Bip001-Head","Bip001-Spine1","Bip001-Pelvis","Bip001-R-Foot","Bip001-L-Foot"}    --- 自动开火检测点
    self.AimingSocketTb = {"Bip001-Head","Bip001-Spine1","Bip001-Pelvis"}    --- 自动开火检测点
    self.TraceCkInterval = 0.2                                                      --- 检测间隔
    self.TraceCkCounter = 0.0                                                       --- 检测计数器

    --- 自动开火 FSM state1, event2, state3, action2
    local autoFireFSM = {
        {AutomaticFireEnums.AutomaticFireState.NONE_TARGET,"ReadyToLock",AutomaticFireEnums.AutomaticFireState.LOCK_TARGET,self.OnReadyToLock},
        {AutomaticFireEnums.AutomaticFireState.LOCK_TARGET,"ReadyToFire",AutomaticFireEnums.AutomaticFireState.FIRE_TARGET,self.OnReadyToFire},
        {AutomaticFireEnums.AutomaticFireState.LOCK_TARGET,"ReadyToUnLock",AutomaticFireEnums.AutomaticFireState.NONE_TARGET,self.OnReadyToLock},
        {AutomaticFireEnums.AutomaticFireState.FIRE_TARGET,"ReadyToStopFire",AutomaticFireEnums.AutomaticFireState.NONE_TARGET,self.ReadyToStopFire},
        {AutomaticFireEnums.AutomaticFireState.FIRE_TARGET,"ReadyToReFire",AutomaticFireEnums.AutomaticFireState.FIRE_TARGET,self.ReadyToReFire},
    }
    self.AutoFireFSM_Tb = FSM(autoFireFSM)
    self.ReadyToFireFlag = false

    --- 转向模式【靠近敌人一定范围，减慢转向镜头的速度】
    self.TurnSpeedMode = AutomaticFireEnums.AimTurnSpeedMode.NORMAL_MODE

    --- 瞄准的物体 -1是无角色 0是敌人 1是队友 
    self.AimObjectState = -1
end

---@param owner AShooterHUD
function AimAssistMgr:OnCreate(owner)
    self.Owner = owner
end

function AimAssistMgr:Tick(deltaTime)
    local pawn = self.Owner:GetOwningPawn()
    if pawn == nil or not self.Owner:IsValid() then
        return
    end

    --- 自动开火
    self:TickExecuteAutoFire(deltaTime)

    --- 辅助瞄准
    self:TickExecuteAimAssist()
end

function AimAssistMgr:OnDestroy()
    self.Owner = nil
    self.AutoFireFSM_Tb = nil
    self.CacheOutHitRef = nil
    self.ReadyToFireFlag = false
    self.AutoLockTimerSwitch = false
    self.AutoLockTimerCounter = 0.0
    self.AimingSocketTb = nil
end



-----------------------------------------------------------
--- 辅助函数
-----------------------------------------------------------
function AimAssistMgr:TickExecuteAimAssist()
    if self:IsAimAssistEnable() then
        self:UpdateFriction()
    end
end

function AimAssistMgr:TickExecuteAutoFire(deltaTime)

    self:AutoLockTimerCalc(deltaTime)

    local bHit, target , OutHitRef = self:GetTraceCkFirstLineCharacter()

    if bHit then
        self:SetTurnSpeedMode(AutomaticFireEnums.AimTurnSpeedMode.SLOWDOWN_MODE)
    else
        self:SetTurnSpeedMode(AutomaticFireEnums.AimTurnSpeedMode.NORMAL_MODE)
    end

    --- 自动开火
    if self:IsAutomaticFireEnable() then
        --local target , OutHitRef , bodyTarget , bodyHitRef = nil , nil

        if target == nil then
            local bHit , OutHits = self:SphereTraceMultiCheckActors()
            local bodyTarget , bodyHitRef = self:GetTraceCheckSphereCharacter(OutHits)
            target = bodyTarget
            OutHitRef = bodyHitRef
        end

        self:UpdateAutomaticFire(target , OutHitRef)
    end

end

--- 自动开火锁定计时
function AimAssistMgr:AutoLockTimerCalc(deltaTime)

    if self.CacheOutHitRef == nil or self.Owner == nil or self.Owner.FireLockCurve == nil then
        return
    end

    --- 锁定计时
    if self.AutoLockTimerSwitch and not self.ReadyToFireFlag then

        self.AutoLockTimerCounter = self.AutoLockTimerCounter  + deltaTime

        local targetDistance = self.CacheOutHitRef.Distance

        local lockWaitTime = self.Owner.FireLockCurve:GetFloatValue(targetDistance)
        --- 时间为千分比
        lockWaitTime = lockWaitTime / 1000.0

        --- 当前计时 大于等于等待曲线时间
        if self.AutoLockTimerCounter >= lockWaitTime then
            --- 设置标记，表示状态机可以跳入 ReadyToFire
            self.ReadyToFireFlag = true
            --self.AutoLockTimerSwitch = false
            --self.AutoLockTimerCounter = 0.0
        end
    end
end

--- 自动开火
function AimAssistMgr:UpdateAutomaticFire(target , OutHitRef)
    if target ~= nil then
        --FSM For Auto Fire
        self.CacheOutHitRef = OutHitRef

        if self.CurrAutoFireState == AutomaticFireEnums.AutomaticFireState.NONE_TARGET then
            self:OnChangeAutoFireState(self.CurrAutoFireState , "ReadyToLock")
        elseif self.CurrAutoFireState == AutomaticFireEnums.AutomaticFireState.LOCK_TARGET and self.ReadyToFireFlag then
            self:OnChangeAutoFireState(self.CurrAutoFireState , "ReadyToFire")
        elseif self.CurrAutoFireState == AutomaticFireEnums.AutomaticFireState.FIRE_TARGET and true then
            self:OnChangeAutoFireState(self.CurrAutoFireState , "ReadyToReFire")
        end
    else
        if self.CurrAutoFireState == AutomaticFireEnums.AutomaticFireState.LOCK_TARGET then
            self:OnChangeAutoFireState(self.CurrAutoFireState , "ReadyToUnLock")
        elseif self.CurrAutoFireState == AutomaticFireEnums.AutomaticFireState.FIRE_TARGET and true then
            self:OnChangeAutoFireState(self.CurrAutoFireState , "ReadyToStopFire")
        end
    end
end

---------------------------------------------------------
--- 辅助瞄准
---------------------------------------------------------

--- 辅助瞄准更新
function AimAssistMgr:UpdateFriction()

    local OutHit2 , bHit = self:AimAssistSphereTrace(self.Owner.AimOuterRadius , UE4.ETraceTypeQuery.AimAssist)
    if not OutHit2 then
        return
    end

    local bFireFriction , shooterOwnerBase = self:GetOwnerFireFrictionState()
    if not shooterOwnerBase or not shooterOwnerBase:IsValid() then
        return
    end

    local bInputAccFriction = self:IsInputAcceptAimFriction()
    --- 外圆触发贴靠
    if bHit then
        if OutHit2.Actor and OutHit2.Actor:Cast(UE4.ABP_ShooterCharacterBase_C) then

            local checkCharacterBase = OutHit2.Actor:Cast(UE4.ABP_ShooterCharacterBase_C)
            if checkCharacterBase and shooterOwnerBase:IsEnemy(checkCharacterBase) then
                --- 选择贴靠点
                local tracePoint , newHitRef = self:GetTraceCharacterHitPointNew(checkCharacterBase , OutHit2 , self.Owner.FrictionPointAngleCurve)
                if tracePoint then
                    --UE4.UKismetSystemLibrary.DrawDebugSphere(self.Owner , tracePoint , 12 , 12 , UE4.FLinearColor(0.0 , 0.0 , 1.0 , 1))
                    if bFireFriction and bInputAccFriction then
                        self:SetControlLookAtTarget(tracePoint)
                    end
                end
            end
        end
    end
end

--- 辅助瞄准圆检测
function AimAssistMgr:AimAssistSphereTrace(Radius , channel)

    local startPoint , endPoint , bGetCkPoint = self:GetCameraCenterTracePoints()
    if not bGetCkPoint then
        return false , nil
    end

    local IgnoreActors = UE4.TArray(UE4.AActor)
    self:GetIgnoreSelfActors(IgnoreActors)
    if not IgnoreActors then
        return false , nil
    end

    local OutHit = UE4.FHitResult()
    local bHit  = UE4.UKismetSystemLibrary.SphereTraceSingle(self.Owner , startPoint , endPoint , Radius , channel , false , IgnoreActors , UE4.EDrawDebugTrace.None , OutHit , true)

    return OutHit , bHit
end

--- 自动开火检测 Actors
function AimAssistMgr:SphereTraceMultiCheckActors()

    local startPoint , endPoint , bGetCkPoint = self:GetCameraCenterTracePoints()
    if not bGetCkPoint then
        return false , nil
    end

    local IgnoreActors = UE4.TArray(UE4.AActor)
    self:GetIgnoreSelfActors(IgnoreActors)

    local OutHits = UE4.FHitResult()
    local OutHits , bHit  = UE4.UKismetSystemLibrary.SphereTraceMulti(self.Owner , startPoint , endPoint , self.Owner.CircleRadius , UE4.ETraceTypeQuery.AimAssist , false , IgnoreActors , UE4.EDrawDebugTrace.None , OutHits , true)

    return bHit , OutHits
end


function AimAssistMgr:GetCameraCenterTracePoints()

    local startPoint = UE4.FVector()
    local endPoint = UE4.FVector()
    local bSuccess = false
    local playerCameraMgr = UE4.UGameplayStatics.GetPlayerCameraManager(self.Owner , 0)

    if playerCameraMgr ~= nil then
        local offset = self:GetAutomaticStartPointOffset()

        startPoint = playerCameraMgr:GetCameraLocation() + (playerCameraMgr:GetActorForwardVector() * offset)
        endPoint = playerCameraMgr:GetActorForwardVector() * self.Owner.AutomaticTraceMaxDis
        endPoint = endPoint + startPoint
        bSuccess = true
    end

    --- Debug Start Point and End Point in Editor
    --UE4.UKismetSystemLibrary.DrawDebugSphere(self.Owner , startPoint , 5 , 5 , UE4.FLinearColor(0.0 , 0.238 , 0.0 , 1))
    --UE4.UKismetSystemLibrary.DrawDebugSphere(self.Owner , endPoint , 5, 5 , UE4.FLinearColor(0.238 , 0.2123387, 0.0 , 1))

    return startPoint , endPoint , bSuccess
end

--- 第一条镜头中心检测
function AimAssistMgr:GetTraceCkFirstLineCharacter()

    local startPoint , endPoint , bGetCkPoint = self:GetCameraCenterTracePoints()
    if not bGetCkPoint then
        return false , nil
    end

    local IgnoreActors = UE4.TArray(UE4.AActor)
    self:GetIgnoreSelfActors(IgnoreActors)

    local OutHit = UE4.FHitResult()
    --UE4.UKismetSystemLibrary.LineTraceSingle(self.Owner, startPoint, endPoint, UE4.ETraceTypeQuery.AimAssist, false, IgnoreActors , UE4.EDrawDebugTrace.ForOneFrame , OutHit , true , UE4.FLinearColor(0.0,0.0,1.0,1.0))
    --UE4.UKismetSystemLibrary.LineTraceSingle(self.Owner, startPoint, endPoint, UE4.ETraceTypeQuery.AimAssist, false, IgnoreActors , UE4.EDrawDebugTrace.ForOneFrame , OutHit , true)
    --void DrawDebugLine(const UWorld* InWorld, FVector const& LineStart, FVector const& LineEnd, FColor const& Color, bool bPersistentLines, float LifeTime, uint8 DepthPriority, float Thickness)
    local bHit = UE4.UKismetSystemLibrary.LineTraceSingle(self.Owner, startPoint, endPoint, UE4.ETraceTypeQuery.Weapon, false, IgnoreActors , UE4.EDrawDebugTrace.None , OutHit , true)

    local ckActor = OutHit.Actor

    self.AimObjectState = -1

    if ckActor and self:IsActorIsEnemy(ckActor) then
        self.AimObjectState = 0
        return  bHit , ckActor , OutHit
    elseif ckActor and self:IsActorIsIsTeammate(ckActor) then
        self.AimObjectState = 1
    end
    return false , nil , nil
end

---- 检测物体区域 ， 检测角色射击点
function AimAssistMgr:GetTraceCheckSphereCharacter(OutHits)
    local outTarget = nil
    local outHitRef = nil

    if OutHits == nil then
        return outTarget , outHitRef
    end

    for i = 1, OutHits:Length() do
        local ckActor = OutHits:GetRef(i).Actor

        if ckActor ~= nil then
            local ownerCharacter = self.Owner:GetOwningPawn()
            if ownerCharacter then
                local ownerCharacterBase = ownerCharacter:Cast(UE4.ABP_ShooterCharacterBase_C)
                if ownerCharacterBase then
                    local characterBase = ckActor:Cast(UE4.ABP_ShooterCharacterBase_C)
                    if characterBase and ownerCharacterBase:IsEnemy(characterBase) then
                        outTarget , outHitRef = self:GetTraceCharacterHitPoint(characterBase , OutHits:GetRef(i))
                        return outTarget , outHitRef
                    end
                end
            end
        end
    end

    return nil , nil
end

--- 检测自动开火射击点
function AimAssistMgr:GetTraceCharacterHitPoint(target, OutHitRef)
    if OutHitRef == nil or
            target == nil or
            target.Mesh == nil then
        return nil , nil
    end

    local IgnoreActors = UE4.TArray(UE4.AActor)
    self:GetIgnoreSelfActors(IgnoreActors)

    --- 获取检测射击点
    local aimingTargetsPoints = UE4.TArray(UE4.FVector)
    self:GetShooterCheckSocketPoint(target , self.AutoFireSocketTb , aimingTargetsPoints)
    if not aimingTargetsPoints or aimingTargetsPoints:Length() <= 0 then
        return nil , nil
    end

    local traceStartPoint , traceForwardPoint = self:GetCameraStartPointAndForwardPoint(self.Owner.AutomaticTraceMaxDis)

    --- 射击检测
    for i = 1, aimingTargetsPoints:Length() do
        local tracePoint = aimingTargetsPoints:GetRef(i)
        if tracePoint ~= nil then

            local traceEndPoint = tracePoint
            local OutHit = UE4.FHitResult()
            --local bHit = UE4.UKismetSystemLibrary.LineTraceSingle(self.Owner, traceStartPoint, traceEndPoint, UE4.ETraceTypeQuery.Weapon, false, IgnoreActors , UE4.EDrawDebugTrace.ForOneFrame , OutHit , true , UE4.FLinearColor(0.0,0.0,1.0,1.0))
            local bHit = UE4.UKismetSystemLibrary.LineTraceSingle(self.Owner, traceStartPoint, traceEndPoint, UE4.ETraceTypeQuery.Weapon, false, IgnoreActors , UE4.EDrawDebugTrace.None , OutHit , true)

            if bHit then
                local ckActor = OutHit.Actor

                local targetDistance = OutHit.Distance

                local degree = self:GetDegreeOfTargetTwoVector(traceForwardPoint - traceStartPoint , traceEndPoint - traceStartPoint)
                local ckAngle = self.Owner.AutomaticFireAngleCurve:GetFloatValue(targetDistance)

                if ckActor and self.Owner:GetOwningPawn() then
                    local ownerCharacterBase = self.Owner:GetOwningPawn():Cast(UE4.ABP_ShooterCharacterBase_C)
                    if ownerCharacterBase then
                        local characterBase = ckActor:Cast(UE4.ABP_ShooterCharacterBase_C)
                        if characterBase and ownerCharacterBase:IsEnemy(characterBase) then
                            if degree <= ckAngle then
                                return  tracePoint , OutHit
                            end
                        end
                    end
                end
            end
        end
    end

    return nil , nil
end

--- 获取辅助瞄准吸附点
function AimAssistMgr:GetTraceCharacterHitPointNew(target, outHitRef , angleCurve)
    if outHitRef == nil or
        target == nil or
        angleCurve == nil or
        target.Mesh == nil then
        return nil , nil
    end

    local IgnoreActors = UE4.TArray(UE4.AActor)
    self:GetIgnoreSelfActors(IgnoreActors)
    if not IgnoreActors or IgnoreActors:Length() <= 0 then
        return nil , nil
    end

    local aimingTargetsPoints = UE4.TArray(UE4.FVector)
    self:GetShooterCheckSocketPoint(target , self.AimingSocketTb , aimingTargetsPoints)
    if not aimingTargetsPoints or aimingTargetsPoints:Length() <= 0 then
        return nil , nil
    end

    local traceStartPoint , traceForwardPoint = self:GetCameraStartPointAndForwardPoint(self.Owner.AutomaticTraceMaxDis)

    local maxScore = 0
    local maxScoreSocketLocation = nil
    local maxScoreOutHit = nil
    local maxScoreName = ""
    for i = 1, aimingTargetsPoints:Length() do

        local tracePoint = aimingTargetsPoints:GetRef(i)
        if tracePoint ~= nil then

            local traceEndPoint = tracePoint
            local OutHit = UE4.FHitResult()
            local bHit = UE4.UKismetSystemLibrary.LineTraceSingle(self.Owner, traceStartPoint, traceEndPoint, UE4.ETraceTypeQuery.Weapon, false, IgnoreActors , UE4.EDrawDebugTrace.None , OutHit , true)

            if bHit then

                local HitActor = OutHit.Actor
                if HitActor and self:IsActorIsEnemy(HitActor) then

                    local degree = self:GetDegreeOfTargetTwoVector(traceForwardPoint - traceStartPoint , traceEndPoint - traceStartPoint)
                    local targetDistance = OutHit.Distance
                    local ckAngle = angleCurve:GetFloatValue(targetDistance)

                    if degree <= ckAngle then
                        local score = self:GetFrictionPointScoreByDegree(self.AimingSocketTb[i] , degree)
                        if score > maxScore then
                            maxScore = score
                            maxScoreSocketLocation = tracePoint
                            maxScoreOutHit = OutHit
                            maxScoreName = self.AimingSocketTb[i]
                        end
                    end
                end
            end
        end
    end

    if maxScoreSocketLocation then
        return maxScoreSocketLocation , maxScoreOutHit
    else
        return nil , nil
    end
end

--- 获取
function AimAssistMgr:GetCameraStartPointAndForwardPoint(forwardDistance)

    local playerCameraMgr = UE4.UGameplayStatics.GetPlayerCameraManager(self.Owner , 0)
    local traceStartPoint = UE4.FVector()
    local traceForwardPoint = UE4.FVector()

    if playerCameraMgr ~= nil then

        traceStartPoint = playerCameraMgr:GetCameraLocation()
        traceForwardPoint = playerCameraMgr:GetActorForwardVector() * forwardDistance
        traceForwardPoint = traceForwardPoint + traceStartPoint
    end

    return traceStartPoint ,traceForwardPoint
end


--- 状态转换接口
function AimAssistMgr:OnChangeAutoFireState(state , event)

    --print("AimAssist FSM : OnChangeAutoFireState state :" , state , " event" , event)

    local a = self.AutoFireFSM_Tb[state][event]
    if a ~= nil then
        self.LastAutoFireState = self.CurrAutoFireState
        a.action(self)
        self.CurrAutoFireState = a.new_state
    else
        print("Change State Failed . state :" , state , " event :" , event)
    end

end


-------------------------------------------------------
--- 自动开火状态
-------------------------------------------------------
function AimAssistMgr:OnReadyToFire()
    local pawn = self.Owner:GetOwningPawn()
    if pawn == nil then
        return
    end

    local characterBase = pawn:Cast(UE4.ABP_ShooterCharacterBase_C);
    if characterBase ~= nil and characterBase:IsValid() then
        characterBase:Fire_Pressed()
    end
end

function AimAssistMgr:OnReadyToLock()
    self.AutoLockTimerSwitch = true
end

function AimAssistMgr:ReadyToUnLock()
    self:ClearAutomaticTimer()
end

function AimAssistMgr:ReadyToStopFire()
    --- 退出开火
    self.ReadyToFireFlag = false

    local pawn = self.Owner:GetOwningPawn()
    if pawn == nil then
        return
    end

    local characterBase = pawn:Cast(UE4.ABP_ShooterCharacterBase_C);
    if characterBase ~= nil and characterBase:IsValid() then
        characterBase:Fire_Released()
    end
end

function AimAssistMgr:ReadyToReFire()

    local pawn = self.Owner:GetOwningPawn()
    if pawn == nil then
        return
    end

    local characterBase = pawn:Cast(UE4.ABP_ShooterCharacterBase_C);
    if characterBase ~= nil and characterBase:IsValid() then
        characterBase:Fire_Released()
        characterBase:Fire_Pressed()
    end
end

--- 清除自动开火锁定计时
function AimAssistMgr:ClearAutomaticTimer()
    self.AutoLockTimerSwitch = false
    self.ReadyToFireFlag = false
    self.AutoLockTimerCounter = 0.0
end

-----------------------------------------------------------
--- 设置数据接口 Setter
-----------------------------------------------------------
function AimAssistMgr:SetTurnSpeedMode(mode)

    if mode < AutomaticFireEnums.AimTurnSpeedMode.NORMAL_MODE or
        mode > AutomaticFireEnums.AimTurnSpeedMode.SLOWDOWN_MODE then
        return
    end

    if self.TurnSpeedMode == mode then
        return
    end
    --print("SpeedMode:" , self.TurnSpeedMode, "=>" ,mode)
    self.TurnSpeedMode = mode
end

--- 转向目标点
function AimAssistMgr:SetControlLookAtTarget(targetPoint)
    local playerCameraMgr = UE4.UGameplayStatics.GetPlayerCameraManager(self.Owner , 0)
    local playerController = UE4.UGameplayStatics.GetPlayerController(self.Owner , 0)

    if playerCameraMgr and playerController then
        local startPoint = playerCameraMgr:GetCameraLocation()
        local endPoint = targetPoint
        local curRotator = playerController:GetControlRotation()
        local worldDeltaSec = UE4.UGameplayStatics.GetWorldDeltaSeconds(self.Owner)

        local fRotator = UE4.UKismetMathLibrary.FindLookAtRotation(startPoint , endPoint)
        local newRotator = UE4.UKismetMathLibrary.RInterpTo(curRotator , fRotator , worldDeltaSec , self:GetFrictionSpeed())

        playerController:SetControlRotation(newRotator)
    end
end


-----------------------------------------------------------
--- 获取数据接口 Getter
-----------------------------------------------------------

--- 获取 AShooterHUD
---@return AShooterHUD
function AimAssistMgr:GetOwner()
    return self.Owner
end

--- 获取当前自动开火状态
function AimAssistMgr:GetAutoFireState()
    return self.CurrAutoFireState
end

--- 获取检测起始点偏移
function AimAssistMgr:GetAutomaticStartPointOffset()
    local pawn = self.Owner:GetOwningPawn()
    if pawn == nil then
        return self.Owner.AutomaticFire_Offset_1
    end

    local characterBase = pawn:Cast(UE4.ABP_ShooterCharacterBase_C);
    if characterBase ~= nil then
        if characterBase:IsCovering() and characterBase:IsWeaponAim() then
            return self.Owner.AutomaticFire_Offset_3
        end

        if not characterBase:IsCovering() and characterBase:IsWeaponAim() then
            return self.Owner.AutomaticFire_Offset_2
        end
    end

    return self.Owner.AutomaticFire_Offset_1
end

--- 获取关节点
---@param target Actor
---@param socketTb table {"",""}
---@param targetSocketPoint TArray(UE4.FVector)
function AimAssistMgr:GetShooterCheckSocketPoint(target , socketTb , targetSocketPoint)
    if not target or
        not socketTb or
        not targetSocketPoint then
        return nil
    end

    local targetMesh = target.Mesh
    for i = 1, #socketTb do
        if targetMesh then
            local socketLocation = targetMesh:GetSocketLocation(socketTb[i])
            if socketLocation then
                targetSocketPoint:Add(socketLocation)
            end
        end
    end
end

--- 获取忽略自己的Actor列表
---@param IgnoreActors TArray(UE4.AActor)
function AimAssistMgr:GetIgnoreSelfActors(IgnoreActors)
    if IgnoreActors then
        local ownPawn = self.Owner:GetOwningPawn()
        if ownPawn ~= nil then
            IgnoreActors:Add(ownPawn)
        end
    end
end

--- 获取夹角
function AimAssistMgr:GetDegreeOfTargetTwoVector(vector1 , vector2)

    vector1 = vector1:GetSafeNormal()
    vector2 = vector2:GetSafeNormal()

    local vectorDot = UE4.UKismetMathLibrary.Dot_VectorVector(vector1 , vector2)
    local size = vector1:Size() * vector1:Size()

    local vectorCos = vectorDot / size
    local cosAngle = UE4.UKismetMathLibrary.Acos(vectorCos)
    local angleAgree = UE4.UKismetMathLibrary.RadiansToDegrees(cosAngle)

    return angleAgree
end

---通过度数获得贴靠点分数
function AimAssistMgr:GetFrictionPointScoreByDegree(aimSocket ,degree)
    local score = 0
    if aimSocket then
        local socketScoreCurve = self.Owner.FrictionPointScoreCurve:Find(aimSocket)
        if socketScoreCurve then
            score = socketScoreCurve:GetFloatValue(degree)
        end
    end

    return score
end

--- 获取允许磁贴状态
function AimAssistMgr:GetOwnerFireFrictionState()
    local owningPawn = self.Owner:GetOwningPawn()
    local shooterOwnerBase = nil
    local bFireFriction = false
    if owningPawn then
        shooterOwnerBase = owningPawn:Cast(UE4.ABP_ShooterCharacterBase_C)
        if shooterOwnerBase then
            bFireFriction = shooterOwnerBase:IsFiring()
        end
    end

    return bFireFriction , shooterOwnerBase
end

--- 获取输入取消磁贴
function AimAssistMgr:GetInputCancelFriction()
    local inputCancelFriction = 0.0

    if self.Owner and self.Owner:IsValid() then
        inputCancelFriction = self.Owner.InputCancelFriction
    end

    return inputCancelFriction
end

--- 获取磁贴速度
function AimAssistMgr:GetFrictionSpeed()
    local frictionSpeed = 0.0

    if self.Owner and self.Owner:IsValid() then
        frictionSpeed = self.Owner.FrictionSpeed
    end

    return frictionSpeed
end



-----------------------------------------------------------
--- 判断接口 Is
-----------------------------------------------------------
--- 角色是否开火
function AimAssistMgr:IsFiring()
    local pawn = self.Owner:GetOwningPawn()
    if pawn == nil then
        return false
    end

    local characterBase = pawn:Cast(UE4.ABP_ShooterCharacterBase_C);
    if characterBase ~= nil then
        return characterBase:IsFiring()
    end

    return false
end

--- 是否开启自动开火
function AimAssistMgr:IsAutomaticFireEnable()
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()

    local AutomaticFireSettings = UserConfigSettings.AutoFireSetting
    local IsCanAutomaticFire = false

    if UserConfigSettings ~= nil then
        IsCanAutomaticFire = UserConfigSettings:GetBool(AutomaticFireSettings.Section, AutomaticFireSettings.Key, AutomaticFireSettings.Value)
    end

    return IsCanAutomaticFire
end

--- 是否开启辅助瞄准
function AimAssistMgr:IsAimAssistEnable()
    local UserConfigSettings = ShooterGameInstance:GetUserConfigSettings()

    local AimAssistSettings = UserConfigSettings.AimAssistSetting
    local IsCanAutomaticFire = false

    if UserConfigSettings ~= nil then
        IsCanAutomaticFire = UserConfigSettings:GetBool(AimAssistSettings.Section, AimAssistSettings.Key, AimAssistSettings.Value)
    end

    return IsCanAutomaticFire
end

--- 检测是否是敌人
function AimAssistMgr:IsActorIsEnemy(checkActor)
    if checkActor and self.Owner:GetOwningPawn() then
        local ownerCharacterBase = self.Owner:GetOwningPawn():Cast(UE4.ABP_ShooterCharacterBase_C)
        if ownerCharacterBase then
            local characterBase = checkActor:Cast(UE4.ABP_ShooterCharacterBase_C)
            if characterBase and ownerCharacterBase:IsEnemy(characterBase) then
                return true
            end
        end
    end

    return false
end

--- 检测是否是队友
function AimAssistMgr:IsActorIsIsTeammate(checkActor)
    if checkActor and self.Owner:GetOwningPawn() then
        local ownerCharacterBase = self.Owner:GetOwningPawn():Cast(UE4.ABP_ShooterCharacterBase_C)
        if ownerCharacterBase then
            local characterBase = checkActor:Cast(UE4.ABP_ShooterCharacterBase_C)
            if characterBase and ownerCharacterBase:IsTeammate(characterBase) then
                return true
            end
        end
    end

    return false
end

--- 当前输入是否支持磁贴操作
function AimAssistMgr:IsInputAcceptAimFriction()
    --- 输入差值过大不执行磁贴操作
    local playerController = UE4.UGameplayStatics.GetPlayerController(self.Owner , 0)
    if playerController then
        local movX , movY = playerController:GetInputMouseDelta()

        local inputCancelFriction = self:GetInputCancelFriction()
        if math.abs(movX) >= inputCancelFriction or math.abs(movY) >= inputCancelFriction then
            return false
        end
    end

    return true
end

--- 是否处于摄像机减慢转速模式
function AimAssistMgr:IsAimTurnSlowDown()
    return self.TurnSpeedMode == AutomaticFireEnums.AimTurnSpeedMode.SLOWDOWN_MODE
end


return AimAssistMgr