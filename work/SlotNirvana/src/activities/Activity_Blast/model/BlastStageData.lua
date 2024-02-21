--pick 过关奖励和轮次奖励数据
local ShopItem = require "data.baseDatas.ShopItem"
local BlastStageData = class("BlastStageData")

function BlastStageData:ctor()
    self.m_coins = toLongNumber(0)
end

function BlastStageData:parseData(data)
    self.m_gems = data.gems
    self.m_card = data.cardDrops
    if data.coinsV2 and data.coinsV2 ~= "" and data.coinsV2 ~= "0" then
        self.m_coins:setNum(data.coinsV2)
    else
        self.m_coins:setNum(data.coins)
    end
    self.m_items = {}
    if data.items and #data.items > 0 then
        for i,v in ipairs(data.items) do
            local shopItem = ShopItem:create()
            shopItem:parseData(v, true)
            table.insert(self.m_items,shopItem)
        end
    end
end

function BlastStageData:getCoins()
    return self.m_coins
end

function BlastStageData:getCards()
    return self.m_card
end

function BlastStageData:getItems()
    return self.m_items
end

function BlastStageData:getGems()
    return self.m_gems or 0
end

return BlastStageData
