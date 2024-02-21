--[[
    掉落气泡
]]
local CardDropBubbleUI = class("CardDropBubbleUI", BaseView)

function CardDropBubbleUI:getCsbName()
    return "CardsBase201903/CardRes/season201903/cash_drop_bubble.csb"
end

function CardDropBubbleUI:setKey(_key)
    self.m_key = _key
end

function CardDropBubbleUI:getKey()
    return self.m_key
end

function CardDropBubbleUI:setIndex(_index)
    self.m_index = _index
end

function CardDropBubbleUI:getIndex()
    return self.m_index
end

function CardDropBubbleUI:getBubbleHeight()
    local bgSize = self.m_imgBg:getContentSize()
    local realHeight = bgSize.height * self:getUIScalePro()
    return realHeight
end

function CardDropBubbleUI:initDatas(_cardDatas)
    self.m_cardDatas = _cardDatas
    self.m_addNadoCount = self:getAddNadoCount() or 0

    self.m_chipScale = 0.2
    self.m_chipSize = cc.size(380, 380) -- 要跟 MiniChipUnit:getCardSize() 保持一致
    self.m_offsetWidth = 70 -- 左右两边留下的总像素
    self.m_minWidth = 300 -- 最小尺寸
end

function CardDropBubbleUI:getAddNadoCount()
    local addCount = 0
    for i = 1, #self.m_cardDatas do
        local cardData = self.m_cardDatas[i]
        if cardData.type == CardSysConfigs.CardType.link then
            addCount = addCount + cardData.nadoCount
        end
    end
    return addCount
end

function CardDropBubbleUI:initCsbNodes()
    self.m_imgBg = self:findChild("sp_bubble_di")
    self.m_nodeChips = self:findChild("node_chips")
    self.m_nodeInfo = self:findChild("node_info")
    self.m_lbNado = self:findChild("lb_nado")
end

function CardDropBubbleUI:initUI()
    CardDropBubbleUI.super.initUI(self)
    self:setAutoScaleEnabled(true)
    self:initBg()
    self:initCards()
    self:initNadoGames()
end

function CardDropBubbleUI:initBg()
    local bgSize = self.m_imgBg:getContentSize()
    local cardNum = #self.m_cardDatas
    local cardWidth = cardNum * (self.m_chipSize.width * self.m_chipScale)
    local bgWidth = math.max(self.m_minWidth, cardWidth + self.m_offsetWidth)
    local bgHeight = bgSize.height
    self.m_imgBg:setContentSize(cc.size(bgWidth, bgHeight))
    self.m_nodeInfo:setPositionX(bgWidth / 2)
end

function CardDropBubbleUI:initCards()
    self.m_nodeChips:setPositionY(self.m_addNadoCount > 0 and 0 or -10)

    local UIList = {}
    for i = 1, #self.m_cardDatas do
        local cardData = self.m_cardDatas[i]
        local chip = util_createView("GameModule.Card.season201903.MiniChipUnit")
        chip:setScale(self.m_chipScale)
        chip:playIdle()
        chip:reloadUI(cardData, true, true)
        chip:updateTagNew(cardData.firstDrop == true) -- 改为首次掉落展示new，玩家反馈后优化的
        self.m_nodeChips:addChild(chip)
        local chipSize = chip:getCardSize()
        table.insert(UIList, {node = chip, scale = self.m_chipScale, anchor = cc.p(0.5, 0.5), size = chipSize})
    end
    util_alignCenter(UIList)
end

function CardDropBubbleUI:initNadoGames()
    if self.m_addNadoCount > 0 then
        self.m_lbNado:setVisible(true)
        self.m_lbNado:setString("Nado Spin +" .. self.m_addNadoCount)
    else
        self.m_lbNado:setVisible(false)
    end
end

function CardDropBubbleUI:playStart()
    self:runCsbAction(
        "start",
        false,
        function()
            if not tolua.isnull(self) then
                self:runCsbAction("idle", true, nil, 60)
            end
        end,
        60
    )
end

function CardDropBubbleUI:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

return CardDropBubbleUI
