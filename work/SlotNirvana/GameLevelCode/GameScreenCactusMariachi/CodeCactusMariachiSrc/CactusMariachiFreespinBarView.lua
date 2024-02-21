---
--xcyy
--2018年5月23日
--CactusMariachiFreespinBarView.lua

local CactusMariachiFreespinBarView = class("CactusMariachiFreespinBarView",util_require("Levels.BaseLevelDialog"))

CactusMariachiFreespinBarView.m_freespinCurrtTimes = 0


function CactusMariachiFreespinBarView:initUI()

    self:createCsbNode("CactusMariachi_freegamebar.csb")


end


function CactusMariachiFreespinBarView:onEnter()

    CactusMariachiFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function CactusMariachiFreespinBarView:onExit()

    CactusMariachiFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function CactusMariachiFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CactusMariachiFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
end


return CactusMariachiFreespinBarView