---
--xcyy
--2018年5月23日
--HallowinFreespinBarView.lua

local HallowinFreespinBarView = class("HallowinFreespinBarView",util_require("base.BaseView"))

HallowinFreespinBarView.m_freespinCurrtTimes = 0


function HallowinFreespinBarView:initUI()

    self:createCsbNode("Hallowin_tishitiao_1.csb")
    self:runCsbAction("idle2")

end


function HallowinFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function HallowinFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function HallowinFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function HallowinFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
end


return HallowinFreespinBarView