local CardDropStoreTicket = class("CardDropStoreTicket", BaseView)

function CardDropStoreTicket:initDatas(_ticketType)
    self.m_ticketType = _ticketType
end

function CardDropStoreTicket:getCsbName()
    return "CardsBase201903/CardRes/season201903/cash_drop_storeTicket.csb"
end

function CardDropStoreTicket:getTicketSize()
    return cc.size(100, 60)
end

function CardDropStoreTicket:initCsbNodes()
    self.m_spTicket = self:findChild("sp_ticket")
    self.m_lbTicket = self:findChild("lb_ticket")
end

function CardDropStoreTicket:initUI()
    CardDropStoreTicket.super.initUI(self)

    local ticketPath = "CardsBase201903/CardRes/season201903/Other/store_ticket_" .. self.m_ticketType .. ".png"
    if util_IsFileExist(ticketPath) then
        util_changeTexture(self.m_spTicket, ticketPath)
    end
end

function CardDropStoreTicket:initTickets(_showNum)
    self.m_lbTicket:setVisible(_showNum > 0)
    self.m_lbTicket:setString("X" .. _showNum)
end

function CardDropStoreTicket:playIdle()
    self:runCsbAction("idle", true)
end

function CardDropStoreTicket:startScroll(_over, _addTicketNum)
    self.m_addTicketNum = _addTicketNum
    local normalTickets, goldTickets = self:getStoreTickets()
    if self.m_ticketType == "normal" then
        self.m_totalTickets = normalTickets
    elseif self.m_ticketType == "gold" then
        self.m_totalTickets = goldTickets
    end
    local showNum = self.m_totalTickets - self.m_addTicketNum
    self:initTickets(showNum)
    self:playStart(
        function()
            if not tolua.isnull(self) then
                self:scrollNum(_over)
            end
        end
    )
end

function CardDropStoreTicket:playStart(_over)
    self:runCsbAction(
        "start",
        false,
        function()
            if not tolua.isnull(self) then
                self:playIdle()
                if _over then
                    _over()
                end
            end
        end
    )
end

function CardDropStoreTicket:scrollNum(_over)
    local showNum = self.m_totalTickets - self.m_addTicketNum
    self.m_she =
        util_schedule(
        self,
        function()
            if not tolua.isnull(self) then
                showNum = math.min(showNum + 1, self.m_totalTickets)
                self:initTickets(showNum)
                if showNum >= self.m_totalTickets then
                    if self.m_she ~= nil then
                        self:stopAction(self.m_she)
                        self.m_she = nil
                    end
                    if _over then
                        _over()
                    end
                end
            end
        end,
        1 / 60
    )
end

function CardDropStoreTicket:getStoreTickets()
    local storeData = G_GetMgr(G_REF.CardStore):getRunningData()
    if not storeData then
        return
    end
    return storeData:getNormalChipPoints(), storeData:getGoldenChipPoints()
end

return CardDropStoreTicket
