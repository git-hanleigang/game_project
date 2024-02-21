---
--xcyy
--2018年5月23日
--GoldMarmotFreespinBarView.lua

local GoldMarmotFreespinBarView = class("GoldMarmotFreespinBarView",util_require("Levels.BaseLevelDialog"))

GoldMarmotFreespinBarView.m_freespinCurrtTimes = 0


function GoldMarmotFreespinBarView:initUI()

    self:createCsbNode("GoldMarmot_freebar.csb")


end


function GoldMarmotFreespinBarView:onEnter()

    GoldMarmotFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function GoldMarmotFreespinBarView:onExit()

    GoldMarmotFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function GoldMarmotFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function GoldMarmotFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_0"):setString(totaltimes - curtimes)
    self:findChild("m_lb_num_0_0"):setString(totaltimes)
    
end


return GoldMarmotFreespinBarView