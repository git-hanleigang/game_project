---
--xcyy
--2018年5月23日
--MiningManiaFreespinBarView.lua

local MiningManiaFreespinBarView = class("MiningManiaFreespinBarView",util_require("Levels.BaseLevelDialog"))

MiningManiaFreespinBarView.m_freespinCurrtTimes = 0


function MiningManiaFreespinBarView:initUI()

    self:createCsbNode("MiningMania_FreeSpinBar.csb")
    self:runCsbAction("idleframe", true)
end


function MiningManiaFreespinBarView:onEnter()

    MiningManiaFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MiningManiaFreespinBarView:onExit()
    MiningManiaFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MiningManiaFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MiningManiaFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num1"):setString(totaltimes)
end


return MiningManiaFreespinBarView