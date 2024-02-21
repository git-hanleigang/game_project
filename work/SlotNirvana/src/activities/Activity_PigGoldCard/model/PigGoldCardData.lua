--[[
Author: dhs
Date: 2022-03-01 20:36:44
LastEditTime: 2022-03-01 20:37:43
LastEditors: your name
Description: 小猪折扣送金卡 数据解析类
FilePath: /SlotNirvana/src/activities/Activity_PigGoldCard/model/PigGoldCardData.lua
--]]

--[[
    message PigNormalCard {
    optional string activityId = 1;    //活动 id
    optional int64 expireAt = 2;      //活动截止时间
    optional int64 expire = 3;        //活动剩余时间
    repeated ShopItem items = 4;    //奖励物品
    optional int32 discount = 5;  //折扣
    repeated int32 collectFlags = 6;  //领取标记
    }
--]]

local BaseActivityData = require "baseActivity.BaseActivityData"
local PigGoldCardData = class("PigGoldCardData", BaseActivityData)
local ShopItem = util_require("data.baseDatas.ShopItem")

function PigGoldCardData:ctor()
    PigGoldCardData.super.ctor(self)
end

function PigGoldCardData:parseData(data)
    data = data or {}
    BaseActivityData.parseData(self, data)
    if not data then
        return 
    end

    self.m_activityId = data.activityId
    self.m_expireAt = tonumber(data.expireAt) 
    self.m_expire = tonumber(data.expire) 
    self.m_items = data.items
    self.m_discount = data.discount
    self.m_collectFlags = data.collectFlags
    self:setPiggyGoldFlag(self.m_expireAt)

    if self.m_items then
        self.m_itemsList = self:parseItems(self.m_items)
    end

    if self.m_collectFlags then
        self.m_collectFlagsList = self:parseFlags(self.m_collectFlags)
    end

end

function PigGoldCardData:parseItems(_items)
    local count = table.nums(_items)
    if count <= 0 then
        return {}
    end
    local itemList = {}
    for key,value in ipairs(_items) do
        local shopItem = ShopItem:create()
        shopItem:parseData(value)
        table.insert(itemList, shopItem)
    end
    return itemList
end

function PigGoldCardData:parseFlags(_flags)
    local count = table.nums(_flags)
    if count <= 0 then
        return {}
    end

    local flagsList = {}

    for key,value in ipairs(_flags) do
        table.insert( flagsList, value )
    end
    return flagsList
end

function PigGoldCardData:getItems()
    return self.m_itemsList
end
function PigGoldCardData:getStatus()
    return self.m_collectFlagsList
end
-- 关闭界面的回调
function PigGoldCardData:setCloseCallBack(_cb)
    self.m_closeBack = _cb
end
function PigGoldCardData:getCloseCallBack()
    return self.m_closeBack
end

function PigGoldCardData:getDisCount()
    return self.m_discount or 0
end

function PigGoldCardData:setPiggyGoldFlag(nOpenFlag)
    self.nFlag = nOpenFlag
end

function PigGoldCardData:getPiggyGoldFlag()
    return self.nFlag and self.nFlag > 0
end
-- 这里封装item以及item的状态
function PigGoldCardData:getItemData()
    local count = table.nums(self.m_itemsList)
    if count <= 0 then
        return {}
    end
    local tempData = {}
    for i=1,count do
        tempData.item = self.m_itemsList[i]
        tempData.status = self.m_collectFlagsList[i]
    end
    return tempData
end

return PigGoldCardData
