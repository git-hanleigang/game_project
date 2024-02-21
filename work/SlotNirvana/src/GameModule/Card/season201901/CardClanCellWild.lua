--[[
    author:{author}
    time:2019-07-08 14:28:18
]]
local BaseView = util_require("base.BaseView")
local CardClanCellWild = class(CardClanCellWild, BaseView)
function CardClanCellWild:initUI()
    self:createCsbNode(CardResConfig.CardClanViewWildNodeRes)
    self.m_cardsNode = self:findChild("Node_cards")
    self.m_pizzleHouseNode = self:findChild("Node_pizzleHouse")
end

function CardClanCellWild:getClanData()
    local clansData = CardSysRuntimeMgr:getAlbumTalbeviewData()
    return clansData  and clansData[self.m_index]
end

function CardClanCellWild:updateCell(index)
    self.m_index = index
    self.m_clanData = self:getClanData()

    self:updateCards()
    self:updatePuzzleHouse()
end

function CardClanCellWild:updateCards()
    local child = self.m_cardsNode:getChildByName("CARDS")
    if not child then
        -- 方便以后扩展成多个
        child = util_createView("GameModule.Card.season201901.CardClanCellWildCard")
        child:setName("CARDS")
        self.m_cardsNode:addChild(child)
    end
    child:updateCards(self.m_clanData)
end

function CardClanCellWild:updatePuzzleHouse()
    local child = self.m_pizzleHouseNode:getChildByName("PIZZLEHOUSE")
    if not child then
        -- 方便以后扩展成多个
        child = util_createView("GameModule.Card.views.CardSeasonCellPuzzleHouse")
        child:setName("PIZZLEHOUSE")
        self.m_pizzleHouseNode:addChild(child)
    end
    child:updateHouse(self.m_clanData.albumId)
end


return CardClanCellWild