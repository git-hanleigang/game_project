---
--xcyy
--2018年5月23日
--JuicyHolidayFreespinBarView.lua
local PublicConfig = require "JuicyHolidayPublicConfig"
local JuicyHolidayFreespinBarView = class("JuicyHolidayFreespinBarView", util_require("base.BaseView"))

JuicyHolidayFreespinBarView.m_freespinCurrtTimes = 0

function JuicyHolidayFreespinBarView:initUI()
    self:createCsbNode("JuicyHoliday_freegameBar.csb")
end

function JuicyHolidayFreespinBarView:onEnter()
    JuicyHolidayFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function JuicyHolidayFreespinBarView:onExit()
    JuicyHolidayFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function JuicyHolidayFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function JuicyHolidayFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

return JuicyHolidayFreespinBarView
