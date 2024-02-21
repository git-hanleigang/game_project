---
--xcyy
--GeminiJourneyRespinBarView.lua

local PublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyRespinBarView = class("GeminiJourneyRespinBarView", util_require("Levels.BaseLevelDialog"))

GeminiJourneyRespinBarView.m_respinTotalTimes = 3
GeminiJourneyRespinBarView.m_respinIsPlayAni = true

function GeminiJourneyRespinBarView:initUI()
    self:createCsbNode("GeminiJourney_ReSpinBar.csb")

    self:runCsbAction("idle", true)
    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self.m_countNodeTbl = {}
    for i=1, self.m_respinTotalTimes do
        self.m_countNodeTbl[i] = self:findChild("active"..i)
    end
end

function GeminiJourneyRespinBarView:onEnter()
    gLobalNoticManager:addObserver(self, function()
        -- 显示 freespin count
        self:updateLeftCount(globalData.slotRunData.iReSpinCount, false)
    end, ViewEventType.SHOW_RESPIN_SPIN_NUM)
end

function GeminiJourneyRespinBarView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

-- 停轮动画
function GeminiJourneyRespinBarView:completeAni(_onEnter)
    util_resetCsbAction(self.m_csbAct)
    if _onEnter then
        self:runCsbAction("idle1", true)
    else
        self:runCsbAction("switch", false, function()
            self:runCsbAction("idle1", true)
        end)
    end
end

-- 开始出现动画
function GeminiJourneyRespinBarView:startShowAni(_isShow, _isStart)
    util_resetCsbAction(self.m_csbAct)
    self:setVisible(_isShow)
    if _isShow then
        if _isStart then
            self:runCsbAction("start", false, function()
                self:runCsbAction("idle", true)
            end)
        else
            self:runCsbAction("idle", true)
        end
    end
end

-- 消失动画
function GeminiJourneyRespinBarView:closeBarAni()
    self.m_respinIsPlayAni = true
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

-- 更新 respin 次数
function GeminiJourneyRespinBarView:updateLeftCount(respinCount, totalRespinCount, _isStart)
    self:runCsbAction("idle", true)
    util_resetCsbAction(self.m_csbAct)
    for i=1, self.m_respinTotalTimes do
        if respinCount >= i then
            self.m_countNodeTbl[i]:setVisible(true)
        else
            self.m_countNodeTbl[i]:setVisible(false)
        end
    end

    if respinCount == self.m_respinTotalTimes and self.m_respinIsPlayAni and not _isStart then
        self.m_respinIsPlayAni = false
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.Music_RespinCount_Add)
        self:runCsbAction("actionframe", false, function()
            self:runCsbAction("idle", true)
        end)
    end

    if respinCount < self.m_respinTotalTimes then
        self.m_respinIsPlayAni = true
    end
end

return GeminiJourneyRespinBarView
