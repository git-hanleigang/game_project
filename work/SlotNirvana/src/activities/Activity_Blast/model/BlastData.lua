local BaseActivityRankCfg = require "baseActivity.BaseActivityRankCfg"
local BaseActivityData = require "baseActivity.BaseActivityData"
local ShopItem = util_require("data.baseDatas.ShopItem")
local BlastPanelData = require "activities.Activity_Blast.model.BlastPanelData"
local BlastJackData = require "activities.Activity_Blast.model.BlastJackData"
local BlastResultData = require "activities.Activity_Blast.model.BlastResultData"
local BlastBombRData = require "activities.Activity_Blast.model.BlastBombRData"
local BlastData = class("BlastData", BaseActivityData)

--message Blast {
--    optional int32 expire = 1; //剩余秒数
--    optional int64 expireAt = 2; //过期时间
--    optional string activityId = 3; //活动id
--    optional int32 stage = 4; //目前进行的章节
--    repeated BlastPanelDetail panels = 5; //各章节的数据
--    repeated BlastJackpot jackpots = 6; //jackpots
--    optional int32 round = 7; //第几个轮回
--    optional int32 picks = 8; // 可点次数
--    optional int32 hits = 9; //必中次数
--    optional int32 energy = 10; //当前能量
--    optional int32 maxEnergy = 11; //最大能量
--    optional int32 questOpenBlast = 12;  //quest中是否开启blast
--    optional int32 maxPicks = 13; // 最大可点次数
--    optional int32 hitsLimit = 14; //最大必中次数
--    optional int32 zone = 15;  //排行榜 赛区
--    optional int32 roomType = 16;  //排行榜 房间类型
--    optional int32 roomNum = 17;  //排行榜 房间数
--    optional int32 rankUp = 18; //排行榜排名上升的幅度
--    optional int32 rank = 19; //排行榜排名
--    optional int32 points = 20; //排行榜点数
--    optional BlastBomb blastBombData = 22; // 炸弹数据
--    repeated NewUserActivityMission missions = 21; //新手期任务
     -- repeated CommonRewardV2 rewardPackage = 23; //累计的奖励
--}

function BlastData:parseData(data, isJson, isNetData)
    BaseActivityData.parseData(self, data, isJson)
    self.stage = data.stage --目前章节
    self.round = data.round --轮数
    self.picks = data.picks --点击次数
    self.hits = data.hits --必中次数
    self.hitsLimit = data.hitsLimit --最大必中次数
    self.energy = data.energy --当前能量
    self.maxEnergy = data.maxEnergy --最大能量
    self.questOpenBlast = data.questOpenBlast --quest中是否开启blast
    self.picksLimit = data.maxPicks --次数累计最大值
    self.m_affOpen = data.affairOpen --1抵n事件
    self.m_affLight = data.affairLight --高亮事件
    self.m_affairPick = data.affairPick --三选一事件
    --各个章节数据
    self:parsePanelData(data.panels)
    --jackpot数据
    self:parseJackpotsData(data.jackpots)

    self.rank = tonumber(data.rank) -- 排行榜排名
    self.points = tonumber(data.points) -- 排行榜积分
    self.rankUp = tonumber(data.rankUp) -- 排行榜排名上升的幅度
    if data.expireAt then
        self.m_expireAt = tonumber(data.expireAt)/1000
    end
    if data.blastBombData then
        self:parseBomData(data.blastBombData)
    end
    self.m_boxPackage = {}
    if data.rewardPackage and #data.rewardPackage > 0 then
        self:parseBoxPackage(data.rewardPackage)
    end
    self.m_maxBomb = 20

    -- 新手期balst任务
    G_GetMgr(ACTIVITY_REF.BlastNoviceTask):parseData(data.missions)

    -- 刷新数据
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.Blast})
end

function BlastData:parseBoxPackage(_data)
    for i,v in ipairs(_data) do
        local item = {}
        if v.coins and v.coins ~= "" and v.coins ~= "0" then
            item.type = "COIN"
            item.coins = toLongNumber(v.coins)
        elseif v.gems and tonumber(v.gems) > 0 then
            item.type = "Gem"
            item.gems = tonumber(v.gems)
        elseif v.items and #v.items > 0 then
            item.type = "Card"
            local card = {}
            for k=1,#v.items do
                local shopItem = ShopItem:create()
                shopItem:parseData(v.items[1])
                table.insert(card,shopItem)
            end
            item.items = card
        end
        table.insert(self.m_boxPackage,item)
    end
end

function BlastData:parseBomData(_data)
    self.m_bomNum = _data.bombs
end

function BlastData:parsePanelData(data)
    assert(data and table.nums(data) > 0, "blast活动 章节列表数据异常")

    self.panels = {}
    for i, panel in ipairs(data) do
        local panelData = BlastPanelData:create()
        panelData:parseData(panel)
        table.insert(self.panels,panelData)
    end
end

function BlastData:getExpireAt()
    return self.m_expireAt or 0
end

function BlastData:getBoxPackage()
    return self.m_boxPackage
end

-- message BlastJackpot {
--     optional int32 jackpot = 1;
--     optional int32 count = 2;
--     optional int64 coins = 3;
-- }
function BlastData:parseJackpotsData(data)
    assert(data and table.nums(data) > 0, "blast活动 jackpot数据异常")

    self.jackpots = {}
    for i, jackpot in ipairs(data) do
        local jackpotData = BlastJackData:create()
        jackpotData:parseData(jackpot)
        table.insert(self.jackpots, jackpotData)
    end
end

-- 获取关卡id列表
function BlastData:getStageIds()
    return table.keys(self.panels)
end

-- 获取关卡数据
function BlastData:getStageDataById(_id)
    if _id and _id >= 0 and self.panels[_id] then
        return self.panels[_id]
    end
end

-- 获取金票的数量
function BlastData:getHits()
    return self.hits or 0
end

-- 获取金票持有的最大值(商城和促销购买获得的)
function BlastData:getHitsMax()
    return self.hitsLimit
end

-- 当前关卡id
function BlastData:getCurrentStageId()
    return self.stage or 1
end

-- 获取jackpot数据
function BlastData:getJackpotDataById(_id)
    if self.jackpots and self.jackpots[_id] then
        return self.jackpots[_id]
    end
end

-- 当前第几轮
function BlastData:getRound()
    return self.round
end

-- 当前第几轮 底层用
function BlastData:getSequence()
    return self:getRound()
end

-- 当前第几章节 ，底层用
function BlastData:getCurrent()
    return self.stage or 1
end

-- 持有抽奖券数量
function BlastData:getPicks()
    return self.picks
end

-- 当前累积能量 能量上限
function BlastData:getEnergyData()
    return {cur = self.energy, max = self.maxEnergy}
end

function BlastData:getPicksLimit()
    return self.picksLimit
end

function BlastData:getQuestOpenBlast()
    return self.questOpenBlast
end

function BlastData:getAffairPick()
    return self.m_affairPick
end

function BlastData:getAffairOpen()
    return self.m_affOpen
end

function BlastData:getAffairLight()
    return self.m_affLight
end

function BlastData:parseBlastRankConfig(data)
    if data == nil then
        return
    end

    if not self.blastRankConfig then
        self.blastRankConfig = BaseActivityRankCfg:create()
    end
    self.blastRankConfig:parseData(data)

    local myRankConfigInfo = self.blastRankConfig:getMyRankConfig()
    if myRankConfigInfo ~= nil then
        self:setRank(myRankConfigInfo.p_rank)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.Blast})
end

function BlastData:getRankCfg()
    return self.blastRankConfig
end

function BlastData:parsePickData(data,_idx)
    self.pickData = nil
    local boxType = data.boxType
    if boxType == "BOMB1" or boxType == "BOMB2" or boxType == "BOMB3" or boxType == "BOMB4" then
        self.pickData = BlastBombRData:create()
    else
        self.pickData = BlastResultData:create()
    end
    self.pickData:parseData(data,_idx)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BLAST_CELL_REFRESH)
end

function BlastData:parseBombData(data,_idx)
    self.pickData = nil
    self.pickData = BlastBombRData:create()
    self.pickData:parseData(data,_idx,true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BLAST_CELL_REFRESH)
end

function BlastData:getPickData()
    return self.pickData
end

function BlastData:setPickData()
    if self.pickData and self.pickData.stage then
        self.pickData.stage = nil
    end
end

--获取入口位置 1：左边，0：右边
function BlastData:getPositionBar()
    return 1
end

-- 检查完成条件
function BlastData:checkCompleteCondition()
    if self:getNewUser() and G_GetMgr(ACTIVITY_REF.Blast):getNewUserOver() then
        return true
    end
    return false
end

--新手期
function BlastData:setNewUser(_flag)
    self.m_isNewUser = _flag
end

function BlastData:getNewUser()
    return self.m_isNewUser
end

function BlastData:setConfigData(_data)
    self.m_configdata = _data
end

function BlastData:getConfigData()
    return self.m_configdata
end

function BlastData:getBomsNum()
    return self.m_bomNum or 0
end

return BlastData
