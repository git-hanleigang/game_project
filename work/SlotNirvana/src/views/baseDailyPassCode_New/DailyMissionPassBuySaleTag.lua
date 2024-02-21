--[[
    
]]
local DailyMissionPassBuySaleTag = class("DailyMissionPassBuySaleTag", util_require("base.BaseView"))

function DailyMissionPassBuySaleTag:getCsbName()
    return DAILYPASS_RES_PATH.BuySaleTag
end

function DailyMissionPassBuySaleTag:initUI(_discount)    
    DailyMissionPassBuySaleTag.super.initUI(self)

    local lb_off3 = self:findChild("lb_off3")
    lb_off3:setString("-" .. _discount .. "%")
end

function DailyMissionPassBuySaleTag:playStart()
    self:runCsbAction("start", false)
end

function DailyMissionPassBuySaleTag:playIdle2()
    self:runCsbAction("idle2", false)
end

return DailyMissionPassBuySaleTag