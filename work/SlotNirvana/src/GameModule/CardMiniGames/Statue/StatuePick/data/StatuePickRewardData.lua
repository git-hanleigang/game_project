--[[
    奖励信息
    author:徐袁
    time:2020-12-21 14:11:46
]]
local ShopItem = require("data.baseDatas.ShopItem")
local ParseCardDropData = require("GameModule.Card.data.ParseCardDropData")
local StatuePickRewardData = class("StatuePickRewardData")

function StatuePickRewardData:ctor()
    self.m_coins = 0
    self.m_items = {}
    self.m_dropCards = {}
    -- 宝石数量
    self.m_gems = 0
end

function StatuePickRewardData:getInstance()
    if not self._instance then
        self._instance = StatuePickRewardData:create()
    end
    return self._instance
end

function StatuePickRewardData:parseData(data)
    if not data or not next(data) then
        return
    end

    self.m_coins = data.coins
    self.m_items = {}
    -- 解析奖励道具
    for i = 1, #(data.rewards or {}) do
        local _itemInfo = ShopItem:create()
        _itemInfo:parseData(data.rewards[i])
        local bExit = self:changeExitItemCount(_itemInfo)
        if not bExit then
            table.insert(self.m_items, _itemInfo)
        end
    end

    -- 解析掉卡
    self.m_dropCards = {}
    if data.cardDrops and #data.cardDrops > 0 then
        for i = 1, #data.cardDrops do
            local pcData = ParseCardDropData:create()
            pcData:parseData(data.cardDrops[i])
            table.insert(self.m_dropCards, pcData)
        end
    end
    -- self:recombineClanRewards(self.m_dropCards)

    -- 宝石数量
    self.m_gems = data.gems
end

function StatuePickRewardData:getCoins()
    return tonumber(self.m_coins or 0)
end

function StatuePickRewardData:getItems()
    return self.m_items or {}
end

function StatuePickRewardData:getGems()
    return tonumber(self.m_gems or 0)
end

function StatuePickRewardData:getDropCards()
    return self.m_dropCards or {}
end

-- 相同source，分了多个卡包中，需要把多个卡包中的章节奖励合并成一个数组
function StatuePickRewardData:recombineClanRewards(_dropList)
    local clanRewards = {}
    for i = 1, #_dropList do
        local dropData = _dropList[i]
        if dropData.clanReward and #dropData.clanReward > 0 then
            for j = 1, #dropData.clanReward do
                table.insert(clanRewards, clone(dropData.clanReward[j]))
            end
            dropData.clanReward = {}
        end
        if i == #_dropList then
            dropData.clanReward = clanRewards
        end
    end
end

function StatuePickRewardData:changeExitItemCount(_itemInfo)
    if not _itemInfo then
        return
    end

    local checkId = _itemInfo.p_itemInfo and _itemInfo.p_itemInfo.p_id
    for _, itemData in pairs(self.m_items) do
        if itemData.p_itemInfo and itemData.p_itemInfo.p_id == checkId then
            itemData.p_num = itemData.p_num + _itemInfo.p_num
            return true
        end
    end

    return false
end

return StatuePickRewardData
