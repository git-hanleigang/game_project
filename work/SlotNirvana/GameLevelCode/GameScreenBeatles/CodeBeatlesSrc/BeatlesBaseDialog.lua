---
--xcyy
--2018年5月23日
--BeatlesBaseDialog.lua

local BeatlesBaseDialog = class("BeatlesBaseDialog",util_require("Levels.BaseDialog"))

--开始ccb中配置 暂时屏蔽
function BeatlesBaseDialog:showStart()
    self.m_status = self.STATUS_START
    if self.m_type_name == "FreeSpinOver" then
        self:runCsbAction(self.m_start_name,false,function()
            self.m_machine:setReelSlotsNodeVisible(false)
        end)
    else
        self:runCsbAction(self.m_start_name)
    end
    
    local time = self:getAnimTime(self.m_start_name)

    if not time or time <= 0 then
        time = self.m_startTime
    end

    performWithDelay(
        self,
        function()
            self:showidle()
        end,
        time
    )
end

--结束
function BeatlesBaseDialog:showOver(name)
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
        if self.m_type_name == "FreeSpinOver" then
            self.m_machine:setReelSlotsNodeVisible(true)
            self:runCsbAction(self.m_over_name)
        else
            self:runCsbAction(self.m_over_name)
        end
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

return BeatlesBaseDialog