---
--xcyy
--2018年5月23日
--MoneyBallFreespinBarView.lua

local MoneyBallFreespinBarView = class("MoneyBallFreespinBarView",util_require("base.BaseView"))

MoneyBallFreespinBarView.m_freespinCurrtTimes = 0


function MoneyBallFreespinBarView:initUI()
    self:createCsbNode("MoneyBall_tishitiao.csb")
end

function MoneyBallFreespinBarView:updateTip()
    self:runCsbAction("idle3", true)
end

function MoneyBallFreespinBarView:stopUpdate()
    self:runCsbAction("idle1")
end

function MoneyBallFreespinBarView:showFsTime()
    self:runCsbAction("idle2")
    self:changeFreeSpinByCount()
end

function MoneyBallFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MoneyBallFreespinBarView:onExit()

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MoneyBallFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MoneyBallFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("lab_curr"):setString(curtimes)
    self:findChild("lab_total"):setString(totaltimes)
end


return MoneyBallFreespinBarView