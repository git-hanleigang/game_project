---
--xcyy
--2018年5月23日
--ClawStallSuperFreespinBarView.lua

local ClawStallSuperFreespinBarView = class("ClawStallSuperFreespinBarView",util_require("Levels.BaseLevelDialog"))

ClawStallSuperFreespinBarView.m_freespinCurrtTimes = 0


function ClawStallSuperFreespinBarView:initUI()

    self:createCsbNode("ClawStall_4Rows_SuperBar.csb")
end


function ClawStallSuperFreespinBarView:onEnter()

    ClawStallSuperFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ClawStallSuperFreespinBarView:onExit()

    ClawStallSuperFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function ClawStallSuperFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ClawStallSuperFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num1_0"):setString(totaltimes)
end

return ClawStallSuperFreespinBarView