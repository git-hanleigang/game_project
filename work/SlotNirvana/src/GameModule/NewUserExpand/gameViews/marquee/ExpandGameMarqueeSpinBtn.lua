--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-10 16:30:21
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-10 16:30:31
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/ExpandGameMarqueeSpinBtn.lua
Description: 扩圈小游戏 跑马灯 spin按钮
--]]
local ExpandGameMarqueeSpinBtn = class("ExpandGameMarqueeSpinBtn", BaseView)
local ExpandGameMarqueeConfig = util_require("GameModule.NewUserExpand.config.ExpandGameMarqueeConfig")

function ExpandGameMarqueeSpinBtn:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_Start.csb"
end

function ExpandGameMarqueeSpinBtn:initUI(_gameData, _mainView)
    ExpandGameMarqueeSpinBtn.super.initUI(self)

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
function ExpandGameMarqueeSpinBtn:initBtnSpine()
    local nodeSpine = self:findChild("node_spine")
    local spine = util_spineCreate("MarqueeGame/spine/Start_spine", true, true, 1)
    nodeSpine:addChild(spine)
    self.m_spineBtn = spine
    util_spinePlay(spine, "idle", true)
end

-- 按钮csbAni
function ExpandGameMarqueeSpinBtn:initCsbAni()
    local parent = self:findChild("node_csbAni")
    local view = util_createAnimation("MarqueeGame/csb/MarqueeGame_Start_First.csb")
    parent:addChild(view)
    self.m_csbAniBtn = view
end

-- 更新按钮状态
function ExpandGameMarqueeSpinBtn:updateBtnState()
    local btnSpin = self:findChild("btn_spin")
    local bEnabled = self.m_gameData:checkCanSpin()
    btnSpin:setEnabled(bEnabled) 

    if bEnabled then
        local nodeGuide = self:findChild("node_guide")
        performWithDelay(nodeGuide, function()
            self:showGuideFinger()
        end, 5)
    else
        self:hideGuideFinger()
    end
end

function ExpandGameMarqueeSpinBtn:updateSpineCsbAniVisible()
    local gameState = G_GetMgr(G_REF.ExpandGameMarquee):getGameMachineState() or ExpandGameMarqueeConfig.GAME_STATE.START
    local nodeSpine = self:findChild("node_spine")
    local nodeCsbAni = self:findChild("node_csbAni")

    nodeCsbAni:setVisible(gameState == ExpandGameMarqueeConfig.GAME_STATE.START)
    nodeSpine:setVisible(gameState ~= ExpandGameMarqueeConfig.GAME_STATE.START)
end

function ExpandGameMarqueeSpinBtn:showGuideFinger()
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
function ExpandGameMarqueeSpinBtn:hideGuideFinger()
    local nodeGuide = self:findChild("node_guide")
    nodeGuide:stopAllActions()

    if self.m_fingerUI then
        self.m_fingerUI:setVisible(false)
    end
end

function ExpandGameMarqueeSpinBtn:clickFunc(sender)
    local name = sender:getName()

    local gameState = G_GetMgr(G_REF.ExpandGameMarquee):getGameMachineState()
    if gameState ~= ExpandGameMarqueeConfig.GAME_STATE.IDLE and gameState ~= ExpandGameMarqueeConfig.GAME_STATE.START then
        return
    end


    if name == "btn_spin" and not self.m_clicking then
        self:hideGuideFinger()
        self.m_clicking = true

        if gameState == ExpandGameMarqueeConfig.GAME_STATE.START then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
            self:playBtnCsbAni()
        else
            gLobalSoundManager:playSound(ExpandGameMarqueeConfig.SOUNDS.BTN_PRESS)
            self:playBtnSpineAni()
        end
        
    end
end

function ExpandGameMarqueeSpinBtn:playBtnCsbAni()
    local cb = function()
        self.m_mainView:updateState(ExpandGameMarqueeConfig.GAME_STATE.IDLE)
        self:resetClickSign()
        self:updateBtnState()
        self:updateSpineCsbAniVisible()
    end
    self.m_csbAniBtn:playAction("start", false, cb, 60)
end

function ExpandGameMarqueeSpinBtn:playBtnSpineAni()
    local cb = function()
        util_spinePlay(self.m_spineBtn, "idle", true)
        G_GetMgr(G_REF.ExpandGameMarquee):sendPlayExpandGameReq()
    end
    util_spinePlay(self.m_spineBtn, "start", false)
    util_spineEndCallFunc(self.m_spineBtn, "start", cb)

    -- spin按钮落下去再播 牌面动画
    performWithDelay(self, function()
        self.m_mainView:playSpinShakeAni()
    end, 15/60)
end

function ExpandGameMarqueeSpinBtn:onSpinSuccessEvt()
    self:updateBtnState()
    self:resetClickSign()
end

function ExpandGameMarqueeSpinBtn:resetClickSign()
    self.m_clicking = false
end

return ExpandGameMarqueeSpinBtn