---
--xcyy
--2018年5月23日
--ThorsStrikeFreespinBarView.lua

local ThorsStrikeFreespinBarView = class("ThorsStrikeFreespinBarView",util_require("Levels.BaseLevelDialog"))

ThorsStrikeFreespinBarView.m_freespinCurrtTimes = 0


function ThorsStrikeFreespinBarView:initUI()
    self:createCsbNode("FreeSpinBar.csb")
end


function ThorsStrikeFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function ThorsStrikeFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function ThorsStrikeFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function ThorsStrikeFreespinBarView:updateFreespinCount( curtimes,totaltimes )
  self:findChild("m_lb_num_0"):setString(totaltimes-curtimes)
  self:findChild("m_lb_num_1"):setString(totaltimes)
end


return ThorsStrikeFreespinBarView