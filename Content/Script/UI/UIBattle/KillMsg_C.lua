require "UnLua"

local KillMsg_C = Class()

function KillMsg_C:Initialize(Initializer)
    self.Timer = 0.0
end

function KillMsg_C:Tick(MyGeometry, InDeltaTime)
    self:OnFadeOut(InDeltaTime)
end

--击杀消息条渐褪
function KillMsg_C:OnFadeOut(InDeltaTime)
    self.Timer = self.Timer + InDeltaTime
    local FadeTime = 1
    local ShowTime = 6
    if self.Timer >= ShowTime - FadeTime and self.Timer <= ShowTime then 
        local DeltaTime = self.Timer - (ShowTime - FadeTime)
        local OpacityDelta = math.min(1.0, 1 - (DeltaTime / FadeTime))
        self:SetRenderOpacity(OpacityDelta)
    end
end

function KillMsg_C:Destruct()

end
return KillMsg_C