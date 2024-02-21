---
--xcyy
--2018年5月23日
--KittysCatchFreespinBarView.lua

local KittysCatchFreespinBarView = class("KittysCatchFreespinBarView",util_require("Levels.BaseLevelDialog"))

KittysCatchFreespinBarView.m_freespinCurrtTimes = 0


function KittysCatchFreespinBarView:initUI()

    self:createCsbNode("KittysCatch_freebar.csb")


end


function KittysCatchFreespinBarView:onEnter()

    KittysCatchFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function KittysCatchFreespinBarView:onExit()

    KittysCatchFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function KittysCatchFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function KittysCatchFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("m_lb_num_1"):setString(totaltimes - curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)

    self:updateLabelSize({label = self:findChild("m_lb_num_1"), sx = 0.75, sy = 0.75}, 58)
    self:updateLabelSize({label = self:findChild("m_lb_num_2"), sx = 0.75, sy = 0.75}, 58)
end


return KittysCatchFreespinBarView