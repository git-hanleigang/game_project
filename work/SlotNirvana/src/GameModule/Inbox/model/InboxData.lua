--[[
    todo:maqun 邮件数据处理
]]

local InboxCollectRunData = util_require("GameModule.Inbox.model.InboxCollectRunData")
local InboxFriendRunData = util_require("GameModule.Inbox.model.InboxFriendRunData")


local BaseGameModel = require("GameBase.BaseGameModel")
local InboxData = class("InboxData", BaseGameModel)

function InboxData:ctor()
    InboxData.super.ctor(self)
    self:setRefName(G_REF.Inbox)

    self.m_collectMailData = nil
    self.m_friendMailData = nil
end

function InboxData:parseCollectData(_netData)
    local data = InboxCollectRunData:create()
    data:parseData(_netData)
    self.m_collectMailData = data
end

function InboxData:parseFriendData(_netData)
    local data = InboxFriendRunData:create()
    data:parseData(_netData)
    self.m_friendMailData = data
end

function InboxData:getCollectData()
    return self.m_collectMailData
end

function InboxData:getFriendData()
    return self.m_friendMailData
end

return InboxData