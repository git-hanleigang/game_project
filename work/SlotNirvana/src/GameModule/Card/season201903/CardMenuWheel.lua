--[[
    小转盘
    界面右上角显示用 
]]
local CardMenuWheel201901 = require("GameModule.Card.season201901.CardMenuWheel")
local CardMenuWheel = class("CardMenuWheel", CardMenuWheel201901)

function CardMenuWheel:getCsbName()
    return string.format(CardResConfig.seasonRes.CardSeasonLottoRes, "season201903")
end

function CardMenuWheel:getBubbleLua()
    return "GameModule.Card.season201903.CardMenuWheelBubble"
end

return CardMenuWheel
