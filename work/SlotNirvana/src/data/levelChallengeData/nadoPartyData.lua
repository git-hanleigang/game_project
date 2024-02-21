--[[
    nadoParty  新关预热
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local nadoPartyData = class("nadoPartyData",BaseActivityData)


function nadoPartyData:ctor(_data)
    nadoPartyData.super.ctor(self,_data)

    self.p_open = true
end

return nadoPartyData
