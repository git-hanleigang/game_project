---
--xcyy
--2018年5月23日
--SaharaTreasureFreespinBarView.lua

local SaharaTreasureFreespinBarView = class("SaharaTreasureFreespinBarView",util_require("base.BaseView"))

SaharaTreasureFreespinBarView.m_freespinCurrtTimes = 0


function SaharaTreasureFreespinBarView:initUI()

    self:createCsbNode("SaharaTreasure_FS_cishu.csb")


end


function SaharaTreasureFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function SaharaTreasureFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function SaharaTreasureFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function SaharaTreasureFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
end


return SaharaTreasureFreespinBarView