--[[--
    游戏公告 按钮
]]
local AnnouncementBtnFanpage = class("AnnouncementBtnFanpage", BaseView)

function AnnouncementBtnFanpage:initUI(_clickFunc)
    self.m_clickFunc = _clickFunc
    AnnouncementBtnFanpage.super.initUI(self)
end

function AnnouncementBtnFanpage:getCsbName()
    return "Announcement/csb/AnnouncementBtnFanpage.csb"
end

function AnnouncementBtnFanpage:initCsbNodes()
    self.m_btnFanpage = self:findChild("btn_fanpage")
end

function AnnouncementBtnFanpage:getBtnSize()
    return self.m_btnFanpage:getContentSize()
end

function AnnouncementBtnFanpage:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_fanpage" then
        if self.m_clickFunc then
            self.m_clickFunc(name)
        end
    end
end

return AnnouncementBtnFanpage
