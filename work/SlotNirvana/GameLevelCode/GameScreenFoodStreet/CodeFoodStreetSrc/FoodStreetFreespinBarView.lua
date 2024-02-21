---
--xcyy
--2018年5月23日
--FoodStreetFreespinBarView.lua

local FoodStreetFreespinBarView = class("FoodStreetFreespinBarView",util_require("base.BaseView"))

FoodStreetFreespinBarView.m_freespinCurrtTimes = 0


function FoodStreetFreespinBarView:initUI()

    self:createCsbNode("FoodStreet_tishikuang.csb")


end


function FoodStreetFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function FoodStreetFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function FoodStreetFreespinBarView:changeFreeSpinByCount()
    local leftFsCount =  globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function FoodStreetFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_cur"):setString(curtimes)
    self:findChild("m_lb_total"):setString(totaltimes)
    
end


return FoodStreetFreespinBarView