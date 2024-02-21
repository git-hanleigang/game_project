--[[
    新手期每日签到 -- 数据
]]
-- FIX IOS 139 z
local ShopItem = util_require("data.baseDatas.ShopItem")
local DailyBonusNoviceData = class("DailyBonusNoviceData")

--[[
    message NoviceCheckConfig {
        repeated NoviceCheckReward rewards = 1;//新手期签到奖励
        optional int32 checkTimes = 2;//签到第几天
    }
   
    message NoviceCheckReward {
        optional int32 day = 1;//第几天
        optional int64 coins = 2;//金币
        repeated ShopItem item = 3; //物品奖励
        optional bool collect = 4;//是否领取
    }
]]

function DailyBonusNoviceData:ctor()
    self.m_hasData = false  --是否有签到数据
end

--签到数据解析
function DailyBonusNoviceData:parseData(_data)
    self.p_days = self:parseRewards(_data.rewards)
    self.p_day = _data.checkTimes

    if self.p_day and self.p_days and #self.p_days > 0 then 
        self:setDataFlag(true)
    else
        self:setDataFlag(false)
    end
end

function DailyBonusNoviceData:parseRewards(_data)
    local rewardList = {}
    for i,v in ipairs(_data) do
        local temp = {}
        temp.day = v.day
        temp.coins = tonumber(v.coins)
        temp.item = self:parseItem(v.item)
        temp.collect = v.collect
        table.insert(rewardList, temp)
    end
    return rewardList
end

function DailyBonusNoviceData:parseItem(_data)
    local itemList = {}
    for i, v in ipairs(_data) do
        local tempData = ShopItem:create()
        tempData:parseData(v)
        table.insert(itemList, tempData)
    end
    return itemList
end

--访问数据接口
function DailyBonusNoviceData:getDay()
    return self.p_day
end

function DailyBonusNoviceData:getDays()
    return self.p_days
end

--当天签到数据
function DailyBonusNoviceData:getOnThatDayData()
    return self.p_days[self.p_day]
end

--检查是否有数据
function DailyBonusNoviceData:checkHasData()
    if self.m_hasData and self.p_day and self.p_day > 0 and self.p_days[self.p_day] and self.p_days[self.p_day].collect == false then
        return true
    else
        return false
    end
end

--签到数据
function DailyBonusNoviceData:setDataFlag(_flag)
    self.m_hasData = _flag
end

function DailyBonusNoviceData:isHasData()
    return self.m_hasData
end

return DailyBonusNoviceData