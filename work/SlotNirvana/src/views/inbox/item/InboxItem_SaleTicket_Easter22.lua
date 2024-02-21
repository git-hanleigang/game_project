
--[[
Author: dhs
Date: 2022-03-16 18:29:53
LastEditTime: 2022-03-21 17:21:26
LastEditors: your name
Description: 2022复活节四联优惠券邮件
FilePath: /SlotNirvana/src/views/inbox/InboxItem_SaleTicket_Easter22.lua
--]]

local InboxItem_ticket = util_require("views.inbox.item.InboxItem_ticket")
local InboxItem_SaleTicket_Easter22 = class("InboxItem_SaleTicket_Easter22", InboxItem_ticket)

function InboxItem_SaleTicket_Easter22:getCsbName()
    local csbName = "InBox/InboxItem_SaleTicket_Easter22.csb"
    return csbName
end

function InboxItem_SaleTicket_Easter22:initCsbNodes()
    self.m_sp_all = self:findChild("sp_all")
    -- self.m_sp_part = self:findChild("sp_part")
end

function InboxItem_SaleTicket_Easter22:updateCustomUI()
    local config = globalData.itemsConfig:getCommonTicket(self.m_mailData.ticketId)
    if not config or not config:checkEffective() then --无数据或者过期了
        return
    end
    
    -- self.m_sp_all:setVisible(config.p_num == 75)
    -- self.m_sp_part:setVisible(config.p_num ~= 75)
end

function InboxItem_SaleTicket_Easter22:onEnter()
    gLobalNoticManager:addObserver(self,function(target,params)
        if params.name == ACTIVITY_REF.SaleTicket then
            if not tolua.isnull(self) and self.hideTicket then
                self:hideTicket()
            end
        end
    end, ViewEventType.NOTIFY_ACTIVITY_TIMEOUT)
end

function InboxItem_SaleTicket_Easter22:onExit()
    InboxItem_SaleTicket_Easter22.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

return  InboxItem_SaleTicket_Easter22