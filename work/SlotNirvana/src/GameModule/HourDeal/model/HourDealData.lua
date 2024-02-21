--[[
    限时抽奖
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseGameModel = require("GameBase.BaseGameModel")
local HourDealData = class("HourDealData", BaseGameModel)

function HourDealData:ctor()
    HourDealData.super.ctor(self)

    self.p_openActivity = 0     -- 活动是否开启：1-登陆时未开启 2-登陆时以开启 3-游戏中开启 4-以弹过开启弹板
end

-- message HourDeal {
--     optional int32 openLevel = 1;//开启等级
--     optional bool unlock = 2;//是否解锁
--     optional int64 expireAt = 3;//实际到期时间
--     optional int64 showExpireAt = 4;//显示到期时间
--     optional int32 drawTimes = 5;//抽取次数
--     optional int64 jackpotCoins = 6;//jackpot奖金
--     repeated HourDealReward giftList = 7;//礼盒
--     repeated HourDealReward rewardList = 8;//两侧奖励
--     repeated HourDealSale timesSale = 9;//次数促销
--     optional HourDealSale extendedTimeSale = 10;//延时促销
--     optional int32 maxDrawTimes = 11;//最大可抽取次数
--     optional int32 triggerBatchNum = 12;//剩余宝箱数 > X，触发批量
--   }
function HourDealData:parseData(_data)
    self.p_openLevel = _data.openLevel
    self.p_unlock = _data.unlock
    self.p_expireAt = tonumber(_data.expireAt)
    self.p_showExpireAt = tonumber(_data.showExpireAt)
    self.p_drawTimes = _data.drawTimes
    self.p_jackpotCoins = tonumber(_data.jackpotCoins)
    self.p_maxDrawTimes = _data.maxDrawTimes
    self.p_triggerBatchNum = _data.triggerBatchNum
    self.p_giftList = self:paresRewardData(_data.giftList)
    self.p_rewardList = self:paresRewardData(_data.rewardList)
    self.p_timesSale = self:paresTimesSaleData(_data.timesSale)
    self.p_extendedTimeSale = self:paresExtendedSaleData(_data.extendedTimeSale)

    if self:isRunning() then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_DATA_UPDATE)
    end

    if self.p_openActivity == 0 then
        if self.p_unlock then
            self.p_openActivity = 2
        else
            self.p_openActivity = 1
        end
    elseif self.p_openActivity == 1 then
        if self:isRunning() then
            self.p_openActivity = 3
        end
    elseif self.p_openActivity == 3 then
        self.p_openActivity = 4
    end
end

-- message HourDealReward {
--     optional int32 index = 1;
--     optional int64 coins = 2;
--     repeated ShopItem items = 3;
--     optional bool grand = 4;//是否grand
--     optional bool extracted = 5;//是否抽取
--   }
function HourDealData:paresRewardData(_data)
    local giftList = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_coins = tonumber(v.coins)
            temp.p_grand = v.grand
            temp.p_extracted = v.extracted
            temp.p_items = self:parseItems(v.items)
            table.insert(giftList, temp)
        end
    end
    return giftList
end

function HourDealData:parseItems(_items)
    local itemsData = {}
    if _items and #_items > 0 then 
        for i,v in ipairs(_items) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(itemsData, tempData)
        end
    end
    return itemsData
end

-- message HourDealSale {
--     optional string key = 1;
--     optional string keyId = 2;
--     optional string price = 3;
--     optional int32 newTimes = 4;//新增次数
--     optional int32 extendedTime = 5;//延长的时间 （分钟）
--     optional int64 coins = 6;
--   }
function HourDealData:paresTimesSaleData(_data)
    local saleData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_key = v.key
            temp.p_keyId = v.keyId
            temp.p_price = v.price
            temp.p_newTimes = v.newTimes
            temp.p_extendedTime = v.extendedTime
            temp.p_coins = tonumber(v.coins)
            table.insert(saleData, temp)
        end
    end
    return saleData
end

function HourDealData:paresExtendedSaleData(_data)
    local saleData = {}
    if _data then 
        saleData.p_key = _data.key
        saleData.p_keyId = _data.keyId
        saleData.p_price = _data.price
        saleData.p_newTimes = _data.newTimes
        saleData.p_extendedTime = _data.extendedTime
        saleData.p_coins = tonumber(_data.coins)
    end
    return saleData
end

function HourDealData:parseSpinData(_spinData)
    if _spinData.unlock then
        self.p_openActivity = 3
        local data = cjson.decode(_spinData.data)
        self:parseData(data)
    elseif _spinData.drop then
        local drop = _spinData.drop
        self.p_newTimes = drop.newTimes
        self.p_drawTimes = drop.totalTimes
    end
end

function HourDealData:clearSpinData()
    self.p_newTimes = 0
end

function HourDealData:getNewTimes()
    return self.p_newTimes or 0
end

function HourDealData:getUnlock()
    return self.p_unlock
end

function HourDealData:getDrawTimes()
    return self.p_drawTimes or 0
end

function HourDealData:getJackpotCoins()
    return self.p_jackpotCoins or 0
end

function HourDealData:getGiftList()
    return self.p_giftList
end

function HourDealData:getRewardList()
    return self.p_rewardList
end

function HourDealData:getTimesSale()
    return self.p_timesSale
end

function HourDealData:getExtendSale()
    return self.p_extendedTimeSale
end

function HourDealData:getShowExpireAt()
    return (self.p_showExpireAt or 0) / 1000
end

function HourDealData:getExpireAt()
    return (self.p_expireAt or 0) / 1000
end

function HourDealData:isUnlock()
    return self.p_openActivity == 3
end

function HourDealData:getTriggerBatchNum()
    return self.p_triggerBatchNum
end

function HourDealData:isRunning()
    if not self.p_unlock then
        return false
    end

    if self:getExpireAt() <= 0 then
        return false
    end

    return self:getLeftTime() > 0
end

function HourDealData:getLeftTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function HourDealData:getLeftShowTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self:getShowExpireAt() - curTime
    leftTime = leftTime > 0 and leftTime or 0
    return leftTime
end

function HourDealData:getNoExtractCount()
    local count = 0
    for i,v in ipairs(self.p_giftList) do
        if not v.p_extracted then
            count = count + 1
        end
    end
    return count
end

function HourDealData:setOpenActivityStatus(_status)
    self.p_openActivity = _status
end

return HourDealData
