require "UnLua"

local BP_LevelDropItem_C = Class()

function BP_LevelDropItem_C:Initialize(Initializer)
    
   
end

function BP_LevelDropItem_C:OnInit(iResID, Num, BulletNum, ValidTime)

    self.ItemResID = iResID;
    self.ItemNum = Num;
    self.BulletNum = BulletNum;

    if ValidTime > 0.1 then
        self:SetLifeSpan(ValidTime);
    end
end

function BP_LevelDropItem_C:PickItem(character)

    self.ItemNum = 0;
 
    self:SetLifeSpan(0.01);
end

function BP_LevelDropItem_C:IsValid()
    return self.ItemNum > 0 and true or false;
end

return BP_LevelDropItem_C;