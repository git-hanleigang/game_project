--[[--
    邮件页签基类
]]
local BaseView = util_require("base.BaseView")
local InboxPage_base = class("InboxPage_base", BaseView)
function InboxPage_base:initUI(mainClass)
    self.m_mainClass = mainClass
    self:createCsbNode(self:getCsbName())
    self:initView()
end

function InboxPage_base:getMainClass()
    return self.m_mainClass    
end

function InboxPage_base:initView()
end

function InboxPage_base:getCsbName()
    return ""
end

function InboxPage_base:getPageIndex()
    return nil
end

function InboxPage_base:updataInboxItem()
    self.m_mainClass:setTouchStatus(true)
end

function InboxPage_base:clickFunc(sender)
    local name = sender:getName()
end

function InboxPage_base:onEnter()
    gLobalNoticManager:addObserver(self,function()
        if self.updataInboxItem then
            self:updataInboxItem()
        end
    end, ViewEventType.NOTIFY_INBOX_UPDATE_PAGE)
end

function InboxPage_base:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

return InboxPage_base