--[[
    author:{author}
    time:2021-09-28 14:22:08
]]
local SaleTicketMgr = class("SaleTicketMgr", BaseActivityControl)

function SaleTicketMgr:ctor()
    SaleTicketMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.SaleTicket)

    self.m_useNewPath = {
        ["Activity_SaleTicket_AUDay"] = true,
    }
end

function SaleTicketMgr:getPopPath(popName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return themeName .. "/" .. popName
    else
        return SaleTicketMgr.super.getPopPath(self, popName)
    end
end

function SaleTicketMgr:getHallPath(hallName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return themeName .. "/" .. hallName .. "HallNode"
    else
        return SaleTicketMgr.super.getHallPath(self, hallName)
    end
end

function SaleTicketMgr:getSlidePath(slideName)
    local themeName = self:getThemeName()
    if self.m_useNewPath[themeName] then
        return themeName .. "/" .. slideName .. "SlideNode"
    else
        return SaleTicketMgr.super.getSlidePath(self, slideName)
    end    
end

return SaleTicketMgr
