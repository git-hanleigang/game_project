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
    self.m_cardClanUI = "GameModule.Card.season202101.CardClanView"
    -- 卡册弹框
    self.m_bigCardUI = "GameModule.Card.season202101.BigCardLayer"
end

function CardSeason:getLinkProgressCsbName()
    return string.format(CardResConfig.commonRes.linkProgress201903, "common"..CardSysRuntimeMgr:getCurAlbumID())
end

function CardSeason:getPuzzlePageLuaName()
    return nil
end

function CardSeason:getPuzzleGameLuaName()
    return nil
end

return CardSeason
