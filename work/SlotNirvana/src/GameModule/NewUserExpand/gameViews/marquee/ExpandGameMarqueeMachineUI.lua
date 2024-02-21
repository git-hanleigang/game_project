--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-10 16:37:56
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-10 16:39:14
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/gameViews/marquee/ExpandGameMarqueeMachineUI.lua
Description: 扩圈小游戏 跑马灯 机器UI
--]]
local ExpandGameMarqueeConfig = util_require("GameModule.NewUserExpand.config.ExpandGameMarqueeConfig")
local ExpandGameMarqueeMachineUI = class("ExpandGameMarqueeMachineUI", BaseView)

function ExpandGameMarqueeMachineUI:initDatas(_gameData, _mainView)
    ExpandGameMarqueeMachineUI.super.initDatas(self)

    self.m_mainView = _mainView
    self.m_gameData = _gameData
    self.m_rewardList = self.m_gameData:getRewardList()

    self.m_cellList = {}
end

function ExpandGameMarqueeMachineUI:getCsbName()
    return "MarqueeGame/csb/MarqueeGame_Light.csb"
end

function ExpandGameMarqueeMachineUI:initUI()
    ExpandGameMarqueeMachineUI.super.initUI(self)

    -- 初始化道具
    self:initRewardsUI()
    -- 初始化中间 大道具
    self:initBigRewardsUI()
    -- 初始化中间 开始游戏动画
    self:initStartAniUI()
end

-- 初始化道具
function ExpandGameMarqueeMachineUI:initRewardsUI()
    for i=1, 18 do

        local parent = self:findChild("node_ring_piece_" .. i)
        local data = self.m_rewardList[i]
        if parent and data then
            local cell = self:createItemCellUI(i, data)
            parent:addChild(cell)
            self.m_cellList[i] = cell
        end

    end

    util_setCascadeColorEnabledRescursion(self:findChild("node_ring"), true)
end

-- 创建道具cell
function ExpandGameMarqueeMachineUI:createItemCellUI(_idx, _rewardData)
    local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.machine.MarqueeRewardCellUI", _idx, _rewardData)
    return view
end

-- 初始化中间 大道具
function ExpandGameMarqueeMachineUI:initBigRewardsUI()
    local parent = self:findChild("node_show_reward")
    local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.machine.MarqueeRewardBigItemUI", self.m_mainView)
    parent:addChild(view)
    self.m_bigItemView = view
end

-- 初始化中间 开始游戏动画
function ExpandGameMarqueeMachineUI:initStartAniUI()
    local parent = self:findChild("node_show_reward")
    local view = util_createView("GameModule.NewUserExpand.gameViews.marquee.machine.MarqueeBigStartAniUI")
    parent:addChild(view)
    self.m_bigStarAniView = view
end

-- 更新跑马灯机器状态
function ExpandGameMarqueeMachineUI:updateState(_state)
    self.m_state = _state

    if _state == ExpandGameMarqueeConfig.GAME_STATE.START then
        -- 播放 开始动画
        self:playStartAni()
    elseif _state == ExpandGameMarqueeConfig.GAME_STATE.IDLE then
        self:grayOtherCellView()

        -- 游戏idle 随机闪烁奖励
        self.m_bigStarAniView:setVisible(false)
        self.m_bigItemView:setVisible(true)
        self:playIdleAni()
    elseif _state == ExpandGameMarqueeConfig.GAME_STATE.SHOW_RESULT then
        -- spin 选出本次游戏结果
        self:stopLastCellFlashAni()
        self:playResultAni()
    elseif _state == ExpandGameMarqueeConfig.GAME_STATE.OVER then

    end
    G_GetMgr(G_REF.ExpandGameMarquee):setGameMachineState(_state)
end

-- 播放 开始动画
function ExpandGameMarqueeMachineUI:playStartAni()
    local cb = function()
        -- 废弃由玩家主动点击
        -- self:updateState(ExpandGameMarqueeConfig.GAME_STATE.IDLE)
    end
    self.m_bigStarAniView:setVisible(true)
    self.m_bigItemView:setVisible(false)
    self.m_bigStarAniView:playStarAni(cb)
end

-- 游戏idle 随机闪烁奖励
function ExpandGameMarqueeMachineUI:playIdleAni()
    -- 非 IDLE状态 return
    if self.m_state ~= ExpandGameMarqueeConfig.GAME_STATE.IDLE then
        return
    end

    -- 停止上一个 cell闪烁
    self:stopLastCellFlashAni()

    -- 随机选一个 播放闪烁东海
    local idx = self:getRandomFlashCellIdx()
    local view = self.m_cellList[idx]
    if not view then
        self:playIdleAni()
        return
    end

    self.m_bigItemView:updateType(self.m_rewardList[idx])
    self.m_aniCellView = view
    self.m_flashCellIdx = idx
    view:playChooseAni(util_node_handler(self, self.playIdleAni))
end
function ExpandGameMarqueeMachineUI:getRandomFlashCellIdx()

    while true do
        local idx = util_random(1, 18)
        if idx ~= self.m_flashCellIdx then
            return idx
        end
    end

end
-- 停止上一个 cell闪烁
function ExpandGameMarqueeMachineUI:stopLastCellFlashAni()
    if not self.m_aniCellView then
        return
    end

    self.m_aniCellView:playUnChooseAni()
    self.m_aniCellView = nil
end

-- spin播放选中结果动画
function ExpandGameMarqueeMachineUI:playResultAni()
    local serverHitIdx = G_GetMgr(G_REF.ExpandGameMarquee):getCurSpinHitIdx()
    if not serverHitIdx then
        return
    end

    local view = self.m_cellList[serverHitIdx]
    local rewardData = self.m_rewardList[serverHitIdx]
    if not view or not rewardData then
        return
    end

    local cb = function()
        -- 播放动画完毕 更新 累积金币动画
        self.m_mainView:playCoinChangeAni()
    end
    view:playChooseAni()
    self.m_bigItemView:playChooseAni(cb, rewardData)
    self.m_aniCellView = view
    self.m_flashCellIdx = serverHitIdx
    self:grayOtherCellView(true)
end

-- 压暗其他奖励
function ExpandGameMarqueeMachineUI:grayOtherCellView(_bGray)
    for idx, cellView in pairs(self.m_cellList) do
        cellView:checkGrayUI(self.m_flashCellIdx, _bGray)
    end
end

function ExpandGameMarqueeMachineUI:onSpinSuccessEvt()
    self:updateState(ExpandGameMarqueeConfig.GAME_STATE.SHOW_RESULT)
end

return ExpandGameMarqueeMachineUI