-- --[[
-- ]]

-- local ParseYearData = require("GameModule.Card.data.ParseYearData")
-- local ParseCardAlbumData = require("GameModule.Card.data.ParseCardAlbumData")

local BaseGameModel = require("GameBase.BaseGameModel")
local CardNoviceData = class("CardNoviceData", BaseGameModel)

function CardNoviceData:ctor()
    self:setRefName(G_REF.CardNovice)
end

return CardNoviceData
   