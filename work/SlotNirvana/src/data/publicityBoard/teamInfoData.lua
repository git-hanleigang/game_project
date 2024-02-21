--[[
    公会宣传活动
]]

local BaseActivityData = require("baseActivity.BaseActivityData")
local teamInfoData = class("teamInfoData",BaseActivityData)

function teamInfoData:ctor(_data)
    teamInfoData.super.ctor(self,_data)

    -- self.p_open = true
    self.p_open = globalData.constantData.CLAN_OPEN_SIGN
end

-- 是否忽略等级
function teamInfoData:isIgnoreLevel()
    return false
end

return teamInfoData
