---
--xcyy
--2018年5月23日
--PiggyLegendTreasureFreespinBarView.lua

local PiggyLegendTreasureFreespinBarView = class("PiggyLegendTreasureFreespinBarView",util_require("Levels.BaseLevelDialog"))

PiggyLegendTreasureFreespinBarView.m_freespinCurrtTimes = 0


function PiggyLegendTreasureFreespinBarView:initUI(machine)
    
    self:createCsbNode("PiggyLegendTreasure_freebar.csb")

end

function PiggyLegendTreasureFreespinBarView:initMachine(machine)
    self.machine = machine
    self.m_baoZha = util_createAnimation("PiggyLegendTreasure_freebar_fankui.csb")
    self:findChild("Node_2"):addChild(self.m_baoZha)
    self.m_baoZha:runCsbAction("idle",false)
end

function PiggyLegendTreasureFreespinBarView:onEnter()

    PiggyLegendTreasureFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function PiggyLegendTreasureFreespinBarView:onExit()

    PiggyLegendTreasureFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function PiggyLegendTreasureFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function PiggyLegendTreasureFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    --最后一次 free 
    -- if curtimes == totaltimes then
    --     self.machine:showFreeFinallyQiPan()
    -- end
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
    
end


return PiggyLegendTreasureFreespinBarView