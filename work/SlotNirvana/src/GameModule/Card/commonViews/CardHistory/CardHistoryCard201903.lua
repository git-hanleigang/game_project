--[[--
    历史界面 卡牌汇总
]]
local CardHistoryCard201903 = class("CardHistoryCard201903", BaseView)
function CardHistoryCard201903:initUI()
    CardHistoryCard201903.super.initUI(self)
end

function CardHistoryCard201903:getCsbName()
    return "CardsBase201903/CardRes/season201903/cash_card_history201903.csb"
end

function CardHistoryCard201903:initCsbNodes()
    self.m_spBg = self:findChild("sp_bg")
    self.m_spIcon = self:findChild("sp_card")
    self.m_fntName1 = self:findChild("lb_name_1")
    self.m_fntName2 = self:findChild("lb_name_2")
    self.m_fntName3 = self:findChild("lb_name_3")
    self.m_nodeStar = self:findChild("Node_star")
end

-- 外部调用
function CardHistoryCard201903:updateUI(cardData, noShowStar)
    -- self.m_noShowStar = noShowStar
    self:updateBg(cardData.type)
    self:updateIcon(cardData.cardId, tonumber(cardData.albumId) == tonumber(CardNoviceCfg.ALBUMID))
    self:updateName(cardData.name)
    self:updateStar201903(cardData)
    self:updateObsidianTag(cardData)
end

function CardHistoryCard201903:updateBg(cardType)
    local bgImgRes = CardResConfig.getCardBgRes(cardType, true)
    if bgImgRes then
        util_changeTexture(self.m_spBg, bgImgRes)
    end
end

function CardHistoryCard201903:updateIcon(cardId, isNovice)
    local cardImgRes = CardResConfig.getCardIcon(cardId, nil, isNovice)
    util_changeTexture(self.m_spIcon, cardImgRes)
end

--[[(黑曜卡通过标签区分赛季)]]
function CardHistoryCard201903:updateObsidianTag(_cardData)
    if not CardSysRuntimeMgr:isObsidianCard(_cardData.type) then
        return
    end
    local node_Parent = self:findChild("Node_icon")
    if node_Parent then 
        local scale = 0.77
        local tagIconRes = CardResConfig.getObsidianCardTagIcon(_cardData.cardId, true)
        local tag = util_createSprite("" .. tagIconRes)
        tag:setPosition(-147, -60)
        tag:setScale(scale)
        node_Parent:addChild(tag)
    end
end

function CardHistoryCard201903:updateName(cardName)
    self.m_fntName1:setVisible(false)
    self.m_fntName2:setVisible(false)
    self.m_fntName3:setVisible(false)
    local nameStrs = string.split(cardName, "|")
    if #nameStrs == 1 then
        self.m_fntName3:setVisible(true)
        self.m_fntName3:setString(nameStrs[1])
    else
        self.m_fntName1:setVisible(true)
        self.m_fntName2:setVisible(true)
        self.m_fntName1:setString(nameStrs[1])
        self.m_fntName2:setString(nameStrs[2])
    end
end

-- 外部调用
function CardHistoryCard201903:updateStar201903(cardData)
    local child = self.m_nodeStar:getChildByName("star")
    if not child then
        child = util_createView("GameModule.Card.season201903.CardTagStar")
        child:setName("star")
        self.m_nodeStar:addChild(child)
    end
    child:updateUI(cardData)
end

return CardHistoryCard201903
