---
--xcyy
--2018年5月23日
--VegasLifeBaseDialog.lua

local VegasLifeBaseDialog = class("VegasLifeBaseDialog",util_require("Levels.BaseDialog"))



--待机ccb中配置暂时屏蔽
function VegasLifeBaseDialog:showidle()
    self.m_status = self.STATUS_IDLE
    --auto 2
    if self.m_autoType and self.m_autoType == BaseDialog.AUTO_TYPE_NOMAL then
        self:runCsbAction(self.m_idle_name)
        local time = self:getAnimTime(self.m_idle_name)
        if not time or time <= 0 then
            time = self.m_idleTime
        end
        performWithDelay(
            self,
            function()
                self:showOver()
            end,
            time
        )
        return
    elseif globalData.slotRunData.m_isNewAutoSpin and globalData.slotRunData.m_isAutoSpinAction then
        performWithDelay(
            self,
            function()
                self:showOver()
            end,
            4
        )
    end

    --循环播放
    self:runCsbAction(self.m_idle_name, true)
end

return VegasLifeBaseDialog