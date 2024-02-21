---
--xcyy
--2018年5月23日
--MrJokerCashFreespinBarView.lua

local MrJokerCashFreespinBarView = class("MrJokerCashFreespinBarView",util_require("Levels.BaseLevelDialog"))

MrJokerCashFreespinBarView.m_freespinCurrtTimes = 0


function MrJokerCashFreespinBarView:initUI()
    self:createCsbNode("MrJokerCash_FreeGameBar.csb")
end


function MrJokerCashFreespinBarView:onEnter()

    MrJokerCashFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MrJokerCashFreespinBarView:onExit()

    MrJokerCashFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MrJokerCashFreespinBarView:changeFreeSpinByCount()
    local leftFsCount =  globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MrJokerCashFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("m_lb_num1"):setString(curtimes)
    self:updateLabelSize({label=self:findChild("m_lb_num1"),sx=1,sy=1},46)
    self:findChild("m_lb_num2"):setString(totaltimes)
    self:updateLabelSize({label=self:findChild("m_lb_num2"),sx=1,sy=1},46)
end


return MrJokerCashFreespinBarView