---
--xcyy
--2018年5月23日
--FarmMoolahRaidFreespinBarView.lua

local FarmMoolahRaidFreespinBarView = class("FarmMoolahRaidFreespinBarView", util_require("base.BaseView"))

FarmMoolahRaidFreespinBarView.m_freespinCurrtTimes = 0

function FarmMoolahRaidFreespinBarView:initUI()
    self:createCsbNode("FarmMoolahRaid_freebar.csb")
    self:runCsbAction("idle",true)
    self:changeFreeSpinByCount()
end

function FarmMoolahRaidFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function FarmMoolahRaidFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function FarmMoolahRaidFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    leftFsCount = totalFsCount - leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FarmMoolahRaidFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

return FarmMoolahRaidFreespinBarView
