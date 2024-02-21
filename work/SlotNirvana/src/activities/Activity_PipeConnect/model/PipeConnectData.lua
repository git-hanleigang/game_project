--接水管主数据部分
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local BaseActivityData = require "baseActivity.BaseActivityData"
local ShopItem = require "data.baseDatas.ShopItem"
local PipeConnectData = class("PipeConnectData", BaseActivityData)
--[[
    message PipeConnect {
        optional string activityId = 1; //活动id
        optional int64 expireAt = 2; //过期时间
        optional int32 expire = 3; //剩余秒数
        optional int32 stage = 4; //章节
        repeated PipeConnectPipeLineList pipeLineList = 5; //管道信息
        optional PipeConnectSlot slot = 6; //老虎机
        optional int32 round = 7; //轮次
        optional int64 roundCoins = 8;//轮次金币
        repeated ShopItem roundItems = 9;//轮次物品
        optional int32 pipes = 10; //剩余道具数量
        optional int32 maxPipes = 11; //最大道具数量
        optional int32 spinPipeLimit = 12; //spin道具数量上限
        repeated PipeConnectStageInfo stageInfoList = 13; //章节(面板)信息
        repeated PipeConnectJackpot jackpots = 14; //jackpot
        optional PipeConnectJigsawGame jigsawGame = 15; //拼图游戏
        optional int32 energy = 16; //Spin能量收集个数
        optional int32 maxEnergy = 17; //Spin能量最大收集个数
        optional int32 zone = 18; //排行榜 赛区
        optional int32 roomType = 19; //排行榜 房间类型
        optional int32 roomNum = 20; //排行榜 房间数
        optional int32 rankUp = 21; //排行榜排名上升的幅度
        optional int32 rank = 22; //排行榜排名
        optional int32 points = 23; //排行榜 积分
        optional int32 leftScoops = 26;//剩余铲子数量
        optional string roundCoinsV2 = 28;//轮次金币
    }
]]
function PipeConnectData:ctor()
    PipeConnectData.super.ctor(self)
    self.m_first = false
    self.m_maxBet = 0
    self.m_roundCoins = toLongNumber(0)
end

function PipeConnectData:parseData(data)
    PipeConnectData.super.parseData(self, data)
    self.m_stage = data.stage --目前章节
    self.m_pipes = data.pipes --道具数量
    self.m_maxPipes = data.maxPipes --最大道具数量
    self:parseStageInfoData(data.stageInfoList) --章节信息
    self:parsePipeLineData(data.pipeLineList) --管道信息
    self.m_round = data.round  --轮次
    if data.roundCoinsV2 and data.roundCoinsV2 ~= "" and data.roundCoinsV2 ~= "0" then
        self.m_roundCoins:setNum(data.roundCoinsV2)
    else
        self.m_roundCoins:setNum(data.roundCoins)
    end
    -- self.m_roundCoins = data.roundCoins --轮次金币
    -- self.m_roundCoinsV2 = data.roundCoinsV2 --大金币
    self.m_roundItems = data.roundItems --轮次物品
    self.m_energy = data.energy --能量收集个数
    self.m_maxEnergy = data.maxEnergy --最大能量收集个数
    self.m_rank = data.rank --排行榜排名
    self.m_rankUp = data.rankUp --排行榜上升幅度
    self.m_rankpoint = data.points --排行榜积分
    self.m_jigsawGame = self:parseJigsawGameData(data.jigsawGame)
    self:parsePipeJackData(data.jackpots)
    self.m_jackpots = data.jackpots
    self:parsePipeFinalItems(data.roundItems)
    self:parsePipeSoltData(data.slot)
    self.m_leftScoops = data.leftScoops --小游戏钥匙
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.PipeConnect})
end

function PipeConnectData:setIsFirst(_flag)
    self.m_first = _flag
end

function PipeConnectData:getIsFirst()
    return self.m_first
end

function PipeConnectData:setMaxBet()
    self.m_maxBet = 0
end

function PipeConnectData:getMaxBet()
    return self.m_maxBet
end

function PipeConnectData:setNewJackPort()
    self:parsePipeJackData(self.m_jackpots)
end

--当前章节
function PipeConnectData:getCurrectState()
    return self.m_stage
end
--当前道具数量
function PipeConnectData:getPipes()
    return self.m_pipes or 0
end
--当前道具数量
function PipeConnectData:setPipes(_bet)
    self.m_pipes = _bet
end
--最大道具数量
function PipeConnectData:getMaxPipes()
    return self.m_maxPipes or 0
end

function PipeConnectData:getEnergy()
    return self.m_energy or 0
end

function PipeConnectData:getMaxEnergy()
    return self.m_maxEnergy or 0
end

function PipeConnectData:getCurrectReward()
    return self.m_stageInfo[self.m_stage] or {}
end

function PipeConnectData:getMyRank()
    return self.m_rank or 0
end

function PipeConnectData:getMyRankUp()
    return self.m_rankUp or 0
end

function PipeConnectData:getMyRankPoint()
    return self.m_rankpoint or 0
end

function PipeConnectData:getPipLine()
    return self.m_linedata or {}
end
--档位集合
function PipeConnectData:getBetGear()
    return self.m_betGear or {}
end
--档位
function PipeConnectData:getSinglBet()
    return self.m_singleBet or 1
end

function PipeConnectData:setSinglBet(_bet)
    self.m_singleBet = _bet
end

--轮次奖励
function PipeConnectData:parsePipeFinalItems(_data)
    self.m_finalInfo = {}
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local tempData = ShopItem:create()
            tempData:parseData(v)
            table.insert(self.m_finalInfo,tempData)
        end
    end
end

--管道信息
function PipeConnectData:parsePipeLineData(_data)
    self.m_linedata = {}
    if _data and #_data > 0 then
        for i,v in ipairs(_data) do
            local map = {}
            local can = v
            if v.pipeLine then
                can = v.pipeLine
            end
            for j=1,#can do
                local mp = {}
                mp.collect = can[j].collect
                mp.reward = can[j].reward
                table.insert(map,mp)
            end
            table.insert(self.m_linedata,map)
        end
    end
end

--老虎机信息
function PipeConnectData:parsePipeSoltData(_data)
    if self.m_betGear and #self.m_betGear > 0 then
        if self.m_betGear[#self.m_betGear] ~= _data.betGear[#_data.betGear] then
            self.m_maxBet = _data.betGear[#_data.betGear]
        end
    end
    self.m_betGear = _data.betGear
    self.m_singleBet = _data.currentBetGear
   
    if self.m_singleBet == 0 then
        self.m_singleBet = 1
    end
    if _data.reels and #_data.reels > 0 then
        self:parseEndRells(_data.reels)
    end

    if _data.fakeScrollReels and #_data.fakeScrollReels > 0 then
        self:parseRells(_data.fakeScrollReels)
    end
end

function PipeConnectData:parseRells(_data)
    self.m_fkrells = {}
    for i,v in ipairs(_data) do
        local st = {}
        if v.reels then
            for j=1,#v.reels do
                table.insert(st,100)
                table.insert(st,v.reels[j])
            end
        else
            for j=1,#v do
                table.insert(st,100)
                table.insert(st,v[j])
            end
        end
        table.insert(self.m_fkrells,st)
    end
end

function PipeConnectData:parseEndRells(_data)
    self.m_endRells = {}
    for i,v in ipairs(_data) do
        local st = {}
        if v.reels then
            for j=1,#v.reels do
                table.insert(st,v.reels[j])
            end
        else
            for j=1,#v do
                table.insert(st,v[j])
            end
        end
        
        table.insert(self.m_endRells,st)
        if i ~= #_data then
            table.insert(self.m_endRells,{100,100,100})
        end
    end
end

function PipeConnectData:getFkReels()
    return self.m_fkrells or {}
end

function PipeConnectData:getEndReels()
    return self.m_endRells or {}
end

--章节信息
function PipeConnectData:parseStageInfoData(_data)
    self.m_stageInfo = {}
    self.m_totalItems = {}
    for i,v in ipairs(_data) do
        local st = {}
        st.stage = v.stage   --第几章节
        st.status = v.status --status状态 COMPLETED PLAY LOCKD
        st.coins = toLongNumber(0)
        if v.coinsV2 and v.coinsV2 ~= "" and toLongNumber(v.coinsV2) > toLongNumber(0) then
            st.coins:setNum(v.coinsV2)
        else
            st.coins:setNum(v.coins)
        end
        --道具奖励信息
        local itemsData = {}
        if v.items and #v.items > 0 then 
            for i,k in ipairs(v.items) do
                local tempData = ShopItem:create()
                tempData:parseData(k)
                table.insert(itemsData, tempData)
                table.insert(self.m_totalItems,tempData)
            end
        end
        st.items = itemsData
        table.insert(self.m_stageInfo,st)
    end
end
--[[
    message PipeConnectJigsawGame {
        optional int32 number = 1; // 第几轮游戏
        optional int32 picks = 2; // 挖宝次数
        optional int32 hitPicks = 3;//必中次数
        repeated PipeConnectJigsawGamePosition positions = 4; //每个位置的奖励
        optional int64 coins = 5;
        repeated ShopItem items = 6;
        repeated int32 findIcons = 7;// 已获得图标
    }
]]
--小游戏
function PipeConnectData:parseJigsawGameData(_data)
    local tempData = {}
    if _data then 
        tempData.p_number = _data.number
        tempData.p_picks = _data.picks
        tempData.p_hitPicks = _data.hitPicks
        tempData.p_positions = self:parseBox(_data.positions)
        tempData.p_coins = toLongNumber(0)
        if _data.coinsV2 and _data.coinsV2 ~= "" and _data.coinsV2 ~= "0" then
            tempData.p_coins:setNum(_data.coinsV2)
        else
            tempData.p_coins:setNum(_data.coins)
        end
        tempData.p_items = self:parseItemData(_data.items)
        tempData.p_findIcons = _data.findIcons
    end
    return tempData
end

--[[
    message PipeConnectJigsawGamePosition {
        optional int32 pos = 1; // 位置
        optional int32 type = 2; // 是否翻开
        optional int32 icon = 3; // 翻开图标
        optional int64 coins = 4; // 金币奖励
        repeated ShopItem items = 5;//物品奖励
    }
]]
function PipeConnectData:parseBox(_data)
    local tempData = {}
    if _data and #_data > 0 then 
        for i,v in ipairs(_data) do
            local temp = {}
            temp.p_pos = v.pos
            temp.p_type = v.type
            temp.p_icon = v.icon
            temp.p_coins = toLongNumber(0)
            if v.coinsV2 and v.coinsV2 ~= "" and v.coinsV2 ~= "0" then
                temp.p_coins:setNum(v.coinsV2)
            else
                temp.p_coins:setNum(v.coins)
            end
            --temp.p_coins = tonumber(v.coins)
            temp.p_items = v.items
            table.insert(tempData, temp)
        end
        table.sort(
            tempData,
            function(a, b)
                return (a.p_pos) < (b.p_pos)
            end
        )
    end
    return tempData
end

-- 解析所有道具信息
function PipeConnectData:parseItemData(items)
    local itemList = {}
    for _, data in ipairs(items) do
        local shopItem = ShopItem:create()
        shopItem:parseData(data, true)
        table.insert(itemList, shopItem)
    end
    return itemList
end

-- 解析接口返回小游戏数据
function PipeConnectData:parseJigsawGameResData(_data)
    self.m_jigsawGame = self:parseJigsawGameData(_data)
end

--当前轮次
function PipeConnectData:getRound()
    return self.m_round or 0
end

--Jackport信息
function PipeConnectData:parsePipeJackData(_data)
    self.m_jackpot = {}
    for i,v in ipairs(_data) do
        local jk = {}
        jk.jackpot = v.jackpot
        jk.count = v.count
        jk.coins = toLongNumber(0)
        --jk.coins = v.coins
        if v.coinsV2 and v.coinsV2 ~= "" and v.coinsV2 ~= "0" then
            jk.coins:setNum(v.coinsV2)
        else
            jk.coins:setNum(v.coins)
        end
        table.insert(self.m_jackpot,jk)
    end
end

function PipeConnectData:getStageInfo()
    return self.m_stageInfo or {}
end

function PipeConnectData:getTotalCoins()
    return self.m_roundCoins or 0
end

function PipeConnectData:getTotalItems()
    return self.m_finalInfo or {}
end

--固定buff
function PipeConnectData:getHits()
    return self.hits or 0
end

function PipeConnectData:getHitsMax()
    return self.hitsLimit or 10
end

--小游戏数据
function PipeConnectData:getJigsawGame()
    return self.m_jigsawGame or {}
end

--小游戏数据
function PipeConnectData:setMayaGameSoop(_scoop)
    self.m_leftScoops = self.m_leftScoops + _scoop
end

--获取入口位置 1：左边，0：右边
function PipeConnectData:getPositionBar()
    return 1
end

-- 解析排行榜信息
function PipeConnectData:parseRankConfig(_data)
    if not _data then
        return
    end

    if not self.p_rankCfg then
        self.p_rankCfg = BaseActivityRankCfg:create()
    end
    self.p_rankCfg:parseData(_data)

    local myRankConfigInfo = self.p_rankCfg:getMyRankConfig()
    if myRankConfigInfo and myRankConfigInfo.p_rank then
        self:setRank(myRankConfigInfo.p_rank)
    end
end

-- 获取jackpot的数据
function PipeConnectData:getJackpot()
    return self.m_jackpot or {}
end

function PipeConnectData:getRankCfg()
    return self.p_rankCfg
end

-- 得到小游戏钥匙数量
function PipeConnectData:getLeftScoops()
    return self.m_leftScoops or 0
end

-- 设置小游戏钥匙数量
function PipeConnectData:setLeftScoops(_num)
    if not _num then
        return
    end
    self.m_leftScoops = _num
end

-- 睡眠中
function PipeConnectData:isSleeping()
    if self:getLeftTime() <= 2 then
        return true
    end

    return false
end

return PipeConnectData
