---
--xcyy
--2018年5月23日
--GeminiJourneyRespinBoardView.lua
local PublicConfig = require "GeminiJourneyPublicConfig"
local GeminiJourneyRespinBoardView = class("GeminiJourneyRespinBoardView",util_require("Levels.BaseLevelDialog"))

function GeminiJourneyRespinBoardView:initUI(_parms)
    self.m_machine = _parms._machine
    self.m_boardIndex = _parms._boardIndex
    self.m_baseReSpinBar = _parms._respinbar
    local respinTopNode = _parms._respinTopNode

    self:createCsbNode("GeminiJourney_ReSpinReel.csb")
    self.m_clipParentNode = self:findChild("Node_sp_reel")

    self:findChild("Node_reels"):addChild(respinTopNode)

    local lineAni = util_createAnimation("GeminiJourney_ReSpin_jiange.csb")
    self:findChild("Node_jiange"):addChild(lineAni)
    lineAni:runCsbAction("idle", true)

    self:findChild("Node_ReSpinBar"):addChild(self.m_baseReSpinBar)

    -- 锁定行
    self.m_baseReSpinLockTbl = {}
    -- 底下的遮罩
    self.m_bottomMaskTbl = {}
    for i=1, 2 do
        self.m_baseReSpinLockTbl[i] = util_createView("GeminiJourneySrc.GeminiJourneyRespinLockView", i)
        self:findChild("Lock"..i):addChild(self.m_baseReSpinLockTbl[i])

        self.m_bottomMaskTbl[i] = util_createAnimation("GeminiJourney_ReSpinReel_di.csb")
        self:findChild("Node_di"):addChild(self.m_bottomMaskTbl[i])
    end

    -- 棋盘底光
    self.m_bottomLight = util_createAnimation("GeminiJourney_ReSpin_diguang.csb")
    self:findChild("Node_diguang"):addChild(self.m_bottomLight)
    self.m_bottomLight:findChild("sp_light_1"):setVisible(self.m_boardIndex==1)
    self.m_bottomLight:findChild("sp_light_2"):setVisible(self.m_boardIndex==2)
    self.m_bottomLight:setVisible(false)

    -- 添加grand
    self.m_grandAni = util_createAnimation("GeminiJourney_ReSpin_chufa.csb")
    self:findChild("Node_grand"):addChild(self.m_grandAni)
    self.m_grandAni:setVisible(false)

    -- 添加grand背光
    self.m_grandLight = util_createAnimation("GeminiJourney_ReSpin_guang.csb")
    self.m_grandAni:findChild("guang"):addChild(self.m_grandLight)
    self.m_grandLight:runCsbAction("idleframe", true)
    util_setCascadeOpacityEnabledRescursion(self.m_grandAni, true)

    -- self:findChild("Node_respin_reels1"):setVisible(self.m_boardIndex==1)
    -- self:findChild("Node_respin_reels2"):setVisible(self.m_boardIndex==2)
    self:findChild("Node_ReelBorder1"):setVisible(self.m_boardIndex==1)
    self:findChild("Node_ReelBorder2"):setVisible(self.m_boardIndex==2)
end

function GeminiJourneyRespinBoardView:getClipParentNode()
    return self.m_clipParentNode
end

-- 显示底reel条
function GeminiJourneyRespinBoardView:showBottomReelAni(_showType)
    self:runCsbAction(_showType, true)
end

-- 显示底光条
function GeminiJourneyRespinBoardView:showBottomLight(_isShow, _isStart)
    self.m_bottomLight:setVisible(_isShow)
    util_resetCsbAction(self.m_bottomLight.csbAct)
    if _isStart then
        self.m_bottomLight:runCsbAction("start", false, function()
            self.m_bottomLight:runCsbAction("idle", true)
        end)
    else
        self.m_bottomLight:runCsbAction("idle", true)
    end
end

-- 底光消失
function GeminiJourneyRespinBoardView:closeBottomReelAndLight(_onEnter)
    if _onEnter then
        self.m_bottomLight:setVisible(false)
    else
        util_resetCsbAction(self.m_bottomLight.csbAct)
        self.m_bottomLight:runCsbAction("over", false, function()
            self.m_bottomLight:setVisible(false)
        end)
    end
end

-- respinLock开始动画
function GeminiJourneyRespinBoardView:startRespinLockBar()
    for i=1, 2 do
        self.m_baseReSpinLockTbl[i]:startPlayLockAni()

        -- mask
        self.m_bottomMaskTbl[i]:setVisible(true)
        self.m_bottomMaskTbl[i]:runCsbAction("start", false, function()
            self.m_bottomMaskTbl[i]:runCsbAction("idle", true)
        end)
    end
end

-- respinLock解锁状态idle
function GeminiJourneyRespinBoardView:showLockState(_isShow)
    for i=1, 2 do
        self.m_baseReSpinLockTbl[i]:showLockState(_isShow)
    end
end

-- respinLock解锁动画(_unlockRowIndex:1-解锁第四行  _unlockRowIndex:2-解锁第五行)
function GeminiJourneyRespinBoardView:startRespinUnLockBar(_unlockRowIndex, _onEnter)
    if _onEnter then
        for i=1, 2 do
            if _unlockRowIndex >= i then
                self.m_baseReSpinLockTbl[i]:startPlayUnlockAni(_onEnter)
                if _unlockRowIndex == 1 then
                    self.m_baseReSpinLockTbl[2]:setLockMoreState()
                end
            end
        end
    else
        self.m_baseReSpinLockTbl[_unlockRowIndex]:startPlayUnlockAni(_onEnter)
        if _unlockRowIndex == 1 then
            self.m_baseReSpinLockTbl[2]:setLockMoreState()
        end
    end
end

-- 关闭lock动画
function GeminiJourneyRespinBoardView:closeLockAni()
    for i=1, 2 do
        self.m_baseReSpinLockTbl[i]:closeLockAni()
    end
end

-- 底下的mask-idle
function GeminiJourneyRespinBoardView:showBottomMaskIdleAni()
    for i=1, 2 do
        self.m_bottomMaskTbl[i]:setVisible(true)
        self.m_bottomMaskTbl[i]:runCsbAction("idle", true)
    end
end

-- 关闭底下的mask
function GeminiJourneyRespinBoardView:closeBottomMaskAni()
    for i=1, 2 do
        self.m_bottomMaskTbl[i]:runCsbAction("over", false, function()
            self.m_bottomMaskTbl[i]:setVisible(false)
        end)
    end
end

-- 显示grand
function GeminiJourneyRespinBoardView:showGrandAni(_isShow, _showType)
    util_resetCsbAction(self.m_grandAni.csbAct)
    self.m_grandAni:setVisible(_isShow)
    if _showType == "start" then
        self.m_grandAni:runCsbAction("start", false, function()
            self.m_grandAni:runCsbAction("idle", true)
        end)
    elseif _showType == "idle" then
        self.m_grandAni:runCsbAction("idle", true)
    elseif _showType == "over" then
        self.m_grandAni:runCsbAction("over", false, function()
            self.m_grandAni:setVisible(false)
        end)
    elseif _showType == "actionframe" then
        self.m_grandAni:runCsbAction("actionframe", false, function()
            self.m_grandAni:runCsbAction("over", false, function()
                self.m_grandAni:setVisible(false)
            end)
        end)
    end
end

return GeminiJourneyRespinBoardView
