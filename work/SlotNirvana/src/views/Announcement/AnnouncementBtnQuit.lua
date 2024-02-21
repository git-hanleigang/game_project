--[[--
    游戏公告 按钮
]]
local AnnouncementBtnQuit = class("AnnouncementBtnQuit", BaseView)

function AnnouncementBtnQuit:initUI(_clickFunc)
    self.m_clickFunc = _clickFunc
    AnnouncementBtnQuit.super.initUI(self)
end

function AnnouncementBtnQuit:getCsbName()
    return "Announcement/csb/AnnouncementBtnQuit.csb"
end

function AnnouncementBtnQuit:initCsbNodes()
    self.m_btnQuit = self:findChild("btn_quit")
end

function AnnouncementBtnQuit:getBtnSize()
    return self.m_btnQuit:getContentSize()
end

function AnnouncementBtnQuit:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_quit" then
        if self.m_clickFunc then
            self.m_clickFunc(name)
        end
    end
end

return AnnouncementBtnQuit
