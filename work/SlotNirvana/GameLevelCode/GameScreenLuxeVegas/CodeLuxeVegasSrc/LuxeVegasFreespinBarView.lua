---
--xcyy
--2018年5月23日
--LuxeVegasFreespinBarView.lua
local LuxeVegasPublicConfig = require "LuxeVegasPublicConfig"
local LuxeVegasFreespinBarView = class("LuxeVegasFreespinBarView", util_require("base.BaseView"))

LuxeVegasFreespinBarView.m_freespinCurrtTimes = 0

function LuxeVegasFreespinBarView:initUI()
    self:createCsbNode("LuxeVegas_FGbar.csb")
    self:runCsbAction("idle", true)
end

function LuxeVegasFreespinBarView:onEnter()
    LuxeVegasFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function LuxeVegasFreespinBarView:onExit()
    LuxeVegasFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function LuxeVegasFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function LuxeVegasFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
end

return LuxeVegasFreespinBarView
