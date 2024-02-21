--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 16:21:44
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 16:22:05
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/plinko/ExpandGamePlinkoMainUI.lua
Description: 扩圈小游戏 弹珠 主UI
--]]
local BaseActivityMainLayer = require("baseActivity.BaseActivityMainLayer")
local ExpandGamePlinkoMainUI = class("ExpandGamePlinkoMainUI", BaseActivityMainLayer)
local ExpandGamePlinkoConfig = util_require("GameModule.NewUserExpand.config.ExpandGamePlinkoConfig")
local NewUserExpandConfig = util_require("GameModule.NewUserExpand.config.NewUserExpandConfig")

function ExpandGamePlinkoMainUI:initDatas()
    ExpandGamePlinkoMainUI.super.initDatas(self)

    self.m_gameData = G_GetMgr(G_REF.ExpandGamePlinko):getData()

    self:setPortraitCsbName("PlinkoGame/csb/PlinkoGame_MainUI.csb")
    self:setPauseSlotsEnabled(true)
    self:setHideLobbyEnabled(true)
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setExtendData("ExpandGamePlinkoMainUI")
    self:setName("ExpandGamePlinkoMainUI")
    self:setBgm(ExpandGamePlinkoConfig.SOUNDS.BGM)
end

function ExpandGamePlinkoMainUI:initView()
    -- 标题
    self:initTitleUI()
    -- 剩余次数
    self:updateLeftTimeUI()
    -- spin按钮
    self:initSpinBtnUI()

    -- 钉子棋盘
    self:initChessUI()
    -- 奖励仓库
    self:initRewardUI()

    -- 发送器
    self:initLaunchUI()
    -- 箭头动画
    self:initArrowAniUI()

    self:runCsbAction("idle", true)
end

function ExpandGamePlinkoMainUI:onEnter()
    ExpandGamePlinkoMainUI.super.onEnter(self)

    -- 开始游戏 (之前点过了直接idle状态)
    -- cxc 2023年04月20日14:39:08 取消开始等待状态策划要求上来直接可以玩
    local state = ExpandGamePlinkoConfig.GAME_STATE.IDLE
    -- local playTimes = self.m_gameData:getPlayTimes()
    -- if playTimes > 0 then
    --     state = ExpandGamePlinkoConfig.GAME_STATE.IDLE
    -- end 
    self:updateState(state)
    self.m_spinBtnView:updateSpineCsbAniVisible()

    self:dealGuideLogic()
    performWithDelay(self, util_node_handler(self, self.checkGameOver), 0.5)
end

-- 标题
function ExpandGamePlinkoMainUI:initTitleUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.ExpandGamePlinkoTitleUI", self.m_gameData)
    local parent = self:findChild("node_title")
    parent:addChild(view)
    self.m_titleView = view
end

-- 剩余次数
function ExpandGamePlinkoMainUI:updateLeftTimeUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.ExpandGamePlinkoLeftTimeUI", self.m_gameData)
    local parent = self:findChild("node_leftgame")
    parent:addChild(view)
    self.m_leftTimeView = view
end

-- spin按钮
function ExpandGamePlinkoMainUI:initSpinBtnUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.ExpandGamePlinkoSpinBtn", self.m_gameData, self)
    local parent = self:findChild("node_start")
    parent:addChild(view)
    self.m_spinBtnView = view
end
function ExpandGamePlinkoMainUI:playSpinShakeAni()
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end, 60) 
end

-- 钉子棋盘
function ExpandGamePlinkoMainUI:initChessUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.chess.ExpandPlinkoChessUI", self.m_gameData, self)
    local parent = self:findChild("node_map")
    parent:addChild(view)
    self.m_chessView = view
end

-- 奖励仓库
function ExpandGamePlinkoMainUI:initRewardUI()
    local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.chess.ExpandPlinkoRewardListUI", self.m_gameData, self)
    local parent = self:findChild("node_reward")
    parent:addChild(view)
    self.m_rewardView = view
end

-- 发送器
function ExpandGamePlinkoMainUI:initLaunchUI()
    local posXList = self.m_chessView:getRow12PosXList()
    local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.chess.ExpandPlinkoLaunchUI", posXList, self)
    local parent = self:findChild("node_out")
    parent:addChild(view)
    self.m_launchView = view
end
-- 箭头动画
function ExpandGamePlinkoMainUI:initArrowAniUI()
    self.m_arrowViewList = {}
    for i=1, 2 do
        local node = self:findChild("node_arrowhead_" .. i)
        local view = util_createView("GameModule.NewUserExpand.gameViews.plinko.chess.ExpandPlinkoArrowAniUI")
        node:addChild(view)
        self.m_arrowViewList[i] = view
    end
end
function ExpandGamePlinkoMainUI:setArrowAniVisible(_visible)
    local nodeArrow = self:findChild("node_arrow")
    nodeArrow:setVisible(_visible)
end

function ExpandGamePlinkoMainUI:updateState(_state)
    self.m_state = _state

    if _state == ExpandGamePlinkoConfig.GAME_STATE.START then
        self:setArrowAniVisible(true)
        self.m_launchView:updateState(ExpandGamePlinkoConfig.LAUNCH_STATE.STOP)
    elseif _state == ExpandGamePlinkoConfig.GAME_STATE.IDLE then
        self:setArrowAniVisible(true)
        self.m_launchView:updateState(ExpandGamePlinkoConfig.LAUNCH_STATE.MOVE)
    elseif _state == ExpandGamePlinkoConfig.GAME_STATE.DROP_BALL then
        local nextPosX, nextIdx = self.m_launchView:getNextPosX()
        local pathNodePosList = self.m_chessView:getDingNodePosList(nextIdx)
        self.m_launchView:setDropBallPathInfo(pathNodePosList)
        self.m_launchView:updateState(ExpandGamePlinkoConfig.LAUNCH_STATE.LAUNCH)
    elseif _state == ExpandGamePlinkoConfig.GAME_STATE.OVER then

    end

    G_GetMgr(G_REF.ExpandGamePlinko):setGameState(_state)
end

-- spin成功
function ExpandGamePlinkoMainUI:onSpinSuccessEvt()
    self:updateState(ExpandGamePlinkoConfig.GAME_STATE.DROP_BALL)

    self.m_spinBtnView:onSpinSuccessEvt()
    self.m_leftTimeView:onSpinSuccessEvt()
end

-- 球掉落完毕播完 飞金币动画
function ExpandGamePlinkoMainUI:checkPlayFlyCoinsAni()
    local curSpinHitIdx = G_GetMgr(G_REF.ExpandGamePlinko):getCurSpinHitIdx()
    local cb = function()
        self.m_titleView:playCoinChangeAni(util_node_handler(self, self.curSpinOverCheck))
    end
    self.m_rewardView:playRewardColAni(curSpinHitIdx, cb)
end
function ExpandGamePlinkoMainUI:curSpinOverCheck()
    local bCanSpin = self.m_gameData:checkCanSpin()
    if not bCanSpin then
        -- 游戏结束
        self:updateState(ExpandGamePlinkoConfig.GAME_STATE.OVER)
        G_GetMgr(G_REF.ExpandGamePlinko):sendOverExpandGameReq()
    else
        -- 恢复为待机状态
        self:updateState(ExpandGamePlinkoConfig.GAME_STATE.IDLE)
    end
end

function ExpandGamePlinkoMainUI:registerListener()
    ExpandGamePlinkoMainUI.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onSpinSuccessEvt", ExpandGamePlinkoConfig.EVENT_NAME.SPIN_SUCCESS_AND_DROP_BALL)
end

function ExpandGamePlinkoMainUI:closeUI()
    local cb = function()
        gLobalNoticManager:postNotification(NewUserExpandConfig.EVENT_NAME.COMPLETE_MINI_GAME_BACK_EXPAND_UI)
    end
    ExpandGamePlinkoMainUI.super.closeUI(self, cb)
end

-- 界面是否横屏
function ExpandGamePlinkoMainUI:isLandscape()
    return false
end

-- 引导
function ExpandGamePlinkoMainUI:dealGuideLogic()
    self.m_bGuide = G_GetMgr(G_REF.NewUserExpand):getGuide():triggerGuide(self, "FirstPlayExpandGame", G_REF.NewUserExpand)
    if self.m_bGuide then
        G_GetMgr(G_REF.NewUserExpand):getLogObj():sendExpandGuideLog("FirstPlayExpandGame")
    end
end

-- 检查游戏是否结束 未结算
function ExpandGamePlinkoMainUI:checkGameOver()
    local bCanSpin = self.m_gameData:checkCanSpin()
    if bCanSpin then
        return
    end
    if self.m_bGuide then
        G_GetMgr(G_REF.NewUserExpand):getGuide():doNextGuideStep("FirstPlayExpandGame")
    end
    G_GetMgr(G_REF.ExpandGamePlinko):sendOverExpandGameReq()
end

return ExpandGamePlinkoMainUI