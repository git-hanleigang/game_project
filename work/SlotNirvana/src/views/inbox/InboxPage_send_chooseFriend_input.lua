--[[--

]]
local InboxPage_send_chooseFriend_input = class("InboxPage_send_chooseFriend_input")
function InboxPage_send_chooseFriend_input:ctor(mainClass)
    self.m_mainClass = mainClass
end

function InboxPage_send_chooseFriend_input:initTextField(textField)
    self.m_TextField = textField
    self:registerListener()
end

function InboxPage_send_chooseFriend_input:setString(txt)
    if self.m_mailText then
        self.m_mailText:setText(txt)
        -- 刷新界面
        self:updateMainUI()
    elseif self.m_TextField then
        self.m_TextField:setString(txt)
        -- 刷新界面
        self:updateMainUI()
    end
end

function InboxPage_send_chooseFriend_input:getString()
    if self.m_mailText then
        return self.m_mailText:getText()
    elseif self.m_TextField then
        return self.m_TextField:getString()
    end
end

function InboxPage_send_chooseFriend_input:registerListener()
    -- self.m_TextField:addEventListener(function(sender, eventType)
    --     local event = {}
    --     if eventType == 0 then
    --         event.name = "ATTACH_WITH_IME"
    --     elseif eventType == 1 then
    --         event.name = "DETACH_WITH_IME"
    --     elseif eventType == 2 then
    --         event.name = "INSERT_TEXT"
    --     elseif eventType == 3 then
    --         event.name = "DELETE_BACKWARD"
    --     end
    --     event.target = sender
    --     self:inputCallback(event)
    -- end)

    self.m_mailText = util_convertTextFiledToEditBox(self.m_TextField, nil, function (strEventName,sender)
        if strEventName == "began" then 
        elseif strEventName == "ended" then 
        elseif strEventName == "return" then 
        elseif strEventName == "changed" then 
            self:inputCallback()
        end
    end) 
    self.m_TextField:setVisible(false)
end

function InboxPage_send_chooseFriend_input:inputCallback(event)
    -- if event.name == "ATTACH_WITH_IME" then
        
    -- elseif event.name == "DETACH_WITH_IME" then
    -- elseif event.name == "INSERT_TEXT" then
    --     -- 刷新界面
    --     self:updateMainUI()
    -- elseif event.name == "DELETE_BACKWARD" then
    --     -- 刷新界面
    --     self:updateMainUI()
    -- end
    -- 刷新界面
    self:updateMainUI()
end

function InboxPage_send_chooseFriend_input:updateMainUI()
    if self.m_mainClass then
        self.m_mainClass:updateInputDefaultText()
        self.m_mainClass:resetFriendList()
        self.m_mainClass:updateFriendList()
    end
end

return InboxPage_send_chooseFriend_input