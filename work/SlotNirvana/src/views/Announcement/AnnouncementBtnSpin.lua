--[[--
    游戏公告 按钮
]]
local AnnouncementBtnSpin = class("AnnouncementBtnSpin", BaseView)

function AnnouncementBtnSpin:initUI(_clickFunc)
    self.m_clickFunc = _clickFunc
    AnnouncementBtnSpin.super.initUI(self)
end

function AnnouncementBtnSpin:getCsbName()
    return "Announcement/csb/AnnouncementBtnSpin.csb"
end

function AnnouncementBtnSpin:initCsbNodes()
    self.m_btnSpin = self:findChild("btn_gotospin")
end

function AnnouncementBtnSpin:getBtnSize()
    return self.m_btnSpin:getContentSize()
end

function AnnouncementBtnSpin:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_gotospin" then
        if self.m_clickFunc then
            self.m_clickFunc(name)
        end
    end
end

return AnnouncementBtnSpin
