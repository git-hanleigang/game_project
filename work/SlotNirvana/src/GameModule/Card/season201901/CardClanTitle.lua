--[[
    卡组的标题
    2019
]]
local CardClanTitleBase = util_require("GameModule.Card.baseViews.CardClanTitleBase")
local CardClanTitle = class("CardClanTitle", CardClanTitleBase)

function CardClanTitle:initUI(csbName)
    self.m_csbTitleName = csbName
    CardClanTitle.super.initUI(self)
end

-- 子类重写
function CardClanTitle:getCsbName()
    return self.m_csbTitleName
end

function CardClanTitle:updateView(index, clanData)
    CardClanTitle.super.updateView(self, index, clanData)
    self:updateLogo()
    self:updateCoin()
end

-- logo
function CardClanTitle:updateLogo()
    local icon = CardResConfig.getCardClanIcon(self.m_clanData.clanId)
    util_changeTexture(self.m_cardLogo, icon)
end

-- 奖励
function CardClanTitle:updateCoin()
    local count = CardSysRuntimeMgr:getClanCardTypeCount(self.m_clanData.cards)
    local isCompleted = count >= #self.m_clanData.cards
    if isCompleted then
        self:runCsbAction("idle3", true)
    else
        if self.m_clanData.albumId == "201901" then
            if self.m_clanData.wild then
                self.m_coinWild:getChildByName("coins"):setString(util_formatCoins(tonumber(self.m_clanData.coins), 30).." COINS")
                self:runCsbAction("idle2", true)
            else
                self.m_coinNormal:getChildByName("coins"):setString(util_formatCoins(tonumber(self.m_clanData.coins), 30).." COINS")
                self:runCsbAction("idle1", true)
            end            
        elseif self.m_clanData.albumId == "201902" then
            self.m_coinNormal:getChildByName("coins"):setString(util_formatCoins(tonumber(self.m_clanData.coins), 30).." COINS")
            self:runCsbAction("idle1", true)
        end

    end
end

return CardClanTitle