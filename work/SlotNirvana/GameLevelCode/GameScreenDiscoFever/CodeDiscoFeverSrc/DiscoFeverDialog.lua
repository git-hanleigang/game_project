---
--xcyy
--2018年5月23日
--DiscoFeverDialog.lua

local DiscoFeverDialog = class("DiscoFeverDialog",util_require("Levels.BaseDialog"))

function DiscoFeverDialog:clickFunc(sender)
    local name
    if sender then
        name = sender:getName()
    end
    -- gLobalSoundManager:playSound(self.m_btnTouchSound)

    gLobalSoundManager:playSound("DiscoFeverSounds/DiscoFever_CloseView.mp3")
    
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if  self.m_status==self.STATUS_START or self.m_status==self.STATUS_IDLE or self.m_status==self.STATUS_AUTO then
        self:showOver(name)
    end
end

return DiscoFeverDialog