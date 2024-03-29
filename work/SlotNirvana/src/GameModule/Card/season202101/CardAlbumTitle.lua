--[[--
    章节选择界面的标题
]]
local CardAlbumTitle201903 = util_require("GameModule.Card.season201903.CardAlbumTitle")
local CardAlbumTitle = class("CardAlbumTitle", CardAlbumTitle201903)

function CardAlbumTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardAlbumTitleRes, "season202101")
end

function CardAlbumTitle:getTimeLua()
    return "GameModule.Card.season202101.CardSeasonTime"
end

return CardAlbumTitle
