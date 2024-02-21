---
--xcyy
--2018年5月23日
--FortuneTreeBaseDialog.lua

local FortuneTreeBaseDialog = class("FortuneTreeBaseDialog",util_require("Levels.BaseDialog"))

function FortuneTreeBaseDialog:setPlayIdleFunc(func)
    self.m_playIdleFunc = func
end

function FortuneTreeBaseDialog:setPlayOverState(_state)
    self.m_playOverState = _state
end

--待机ccb中配置暂时屏蔽
function FortuneTreeBaseDialog:showidle()
    self.m_status = self.STATUS_IDLE
    if self.m_playIdleFunc then
        self.m_playIdleFunc()
        self.m_playIdleFunc = nil
    end
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
            8
        )
    end

    --循环播放
    self:runCsbAction(self.m_idle_name, true)
end

--结束
function FortuneTreeBaseDialog:showOver(name)
    local overCallFunc = function()
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
                    self.m_callfunc()
                    self.m_callfunc = nil
                end
                self:removeFromParent()
            end,
            time
        )
    end


    if self.m_playOverState and not self.m_machine:checkShareState() then
        self.m_machine:jackpotViewOver(function()
            self.m_playOverState = nil
            overCallFunc()
        end)
    else
        overCallFunc()
    end
end

return FortuneTreeBaseDialog
