---
--xcyy
--2018年5月23日
--TurkeyDayFreespinBarView.lua
local PublicConfig = require "TurkeyDayPublicConfig"
local TurkeyDayFreespinBarView = class("TurkeyDayFreespinBarView", util_require("base.BaseView"))

TurkeyDayFreespinBarView.m_freespinCurrtTimes = 0

function TurkeyDayFreespinBarView:initUI()
    self:createCsbNode("TurkeyDay_free_spinbar.csb")
end

function TurkeyDayFreespinBarView:onEnter()
    TurkeyDayFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function TurkeyDayFreespinBarView:onExit()
    TurkeyDayFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

function TurkeyDayFreespinBarView:setFreeAni(_isFreeMore)
    self.m_isFreeMore = _isFreeMore
end

---
-- 更新freespin 剩余次数
--
function TurkeyDayFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function TurkeyDayFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_1"):setString(curtimes)
    self:findChild("m_lb_num_2"):setString(totaltimes)

    if self.m_isFreeMore then
        self.m_isFreeMore = false
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_FgTime_Add)
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("idle", true)
        end)
    end
end

return TurkeyDayFreespinBarView
