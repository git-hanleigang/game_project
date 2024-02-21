--[[
    wild章节的卡组合
]]
local CardClanCellWildCard = class("CardClanCellWildCard", BaseView)

function CardClanCellWildCard:getCsbName()
    return CardResConfig.CardClanViewWildCardRes
end

function CardClanCellWildCard:initCsbNodes()
    self.m_sps = {}
    self.m_nums = {}
    for i=1,4 do
        self.m_sps[i] = self:findChild("sp_"..i)
        self.m_nums[i] = self:findChild("tishi_"..i)
    end

    self.m_sp_bg = self:findChild("sp_bg")
end

function CardClanCellWildCard:updateCards(clanData)
    local cardsData = clanData.cards
    for i=1,#self.m_sps do
        if cardsData[i] and cardsData[i].count == 0 then
            self.m_sps[i]:setVisible(true)
            util_changeTexture(self.m_sps[i], CardResConfig.getCardIcon(cardsData[i].cardId))
        else
            self.m_sps[i]:setVisible(false)
        end
    end
    -- 20190221
    util_changeTexture(self.m_sp_bg, CardResConfig.getWildCardBgIcon(clanData.clanId))
end

return CardClanCellWildCard