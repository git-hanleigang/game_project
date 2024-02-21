---
--xcyy
--2018年5月23日
--SoaringWealthFreespinBarView.lua

local SoaringWealthFreespinBarView = class("SoaringWealthFreespinBarView",util_require("Levels.BaseLevelDialog"))

SoaringWealthFreespinBarView.m_freespinCurrtTimes = 0


function SoaringWealthFreespinBarView:initUI()
    self:createCsbNode("SoaringWealth_FreeSpinBar.csb")
end


function SoaringWealthFreespinBarView:onEnter()

    SoaringWealthFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function SoaringWealthFreespinBarView:onExit()

    SoaringWealthFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function SoaringWealthFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function SoaringWealthFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num0"):setString(totaltimes)
end

return SoaringWealthFreespinBarView
