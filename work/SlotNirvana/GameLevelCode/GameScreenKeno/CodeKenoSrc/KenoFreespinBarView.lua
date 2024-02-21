---
--xcyy
--2018年5月23日
--KenoFreespinBarView.lua

local KenoFreespinBarView = class("KenoFreespinBarView",util_require("Levels.BaseLevelDialog"))

KenoFreespinBarView.m_freespinCurrtTimes = 0


function KenoFreespinBarView:initUI()
    self:createCsbNode("Keno_FreeSpinBar.csb")
end

function KenoFreespinBarView:onEnter()
    KenoFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function KenoFreespinBarView:onExit()
    KenoFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function KenoFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function KenoFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num2"):setString(totaltimes)
end

return KenoFreespinBarView