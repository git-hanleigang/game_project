---
--xcyy
--2018年5月23日
--HogHustlerFreespinBarView.lua

local HogHustlerFreespinBarView = class("HogHustlerFreespinBarView",util_require("Levels.BaseLevelDialog"))

HogHustlerFreespinBarView.m_freespinCurrtTimes = 0


function HogHustlerFreespinBarView:initUI()

    self:createCsbNode("HogHustler_freebar.csb")
    self:runCsbAction("idle", true) -- 播放时间线

end


function HogHustlerFreespinBarView:onEnter()
    HogHustlerFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function HogHustlerFreespinBarView:onExit()
    HogHustlerFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function HogHustlerFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function HogHustlerFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num_2"):setString(totaltimes - curtimes)
    self:findChild("m_lb_num_1"):setString(totaltimes)

end


return HogHustlerFreespinBarView