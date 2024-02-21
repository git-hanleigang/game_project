---
--xcyy
--2018年5月23日
--StarryAnniversaryFreespinBarView.lua
local StarryAnniversaryPublicConfig = require "StarryAnniversaryPublicConfig"
local StarryAnniversaryFreespinBarView = class("StarryAnniversaryFreespinBarView", util_require("base.BaseView"))

StarryAnniversaryFreespinBarView.m_freespinCurrtTimes = 0

function StarryAnniversaryFreespinBarView:initUI()
    self:createCsbNode("StarryAnniversary_FreeGameBar.csb")
end

function StarryAnniversaryFreespinBarView:onEnter()
    StarryAnniversaryFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function StarryAnniversaryFreespinBarView:onExit()
    StarryAnniversaryFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function StarryAnniversaryFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function StarryAnniversaryFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num1_0"):setString(totaltimes)
end

return StarryAnniversaryFreespinBarView
