---
--xcyy
--2018年5月23日
--CharmsBaseDialog.lua

local CharmsBaseDialog = class("CharmsBaseDialog",util_require("Levels.BaseDialog"))


--结束
function CharmsBaseDialog:showOver(name)
    local time
    if self.m_status==self.STATUS_IDLE then
        time=self:getAnimTime(self.m_over_name)
        self:runCsbAction(self.m_over_name)
    else
        self.m_status=self.STATUS_OVER

        util_playFadeOutAction(self,0.2,function(  )
            if self.m_callfunc then
                self.m_callfunc()
                self.m_callfunc=nil
            end
            self:removeFromParent()
        end)
        
        return
    end
    self.m_status=self.STATUS_OVER
    if not time or time<=0 or time>100 then
    	time=self.m_overTime
    end
    util_playFadeOutAction(self,0.2,function(  )
        if self.m_callfunc then
            self.m_callfunc()
            self.m_callfunc=nil
        end
        self:removeFromParent()
    end)
    -- performWithDelay(self,function (  )
        
    -- end,time)
end


return CharmsBaseDialog