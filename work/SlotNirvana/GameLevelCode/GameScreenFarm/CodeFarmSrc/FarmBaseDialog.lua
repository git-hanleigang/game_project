---
--xcyy
--2018年5月23日
--FarmBaseDialog.lua

local FarmBaseDialog = class("FarmBaseDialog",util_require("Levels.BaseDialog"))


function FarmBaseDialog:setClickSound( path )
    self.m_selfBtnTouchSound = path
end

function FarmBaseDialog:clickFunc(sender)
    local name
    if sender then
        name = sender:getName()
    end

    local name = self.m_selfBtnTouchSound or SOUND_ENUM.MUSIC_BTN_CLICK
    gLobalSoundManager:playSound(name)
    
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if  self.m_status==self.STATUS_START or self.m_status==self.STATUS_IDLE or self.m_status==self.STATUS_AUTO then
        self:showOver(name)
    end
end



return FarmBaseDialog