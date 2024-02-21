--[[
    集卡系统  指定卡组中卡片显示面板 数据来源于指定或手动选择的赛季
    201903
--]]
local CardClanView201903 = util_require("GameModule.Card.season201903.CardClanView")
local CardClanView = class("CardClanView", CardClanView201903)

function CardClanView:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanViewRes, "season202302")
end

function CardClanView:getCellLua()
    return "GameModule.Card.season202302.CardClanCell"
end

function CardClanView:getTitleLua()
    return "GameModule.Card.season202302.CardClanTitle"
end

function CardClanView:getPageNum()
    return 22
end

function CardClanView:initView()
    CardClanView.super.initView(self)
    self:initRoundBg()
end

function CardClanView:initRoundBg()
    local round = self:getAlbumRound()
    for i = 1, 3 do
        local spRoundBg = self:findChild("sp_bg_" .. i)
        spRoundBg:setVisible(i == round)
    end
end

function CardClanView:getAlbumRound()
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    local info = CardSysRuntimeMgr:getCardAlbumInfo(albumID)
    return (info.round or 0) + 1
end

return CardClanView
