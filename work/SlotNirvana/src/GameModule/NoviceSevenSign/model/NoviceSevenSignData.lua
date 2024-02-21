--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-09-19 17:24:02
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-09-19 17:32:02
FilePath: /SlotNirvana/src/GameModule/NoviceSevenSign/model/NoviceSevenSignData.lua
Description: 新手期 7日签到V2 数据
--]]
local SignDayData = class("SignDayData")
local NoviceSevenSignConfig = util_require("GameModule.NoviceSevenSign.config.NoviceSevenSignConfig")
local ShopItem = util_require("data.baseDatas.ShopItem")

function SignDayData:ctor(_serverData)
    self._day = _serverData.day or 0 -- 第几天
    self._coins = tonumber(_serverData.coins) or 0 -- 支付相关
    self._multiple = tonumber(_serverData.multiple) or 0 -- 倍数
    -- 奖励物品
    self:parseItemList(_serverData.items or {}) 
    self._bCollect = _serverData.collect -- 是否领取
    self._startAt = tonumber(_serverData.startAt) or 0  -- 开始时间
    self._endAt = tonumber(_serverData.endAt) or 0  -- 结束时间
end

function SignDayData:parseItemList(_list)
    self._rewardList = {} -- 物品奖励
    if self._coins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self._coins, 6))
        table.insert(self._rewardList, itemData)
    end

    for k, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        table.insert(self._rewardList, shopItem)
    end
end

function SignDayData:getDay()
    return self._day
end
function SignDayData:getCoins()
    return self._coins
end
function SignDayData:getMultiple()
    return self._multiple
end
function SignDayData:getRewrdItemList()
    return self._rewardList
end
function SignDayData:checkHadCollected()
    return self._bCollect
end
function SignDayData:checkUnlock()
    local curTime = util_getCurrnetTime() * 1000
    if curTime >= self._startAt and curTime <= self._endAt then
        return true
    end

    return false
end
function SignDayData:checkMissed()
    local curTime = util_getCurrnetTime() * 1000
    return curTime > self._endAt
end
function SignDayData:getStatus()
    local status = NoviceSevenSignConfig.DAY_STATUS.LOCK
    if self:checkHadCollected() then
        status = NoviceSevenSignConfig.DAY_STATUS.COLLECTED
    elseif self:checkUnlock() then
        status = NoviceSevenSignConfig.DAY_STATUS.UNLOCK 
    end 

    return status
end


local BaseGameModel = util_require("GameBase.BaseGameModel")
local NoviceSevenSignData = class("NoviceSevenSignData", BaseGameModel)

-- message NoviceCheckV2 {
--     optional int64 activeAt = 1; // 激活时间
--     optional int64 expireAt = 2; // 功能过期时间
--     repeated NoviceCheckV2Reward rewards = 3; // 奖励
--   }
--   message NoviceCheckV2Reward {
--     optional int32 day = 1; //第几天
--     optional string coins = 2; //支付相关
--     optional string multiple = 3; //倍数
--     repeated ShopItem items = 4; //奖励物品
--     optional bool collect = 5; //第几天
--   }

function NoviceSevenSignData:ctor()
    NoviceSevenSignData.super.ctor(self)
    self._expireAt = 0
    self._dayList = {}
end

function NoviceSevenSignData:parseData(_data) 
    if not _data then
        return
    end
    
    NoviceSevenSignData.super.parseData(self)
    self._expireAt = tonumber(_data.expireAt) or 0 -- 功能过期时间
    self:parseDayDataList(_data.rewards or {})
end

-- 功能过期时间
function NoviceSevenSignData:getExpireAt()
    return self._expireAt
end

-- 每日 数据
function NoviceSevenSignData:parseDayDataList(_list)
    self._dayList = {}

    for _, _data in ipairs(_list) do
        local dayData = SignDayData:create(_data or {})
        local day = dayData:getDay()
        self._dayList[day] = dayData
    end
end
function NoviceSevenSignData:getDayList()
    return self._dayList
end
function NoviceSevenSignData:getDayData(_day)
    return self._dayList[_day]
end

function NoviceSevenSignData:isRunning()
    local leftTime = util_getLeftTime(self:getExpireAt())
    if leftTime < 0 then
        return false
    end

    return #self._dayList == 7
end

-- 是否可以签到
function NoviceSevenSignData:checkCanCollect()
    local bCanCollect = false
    for k, _data in pairs(self._dayList) do
        if _data:checkUnlock() and not _data:checkHadCollected() then
            bCanCollect = true
            break
        end
    end
    return bCanCollect
end

return NoviceSevenSignData