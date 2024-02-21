--[[
    网络管理
    author: 徐袁
    time: 2021-03-02 15:07:56
]]
GD.NetType = {
    Common = "Common",
    Login = "Login",
    Spin = "Spin",
    Clan = "Clan",
    Lottery = "Lottery", --乐透
    Friend = "Friend" --好友
}

GD.NetLuaModule = {
    Common = "net.netModel.CommonNetModel",
    Login = "net.netModel.LoginNetModel",
    Activity = "net.netModel.ActivityNetModel",
    DeluxeMergeGame = "net.netModel.DeluxeMergeNetModel",
    Clan = "net.netModel.ClanNetModel",
    Lottery = "GameModule.Lottery.net.LotteryNetModel",
    Friend = "GameModule.Friend.net.FriendNet",
}

local NetModelMgr = class("NetModelMgr")

GD.G_GetNetModel = function(nType)
    return NetModelMgr:getInstance():getNet(nType)
end

function NetModelMgr:getInstance()
    if not self._instance then
        self._instance = NetModelMgr:create()
    end
    return self._instance
end

function NetModelMgr:ctor()
    -- 网络模型列表
    self.m_netModels = {}
end

-- 获得网络模型
function NetModelMgr:getNet(nType)
    nType = nType or ""
    if not self.m_netModels[nType] then
        local _lua = NetLuaModule[nType]
        if _lua then
            self.m_netModels[nType] = require(_lua):create()
        end
    end
    return self.m_netModels[nType]
end

-- 设置网络模型
function NetModelMgr:setNet(nType, module)
    if not nType or not module then
        return
    end
    self.m_netModels[nType] = module
end

return NetModelMgr
