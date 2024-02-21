--[[--
    轮次引导
]]
local CardAlbumRoundGuide = class("CardAlbumRoundGuide", BaseView)

function CardAlbumRoundGuide:initDatas(_round)
    self.m_round = _round
end

function CardAlbumRoundGuide:getCsbName()
    return "CardRes/season202303/cash_album_guide.csb"
end

function CardAlbumRoundGuide:initCsbNodes()
    self.m_lbDesc = self:findChild("lb_desc")
end

function CardAlbumRoundGuide:initUI()
    CardAlbumRoundGuide.super.initUI(self)
    self:initDesc()
end

function CardAlbumRoundGuide:initDesc()
    local str = gLobalLanguageChangeManager:getStringByKey("CardAlbumRoundGuide:lb_desc")
    local desc = string.format(str, tostring(self.m_round + 1), self:getCoinMulti() .. "%")
    self.m_lbDesc:setString(desc)
end

function CardAlbumRoundGuide:getCoinMulti()
    if self.m_round == 1 then
        return 300
    elseif self.m_round == 2 then
        return 600
    end
    return 100
end

return CardAlbumRoundGuide
