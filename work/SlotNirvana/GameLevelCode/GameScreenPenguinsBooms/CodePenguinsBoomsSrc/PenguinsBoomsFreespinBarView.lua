--free计数栏
local PenguinsBoomsFreespinBarView = class("PenguinsBoomsFreespinBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "PenguinsBoomsPublicConfig"

PenguinsBoomsFreespinBarView.m_freespinCurrtTimes = 0


function PenguinsBoomsFreespinBarView:initUI()

    self:createCsbNode("PenguinsBooms_free_bar.csb")


end


function PenguinsBoomsFreespinBarView:onEnter()

    PenguinsBoomsFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)
end

function PenguinsBoomsFreespinBarView:onExit()
    PenguinsBoomsFreespinBarView.super.onExit(self)

    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function PenguinsBoomsFreespinBarView:changeFreeSpinByCount()
    local leftFsCount  = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function PenguinsBoomsFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    self.m_freespinCurrtTimes = curtimes

    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)
end

-- freeMore
function PenguinsBoomsFreespinBarView:playFreeMoreAnim(_totalTimes, _fun)
    self:runCsbAction("actionframe", false, _fun)

    performWithDelay(self,function()
        gLobalSoundManager:playSound(PublicConfig.sound_PenguinsBooms_freeBar_add_2)
        self:updateFreespinCount(self.m_freespinCurrtTimes, _totalTimes)
    end, 54/60)
end

return PenguinsBoomsFreespinBarView