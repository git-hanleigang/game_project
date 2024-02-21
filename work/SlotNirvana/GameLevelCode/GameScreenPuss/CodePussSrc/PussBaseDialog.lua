---
--xcyy
--2018年5月23日
--PussBaseDialog.lua

local PussBaseDialog = class("PussBaseDialog",util_require("Levels.BaseDialog"))

function PussBaseDialog:setOverActBeginCallFunc( func )
    self.m_OverActBeginCallFunc = func
end

function PussBaseDialog:clickFunc(sender)
    local name
    if sender then
        name = sender:getName()
    end
    -- gLobalSoundManager:playSound(self.m_btnTouchSound)
    
    gLobalSoundManager:playSound("PussSounds/music_Puss_Click_Collect.mp3")
    if sender and sender.setTouchEnabled then
        sender:setTouchEnabled(false)
    end
    if  self.m_status==self.STATUS_START or self.m_status==self.STATUS_IDLE or self.m_status==self.STATUS_AUTO then
        self:showOver(name)
    end
end

--结束
function PussBaseDialog:showOver(name)
    local time
    if self.m_status==self.STATUS_IDLE then
        time=self:getAnimTime(self.m_over_name)
        self:runCsbAction(self.m_over_name)
    else
        self.m_status=self.STATUS_OVER
        if self.m_OverActBeginCallFunc then
            self.m_OverActBeginCallFunc()
            self.m_OverActBeginCallFunc = nil
        end

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

    if self.m_OverActBeginCallFunc then
        self.m_OverActBeginCallFunc()
        self.m_OverActBeginCallFunc = nil
    end

    performWithDelay(self,function (  )
        if self.m_callfunc then
            self.m_callfunc()
            self.m_callfunc=nil
        end
        self:removeFromParent()
    end,time)
end



return PussBaseDialog