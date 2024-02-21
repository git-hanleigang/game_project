--[[

    author:{author}
    time:2022-01-24 11:26:27
]]
local BaseMenuItem = class("BaseMenuItem", util_require("base.BaseView"))

function BaseMenuItem:initUI(bDeluxe)
    self:createCsbNode("Option/OptionsMenu_item.csb")

    self:initView(bDeluxe)
end

function BaseMenuItem:initCsbNodes()
    self.m_palItem = self:findChild("panel_item")
    self:addClick(self.m_palItem)
    -- self.m_btnItem = self:findChild("btn_item")
    self.m_spItemN = self:findChild("sp_item_n")
    self.m_spItemD = self:findChild("sp_item_d")
    self.m_spContact = self:findChild("sprite_contact")
    self.m_spContact:setVisible(false)
    self.m_labNum = self:findChild("label_message_num")
    self.m_spLine = self:findChild("sp_line")
    self.m_spLine:setVisible(false)
    self:setClickState(false)
end

function BaseMenuItem:initView(bDeluxe)
    if bDeluxe then
        util_changeTexture(self.m_spLine, "Option/ui/option_club_line.png")
    else
        util_changeTexture(self.m_spLine, "Option/ui/option_bg_line.png")
    end
end

function BaseMenuItem:setClickState(isClick)
    self.m_spItemN:setVisible(not isClick)
    self.m_spItemD:setVisible(isClick)
end

function BaseMenuItem:getItemSize()
    if self.m_palItem then
        return self.m_palItem:getContentSize()
    else
        return nil
    end
end

function BaseMenuItem:setLineVisible(isVisible)
    self.m_spLine:setVisible(isVisible or false)
end

function BaseMenuItem:clickFunc(sender)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_MENUNODE_OPEN)
end

function BaseMenuItem:updateNewMessageUi(nNum)
    nNum = nNum or 0
    local status = false
    if nNum > 0 then
        status = true
    end
    self.m_spContact:setVisible(status)
    if status and nNum > 0 then
        self.m_labNum:setString(tostring(nNum))
    end
end

function BaseMenuItem:clickStartFunc(sender)
    self:setClickState(true)
end

function BaseMenuItem:clickEndFunc(sender)
    self:setClickState(false)
end

return BaseMenuItem
