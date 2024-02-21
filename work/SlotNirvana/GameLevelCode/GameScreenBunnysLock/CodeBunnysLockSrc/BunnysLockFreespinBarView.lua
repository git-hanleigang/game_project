---
--xcyy
--2018年5月23日
--BunnysLockFreespinBarView.lua

local BunnysLockFreespinBarView = class("BunnysLockFreespinBarView",util_require("Levels.BaseLevelDialog"))

BunnysLockFreespinBarView.m_freespinCurrtTimes = 0


function BunnysLockFreespinBarView:initUI()

    self:createCsbNode("BunysLock_free_kuang.csb")

    self.m_totalTimes = 0
end


function BunnysLockFreespinBarView:onEnter()

    BunnysLockFreespinBarView.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)

end

function BunnysLockFreespinBarView:onExit()
    BunnysLockFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)

end

---
-- 更新freespin 剩余次数
--
function BunnysLockFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount -- globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount 
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function BunnysLockFreespinBarView:updateFreespinCount( curtimes,totaltimes )
    
    self:findChild("free_zi_3"):setString(totaltimes)
    self:findChild("free_zi_4"):setString(totaltimes - curtimes)

    if self.m_totalTimes < totaltimes and self.m_totalTimes ~= 0 then
        gLobalSoundManager:playSound("BunnysLockSounds/sound_BunnysLock_fg_times_add.mp3")
        self:runCsbAction("actionframe")
    end
    self.m_totalTimes = totaltimes

    self:updateLabelSize({label=self:findChild("free_zi_3"),sx=1,sy=1},44)
    self:updateLabelSize({label=self:findChild("free_zi_4"),sx=1,sy=1},44)
end


return BunnysLockFreespinBarView