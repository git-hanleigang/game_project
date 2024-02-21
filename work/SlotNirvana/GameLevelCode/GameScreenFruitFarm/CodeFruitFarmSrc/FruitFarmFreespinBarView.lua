---
--xcyy
--2018年5月23日
--FruitFarmFreespinBarView.lua

local FruitFarmFreespinBarView = class("FruitFarmFreespinBarView",util_require("base.BaseView"))

FruitFarmFreespinBarView.m_freespinCurrtTimes = 0


function FruitFarmFreespinBarView:initUI()

    self:createCsbNode("FruitFarm_FreeSpinNum.csb")
    self:runCsbAction("idle")

end


function FruitFarmFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function FruitFarmFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function FruitFarmFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FruitFarmFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_spin_num"):setString(totaltimes - curtimes)
    self:findChild("m_lb_spin_num_0"):setString(totaltimes)
    
end


return FruitFarmFreespinBarView