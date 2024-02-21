--[[
]]
local ShopItem = util_require("data.baseDatas.ShopItem")

local BaseActivityData = require "baseActivity.BaseActivityData"
local ChristmasCalendarData = class("ChristmasCalendarData", BaseActivityData)

-- message ChristmasCalendarConfig {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     repeated ChristmasCalendarSignInInfo signInInfoList = 4;//签到信息
--     optional int32 stage = 5;//阶段
--     optional int64 coins = 6;//阶段奖励金币
--     repeated ShopItem itemList = 7;//阶段奖励物品
--     optional bool lastDay = 8;//是否最后一天
--     optional int32 currentDay = 9;//当前第几天
--     optional bool collect = 10;//最后一天是否领奖
--   }
function ChristmasCalendarData:parseData(data)
    ChristmasCalendarData.super.parseData(self, data)

    self.sign_data = self:parseSignData(data.signInInfoList)
    self.reward_stage = data.stage
    self.rewards = self:parseRewards(data)
    self.bl_isLastDay = data.lastDay
    self.currentDay = data.currentDay
    self.bl_collect = data.collect
    local today_data = self.sign_data[self.currentDay]
    if today_data and today_data.status == "INIT" then
        today_data.status = "SIGNING"
    end
    -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.ChristmasCalendar})
end

function ChristmasCalendarData:isRunning()
    local bl_running = ChristmasCalendarData.super.isRunning(self)
    return (bl_running and not self.bl_collect)
end

function ChristmasCalendarData:getLeftTime()
    if self.bl_collect then
        return 0
    end
    return ChristmasCalendarData.super.getLeftTime(self)
end

--   message ChristmasCalendarSignInInfo {
--     optional int32 day = 1;//天数
--     optional string status = 2;//状态 初始化 INIT,已签到 SIGNED_IN,未签到 NO_SIGN_IN 前端添加 SIGNING 签到
--   }
function ChristmasCalendarData:parseSignData(data)
    local sign_datas = {}
    if data and #data > 0 then
        for i, sign_info in ipairs(data) do
            if sign_info then
                local sign_data = {}
                sign_data.day = sign_info.day
                sign_data.status = sign_info.status

                sign_datas[i] = sign_data
            end
        end
    end
    return sign_datas
end

function ChristmasCalendarData:parseRewards(data)
    local rewards = {}
    rewards.coins = 0
    if data.coins then
        rewards.coins = tonumber(data.coins)
    end
    rewards.items = {}
    if data.itemList and #data.itemList > 0 then
        for i, item_data in ipairs(data.itemList) do
            local shopItem = ShopItem:create()
            shopItem:parseData(item_data, true)
            table.insert(rewards.items, shopItem)
        end
    end
    return rewards
end

function ChristmasCalendarData:getSignData()
    return self.sign_data
end

function ChristmasCalendarData:getRewardData()
    return self.rewards
end

function ChristmasCalendarData:getCurDay()
    return self.currentDay
end

function ChristmasCalendarData:isLastDay()
    return self.bl_isLastDay
end

function ChristmasCalendarData:getRewardState()
    return self.reward_stage
end

function ChristmasCalendarData:getTodayState()
    local cur_day = self:getCurDay()
    return self:getSignState(cur_day)
end

function ChristmasCalendarData:getSignState(day)
    local sign_data = self:getSignData()
    if sign_data[day] then
        return sign_data[day].status
    end
end

return ChristmasCalendarData
