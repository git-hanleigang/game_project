--[[
]]
local CardDropStoreTicket = class("CardDropStoreTicket", BaseView)

function CardDropStoreTicket:initDatas(_csbName, _num)
    self.m_csbName = _csbName
    self.m_num = _num
end

function CardDropStoreTicket:getCsbName()
    return self.m_csbName
end

function CardDropStoreTicket:getTicketSize()
    return cc.size(100, 60)
end

function CardDropStoreTicket:initCsbNodes()
    self.m_lbNum = self:findChild("lb_num")
end

function CardDropStoreTicket:initUI()
    CardDropStoreTicket.super.initUI(self)
    self:initView()
end

function CardDropStoreTicket:initView()
    self.m_lbNum:setString("X"..self.m_num)
end

function CardDropStoreTicket:playStart(_over)
    self:runCsbAction("start", false, _over, 30)
end

function CardDropStoreTicket:playIdle()
    self:runCsbAction("idle", true, nil, 30)
end

return CardDropStoreTicket