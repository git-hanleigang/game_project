--[[
    集卡系统
    卡册选择面板子类 201903赛季
    数据来源于年度开启的赛季
--]]

local CardAlbumView201903 = util_require("GameModule.Card.season201903.CardAlbumView")
local CardAlbumView = class("CardAlbumView", CardAlbumView201903)

function CardAlbumView:getCsbName()
    return string.format(CardResConfig.seasonRes.CardAlbumViewRes, "season201904") 
end

function CardAlbumView:getTitleLuaPath()
    return "GameModule.Card.season201904.CardAlbumTitle"
end

function CardAlbumView:getBottomLuaPath()
    return "GameModule.Card.season201904.CardSeasonBottom"
end

function CardAlbumView:getCellLuaPath()
    return "GameModule.Card.season201904.CardAlbumCell"
end

return CardAlbumView