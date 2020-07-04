require "UnLua"

local BP_EntranceHUD_C = Class()

function BP_EntranceHUD_C:Initialize(Initializer)

    self.bTestTime = 0
    self.ExecuteTime = 2
    self.bExecute = false
end

function BP_EntranceHUD_C:UserConstructionScript()

end

function BP_EntranceHUD_C:ReceiveBeginPlay()
    --LUIManager:ShowWindow("UILoginMain")
end

--function BP_EntranceHUD_C:ReceiveEndPlay()
--end

function BP_EntranceHUD_C:ReceiveTick(DeltaSeconds)
    self.bTestTime = self.bTestTime + DeltaSeconds
    if self.bTestTime >= self.ExecuteTime and not self.bExecute then
        print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
        LUIManager:ShowWindow("UILoginMain")
        self.bExecute = true
        print("%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%")
    end
end

--function BP_EntranceHUD_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function BP_EntranceHUD_C:ReceiveActorBeginOverlap(OtherActor)
--end

--function BP_EntranceHUD_C:ReceiveActorEndOverlap(OtherActor)
--end

function BP_EntranceHUD_C:ReceiveDestroyed()
    LUIManager:DestroyAllWindow()
end

return BP_EntranceHUD_C
