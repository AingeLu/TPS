

function s2c_login_rsp(RetCode , reason  , Data)
	-- NetMsgMgr.SendMsg("client.c2s_read_mail_req", {mail_id = 10000})

	GameLogicNetWorkMgr:GetGameLogicNetConnect():OnS2cLogicLoginRsp(RetCode , reason , Data)
end

function s2c_ping_rsp(PingTime)
	GameLogicNetWorkMgr:GetGameLogicNetConnect():OnS2cPingRsp(PingTime)
end


----------------------------------
--- 组队
----------------------------------

function s2c_team_enter_notify(info)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamEnterNotify(info)
end

function s2c_team_invite_rsp(ok , reason , uuid , state)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamInviteRsp(ok , reason , uuid , state)
end

function s2c_team_member_sync(type , team_id , player_num , leader_uuid , members , team_addr , aiConfigType)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamMemberSync(type , team_id , player_num , leader_uuid , members , team_addr , aiConfigType)
end

function s2c_team_answer_rsp(ok ,reason)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamAnswerRsp(ok ,reason)
end

function s2c_team_invite_ask(team_id , type , player_num , inviter , team_addr , from)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamInviteAsk(team_id , type , player_num , inviter , team_addr , from)
end

function s2c_team_invite_denied(uuid , lock_time , words , name)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamInviteDenied(uuid , lock_time , words , name)
end

function s2c_create_team_rsp(ok , reason)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cCreateTeamRsp(ok , reason)
end

function s2c_team_start_rsp(ok , reason)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cStartTeamRsp(ok , reason)
end

function s2c_team_quit_rsp(ok , reason)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamQuitRsp(ok , reason)
end

function s2c_team_leader_notify(uuid)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamLeaderNotify(uuid)
end

function s2c_team_quit_notify(uuid)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamQuitNotify(uuid)
end

function s2c_team_kick_rsp(ok , reason)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cTeamQuitNotify(ok , reason)
end

function s2c_rank_enqueue_notify(vs_mode ,multi_mode, mapid)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cRankEnqueueNotify(vs_mode ,multi_mode, mapid)
end

function s2c_rank_dequeue_notify(uuid)

	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cRankDequeueNotify(uuid)
end


function s2c_match_notify(RetCode,OwnLegion,CountDown,MapID,vs_mode,room_id)
    LUAPlayerDataMgr:GetMatchDataMgr():OnS2cMatchNotify(RetCode,OwnLegion,CountDown,MapID,vs_mode,room_id)
end

function s2c_choose_hero_rsp(ok , reason)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cChooseheroRsp(ok , reason)
end

function s2c_choose_hero_notify(player)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cChooseHeroNotify(player)
end

function s2c_match_ready_rsp(ok , reason)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cMatchReadyRsp(ok , reason)
end

function s2c_match_ready_notify(player)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cMatchReadyNotify(player)
end

function s2c_enter_battle_count_down(CountDown)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cEnterBattleCountDown(CountDown)
end

function s2c_start_load_map_notify(RoomID, BattleServerIP, BattleServerPort, Player_list, Token, MapID, BattleID, vs_mode, multi_mode)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cStartLoadMapNotify(RoomID, BattleServerIP, BattleServerPort, Player_list, Token, MapID, BattleID, vs_mode, multi_mode)
end

function s2c_fetch_custom_room_info_rsp(ok, reason, infos)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cFetchCustomRoomInfoRsp(ok, reason, infos)
end

function s2c_prepare_battle_rsp(ok ,reason)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cPrepareBattleRsp(ok ,reason)
end

function s2c_sync_custom_room_info(room_id, leader_uuid, members, map_id, mode, remainder)
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cSyncCustomRoomInfo(room_id, leader_uuid, members, map_id, mode, remainder)
end

function s2c_kick_custom_room_notify()
	LUAPlayerDataMgr:GetMatchDataMgr():OnS2cKickCustomRoomNotify()
end


----------------------------------
--- 好友
----------------------------------

function s2c_fetch_new_friends_info(new_friends)

	LUAPlayerDataMgr:GetFriendDataMgr():OnS2cFetchNewFriendInfo(new_friends)
end

function s2c_fetch_muti_friend_info(infos)

	LUAPlayerDataMgr:GetFriendDataMgr():OnS2cFetchMutiFriendInfo(infos)
end