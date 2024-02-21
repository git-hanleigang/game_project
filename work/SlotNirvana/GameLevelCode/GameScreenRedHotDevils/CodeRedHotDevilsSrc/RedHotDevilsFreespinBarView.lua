---
--xcyy
--2018年5月23日
--RedHotDevilsFreespinBarView.lua

local RedHotDevilsFreespinBarView = class("RedHotDevilsFreespinBarView",util_require("Levels.BaseLevelDialog"))

RedHotDevilsFreespinBarView.m_freespinCurrtTimes = 0


function RedHotDevilsFreespinBarView:initUI()

    self:createCsbNode("RedHotDevils_freegameBar.csb")

end


function RedHotDevilsFreespinBarView:onEnter()

    RedHotDevilsFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function RedHotDevilsFreespinBarView:onExit()

    RedHotDevilsFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function RedHotDevilsFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function RedHotDevilsFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("m_lb_num_2"):setString(curtimes)
    self:findChild("m_lb_num_1"):setString(totaltimes)
end


return RedHotDevilsFreespinBarView