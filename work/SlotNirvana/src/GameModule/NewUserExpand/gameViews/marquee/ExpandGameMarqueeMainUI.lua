--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-10 12:11:13
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-10 12:11:19
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/ExpandGameMarqueeMainUI.lua
Description: 扩圈小游戏 跑马灯 主UI
--]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local ExpandGameMarqueeMainUI = class("ExpandGameMarqueeMainUI", BaseActivityMainLayer)
local ExpandGameMarqueeConfig = util_require("GameModule.NewUserExpand.config.ExpandGameMarqueeConfig")
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")

function ExpandGameMarqueeMainUI:initDatas()
    ExpandGameMarqueeMainUI.super.initDatas(self)

    self.m_gameData = G_GetMgr(G_REF.ExpandGameMarquee):getData()

    self:setPortraitCsbName("MarqueeGame/csb/MarqueeGame_MainUI.csb")
    self:setPauseSlotsEnabled(true)
    self:setHideLobbyEnabled(true)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setExtendData("ExpandGameMarqueeMainUI")
    self:setName("ExpandGameMarqueeMainUI")
    self:setBgm(ExpandGameMarqueeConfig.SOUNDS.BGM)
    self:setHasGuide(true)
end

function ExpandGameMarqueeMainUI:initView()
    -- 标题
    self:initTitleUI()
    -- 剩余次数
    self:updateLeftTimeUI()
    -- spin按钮
    self:initSpinBtnUI()
    -- 机器
    self:initMachineUI()

    self:runCsbAction("idle", true)
end

function ExpandGameMarqueeMainUI:onEnter()
    ExpandGameMarqueeMainUI.super.onEnter(self)

    -- 开始游戏 (之前点过了直接idle状态)
    local state = ExpandGameMarqueeConfig.GAME_STATE.START
    local playTimes = self.m_gameData:getPlayTimes()
    if playTimes > 0 then
        state = ExpandGameMarqueeConfig.GAME_STATE.IDLE
    end 
    self:updateState(state)
    self.m_spinBtnView:updateSpineCsbAniVisible()

    if state == ExpandGameMarqueeConfig.GAME_STATE.START then
        self:dealGuideLogic()
    end

    performWithDelay(self, util_node_handler(self, self.checkGameOver), 0.5)
end

function ExpandGameMarqueeMainUI:updateState(_state)
    self.m_machineView:updateState(_state)
end

-- 标题
function ExpandGameMarqueeMainUI:initTitleUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.ExpandGameMarqueeTitleUI", self.m_gameData)
    local parent = self:findChild("node_title")
    parent:addChild(view)
    self.m_titleView = view
end

-- 剩余次数
function ExpandGameMarqueeMainUI:updateLeftTimeUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.ExpandGameMarqueeLeftTimeUI", self.m_gameData)
    local parent = self:findChild("node_leftgame")
    parent:addChild(view)
    self.m_leftTimeView = view
end

-- spin按钮
function ExpandGameMarqueeMainUI:initSpinBtnUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.ExpandGameMarqueeSpinBtn", self.m_gameData, self)
    local parent = self:findChild("node_start")
    parent:addChild(view)
    self.m_spinBtnView = view
end
function ExpandGameMarqueeMainUI:playSpinShakeAni()
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end, 60) 
end

-- 机器
function ExpandGameMarqueeMainUI:initMachineUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.ExpandGameMarqueeMachineUI", self.m_gameData, self)
    local parent = self:findChild("node_light")
    parent:addChild(view)
    self.m_machineView = view
end

-- spin成功
function ExpandGameMarqueeMainUI:onSpinSuccessEvt()
    self.m_spinBtnView:onSpinSuccessEvt()
    self.m_machineView:onSpinSuccessEvt()
    self.m_leftTimeView:onSpinSuccessEvt()
end

-- 中奖后 播放彩带动画
function ExpandGameMarqueeMainUI:playCaidaiAni()
    local nodeCaidai = self:findChild("node_caidai")
    nodeCaidai:removeAllChildren()
    
    local csbNode = util_csbCreate("MarqueeGame/csb/Node_caidai.csb")
    nodeCaidai:addChild(csbNode)
end

-- 金币放大 飞到 金币栏
function ExpandGameMarqueeMainUI:playCoinFlyAni(_startPosW, _cb, _rewardData)
    local coinFlyView = util_createView("GameModule.NewUserExpand.gameViews.marquee.machine.MarqueeFlyRewardUI", _rewardData)
    local parent = self:findChild("node_ani")
    parent:addChild(coinFlyView)
    
    local posL_s = parent:convertToNodeSpace(_startPosW)
    coinFlyView:move(posL_s)
    local endPosW = self.m_titleView:getCoinsPosW()
    local posL_e = parent:convertToNodeSpace(endPosW)
    coinFlyView:playFlyAni(posL_e, _cb)
end
-- 成倍buff放大 飞到 标题 buff栏
function ExpandGameMarqueeMainUI:playBuffFlyAni(_startPosW, _cb, _rewardData)
    local coinFlyView = util_createView("GameModule.NewUserExpand.gameViews.marquee.machine.MarqueeFlyRewardUI", _rewardData)
    local parent = self:findChild("node_ani")
    parent:addChild(coinFlyView)
    
    local posL_s = parent:convertToNodeSpace(_startPosW)
    coinFlyView:move(posL_s)
    local endPosW = self.m_titleView:getBuffPosW()
    local posL_e = parent:convertToNodeSpace(endPosW)
    coinFlyView:playFlyAni(posL_e, _cb)
end

function ExpandGameMarqueeMainUI:playCoinChangeAni()
    local cb = function()
        local bCanSpin = self.m_gameData:checkCanSpin()
        if not bCanSpin then
            -- 游戏结束
            self.m_machineView:updateState(ExpandGameMarqueeConfig.GAME_STATE.OVER)
            -- G_GetMgr(G_REF.ExpandGameMarquee):showRewardLayer(function()
            --     self:closeUI()
            -- end)
            G_GetMgr(G_REF.ExpandGameMarquee):sendOverExpandGameReq()
        else
            -- 恢复为待机状态
            self.m_machineView:updateState(ExpandGameMarqueeConfig.GAME_STATE.IDLE)
        end
    end
    self.m_titleView:playCoinChangeAni(cb)
end

-- spin失败
function ExpandGameMarqueeMainUI:onSpinFaildEvt()
    self.m_spinBtnView:resetClickSign()
end

-- 结算成功
function ExpandGameMarqueeMainUI:onCollectSuccessEvt(_rewardCoins)
    local cb = function()
        G_GetMgr(G_REF.ExpandGameMarquee):showRewardLayer(_rewardCoins, function()
            self:closeUI()
        end)
    end
    self.m_titleView:playOverCollectCoinsAni(_rewardCoins, cb)
end

function ExpandGameMarqueeMainUI:registerListener()
    ExpandGameMarqueeMainUI.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onSpinSuccessEvt", ExpandGameMarqueeConfig.EVENT_NAME.PLAY_EXPAND_MINI_GMAE_SUCCESS)
    gLobalNoticManager:addObserver(self, "onSpinFaildEvt", ExpandGameMarqueeConfig.EVENT_NAME.PLAY_EXPAND_MINI_GMAE_FAILD)
    gLobalNoticManager:addObserver(self, "onCollectSuccessEvt", ExpandGameMarqueeConfig.EVENT_NAME.COLLECT_EXPAND_MINI_GMAE_SUCCESS)
end

function ExpandGameMarqueeMainUI:closeUI()
    local cb = function()
        gLobalNoticManager:postNotification(NewUserExpandConfig.EVENT_NAME.COMPLETE_MINI_GAME_BACK_EXPAND_UI)
    end
    ExpandGameMarqueeMainUI.super.closeUI(self, cb)
end

-- 界面是否横屏
function ExpandGameMarqueeMainUI:isLandscape()
    return false
end

-- 引导
function ExpandGameMarqueeMainUI:dealGuideLogic()
    self.m_bGuide = G_GetMgr(G_REF.NewUserExpand):getGuide():triggerGuide(self, "FirstPlayExpandGame", G_REF.NewUserExpand)
    if self.m_bGuide then
        G_GetMgr(G_REF.NewUserExpand):getLogObj():sendExpandGuideLog("FirstPlayExpandGame")
    end
end

-- 检查游戏是否结束 未结算
function ExpandGameMarqueeMainUI:checkGameOver()
    local bCanSpin = self.m_gameData:checkCanSpin()
    if bCanSpin then
        return
    end
    if self.m_bGuide then
        G_GetMgr(G_REF.NewUserExpand):getGuide():doNextGuideStep("FirstPlayExpandGame")
    end
    G_GetMgr(G_REF.ExpandGameMarquee):sendOverExpandGameReq()
end

return ExpandGameMarqueeMainUI