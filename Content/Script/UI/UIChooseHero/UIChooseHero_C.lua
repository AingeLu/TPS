require "UnLua"

local UIChooseHero_C = Class()
local UIMatchBattleTypeEnums = require "UI/UIMatch/UIMatchBattleTypeEnums"
--local UIChooseExhibition  = require("UI/UIChooseHero/UIChooseHeroExhibition")

--function UIChooseHero_C:Initialize(Initializer)
--end
--function UIChooseHero_C:PreConstruct(IsDesignTime)
--end

function UIChooseHero_C:Construct()
    -- 职业UI元素的总数目
    self.MaxClassUIElement = 4
    -- 玩家信息UI元素总数目
    self.MaxPlayerInfoUIElement = 3

    self.PlayerClass_Tb = {}
    for i = 1, self.MaxClassUIElement do
        self.PlayerClass_Tb[i] = {}
        self.PlayerClass_Tb[i].PlayerClass_Cvs = self:GetWidgetFromName("PlayerClassCanvas"..i)
        self.PlayerClass_Tb[i].PlayerClass_Btn = self:GetWidgetFromName("PlayerClass"..i)
        self.PlayerClass_Tb[i].PlayerNameClass_Text = self:GetWidgetFromName("PlayerClassName"..i)
        self.PlayerClass_Tb[i].PlayerClassHL_Img = self:GetWidgetFromName("PlayerClassHL"..i)
        self.PlayerClass_Tb[i].PlayerClassIcon_Img = self:GetWidgetFromName("PlayerClassIcon"..i .."_Img")
        if i == 1 then
            self.PlayerClass_Tb[i].bSelect = false
        else
            self.PlayerClass_Tb[i].bSelect = false
        end
    end

    --- 玩家头像UI元素
    self.PlayerInfo_Tb = {}
    for i = 1, self.MaxPlayerInfoUIElement do
        self.PlayerInfo_Tb[i] = {}

        ----左侧卡片元素
        self.PlayerInfo_Tb[i].PlayerInfo_Cvs = self:GetWidgetFromName("PlayerInfoCvs"..i)
        self.PlayerInfo_Tb[i].PlayerName_Text = self:GetWidgetFromName("PlayerNameText"..i)
        self.PlayerInfo_Tb[i].Male_Img = self:GetWidgetFromName("MaleImg"..i)
        self.PlayerInfo_Tb[i].Female_Img = self:GetWidgetFromName("FemaleImg"..i)

        self.PlayerInfo_Tb[i].ClassTypeIcon = self:GetWidgetFromName("ClassTypeIcon"..i)
    end

    --- 模型展示位置 【中间为 1 按照顺时针进行增加开始】
    self.MyRenderModeImg_Tb = {}
    for i = 1, self.MaxPlayerInfoUIElement do
        local show3dModelWidget = self:GetWidgetFromName("MyRenderModeImg" .. i)

        if show3dModelWidget ~= nil then
            show3dModelWidget:SetVisibility(UE4.ESlateVisibility.Hidden)

            local exhibitionLuaClass = show3dModelWidget

            table.insert(self.MyRenderModeImg_Tb , exhibitionLuaClass)
        end
    end

    --- 模型头顶UI 【中间为 1 按照顺时针进行增加开始】
    self.Player3dHeaderBar = {}
    for i = 1, self.MaxPlayerInfoUIElement do
        self.Player3dHeaderBar[i] = {}

        self.Player3dHeaderBar[i].Player3dHeader_Cvs = self:GetWidgetFromName("Player3dHeaderInfo"..i)
        self.Player3dHeaderBar[i].Player3dHeaderName_Text = self:GetWidgetFromName("Player3dHeaderName"..i)
        self.Player3dHeaderBar[i].PlayerGenderMale = self:GetWidgetFromName("PlayerGenderMale"..i)
        self.Player3dHeaderBar[i].PlayerGenderFemale = self:GetWidgetFromName("PlayerGenderFemale"..i)
        self.Player3dHeaderBar[i].PlayerClassType = self:GetWidgetFromName("HeaderClassType"..i)
    end

    ----------------------------------------------
    --- 数据
    ----------------------------------------------
    self.CDStartTime = 0
    self.bStart = false;
    self.CurrSelectResID = -1
    self.CurrChooseHeroState = -1
    self.DefaultResID = -1
    self.bReady = false
    --- Hero Models Caches
    self.Hero3DModelCache = {}

    --- 用于记录某个槽位下标记正在选中的模型
    self.CurrModelKey = {}
    for i = 1, self.MaxPlayerInfoUIElement do
        self.CurrModelKey[i] = 0
    end


    ----------------------------------------------
    --- 注册
    ----------------------------------------------
    self.PlayerClass_Tb[1].PlayerClass_Btn.OnClicked:Add(self, UIChooseHero_C.OnClicked_PlayerClass1_Btn)
    self.PlayerClass_Tb[2].PlayerClass_Btn.OnClicked:Add(self, UIChooseHero_C.OnClicked_PlayerClass2_Btn)
    self.PlayerClass_Tb[3].PlayerClass_Btn.OnClicked:Add(self, UIChooseHero_C.OnClicked_PlayerClass3_Btn)
    self.Ready_Btn.OnClicked:Add(self, UIChooseHero_C.OnClicked_Ready_Btn)

    self.PlayerClass_Tb[4].PlayerClass_Btn.OnClicked:Add(self, UIChooseHero_C.OnClicked_PlayerClass4_Btn)

    LUIManager:RegisterMsg("UIChooseHero",Ds_UIMsgDefine.UI_SYSTEM_MATCH_SELECT_CLASS,
            function(...) self:OnChangeSelectChangeClassType() end)

    LUIManager:RegisterMsg("UIChooseHero",Ds_UIMsgDefine.UI_SYSTEM_GAME_COUNT_DOWN,
            function(...) self:OnShowEnterBattleCD(...) end)

    LUIManager:RegisterMsg("UIChooseHero",Ds_UIMsgDefine.UI_SYSTEM_MATCH_READY_NOTIFY,
            function(...) self:OnS2cMatchReadyNotify() end)

    LUIManager:RegisterMsg("UIChooseHero",Ds_UIMsgDefine.UI_SYSTEM_MATCH_READY_RSP,
            function(...) self:OnS2cMatchReadyRsp() end)
end

function UIChooseHero_C:Destruct()
    print("UIChooseHero_C:Destruct ...")
end

function UIChooseHero_C:Tick(MyGeometry, InDeltaTime)

    --- 倒计时
    if self.bStart then
        local uworld = self:GetWorld()

        if uworld == nil then
            return
        end

        --local currTime = uworld:GetTimeSeconds()
        local currTime = UE4.UGameplayStatics.GetTimeSeconds(self)

        local CDTime = self.currTimeSecLen - (currTime - self.CDStartTime)

        CDTime = math.modf(CDTime)

        if CDTime <= 0 then
            CDTime = 0
        end

        self.CDTime_Text:SetText(CDTime)
    end

end

function UIChooseHero_C:OnShowWindow()
    self:OnInitPlayerInfo()
    self:OnInitPlayerClassType()
    self:OnInitChooseHeroStartTime()
    self:OnChangeState(UIMatchBattleTypeEnums.ChooseHeroState.None)
    self.ReadyGray_Btn:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.Ready_Btn:SetVisibility(UE4.ESlateVisibility.Visible)
    self:OnReflashPlayerInfoUI()
end

----------------------------------------------
--- UI Event Callback
----------------------------------------------
function UIChooseHero_C:OnClickedSelectedClassType(index , ...)

    if self.PlayerClass_Tb[index] == nil then
        return
    end

    local resID = self:GetResIdByClassType(self.PlayerClass_Tb[index].ClassType)

    if resID > 0 then
        self.CurrSelectResID = resID

        self:OnChangeSelectClassTypeData(index)

        --GameLogicNetWorkMgr.GetNetLogicMsgHandler():OnLogicRoomChoseHeroReq(self.CurrSelectResID);
        LUAPlayerDataMgr:GetMatchDataMgr():OnLogicRoomChoseHeroReq(self.CurrSelectResID)
    end
end

function UIChooseHero_C:OnClicked_PlayerClass1_Btn()
    self:OnClickedSelectedClassType(1)
end

function UIChooseHero_C:OnClicked_PlayerClass2_Btn()
    self:OnClickedSelectedClassType(2)
end

function UIChooseHero_C:OnClicked_PlayerClass3_Btn()
    self:OnClickedSelectedClassType(3)
end

function UIChooseHero_C:OnClicked_PlayerClass4_Btn()
    self:OnClickedSelectedClassType(4)
end

function UIChooseHero_C:OnClicked_Ready_Btn()

    if self.CurrSelectResID <= 0 then
        self.CurrSelectResID = self.DefaultResID
        end

    print("OnClick ReadyBtn : self.CurrSelectResID = " , self.CurrSelectResID)

    --GameLogicNetWorkMgr.GetNetLogicMsgHandler():OnLogicMatchReadyReq(self.CurrSelectResID);
    LUAPlayerDataMgr:GetMatchDataMgr():OnLogicMatchReadyReq(self.CurrSelectResID)
end

function UIChooseHero_C:OnChangeSelectClassTypeData(index)

    if index <= 0 or index > #self.PlayerClass_Tb then
        return
    end

    for i = 1, #self.PlayerClass_Tb do
        if self.PlayerClass_Tb[i].bShow then
            self.PlayerClass_Tb[i].bSelect = false
        end
    end

    self.PlayerClass_Tb[index].bSelect = true
end

--- 初始化玩家卡片信息和需要显示的槽位
function UIChooseHero_C:OnInitPlayerInfo()
    local PlayerCtn = LUAPlayerDataMgr:GetMatchDataMgr():GetTeamPlayerInfoCtn()

    if PlayerCtn <= 0 then
        return
    end

    local hiddenPlayerInfoIndex = 1
    --- 玩家显示部分和玩家数据
    for i = 1,PlayerCtn do
        local playerDataInfo = LUAPlayerDataMgr:GetMatchDataMgr():GetTeamPlayerInfoByIndex(i)
        if (playerDataInfo ~= nil) then
            --- 界面显示初始化
            self.PlayerInfo_Tb[i].PlayerInfo_Cvs:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            self.PlayerInfo_Tb[i].bShow = true
            --self:OnSetSinglePlayerInfoUI(playerDataInfo , self.PlayerInfo_Tb[i])
            hiddenPlayerInfoIndex = i

            if self.MyRenderModeImg_Tb[i] then
                if i == 1 then
                    self.MyRenderModeImg_Tb[i]:SetEnableRotation(true)
                else
                    self.MyRenderModeImg_Tb[i]:SetEnableRotation(false)
                end
            end

            if self.MyRenderModeImg_Tb[i] then
                self.MyRenderModeImg_Tb[i]:SetVisibility(UE4.ESlateVisibility.Hidden)
            end

            self.Player3dHeaderBar[i].Player3dHeader_Cvs:SetVisibility(UE4.ESlateVisibility.Visible)
        end
    end

    hiddenPlayerInfoIndex = hiddenPlayerInfoIndex + 1

    --- 隐藏多余UI
    for i = #self.PlayerInfo_Tb,hiddenPlayerInfoIndex , -1  do
        if self.PlayerInfo_Tb[i] ~= nil then
            self.PlayerInfo_Tb[i].PlayerInfo_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden)
            self.PlayerInfo_Tb[i].bShow = false

            self.MyRenderModeImg_Tb[i]:SetVisibility(UE4.ESlateVisibility.Hidden)
            self.Player3dHeaderBar[i].Player3dHeader_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end
end

--- 初始化职业列表
function UIChooseHero_C:OnInitPlayerClassType()

    local currSelectLegionType = LUAPlayerDataMgr:GetMatchDataMgr():GetPlayerSelectedLegion()

    local CharacterClassDesc_Tb = GameResMgr:GetGameResDataArray("CharacterDesc_Res")
    local currSelectLegionClass_Tb = {}

    --- 根据阵营筛选和角色可选的职业类型
    for k, v in pairs(CharacterClassDesc_Tb) do
        if v ~= nil then
            if v.Type == currSelectLegionType and v.IsCanSelect > 0 then
                table.insert(currSelectLegionClass_Tb , v)
            end
        end
    end

    --- 定位隐藏元素 hiddenStartIndex
    local hiddenStartIndex = 1

    --- 职业UI元素的显示部分
    for i = 1, #currSelectLegionClass_Tb do

        if self.PlayerClass_Tb[i] ~= nil then
            self.PlayerClass_Tb[i].bShow = true
            self.PlayerClass_Tb[i].ClassType = currSelectLegionClass_Tb[i].ClassType
            self.PlayerClass_Tb[i].PlayerClass_Cvs:SetVisibility(UE4.ESlateVisibility.Visible)
            self.PlayerClass_Tb[i].PlayerNameClass_Text:SetText(currSelectLegionClass_Tb[i].ClassName_CN)
            UE4.UMGLuaUtils.UMG_Image_SetBrush(self.PlayerClass_Tb[i].PlayerClassIcon_Img , currSelectLegionClass_Tb[i].ClassIconPath)

            if(self.PlayerClass_Tb[i].bSelect) then
                self.PlayerClass_Tb[i].PlayerClassHL_Img:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            else
                self.PlayerClass_Tb[i].PlayerClassHL_Img:SetVisibility(UE4.ESlateVisibility.Hidden)
            end

            hiddenStartIndex = i
        end
    end

    --- 职业UI元素的隐藏部分
    if self.MaxClassUIElement > hiddenStartIndex then
        for i = self.MaxClassUIElement, hiddenStartIndex + 1 , -1 do
            if self.PlayerClass_Tb[i] ~= nil then
                self.PlayerClass_Tb[i].bShow = false
                self.PlayerClass_Tb[i].PlayerClass_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden)
            end
        end
    end

    ----- 设置，默认职业对应的角色ID
    if self.PlayerClass_Tb[1] ~= nil then
        self.DefaultResID = self:GetResIdByClassType(self.PlayerClass_Tb[1].ClassType)
    end
end

--- 根据职业获取对应角色ID 【后续会从外部系统带进预设组，然后从预设组中找，目前直接从角色表里面取】
function UIChooseHero_C:GetResIdByClassType(classType)

    local resID = 0
    if classType == nil then
        print("UIChooseHero:GetResIdByClassType classType is nil .")
        return resID
    end

    local currSelectLegionType = LUAPlayerDataMgr:GetMatchDataMgr():GetPlayerSelectedLegion()

    local ResCharacterDesc_Tb = GameResMgr:GetGameResDataArray("CharacterDesc_Res")
    for k, v in pairs(ResCharacterDesc_Tb) do
        if v ~= nil then
            if v.ClassType == classType and currSelectLegionType == v.Type then
                resID = v.ResID
            end
        end
    end

    return resID
end

--- 开始选择英雄倒计时
function UIChooseHero_C:OnInitChooseHeroStartTime()
    local uworld = self:GetWorld()
    if uworld == nil then
        return
    end

    --self.CDStartTime = uworld:GetTimeSeconds()
    self.CDStartTime = UE4.UGameplayStatics.GetTimeSeconds(self)
    self.bStart = true
    self.currTimeSecLen = 10
end

function UIChooseHero_C:OnChangeState(NextState)

    if(self.CurrChooseHeroState == NextState) then
        return
    end

    self.CurrChooseHeroState = NextState

    self:OnReflashStateUI()
end

function UIChooseHero_C:OnReflashStateUI()
    if self.CurrChooseHeroState == UIMatchBattleTypeEnums.ChooseHeroState.None then
        print("self.CurrentState => UIMatchBattleTypeEnums.ChooseHeroState.None")
        self:OnReflashChooseHeroStateNone()
    elseif self.CurrChooseHeroState == UIMatchBattleTypeEnums.ChooseHeroState.Selected then
        print("self.CurrentState => UIMatchBattleTypeEnums.ChooseHeroState.Selected")
        self:OnReflashChooseHeroStateSelected()
    end
end

function UIChooseHero_C:OnReflashChooseHeroStateSelected()
    self.ReadyGray_Btn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.UI3dHeader_Cvs:SetVisibility(UE4.ESlateVisibility.Visible)

    self.Ready_Btn:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.PlayerList_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.SelectClassType_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden)
end

function UIChooseHero_C:OnReflashChooseHeroStateNone()
    self.Ready_Btn:SetVisibility(UE4.ESlateVisibility.Visible)
    self.PlayerList_Cvs:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
    self.SelectClassType_Cvs:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)

    self.ReadyGray_Btn:SetVisibility(UE4.ESlateVisibility.Hidden)
    self.UI3dHeader_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden)
end

--- 刷新3d展示部分UI和模型
function UIChooseHero_C:OnReflash3DPlayerHeaderInfoAndModel()
    --- 中间是自己，按照顺时针从自己开始进行轮换
    local PlayerCtn = LUAPlayerDataMgr:GetMatchDataMgr():GetTeamPlayerInfoCtn()
    local myPlayerID = LUAPlayerDataMgr:GetPlayerID()

    local startIndex = -1

    --- 定位开始本机玩家位置
    for i = 1, PlayerCtn do
        local playerDataInfo = LUAPlayerDataMgr:GetMatchDataMgr():GetTeamPlayerInfoByIndex(i)
        if playerDataInfo ~= nil then
            if playerDataInfo.uid == myPlayerID then
                startIndex = i
                break
            end
        end
    end

    if startIndex <= 0 then
        return
    end

    local location3dBarIndex = 1

    --- 本机玩家位置起点位置到终点位置
    for i = startIndex, PlayerCtn do
        local playerDataInfo = LUAPlayerDataMgr:GetMatchDataMgr():GetTeamPlayerInfoByIndex(i)
        if playerDataInfo ~= nil then
            self:OnSelectReflash3DPlayerUI(self.MyRenderModeImg_Tb[location3dBarIndex] , location3dBarIndex , playerDataInfo.selectResID)
            self:OnSetSingle3dHeaderPlayerInfoUI(playerDataInfo , self.Player3dHeaderBar[location3dBarIndex])
            location3dBarIndex = location3dBarIndex + 1
        end
    end

    --- 开始到本机玩家位置起点位置前一位
    for i = 1, startIndex - 1 do
        local playerDataInfo = LUAPlayerDataMgr:GetMatchDataMgr():GetTeamPlayerInfoByIndex(i)
        if playerDataInfo ~= nil then
            self.Player3dHeaderBar[location3dBarIndex].Player3dHeaderName_Text:SetText(playerDataInfo.name)
            self:OnSelectReflash3DPlayerUI(self.MyRenderModeImg_Tb[location3dBarIndex] , location3dBarIndex , playerDataInfo.selectResID)
            self:OnSetSingle3dHeaderPlayerInfoUI(playerDataInfo , self.Player3dHeaderBar[location3dBarIndex])
            --dump(self.MyRenderModeImg_Tb[location3dBarIndex])
            location3dBarIndex = location3dBarIndex + 1
        end
    end
end

--- 选中职业时候，刷新UI展示槽位模型
--- posIndex 刷新位置
function UIChooseHero_C:OnSelectReflash3DPlayerUI(uiChooseHeroExhibition , posIndex , selectResID)

    if uiChooseHeroExhibition == nil or uiChooseHeroExhibition.RootWidget == nil then
        return
    end

    if posIndex <= 0 and posIndex > self.MaxPlayerInfoUIElement then
        print("Error posIndex in UIChooseHero:OnSelectReflash3DPlayerUI posIndex =" , posIndex)
        return
    end

    if selectResID <= 0 then
        uiChooseHeroExhibition.RootWidget:SetVisibility(UE4.ESlateVisibility.Hidden)
        return
    end

    local gameDesc = GameResMgr:GetGameResDataByResID("CharacterDesc_Res", selectResID)

    if gameDesc ~= nil then

        local bpFullPath = self:GetFullBPPath(gameDesc.ClassShowBPPath)
        local renderTarget2dPath = gameDesc.ClassShowRenderTargetPath

        --- 加载模型
        local spawnActor , imgBrushMat , NewtKey = self:OnLoadNewModels(selectResID,bpFullPath,renderTarget2dPath)

        --- 设置UI Brush
        if spawnActor ~= nil and imgBrushMat ~= nil then
            print("OnSelectReflash3DPlayerUI  spawnActor :" , spawnActor , "    imgBrushMat :" , imgBrushMat)
            --- 标记隐藏旧模型
            self:SetModelVisiablitiy(self.CurrModelKey[posIndex] , false)

            self.CurrModelKey[posIndex] = NewtKey

            --- 标记显示新模型
            self:SetModelVisiablitiy(self.CurrModelKey[posIndex] , true)

            uiChooseHeroExhibition:SetSelectedModel(spawnActor)

            --- MyRenderMode_Img 为蓝图上的控件
            if uiChooseHeroExhibition.MyRenderMode_Img ~= nil then

                UE4.UMGLuaUtils.UMG_Image_SetResource(uiChooseHeroExhibition.MyRenderMode_Img , imgBrushMat)

                uiChooseHeroExhibition.MyRenderMode_Img:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)

                --- 玩家没准备 ， 不显示其他玩家选择的模型 【posIndex 为玩家自己位置的模型】
                if not self.bReady and posIndex ~= 1 then
                    uiChooseHeroExhibition:SetVisibility(UE4.ESlateVisibility.Hidden)
                else
                    uiChooseHeroExhibition:SetVisibility(UE4.ESlateVisibility.Visible)
                end

            end
        end

    else

        if uiChooseHeroExhibition.ExhibitionImg ~= nil then
            uiChooseHeroExhibition.ExhibitionImg:SetVisibility(UE4.ESlateVisibility.Hidden)
            uiChooseHeroExhibition.RootWidget:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end
end

--- 隐藏模型
function UIChooseHero_C:SetModelVisiablitiy(tkey ,bShow)

    for i = 1, #self.Hero3DModelCache do
        if self.Hero3DModelCache[i].tkey == tkey then
            local spawnActor = self.Hero3DModelCache[i].spawnActor;
            if spawnActor ~= nil then
                --spawnActor:SetActorHiddenInGame(bShow)
                self.Hero3DModelCache[i].bShow = bShow
            end
        end
    end
end

--- 设置单个3d展示头像上方信息 UI
function UIChooseHero_C:OnSetSingle3dHeaderPlayerInfoUI(playerDataInfo , playerInfoTbElement)
    --- playerInfoTbElement 为 Player3dHeaderBar
    if playerDataInfo ~= nil and playerInfoTbElement ~= nil then

        playerInfoTbElement.Player3dHeaderName_Text:SetText(playerDataInfo.name)

        local playerGender = playerDataInfo.gender
        if playerGender == 1 then
            playerInfoTbElement.PlayerGenderMale:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            playerInfoTbElement.PlayerGenderFemale:SetVisibility(UE4.ESlateVisibility.Hidden)
        else
            playerInfoTbElement.PlayerGenderMale:SetVisibility(UE4.ESlateVisibility.Hidden)
            playerInfoTbElement.PlayerGenderFemale:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end

        local selectResID = playerDataInfo.selectResID
        if selectResID <= 0 then
            return
        end

        local gameDesc = GameResMgr:GetGameResDataByResID("CharacterDesc_Res",selectResID)

        if gameDesc ~= nil then
            playerInfoTbElement.PlayerClassType:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            UE4.UMGLuaUtils.UMG_Image_SetBrush(playerInfoTbElement.PlayerClassType , gameDesc.ClassIconPath)
        else
            playerInfoTbElement.PlayerClassType:SetVisibility(UE4.ESlateVisibility.Hidden)
            print("Can not Find selectResID = " , selectResID , "   playerDataInfo:GetPlayerName() = " , playerDataInfo:GetPlayerName())
        end

        --self.Player3dHeaderBar[i].Player3dHeader_Cvs:SetVisibility(UEnums.ESlateVisibility.Visible)
        local myPlayerID = LUAPlayerDataMgr:GetPlayerID()
        --- 玩家没准备不显示其他玩家的
        if not self.bReady and myPlayerID ~= playerDataInfo.uid then
            playerInfoTbElement.Player3dHeader_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden)
        else
            playerInfoTbElement.Player3dHeader_Cvs:SetVisibility(UE4.ESlateVisibility.Visible)
        end
    end
end

--- 刷新玩家信息卡片UI
function UIChooseHero_C:OnReflashPlayerInfoUI()

    local PlayerCtn = LUAPlayerDataMgr:GetMatchDataMgr():GetTeamPlayerInfoCtn()

    for i = 1,PlayerCtn do
        local playerDataInfo = LUAPlayerDataMgr:GetMatchDataMgr():GetTeamPlayerInfoByIndex(i)
        if (playerDataInfo ~= nil) then
            if self.PlayerInfo_Tb[i].bShow then
                self:OnSetSinglePlayerInfoUI(playerDataInfo , self.PlayerInfo_Tb[i])
            end
        else
            print("playerDataInfo is nil .")
        end
    end
end

--- 设置单个玩家卡牌
function UIChooseHero_C:OnSetSinglePlayerInfoUI(playerDataInfo , playerInfoTbElement)
    --- playerInfoTbElement 为 PlayerInfo_Tb中的元素
    if playerDataInfo ~= nil and playerInfoTbElement ~= nil then

        playerInfoTbElement.PlayerName_Text:SetText(playerDataInfo.name)

        local playerGender = playerDataInfo.gender
        if playerGender == 1 then
            playerInfoTbElement.Male_Img:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
            playerInfoTbElement.Female_Img:SetVisibility(UE4.ESlateVisibility.Hidden)
        else
            playerInfoTbElement.Male_Img:SetVisibility(UE4.ESlateVisibility.Hidden)
            playerInfoTbElement.Female_Img:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
        end

        local selectResID = playerDataInfo.selectResID

        if selectResID > 0 then
            local gameDesc = GameResMgr:GetGameResDataByResID("CharacterDesc_Res", selectResID)

            if gameDesc ~= nil then
                playerInfoTbElement.ClassTypeIcon:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
                UE4.UMGLuaUtils.UMG_Image_SetBrush(playerInfoTbElement.ClassTypeIcon , gameDesc.ClassIconPath)
            else
                playerInfoTbElement.ClassTypeIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
                print("1.Can not Find selectResID = " , selectResID , "   playerDataInfo:GetPlayerName() = " , playerDataInfo:GetPlayerName())
            end
        else
            playerInfoTbElement.ClassTypeIcon:SetVisibility(UE4.ESlateVisibility.Hidden)
        end
    end
end

function UIChooseHero_C:OnLoadNewModels(resID , actorClassPath , renderTarget2dPath)

    --- 存在取未显示的优先取
    for i = 1, #self.Hero3DModelCache do
        if self.Hero3DModelCache[i].resID == resID and not self.Hero3DModelCache[i].bShow then
            local spawnActor = self.Hero3DModelCache[i].spawnActor;
            local cacheRenderTarget2d = self.Hero3DModelCache[i].renderTarget2d;

            if cacheRenderTarget2d ~= nil then
                self.Hero3DModelCache[i].ShowMat:SetTextureParameterValue("RTargetTexture" , cacheRenderTarget2d)
            end

            return spawnActor , self.Hero3DModelCache[i].ShowMat,self.Hero3DModelCache[i].tkey
        end
    end

    local spawnActor = nil

    --- 没有时候，创建新的 actorClassPath
    --print("actorClassPath :" , actorClassPath)
    local actorClass = UE4.UClass.Load(actorClassPath)

    local uworld = self:GetWorld()
    if uworld == nil then
        print("UIChooseHero:OnLoadNewModels() UWorld is nil .")
        return nil , nil , nil
    end

    ---- 场景外一个位置，天空盒以外的地方
    local randX = 10000000

    local rotation = UE4.FQuat()
    local p = UE4.FVector(randX , 0 , #self.Hero3DModelCache * 500)

    local newFTransform = UE4.FTransform(rotation , p)

    spawnActor = uworld:SpawnActor(actorClass , newFTransform , nil , nil)

    if(spawnActor == nil) then
        print("UIChooseHero:OnLoadNewModels() spawnActor is nil .")
        return nil , nil , nil
    end

    local renderTarget2d = spawnActor.RTarget

    local newMat = UE4.UMGLuaUtils.UMG_GetMaterial("Material'/Game/UI/ChooseHero/ChooseExhibition_Mat.ChooseExhibition_Mat'" , self.RootWidget);
    if renderTarget2d ~= nil then
        newMat:SetTextureParameterValue("RTargetTexture" , renderTarget2d)
    else
        print("renderTarget2d Can not find Path : " , renderTarget2dPath)
    end


    local newModelTb = {}
    --- tkey 用于定位关闭模型
    newModelTb.tkey = os.time()
    newModelTb.resID = resID
    newModelTb.bShow = false
    newModelTb.spawnActor = spawnActor
    newModelTb.renderTarget2d = renderTarget2d
    newModelTb.ShowMat = newMat
    table.insert(self.Hero3DModelCache , newModelTb)
    return spawnActor , newModelTb.ShowMat , newModelTb.tkey
end

function UIChooseHero_C:OnChangeSelectChangeClassType()
    print("UIMsgDefine.UI_SYSTEM_MATCH_SELECT_CLASS  UIChooseHero:OnChangeSelectChangeClassType ...")

    self:OnReflashPlayerInfoUI()

    self:OnReflash3DPlayerHeaderInfoAndModel()

    self:OnReflashClassTypeUI()
end

function UIChooseHero_C:OnShowEnterBattleCD(CountDown)

    --- 进入自动完成准备 ， 开始进入战斗倒计时
    local uworld = self:GetWorld()
    if uworld == nil then
        return
    end

    --self.CDStartTime = uworld:GetTimeSeconds()
    self.CDStartTime = UE4.UGameplayStatics.GetTimeSeconds(self)
    self.bStart = true
    self.currTimeSecLen = CountDown
    self.bReady = true

    --print("self.CurrSelectResID :" , self.CurrSelectResID)
    self:OnReflash3DPlayerHeaderInfoAndModel()

    self:OnChangeState(UIMatchBattleTypeEnums.ChooseHeroState.Selected)
end

function UIChooseHero_C:OnS2cMatchReadyNotify(readyPlayerId)

    local myPlayerID = LUAPlayerDataMgr:GetPlayerID()
    if readyPlayerId == myPlayerID then
        self:OnChangeState(UIMatchBattleTypeEnums.ChooseHeroState.Selected)
    end

    self:OnReflash3DPlayerHeaderInfoAndModel()

    self:OnReflashPlayerInfoUI()
end

function UIChooseHero_C:OnS2cMatchReadyRsp()

    self.bReady = true

    self:OnChangeState(UIMatchBattleTypeEnums.ChooseHeroState.Selected)

    self:OnReflash3DPlayerHeaderInfoAndModel()
    --self:OnReflashPlayerInfoUI()
end

function UIChooseHero_C:OnReflashClassTypeUI()

    --- 职业页签高亮
    for i = 1, #self.PlayerClass_Tb do
        if self.PlayerClass_Tb[i] ~= nil then
            if self.PlayerClass_Tb[i].bShow then

                if(self.PlayerClass_Tb[i].bSelect) then
                    self.PlayerClass_Tb[i].PlayerClassHL_Img:SetVisibility(UE4.ESlateVisibility.SelfHitTestInvisible)
                else
                    self.PlayerClass_Tb[i].PlayerClassHL_Img:SetVisibility(UE4.ESlateVisibility.Hidden)
                end
            end
        end
    end
end

function UIChooseHero_C:GetFullBPPath(descPath)

    local spiltPath = self:PathSplit(descPath , "/")

    local tbLen = #spiltPath
    if tbLen  < 0 then
        return ""
    end

    if spiltPath[tbLen] ~= nil then
        local BPName = spiltPath[tbLen]

        --return "Blueprint'/Game/" .. descPath .. "." .. BPName .."'"
        return "/Game/" .. descPath .. "." .. BPName
    end

    return ""
end

function UIChooseHero_C:PathSplit(inputstr, sep)

    if sep == nil then
        sep = "%s"
    end

    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end

    return t
end


return UIChooseHero_C
