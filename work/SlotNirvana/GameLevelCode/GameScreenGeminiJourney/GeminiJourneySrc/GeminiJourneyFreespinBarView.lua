---
--xcyy
--2018年5月23日
--GeminiJourneyFreespinBarView.lua
local GeminiJourneyPublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyFreespinBarView = class("GeminiJourneyFreespinBarView", util_require("base.BaseView"))

GeminiJourneyFreespinBarView.m_freespinCurrtTimes = 0

function GeminiJourneyFreespinBarView:initUI()
    self:createCsbNode("GeminiJourney_FreeSpinBar.csb")

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

function GeminiJourneyFreespinBarView:onEnter()
    GeminiJourneyFreespinBarView.super.onEnter(self)
    gLobalNoticManager:addObserver(self, function(params) -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end, ViewEventType.SHOW_FREE_SPIN_NUM)
end

function GeminiJourneyFreespinBarView:onExit()
    GeminiJourneyFreespinBarView.super.onExit(self)
    gLobalNoticManager:removeAllObservers(self)
end


function GeminiJourneyFreespinBarView:setIsRefresh(_refresh)
    self.m_refresh = _refresh
end

---
-- 更新freespin 剩余次数
--
function GeminiJourneyFreespinBarView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.totalFreeSpinCount - globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self.m_freespinCurrtTimes = leftFsCount
    self:updateFreespinCount(leftFsCount, totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function GeminiJourneyFreespinBarView:updateFreespinCount(curtimes, totaltimes)
    local delayTime = 0
    if self.m_refresh then
        delayTime = 5/60
    end

    local updateCount = function()
        self:findChild("m_lb_num1"):setString(curtimes)
        self:findChild("m_lb_num2"):setString(totaltimes)
    end

    if self.m_refresh then
        self.m_refresh = false
        gLobalSoundManager:playSound(GeminiJourneyPublicConfig.SoundConfig.Music_FgCount_Add)
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("idle", true)
        end)
    end

    performWithDelay(self.m_scWaitNode, function()
        updateCount()
    end, delayTime)
end

return GeminiJourneyFreespinBarView
