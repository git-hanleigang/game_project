---
--xcyy
--2018年5月23日
--GhostBlasterFreespinBarView.lua
local GhostBlasterPublicConfig = require "GhostBlasterPublicConfig"
local GhostBlasterFreespinBarView = class("GhostBlasterFreespinBarView", util_require("base.BaseView"))

GhostBlasterFreespinBarView.m_freespinCurrtTimes = 0

function GhostBlasterFreespinBarView:initUI()
    self:createCsbNode("GhostBlaster_freebar.csb")
end

function GhostBlasterFreespinBarView:onEnter()
    GhostBlasterFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(params) -- 显示 freespin count
            self:changeFreeSpinByCount(params)
        end,
        ViewEventType.SHOW_FREE_SPIN_NUM
    )
end

function GhostBlasterFreespinBarView:onExit()
    GhostBlasterFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end

---
-- 更新freespin 剩余次数
--
function GhostBlasterFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(totalFsCount - leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function GhostBlasterFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    self:findChild("m_lb_num"):setString(curtimes)
    self:findChild("m_lb_num_0"):setString(totaltimes)
end

function GhostBlasterFreespinBarView:runIdleAni()
    self:runCsbAction("idleframe")
end

--[[
    反馈动效
]]
function GhostBlasterFreespinBarView:runFeedBackAni(func)
    gLobalSoundManager:playSound(GhostBlasterPublicConfig.Music_Free_Add_Count)
    self:runCsbAction("actionframe",false,function()
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

return GhostBlasterFreespinBarView
