--[[
]]
local BaseActivityData = require("baseActivity.BaseActivityData")
local FlowerLobbyData = class("FlowerLobbyData", BaseActivityData)

function FlowerLobbyData:ctor(_data)
    FlowerLobbyData.super.ctor(self, _data)

    self.p_open = true
end

return FlowerLobbyData
