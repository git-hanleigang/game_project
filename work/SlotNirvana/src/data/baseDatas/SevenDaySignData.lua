--[[
    author:{author}
    time:2019-04-18 21:53:40
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local SevenDaySignDayData = util_require("data.baseDatas.SevenDaySignDayData")
local SevenDaySignData = class("SevenDaySignData",BaseActivityData)

SevenDaySignData.p_days = nil
SevenDaySignData.p_collectDay = nil

--换皮主题名称
function SevenDaySignData:getTheme()
    return "Activity_7DaySign_ThanksGiving"
end

function SevenDaySignData:parseData(data,isNotPost)
    SevenDaySignData.super.parseData(self,data)
    self.p_days = {}
    for i=1,#data.days do
        local item = SevenDaySignDayData:create()
        item:parseData(data.days[i])
        self.p_days[i] = item
    end
    self.p_activityId = data.activityId
    self.p_collectDay = tonumber(data.collectDay)
end

-- CashBack Rank_6  Rank_9
function SevenDaySignData:getDayDataByDay(day)
    if day <= #self.p_days then
        return self.p_days[day]
    end
    return nil
end

function SevenDaySignData:checkIsCollectToday()
    if self.p_collectDay <= #self.p_days then
        local dayData = self.p_days[self.p_collectDay]
        if dayData then
            return dayData.p_collected
        end
    end
    --无数据返回已领取
    return true
end

function SevenDaySignData:getCollectDay()
    return self.p_collectDay
end


return SevenDaySignData