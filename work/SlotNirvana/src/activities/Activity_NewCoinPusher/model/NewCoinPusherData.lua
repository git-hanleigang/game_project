local BaseActivityData = require "baseActivity.BaseActivityData"
local BaseActivityRankCfg = require "baseActivity.BaseActivityRankCfg"
local ShopItem = util_require("data.baseDatas.ShopItem")
local PushCoin = util_require("activities.Activity_NewCoinPusher.model.PushCoin")
local NewCoinPusherPassData = util_require("activities.Activity_NewCoinPusher.model.NewCoinPusherPassData")
local NewCoinPusherData = class("NewCoinPusherData", BaseActivityData)
-- FIX IOS 139
NewCoinPusherData.difficulty = nil --难度
-- message NewCoinPusher {
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
--     optional NewCoinPusherPass passResult = 16;pass相关数据
--     optional int32 carCoinNum = 17;//小车金币数量
--     repeated NewCoinPusherFruitMachine fruitMachineList = 18;//水果机数据
--   }
function NewCoinPusherData:ctor()
    self.m_passData = NewCoinPusherPassData:create()
end
----------------------------------parseData S -----------------------------------------
function NewCoinPusherData:parseData(data, isNetData)
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
    self.carCoinNum = tonumber(data.carCoinNum)
    self:parsePanelData(data.panels)
    self:parseTotleRewardData(data.totalReward)
    self:parsePassData(data.passData)
    self:parseFruitMachineData(data.fruitMachineList)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.NewCoinPusher})
    util_nextFrameFunc(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_ACTIVITY_DATA, {name = ACTIVITY_REF.NewCoinPusher})
        end
    )
end

function NewCoinPusherData:parsePanelData(data)
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

function NewCoinPusherData:parseTotleRewardData(data)
    assert(data and table.nums(data) > 0, "blast活动 章节列表数据异常")

    self.totleRewardsItem = {} -- 其他奖励物品
    for j, reward in ipairs(data) do
        local shopItem = ShopItem:create()
        shopItem:parseData(reward)

        table.insert(self.totleRewardsItem, shopItem)
    end
end

function NewCoinPusherData:parseRankData(_data)
    self.p_rankConfig = BaseActivityRankCfg:create()
    self.p_rankConfig:parseData(_data)
    local myRankConfigInfo = self.p_rankConfig:getMyRankConfig()
    if myRankConfigInfo then
        release_print("_result.myRank 4 is " .. tostring(myRankConfigInfo))
        self:setRank(myRankConfigInfo.p_rank)
    end
end

-- 解析 pass 数据
function NewCoinPusherData:parsePassData(_data)
    if _data then
        self.m_passData:parseData(_data)
    end
end

-- 解析 水果机 数据
function NewCoinPusherData:parseFruitMachineData(_data)
    self.fruitMachineList = {}
    for i, panel in ipairs(_data) do
        -- dump(panel, "panel Data --")
        local fruitMachineData = {}
        fruitMachineData.index = tonumber(panel.index) -- 对应的第几章节
        fruitMachineData.rewardType = tostring(panel.rewardType) -- status状态 COMPLETED PLAY LOCKD
        fruitMachineData.value = tonumber(panel.value) -- coins奖励金币
        table.insert(self.fruitMachineList, fruitMachineData)
    end
end

----------------------------------parseData E -----------------------------------------

----------------------------------pub FUNC  S -----------------------------------------
--获取上次数据
function NewCoinPusherData:getPreData()
    return self.preData
end

--获取入口位置 1：左边，0：右边
function NewCoinPusherData:getPositionBar()
    return 1
end

--目前进行章节
function NewCoinPusherData:getStage()
    return self.stage
end

--第几个轮回
function NewCoinPusherData:getRound()
    return self.round
end

--可push次数
function NewCoinPusherData:getPushes()
    return self.pushes
end

--最大可push次数
function NewCoinPusherData:getMaxPushes()
    return self.maxPushes
end

--当前能量
function NewCoinPusherData:getEnergy()
    return self.energy
end

--最大能量
function NewCoinPusherData:getMaxEnergy()
    return self.maxEnergy
end

--quest中是否开启blast
function NewCoinPusherData:getQuestOpenPusher()
    return self.questOpenPusher
end

--获取当前章节数据 by 章节id
function NewCoinPusherData:getStageDataById(_id)
    return self.panels[_id]
end

--获取当前章节数据 by 章节id
function NewCoinPusherData:getStageDataStateById(_id)
    -- return "PLAY"
    return self.panels[_id].status
end

--获取当前章节数据 by 章节id
function NewCoinPusherData:getStageDataBaseCoinsById(_id)
    return self.panels[_id].baseCoins
end

function NewCoinPusherData:getPanels()
    return self.panels
end

function NewCoinPusherData:getPanelsCount()
    return table.nums(self.panels)
end

function NewCoinPusherData:getTotleRewardCoins()
    return self.totleRewardCoins
end

function NewCoinPusherData:getTotleRewardItem()
    return self.totleRewardsItem
end

function NewCoinPusherData:getSequence()
    return self.round
end

function NewCoinPusherData:getCurrent()
    return self.stage
end

function NewCoinPusherData:getBuffUpWallsLT()
    local leftTimes = self:getBuffLTByType(BUFFTYPY.BUFFTYPE_NEWCOINPUSHER_WALL)
    return leftTimes
end

function NewCoinPusherData:getBuffPusherLT()
    local leftTimes = self:getBuffLTByType(BUFFTYPY.BUFFTYPE_NEWCOINPUSHER_PUSHER)
    return leftTimes
end

function NewCoinPusherData:getBuffPrizeLT()
    local leftTimes = self:getBuffLTByType(BUFFTYPY.BUFFTYPE_NEWCOINPUSHER_PRIZE)
    return leftTimes
end

function NewCoinPusherData:getBuffLTByType(type)
    local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(type)
    return leftTimes
end

function NewCoinPusherData:getStagePushCoinsData(id)
    local stage = self:getStageDataById(id)
    local pushCoins = stage.pushCoins
    return pushCoins
end

function NewCoinPusherData:initNewCoinPusherGuideData(extraData)
    self.extraData = extraData
end

function NewCoinPusherData:getNewCoinPusherGuideData()
    return self.extraData or {}
    -- return {}
end

function NewCoinPusherData:getNewCoinPusherPassData()
    return self.m_passData or nil
end

-- 获得小车金币数量
function NewCoinPusherData:getCarCoinNum()
    return self.carCoinNum or 0
end

-- 获得水果机数据
function NewCoinPusherData:getFruitMachineData()
    return self.fruitMachineList or {}
end

function NewCoinPusherData:getRankCfg()
    return self.p_rankConfig
end

-- 获得水果机数据通过索引
function NewCoinPusherData:getFruitMachineDataByIndex(_index)
    for i,v in ipairs(self.fruitMachineList) do
        if v.index == _index then
            return v
        end
    end
    return nil
end

function NewCoinPusherData:checkGuideFinsh(iStep)
    local guideFinishSteps = self:getNewCoinPusherGuideData()
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
-- function NewCoinPusherData.getNewCoinPusherPromotionActivity()
--     local activityDatas = {}
--     local coinPusherData = G_GetActivityDataByRef(ACTIVITY_REF.NewCoinPusherSale)
--     if coinPusherData then
--         table.insert(activityDatas, coinPusherData)
--     end

--     return activityDatas
-- end

--组装运行时数据 主要用于转为json 保存到本地
function NewCoinPusherData:getRuningUserData()
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
function NewCoinPusherData:getRuningData()
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

return NewCoinPusherData
