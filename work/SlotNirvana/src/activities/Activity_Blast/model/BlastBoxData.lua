--pick 返回数据解析
local ShopItem = require "data.baseDatas.ShopItem"
local BlastBoxData = class("BlastBoxData")
--     "box":{
--         "coins":0,
--         "items":[
--             {
--                 "activityId":"-1",
--                 "description":"BLAST宝箱加成",
--                 "expireAt":0,
--                 "icon":"Blast",
--                 "id":80003,
--                 "item":{
--                     "createTime":1597809316000,
--                     "description":"BLAST宝箱加成",
--                     "duration":-1,
--                     "icon":"/XX/XX.png",
--                     "id":119,
--                     "lastUpdateTime":1597809316000,
--                     "linkId":"-1",
--                     "type1":1,
--                     "type2":1
--                 },
--                 "num":10,
--                 "type":"Item"
--             }
--         ],
--         "jackpot":0, -- 获得jackpot星星的类型(mini minor major grand)
--         "rewardCoinsEnd":720720000,
--         "rewardCoinsStart":655200000
--         "gems":0,
--         "treasurePositions":["1","2","3"]
--     },

function BlastBoxData:ctor()
    self.m_coins = toLongNumber(0)
    self.m_rewardCoinsStart = toLongNumber(0)
    self.m_rewardCoinsEnd = toLongNumber(0)
end

function BlastBoxData:parseData(data)
    self.m_jackpot = data.jackpot
    self.m_gems = data.gems
    self.m_cardDrops = data.cardDrops
    self.m_items = {}
    if data.items and #data.items > 0 then
        for i,v in ipairs(data.items) do
            local shopItem = ShopItem:create()
            shopItem:parseData(v, true)
            table.insert(self.m_items,shopItem)
        end
    end
    if data.coinsV2 and data.coinsV2 ~= "" and data.coinsV2 ~= "0" then
        self.m_coins:setNum(data.coinsV2)
    else
        self.m_coins:setNum(data.coins)
    end

    if data.rewardCoinsStartV2 and data.rewardCoinsStartV2 ~= "" and data.rewardCoinsStartV2 ~= "0" then
        self.m_rewardCoinsStart:setNum(data.rewardCoinsStartV2)
    elseif data.rewardCoinsV2Start and data.rewardCoinsV2Start ~= "" and data.rewardCoinsV2Start ~= "0" then
        self.m_rewardCoinsStart:setNum(data.rewardCoinsV2Start)
    else
        self.m_rewardCoinsStart:setNum(data.rewardCoinsStart)
    end

    if data.rewardCoinsEndV2 and data.rewardCoinsEndV2 ~= "" and data.rewardCoinsEndV2 ~= "0" then
        self.m_rewardCoinsEnd:setNum(data.rewardCoinsEndV2)
    elseif data.rewardCoinsV2End and data.rewardCoinsV2End ~= "" and data.rewardCoinsV2End ~= "0" then
        self.m_rewardCoinsEnd:setNum(data.rewardCoinsV2End)
    else
        self.m_rewardCoinsEnd:setNum(data.rewardCoinsEnd)
    end
    self.m_treasure = {}
    if data.treasurePositions and #data.treasurePositions > 0 then
        for i,v in ipairs(data.treasurePositions) do
            table.insert(self.m_treasure,v)
        end
    end
end

function BlastBoxData:getCards()
    return self.m_cardDrops
end

function BlastBoxData:getJackpot()
    return self.m_jackpot
end

function BlastBoxData:getGems()
    return self.m_gems or 0
end

function BlastBoxData:getCoins()
    return self.m_coins
end

function BlastBoxData:getStartCoins()
    return self.m_rewardCoinsStart
end

function BlastBoxData:getEndCoins()
    return self.m_rewardCoinsEnd
end

function BlastBoxData:getTreasures()
    return self.m_treasure
end

function BlastBoxData:getItems()
    return self.m_items
end

return BlastBoxData
