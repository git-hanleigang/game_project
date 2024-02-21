--[[
    促销券
    author:{author}
    time:2020-07-21 10:52:08
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local LevelBoomData = class("LevelBoomData", BaseActivityData)

function LevelBoomData:parseData(data)
    LevelBoomData.super.parseData(self, data)
    self.p_expire = data.expire
    self.p_expireAt = tonumber(data.expireAt)
    self.p_activityId = data.id
end

return LevelBoomData
