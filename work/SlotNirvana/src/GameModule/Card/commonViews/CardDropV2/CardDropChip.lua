--[[--
    掉落界面的卡牌单元，包含卡牌和集卡商城券两个节点
]]
local CardDropChip = class("CardDropChip", BaseView)

function CardDropChip:initDatas(_dropCardData, _cardIndex)
    self.m_cardData = _dropCardData
    self.m_cardIndex = _cardIndex
end

function CardDropChip:getCsbName()
    return "CardsBase201903/CardRes/season201903/DropNew2/chip_cell.csb"
end

function CardDropChip:initCsbNodes()
    self.m_particleChip = self:findChild("Particle_chip")
    self.m_particleStore = self:findChild("Particle_store")
    -- self.m_particleOver = self:findChild("Particle_over")
    
    self:stopChipParticle()
    self:stopStoreParticle()
    self:stopOverParticle()

    self.m_nodeChip = self:findChild("node_chip")
    self.m_nodeTicket = self:findChild("node_ticket")
end

function CardDropChip:stopChipParticle()
    self.m_particleChip:stopSystem()
end

function CardDropChip:stopStoreParticle()
    self.m_particleStore:stopSystem()
end

function CardDropChip:stopOverParticle()
    -- self.m_particleOver:stopSystem()
end

function CardDropChip:resetChipParticle()
    self.m_particleChip:resetSystem()
    self.m_particleChip:setPositionType(0)    
    
end

function CardDropChip:resetStoreParticle()
    self.m_particleStore:resetSystem()
    self.m_particleStore:setPositionType(0)
end

function CardDropChip:resetOverParticle()
    -- self.m_particleOver:resetSystem()
    -- self.m_particleOver:setPositionType(0)
end

function CardDropChip:initUI()
    CardDropChip.super.initUI(self)
    self:initChip()
    self:initStorePoint()

    if globalData.slotRunData.isPortrait == true then
        self:setScale(0.85)
    end    
end

function CardDropChip:initChip()
    self.m_nodeChip:setVisible(false)
    local chip = util_createView("GameModule.Card.season201903.MiniChipUnit")
    self.m_nodeChip:addChild(chip)
    chip:playIdle()
    chip:reloadUI(self.m_cardData, true, true)
    chip:updateTagNew(self.m_cardData.firstDrop == true)
    chip:playAnimByIndex(self.m_cardIndex, self.m_nodeChip, false)
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

function CardDropChip:playChipIdle()
    self:runCsbAction("idle_chip", true, nil, 30)
end

function CardDropChip:playSwitch(_over)
    self:runCsbAction("switch", false, _over, 30)
end

function CardDropChip:playOver(_over)
    self:resetOverParticle()
    if self.m_cardData.firstDrop then
        self:runCsbAction("over_chip", false, _over, 30)
    else
        self:runCsbAction("over_ticket", false, _over, 30)
    end
end

function CardDropChip:getCardData()
    return self.m_cardData
end

function CardDropChip:getViewSize()
    return cc.size(160, 200)
end

return CardDropChip
