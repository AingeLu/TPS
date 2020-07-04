if MathUtils then
    return MathUtils
end

MathUtils = {}

-------------------------------------------------------------------------
-- 数学接口
-------------------------------------------------------------------------
--- 判断点是否在一个矩形内
--- 判断该点是否在上下两条边和左右两条边之间，
--- 判断一个点是否在两条线段之间夹着，就转化成，判断一个点是否在某条线段的一边上，就可以利用叉乘的方向性，来判断夹角是否超过了180
---（前提是计算边所在的向量时采用的是同一个方向，同为顺时针或者同为逆时针），利用叉积求解
function MathUtils:IsPointInMatrix(p, p1, p2, p3, p4)
	return (self:GetCross(p1, p2, p) * self:GetCross(p3, p4, p) >= 0) and (self:GetCross(p2, p3, p) * self:GetCross(p4, p1, p) >= 0)
end
-- 计算 |p1 p2| X |p1 p|
function MathUtils:GetCross(p1, p2, p)
	return (p2.X - p1.X) * (p.Y - p1.Y) - (p2.Y - p1.Y) * (p.X - p1.X)
end

--- 凸多边形内部的点都在凸多边形的边所在的向量的同一侧
---（前提是计算边所在的向量时采用的是同一个方向，同为顺时针或者同为逆时针），利用叉积求解
function MathUtils:IsPointInRect(Point, PointA, PointB, PointC, PointD)
    local AB = PointB - PointA
    local BC = PointC - PointB
    local CD = PointD - PointC
    local DA = PointA - PointD

    local AP = Point - PointA
    local BP = Point - PointB
    local CP = Point - PointC
    local DP = Point - PointD

    local a = AB:Cross(AP)
    local b = BC:Cross(BP)
    local c = CD:Cross(CP)
    local d = DA:Cross(DP)

    if (a.Z >= 0 and b.Z >= 0 and c.Z >= 0 and d.Z >= 0) or (a.Z <= 0 and b.Z <= 0 and c.Z <= 0 and d.Z <= 0) then
        return true
    end

    return false
end

--- 判断点是否在向量的前方
-- Dot，返回值为正时,目标在自己的前方,反之在自己的后方
function MathUtils:IsPointOnForward(Point, PointA, PointB)
    local AB = PointB - PointA
    AB.Z = 0

    local AP = Point - PointA
    AP.Z = 0

    local a = AB:Dot(AP)
    if a >= 0 then
        return true
    end

    return false
end

--- 判断点是否在向量的右侧
-- Cross 返回值为正时,目标在自己的右方,反之在自己的左方
function MathUtils:IsPointOnRight(Point, PointA, PointB)
    local AB = PointB - PointA

    local AP = Point - PointA

    local a = AB:Cross(AP)
    if a.Z >= 0 then
        return true
    end

    return false
end

--- 判断向量是否夹在两个向量中间
function MathUtils:IsVectorInClamps(Vector, Point, PointA, PointB)
    local AP = Point - PointA
    local BP = Point - PointB

    local a = Vector:Cross(AP)
    local b = Vector:Cross(BP)

    if a.Z >= 0 and b.Z <= 0 then
        return true
    end

    return false
end

-- 获取两个向量的夹角
function MathUtils:GetAngleBetweenVectors(Vector1, Vector2)
    Vector1:Normalize()
    Vector1.Z = 0

    Vector2:Normalize()
    Vector2.Z = 0

    local a = Vector1:Dot(Vector2)
    return UE4.UKismetMathLibrary.DegAcos(a)
end

-- 平面距离
-- 获取点到两个向量组成的线段的距离
function MathUtils:GetPointToVectorsDistance(Point, PointA, PointB)
    local AB = PointB - PointA

    local AP = Point - PointA

    -- 角度
    local a = self:GetAngleBetweenVectors(AB, AP)

    -- 斜边
    local l = (Point - PointA):SizeSquared2D()

    -- 高
    local h =  l * UE4.UKismetMathLibrary.Sin(a)

    return h
end

return MathUtils