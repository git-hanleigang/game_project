---
--xcyy
--2018年5月23日
--ChicEllaFreespinBarView.lua

local ChicEllaFreespinBarView = class("ChicEllaFreespinBarView",util_require("Levels.BaseLevelDialog"))

ChicEllaFreespinBarView.m_freespinCurrtTimes = 0


function ChicEllaFreespinBarView:initUI()

    self:createCsbNode("ChicElla_freebar.csb")

    self:runCsbAction("idle", true)
end


function ChicEllaFreespinBarView:onEnter()
    ChicEllaFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ChicEllaFreespinBarView:onExit()
    ChicEllaFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function ChicEllaFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ChicEllaFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num1"):setString(curtimes)
    self:findChild("m_lb_num2_0"):setString(totaltimes)
end


return ChicEllaFreespinBarView