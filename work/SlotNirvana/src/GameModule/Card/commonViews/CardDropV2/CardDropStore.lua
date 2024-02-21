--[[--
]]
local CardDropStore = class("CardDropStore", BaseView)

function CardDropStore:initDatas(_normalPoint, _goldenPoint)
    self.m_normalPoint = _normalPoint
    self.m_goldenPoint = _goldenPoint
end

function CardDropStore:getCsbName()
    
    if globalData.slotRunData.isPortrait == true then
        return "CardsBase201903/CardRes/season201903/DropNew2/store_node_shu.csb"
    end
    return "CardsBase201903/CardRes/season201903/DropNew2/store_node.csb"
end

function CardDropStore:initCsbNodes()
    self.m_nodeTickets = {}
    for i=1,2 do
        local nodeTicket = self:findChild("node_ticket_"..i)
        self.m_nodeTickets[i] = nodeTicket
    end
end

function CardDropStore:initUI()
    CardDropStore.super.initUI(self)
    self:initView()
end

function CardDropStore:initView()
    local count = 0
    if self.m_normalPoint and self.m_normalPoint > 0 then
        count = count + 1
        local ticket = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropStoreTicket", "CardsBase201903/CardRes/season201903/DropNew2/store_green.csb", self.m_normalPoint, 60)
        self.m_nodeTickets[count]:addChild(ticket)
        ticket:playIdle()
    end
    if self.m_goldenPoint and self.m_goldenPoint > 0 then
        count = count + 1
        local ticket = util_createView("GameModule.Card.commonViews.CardDropV2.CardDropStoreTicket", "CardsBase201903/CardRes/season201903/DropNew2/store_golden.csb", self.m_goldenPoint, 60)
        self.m_nodeTickets[count]:addChild(ticket)
        ticket:playIdle()
    end
end

function CardDropStore:playFlyto(_over)
    self:runCsbAction("flyto", false, _over, 60)
end

function CardDropStore:playShowTickets(_over)
    self:runCsbAction("ticket", false, _over, 60)
end

return CardDropStore
