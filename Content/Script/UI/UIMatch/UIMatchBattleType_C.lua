require "UnLua"


local UIMatchBattleType_C = Class("UI/UICommon/BP_UISysBaseWidget_C")
local UIMatchBattleTypeEnums = require("UI/UIMatch/UIMatchBattleTypeEnums")

--- Friend List Child Node BP
local Friend_One_Info_BP = "/Game/UI/UIMatchBattleType/UIFriendOneInfoList"



function UIMatchBattleType_C:Initialize(Initializer)
    self.Super.Initialize(Initializer)
    print("UIMatchBattleType_C Initialize ...")

    ------------------------------------------------
    ----- 数据
    ------------------------------------------------
    self.CurrentState = UIMatchBattleTypeEnums.MatchBattleTypeState.None
    self.LastState = UIMatchBattleTypeEnums.MatchBattleTypeState.None

    self.Lua_NewFriendsDataCache_Tb = {}
    self.Lua_NewFriendsSlotInfo = {}

    ----- 初始化 展示组队 队伍数据 和 UI 【目前只有两个位置】
    self.TeamGroupSlotTb = nil
end

function UIMatchBattleType_C:OnInitialized()
    self.Overridden.OnInitialized(self)

    ----------------------------------------------
    --- 注册事件
    ----------------------------------------------
    self.Back_Btn.OnClicked:Add(self, UIMatchBattleType_C.OnClicked_Back_Btn)
    self.HunterCamp_Btn.OnClicked:Add(self, UIMatchBattleType_C.OnClicked_HunterCamp_Btn)
    self.MonsterCamp_Btn.OnClicked:Add(self, UIMatchBattleType_C.OnClicked_MonsterCamp_Btn)
    self.Submit_Btn.OnClicked:Add(self, UIMatchBattleType_C.OnClicked_Submit_Btn)
    self.Cancel_Btn.OnClicked:Add(self, UIMatchBattleType_C.OnClicked_Cancel_Btn)
    self.InvitePlayer_Btn.OnClicked:Add(self, UIMatchBattleType_C.OnClicked_InvitePlayer_Btn)
    self.CancelInvite_Btn.OnClicked:Add(self, UIMatchBattleType_C.OnClicked_CancelInvite_Btn)


    --- 拉取好友
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_S2C_FETCH_MUTI_FRIENDINFO,
            function(...) self:OnS2sFetchMutiFriendInfo() end)

    --- 拉取新朋友
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_S2C_FETCH_NEW_FRIENDINFO,
            function(...) self:OnS2sFetchNewFriendsInfo(...) end)

    --- 创建队伍
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_SYSTEM_CREATE_TEAM,
            function(...) self:OnCreateTeam(...) end)

    --- 开始匹配
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_SYSTEM_BEGIN_MATCH,
            function(...) self:OnS2cBeginMatch(...) end)

    --- 取消匹配
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_SYSTEM_MATCH_CANCEL,
            function(...) self:OnCancelMatch(...) end)


    --- 进入队伍
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_SYSTEM_MATCH_ENTER_TEAM,
            function(...) self:OnMatchEnterTeam(...) end)

    --- 同步房间队伍信息
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_SYSTEM_MATCH_SYCN_ROOM_TEAM,
            function(...) self:OnMatchEnterTeam(...) end)

    --- 退出房间
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_SYSTEM_MATCH_QUIT_TEAM,
            function(...) self:OnMatchQuiteTeam(...) end)

    --- 邀请玩家
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_SYSTEM_MATCH_INVITE_PLAYER,
            function(...) self:OnMatchInvitePlayer(...) end)

    --- 队长更变
    LUIManager:RegisterMsg("UIMatchBattleType",Ds_UIMsgDefine.UI_SYSTEM_MATCH_SYCN_TEAMLEADER,
            function(...) self:OnSyncTeamLeader(...) end)
end

function UIMatchBattleType_C:PreConstruct(IsDesignTime)
    self.Super.PreConstruct(IsDesignTime)
end

function UIMatchBattleType_C:Construct()
    self.Super.Construct();

    self.TeamGroupSlotTb = {}
    for i = 1, 2 do
        self.TeamGroupSlotTb[i] = {}
        self.TeamGroupSlotTb[i] = self:GetWidgetFromName("MatchTeamSlot"..i)
    end
end

function UIMatchBattleType_C:Tick(MyGeometry, InDeltaTime)
    self.Super.Tick(MyGeometry, InDeltaTime)
end


function UIMatchBattleType_C:OnShowWindow()
    print("self.CurrentState : " , self.CurrentState)
    if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.None then
        self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp)
    end

    LUAPlayerDataMgr:GetMatchDataMgr():SetbInMatchBattleType(true)

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_ENTER_MATCH_BATTLETYPE)
end

------------------------------------------
--- UI Event Callback
------------------------------------------

--- 点击返回按钮
function UIMatchBattleType_C:OnClicked_Back_Btn()

    LUIManager:ShowWindow("UIMainEnterMain")

    --print("self:IsNeedClearMatchRoomState() :" , self:IsNeedClearMatchRoomState())
    --if self:IsNeedClearMatchRoomState() then
    --    LUIManager:DestroyUI("UIMatchBattleType")
    --end
end

--- 点击选择狩猎者阵营
function UIMatchBattleType_C:OnClicked_HunterCamp_Btn()
    if(self.CurrentState ~= UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp) then
        return
    end

    LUAPlayerDataMgr:GetMatchDataMgr():SetPlayerSelectedLegion(Ds_BattleActorType.ACTORTYPE_SHOOTER);

    local mapid = 1001
    local aiconfig = LUAPlayerDataMgr:GetMatchDataMgr():GetPlayerSelectedLegion();

    ----- 狩猎者建立队伍
    LUAPlayerDataMgr:GetMatchDataMgr():OnC2sCreateTeamReq(aiconfig , mapid)
end

--- 点击怪物按钮
function UIMatchBattleType_C:OnClicked_MonsterCamp_Btn()

    if(self.CurrentState ~= UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp) then
        return
    end

    print("OnClicked_MonsterCamp_Btn ...")

    self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.MonsterCampSelected)

    LUAPlayerDataMgr:GetMatchDataMgr():SetPlayerSelectedLegion(Ds_BattleActorType.ACTORTYPE_MONSTER);
end

--- 点击开始战斗
function UIMatchBattleType_C:OnClicked_Submit_Btn()

    local aiconfig = LUAPlayerDataMgr:GetMatchDataMgr():GetPlayerSelectedLegion();

    if aiconfig == Ds_BattleActorType.ACTORTYPE_SHOOTER then

        local isLeader = LUAPlayerDataMgr:GetMatchDataMgr():IsTeamLeader()
        print("isLeader :" , isLeader)
        if not isLeader then
            return
        end
    end

    --- 开始匹配
    LUAPlayerDataMgr:GetMatchDataMgr():OnC2sTeamStartReq(aiconfig)
end

--- 点击取消按钮
function UIMatchBattleType_C:OnClicked_Cancel_Btn()

    if(self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.MonsterCampSelected) then

        self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp)
    elseif(self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.HunterCampSelected) then

        self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp)
        --- 取消组队
        LUAPlayerDataMgr:GetMatchDataMgr():OnC2sTeamQuitReq()
    elseif(self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.InviteTeammate) then

    elseif(self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup) then

        --- 取消组队
        LUAPlayerDataMgr:GetMatchDataMgr():OnC2sTeamQuitReq()
    end

end

--- 点击邀请按钮
function UIMatchBattleType_C:OnClicked_InvitePlayer_Btn()

    if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.ReadyToPlay then
        return
    end

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_INVITE_PLAYER , false)

    LUAPlayerDataMgr:GetFriendDataMgr():OnC2sFetchNewFriendInfo()
end

--- 点击邀请的取消按钮
function UIMatchBattleType_C:OnClicked_CancelInvite_Btn()
    local teamCtn = LUAPlayerDataMgr:GetMatchDataMgr():GetMatchTeamGroupPlayerCtn()

    if teamCtn > 1 then
        --- 存在多个队友时候
        self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup)
    else
        self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.HunterCampSelected)
    end
end


------------------------------------------
--- UI Mgs Callback
------------------------------------------
function UIMatchBattleType_C:OnCreateTeam()

    self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.HunterCampSelected)

    LUAPlayerDataMgr:GetMatchDataMgr():SetPlayerSelectedLegion(Ds_BattleActorType.ACTORTYPE_SHOOTER);
end

function UIMatchBattleType_C:OnS2cBeginMatch()

    self:OnAllTeamSlotOpenMenuSwitch(false , false)

    self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.ReadyToPlay)
end

function UIMatchBattleType_C:OnCancelMatch()

    self:OnAllTeamSlotOpenMenuSwitch(true , false)

    self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp)
end

function UIMatchBattleType_C:OnMatchEnterTeam()
    self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup)
end

--- 控制组队槽位的菜单面板接口
function UIMatchBattleType_C:OnAllTeamSlotOpenMenuSwitch(bEnableOpenMenu , bOpenMenu)

    for i = 1, 2 do
        if self.TeamGroupSlotTb[i] then
            self.TeamGroupSlotTb[i]:SetOpenMenuSwitch(bEnableOpenMenu , bOpenMenu)
        end
    end
end

--- 退出队伍
function UIMatchBattleType_C:OnMatchQuiteTeam(isMeQuitTeam)

    self.IsMeQuitTeam = isMeQuitTeam

    if isMeQuitTeam then
        --- 自己退出队伍 ， 返回选择阵营
        self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp)
        self:OnReflashTeamSlots()
    else
        --- 别人退出 ， 刷新槽位
        self:OnReflashTeamSlots()
    end

    self.IsMeQuitTeam = false
end

function UIMatchBattleType_C:OnMatchInvitePlayer(isPlayerSlot)

    --- 拉取新朋友
    LUAPlayerDataMgr:GetFriendDataMgr():OnC2sFetchNewFriendInfo()
end

--- 队长更变
function UIMatchBattleType_C:OnSyncTeamLeader()
    self:OnReflashTeamSlots()

    self:OnReflashEnterBattleBtn()
end

function UIMatchBattleType_C:OnReflashTeamSlots()

    for i = 1, 2 do
        self.TeamGroupSlotTb[i]:OnShowWindow(i)
    end
end

function UIMatchBattleType_C:OnS2sFetchNewFriendsInfo(friendUids)

    if friendUids ~= nil then

        LUAPlayerDataMgr:GetFriendDataMgr():OnC2sFetchMutiFriendInfo(friendUids)
    end
end

function UIMatchBattleType_C:OnReflashEnterBattleBtn()

    if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.MonsterCampSelected then
        --- 怪物 进去可以开始游戏 [怪物无队伍]
        self.Submit_Btn:SetIsEnabled(true)
        return
    end

    local isLeader = LUAPlayerDataMgr:GetMatchDataMgr():IsTeamLeader()

    --- 狩猎者队长才能点开始游戏
    if not isLeader then
        self.Submit_Btn:SetIsEnabled(false)
    else
        self.Submit_Btn:SetIsEnabled(true)
    end
end

function UIMatchBattleType_C:OnS2sFetchMutiFriendInfo()

    self:OnReflashNewFriendsData()

    self:OnChangeState(UIMatchBattleTypeEnums.MatchBattleTypeState.InviteTeammate)
end

function UIMatchBattleType_C:OnReflashNewFriendsData()
    self.Lua_NewFriendsDataCache_Tb = {}

    local muitFriendsInfo = LUAPlayerDataMgr:GetFriendDataMgr():GetFetchMutiFriendsIdList()
    if muitFriendsInfo == nil then
        return
    end

    for k, v in pairs(muitFriendsInfo) do
        if v ~= nil then
            table.insert(self.Lua_NewFriendsDataCache_Tb , v)
        end
    end
end

------------------------------------------
--- 辅助函数
------------------------------------------

--- 界面状态转换
---- @param UIMatchBattleTypeEnums.MatchBattleTypeState
function UIMatchBattleType_C:OnChangeState(NextState)
    if(self.CurrentState == NextState) then
        return
    end

    self.LastState = self.CurrentState
    self.CurrentState = NextState

    self:OnReflashStateAnimation()

    self:OnReflashStateUI()
end

--- 动画状态转换刷新
function UIMatchBattleType_C:OnReflashStateAnimation()
    --- 状态过渡
    if self.LastState == UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp then

        if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.MonsterCampSelected then
            self:OnStartPlayAnimationFowardByIndex(3)
        elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.HunterCampSelected then
            self:OnStartPlayAnimationFowardByIndex(0)
        elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup then
            self:OnStartPlayAnimationFowardByIndex(2)
            --- 进入SelectCamp ReadyToInvite_Cvs 的 RenderOpacity 为 0 ，此时邀请进入到 TeamGroup 时候 ，防止 ReadyToInvite_Cvs 保持为 0
            self.ReadyToInvite_Cvs:SetRenderOpacity(1.0)
        end

    elseif self.LastState == UIMatchBattleTypeEnums.MatchBattleTypeState.MonsterCampSelected then

        if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.ReadyToPlay then

        elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp then
            self:OnStartPlayAnimationReverseByIndex(3)
        end

    elseif self.LastState == UIMatchBattleTypeEnums.MatchBattleTypeState.HunterCampSelected then

        if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.InviteTeammate then
            self:OnStartPlayAnimationReverseByIndex(2)
        elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp then
            --self:OnStartPlayAnimationReverseByIndex(1)

            self:OnStartPlayAnimationReverseByIndex(0)
            self:OnStartPlayAnimationReverseByIndex(3)
        end

    elseif self.LastState == UIMatchBattleTypeEnums.MatchBattleTypeState.InviteTeammate then

        if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.HunterCampSelected then

            self:OnStartPlayAnimationReverseByIndex(1)
        elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup then

            self:OnStartPlayAnimationFowardByIndex(2)
        end

    elseif self.LastState == UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup then

        if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.ReadyToPlay then

        elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.InviteTeammate then
            self:OnStartPlayAnimationReverseByIndex(2)
        elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp then

            if self.IsMeQuitTeam then
                self:OnStartPlayAnimationReverseByIndex(3)
                self:OnStartPlayAnimationReverseByIndex(0)
            end
        end

    elseif self.LastState == UIMatchBattleTypeEnums.MatchBattleTypeState.ReadyToPlay then

        if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup then

        elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp then
            self:OnStartPlayAnimationReverseByIndex(3)
            self:OnStartPlayAnimationReverseByIndex(0)
        end

    end
end

--- 界面 UI刷新
function UIMatchBattleType_C:OnReflashStateUI()
    if self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp then
        print("self.CurrentState => UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp")
        self:OnReflashUIToSelectCamp()
    elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.MonsterCampSelected then
        print("self.CurrentState => UIMatchBattleTypeEnums.MatchBattleTypeState.MonsterCampSelected")
        self:OnReflashUIMonsterCampSelected()
    elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.HunterCampSelected then
        print("self.CurrentState => UIMatchBattleTypeEnums.MatchBattleTypeState.HunterCampSelected")
        self:OnReflashUIHunterCampSelected()
    elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.InviteTeammate then
        print("self.CurrentState => UIMatchBattleTypeEnums.MatchBattleTypeState.InviteTeammate")
        self:OnReflashUIInviteTeammate()
    elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup then
        print("self.CurrentState => UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup")
        self:OnReflashTeamGroup()
    elseif self.CurrentState == UIMatchBattleTypeEnums.MatchBattleTypeState.ReadyToPlay then
        print("self.CurrentState => UIMatchBattleTypeEnums.MatchBattleTypeState.ReadyToPlay")
        self:OnReflashUIReadyToPlay()
    end
end

function UIMatchBattleType_C:OnReflashTeamGroup()
    if self.CurrentState ~= UIMatchBattleTypeEnums.MatchBattleTypeState.TeamGroup then
        return
    end

    self.Monster_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.BottomTips_Text:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.ReadyToInvite_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.Cancel_Btn:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.Submit_Btn:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.PlayerInviteList_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);

    self.PlayerTeamCreate_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Back_Btn:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Human_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Cancel_Btn:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Submit_Btn:SetVisibility(UE4.ESlateVisibility.Visible);

    self:OnReflashEnterBattleBtn()

    self:OnReflashTeamSlots()
end

function UIMatchBattleType_C:OnReflashUIReadyToPlay()
    if self.CurrentState ~= UIMatchBattleTypeEnums.MatchBattleTypeState.ReadyToPlay then
        return
    end

    self.Cancel_Btn:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.Submit_Btn:SetVisibility(UE4.ESlateVisibility.Hidden);

    self:OnReflashEnterBattleBtn()
end

function UIMatchBattleType_C:OnReflashUIToSelectCamp()

    if self.CurrentState ~= UIMatchBattleTypeEnums.MatchBattleTypeState.SelectCamp then
        return
    end

    self.ReadyToInvite_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.PlayerInviteList_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.PlayerTeamCreate_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.Submit_Btn:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.Cancel_Btn:SetVisibility(UE4.ESlateVisibility.Hidden);

    self.BottomTips_Text:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Back_Btn:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Human_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Monster_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);

    self:OnReflashEnterBattleBtn()
end

function UIMatchBattleType_C:OnReflashUIMonsterCampSelected()

    if self.CurrentState ~= UIMatchBattleTypeEnums.MatchBattleTypeState.MonsterCampSelected then
        return
    end

    self.ReadyToInvite_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.PlayerInviteList_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.PlayerTeamCreate_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.Human_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.BottomTips_Text:SetVisibility(UE4.ESlateVisibility.Hidden);

    self.Back_Btn:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Monster_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Cancel_Btn:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Submit_Btn:SetVisibility(UE4.ESlateVisibility.Visible);

    self:OnReflashEnterBattleBtn()
end

function UIMatchBattleType_C:OnReflashUIHunterCampSelected()

    if self.CurrentState ~= UIMatchBattleTypeEnums.MatchBattleTypeState.HunterCampSelected then
        return
    end

    self.PlayerInviteList_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.PlayerTeamCreate_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);

    self.Monster_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.BottomTips_Text:SetVisibility(UE4.ESlateVisibility.Hidden);

    self.Human_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Back_Btn:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Cancel_Btn:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Submit_Btn:SetVisibility(UE4.ESlateVisibility.Visible);
    self.ReadyToInvite_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);

    self:OnReflashEnterBattleBtn()
end

function UIMatchBattleType_C:OnReflashUIInviteTeammate()

    if self.CurrentState ~= UIMatchBattleTypeEnums.MatchBattleTypeState.InviteTeammate then
        return
    end

    self.PlayerTeamCreate_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);

    self.Monster_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.BottomTips_Text:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.ReadyToInvite_Cvs:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.Cancel_Btn:SetVisibility(UE4.ESlateVisibility.Hidden);
    self.Submit_Btn:SetVisibility(UE4.ESlateVisibility.Hidden);

    self.PlayerInviteList_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Back_Btn:SetVisibility(UE4.ESlateVisibility.Visible);
    self.Human_Cvs:SetVisibility(UE4.ESlateVisibility.Visible);

    self:OnReflashEnterBattleBtn()

    --- 显示玩家列表
    self:OnShowFriendScrollBox()
end

function UIMatchBattleType_C:OnShowFriendScrollBox()
    --- 根据 self.Lua_NewFriendsDataCache_Tb 数据进行显示
    if self.FriendsBox_WrapBox:HasAnyChildren() then
        self.Lua_NewFriendsSlotInfo = {}
        self.FriendsBox_WrapBox:ClearChildren()
    end

    for i = 1, #self.Lua_NewFriendsDataCache_Tb do

        local Widget = UE4.UWidgetBlueprintLibrary.Create(self, UE4.UClass.Load(Friend_One_Info_BP))
        if Widget ~= nil then

            self.Lua_NewFriendsSlotInfo[i] = Widget
            self.FriendsBox_WrapBox:AddChildToWrapBox(Widget)

            local func = self.Lua_NewFriendsSlotInfo[i].OnShowWindow;
            if(func ~= nil and type(func) == "function")then
                self.Lua_NewFriendsSlotInfo[i]:OnShowWindow(self.Lua_NewFriendsDataCache_Tb[i]);
            end
        end

        --local parts_ui = slua.loadUI(Friend_One_Info_BP);
        --if parts_ui then
        --    local UITable = require("Match/UIFriendOneInfoList")
        --    local luaClass = UITable:New()
        --    luaClass:OnAwake(parts_ui)
        --    self.Lua_NewFriendsSlotInfo[i] = luaClass;
        --
        --    self.FriendsBox_WrapBox:AddChildWrapBox(parts_ui)
        --
        --    local func = self.Lua_NewFriendsSlotInfo[i].OnShowWindow;
        --    if(func ~= nil and type(func) == "function")then
        --        self.Lua_NewFriendsSlotInfo[i]:OnShowWindow(parts_ui ,self.Lua_NewFriendsDataCache_Tb[i]);
        --    end
        --end
    end

end

---------------------------------------
--- 状态判断
---------------------------------------

--- 退出是否需要重置界面状态
function UIMatchBattleType_C:IsNeedClearMatchRoomState()

    --- 处于匹配倒计时
    local bInMatchCD = LUAPlayerDataMgr:GetMatchDataMgr():IsInEnterChooseHeroCD()

    if bInMatchCD then
        return false
    end

    local bInTeam = LUAPlayerDataMgr:GetMatchDataMgr():IsInTeam()
    if bInTeam then
        return false
    end

    return true
end


return UIMatchBattleType_C
