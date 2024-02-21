---
--xcyy
--2018年5月23日
--PiggyLegendPirateFreespinBarView.lua

local PiggyLegendPirateFreespinBarView = class("PiggyLegendPirateFreespinBarView",util_require("Levels.BaseLevelDialog"))

PiggyLegendPirateFreespinBarView.m_freespinCurrtTimes = 0


function PiggyLegendPirateFreespinBarView:initUI()
    
    self:createCsbNode("PiggyLegendPirate_freebar.csb")

end

function PiggyLegendPirateFreespinBarView:initViewData(m_machine)
    self.m_machine = m_machine
end

function PiggyLegendPirateFreespinBarView:onEnter()

    PiggyLegendPirateFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function PiggyLegendPirateFreespinBarView:onExit()
    PiggyLegendPirateFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function PiggyLegendPirateFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function PiggyLegendPirateFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    -- self.m_machine.m_runSpinResultData.p_fsExtraData
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData or {}
    local freeType = selfData.freeType
    if freeType and freeType == "COLLECT" then
        self:findChild("Node_free"):setVisible(false)
        self:findChild("Node_superfree"):setVisible(true)
        self:findChild("m_lb_num_super"):setString(curtimes)
        self:findChild("m_lb_num_super_0"):setString(totaltimes)
    else
        self:findChild("Node_free"):setVisible(true)
        self:findChild("Node_superfree"):setVisible(false)
        self:findChild("m_lb_num"):setString(curtimes)
        self:findChild("m_lb_num_0"):setString(totaltimes)
    end
    
    
end


return PiggyLegendPirateFreespinBarView