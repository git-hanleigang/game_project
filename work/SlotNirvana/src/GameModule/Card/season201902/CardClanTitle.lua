--[[
    卡组的标题
    201902
]]
local CardClanTitleBase = util_require("GameModule.Card.baseViews.CardClanTitleBase")
local CardClanTitle = class("CardClanTitle", CardClanTitleBase)

function CardClanTitle:initUI(csbName)
    self.m_csbTitleName = csbName
    CardClanTitle.super.initUI(self)
end

function CardClanTitle:initCsbNodes()
    CardClanTitle.super.initCsbNodes(self)
    -- 初始化自己的csb节点
    self.m_logos = {}
    for i=1,3 do
        self.m_logos[i] = self:findChild("wild_logo_"..i)
    end    
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
    if self.m_clanData.type == CardSysConfigs.CardClanType.puzzle_normal or self.m_clanData.type == CardSysConfigs.CardClanType.puzzle_golden or self.m_clanData.type == CardSysConfigs.CardClanType.puzzle_link then
    -- if self.m_clanData.wild then
        -- wild标题需要控制显示隐藏
        local showIndex = nil
        if self.m_clanData.type == CardSysConfigs.CardClanType.puzzle_normal then
            showIndex = 1
        elseif self.m_clanData.type == CardSysConfigs.CardClanType.puzzle_golden then
            showIndex = 2
        elseif self.m_clanData.type == CardSysConfigs.CardClanType.puzzle_link then
            showIndex = 3
        end
        for i=1,3 do
            self.m_logos[i]:setVisible(showIndex == i)
        end    
    else
        local icon = CardResConfig.getCardClanIcon(self.m_clanData.clanId)
        util_changeTexture(self.m_cardLogo, icon)
    end
end

-- 奖励
function CardClanTitle:updateCoin()
    local count = CardSysRuntimeMgr:getClanCardTypeCount(self.m_clanData.cards)
    local isCompleted = count >= #self.m_clanData.cards
    if isCompleted then
        self:runCsbAction("idle3", true)
    else
        -- if self.m_clanData.wild then
        --     self.m_coinWild:getChildByName("coins"):setString(util_formatCoins(tonumber(self.m_clanData.coins), 30).." COINS")
        --     self:runCsbAction("idle2", true)
        -- else
            self.m_coinNormal:getChildByName("coins"):setString(util_formatCoins(tonumber(self.m_clanData.coins), 30).." COINS")
            self:runCsbAction("idle1", true)
        -- end
    end
end

return CardClanTitle