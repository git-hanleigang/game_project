local BaseActivityData = require "baseActivity.BaseActivityData"
local BaseActivityRankCfg = require "baseActivity.BaseActivityRankCfg"
local ShopItem = util_require("data.baseDatas.ShopItem")
local PushCoin = util_require("activities.Activity_CoinPusher.model.PushCoin")
local CoinPusherPassData = util_require("activities.Activity_CoinPusher.model.CoinPusherPassData")
local CoinPusherData = class("CoinPusherData", BaseActivityData)
-- FIX IOS 139
CoinPusherData.difficulty = nil --难度
-- message CoinPusher {
--     optional int32 expire = 1; //剩余秒数
--     optional int64 expireAt = 2; //过期时间
--     optional string activityId = 3; //活动id
--     optional int32 stage = 4; //目前进行的章节
--     repeated PusherPanelDetail panels = 5; //各章节的数据
--     optional int32 round = 6; //第几个轮回
--     optional int32 pushes = 7; // 可push次数
--     optional int32 maxPushes = 8; // 最大可push次数
--     optional int32 energy = 9; //当前能量
--     optional int32 maxEnergy = 10; //最大能量
--     optional int32 questOpenPusher = 11;  //quest中是否开启blast
--     optional int64 rewardCoins = 12; //奖励金币
--     repeated ShopItem totalReward = 13; //全部完成奖励
--     optional int32 rankUp = 14; //排行榜排名上升的幅度
--     optional int32 rank = 15; //排行榜排名
--     optional CoinPusherPass passResult = 16;pass相关数据
--   }
function CoinPusherData:ctor()
    CoinPusherData.super.ctor(self)
    self.m_passData = CoinPusherPassData:create()
end
----------------------------------parseData S -----------------------------------------
function CoinPusherData:parseData(data, isNetData)
    self.preData = self.data
    BaseActivityData.parseData(self, data, isNetData)
    self.stage = tonumber(data.stage) --目前进行章节
    self.round = tonumber(data.round) --第几个轮回
    self.pushes = tonumber(data.pushes) --可以放置次数
    self.maxPushes = tonumber(data.maxPushes)
    self.energy = tonumber(data.energy) --当前能量
    self.maxEnergy = tonumber(data.maxEnergy) --最大能量
    self.questOpenPusher = tonumber(data.questOpenPusher)
    self.totleRewardCoins = tonumber(data.rewardCoins)
    self:parsePanelData(data.panels)
    self:parseTotleRewardData(data.totalReward)
    self:parsePassData(data.passData)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.CoinPusher})
    util_nextFrameFunc(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_ACTIVITY_DATA, {name = ACTIVITY_REF.CoinPusher})
        end
    )
end

function CoinPusherData:parsePanelData(data)
    assert(data and table.nums(data) > 0, "blast活动 章节列表数据异常")
    self.panels = {}
    for i, panel in ipairs(data) do
        -- dump(panel, "panel Data --")
        local panelData = {}
        panelData.stage = tonumber(panel.stage) -- 对应的第几章节
        panelData.status = tostring(panel.status) -- status状态 COMPLETED PLAY LOCKD
        panelData.coins = tonumber(panel.coins) -- coins奖励金币
        panelData.baseCoins = tonumber(panel.baseCoins) -- 台面金币数据
        panelData.stageCoins = tonumber(panel.stageCoins)
        -- 章节奖励加成
        panelData.data = tostring(panel.data) --客户端金币数据

        panelData.score = tonumber(panel.score) --当前过关分数
        panelData.targetScore = tonumber(panel.targetScore) --过关分数

        panelData.rewards = {} -- 其他奖励物品
        for j, reward in ipairs(panel.rewards) do
            local shopItem = ShopItem:create()
            shopItem:parseData(reward)
            table.insert(panelData.rewards, shopItem)
        end
        panelData.pushCoins = {}
        for j, dataPushCoin in ipairs(panel.pushCoins) do
            local pushCoin = PushCoin:create()
            pushCoin:parseData(dataPushCoin)
            table.insert(panelData.pushCoins, pushCoin)
        end

        self.panels[panelData.stage] = panelData
    end
end

function CoinPusherData:parseTotleRewardData(data)
    assert(data and table.nums(data) > 0, "blast活动 章节列表数据异常")

    self.totleRewardsItem = {} -- 其他奖励物品
    for j, reward in ipairs(data) do
        local shopItem = ShopItem:create()
        shopItem:parseData(reward)

        table.insert(self.totleRewardsItem, shopItem)
    end
end

function CoinPusherData:parseRankData(_data)
    self.p_rankConfig = BaseActivityRankCfg:create()
    self.p_rankConfig:parseData(_data)
    local myRankConfigInfo = self.p_rankConfig:getMyRankConfig()
    if myRankConfigInfo then
        release_print("_result.myRank 4 is " .. tostring(myRankConfigInfo))
        self:setRank(myRankConfigInfo.p_rank)
    end
end

function CoinPusherData:getRankCfg()
    return self.p_rankConfig
end


-- 解析 pass 数据
function CoinPusherData:parsePassData(_data)
    if _data then
        self.m_passData:parseData(_data)
    end
end

----------------------------------parseData E -----------------------------------------

----------------------------------pub FUNC  S -----------------------------------------
--获取上次数据
function CoinPusherData:getPreData()
    return self.preData
end

--获取入口位置 1：左边，0：右边
function CoinPusherData:getPositionBar()
    return 1
end

--目前进行章节
function CoinPusherData:getStage()
    return self.stage
end

--第几个轮回
function CoinPusherData:getRound()
    return self.round
end

--可push次数
function CoinPusherData:getPushes()
    return self.pushes
end

--最大可push次数
function CoinPusherData:getMaxPushes()
    return self.maxPushes
end

--当前能量
function CoinPusherData:getEnergy()
    return self.energy
end

--最大能量
function CoinPusherData:getMaxEnergy()
    return self.maxEnergy
end

--quest中是否开启blast
function CoinPusherData:getQuestOpenPusher()
    return self.questOpenPusher
end

--获取当前章节数据 by 章节id
function CoinPusherData:getStageDataById(_id)
    return self.panels[_id]
end

--获取当前章节数据 by 章节id
function CoinPusherData:getStageDataStateById(_id)
    -- return "PLAY"
    return self.panels[_id].status
end

--获取当前章节数据 by 章节id
function CoinPusherData:getStageDataBaseCoinsById(_id)
    return self.panels[_id].baseCoins
end

function CoinPusherData:getPanels()
    return self.panels
end

function CoinPusherData:getPanelsCount()
    return table.nums(self.panels)
end

function CoinPusherData:getTotleRewardCoins()
    return self.totleRewardCoins
end

function CoinPusherData:getTotleRewardItem()
    return self.totleRewardsItem
end

function CoinPusherData:getSequence()
    return self.round
end

function CoinPusherData:getCurrent()
    return self.stage
end

function CoinPusherData:getBuffUpWallsLT()
    local leftTimes = self:getBuffLTByType(BUFFTYPY.BUFFTYPE_COINPUSHER_WALL)
    return leftTimes
end

function CoinPusherData:getBuffPusherLT()
    local leftTimes = self:getBuffLTByType(BUFFTYPY.BUFFTYPE_COINPUSHER_PUSHER)
    return leftTimes
end

function CoinPusherData:getBuffPrizeLT()
    local leftTimes = self:getBuffLTByType(BUFFTYPY.BUFFTYPE_COINPUSHER_PRIZE)
    return leftTimes
end

function CoinPusherData:getBuffLTByType(type)
    local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(type)
    return leftTimes
end

function CoinPusherData:getStagePushCoinsData(id)
    local stage = self:getStageDataById(id)
    local pushCoins = stage.pushCoins
    return pushCoins
end

function CoinPusherData:initCoinPusherGuideData(extraData)
    self.extraData = extraData
end

function CoinPusherData:getCoinPusherGuideData()
    return self.extraData or {}
    -- return {}
end

function CoinPusherData:getCoinPusherPassData()
    return self.m_passData or nil
end

function CoinPusherData:checkGuideFinsh(iStep)
    local guideFinishSteps = self:getCoinPusherGuideData()
    if not guideFinishSteps then
        return false
    end

    for i = 1, table.nums(guideFinishSteps) do
        local stepNum = guideFinishSteps[i]
        if stepNum == iStep then
            return true
        end
    end

    return false
end

--获取促销数据
-- function CoinPusherData.getCoinPusherPromotionActivity()
--     local activityDatas = {}
--     local coinPusherData = G_GetActivityDataByRef(ACTIVITY_REF.CoinPusherSale)
--     if coinPusherData then
--         table.insert(activityDatas, coinPusherData)
--     end

--     return activityDatas
-- end

--组装运行时数据 主要用于转为json 保存到本地
function CoinPusherData:getRuningUserData()
    local runingData = {}

    runingData.Stage = self:getStage()
    runingData.Round = self:getRound()
    runingData.Pushes = self:getPushes()

    runingData.MaxPushes = self:getMaxPushes()
    runingData.Energy = self:getEnergy()
    runingData.MaxEnergy = self:getMaxEnergy()

    return runingData
end

--组装运行时数据
function CoinPusherData:getRuningData()
    local nowStage = self:getStage()
    local plane = self:getStageDataById(nowStage)

    local runingData = {}
    runingData.Stage = self:getStage()
    runingData.Round = self:getRound()
    runingData.Pushes = self:getPushes()

    runingData.MaxPushes = self:getMaxPushes()
    runingData.Energy = self:getEnergy()
    runingData.MaxEnergy = self:getMaxEnergy()

    if plane then
        runingData.Status = plane.status
        runingData.Coins = plane.coins
        runingData.BaseCoins = plane.baseCoins
        runingData.StageCoins = plane.stageCoins
        runingData.Data = plane.data

        runingData.Score = plane.score
        runingData.TargetScore = plane.targetScore
    end
    return runingData
end
----------------------------------pub FUNC  E -----------------------------------------

return CoinPusherData
