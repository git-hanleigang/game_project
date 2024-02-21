--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2020-11-26 18:23:17
]]
-- FIX IOS 139 z
local ShopItem = util_require("data.baseDatas.ShopItem")
local DailySignData = class("DailySignData")

DailySignData.p_day = nil  --当前签到天数
DailySignData.p_days = nil  --7天数据
DailySignData.p_point = nil  --累计签到数
DailySignData.p_rewards = nil  --累计奖励
DailySignData.p_begin = nil  --开始日前

function DailySignData:ctor()
    self.m_hasData = false  --是否有签到数据
end
--签到数据解析
function DailySignData:parseData(_data)
    self.p_day = _data.day
    self.p_days = _data.days
    self.p_points = _data.points
    self.p_rewards = _data.rewards
    self.p_begin = _data.begin

    if self.p_day and self.p_days and self.p_points and self.p_rewards  then 
        self:setDataFlag(true)
    end
    self:parseRewardData()
end
--访问数据接口
function DailySignData:getDay()
    return self.p_day
end

function DailySignData:getDays()
    return self.p_days
end

function DailySignData:getPoint()
    return self.p_points
end

function DailySignData:getRewards()
    return self.p_rewards
end

function DailySignData:getRewardsCount()
    return #self.p_rewards
end

function DailySignData:getDaysRewardsPoints(_day)
    return self.p_rewards[_day].points
end

function DailySignData:getRewardDay()
    for i=1,#self.p_rewards do
        if not self.p_rewards[i].collected then
            return i 
        end
    end

    return #self.p_rewards
end

function DailySignData:getBegin()
    return self.p_begin
end
--当天签到数据
function DailySignData:getOnThatDayData()
    return self.p_days[self.p_day]
end
--检查是否有数据
function DailySignData:checkHasData()
    if self.m_hasData and self.p_days and self.p_day and self.p_day ~= 0 and self.p_days[self.p_day].collected == false then
        return true
    else
        return false
    end
end
--签到完成
function DailySignData:setDataFlag(_flag)
    self.m_hasData = _flag
end

--签到奖励解析
function DailySignData:parseRewardData()
    self.m_rewardsList = {}
    for i, v in ipairs(self.p_days) do
        local rewardsData = v.items1
        self.m_rewardsList[i] = rewardsData
    end
end

--处理后的签到奖励
function DailySignData:getRewardList(_index)
    local rewardsData = self.m_rewardsList[_index]
    local m_rewardsList = {}
    for i, v in ipairs(rewardsData) do
        local tempData = ShopItem:create()
        tempData:parseData(v)
        table.insert(m_rewardsList, tempData)
    end

    return m_rewardsList
end
return DailySignData

