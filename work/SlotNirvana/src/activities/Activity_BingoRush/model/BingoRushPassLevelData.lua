--[[
Author: cxc
Date: 2022-01-27 18:26:52
LastEditTime: 2022-01-27 18:27:14
LastEditors: cxc
Description: bingo 比赛pass 各阶段的奖励 数据
FilePath: /SlotNirvana/src/activities/Activity_BingoRush/model/BingoRushPassLevelData.lua
--]]
-- message BingoRushPassLevel {
--     optional int64 points = 1; //当前阶段的点数
--     optional bool collectFree = 2; // 免费是否已收集
--     optional bool collectPay = 3; // 付费是否已收集
--     optional int64 freeCoins = 4; // 免费金币
--     optional ShopItem freeItem = 5; // 免费物品
--     optional int64 payCoins = 6; // 付费金币
--     optional ShopItem payItem = 7; // 付费物品
--     optional string freeUsd = 8; // 免费金币
--     optional string payUsd = 9; // 付费金币
--     optional string freeTitle = 10; // 免费标题
--     optional string payTitle = 11; // 付费标题
--   }
local BingoRushPassLevelData = class("BingoRushPassLevelData")
local ShopItem = util_require("data.baseDatas.ShopItem")

function BingoRushPassLevelData:ctor(_idx)
    self.m_points = 0
    self.m_bCollectFree = false
    self.m_bCollectPay = false
    self.m_freeCoins = 0
    self.m_payCoins = 0
    self.m_freeItemList = {}
    self.m_payItemList = {}
    self.m_freeItemNumber = 0
    self.m_payItemNumber = 0
    self.m_freeUsdValue = 0
    self.m_payUsdValue = 0
    self.m_freeItemDesc = ""
    self.m_payItemDesc = ""
    self.m_idx = _idx or 0
    self.m_bUnlock = false -- 是否解锁
end

function BingoRushPassLevelData:parseData(_data, _bUnlock)
    if not _data then
        return
    end

    self.m_bUnlock = _bUnlock

    self.m_points = tonumber(_data.points) or 0
    self.m_bCollectFree = _data.collectFree
    self.m_bCollectPay = _data.collectPay
    self.m_freeCoins = tonumber(_data.freeCoins) or 0
    self.m_payCoins = tonumber(_data.payCoins) or 0

    self.m_freeItemList = {}
    if self.m_freeCoins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_freeCoins)
        itemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        table.insert(self.m_freeItemList, itemData)
    end
    self:parseFreeItemList(_data.freeItem)
    self.m_payItemList = {}
    if self.m_payCoins > 0 then
        local itemData = gLobalItemManager:createLocalItemData("Coins", self.m_payCoins)
        itemData:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
        table.insert(self.m_payItemList, itemData)
    end
    self:parsePayItemList(_data.payItem)

    self.m_freeUsdValue = _data.freeUsd
    self.m_payUsdValue = _data.payUsd

    self.m_freeItemDesc = _data.freeTitle or ""
    self.m_payItemDesc = _data.payTitle or ""
end

function BingoRushPassLevelData:getCollectCount(_curPoints)
    local collect_count = 0
    -- 未解锁
    if self.m_points > _curPoints then
        return collect_count
    end
    -- 免费和付费都已领取
    if not self:isCollectFree() then
        collect_count = collect_count + 1
    end

    if not self:isUnlock() then
        return collect_count
    end

    if not self:isCollectPay() then
        collect_count = collect_count + 1
    end

    return collect_count
end

-- 免费物品
function BingoRushPassLevelData:parseFreeItemList(_itemData)
    if not _itemData then
        return
    end

    local itemData = _itemData
    local rewardItem = ShopItem:create()
    rewardItem:parseData(itemData)
    rewardItem:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
    self.m_freeItemNumber = self:getNumDesc(rewardItem)
    table.insert(self.m_freeItemList, rewardItem)
end

-- 付费物品
function BingoRushPassLevelData:parsePayItemList(_itemData)
    if not _itemData then
        return
    end

    local itemData = _itemData
    local rewardItem = ShopItem:create()
    rewardItem:parseData(itemData)
    rewardItem:setTempData({p_mark = {ITEM_MARK_TYPE.NONE}}) -- 隐藏数量
    self.m_payItemNumber = self:getNumDesc(rewardItem)
    table.insert(self.m_payItemList, rewardItem)
end

function BingoRushPassLevelData:getNumDesc(_itemData)
    local _multip = 1
    -- 先找到创建好的 itemnode 节点下的文本字体
    local newStr = _itemData.p_num
    -- 重新根据需求组装文本
    if string.find(_itemData.p_icon, "club_pass_") then -- 高倍场体验卡
        -- 需要把文字设置成居中模式
        newStr = "X" .. (1 * _multip) -- 高倍场体验卡需要根据倍数来显示个数
    elseif string.find(_itemData.p_icon, "Coupon") then -- 折扣券
        newStr = _itemData.p_num .. "%"
    elseif string.find(_itemData.p_icon, "GiftPickBonusIcon") then -- starpick 小游戏
        -- 需要把文字设置成居中模式
        newStr = "X" .. (1 * _multip) -- 小游戏需要根据倍数来显示个数
    elseif string.find(_itemData.p_icon, "MiniGame_") then
        local num = _itemData.p_num
        if _itemData.p_showTempData and table.nums(_itemData.p_showTempData) then
            num = _itemData.p_showTempData.p_num
        end
        newStr = "+" .. (num * _multip)
    else
        local num = _itemData.p_num
        newStr = "X" .. num
    end
    return newStr
end

-- 当前阶段的点数
function BingoRushPassLevelData:getPoints()
    return self.m_points
end

-- 免费是否已收集
function BingoRushPassLevelData:isCollectFree()
    return self.m_bCollectFree
end

-- 付费是否已收集
function BingoRushPassLevelData:isCollectPay()
    return self.m_bCollectPay
end

-- 免费金币
function BingoRushPassLevelData:getFreeCoins()
    return self.m_freeCoins
end

-- 付费金币
function BingoRushPassLevelData:getPayCoins()
    return self.m_payCoins
end

-- 免费物品
function BingoRushPassLevelData:getFreeItemList()
    return self.m_freeItemList
end

-- 付费物品
function BingoRushPassLevelData:getPayItemList()
    return self.m_payItemList
end

-- 免费物品个数
function BingoRushPassLevelData:getFreeItemNumber()
    if self.m_freeCoins > 0 and self.m_freeUsdValue then
        return "$" .. self.m_freeUsdValue
    end

    return self.m_freeItemNumber
end

-- 付费物品个数
function BingoRushPassLevelData:getPayItemNumber()
    if self.m_payCoins > 0 and self.m_payUsdValue then
        return "$" .. self.m_payUsdValue
    end

    return self.m_payItemNumber
end

function BingoRushPassLevelData:getItemDesc(_bPay)
    if _bPay then
        return self.m_payItemDesc
    end
    return self.m_freeItemDesc
end

-- 获取阶段idx
function BingoRushPassLevelData:getPhaseIdx()
    return self.m_idx
end

-- 是否已解锁
function BingoRushPassLevelData:goUnlock()
    self.m_bUnlock = true
end
function BingoRushPassLevelData:isUnlock()
    return self.m_bUnlock
end

return BingoRushPassLevelData
