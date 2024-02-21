--[[--
    sdk fb好友数据
--]]
local FBFriendInfoData = require("GameModule.FBFriend.model.FBFriendInfoData")
local BaseGameModel = require("GameBase.BaseGameModel")
local FBFriendData = class("FBFriendData", BaseGameModel)

function FBFriendData:ctor()
    self:setRefName(G_REF.FBFriend)
end

function FBFriendData:parseData(_netData)
    self.p_FBFriendList = {}

    if _netData.data and #_netData.data > 0 then
        for i = 1, #_netData.data do
            local info = FBFriendInfoData:create()
            info:parseData(_netData.data[i])
            table.insert(self.p_FBFriendList, info)
        end
    end
    release_print("self.p_FBFriendList------------",#self.p_FBFriendList)
end

function FBFriendData:getFBFriendList()
    return self.p_FBFriendList
end

function FBFriendData:getFBFriendFBIds()
    local fbIdList = {}
    local list = self:getFBFriendList()
    if list and #list > 0 then
        for i = 1, #list do
            table.insert(fbIdList, list[i]:getFacebookId())
        end
    end
    return fbIdList
end

return FBFriendData
