--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:30:47
FilePath: /SlotNirvana/src/GameModule/TrillionChallenge/views/TrillionChallengeMainLayer.lua
Description: 亿万赢钱挑战 主界面
--]]
local TrillionChallengeMainLayer = class("TrillionChallengeMainLayer", BaseLayer)
local TrillionChallengeTableView = util_require("GameModule.TrillionChallenge.views.challenge.TrillionChallengeTableView")
local TrillionChallengeConfig = util_require("GameModule.TrillionChallenge.config.TrillionChallengeConfig")

local BTN_TYPE = {
    TOURNAMENT = 1, -- 竞赛排行
    CHALLENGE = 2 -- 锦标任务
}

function TrillionChallengeMainLayer:initDatas()
    TrillionChallengeMainLayer.super.initDatas(self)

    self._btnTag = BTN_TYPE.CHALLENGE
    self._canColIdxList = {} --待领取任务 idx
    self._boxViewList = {}
    self._data = G_GetMgr(G_REF.TrillionChallenge):getRunningData()
    
    self:setPauseSlotsEnabled(true)
    self:setLandscapeCsbName("Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_Main.csb")
    self:setPortraitCsbName("Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_Main_shu.csb")
    self:setName("TrillionChallengeMainLayer")
end

function TrillionChallengeMainLayer:onShowedCallFunc()
    G_GetMgr(G_REF.TrillionChallenge):sendGetRankDataReq()
    -- 检查领取任务宝箱
    self:checkColBoxTask()
end

function TrillionChallengeMainLayer:initView()
    TrillionChallengeMainLayer.super.initView(self)
    self:runCsbAction("idle", true)
    
    -- 内容显隐
    self:updateContentState()
    -- 内容 锦标赛
    self:initTournamentUI()
    -- 内容 挑战排行
    self:initChallengeUI()

    -- 时间
    self:initTimeUI()
end

-- 内容 锦标赛
function TrillionChallengeMainLayer:initTournamentUI()
    -- 宝箱
    local taskDataList = self._data:getTaskList()
    self._boxViewList = {}
    local maxTaskUnlockCoins = 0
    for i = 1, 5 do
        local nodeBox = self:findChild("node_box_"..i)
        local taskData = taskDataList[i]
        if taskData then
            if i == 5 then
                maxTaskUnlockCoins = taskData:getTaskParam() 
            end
            local boxView = util_createView("GameModule.TrillionChallenge.views.tournament.TrillionChallengeBoxUI", taskData)
            nodeBox:addChild(boxView)
            self._boxViewList[taskData:getTaskOrder()] = boxView
        end
    end
    -- 说明 任务要求金币
    local lbUnlockCoins = self:findChild("lb_unlock_coins")
    lbUnlockCoins:setString(util_formatCoins(maxTaskUnlockCoins, 2))
    util_scaleCoinLabGameLayerFromBgWidth(lbUnlockCoins, 50, 1)
    -- 说明 当前个人累计金币
    local lbCoins = self:findChild("lb_coins")
    local coins = self._data:getCurTotalWin()
    lbCoins:setString(util_formatCoins(coins, 9))

    -- 舞台
    self:initStageUI()
end
-- 内容 挑战排行
function TrillionChallengeMainLayer:initChallengeUI()
    -- 奖励
    local nodePrize = self:findChild("node_prize")
    local prizeView = util_createView("GameModule.TrillionChallenge.views.challenge.TrillionChallengeRankJackpot")
    nodePrize:addChild(prizeView)
    local prizePool = self._data:getPrizePool()
    prizeView:updateUI(prizePool)
    self._prizePoolView = prizeView

    -- 排名
    local tbView = self:findChild("rewardList")
    local size = tbView:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = tbView,
        directionType = 2
    }
    local tableView = TrillionChallengeTableView.new(param)
    tbView:addChild(tableView)
    local rankList = self._data:getRankList()
    tableView:reload(rankList)
    self._rankTableView = tableView
end

-- 时间
function TrillionChallengeMainLayer:initTimeUI()
    local parent = self:findChild("node_time")
    local timeView  = util_createView("GameModule.TrillionChallenge.views.TrillionChallengeMainTimeUI")
    parent:addChild(timeView)
end
-- 舞台
function TrillionChallengeMainLayer:initStageUI()
    local parent = self:findChild("node_stage")
    local aniView = util_createAnimation("Activity/Activity_TrillionChallenge/csb/main/TrillionChallenge_Main_stage.csb")
    parent:addChild(aniView)
end

-- 内容显隐
function TrillionChallengeMainLayer:updateContentState()
    local nodeTournament = self:findChild("node_tournament")
    local nodeChallenge = self:findChild("node_rank")

    -- 内容反着的
    nodeTournament:setVisible(self._btnTag == BTN_TYPE.CHALLENGE)
    nodeChallenge:setVisible(self._btnTag == BTN_TYPE.TOURNAMENT)

    -- 按钮状态
    self:updateBtnState()
end
-- 按钮状态
function TrillionChallengeMainLayer:updateBtnState()
    local spBtnTournament = self:findChild("sp_btn_tournament")
    local spBtnChallenge = self:findChild("sp_btn_challenge")
    local btnTournament = self:findChild("btn_tournament")
    local btnChallenge = self:findChild("btn_challenge")

    spBtnTournament:setVisible(self._btnTag == BTN_TYPE.TOURNAMENT)
    spBtnChallenge:setVisible(self._btnTag == BTN_TYPE.CHALLENGE)
    btnChallenge:setVisible(self._btnTag == BTN_TYPE.TOURNAMENT)
    btnTournament:setVisible(self._btnTag == BTN_TYPE.CHALLENGE)
end

function TrillionChallengeMainLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_challenge" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self._btnTag = BTN_TYPE.CHALLENGE
        self:updateContentState()
    elseif name == "btn_tournament" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self._btnTag = BTN_TYPE.TOURNAMENT
        self:updateContentState()
        gLobalNoticManager:postNotification(TrillionChallengeConfig.EVENT_NAME.NOTIFY_TRILLION_CHALLENGE_ENTRY_RANK_UP_RESET)
    elseif name == "btn_close" then
        self:closeUI()
    end
end

function TrillionChallengeMainLayer:closeUI()
    if self._bClose then
        return
    end
    self._bClose = true
    
    TrillionChallengeMainLayer.super.closeUI(self)
end

-- 检查领取任务宝箱
function TrillionChallengeMainLayer:checkColBoxTask()
    local taskDataList = self._data:getTaskList()
    local curWin = self._data:getCurTotalWin()
    local canColIdxList = {}
    local orderList = {1,2,5,3,4}
    for i=1, #orderList do
        local idx = orderList[i]
        local taskData = taskDataList[idx]
        if taskData and taskData:checkCanCol(curWin) then
            table.insert(canColIdxList, taskData:getTaskOrder()) 
        end
    end
    self._canColIdxList = canColIdxList
    if #canColIdxList > 0 then
        G_GetMgr(G_REF.TrillionChallenge):sendCollectReq()
    end
end

-- 收到最新排行榜信息
function TrillionChallengeMainLayer:onReciveRankInfoEvt()
    local prizePool = self._data:getPrizePool()
    self._prizePoolView:updateUI(prizePool)

    local rankList = self._data:getRankList()
    self._rankTableView:reload(rankList)
end

-- 领取到宝箱奖励
function TrillionChallengeMainLayer:onReciveBoxTaskColEvt(_rewardData)
    if not _rewardData then
        return
    end
    
    self._data = G_GetMgr(G_REF.TrillionChallenge):getRunningData()
    for _, idx in pairs(self._canColIdxList) do
        local box = self._boxViewList[idx]
        local data = self._data:getTaskDataByOrder(idx)
        box:updateBoxState(data)
    end
    self._rewardData = _rewardData
    local flyLayer = util_createView("GameModule.TrillionChallenge.views.tournament.TrillionChallengeFlyLayer", self._canColIdxList)
    G_GetMgr(G_REF.TrillionChallenge):showLayer(flyLayer, ViewZorder.ZORDER_GUIDE)
    flyLayer:playFlyAction(util_node_handler(self, self.openRewardLayer))
    self._canColIdxList = {}
end

-- 打开奖励弹板
function TrillionChallengeMainLayer:openRewardLayer()
    if self._bHadOpen then
        return
    end
    self._bHadOpen = true
    G_GetMgr(G_REF.TrillionChallenge):showRewardLayer(self._rewardData)
end

function TrillionChallengeMainLayer:registerListener()
    TrillionChallengeMainLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(self, "onReciveRankInfoEvt", TrillionChallengeConfig.EVENT_NAME.ONRECIEVE_TRILLION_CHALLENGE_SUCCESS) --收到最新排行榜信息
    gLobalNoticManager:addObserver(self, "onReciveBoxTaskColEvt", TrillionChallengeConfig.EVENT_NAME.ONRECIEVE_TRILLION_BOX_TASK_COL_SUCCESS) --领取到宝箱奖励
end

return TrillionChallengeMainLayer