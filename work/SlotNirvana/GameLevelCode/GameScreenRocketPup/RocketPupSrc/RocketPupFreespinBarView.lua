---
--xcyy
--2018年5月23日
--RocketPupFreespinBarView.lua

local RocketPupFreespinBarView = class("RocketPupFreespinBarView", util_require("base.BaseView"))

RocketPupFreespinBarView.m_freespinCurrtTimes = 0

function RocketPupFreespinBarView:initUI()
    self:createCsbNode("RocketPup_freebar.csb")
    self:runCsbAction("idle",true)
    self:changeFreeSpinByCount()
end

function RocketPupFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function RocketPupFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function RocketPupFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    leftFsCount = totalFsCount - leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function RocketPupFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

return RocketPupFreespinBarView
