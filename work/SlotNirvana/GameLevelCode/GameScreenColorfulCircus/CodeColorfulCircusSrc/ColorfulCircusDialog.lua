
local ColorfulCircusDialog = class("ColorfulCircusDialog", util_require("Levels.BaseDialog"))

--重写 修改只有不是start可以点击
function ColorfulCircusDialog:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name
    if sender then
        name = sender:getName()
    end

    --改
    if self.m_status == self.STATUS_START then
        return
    end


    gLobalSoundManager:playSound(self.m_btnTouchSound)

    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if self.m_status == self.STATUS_START or self.m_status == self.STATUS_IDLE or self.m_status == self.STATUS_AUTO then
        self:showOver(name)
    end
end

function ColorfulCircusDialog:showStart()

    local button = self:findChild("Button_1")
    if button then
        if button and button.setTouchEnabled then
            button:setTouchEnabled(false)
        end
    end
    ColorfulCircusDialog.super.showStart(self)
end

function ColorfulCircusDialog:showidle()
    local button = self:findChild("Button_1")
    if button then
        if button and button.setTouchEnabled then
            button:setTouchEnabled(true)
        end
    end
    ColorfulCircusDialog.super.showidle(self)
end

return ColorfulCircusDialog
