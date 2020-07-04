require "UnLua"

local BP_MainMenuPawn_C = Class()

function BP_MainMenuPawn_C:Initialize(Initializer)
    self.curMainMenuHero = nil
    self.MaxHeroNum = 0
end

function BP_MainMenuPawn_C:UserConstructionScript()
    self.AllMainMenuHero = {}
    self.MaxHeroNum = self.Plane:GetNumChildrenComponents()

    for i = 1, self.MaxHeroNum do
        self.AllMainMenuHero[i] = self.Plane:GetChildComponent(i - 1)
    end
    self.curHeroIndex = math.random(1,self.MaxHeroNum)
    self.curMainMenuHero = self.AllMainMenuHero[self.curHeroIndex]
end

--function BP_MainMenuPawn_C:ReceiveBeginPlay()
--end

-- 旋转模型
function BP_MainMenuPawn_C:RotateModel(newRotation)
    if self.curMainMenuHero ~= nil then
        self.curMainMenuHero:K2_AddLocalRotation(newRotation, false, nil, false)
    end
end

-- 切换模型
function BP_MainMenuPawn_C:ChangCurModel()
    self.curHeroIndex = self.curHeroIndex + 1
    if self.curHeroIndex > self.MaxHeroNum then
        self.curHeroIndex = 1
    end
    self.curMainMenuHero = self.AllMainMenuHero[self.curHeroIndex]
end

function BP_MainMenuPawn_C:ReceiveTick(DeltaSeconds)
    self:OnRefreshModel()
end

-- 刷新模型
function BP_MainMenuPawn_C:OnRefreshModel()
    for i = 1, self.MaxHeroNum do
        
        if self.AllMainMenuHero[i] == nil or self.curMainMenuHero == nil then
            return
        end

        if self.AllMainMenuHero[i] ~= self.curMainMenuHero then
            self.AllMainMenuHero[i]:SetVisibility(false)
            self.AllMainMenuHero[i]:GetChildComponent(0):SetVisibility(false)
        else
            self.AllMainMenuHero[i]:SetVisibility(true)
            self.AllMainMenuHero[i]:GetChildComponent(0):SetVisibility(true)
        end
    end

end
--function BP_MainMenuPawn_C:ReceiveEndPlay()
--end

--function BP_MainMenuPawn_C:ReceiveAnyDamage(Damage, DamageType, InstigatedBy, DamageCauser)
--end

--function BP_MainMenuPawn_C:ReceiveActorBeginOverlap(OtherActor)
--end

--function BP_MainMenuPawn_C:ReceiveActorEndOverlap(OtherActor)
--end

return BP_MainMenuPawn_C
