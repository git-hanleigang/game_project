---
--xcyy
--GeminiJourneyRespinLockView.lua

local PublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyRespinLockView = class("GeminiJourneyRespinLockView", util_require("Levels.BaseLevelDialog"))

function GeminiJourneyRespinLockView:initUI(_index)
    self:createCsbNode("GeminiJourney_ReSpin_lock.csb")

    self.m_curIndex = _index
    self:runCsbAction("idle", true)

    self:initLockMoreState()
end

-- 初始化锁定栏上more的个数
function GeminiJourneyRespinLockView:initLockMoreState()
    self:findChild("sp_more_1"):setVisible(self.m_curIndex == 1)
    self:findChild("sp_more_2"):setVisible(self.m_curIndex == 2)
end

-- 设置最上方锁定栏上more的个数
function GeminiJourneyRespinLockView:setLockMoreState()
    self:findChild("sp_more_1"):setVisible(true)
    self:findChild("sp_more_2"):setVisible(false)
end

-- 开始上锁
function GeminiJourneyRespinLockView:startPlayLockAni()
    self:setVisible(true)
    self:initLockMoreState()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("lock", false, function()
        self:runCsbAction("idle", true)
    end)
end

-- 解锁
function GeminiJourneyRespinLockView:startPlayUnlockAni(_onEnter)
    if _onEnter then
        self:setVisible(false)
    else
        util_resetCsbAction(self.m_csbAct)
        self:runCsbAction("unlock", false, function()
            self:setVisible(false)
        end)
    end
end

-- idle根据数量判断解锁状态
function GeminiJourneyRespinLockView:showLockState(_isShow)
    if _isShow then
        self:setVisible(true)
        util_resetCsbAction(self.m_csbAct)
        self:runCsbAction("idle", true)
    else
        self:setVisible(false)
    end
end

-- 关闭Lock动画
function GeminiJourneyRespinLockView:closeLockAni()
    if self:isVisible() then
        util_resetCsbAction(self.m_csbAct)
        self:runCsbAction("over", false, function()
            self:setVisible(false)
        end)
    end
end

return GeminiJourneyRespinLockView
