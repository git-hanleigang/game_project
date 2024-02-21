---
--xcyy
--2018年5月23日
--MedusaRiseFreespinBar.lua

local MedusaRiseFreespinBar = class("MedusaRiseFreespinBar",util_require("base.BaseView"))

MedusaRiseFreespinBar.m_freespinCurrtTimes = 0


function MedusaRiseFreespinBar:initUI()

    self:createCsbNode("MedusaRise_total.csb")


end


function MedusaRiseFreespinBar:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MedusaRiseFreespinBar:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MedusaRiseFreespinBar:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MedusaRiseFreespinBar:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("lab_Count"):setString(curtimes)
    
end


return MedusaRiseFreespinBar