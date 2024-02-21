--[[
    限时集卡多倍奖励
]]

local ShopItem = require "data.baseDatas.ShopItem"
local BaseActivityData = require("baseActivity.BaseActivityData")
local AlbumMoreAwardData = class("AlbumMoreAwardData",BaseActivityData)

-- message AlbumMoreAward {
--     optional string activityId = 1; //活动id
--     optional int64 expireAt = 2; //过期时间
--     optional int32 expire = 3; //剩余秒数
--     optional string multiply = 4;//倍数
--     repeated AlbumMoreAwardSaleList saleList = 5;//促销
--     optional bool unlock = 6;//是否解锁
--     optional int64 saleExpireAt = 7;//促销过期时间
--   }
function AlbumMoreAwardData:parseData(_data)
    AlbumMoreAwardData.super.parseData(self,_data)

    self.p_lastStatus = self.p_unlock
    self.p_saleExpireAt = tonumber(_data.saleExpireAt)
    self.p_multiply = tonumber(_data.multiply)
    self.p_unlock = _data.unlock
    self.p_saleList = self:parseSaleList(_data.saleList)
    
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ALBUM_MORE_AWARD_UPDATE_DATA)
    
    if self.p_unlock and self.p_lastStatus == false and self:getSaleExpireAt() > util_getCurrnetTime() + 3 then
        if G_GetMgr(ACTIVITY_REF.AlbumMoreAward):isDownloadRes() then
            local activityDatas = globalData.commonActivityData:getActivitys()
            local data = activityDatas[ACTIVITY_REF.AlbumMoreAward]
            if data then
                local params = {}
                params.hall = {info = {feature = {key = "AlbumMoreAwardHall"}}, index = 1}
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_INSERT_HALL_AND_SLIDE, params)

                local params = {}
                params.hall = {info = {feature = {key = "AlbumMoreAwardSaleHall"}}, index = 2}
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LOBBY_INSERT_HALL_AND_SLIDE, params)
            end
        end
    end
end

-- message AlbumMoreAwardSaleList {
--     optional int32 index = 1;
--     optional string key = 2;
--     optional string keyId = 3;
--     optional string price = 4;
--     repeated ShopItem items = 5;
--     optional string coins = 6;
--     optional int32 remainingTimes = 7;//剩余可购买次数
--   }
function AlbumMoreAwardData:parseSaleList(_data)
    local list = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_index = v.index
            temp.p_key = v.key
            temp.p_keyId = v.keyId
            temp.p_price = v.price
            temp.p_coins = tonumber(v.coins)
            temp.p_remainingTimes = v.remainingTimes
            temp.p_items = self:parseItems(v.items)
            table.insert(list, temp)
        end
    end
    return list
end

function AlbumMoreAwardData:parseItems(_items)
    -- 通用道具
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

function AlbumMoreAwardData:getMultiply()
    return self.p_multiply
end

function AlbumMoreAwardData:getSaleList()
    return self.p_saleList
end

function AlbumMoreAwardData:isUnlock()
    return self.p_unlock
end

function AlbumMoreAwardData:getSaleExpireAt()
    return (self.p_saleExpireAt or 0) / 1000
end

return AlbumMoreAwardData
