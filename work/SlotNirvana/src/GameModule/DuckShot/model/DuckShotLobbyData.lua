--[[
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local DuckShotLobbyData = class("DuckShotLobbyData", BaseActivityData)

function DuckShotLobbyData:ctor(_data)
    DuckShotLobbyData.super.ctor(self, _data)

    self.p_open = true
end

return DuckShotLobbyData
