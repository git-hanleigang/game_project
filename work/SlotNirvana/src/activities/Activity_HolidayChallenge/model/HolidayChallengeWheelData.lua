--[[
    转盘数据
]]
local ShopItem = require "data.baseDatas.ShopItem"
local HolidayChallengeWheelData = class("HolidayChallengeWheelData")

--[[
    message ChristmasTourWheel {
        optional int32 leftTimes = 1; //剩余次数
        optional int32 pointsNext = 2; //下一次转动需要的点数
        optional int32 pointsAll = 3; //总点数
        optional bool gameEnd = 4; //游戏结束
        repeated ChristmasTourWheelReward rewards = 5; //奖励列表
        optional string wheelType = 6; //转盘类型 Free Pay 两种类型
        optional bool activatePay = 7; //激活付费
        optional ChristmasTourSale wheelPay = 8; //转盘付费信息
        optional int32 payMaxTimes = 9; //转盘购买的最大次数
        optional int32 payWheelTimes = 10; //付费转盘购买的当前次数
    }
]]
function HolidayChallengeWheelData:ctor()
    self.m_leftTimes = 0 -- 剩余次数
    self.m_pointsNext = 0 -- 下一次转动需要的点数
    self.m_pointsAll = 0 -- 总点数
    self.m_gameEnd = false -- 游戏结束
    self.m_rewards = {} -- 奖励列表
    self.m_wheelType = "" -- 转盘类型
    self.m_activatePay = false -- 激活付费
    self.m_wheelPay = {}
    self.m_jcakpotCoins = 0
    self.m_payMaxTimes = 0 --转盘购买的最大次数
    self.m_payWheelTimes = 0 --付费转盘购买的当前次数
end

function HolidayChallengeWheelData:parseData(data)
    if not data then
        return
    end

    self.m_leftTimes = data.leftTimes
    self.m_pointsNext = data.pointsNext
    self.m_pointsAll = data.pointsAll
    self.m_gameEnd = data.gameEnd
    self.m_rewards = self:parseRewards(data.rewards)
    self.m_wheelType = data.wheelType
    self.m_activatePay = data.activatePay
    self.m_wheelPay = self:parseWheelPay(data.wheelPay)
    self.m_payMaxTimes = data.payMaxTimes --转盘购买的最大次数
    self.m_payWheelTimes = data.payWheelTimes --付费转盘购买的当前次数
    self:parseJackpotCoins()
    G_GetMgr(ACTIVITY_REF.HolidayChallenge):setSpinLeft(self.m_leftTimes, self.m_pointsNext)
end

-- message ChristmasTourWheelReward {
--     optional int64 coins = 1;      //金币奖励
--     repeated ShopItem items = 2;//物品奖励
--     optional bool collect = 3;//领取标识
--     optional int32 specialMark = 4;//特殊奖励标记
--   }
function HolidayChallengeWheelData:parseRewards(_rewards)
    if not _rewards then
        return
    end

    local rewards = {}
    if _rewards and #_rewards > 0 then
        for i, v in ipairs(_rewards) do
            local info = {}
            info.m_collect = v.collect
            info.m_specialMark = v.specialMark
            info.m_coins = tonumber(v.coins)
            info.m_items = self:parseItems(v.items)
            table.insert(rewards, info)
        end
    end
    return rewards
end

--[[
    message ChristmasTourSale {
        optional bool pay = 1;
        optional string key = 12; //付费Key
        optional string keyId = 13; //付费标识
        optional string price = 14; //价格
        optional string discount = 15; //折扣
    }
]]
function HolidayChallengeWheelData:parseWheelPay(_data)
    if not _data then
        return
    end

    local info = {}
    if _data then
        info.m_pay = _data.pay
        info.m_key = _data.key
        info.m_keyId = _data.keyId
        info.m_price = _data.price
        info.m_discount = _data.discount
    end
    return info
end

function HolidayChallengeWheelData:parseItems(_items)
    -- 通用道具
    local itemsData = {}
    if _items and #_items > 0 then
        for i, v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

function HolidayChallengeWheelData:parseJackpotCoins()
    local rewards = self:getRewards()
    for i = #rewards, 1, -1 do
        local reward = rewards[i]
        if reward.m_specialMark == 1 then
            self.m_jcakpotCoins = reward.m_coins or 0
            break
        end
    end
end

function HolidayChallengeWheelData:getJackpotCoins()
    return self.m_jcakpotCoins
end

function HolidayChallengeWheelData:getSpinLeft()
    return self.m_leftTimes
end

function HolidayChallengeWheelData:getPointsNext()
    return self.m_pointsNext
end

function HolidayChallengeWheelData:getAllPoints()
    return self.m_pointsAll
end

function HolidayChallengeWheelData:getGameEnd()
    return self.m_gameEnd
end

function HolidayChallengeWheelData:getRewards()
    return self.m_rewards
end

function HolidayChallengeWheelData:getWheelType()
    return self.m_wheelType
end

function HolidayChallengeWheelData:getActivatePay()
    return self.m_activatePay
end

function HolidayChallengeWheelData:getWheelPay()
    return self.m_wheelPay
end

-- 免费转盘是否完成
function HolidayChallengeWheelData:getWheelIsComplete()
    local isComplete = true
    local rewards = self:getRewards()
    for i = 1, #rewards do
        local reward = rewards[i]
        if not reward.m_collect then
            return false
        end
    end
    return isComplete
end

function HolidayChallengeWheelData:isWheelTypePay()
    local wheelType = self:getWheelType()
    return wheelType == "Pay"
end

-- 得到转盘上剩下的索引
function HolidayChallengeWheelData:getWheelLeftIndexList()
    local indexList = {}
    local rewards = self:getRewards()
    for i = 1, #rewards do
        local reward = rewards[i]
        if not reward.m_collect then
            table.insert(indexList, i)
        end
    end
    return indexList
end

-- 判断轮盘是否还可以付费
function HolidayChallengeWheelData:isWheelCanPay()
    return self.m_payWheelTimes <= self.m_payMaxTimes
end

return HolidayChallengeWheelData
