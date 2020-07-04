if LUAFriendDataMgr ~= nil then
    return LUAFriendDataMgr
end


LUAFriendDataMgr = {}

-------------------------------------------
--- attributes
-------------------------------------------

--- 拉取新朋友uid数据
LUAFriendDataMgr.FetchNewFriendIds = nil
--- 拉取新朋友玩家信息数据
LUAFriendDataMgr.FetchMutiFriendInfos = nil

-------------------------------------------
--- C2S
-------------------------------------------

--- 拉取新朋友
function LUAFriendDataMgr:OnC2sFetchNewFriendInfo()
    GameLogicNetWorkMgr:SendMsg("client.c2s_fetch_new_friends_info" , {})
end

--- 获取一批好友信息
--- @param uids 玩家id列表
function LUAFriendDataMgr:OnC2sFetchMutiFriendInfo(uids)
    GameLogicNetWorkMgr:SendMsg("client.c2s_fetch_muti_friend_info" , {target_uuids = uids})
end



-------------------------------------------
--- S2C
-------------------------------------------

--- 拉取新朋友
--- @param new_friends 玩家uid列表
function LUAFriendDataMgr:OnS2cFetchNewFriendInfo(new_friends)

    LUAFriendDataMgr.FetchNewFriendIds = {}

    LUAFriendDataMgr.FetchNewFriendIds = new_friends

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_S2C_FETCH_NEW_FRIENDINFO , LUAFriendDataMgr.FetchNewFriendIds)
end

--- 拉取新朋友玩家信息数据
--- @param infos PlayerBasicInfo数据列表
function LUAFriendDataMgr:OnS2cFetchMutiFriendInfo(infos)

    LUAFriendDataMgr.FetchMutiFriendInfos = {}

    LUAFriendDataMgr.FetchMutiFriendInfos = infos

    LUIManager:PostMsg(Ds_UIMsgDefine.UI_S2C_FETCH_MUTI_FRIENDINFO , LUAFriendDataMgr.FetchMutiFriendInfos)
end


-------------------------------------------
--- functions
-------------------------------------------

function LUAFriendDataMgr:GetFetchNewFriendsIdList()
    return LUAFriendDataMgr.FetchNewFriendIds
end

function LUAFriendDataMgr:GetFetchMutiFriendsIdList()
    return LUAFriendDataMgr.FetchMutiFriendInfos
end

function LUAFriendDataMgr:OnInit()
    print("LUIPlayerDataMgr.Init succ")
end

function LUAFriendDataMgr:UnInit()
    print("LUIPlayerDataMgr.UnInit succ")
end

function LUAFriendDataMgr:Tick(deltaSeconds)

    for k, v in pairs(self.LuaClasses) do
        local bpClass = self.BPClasses[k];
        if bpClass ~= nil and type(v.Tick) == "function" then
            v:Tick(deltaSeconds)
        end
    end
end

return LUAFriendDataMgr