--[[
    大富翁数据解析
]]
local BaseActivityData = require "baseActivity.BaseActivityData"
local BaseActivityRankCfg = util_require("baseActivity.BaseActivityRankCfg")
local RichManData = class("RichManData", BaseActivityData)

------------------------------------    游戏登录数据    ------------------------------------
--//大富翁信息
--message RichConfig {
--  optional int32 expire = 1; //剩余秒数
--  optional int64 expireAt = 2; //过期时间
--  optional string activityId = 3; //活动id
--  repeated RichPosition positions = 4;//地图所有位置数据
--  optional int32 current = 5;//当前位置
--  optional int32 leftDices = 6;//剩余骰子数量
--  optional int32 diceLimit = 7;//最大骰子数量
--  optional int64 rewardCoins = 8;//全部完成金币奖励
--  repeated ShopItem rewardItems = 9;//全部完成物品奖励
--  optional int32 sequence = 10;//第几轮
--  optional int32 collect = 11; // Spin能量收集个数
--  optional int32 max = 12; // Spin能量最大收集个数
--  optional RichEnergy energy = 13;//地图能量数据
--  optional RichMonster monster = 14;//怪物小游戏数据 只有当前位置类型为怪物时，才需要解析该数据
--  optional int32 doubleDiceNum = 15;//骰子点数X2剩余次数
--  repeated int32 awardedPosition = 16;//获得奖励的位置
--  optional int32 maxDoubleDice = 17;
--  optional int32 spinDiceLimit = 18;
--  repeated RichMonsterDisplay monsterDisplays = 19;// 怪物预览奖励
-- optional int32 zone = 20;  //排行榜 赛区
-- optional int32 roomType = 21;  //排行榜 房间类型
-- optional int32 roomNum = 22;  //排行榜 房间数
-- optional int32 rankUp = 23; //排行榜排名上升的幅度
-- optional int32 rank = 24; //排行榜排名
-- optional int32 points = 25; //排行榜点数
--}
function RichManData:parseData(data, isNetData)
    BaseActivityData.parseData(self, data, isNetData)

    -- 登录数据
    self.positions = self:parsePositionData(data.positions) -- 地图所有位置数据
    self.current = data.current -- 当前位置
    self.leftDices = data.leftDices -- 剩余骰子数量
    self.diceLimit = data.diceLimit -- 最大骰子数量
    self.rewardCoins = data.rewardCoins -- 全部完成金币奖励
    self.rewardItems = self:parseRewardsData(data.rewardItems) -- 全部完成物品奖励
    self.sequence = data.sequence -- 第几轮
    self.collect = data.collect -- Spin能量收集个数(关卡中骰子收集进度)
    self.max = data.max -- Spin能量最大收集个数
    self.spinDiceLimit = data.spinDiceLimit -- spin累积骰子上限
    self.energy = self:parseEnergyData(data.energy) -- 地图能量数据
    self.monster = self:parseMonsterData(data.monster) -- 怪物小游戏数据 只有当前位置类型为怪物时，才需要解析该数据
    self.doubleDiceNum = data.doubleDiceNum -- 双倍骰子数
    self.maxDoubleDice = data.maxDoubleDice -- 骰子buff上限
    self.awardedPosition = self:parseRwardedPosition(data.awardedPosition) -- 已经领奖的位置
    self.monsterDisplays = self:parseMonsterRewards(data.monsterDisplays) -- 怪物奖励预览数据

    self.rank = tonumber(data.rank) or 0 -- 排行榜排名
    self.points = tonumber(data.points) -- 排行榜积分
    self.rankUp = tonumber(data.rankUp) -- 排行榜排名上升的幅度

    -- 数据刷新事件
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.RichMan})
    printInfo("大富翁骰子当前位置 " .. self.current)

    -- GD.dumpStrToDisk( self.monster,"------------> self.monster = ",20 )
    -- dump(self, "登录数据", 5)
end

-- 解析排行榜信息
function RichManData:parseRichManRankConfig(_data)
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

-- 解析位置信息
function RichManData:parsePositionData(data)
    local new_data = {}
    local count = 1
    while data[count] do
        new_data[count] = {}
        new_data[count].position = data[count].position -- 位置
        new_data[count].type = data[count].type -- Coin：金币；Treasure：宝箱；NormalCard：普通卡包；GoldenCard：金卡；NadoCard：NADO卡；Monster：怪物；Blank：空
        new_data[count].icon = data[count].icon
        count = count + 1
    end
    printInfo("大富翁地图格子数据长度 " .. table.nums(new_data))
    if table.nums(new_data) <= 0 then
        local data_length = #data or 0
        util_sendToSplunkMsg("RichManMap", "地图数据异常 数据长度 " .. tostring(data_length))
    end
    return new_data
end

-- 解析奖励列表
function RichManData:parseRewardsData(data)
    local new_data = {}
    local count = 1
    while data[count] do
        new_data[count] = {}
        new_data[count] = data[count] -- 奖励
        count = count + 1
    end
    return new_data
end

-- 解析已经领取的奖励索引
function RichManData:parseRwardedPosition(data)
    local new_data = {}
    if data then
        local count = 1
        while data[count] do
            new_data[count] = data[count]
            count = count + 1
        end
    end
    return new_data
end

-- 解析地图收集能量值及奖励列表
--//大富翁地图能量数据
--message RichEnergy {
--  optional int32 collect = 1;//地图能量收集值
--  optional int32 max = 2;//地图能量完成值
--  optional int64 rewardCoins = 3;//地图能量完成金币奖励
--  repeated ShopItem rewardItems = 4;//地图能量完成物品奖励
--  optional int32 end = 5;//能量对应实际格子位置
--  optional bool interrupt = 6;//本轮目标奖励没有了
--  optional string rewardId = 7;//奖励id,同轮次
--}
function RichManData:parseEnergyData(data)
    local new_data = {}
    new_data.collect = data.collect -- 地图能量收集值
    new_data.max = data.max -- 地图能量完成值
    new_data.rewardCoins = data.rewardCoins -- 地图能量完成金币奖励
    new_data.rewardItems = self:parseRewardsData(data.rewardItems) -- 地图能量完成物品奖励
    new_data.stageEndIndex = data["end"] -- 打日志用的阶段值 80/160 ...
    new_data.interrupt = data.interrupt -- 奖励结束
    new_data.rewardId = data.rewardId -- 奖励id,同轮次

    if self.energy and self.energy.stageEndIndex and self.energy.stageEndIndex ~= new_data.stageEndIndex then
        new_data.max_last = self.energy.max
        new_data.stageEndIndex_Last = self.energy.stageEndIndex
    end

    return new_data
end

-- 解析怪物数据
-- //大富翁怪物信息
-- message RichMonster {
--   optional int32 blood = 1;//怪物血量
--   optional int32 leftBlood = 2;//怪物剩余血量
--   optional int32 leftChances = 3;//剩余机会
--   optional int64 expireAt = 4;//限定时间过期时间
--   optional int32 expire = 5;//限定时间剩余秒数
--   optional CommonRewards rewards = 6;
--   optional CommonRewards limitRewards = 7;//限定时间内击败怪物奖励
--   optional string status = 8;//状态 0：未完成，1：完成
--   optional int32 limitGems = 9; // 消耗宝石延长限定时间奖励
--   optional bool buyLimitItem = 10; //是否买过限时奖励延期道具
-- }
function RichManData:parseMonsterData(data)
    local new_data = {}
    new_data.blood = tonumber(data.blood) -- 怪物血量
    new_data.leftBlood = tonumber(data.leftBlood) -- 怪物剩余血量
    new_data.leftChances = tonumber(data.leftChances) -- 剩余机会
    new_data.expireAt = tonumber(data.expireAt) -- 限定时间过期时间
    new_data.expire = tonumber(data.expire) -- 限定时间剩余秒数

    -- message CommonRewards {
    --     optional int64 coins = 1;
    --     repeated ShopItem items = 2;
    -- }
    new_data.rewards = {}
    new_data.rewards.coins = data.rewards.coins -- 章节奖励
    new_data.rewards.items = data.rewards.items -- 章节奖励

    new_data.extraRewards = {}
    new_data.extraRewards.coins = data.limitRewards.coins -- 额外奖励
    new_data.extraRewards.items = data.limitRewards.items -- 额外奖励

    new_data.status = tonumber(data.status) -- 状态 0：未完成，1：完成
    new_data.gems = tonumber(data.limitGems) -- 钻石
    new_data.buyLimitItem = data.buyLimitItem -- 是否买过限时奖励延期道具

    -- 狼关卡倒计时逻辑测试
    --new_data.expireAt = globalData.userRunData.p_serverTime + 30 * 1000
    return new_data
end

--message RichMonsterDisplay {
--    optional int32 position = 1;//位置
--    optional CommonRewards rewards = 2;
--}
--message CommonRewards {
--    optional int64 coins = 1;
--    repeated ShopItem items = 2;
--}
function RichManData:parseMonsterRewards(data)
    local rewardsData = {}
    for index, value in ipairs(data) do
        local pos = tonumber(value.position)
        local reward = {}
        reward.coins = value.rewards.coins
        reward.items = value.rewards.items
        rewardsData[pos] = reward
    end
    return rewardsData
end

-- 狼关卡 限时击杀倒计时
function RichManData:getMonsterTimeLeft()
    if not self.monster or not self.monster.expireAt then
        return 0
    end

    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    local leftTime = self.monster.expireAt / 1000 - curTime
    if leftTime < 0 then
        leftTime = 0
    end
    return leftTime
end

------------------------------------    游戏进度数据    ------------------------------------
-- 地图上制掷骰子结果
function RichManData:parsePlayData(data)
    -- {
    --     "code":0,
    --     "dice":6,
    --     "moves":7,
    --     "position":319,
    --     "succeed":true,
    --     "treasures":{
    --         "319":{
    --             "coins":0,
    --             "monster":{
    --             },
    --             "rushSteps":0
    --         }
    --     },
    --     "sequence":{
    --             "coins":100000,
    --             "items":[
    --                 {
    --                     "activityId":"-1",
    --                     "buff":0,
    --                     "description":"大富翁宝箱-RUSH道具",
    --                     "icon":"CardClover",
    --                     "id":450203,
    --                     "item":0,
    --                     "itemInfo":{
    --                         "createTime":1595508098000,
    --                         "description":"大富翁Rush ",
    --                         "duration":-1,
    --                         "icon":"/XX/XX.png",
    --                         "id":114,
    --                         "lastUpdateTime":1595508098000,
    --                         "linkId":"-1",
    --                         "type1":1,
    --                         "type2":1
    --                     },
    --                     "num":6,
    --                     "type":"Item"
    --                 }
    --             ],
    --             "cardDrop":{}
    --         }
    --    }

    self.dice = data.dice -- 骰子点数
    self.moves = data.moves -- 棋子移动步数
    self.position = data.position -- 骰子终点位置
    self.treasures = data.treasures -- 本次移动的奖励数据详情
    self.finalReward = data.sequence -- 最终大奖
end

-- 狼关卡掷骰子结果
function RichManData:parseStageData(data)
    self.dice = data.dice -- 骰子点数
    self.stageData = self:parseMonsterData(data.monster) -- 怪物数据
    self.stageData.monsterReward = data.monsterReard -- 结算奖励
    self.stageData.extraReward = data.monsterLimitRewards -- 额外奖励
    self.stageData.limit = data.limit -- 是否限时击杀
end

-- 获取筛子点数
function RichManData:getDice()
    return self.dice
end

-- 获取移动步数
function RichManData:getMoves()
    return self.moves
end

-- 获取某一格子上的奖励
function RichManData:getRreasuresData(_id)
    if self.treasures then
        return self.treasures[tostring(_id)]
    end
end

function RichManData:getTreasures()
    return self.treasures
end

-- 获取最终大奖
function RichManData:getFinalReward()
    return self.finalReward
end

-- 当前轮数
function RichManData:getSequence()
    return self.sequence or 1
end

-- 当前第几章节
function RichManData:getCurrent()
    return self.energy.stageEndIndex
end

function RichManData:getLeftDices()
    return self.leftDices
end

-- 双倍骰子数
function RichManData:getDoubleDice()
    return self.doubleDiceNum
end

-- shuangbei
function RichManData:getDoubleDiceMax()
    return self.maxDoubleDice
end

--获取入口位置 1：左边，0：右边
function RichManData:getPositionBar()
    return 1
end

-- 获取排行榜cfg
function RichManData:getRankCfg()
    return self.p_rankCfg
end

return RichManData
