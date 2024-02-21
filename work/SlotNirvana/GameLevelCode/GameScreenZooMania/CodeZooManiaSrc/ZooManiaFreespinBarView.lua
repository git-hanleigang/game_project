---
--xcyy
--2018年5月23日
--ZooManiaFreespinBarView.lua

local ZooManiaFreespinBarView = class("ZooManiaFreespinBarView",util_require("base.BaseView"))

ZooManiaFreespinBarView.m_freespinCurrtTimes = 0


function ZooManiaFreespinBarView:initUI()

    self:createCsbNode("ZooMania_freecishu.csb")


end

function ZooManiaFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ZooManiaFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function ZooManiaFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ZooManiaFreespinBarView:updateFreespinCount( leftCount,totaltimes )
    
    self:findChild("m_lb_num"):setString(leftCount)
    self:findChild("m_lb_num_0"):setString(totaltimes)
    
end

return ZooManiaFreespinBarView