---
--xcyy
--2018年5月23日
--MerryChristmasFreespinBarView.lua

local MerryChristmasFreespinBarView = class("MerryChristmasFreespinBarView", util_require("base.BaseView"))
MerryChristmasFreespinBarView.m_freespinCurrtTimes = 0

function MerryChristmasFreespinBarView:initUI()
    self:createCsbNode("MerryChristmas_freegame_kuang.csb")
    local particle = self:findChild("Particle_1")
    particle:setVisible(false)
end

function MerryChristmasFreespinBarView:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function MerryChristmasFreespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
---
-- 更新freespin 剩余次数
--
function MerryChristmasFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function MerryChristmasFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local nowTimes = totaltimes - curtimes

    self:findChild("BitmapFontLabel_1"):setString(nowTimes)
    self:findChild("BitmapFontLabel_1_0"):setString(totaltimes)
end

function MerryChristmasFreespinBarView:addTotalFreeSpinCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:runCsbAction("actionframe", false)
    local particle = self:findChild("Particle_1")
    particle:setVisible(true)
    particle:resetSystem()
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

return MerryChristmasFreespinBarView
