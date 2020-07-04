if LUAMatchDataMgr ~= nil then
    return LUAMatchDataMgr
end

LUAMatchDataMgr = {}


function LUAMatchDataMgr:OnInit()
    print("LUIPlayerDataMgr.Init succ")


    ---------------------------
    --- 匹配流程相关
    ---------------------------
    self.InviterDataTb = nil
    --- 房间内队伍相关信息
    self.TeamDataTb = {}            --- 匹配流程玩家组队数据
    self.MatchTeamDataTb = {}       --- 现在英雄房间内数据
    self.PlayerSelectedLegionType = Ds_BattleActorType.ACTORTYPE_MAX

    self.bInCountDown = false
    self.bInMatchBattleType = false
    self.bInMatchCountDown = false


    ---------------------------
    --- 自定义开房间
    ---------------------------
    self.CustomRoomInfos = {}       --- 自定义房间数据信息
    self.CustomRoomData = {}        --- 自定义房间内的数据信息
end

function LUAMatchDataMgr:UnInit()
    print("LUIPlayerDataMgr.UnInit succ")
end

function LUAMatchDataMgr:Tick(deltaSeconds)

end


------------------------------------------------
--- Setter 设置数据接口
------------------------------------------------
function LUAMatchDataMgr:SetPlayerSelectedLegion(selectLegionType)
    self.PlayerSelectedLegionType = selectLegionType
end

function LUAMatchDataMgr:SetbInMatchBattleType(bInMatchBattleType)
    LUAMatchDataMgr.bInMatchBattleType = bInMatchBattleType
end

function LUAMatchDataMgr:SetbInEnterChooseHeroCountDown(bInChooseHeroCD)
    -- 进入匹配倒计时设置为true ， MatchNotify时候或者取消匹配时候设置为 false
    self.bInCountDown = bInChooseHeroCD
end


------------------------------------------------
--- Getter 获取数据接口
------------------------------------------------
function LUAMatchDataMgr:GetPlayerSelectedLegion()
    return self.PlayerSelectedLegionType
end

--- 【匹配】获取队伍中玩家的人数
function LUAMatchDataMgr:GetMatchTeamGroupPlayerCtn()
    return #LUAMatchDataMgr.TeamDataTb.members
end

--- 【匹配】获取队伍中玩家数据
function LUAMatchDataMgr:GetMatchTeamGroupPlayerMembers()
    return LUAMatchDataMgr.TeamDataTb.members
end

--- 【匹配】获取队伍 ID
function LUAMatchDataMgr:GetMatchTeamGroupID()
    return LUAMatchDataMgr.TeamDataTb.team_id
end

--- 【匹配】获取队长 ID
function LUAMatchDataMgr:GetMatchTeamGroupLeaderID()
    return LUAMatchDataMgr.TeamDataTb.leader_uuid
end

function LUAMatchDataMgr:GetbInMatchBattleType()
    return LUAMatchDataMgr.bInMatchBattleType
end

--- 【选择英雄】选择英雄房间玩家数量
function LUAMatchDataMgr:GetTeamPlayerInfoCtn()
    return #LUAMatchDataMgr.MatchTeamDataTb
end

--- 【选择英雄】选择英雄房间玩家数据
function LUAMatchDataMgr:GetTeamPlayerInfoByIndex(index)

    if index <= 0 or index > self:GetTeamPlayerInfoCtn() then
        return nil
    end

    return LUAMatchDataMgr.MatchTeamDataTb[index]
end

---【自定义房间】 获取自定义房间 ID
function LUAMatchDataMgr:GetCustomRoomID()
    dump(self.CustomRoomInfos)
    if self.CustomRoomInfos ~= nil and self.CustomRoomInfos.room_id ~= nil then
        return self.CustomRoomInfos.room_id
    end

    return 0
end

function LUAMatchDataMgr:GetCustomRoomRemainder()
    if self.CustomRoomInfos ~= nil and self.CustomRoomInfos.remainder ~= nil then
        return self.CustomRoomInfos.remainder
    end

    return 0
end

--- 【自定义房间】 获取拉取自定义房间的数量
function LUAMatchDataMgr:GetCustomRoomNum()
    if self.CustomRoomInfos == nil then
        return 0
    end

    return #self.CustomRoomInfos
end

--- 【自定义房间】 获取拉取自定义房间的数据
function LUAMatchDataMgr:GetCustomRoomInfoByIndex(index)

    if self.CustomRoomInfos == nil or #self.CustomRoomInfos <= 0 then
        return nil
    end

    if index <= 0 or index > #self.CustomRoomInfos then
        return nil
    end

    return self.CustomRoomInfos[index]
end

--- 【自定义房间】 获取自定义房间中人数
function LUAMatchDataMgr:GetCustomRoomPlayerCtn()

    if self.CustomRoomData == nil then
        return 0
    end

    if self.CustomRoomData.room_id ~= nil then
        if self.CustomRoomData.room_id > 0 then
            return #self.CustomRoomData.members
        else
            return 0
        end
    else
        return 0
    end
end

--- 【自定义房间】 获取自定义房间中某个玩家
function LUAMatchDataMgr:GetCustomRoomPlayerDataByIndex(index)

    if self.CustomRoomData ~= nil and self.CustomRoomData.members ~= nil then

        if index <= 0 or index > #self.CustomRoomData.members then
            return nil
        end

        return self.CustomRoomData.members[index]
    else
        return nil
    end
end

--- 【自定义房间】 获取自定义房间 ID 【单个房间内】
function LUAMatchDataMgr:GetCustomRoomID()

    if self.CustomRoomData ~= nil and self.CustomRoomData.room_id ~= nil then
        return self.CustomRoomData.room_id
    else
        return 0
    end
end


------------------------------------------------
--- 判断状态接口
------------------------------------------------

--- 【匹配流程】判断队伍是否是队长
function LUAMatchDataMgr:IsTeamLeader()

    local myPlayerID = LUAPlayerDataMgr:GetPlayerID()
    local leaderID = LUAPlayerDataMgr:GetMatchDataMgr():GetMatchTeamGroupLeaderID()

    if leaderID == nil then
        return false
    end

    if myPlayerID ~= leaderID then
        return false
    else
        return true
    end
end

--- 【匹配流程】判断是否玩家是否在队伍中
function LUAMatchDataMgr:IsInTeam()
    local teamid = LUAMatchDataMgr.TeamDataTb.team_id

    if teamid == nil then
        return false
    end

    if teamid > 0 then
        return true
    else
        return false
    end
end

function LUAMatchDataMgr:IsInEnterChooseHeroCD()
    return self.bInCountDown
end


-------------------------------------------
--- C2S 网络相关
-------------------------------------------
function LUAMatchDataMgr:OnC2sCreateTeamReq(aiConfigType , map_id)
    GameLogicNetWorkMgr:SendMsg("client.c2s_create_team_req" , {aiConfigType = aiConfigType ,map_id = map_id })
end

function LUAMatchDataMgr:OnC2sTeamQuitReq()
    GameLogicNetWorkMgr:SendMsg("client.c2s_team_quit_req" , {})
end

function LUAMatchDataMgr:OnC2sTeamStartReq(aiConfigType)
    print("c2s_team_start_req ... aiConfigType =" , aiConfigType)
    GameLogicNetWorkMgr:SendMsg("client.c2s_team_start_req" , {aiConfigType = aiConfigType})
end

--- 邀请玩家
function LUAMatchDataMgr:OnC2sTeamInviteReq(uid , from)
    GameLogicNetWorkMgr:SendMsg("client.c2s_team_invite_req" , {uuid = uid , from = from})
end

--- 邀请回答
function LUAMatchDataMgr:OnC2sTeamAnswerReq(team_id , inviter_uuid , accepted , lock_time , words , team_addr)
    GameLogicNetWorkMgr:SendMsg("client.c2s_team_answer_req" ,
            {
                team_id = team_id ,
                inviter_uuid = inviter_uuid ,
                accepted = accepted ,
                lock_time = lock_time ,
                words = words ,
                team_addr = team_addr })
end

--- 踢玩家出房间
function LUAMatchDataMgr:OnC2sTeamKickReq(uuid)
    GameLogicNetWorkMgr:SendMsg("client.c2s_team_kick_req" , {uuid = uuid})
end

--- 邀请同意
function LUAMatchDataMgr:OnTeamAccReq()

    local team_id = LUAMatchDataMgr.InviterDataTb.team_id
    local inviter_uuid = LUAMatchDataMgr.InviterDataTb.inviter.uuid
    local accepted = true
    local lock_time = 0
    local words = ""
    local team_addr = LUAMatchDataMgr.InviterDataTb.team_addr
    LUAMatchDataMgr:OnC2sTeamAnswerReq(team_id , inviter_uuid , accepted , lock_time , words , team_addr)
end

--- 邀请拒绝
function LUAMatchDataMgr:OnTeamRefusedReq()

    local team_id = LUAMatchDataMgr.InviterDataTb.team_id
    local inviter_uuid = LUAMatchDataMgr.InviterDataTb.inviter.uuid
    local accepted = false
    local lock_time = 0
    local words = ""
    local team_addr = LUAMatchDataMgr.InviterDataTb.team_addr
    LUAMatchDataMgr:OnC2sTeamAnswerReq(team_id , inviter_uuid , accepted , lock_time , words , team_addr)
end

--- 取消匹配
function LUAMatchDataMgr:OnC2sMatchCancelReq()
    GameLogicNetWorkMgr:SendMsg("client.c2s_match_cancel_req" , {uuid = uuid})
end

--- 选择职业
function LUAMatchDataMgr:OnLogicRoomChoseHeroReq(roleresid)
    GameLogicNetWorkMgr:SendMsg("client.c2s_choose_hero_req" , {roleresid = roleresid})
end

--- 准备战斗
function LUAMatchDataMgr:OnLogicMatchReadyReq(roleresid)
    GameLogicNetWorkMgr:SendMsg("client.c2s_match_ready_req" , {roleresid = roleresid})
end

--- 拉取房间信息 【自定义房间】
function LUAMatchDataMgr:OnC2sFetchCustomRoomInfoReq()
    GameLogicNetWorkMgr:SendMsg("client.c2s_fetch_custom_room_info_req" , {})
end

---  创建房间 【自定义房间】
function LUAMatchDataMgr:OnC2sPrepareBattleReq(vsMode , aiConfigType , map_id)
    GameLogicNetWorkMgr:SendMsg("client.c2s_prepare_battle_req" , {vsMode = vsMode, aiConfigType  = aiConfigType, map_id = map_id})
end

--- 开始游戏 【自定义房间】
function LUAMatchDataMgr:OnC2sStartCustomRoomReq(room_id , remainder)
    GameLogicNetWorkMgr:SendMsg("client.c2s_start_custom_room_req" , {room_id = room_id, remainder = remainder})
end

--- 离开房间 【自定义房间】
function LUAMatchDataMgr:OnC2sLeaveCustomRoomReq(room_id, remainder)
    GameLogicNetWorkMgr:SendMsg("client.c2s_leave_custom_room_req" , {room_id = room_id, remainder = remainder})
end

--- 踢出房间 【自定义房间】
function LUAMatchDataMgr:OnC2sKickCustomRoomReq(room_id , kick_pos , remainder)
    GameLogicNetWorkMgr:SendMsg("client.c2s_kick_custom_room_req" , {room_id = room_id , kick_pos = kick_pos, remainder = remainder})
end


-------------------------------------------
--- S2C 网络相关
-------------------------------------------
--- 创建队伍
function LUAMatchDataMgr:OnS2cCreateTeamRsp(ok , reason)

    if ok then
        LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_CREATE_TEAM)
    else
        print("LUAMatchDataMgr:OnS2cCreateTeamRsp reason : " , reason)
    end
end

--- 同步房主信息 (房主退出以后，更换房主)
function LUAMatchDataMgr:OnS2cTeamLeaderNotify(uuid)

    LUAMatchDataMgr.TeamDataTb.leader_uuid = uuid

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_SYCN_TEAMLEADER)
end

--- 退出队伍 (回包给自己的)
function LUAMatchDataMgr:OnS2cTeamQuitRsp(ok , reason)

end

--- 退出队伍通知 (通知别人的)
function LUAMatchDataMgr:S2cTeamQuitNotify(uuid)

end

function LUAMatchDataMgr:OnS2cStartTeamRsp(ok , reason)
    if ok then

    else
        print("LUAMatchDataMgr:OnS2cCreateTeamRsp reason : " , reason)
    end
end


function LUAMatchDataMgr:OnS2cRankEnqueueNotify(vs_mode ,multi_mode, mapid)

    --- 匹配计时开始
    LUIManager:ShowWindow("UIMatchReadyTips")

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_BEGIN_MATCH)

    LUAPlayerDataMgr:GetMatchDataMgr():SetbInEnterChooseHeroCountDown(true)
end

function LUAMatchDataMgr:OnS2cRankDequeueNotify(uuid)

    --- 匹配计时取消
    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_CANCEL)

    LUAPlayerDataMgr:GetMatchDataMgr():SetbInEnterChooseHeroCountDown(false)
end

--- 进入队伍通知 [通知房间内部的人的]
--- @param info TeamInfo
function LUAMatchDataMgr:OnS2cTeamEnterNotify(info)

    LUAMatchDataMgr.TeamDataTb.player_num = LUAMatchDataMgr.TeamDataTb.player_num + 1

    table.insert(LUAMatchDataMgr.TeamDataTb.members ,info )

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_ENTER_TEAM)
end

--- 队伍信息同步 [这个是进入房间时候会触发]
--- @param info TeamInfo
function LUAMatchDataMgr:OnS2cTeamMemberSync(type , team_id , player_num , leader_uuid , members , team_addr , aiConfigType)
    --- 清空数据
    LUAMatchDataMgr.TeamDataTb = {}

    ---- 初始化房间队伍数据
    LUAMatchDataMgr.TeamDataTb.type = type
    LUAMatchDataMgr.TeamDataTb.team_id = team_id
    LUAMatchDataMgr.TeamDataTb.player_num = player_num
    LUAMatchDataMgr.TeamDataTb.leader_uuid = leader_uuid
    LUAMatchDataMgr.TeamDataTb.members = members
    LUAMatchDataMgr.TeamDataTb.team_addr = team_addr
    LUAMatchDataMgr.TeamDataTb.aiConfigType = aiConfigType

    LUAPlayerDataMgr:GetMatchDataMgr():SetPlayerSelectedLegion(aiConfigType);

    ---- 非房主进入房间 , 需要界面打开跳到选人房间
    local isTeamLeader = self:IsTeamLeader()
    if not isTeamLeader then
        LUIManager:ShowWindow("UIMatchBattleType")

        LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_SYCN_ROOM_TEAM)
    end
end

--- 邀请玩家回包
function LUAMatchDataMgr:OnS2cTeamInviteRsp(ok , reason , uuid , state)

    if ok then
        print("OnS2cTeamInviteRsp Success ...")
    else
        print("LUAMatchDataMgr:OnS2cTeamInviteRsp reason :" , reason , "    uuid : " , uuid , " state :" , state)
    end
end

--- 邀请回答回包
function LUAMatchDataMgr:OnS2cTeamAnswerRsp(ok , reason)

    if ok then
        print("OnS2cTeamAnswerRsp Success ...")
    else
        print("LUAMatchDataMgr:OnS2cTeamAnswerRsp reason :" , reason)
    end
end

--- 接受到邀请
function LUAMatchDataMgr:OnS2cTeamInviteAsk(team_id , type , player_num , inviter , team_addr , from)

    LUAMatchDataMgr.InviterDataTb = {
        team_id = team_id ,
        type = type ,
        player_num = player_num ,
        inviter = inviter ,
        team_addr = team_addr ,
        from = from
    }

    local MessageBoxData = {}
    MessageBoxData.contentType = GetUIMessageBoxContentTypeEnums().CenterTextOnly
    MessageBoxData.btnType = GetUIMessageBoxBtnTypeEnums().SubmitAndCancel
    MessageBoxData.titleText = "邀请"
    MessageBoxData.descText = inviter.name .. "邀请你进入房间"
    MessageBoxData.bShowClose = false
    MessageBoxData.submitCallBack = LUAMatchDataMgr.OnTeamAccReq
    MessageBoxData.cancelCallBack = LUAMatchDataMgr.OnTeamRefusedReq
    LUIManager:ShowWindow("UIMessageBox" , MessageBoxData)
end

--- 邀请受到拒绝
function LUAMatchDataMgr:OnS2cTeamInviteDenied(uuid , lock_time , words , name)

end

--- 退出队伍通知
function LUAMatchDataMgr:OnS2cTeamQuitNotify(uuid)

    local isMeQuitTeam = false
    local myPlayerID = LUAPlayerDataMgr:GetPlayerID()
    if myPlayerID == uuid then
        LUAMatchDataMgr.TeamDataTb = {}
        isMeQuitTeam = true
    else
        for k, v in pairs(LUAMatchDataMgr.TeamDataTb.members) do
            if v ~= nil and v.uuid == uuid then
                table.remove(LUAMatchDataMgr.TeamDataTb.members, k)
            end
        end
        isMeQuitTeam = false
    end

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_QUIT_TEAM , isMeQuitTeam)
end

--- 踢出队伍
function LUAMatchDataMgr:OnS2cTeamKickRsp(ok , reason)

    if ok then
        print("LUAMatchDataMgr:OnS2cTeamKickRsp ...")
    else
        print("LUAMatchDataMgr:OnS2cTeamKickRsp reason : " , reason)
    end
end

function LUAMatchDataMgr:OnS2cMatchNotify(RetCode,OwnLegion,CountDown,MapID,vs_mode,room_id)

    self.MatchTeamDataTb = OwnLegion.PlayerList

    for i = 1, #self.MatchTeamDataTb do
        self.MatchTeamDataTb[i].selectResID = -1
        self.MatchTeamDataTb[i].bReady = false
    end

    LUIManager:ShowWindow("UIChooseHero")

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_CHOOSE_HERO)
end

function LUAMatchDataMgr:OnS2cChooseheroRsp(ok , reason)

    if ok then

    else
        print("LUAMatchDataMgr:OnS2cChooseheroRsp ... reason :" , reason)
    end
end

function LUAMatchDataMgr:OnS2cChooseHeroNotify(player)

    for i = 1, #self.MatchTeamDataTb do
        if self.MatchTeamDataTb[i].uid == player.uid then
            self.MatchTeamDataTb[i].selectResID = player.roleresid
        end
    end

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_SELECT_CLASS)
end

function LUAMatchDataMgr:OnS2cMatchReadyRsp(ok , reason)
    if ok then
        LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_READY_RSP)
    else
        print("LUAMatchDataMgr:OnS2cMatchReadyRsp failed . reason :" , reason)
    end
end

function LUAMatchDataMgr:OnS2cMatchReadyNotify(player)

    for i = 1, #self.MatchTeamDataTb do
        if self.MatchTeamDataTb[i].uid == player.uid then
            self.MatchTeamDataTb[i].bReady = true
            self.MatchTeamDataTb[i].selectResID = player.roleresid
        end
    end

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_MATCH_READY_NOTIFY , player.uid)
end

function LUAMatchDataMgr:OnS2cEnterBattleCountDown(CountDown)
    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_GAME_COUNT_DOWN , CountDown)
end

--- 加载进入战斗
function LUAMatchDataMgr:OnS2cStartLoadMapNotify(RoomID, BattleServerIP, BattleServerPort, Player_list, Token, MapID, BattleID, vs_mode, multi_mode)
    print("OnS2cStartLoadMapNotify ...")

    local uGameInstance = ShooterGameInstance
    if uGameInstance == nil then
        return
    end

    local uworld = uGameInstance:GetWorld()
    if uworld == nil then
        return
    end

    -----@type PlayerController
    local LocalPrimaryController = uGameInstance:GetFirstLocalPlayerController(uworld)
    if LocalPrimaryController ~= nil then
        uGameInstance:GotoState("Playing")

        local playerID = LUAPlayerDataMgr:GetPlayerID()
        local Url = BattleServerIP ..":".. BattleServerPort .."?playerId=".. playerID .."?key=1"
        print("OnS2cStartLoadMapNotify Url : " , Url)
        LocalPrimaryController:ClientTravel(Url, UE4.ETravelType.TRAVEL_Absolute);
    end

end

--- 拉取房间信息【自定义】
function LUAMatchDataMgr:OnS2cFetchCustomRoomInfoRsp(ok, reason, infos)

    if ok then

        --[[
            infos [房间信息数组]

            message CostomRoomBaseInfo
            {
                optional int32 room_id = 1;
                optional int32 remainder = 2;
                optional int32 leader_uuid = 3;
                optional int32 map_id = 4;
                optional string leader_name = 5;
            }

        ]]--

        self.CustomRoomInfos = {}
        self.CustomRoomInfos = infos

        LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_FETCH_CUSTEM_DATA)
    else
        print("LUAMatchDataMgr:OnS2cFetchCustomRoomInfoRsp ok == false . reason :" , reason)
    end

end

function LUAMatchDataMgr:OnS2cPrepareBattleRsp(ok ,reason)
    if ok then

    else
        print("LUAMatchDataMgr:OnS2cPrepareBattleRsp ok == false reason:" , reason)
    end
end

function LUAMatchDataMgr:OnS2cSyncCustomRoomInfo(room_id, leader_uuid, members, map_id, mode, remainder)

    --[[

    message S2cSyncCustomRoomInfo
    {
        optional int32 room_id = 1;
        optional int32 leader_uuid = 2;
        repeated CustomRoomMember members = 3;
        optional int32 map_id = 4;
        optional int32 mode = 5;
        optional int32 remainder = 6;
    }

    message CustomRoomMember
    {
        optional int32  uuid = 1;
        optional string name = 2;
    }

    ]]--

    self.CustomRoomData = {}
    if room_id > 0 then
        self.CustomRoomData.room_id = room_id
        self.CustomRoomData.leader_uuid = leader_uuid
        self.CustomRoomData.members = members
        self.CustomRoomData.map_id = map_id
        self.CustomRoomData.mode = mode
        self.CustomRoomData.remainder = remainder

        LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_CUSTEM_ROOM_DATA)
    end
end

function LUAMatchDataMgr:OnS2cKickCustomRoomNotify(room_id, leader_uuid, members, map_id, mode, remainder)

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_SYSTEM_KICK_CUSTEM_DATA)
end


return LUAMatchDataMgr