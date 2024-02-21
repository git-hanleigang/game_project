
local HogHustlerDialog = class("HogHustlerDialog", util_require("Levels.BaseDialog"))

--重写
--结束
function HogHustlerDialog:showOver(name)
    if self.isShowOver then
        return
    end
    self.isShowOver = true

    if self.m_btnClickFunc then
        self.m_btnClickFunc()
        self.m_btnClickFunc = nil
    end

    local time
    if self.m_status == self.STATUS_IDLE then
        time = self:getAnimTime(self.m_over_name)
        self:runCsbAction(self.m_over_name)
    else
        self.m_status = self.STATUS_OVER

        if self.m_overRuncallfunc then
            self.m_overRuncallfunc()
            self.m_overRuncallfunc = nil
        end

        if self.m_callfunc then
            self.m_callfunc()
            self.m_callfunc = nil
        end
        self:removeFromParent()
        return
    end
    self.m_status = self.STATUS_OVER
    if not time or time <= 0 or time > 100 then
        time = self.m_overTime
    end
    performWithDelay(
        self,
        function()
            if self.m_overRuncallfunc then
                self.m_overRuncallfunc()
                self.m_overRuncallfunc = nil
            end

            if self.m_callfunc then
                self.m_callfunc(name)
                self.m_callfunc = nil
            end
            self:removeFromParent()
        end,
        time
    )
end

return HogHustlerDialog
