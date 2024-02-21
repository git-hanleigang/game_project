---
--xcyy
--2018年5月23日
--FourInOneBaseDialog.lua

local FourInOneBaseDialog = class("FourInOneBaseDialog",util_require("Levels.BaseDialog"))



function FourInOneBaseDialog:clickFunc(sender)
    local name
    if sender then
        name = sender:getName()
    end
    -- gLobalSoundManager:playSound(self.m_btnTouchSound)


    if self.m_status == self.STATUS_START then
        return
    end
    
    gLobalSoundManager:playSound("FourInOneSounds/music_FourInOnes_Click_Collect.mp3")
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if  self.m_status==self.STATUS_START or self.m_status==self.STATUS_IDLE or self.m_status==self.STATUS_AUTO then
        self:showOver(name)
    end
end

--结束
function FourInOneBaseDialog:showOver(name)
    local time
    if self.m_status==self.STATUS_IDLE then
        time=self:getAnimTime(self.m_over_name)
        self:runCsbAction(self.m_over_name)
    else
        self.m_status=self.STATUS_OVER
        if self.m_callfunc then
            self.m_callfunc()
            self.m_callfunc=nil
        end
        self:removeFromParent()
        return
    end
    self.m_status=self.STATUS_OVER
    if not time or time<=0 or time>100 then
    	time=self.m_overTime
    end
    performWithDelay(self,function (  )
        if self.m_callfunc then
            self.m_callfunc()
            self.m_callfunc=nil
        end
        self:removeFromParent()
    end,time)
end


return FourInOneBaseDialog