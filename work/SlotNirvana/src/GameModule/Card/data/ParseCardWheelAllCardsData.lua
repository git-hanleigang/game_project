-- 解析回收机可回收年度的所有卡片数据
-- 数据结构
--[[--
      cards{}
]]
local ParseCardData = require("GameModule.Card.data.ParseCardData")
local ParseCardWheelAllCardsData = class("ParseCardWheelAllCardsData")

function ParseCardWheelAllCardsData:ctor()
end

function ParseCardWheelAllCardsData:parseData(data)
    self.cards = {}
    if data.cards and #data.cards > 0 then
        for i = 1, #data.cards do
            local cardData = ParseCardData:create()
            cardData:parseData(data.cards[i])
            table.insert(self.cards, cardData)
        end
    end
end

return ParseCardWheelAllCardsData
