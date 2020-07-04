
local LUIManager = require("UI/UIManager")

-- UI配置表
--[[
    bp_class: 蓝图基本的路径
    layer: 显示层级
    mode: 显示模式(overlay = 叠加模式, 不隐藏底层的界面; fullScreen = 全屏模式, 隐藏底层所有界面)
--]]
LUIManager.UIConfig = {
	--- 通用提示框
	UIMessageBox = { name = "UIMessageBox", bp_class = "/Game/UI/UICommonTips/UIMessageBox.UIMessageBox", layer = 10, mode = "overlay" },


    --- 登录界面
    UILoginMain = { name = "UILoginMain", bp_class = "/Game/UI/UILogin/UI_LoginMain.UI_LoginMain", layer = 1, mode = "fullScreen" },
    --- 创建角色界面
    UILoginCreateRole = { name = "UILoginCreateRole", bp_class = "/Game/UI/UILogin/UILoginCreateRole.UILoginCreateRole", layer = 2, mode = "fullScreen" },
	--- 大厅界面
	UIMainEnterMain = { name = "UIMainEnterMain", bp_class = "/Game/UI/UIMainEnter/UI_MainEnter_2.UI_MainEnter_2", layer = 1, mode = "fullScreen" },
	--- 房间主界面
	UICustomRoom = { name = "UICustomRoom", bp_class = "/Game/UI/UICustomRoom/UICustomRoom.UICustomRoom", layer = 1, mode = "fullScreen" },
	--- 进入房间界面
	UICustomRoomMain = { name = "UICustomRoomMain", bp_class = "/Game/UI/UICustomRoom/UICustomRoomMain.UICustomRoomMain", layer = 1, mode = "fullScreen" },
	--- 预匹配界面
	UIMatchBattleType = { name = "UIMatchBattleType", bp_class = "/Game/UI/UIMatchBattleType/UIMatchBattleType.UIMatchBattleType", layer = 1, mode = "fullScreen" },
	--- 匹配计时
	UIMatchReadyTips = { name = "UIMatchReadyTips", bp_class = "/Game/UI/UIMatchBattleType/UIMatchReadyTips.UIMatchReadyTips", layer = 2, mode = "overlay" },
	--- 战前选人界面
	UIChooseHero = { name = "UIChooseHero", bp_class = "/Game/UI/UIChooseHero/UIChooseHero.UIChooseHero", layer = 1, mode = "fullScreen" },


	--- 战斗界面
	UIBattleMain = { name = "UIBattleMain", bp_class = "/Game/UI/UIBattle/UIBattleMain/UIBattleMain2.UIBattleMain2", layer = 1, mode = "fullScreen" },
	--- 战斗设置自定义界面
	UIBattleUserDefineSetting = { name = "UIBattleUserDefineSetting", bp_class = "/Game/UI/UIBattle/UIBattleSetting/UIBattleMainUserDefine.UIBattleMainUserDefine", layer = 1, mode = "overlay" },
	--- 战斗小地图界面
	UIBattleMiniMap = { name = "UIBattleMiniMap", bp_class = "/Game/UI/UIBattle/UIMiniMap/UI_BattleMiniMap.UI_BattleMiniMap", layer = 1, mode = "overlay" },
	--- 战斗设置界面
	UIBattleSetting = { name = "UIBattleSetting", bp_class = "/Game/UI/UIBattle/UIBattleSetting/UIBattleSetting.UIBattleSetting", layer = 1, mode = "overlay" },
	--- 结算界面
	UIBattleResult = { name = "UIBattleResult", bp_class = "/Game/UI/UIBattleResult/UIBattleResult.UIBattleResult", layer = 1, mode = "fullScreen" },

	
}

LUIManager.ItemQualityIconPath = {
	[0] = "UI/Atlas/BattleBag/Frames/T_BG_diaopinzhi01_png",
	[1] = "UI/Atlas/BattleBag/Frames/T_BG_diaopinzhi01_png",
	[2] = "UI/Atlas/BattleBag/Frames/T_BG_diaopinzhi02_png",
	[3] = "UI/Atlas/BattleBag/Frames/T_BG_diaopinzhi03_png",
	[4] = "UI/Atlas/BattleBag/Frames/T_BG_diaopinzhi04_png",
}

function GetItemQualityIconPath(quality)
	return LUIManager.ItemQualityIconPath[quality];
end


LUIManager.BulletTypeQualityIconPath = {
	[1002131] = "UI/Atlas/BattleBag/Frames/T_BG_diaozidan01_png",
	[1002111] = "UI/Atlas/BattleBag/Frames/T_BG_diaozidan02_png",
	[1002121] = "UI/Atlas/BattleBag/Frames/T_BG_diaozidan03_png",
	[1002141] = "UI/Atlas/BattleBag/Frames/T_BG_diaozidan04_png",
}

function GetBulletTypeQualityPath(resID)
	return LUIManager.BulletTypeQualityIconPath[resID];
end

----装备底图彪
LUIManager.EquipBkIconPath = {
	[Ds_EquipBarType.EQUIPBARTYPE_NONE] = "";
	[Ds_EquipBarType.EQUIPBARTYPE_WEAPON1] = "",
	[Ds_EquipBarType.EQUIPBARTYPE_WEAPON2] = "",
	[Ds_EquipBarType.EQUIPBARTYPE_FIST] = "",
	[Ds_EquipBarType.EQUIPBARTYPE_THROW] = "",
	[Ds_EquipBarType.EQUIPBARTYPE_PROP] = "",
	[Ds_EquipBarType.EQUIPBARTYPE_ARMOR] = "UI/Atlas/ItemIcon/Frames/Icon_Shield_Body_G_png",
	[Ds_EquipBarType.EQUIPBARTYPE_HELMET] = "UI/Atlas/ItemIcon/Frames/Icon_Shield_Head_G_png",
	[Ds_EquipBarType.EQUIPBARTYPE_DOWNSHIELD] = "UI/Atlas/ItemIcon/Frames/Icon_Shield_Shield01_G_png",
	[Ds_EquipBarType.EQUIPBARTYPE_BAG] = "UI/Atlas/ItemIcon/Frames/Icon_BackPack01_G_png",
	[Ds_EquipBarType.EQUIPBARTYPE_MAX] = "";
}

function GetEquipBkIconPath(barType)
	return LUIManager.EquipBkIconPath[barType];
end

--队伍颜色
LUIManager.TeamColorKey = {
	[0] = FLinearColor(1.0,1.0,1.0,1.0),
	[1] = FLinearColor(0.86,0.62,0.27,1.0),
	[2] = FLinearColor(0.79,0.86,0.27,1.0),
	[3] = FLinearColor(0.27,0.86,0.69,1.0),
	[4] = FLinearColor(0.27,0.86,0.69,1.0),
	[5] = FLinearColor(0.27,0.86,0.69,1.0),
}

function GetTeamColorKeyByIndex(index)
	return LUIManager.TeamColorKey[index];
end

LUIManager.BagCapacityTextColor = {
    Red     = FLinearColor(1.0, 0, 0, 1.0),
    White   = FLinearColor(1.0, 1.0, 1.0, 1.0),
}

--- [ID号和必须道具表一致]
LUIManager.GamePlayAmmoIcon =
{
	--- 轻型弹药
	[1002111] = "UI/Atlas/BattleMain/Frames/T_ICON_zidan02_png.T_ICON_zidan02_png",
	--- 重型弹药
	[1002121] = "UI/Atlas/BattleMain/Frames/T_ICON_zidan04_png.T_ICON_zidan04_png",
	--- 霰弹枪子弹
	[1002131] = "UI/Atlas/BattleMain/Frames/T_ICON_zidan01_png.T_ICON_zidan01_png",
	--- 能量弹药
	[1002141] = "UI/Atlas/BattleMain/Frames/T_ICON_zidan03_png.T_ICON_zidan03_png",
}

function GetGamePlayAmmoIconByResID(resID)
	return LUIManager.GamePlayAmmoIcon[resID]
end

LUIManager.GamePlayShieldFillImage =
{
    --White
    [0] = "UI/Atlas/BattleMain/Frames/T_ICON_hudun_01_png.T_ICON_hudun_01_png",
    --Blue
    [1] = "UI/Atlas/BattleMain/Frames/T_ICON_hudun_02_png.T_ICON_hudun_02_png",
    --Purple
    [2] = "UI/Atlas/BattleMain/Frames/T_ICON_hudun_03_png.T_ICON_hudun_03_png",
    --Orange
    [3] = "UI/Atlas/BattleMain/Frames/T_ICON_hudun_04_png.T_ICON_hudun_04_png",
}

function GetGamePlayShieldFillImageByIndex(index)
    return LUIManager.GamePlayShieldFillImage[index]
end

LUIManager.GamePlayArmorFrameFillImage =
{
    --White
    [0] = "UI/Atlas/BattleMain/Frames/T_ICON_hudun_01_png.T_ICON_hudun_01_png",
    --Blue
    [1] = "UI/Atlas/BattleMain/Frames/T_ICON_hudun_02_png.T_ICON_hudun_02_png",
    --Purple
    [2] = "UI/Atlas/BattleMain/Frames/T_ICON_hudun_03_png.T_ICON_hudun_03_png",
    --Orange
    [3] = "UI/Atlas/BattleMain/Frames/T_ICON_hudun_04_png.T_ICON_hudun_04_png",
}

------------ 通用 Message Box
LUIManager.UIMessageBoxContentType =
{
	CenterTextOnly = 1 ,
	CenterWithIcon = 2 ,
}

LUIManager.UIMessageBoxBtnType =
{
	SubmitAndCancel = 1 ,
}

function GetUIMessageBoxContentTypeEnums()
	return LUIManager.UIMessageBoxContentType
end

function GetUIMessageBoxBtnTypeEnums()
	return LUIManager.UIMessageBoxBtnType
end

------------ 性别图标
LUIManager.UIGenderImg =
{
	[1] = "UI/Atlas/Commom_new/Frames/T_ICON_tong_xingbie01_png" ,
	[2] = "UI/Atlas/Commom_new/Frames/T_ICON_tong_xingbie02_png" ,
}

function GetUIGenderImg(genderKeyword)
	return LUIManager.UIGenderImg[genderKeyword]
end

