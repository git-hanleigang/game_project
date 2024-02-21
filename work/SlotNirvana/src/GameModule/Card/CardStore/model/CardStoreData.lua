-- 集卡商城数据

local ShopItem = util_require("data.baseDatas.ShopItem")
local CardStoreItemData = require("GameModule.Card.CardStore.model.CardStoreItemData")
local CardStoreData = class("CardStoreData")

--message CardStoreV2 {
--    optional int32 normalPoints = 1; //普通点数
--    optional int32 goldenPoints = 2; //黄金点数
--    optional int32 lastNormalPoints = 3; //上赛季多余卡兑换的普通点数
--    optional int32 lastGoldenPoints = 4; //上赛季多余卡兑换的黄金点数
--    optional int64 nextRefreshTime = 5; //下次刷新时间
--    optional int32 manualRefreshGems = 6; //手动刷新钻石
--    repeated CardStoreV2Item normalItemList = 7; //普通商品
--    repeated CardStoreV2Item goldenItemList = 8; //黄金商品
--    repeated CardStoreV2Item blindBoxList = 9;//盲盒
--    optional bool canFreeGetGift = 10;//是否可以领取免费礼物
--    optional bool showGuide = 11;//新手引导
--    optional CardStoreV2FreeReward freeReward = 12;//免费奖励
--    repeated CardStoreV2BlindBoxProbability probabilityList = 13;//概率集合
--}
function CardStoreData:parseData(data)
    -- 这里只做数据初始化
    if self:getNormalChipPoints() == nil then
        self:setNormalChipPoints(data.normalPoints)
    end
    -- 这里只做数据初始化
    if self:getGoldenChipPoints() == nil then
        self:setGoldenChipPoints(data.goldenPoints)
    end
    self.showGuide = data.showGuide or false
    self.lastNormalPoints = data.lastNormalPoints
    self.lastGoldenPoints = data.lastGoldenPoints
    self.nextRefreshTime = tonumber(data.nextRefreshTime / 1000)
    self.manualRefreshGems = data.manualRefreshGems
    if data.normalItemList and #data.normalItemList > 0 then
        self:parseNormalItems(data.normalItemList)
    end
    if data.goldenItemList and #data.goldenItemList > 0 then
        self:parseGoldenItems(data.goldenItemList)
    end
    --if data.blindBoxList and #data.blindBoxList > 0 then
    --    self:parseBlindItems(data.blindBoxList)
    --end
    --if data.probabilityList and #data.probabilityList > 0 then
    --    self:parseBlindProbList(data.probabilityList)
    --end
    self.canFreeGetGift = data.canFreeGetGift or false
    self:parseGiftItems(data.freeReward)
end

-- 解析普通商品列表
function CardStoreData:parseNormalItems(data)
    self.normalItems = {}
    for idx, item_data in ipairs(data) do
        local item = CardStoreItemData:create()
        item:parseData(item_data)
        table.insert(self.normalItems, item)
    end
end

-- 解析普通商品列表
function CardStoreData:parseGoldenItems(data)
    self.goldenItems = {}
    for idx, item_data in ipairs(data) do
        local item = CardStoreItemData:create()
        item:parseData(item_data)
        table.insert(self.goldenItems, item)
    end
end

---- 解析普通商品列表
--function CardStoreData:parseBlindItems(data)
--    self.blindItems = {}
--    for idx, item_data in ipairs(data) do
--        local item = CardStoreItemData:create()
--        item:parseData(item_data)
--        table.insert(self.blindItems, item)
--    end
--end

---- 盲盒道具产出概率
--function CardStoreData:parseBlindProbList(data)
--    self.blindProbList = {}
--    for idx, prob_data in ipairs(data) do
--        self.blindProbList[idx] = {}
--        for i, item_data in ipairs(prob_data.probabilityList) do
--            local item = CardStoreItemData:create()
--            item:parseData(item_data)
--            table.insert(self.blindProbList[idx], item)
--        end
--    end
--end

function CardStoreData:parseGiftItems(data)
    self.freeReward = {}
    self.freeReward.coins = tonumber(data.coins or 0)
    self.freeReward.items = {}
    if data.itemList and #data.itemList > 0 then
        for idx, item_data in ipairs(data.itemList) do
            local shopItem = ShopItem:create()
            shopItem:parseData(item_data, true)
            table.insert(self.freeReward.items, shopItem)
        end
    end
end

function CardStoreData:getNormalItems()
    return self.normalItems
end

function CardStoreData:getGoldenItems()
    return self.goldenItems
end

--function CardStoreData:getBlindItems()
--    return self.blindItems
--end

--function CardStoreData:getBlindProbListByIdx(idx)
--    if self.blindProbList and self.blindProbList[idx] then
--        return self.blindProbList[idx]
--    end
--end

-- 商店重置倒计时
function CardStoreData:getTimeReset()
    return self.nextRefreshTime or 0
end

-- 商店刷新所需宝石数
function CardStoreData:getResetGems()
    return self.manualRefreshGems or 0
end

-- 商店刷新所需宝石数
function CardStoreData:getNormalChipPoints()
    return self.m_normalPoints
end

function CardStoreData:setNormalChipPoints(_points)
    self.m_normalPoints = math.max(0, _points)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EVENT_CARD_STORE_REFRESH)
end

-- 商店刷新所需宝石数
function CardStoreData:getGoldenChipPoints()
    return self.m_goldenPoints
end

function CardStoreData:setGoldenChipPoints(_points)
    self.m_goldenPoints = math.max(0, _points)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_EVENT_CARD_STORE_REFRESH)
end

-- 是否可以领取免费奖励
function CardStoreData:getCanGiftCollect()
    return self.canFreeGetGift
end

-- 免费奖励数据
function CardStoreData:getGiftData()
    return self.freeReward
end

-- 是否显示上赛季结算引导
function CardStoreData:isShowGuide()
    return self.showGuide
end

-- 引导显示的结算碎片数
function CardStoreData:getGuideNormalPoints()
    return self.lastNormalPoints
end

-- 引导显示的结算碎片数
function CardStoreData:getGuideGoldenPoints()
    return self.lastGoldenPoints
end

return CardStoreData
