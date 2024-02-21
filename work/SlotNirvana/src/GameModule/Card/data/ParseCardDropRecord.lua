--[[
    历史掉落记录
]]
local ParseCardData = require("GameModule.Card.data.ParseCardData")
local ParseCardDropRecord = class("ParseCardDropRecord")
function ParseCardDropRecord:ctor()
end

function ParseCardDropRecord:parseData(data)
    if data.card and data.card.cardId ~= nil then
        self.card = ParseCardData:create()
        self.card:parseData(data.card)
    end

    self.dropName = data.dropName
    self.dropTime = tonumber(data.dropTime)
end

return ParseCardDropRecord
