---
--xcyy
--2018年5月23日
--HowlingMoonFreespinBarView.lua

local HowlingMoonFreespinBarView = class("HowlingMoonFreespinBarView", util_require("base.BaseView"))

HowlingMoonFreespinBarView.m_freespinCurrtTimes = 0

function HowlingMoonFreespinBarView:initUI()
    self:createCsbNode("Socre_HowlingMoon_FreeSpin.csb")
end

function HowlingMoonFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function HowlingMoonFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function HowlingMoonFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount 
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function HowlingMoonFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local leftTimes = totaltimes - curtimes
    self:findChild("lab_cur_time"):setString(leftTimes)
    self:findChild("lab_cur_time_0"):setString(totaltimes)
end

return HowlingMoonFreespinBarView
