---
--xcyy
--2018年5月23日
--CactusMariachiSuperFreespinBarView.lua

local CactusMariachiSuperFreespinBarView = class("CactusMariachiSuperFreespinBarView",util_require("Levels.BaseLevelDialog"))

CactusMariachiSuperFreespinBarView.m_freespinCurrtTimes = 0


function CactusMariachiSuperFreespinBarView:initUI()

    self:createCsbNode("CactusMariachi_superfreegamebar.csb")


end


function CactusMariachiSuperFreespinBarView:onEnter()

    CactusMariachiSuperFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function CactusMariachiSuperFreespinBarView:onExit()

    CactusMariachiSuperFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function CactusMariachiSuperFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function CactusMariachiSuperFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
end


return CactusMariachiSuperFreespinBarView