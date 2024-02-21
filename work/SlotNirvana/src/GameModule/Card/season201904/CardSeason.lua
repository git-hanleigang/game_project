--[[
    赛季类
    author:{author}
    time:2020-08-24 20:13:26
]]
local CardSeason201903 = require("GameModule.Card.season201903.CardSeason")
local CardSeason = class("CardSeason", CardSeason201903)

function CardSeason:ctor()
    CardSeason.super.ctor(self)
    -- 卡册界面
    self.m_cardClanUI = "GameModule.Card.season201904.CardClanView"
    -- 卡册弹框
    self.m_bigCardUI = "GameModule.Card.season201904.BigCardLayer"
end

function CardSeason:getLinkProgressCsbName()
    return string.format(CardResConfig.commonRes.linkProgress201903, "common"..CardSysRuntimeMgr:getCurAlbumID())
end

function CardSeason:getPuzzlePageLuaName()
    return "GameModule.Card.season201904.PuzzlePage.PuzzleMainUI"
end

function CardSeason:getPuzzleGameLuaName()
    return "GameModule.Card.season201904.PuzzleGame.PuzzleGameMainUI"
end

return CardSeason
