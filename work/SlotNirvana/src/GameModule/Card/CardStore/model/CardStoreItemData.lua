-- 集卡商城数据

local ShopItem = util_require("data.baseDatas.ShopItem")
local CardStoreItemData = class("CardStoreItemData")

--message CardStoreV2Item {
--    optional int64 id = 1; //id
--    repeated ShopItem shopItemResultList = 2; //商品集合
--    optional int64 coins = 3; //金币
--    optional string rewardType = 4; //奖励类型
--    optional int32 num = 5; //剩余数量
--    optional int32 points = 6; //兑换所需点数
--    optional string discount = 7; //折扣
--    optional string type = 8;//商品类型
--    optional string probability = 9;//概率
--    optional int64 gems = 10;//宝石
--}
function CardStoreItemData:parseData(data)
    self.id = data.id
    self.items = {}
    if data.shopItemResultList and #data.shopItemResultList > 0 then
        for i, item_data in ipairs(data.shopItemResultList) do
            local shopItem = ShopItem:create()
            shopItem:parseData(item_data, true)
            table.insert(self.items, shopItem)
        end
    end
    self.coins = tonumber(data.coins) or 0
    self.gems = tonumber(data.gems) or 0
    self.counts = data.num
    self.chips = data.points
    self.discount = data.discount or 0
    self.itemType = data.type
    self.prob = data.probability
end

-- 商品列表
function CardStoreItemData:getRewards()
    local item_list = {}
    item_list.coins = self.coins
    item_list.gems = self.gems
    item_list.items = self.items
    return item_list
end

-- 折扣
function CardStoreItemData:getDiscount()
    return self.discount
end

-- 兑换需要碎片数量
function CardStoreItemData:getChips()
    return self.chips
end

-- 剩余商品数量
function CardStoreItemData:getCounts()
    return self.counts
end

function CardStoreItemData:getItemId()
    return self.id
end

function CardStoreItemData:getItemType()
    return self.itemType
end

function CardStoreItemData:getProb()
    return self.prob
end

return CardStoreItemData
