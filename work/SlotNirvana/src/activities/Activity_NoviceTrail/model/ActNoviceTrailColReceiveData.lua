--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-07-04 14:11:10
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-07-04 14:26:58
FilePath: /SlotNirvana/src/activities/Activity_NoviceTrail/model/ActNoviceTrailColReceiveData.lua
Description: 新手期三日任务 领取数据 客户端组装
--]]
local ActNoviceTrailColReceiveData = class("ActNoviceTrailColReceiveData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function ActNoviceTrailColReceiveData:ctor()
    self.m_taskColCoins = 0
    self.m_taskColPoints = 0
    self.m_taskColItems = {}
    self.m_progColCoins = 0
    self.m_progColItems = {}
    self.m_propsBagist = {}
end

function ActNoviceTrailColReceiveData:parseData(_data)
    if not _data then
        return
    end

    self.m_taskColCoins = tonumber(_data.collectCoins) or 0
    self.m_taskColPoints = tonumber(_data.collectPoints) or 0
    self:parseTaskItems(_data.collectItems or {})
    self.m_progColCoins = tonumber(_data.progressCoins) or 0
    self:parseProgItems(_data.progressItems or {})
end

-- 奖励道具
function ActNoviceTrailColReceiveData:parseTaskItems(_list)
    self.m_taskColItems = {} -- 物品奖励
    if self.m_taskColCoins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self.m_taskColCoins, 6)) 
        table.insert(self.m_taskColItems, itemData)
    end

    for k, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        if string.find(shopItem.p_icon, "Pouch") then
            table.insert(self.m_propsBagist, shopItem)
        end
        table.insert(self.m_taskColItems, shopItem)
    end
end

-- 奖励道具
function ActNoviceTrailColReceiveData:parseProgItems(_list)
    self.m_progColItems = {} -- 物品奖励
    if self.m_progColCoins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", util_formatCoins(self.m_progColCoins, 6)) 
        table.insert(self.m_progColItems, itemData)
    end

    for k, data in ipairs(_list) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data)
        if string.find(shopItem.p_icon, "Pouch") then
            table.insert(self.m_propsBagist, shopItem)
        end
        table.insert(self.m_progColItems, shopItem)
    end
end

function ActNoviceTrailColReceiveData:getTaskColCoins()
    return self.m_taskColCoins
end
function ActNoviceTrailColReceiveData:getTaskColPoints()
    return self.m_taskColPoints
end
function ActNoviceTrailColReceiveData:getTaskColItems()
    return self.m_taskColItems
end
function ActNoviceTrailColReceiveData:getProgColCoins()
    return self.m_progColCoins
end
function ActNoviceTrailColReceiveData:getProgColItems()
    return self.m_progColItems
end
function ActNoviceTrailColReceiveData:getDelxueMergePropBagList()
    return self.m_propsBagist
end
return ActNoviceTrailColReceiveData