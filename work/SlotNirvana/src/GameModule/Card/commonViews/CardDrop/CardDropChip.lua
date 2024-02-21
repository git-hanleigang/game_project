--[[--
    掉落界面的卡牌单元，包含卡牌和集卡商城券两个节点
]]
local CardDropChip = class("CardDropChip", BaseView)

function CardDropChip:initDatas(_dropCardData, _cardIndex, _actionCardNum, _tatolCardNum)
    self.m_cardData = _dropCardData
    self.m_cardIndex = _cardIndex
    self.m_actionCardNum = _actionCardNum
    self.m_tatolCardNum = _tatolCardNum
end

function CardDropChip:getCsbName()
    return "CardsBase201903/CardRes/season201903/cash_drop_chip.csb"
end

function CardDropChip:initCsbNodes()
    self.m_nodeChip = self:findChild("node_chips")
    self.m_nodeTicket = self:findChild("node_ticket")
end

function CardDropChip:initUI()
    CardDropChip.super.initUI(self)
    self:initChip()
    self:initStorePoint()
end

function CardDropChip:initChip()
    self.m_nodeChip:setVisible(false)
    local chip = util_createView("GameModule.Card.season201903.MiniChipUnit")
    self.m_nodeChip:addChild(chip)
    chip:playIdle()
    chip:reloadUI(self.m_cardData, true, true)
    chip:updateTagNew(self.m_cardData.firstDrop == true)
    chip:playAnimByIndex(self.m_cardIndex, self.m_nodeChip, self.m_tatolCardNum > 1 and self.m_cardIndex <= self.m_actionCardNum)
    self.m_chip = chip
    util_setCascadeOpacityEnabledRescursion(self.m_nodeChip, true)
end

function CardDropChip:initStorePoint()
    if CardSysRuntimeMgr:isCardNormalPoint(self.m_cardData) then
        local view = util_createView("GameModule.Card.commonViews.CardDrop.CardDropStoreTicket", "normal")
        self.m_nodeTicket:addChild(view)
        view:initTickets(self.m_cardData.greenPoint)
        view:playIdle()
    elseif CardSysRuntimeMgr:isCardGoldPoint(self.m_cardData) then
        local view = util_createView("GameModule.Card.commonViews.CardDrop.CardDropStoreTicket", "gold")
        self.m_nodeTicket:addChild(view)
        view:initTickets(self.m_cardData.goldPoint)
        view:playIdle()
    elseif CardSysRuntimeMgr:isCardConvertToCoin(self.m_cardData) then
        local itemData = gLobalItemManager:createLocalItemData("Coins", tonumber(self.m_cardData.exchangeCoins))
        local shopItem = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.REWARD)
        if shopItem then
            self.m_nodeTicket:addChild(shopItem)
            shopItem:setScale(0.7)
        end
    end
    util_setCascadeOpacityEnabledRescursion(self.m_nodeTicket, true)
end

function CardDropChip:isPlaySwitch()
    if CardSysRuntimeMgr:isCardNormalPoint(self.m_cardData) then
        return true
    end
    if CardSysRuntimeMgr:isCardGoldPoint(self.m_cardData) then
        return true
    end
    if CardSysRuntimeMgr:isCardConvertToCoin(self.m_cardData) then
        return true
    end
    return false
end

function CardDropChip:initStatus()
    if self:isPlaySwitch() then
        self:playSwitch()
    else
        self:playChipIdle()
    end
end

function CardDropChip:playChipIdle()
    self:runCsbAction("idle_chip", true, nil, 60)
end

function CardDropChip:playSwitch()
    self:runCsbAction("switch", true, nil, 60)
end

function CardDropChip:getCardData()
    return self.m_cardData
end

function CardDropChip:getViewSize()
    return cc.size(122, 140)
end

return CardDropChip
