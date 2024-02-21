---
--xcyy
--2018年5月23日
--SpacePupFreespinBarView.lua

local SpacePupFreespinBarView = class("SpacePupFreespinBarView",util_require("Levels.BaseLevelDialog"))

SpacePupFreespinBarView.m_freespinCurrtTimes = 0


function SpacePupFreespinBarView:initUI()

    self:createCsbNode("SpacePup_freebar.csb")

end


function SpacePupFreespinBarView:onEnter()

    SpacePupFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function SpacePupFreespinBarView:onExit()

    SpacePupFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function SpacePupFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function SpacePupFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end


return SpacePupFreespinBarView