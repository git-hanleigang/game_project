--[[
    message AdventureWinReward {
    optional int64 coins = 1; //奖励金币
    optional int32 gems = 2;//奖励宝石
    repeated ShopItem items = 3;//奖励物品
    }
]]
local ShopItem = util_require("data.baseDatas.ShopItem")
local CardAdventureWinRewardData = class("CardAdventureWinRewardData")

function CardAdventureWinRewardData:parseData(data)
    self.p_coins = tonumber(data.coins or 0)
    self.p_gems = data.gems or 0
    self.p_items = {}
    if data.items and #data.items > 0 then
        for i = 1, #data.items do
            local si = ShopItem:create()
            si:parseData(data.items[i])
            table.insert(self.p_items, si)
        end
    end
end

function CardAdventureWinRewardData:getCoins()
    return self.p_coins or 0
end

function CardAdventureWinRewardData:getGems()
    return self.p_gems or 0
end

function CardAdventureWinRewardData:getItems()
    return self.p_items or {}
end

function CardAdventureWinRewardData:getMergeItems()
    return self.p_items or {}
    -- local mergeItemDatas = {}
    -- if self.p_items and #self.p_items > 0 then
    --     for i = 1, #self.p_items do
    --         local itemData = self.p_items[i]
    --         if mergeItemDatas and #mergeItemDatas > 0 then
    --             for j = 1, #mergeItemDatas do
    --                 local mItemData = mergeItemDatas[j]
    --                 if mItemData.p_icon == itemData.p_icon then
    --                     mItemData.p_num = mItemData.p_num + itemData.p_num
    --                 else
    --                     mergeItemDatas[#mergeItemDatas + 1] = itemData
    --                 end
    --             end
    --         else
    --             mergeItemDatas[#mergeItemDatas + 1] = itemData
    --         end
    --     end
    -- end
    -- return mergeItemDatas
end

function CardAdventureWinRewardData:hasRewards()
    if self.p_coins > 0 or self.p_gems > 0 or #self.p_items > 0 then
        return true
    end
    return false
end

return CardAdventureWinRewardData
