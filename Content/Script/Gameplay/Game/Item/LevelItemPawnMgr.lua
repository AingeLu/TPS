require "UnLua"

local LevelItemPawnMgr = class(LevelItemPawnMgr)

function LevelItemPawnMgr:ctor()
    self.ShooterGameModeBase = nil;
end

function LevelItemPawnMgr:OnInit(ShooterGameModeBase)
 
    self.ShooterGameModeBase = ShooterGameModeBase;

end

function LevelItemPawnMgr:OnUnInit()
 

end

function LevelItemPawnMgr:HandleMatchIsWaitingToStart()
 
    local AllActors = UE4.UGameplayStatics.GetAllActorsOfClass(self.ShooterGameModeBase, ShooterGameInstance.LevelItemStartClass)
    for i = 1, AllActors:Length() do
        local Actor = AllActors:Get(i)
        if  Actor.ItemID > 0 then
            self:SpawnDropItemActor(self.ShooterGameModeBase:GetWorld(), Actor:K2_GetActorLocation() , Actor:K2_GetActorRotation(),
             Actor.ItemID)
        end
    end

end

--查找范围内最优的掉落
function LevelItemPawnMgr:GetClosestBestDropItem(AC_Character)

    if AC_Character == nil then
        return nil;
    end

    local Range = 120.0;
    local Center = AC_Character:K2_GetActorLocation();
	local Forward = AC_Character:GetActorForwardVector();

	local PickRangeSq = g_GamePickRange * g_GamePickRange;

    --射线目标
    local Controller = AC_Character:GetController();
    if Controller then
    
        local LOSItem = self:GetLOSDropItem(AC_Character, Controller:Cast(UE4.ABP_ShooterPlayerControllerBase_C));
        if LOSItem and LOSItem:IsValid() then
        
            local Direction = LOSItem:K2_GetActorLocation() - Center;
            if Direction.SizeSquared() <= PickRangeSq then
                return LOSItem;
            end
        end
    end
    

    --找到夹角范围内最近的目标
    
    local LimitDot = math.cos((Range / 2) * math.pi / 180);
    local nearestDissq = MATH_INT32_MAXVAL;
    local bestDropItem = nil;

    local AllActors = UE4.UGameplayStatics.GetAllActorsOfClass(self.ShooterGameModeBase, ShooterGameInstance.LevelDropItemClass)
    for i = 1, AllActors:Length() do
        local item = AllActors:GetRef(i)
        if item:IsValid() then
      
            local Direction = item:K2_GetActorLocation() - Center;
            local DistSq = Direction:SizeSquared();
            if DistSq <= PickRangeSq then

                Direction:Normalize();
                local Dot = Direction:Dot(Forward);
                if Dot >= LimitDot then
                   
                    if DistSq < nearestDissq then
                        nearestDissq = DistSq;
                        bestDropItem = item;
                    end

                end

            end
        end
        
    end


    if bestDropItem ~= nil then
        return bestDropItem;
    end

    --找到距离最近的
    nearestDissq = MATH_INT32_MAXVAL;
    bestDropItem = nil;
    for i = 1, AllActors:Length() do
        local item = AllActors:GetRef(i)
        if item:IsValid() then
      
            local Direction = item:K2_GetActorLocation() - Center;
            local DistSq = Direction:SizeSquared();
            if DistSq > PickRangeSq then
                
            else

                local Direction = item:K2_GetActorLocation() - Center;
                local DistSq = Direction:SizeSquared();
                if DistSq < nearestDissq then
                    nearestDissq = DistSq;
                    bestDropItem = item;
                end
            end
        end
        
    end

    return bestDropItem;
end

--射线拾取目标
function LevelItemPawnMgr:GetLOSDropItem(AC_Character, AC_PlayerController)

	if AC_Character == nil or AC_PlayerController == nil then
        return nil;
    end

    if AC_PlayerController.PlayerCameraManager == nil then
        return nil;
    end


    local OutCamLoc = AC_PlayerController.PlayerCameraManager:GetCameraLocation();
    local OutCamRot = AC_PlayerController.PlayerCameraManager:GetCameraRotation();

    local Direction = OutCamRot:ToVector();

    local StartLocation = OutCamLoc;
    local EndLocation = StartLocation + Direction * 400.0;
    local OutHit = UE4.FHitResult()

    local bResult = UE4.UKismetSystemLibrary.SphereTraceSingle(AC_Character, StartLocation, EndLocation, 20.0, UE4.ETraceTypeQuery.DropItem,
        false, nil, UE4.EDrawDebugTrace.None, OutHit, true)
   if bResult == true then
        return nil;  --TODO 有问题
        --return OutHit.Actor ~= nil and  OutHit.Actor:Cast(UE4.ABP_LevelDropItem_C) or nil;
   end

	return nil;
end


function LevelItemPawnMgr:SpawnDropItemActor(ShooterGameModeBase, Center, Rotation, itemID)

    local ResItemDesc =  GameResMgr:GetGameResDataByResID("ItemDesc_Res", itemID)
	if not ResItemDesc then
		print("Error: LevelItemPawnMgr::SpawnDropItemActor ResItemDesc is null resID = ", itemID)
		return nil
    end

    local ItemClass =  ResourceMgr:LoadClassByBlueprintsPath(ResItemDesc.ModePath)
    if not ItemClass then
		print("Error: LevelItemPawnMgr::SpawnDropItemActor ItemClass is null ModePath = ", ResItemDesc.ModePath)
		return nil
    end

    local SpawnTransform = FTransform(Rotation:ToQuat(), Center)
    local Actor = UE4.UGameplayStatics.BeginDeferredActorSpawnFromClass(ShooterGameModeBase, ItemClass, SpawnTransform,
     UE4.ESpawnActorCollisionHandlingMethod.AlwaysSpawn)
    if  Actor then
        Actor:OnInit(itemID, 1, 0, 0)
        UE4.UGameplayStatics.FinishSpawningActor(Actor, SpawnTransform)
    end

    return Actor;
end

return LevelItemPawnMgr
