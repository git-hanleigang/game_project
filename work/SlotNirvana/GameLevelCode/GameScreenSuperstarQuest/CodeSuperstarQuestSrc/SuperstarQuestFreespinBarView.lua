---
--xcyy
--2018年5月23日
--SuperstarQuestFreespinBarView.lua
local PublicConfig = require "SuperstarQuestPublicConfig"
local SuperstarQuestFreespinBarView = class("SuperstarQuestFreespinBarView", util_require("base.BaseView"))

SuperstarQuestFreespinBarView.m_freespinCurrtTimes = 0

function SuperstarQuestFreespinBarView:initUI()
    self:createCsbNode("SuperstarQuest_FreeSpinBar.csb")
end

function SuperstarQuestFreespinBarView:onEnter()
    SuperstarQuestFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function SuperstarQuestFreespinBarView:onExit()
    SuperstarQuestFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function SuperstarQuestFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function SuperstarQuestFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
end

return SuperstarQuestFreespinBarView
