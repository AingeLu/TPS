

function OnConnected(PortNo)
    print("Login:OnConnected ...  PortNo : " , PortNo)

    GameLogicNetWorkMgr:GetGameLogicNetConnect():OnConnectedSuccess()
end

function OnClosed(PortNo)
    print("Login:OnClosed ...  PortNo : " , PortNo)
    GameLogicNetWorkMgr:GetGameLogicNetConnect():OnConnectedClose()
end

function OnConnectTimeOut()
   
end

function OnMsgDispatch(msg, sz)
    GameLogicNetWorkMgr:Dispatch(msg, sz)
end


