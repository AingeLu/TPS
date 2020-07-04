--
-- DESCRIPTION
--
-- @COMPANY **
-- @AUTHOR **
-- @DATE ${date} ${time}
--

require "UnLua"

local UIBattleSetting_C = Class()

--function UIBattleSetting_C:Initialize(Initializer)
--end

--function UIBattleSetting_C:PreConstruct(IsDesignTime)
--end

 function UIBattleSetting_C:Construct()
     --------------------------------------------------------------------
     --- UI Event
     --------------------------------------------------------------------
     --- 返回
     self.Button_Return.OnClicked:Add(self, UIBattleSetting_C.OnClickedButton_Return)

	 
	-- 自定义界面功能
	self.BattleUserDefine_Button.OnClicked:Add(self,UIBattleSetting_C.OnClickedBattleUserDefine_Button)
 end

--function UIBattleSetting_C:Tick(MyGeometry, InDeltaTime)
--end

-------------------------------------------------------------------------
--- Input Event
-------------------------------------------------------------------------
function UIBattleSetting_C:OnClickedButton_Return()
    LUIManager:HideWindow("UIBattleSetting")
end

function UIBattleSetting_C:OnClickedBattleUserDefine_Button()
	LUIManager:ShowWindow("UIBattleUserDefineSetting")
end


return UIBattleSetting_C
