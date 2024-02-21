---
--xcyy
--2018年5月23日
--MasterStampFreespinBarView.lua

local MasterStampFreespinBarView = class("MasterStampFreespinBarView", util_require("base.BaseView"))

MasterStampFreespinBarView.m_freespinCurrtTimes = 0

function MasterStampFreespinBarView:initUI()
    self:createCsbNode("MasterStamp_FreeGameTime.csb")
    self:runCsbAction("idle",true)
    self:changeFreeSpinByCount()
end

function MasterStampFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function MasterStampFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function MasterStampFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    leftFsCount = totalFsCount - leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MasterStampFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("Alice_cishu_left"):setString(curtimes)
    self:findChild("Alcie_cishu_total"):setString(totaltimes)
end

return MasterStampFreespinBarView
