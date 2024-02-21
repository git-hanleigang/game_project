--[[
]]

local BaseInboxGroup = util_require("views.inbox.group.BaseInboxGroup")
local InboxGroup_miniGame = class("InboxGroup_miniGame", BaseInboxGroup)

function InboxGroup_miniGame:getCsbName()
    return "InBox/Group/InboxGroup_MiniGame.csb"
end

return InboxGroup_miniGame