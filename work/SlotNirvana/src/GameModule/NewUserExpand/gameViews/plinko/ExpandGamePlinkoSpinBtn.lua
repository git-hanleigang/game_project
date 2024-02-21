--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 16:53:10
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 16:53:17
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/ExpandGamePlinkoSpinBtn.lua
Description: 扩圈小游戏 弹珠 spin按钮
--]]
local ExpandGamePlinkoSpinBtn = class("ExpandGamePlinkoSpinBtn", BaseView)
local ExpandGamePlinkoConfig = util_require("GameModule.NewUserExpand.config.ExpandGamePlinkoConfig")

function ExpandGamePlinkoSpinBtn:getCsbName()
    return "PlinkoGame/csb/PlinkoGame_Start.csb"
end

function ExpandGamePlinkoSpinBtn:initUI(_gameData, _mainView)
    ExpandGamePlinkoSpinBtn.super.initUI(self)

    self.m_mainView = _mainView
    self.m_gameData = _gameData

    -- 按钮spine
    self:initBtnSpine()
    -- 按钮csbAni
    self:initCsbAni()
    -- 更新按钮状态
    self:updateBtnState()
    self:updateSpineCsbAniVisible()
end

-- 按钮spine
function ExpandGamePlinkoSpinBtn:initBtnSpine()
    local nodeSpine = self:findChild("node_spine")
    local spine = util_spineCreate("PlinkoGame/spine/Start_spine", true, true, 1)
    nodeSpine:addChild(spine)
    self.m_spineBtn = spine
    util_spinePlay(spine, "idle", true)
end

-- 按钮csbAni
function ExpandGamePlinkoSpinBtn:initCsbAni()
    local parent = self:findChild("node_csbAni")
    local view = util_createAnimation("PlinkoGame/csb/PlinkoGame_Start_First.csb")
    parent:addChild(view)
    self.m_csbAniBtn = view
end

-- 更新按钮状态
function ExpandGamePlinkoSpinBtn:updateBtnState()
    local btnSpin = self:findChild("btn_spin")
    local bEnabled = self.m_gameData:checkCanSpin()
    btnSpin:setEnabled(bEnabled) 

    if bEnabled then
        local gameState = G_GetMgr(G_REF.ExpandGamePlinko):getGameState() or ExpandGamePlinkoConfig.GAME_STATE.START
        local nodeGuide = self:findChild("node_guide")
        local time = gameState == ExpandGamePlinkoConfig.GAME_STATE.START and 3 or 9
        performWithDelay(nodeGuide, function()
            self:showGuideFinger()
        end, time)
    else
        self:hideGuideFinger()
    end
end

function ExpandGamePlinkoSpinBtn:updateSpineCsbAniVisible()
    local gameState = G_GetMgr(G_REF.ExpandGamePlinko):getGameState() or ExpandGamePlinkoConfig.GAME_STATE.START
    local nodeSpine = self:findChild("node_spine")
    local nodeCsbAni = self:findChild("node_csbAni")

    nodeCsbAni:setVisible(gameState == ExpandGamePlinkoConfig.GAME_STATE.START)
    nodeSpine:setVisible(gameState ~= ExpandGamePlinkoConfig.GAME_STATE.START)
end

function ExpandGamePlinkoSpinBtn:showGuideFinger()
    if G_GetMgr(G_REF.NewUserExpand):getGuide():isCanTriggerGuide("FirstPlayExpandGame", G_REF.NewUserExpand) then
        return
    end
    
    if not self.m_fingerUI then
        local nodeGuide = self:findChild("node_guide")
        self.m_fingerUI = util_createView("GameModule.NewUserExpand.views.NewUserExpandGuideFinger")
        self.m_fingerUI:addTo(nodeGuide)
    end

    self.m_fingerUI:setVisible(true)
    self.m_fingerUI:playShowFinger()
end
function ExpandGamePlinkoSpinBtn:hideGuideFinger()
    local nodeGuide = self:findChild("node_guide")
    nodeGuide:stopAllActions()

    if self.m_fingerUI then
        self.m_fingerUI:setVisible(false)
    end
end

function ExpandGamePlinkoSpinBtn:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    local gameState = G_GetMgr(G_REF.ExpandGamePlinko):getGameState()
    if gameState ~= ExpandGamePlinkoConfig.GAME_STATE.IDLE and gameState ~= ExpandGamePlinkoConfig.GAME_STATE.START then
        return
    end

    if name == "btn_spin" and not self.m_clicking then
        self:hideGuideFinger()
        self.m_clicking = true

        if gameState == ExpandGamePlinkoConfig.GAME_STATE.START then
            gLobalSoundManager:playSound(ExpandGamePlinkoConfig.SOUNDS.BTN_PRESS_START)
            self:playBtnCsbAni()
        else
            gLobalSoundManager:playSound(ExpandGamePlinkoConfig.SOUNDS.BTN_PRESS_STOP)
            self:playBtnSpineAni()
        end
    end
end

function ExpandGamePlinkoSpinBtn:playBtnCsbAni()
    local cb = function()
        self.m_mainView:updateState(ExpandGamePlinkoConfig.GAME_STATE.IDLE)
        self:resetClickSign()
        self:updateBtnState()
        self:updateSpineCsbAniVisible()
    end
    self.m_csbAniBtn:playAction("start", false, cb, 60)
end

function ExpandGamePlinkoSpinBtn:playBtnSpineAni()
    local cb = function()
        util_spinePlay(self.m_spineBtn, "idle", true)
        G_GetMgr(G_REF.ExpandGamePlinko):sendPlayExpandGameReq()
    end
    util_spinePlay(self.m_spineBtn, "start", false)
    util_spineEndCallFunc(self.m_spineBtn, "start", cb)
end

function ExpandGamePlinkoSpinBtn:onSpinSuccessEvt()
    self:updateBtnState()
    self:resetClickSign()
end

function ExpandGamePlinkoSpinBtn:resetClickSign()
    self.m_clicking = false
end

return ExpandGamePlinkoSpinBtn