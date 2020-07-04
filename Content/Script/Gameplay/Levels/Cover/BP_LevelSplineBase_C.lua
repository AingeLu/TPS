require "UnLua"

local BP_LevelSplineBase_C = Class()

--function BP_LevelSplineBase_C:Initialize(Initializer)
--end

--function BP_LevelSplineBase_C:UserConstructionScript()
--end

--function BP_LevelSplineBase_C:ReceiveBeginPlay()
--end

--function BP_LevelSplineBase_C:ReceiveEndPlay()
--end

--function BP_LevelSplineBase_C:ReceiveTick(DeltaSeconds)
--end

--function BP_LevelSplineBase_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function BP_LevelSplineBase_C:ReceiveActorBeginOverlap(OtherActor)
--end

--function BP_LevelSplineBase_C:ReceiveActorEndOverlap(OtherActor)
--end

function BP_LevelSplineBase_C:GetDistanceAlongSpline(Point)
    local Value = self.Spline:FindInputKeyClosestToWorldLocation(Point)
    -- print("---------------------- Value ", Value)
    local PointValue = self.Spline:GetDistanceAlongSplineAtSplinePoint(Value)
    -- print("---------------------- PointValue ", PointValue)
    

    local Trunc_0 = UE4.UKismetMathLibrary.FTrunc(Value)
    -- print("---------------------- Trunc_0 ", Trunc_0)
    local Point_0 = self.Spline:GetDistanceAlongSplineAtSplinePoint(Trunc_0)
    -- print("---------------------- Point_0 ", Point_0)

    local Trunc_1 = UE4.UKismetMathLibrary.FTrunc(Value + 1.0)
    -- print("---------------------- Trunc_1 ", Trunc_1)
    local Point_1 = self.Spline:GetDistanceAlongSplineAtSplinePoint(Trunc_1)
    -- print("---------------------- Point_1 ", Point_1)

    -- local a = (Point_0 - Point_1)
    -- print("---------------------- Point_0 - Point_1 ", a)
    -- local b = (Trunc_0 * 1.0 - Value)
    -- print("---------------------- Trunc_0 * 1.0 - Value ", b)

    local Result = Point_0 + ((Point_0 - Point_1) * (Trunc_0 * 1.0 - Value))
    -- print("---------------------- Result ", Result)

    return Result
end

function BP_LevelSplineBase_C:GetLocationAtDistanceAlongSpline(Value)
    local Location = self.Spline:GetLocationAtDistanceAlongSpline(Value, UE4.ESplineCoordinateSpace.World)
    -- print("--------------------- Location ", Location)

    return Location
end

function BP_LevelSplineBase_C:GetRotationAtDistanceAlongSpline(Value)
    local Rotation = self.Spline:GetRotationAtDistanceAlongSpline(Value, UE4.ESplineCoordinateSpace.World)
    -- print("--------------------- Rotation ", Rotation)

    return Rotation
end

function BP_LevelSplineBase_C:GetSplineLength()
    return self.Spline:GetSplineLength()
end

return BP_LevelSplineBase_C
