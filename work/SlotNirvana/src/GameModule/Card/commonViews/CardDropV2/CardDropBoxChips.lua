--[[
]]
local CardDropBoxChips = class("CardDropBoxChips", BaseView)

function CardDropBoxChips:initDatas(_cardDatas)
    self.m_cardDatas = _cardDatas
end

function CardDropBoxChips:getCsbName()
    return "CardsBase201903/CardRes/season201903/DropNew2/box_chips.csb"
end

function CardDropBoxChips:initCsbNodes()
    self.m_nodeChips = self:findChild("node_chips")
end

function CardDropBoxChips:initUI()
    CardDropBoxChips.super.initUI(self)
    self:initCards()
end

function CardDropBoxChips:initCards()
    local dropCardDatas = CardSysManager:getDropMgr():resetDropCardData(self.m_cardDatas)
    local totalCardNum = #dropCardDatas
    self.m_cardNodes = {}
    for i = 1, totalCardNum do
        local chip = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropChip", dropCardDatas[i], i)
        self.m_nodeChips:addChild(chip, totalCardNum - (i-1))
        table.insert(self.m_cardNodes, chip)   
    end
end

function CardDropBoxChips:getCardNodes()
    return self.m_cardNodes
end

function CardDropBoxChips:playStart(over)
    gLobalSoundManager:playSound(CardResConfig.CARD_MUSIC.CardDropChipAppear)
    self:runCsbAction("open2", false, over, 60)
end

return CardDropBoxChips