---
--xcyy
--2018年5月23日
--WestRangerFreespinBarView.lua

local WestRangerFreespinBarView = class("WestRangerFreespinBarView",util_require("Levels.BaseLevelDialog"))

WestRangerFreespinBarView.m_freespinCurrtTimes = 0


function WestRangerFreespinBarView:initUI()

    self:createCsbNode("WestRanger_Freegamebar.csb")

end


function WestRangerFreespinBarView:onEnter()

    WestRangerFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function WestRangerFreespinBarView:onExit()
    WestRangerFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function WestRangerFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function WestRangerFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num_1"):setString(totaltimes)
    
end


return WestRangerFreespinBarView