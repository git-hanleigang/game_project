---
--xcyy
--2018年5月23日
--GhostCaptainFreespinBarView.lua
local PublicConfig = require "GhostCaptainPublicConfig"
local GhostCaptainFreespinBarView = class("GhostCaptainFreespinBarView", util_require("base.BaseView"))

GhostCaptainFreespinBarView.m_freespinCurrtTimes = 0

function GhostCaptainFreespinBarView:initUI()
    self:createCsbNode("GhostCaptain_free_bar.csb")
end

function GhostCaptainFreespinBarView:onEnter()
    GhostCaptainFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function GhostCaptainFreespinBarView:onExit()
    GhostCaptainFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function GhostCaptainFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount --globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function GhostCaptainFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num_0"):setString(curtimes)
    self:findChild("m_lb_num_1"):setString(totaltimes)
end

--[[
    播放增加free次数的效果
]]
function GhostCaptainFreespinBarView:playAddNumsEffect(_func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_GhostCaptain_free_nums_add)
    self:runCsbAction("actionframe", false)
    
    performWithDelay(self,function()
        if _func then
            _func()
        end
    end, 5/60)
end

return GhostCaptainFreespinBarView
