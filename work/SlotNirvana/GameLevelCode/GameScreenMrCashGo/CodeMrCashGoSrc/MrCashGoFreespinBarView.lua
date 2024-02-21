---
--xcyy
--2018年5月23日
--MrCashGoFreespinBarView.lua

local MrCashGoFreespinBarView = class("MrCashGoFreespinBarView",util_require("Levels.BaseLevelDialog"))

MrCashGoFreespinBarView.m_freespinTotalTimes = 0

function MrCashGoFreespinBarView:initUI()
    self:createCsbNode("MrCashGo_FreeSpinBar.csb")
end


function MrCashGoFreespinBarView:onEnter()

    MrCashGoFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function MrCashGoFreespinBarView:onExit()

    MrCashGoFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function MrCashGoFreespinBarView:changeFreeSpinByCount()
    local leftFsCount  = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MrCashGoFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self.m_freespinTotalTimes = totaltimes
    
    local curTimesLab = self:findChild("m_lb_num_0")
    local totalTimesLab = self:findChild("m_lb_num_1")
    curTimesLab:setString(curtimes)
    totalTimesLab:setString(totaltimes)
end
function MrCashGoFreespinBarView:freeOverResetShow()
    self.m_freespinTotalTimes = 0
end
--[[
    freeMore
]]
function MrCashGoFreespinBarView:playFreeMoreAnim(_fun)
    gLobalSoundManager:playSound("MrCashGoSounds/sound_MrCashGo_freeMore_addTimes.mp3")

    self:runCsbAction("fankui", false, function()
        _fun()
    end)
end
return MrCashGoFreespinBarView