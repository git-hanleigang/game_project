--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 12:18:30
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 15:32:18
FilePath: /SlotNirvana/src/views/lobby/LevelTrillionChallengeHallNode.lua
Description: 亿万赢钱挑战 展示图
--]]
local LevelFeature = util_require("views.lobby.LevelFeature")
local LevelTrillionChallengeHallNode = class("LevelTrillionChallengeHallNode", LevelFeature)
local TrillionChallengeConfig = util_require("GameModule.TrillionChallenge.config.TrillionChallengeConfig")
local TrillionChallengeTableView = util_require("GameModule.TrillionChallenge.views.challenge.TrillionChallengeTableView")

function LevelTrillionChallengeHallNode:createCsb()
    LevelTrillionChallengeHallNode.super.createCsb(self)

    self._data = G_GetMgr(G_REF.TrillionChallenge):getRunningData()
    local rank = self._data:getCurRank()
    local bInRank = rank > 0
    if bInRank then
        self:createCsbNode("Icons/TrillionChallengeHall.csb")
        self:initRankUI()

        G_GetMgr(G_REF.TrillionChallenge):sendGetRankDataReq()
        gLobalNoticManager:addObserver(self, "onReciveRankInfoEvt", TrillionChallengeConfig.EVENT_NAME.ONRECIEVE_TRILLION_CHALLENGE_SUCCESS) --收到最新排行榜信息
    else
        self:createCsbNode("Icons/TrillionChallengeSlide.csb")
    end

    schedule(self, util_node_handler(self, self.updateDt), 1)
end

-- 初始化节点
function LevelTrillionChallengeHallNode:initCsbNodes()
    self._lbCoins = self:findChild("lb_coin")
    if self._lbCoins then
        self._intLimit = self._lbCoins:getContentSize().width
    end

    self._coinsBg = self:findChild("sp_coin_bg")
    if self._coinsBg then
        self._coinsBg:setVisible(false)
    end
end

function LevelTrillionChallengeHallNode:initRankUI()
    -- 奖池金币
    local prizePool = self._data:getPrizePool()
    self:updatePrizePoolUI(prizePool)
    performWithDelay(self,function()
        local prizePool = self._data:getPrizePool()
        self:updatePrizePoolUI(prizePool)
    end, 1)

    -- 排名
    local tbView = self:findChild("rewardList")
    tbView:setSwallowTouches(false)
    local size = tbView:getContentSize()
    local param = {
        tableSize = size,
        parentPanel = tbView,
        directionType = 2,
        bHallNode = true
    }
    local tableView = TrillionChallengeTableView.new(param)
    tbView:addChild(tableView)
    local rankList = self._data:getRankList()
    tableView:reload(rankList)
    self._rankTableView = tableView
    self._rankTableView:getTable():setSwallowTouches(false)
    
end
function LevelTrillionChallengeHallNode:updatePrizePoolUI(_coins)
    local coins = _coins or 0
    if coins > 0 then
        G_GetMgr(G_REF.TrillionChallenge):registerCoinAddComponent(self._lbCoins, self._intLimit, 12)
    else
        self._lbCoins:setString(util_formatCoins(coins, 99))
    end
    util_alignCenter(
        {
            {node = self:findChild("sp_coin")},
            {node = self._lbCoins, alignX = 5}
        },
        nil,
        800*0.22
    )
    self._coinsBg:setVisible(coins > 0)
end

function LevelTrillionChallengeHallNode:updateDt()
    if not G_GetMgr(G_REF.TrillionChallenge):isRunning() then
        self:stopAllActions()
        gLobalNoticManager:postNotification(TrillionChallengeConfig.EVENT_NAME.NOTIFY_REMOVE_TRILLION_CHALLENGE_HALL)
    end
end

function LevelTrillionChallengeHallNode:clickFunc(sender)
    G_GetMgr(G_REF.TrillionChallenge):showMainLayer()
end

-- 收到最新排行榜信息
function LevelTrillionChallengeHallNode:onReciveRankInfoEvt()
    local prizePool = self._data:getPrizePool()
    self:updatePrizePoolUI(prizePool)

    local rankList = self._data:getRankList()
    self._rankTableView:reload(rankList)
end

return LevelTrillionChallengeHallNode