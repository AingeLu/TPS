require "UnLua"

local BP_MainMenuHUD_C = Class()

function BP_MainMenuHUD_C:Initialize(Initializer)


end

--function BP_MainMenuHUD_C:UserConstructionScript()
--end

function BP_MainMenuHUD_C:ReceiveBeginPlay()
    LUIManager:ShowWindow("UIMainEnterMain");
    LUIManager:DestroyWindow("UILoginMain");
    LUIManager:DestroyWindow("UILoginCreateRole");
end

--function BP_MainMenuHUD_C:ReceiveEndPlay()
--end

--function BP_MainMenuHUD_C:ReceiveTick(DeltaSeconds)
--end

--function BP_MainMenuHUD_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function BP_MainMenuHUD_C:ReceiveActorBeginOverlap(OtherActor)
--end

--function BP_MainMenuHUD_C:ReceiveActorEndOverlap(OtherActor)
--end

function BP_MainMenuHUD_C:ReceiveDestroyed()
    LUIManager:DestroyAllWindow()
end

return BP_MainMenuHUD_C
