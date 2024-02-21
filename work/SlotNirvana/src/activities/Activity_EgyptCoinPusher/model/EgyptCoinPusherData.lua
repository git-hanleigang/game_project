local BaseActivityData = require "baseActivity.BaseActivityData"
local BaseActivityRankCfg = require "baseActivity.BaseActivityRankCfg"
local ShopItem = util_require("data.baseDatas.ShopItem")
local PushCoin = util_require("activities.Activity_EgyptCoinPusher.model.PushCoin")
local EgyptCoinPusherData = class("EgyptCoinPusherData", BaseActivityData)
--[[
    message CoinPusherV3 {
        optional int32 expire = 1; //剩余秒数
        optional int64 expireAt = 2; //过期时间
        optional string activityId = 3; //活动id
        optional int32 stage = 4; //目前进行的章节
        repeated CoinPusherV3Panel panels = 5; //各章节的数据
        optional int32 round = 6; //第几个轮回
        optional int32 pushes = 7; // 可push次数
        optional int32 maxPushes = 8; // 最大可push次数
        optional int32 energy = 9; //当前能量
        optional int32 maxEnergy = 10; //最大能量
        optional int32 questOpenPusher = 11;  //quest中是否开启blast
        optional string rewardCoins = 12; //奖励金币
        repeated ShopItem totalReward = 13; //全部完成奖励
        optional int32 leftWildLock = 14;//剩余锁定wild次数
        optional int32 maxWildLock = 15;//最大锁定wild次数
        repeated string coinList = 16; //收集的金币
        repeated ShopItem itemList = 17; //收集的物品
        repeated int64 gemList = 18; //收集的钻石
    }
]]
function EgyptCoinPusherData:ctor()
    EgyptCoinPusherData.super.ctor(self)
    self.totleRewardCoins = toLongNumber(0)
    
end
----------------------------------parseData S -----------------------------------------
function EgyptCoinPusherData:parseData(data, isNetData)
    EgyptCoinPusherData.super.parseData(self, data, isNetData)
    self.stage = tonumber(data.stage) --目前进行章节
    self.round = tonumber(data.round) --第几个轮回
    self.pushes = tonumber(data.pushes) --可以放置次数
    self.maxPushes = tonumber(data.maxPushes)
    self.energy = tonumber(data.energy) --当前能量
    self.maxEnergy = tonumber(data.maxEnergy) --最大能量
    self.questOpenPusher = tonumber(data.questOpenPusher)
    self.totleRewardCoins:setNum(data.rewardCoins)
    self.leftWildLock = tonumber(data.leftWildLock or 0)
    self.maxWildLock = tonumber(data.maxWildLock or 0)
    self.collectCoins = self:parseCollectCoins(data.coinList)
    self.collectItems = self:parseShopItem(data.itemList)
    self.collectGems = self:parseCollectGems(data.gemList)
    self.panels = self:parsePanelData(data.panels)
    self.totleRewardsItem = self:parseShopItem(data.totalReward)

    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.EgyptCoinPusher})
    util_nextFrameFunc(
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_ACTIVITY_DATA, {name = ACTIVITY_REF.EgyptCoinPusher})
        end
    )
end

--[[
    message CoinPusherV3Panel {
        optional int32 stage = 1; // 对应的第几章节
        optional string status = 2; //状态  COMPLETED,PLAY,LOCKED
        optional string coins = 3; //奖励金币
        repeated ShopItem rewards = 4; //其他奖励物品
        repeated CoinPusherV3Coin pushCoins = 5; //台面金币数据
        optional int32 stageCoins = 6; //章节奖励加成
        optional string baseCoins = 7; //基础奖励金币
        optional string data = 8; //客户都安台面金币数据
        optional int32 score = 9; //当前分
        optional int32 targetScore = 10; //目标分
        optional int32 spinTimes = 11; //剩余Spin次数
        repeated CoinPusherV3Coin initPushCoins = 12; //初始台面金币数据
    }
]]
function EgyptCoinPusherData:parsePanelData(data)
    local panels = {}
    for i, panel in ipairs(data) do
        local panelData = {}
        panelData.stage = tonumber(panel.stage) -- 对应的第几章节
        panelData.status = tostring(panel.status) -- status状态 COMPLETED PLAY LOCKD
        panelData.coins = toLongNumber(panel.coins) -- coins奖励金币
        panelData.baseCoins = toLongNumber(panel.baseCoins) -- 台面金币数据
        panelData.stageCoins = tonumber(panel.stageCoins) -- 章节奖励加成
        panelData.data = tostring(panel.data) --客户端金币数据
        panelData.score = tonumber(panel.score) --当前过关分数
        panelData.targetScore = tonumber(panel.targetScore) --过关分数
        panelData.rewards = self:parseShopItem(panel.rewards) -- 其他奖励物品
        panelData.pushCoins = {}
        for j, dataPushCoin in ipairs(panel.pushCoins) do
            local pushCoin = PushCoin:create()
            pushCoin:parseData(dataPushCoin.type, dataPushCoin.count)
            table.insert(panelData.pushCoins, pushCoin)
        end
        panelData.longResetCoins = {}
        for j, dataPushCoin in ipairs(panel.initPushCoins) do
            local pushCoin = PushCoin:create()
            pushCoin:parseData(dataPushCoin.type, dataPushCoin.count)
            table.insert(panelData.longResetCoins, pushCoin)
        end
        panelData.spinTimes = tonumber(panel.spinTimes) --剩余Spin次数
        panels[panelData.stage] = panelData
    end
    return panels
end

-- 解析道具
function EgyptCoinPusherData:parseShopItem(data)
    local itemList = {}
    for i, reward in ipairs(data) do
        local shopItem = ShopItem:create()
        shopItem:parseData(reward)
        table.insert(itemList, shopItem)
    end
    return itemList
end

function EgyptCoinPusherData:parseCollectCoins(data)
    local coinsList = {}
    if data and #data > 0 then
        for i, v in ipairs(data) do
            table.insert(coinsList, toLongNumber(v))
        end
    end
    return coinsList
end

function EgyptCoinPusherData:parseCollectGems(data)
    local gemsList = {}
    if data and #data > 0 then
        for i, v in ipairs(data) do
            table.insert(gemsList, tonumber(v))
        end
    end
    return gemsList
end

function EgyptCoinPusherData:parseRankData(_data)
    self.p_rankConfig = BaseActivityRankCfg:create()
    self.p_rankConfig:parseData(_data)
    local myRankConfigInfo = self.p_rankConfig:getMyRankConfig()
    if myRankConfigInfo then
        release_print("_result.myRank 4 is " .. tostring(myRankConfigInfo))
        self:setRank(myRankConfigInfo.p_rank)
    end
end
----------------------------------parseData E -----------------------------------------

----------------------------------pub FUNC  S -----------------------------------------
--获取入口位置 1：左边，0：右边
function EgyptCoinPusherData:getPositionBar()
    return 1
end

--目前进行章节
function EgyptCoinPusherData:getStage()
    return self.stage
end

--第几个轮回
function EgyptCoinPusherData:getRound()
    return self.round
end

--可push次数
function EgyptCoinPusherData:getPushes()
    return self.pushes
end

--最大可push次数
function EgyptCoinPusherData:getMaxPushes()
    return self.maxPushes
end

--当前能量
function EgyptCoinPusherData:getEnergy()
    return self.energy
end

--最大能量
function EgyptCoinPusherData:getMaxEnergy()
    return self.maxEnergy
end

--quest中是否开启推币机
function EgyptCoinPusherData:getQuestOpenPusher()
    return self.questOpenPusher
end

-- 最大wild Buff次数
function EgyptCoinPusherData:getMaxWildLock()
    return self.maxWildLock or 0
end

-- 剩余wild Buff次数
function EgyptCoinPusherData:getLeftWildLock()
    return self.leftWildLock or 0
end

--获取当前章节数据 by 章节id
function EgyptCoinPusherData:getStageDataById(_id)
    return self.panels[_id]
end

--获取当前章节数据 by 章节id
function EgyptCoinPusherData:getStageDataStateById(_id)
    -- return "PLAY"
    return self.panels[_id].status
end

--获取当前章节数据 by 章节id
function EgyptCoinPusherData:getStageDataBaseCoinsById(_id)
    return self.panels[_id].baseCoins
end

function EgyptCoinPusherData:getPanels()
    return self.panels
end

function EgyptCoinPusherData:getPanelsCount()
    return table.nums(self.panels)
end

function EgyptCoinPusherData:getTotleRewardCoins()
    return self.totleRewardCoins
end

function EgyptCoinPusherData:getTotleRewardItem()
    return self.totleRewardsItem
end

function EgyptCoinPusherData:getSequence()
    return self.round
end

function EgyptCoinPusherData:getCurrent()
    return self.stage
end

function EgyptCoinPusherData:getCollectCoins()
    return self.collectCoins or {}
end

function EgyptCoinPusherData:getCollectItems()
    return self.collectItems or {}
end

function EgyptCoinPusherData:getCollectGems()
    return self.collectGems or {}
end

-- 金币，宝石都变成道具
function EgyptCoinPusherData:getAllCollectItem()
    local itemList = {}
    local rewardCoins = self:getCollectCoins()
    local rewardItems = self:getCollectItems()
    local rewardGems = self:getCollectGems()
    if rewardCoins and #rewardCoins > 0 then
        for i, v in ipairs(rewardCoins) do
            local itemData = gLobalItemManager:createLocalItemData("Coins", v)
            table.insert(itemList, itemData)
        end
    end
    if rewardItems then
        for i, v in ipairs(rewardItems) do
            local shopItem = gLobalItemManager:createLocalItemData(v.p_icon, v.p_num, v)
            table.insert(itemList, shopItem)
        end
    end
    if rewardGems and #rewardGems > 0 then
        for i, v in ipairs(rewardGems) do
            local itemData = gLobalItemManager:createLocalItemData("Gem", v, {p_mark = {ITEM_MARK_TYPE.CENTER_BUFF}})
            table.insert(itemList, itemData)
        end
    end
    return itemList
end

-- 升墙buff
function EgyptCoinPusherData:getBuffUpWallsLT()
    local leftTimes = self:getBuffLTByType(BUFFTYPY.BUFFTYPE_EGYPTCOINPUSHER_WALL)
    return leftTimes
end

-- 掉落双倍buff
function EgyptCoinPusherData:getBuffDoubleItemLT()
    local leftTimes = self:getBuffLTByType(BUFFTYPY.BUFFTYPE_EGYPTCOINPUSHER_ITEM)
    return leftTimes
end

-- 双倍奖励buff
function EgyptCoinPusherData:getBuffPrizeLT()
    local leftTimes = self:getBuffLTByType(BUFFTYPY.BUFFTYPE_EGYPTCOINPUSHER_PRIZE)
    return leftTimes
end

function EgyptCoinPusherData:getBuffLTByType(type)
    local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(type)
    return leftTimes
end

function EgyptCoinPusherData:getStagePushCoinsData(id)
    local stage = self:getStageDataById(id)
    local pushCoins = stage.pushCoins
    return pushCoins
end

function EgyptCoinPusherData:getRankCfg()
    return self.p_rankConfig
end

--组装运行时数据 主要用于转为json 保存到本地
function EgyptCoinPusherData:getRuningUserData()
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
function EgyptCoinPusherData:getRuningData()
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
        runingData.SpinTimes = plane.spinTimes
    end
    return runingData
end
----------------------------------pub FUNC  E -----------------------------------------
-----老虎机信息
function EgyptCoinPusherData:parseGameSoltData(_data)
    if _data.reel and #_data.reel > 0 then
        self:parseEndRells(_data.reel)
    end

    self.m_slotSymbol = _data.symbol

    self:checkIsQuick()

    if _data.symbol == "SYMBOL_OTHER" then
        self.m_useSlotAct = false
    else
        self.m_useSlotAct = true
    end
end

function EgyptCoinPusherData:checkIsQuick()
    local endRells  = self.m_endRells[1]
    self.m_useQuick = false
    self.m_useQuickPush = false
    if  endRells[1] == 6 and (endRells[2] == 3 or endRells[2] == 5) then
        self.m_useQuick = true
    elseif endRells[1] == 3 or endRells[1] == 5 then
        if endRells[1] == endRells[2] or  endRells[2] == 6 then
            self.m_useQuick = true
        end
    end

    if  endRells[1] == 6 and endRells[2] == 3  then
        self.m_useQuickPush = true
    elseif endRells[1] == 3 and (3 == endRells[2] or  endRells[2] == 6) then
        self.m_useQuickPush = true
    end
end

function EgyptCoinPusherData:getSlotSymbolTypeIndex()
    local result = 0
    if self.m_slotSymbol == "SYMBOL_COIN_SHOWER" then
        result = 5
    elseif self.m_slotSymbol == "SYMBOL_HUGE_COINS" then
        result = 6
    elseif self.m_slotSymbol == "SYMBOL_GEM" then
        result = 7
    elseif self.m_slotSymbol == "SYMBOL_BUFF_WALL" then
        result = 8
    elseif self.m_slotSymbol == "SYMBOL_BUFF_DOUBLE_AWARD" then
        result = 9
    elseif self.m_slotSymbol == "SYMBOL_BUFF_DOUBLE_ENERGY" then
        result = 10
    end
    return result
end


function EgyptCoinPusherData:parseEndRells(_data)
    self.m_endRells = {}
    table.insert(self.m_endRells,_data)
end

function EgyptCoinPusherData:getEndReels()
    return self.m_endRells or {}
end

function EgyptCoinPusherData:getStageLongPusherResetCoinsData(id)
    local stage = self:getStageDataById(id)
    local pushCoins = stage.longResetCoins
    return pushCoins
end

function EgyptCoinPusherData:getLeftSlotCount(id)
    local stage = self:getStageDataById(id)
    local spinTimes = stage.spinTimes
    return spinTimes or 0
end

function EgyptCoinPusherData:isUseQuick()
    return not not  self.m_useQuick 
end

function EgyptCoinPusherData:isUseQuickPush()
    return not not  self.m_useQuickPush 
end

function EgyptCoinPusherData:isUseSlotAct()
    return not not  self.m_useSlotAct 
end

return EgyptCoinPusherData
