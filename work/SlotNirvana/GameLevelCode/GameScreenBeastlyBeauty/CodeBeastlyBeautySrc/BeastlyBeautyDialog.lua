---
--xcyy
--2018年5月23日
--FruitFarmView.lua

local BeastlyBeautyDialog = class("BeastlyBeautyDialog",util_require("Levels.BaseDialog"))

BeastlyBeautyDialog.m_tanbanOverSound = nil

function BeastlyBeautyDialog:clickFunc(sender)
    if not self.m_allowClick then
        return
    end

    local name
    if sender then
        name = sender:getName()
    end
    gLobalSoundManager:playSound(self.m_btnTouchSound)
    if self.m_tanbanOverSound then
        gLobalSoundManager:playSound(self.m_tanbanOverSound)
    end

    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if self.m_status == self.STATUS_START or self.m_status == self.STATUS_IDLE or self.m_status == self.STATUS_AUTO then
        self:showOver(name)
    end
end

return BeastlyBeautyDialog