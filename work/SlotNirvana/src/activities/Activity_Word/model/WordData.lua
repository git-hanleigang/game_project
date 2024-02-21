-- 字独数据
local WordProgressData = util_require("activities.Activity_Word.model.WordProgressData")
local WordJackpotData = util_require("activities.Activity_Word.model.WordJackpotData")
local WordMayaGameData = util_require("activities.Activity_Word.model.WordMayaGameData")

local BaseActivityRankCfg = require "baseActivity.BaseActivityRankCfg"
local BaseActivityData = require "baseActivity.BaseActivityData"
local WordData = class("WordData", BaseActivityData)

------------------------------------    游戏登录下发数据    ------------------------------------
--message WordConfig {
--    optional string activityId = 1;    //活动 id
--    optional int64 expireAt = 2;      //活动截止时间
--    optional int64 expire = 3;        //活动剩余时间
--    optional int64 rewardCoins = 4;   //所有关卡完成奖励金币
--    repeated ShopItem items = 5;      //所有关卡完成奖励物品
--    optional int32 sequence = 6;      //第几个轮回
--    optional int32 collect = 7;       // 收集能量数量
--    optional int32 max = 8;           // 最大收集数量
--    optional int32 balls = 9; //剩余字母球
--    optional int32 ballsLimit = 10; //字母球数量限制
--    optional int32 maxHitBalls = 11; //比中球限制
--    optional int32 hitBalls = 12;   //必中球
--    repeated WordChapter chapters = 13; //章节配置
--    optional int32 current = 14;       //当前章节
--    optional int32 cardNum = 15;       //当前章节的第 x 张卡片
--    optional int32 points = 16;        //排行榜积分
--    optional int32 rankUp = 17;              //排行榜排名上升的幅度
--    optional int32 rank = 18;                //排行榜排名
--    optional int32 r = 19;               //r
--    optional int32 zone = 20;            //赛区
--    optional int32 roomType = 21;        //房间类型
--    optional int32 roomNum = 22;         //房间号
--    repeated int32 characterStatus = 23; //字母状态
--    optional int32 spinBallLimit = 24; //spin获得球的上限
--    optional int32 leftScoops = 25; // 剩余铲子数量
--    optional WordProgress progressData = 26; // 进度条奖励
--    repeated WordJackpot jackpots = 27; // jackpot奖池
--    optional WordMayaGame mayaGameData = 28; // 玛雅小游戏
--    optional string rewardCoinsV2 = 29;   //所有关卡完成奖励金币
--}
-- 解析数据
function WordData:parseData(data, isNetData)
    BaseActivityData.parseData(self, data, isNetData)

    self.chapters = self:parseChapterData(data.chapters) -- 章节配置

    self.sequence = tonumber(data.sequence) -- 第几个轮回
    self.current = tonumber(data.current) -- 当前章节id
    self.cardNum = tonumber(data.cardNum) -- 当前章节的翻卡进度
    self.balls = tonumber(data.balls) -- 剩余字母球数量
    self.maxHitBalls = tonumber(data.maxHitBalls) -- 比中球限制
    self.hitBalls = tonumber(data.hitBalls) -- 必中球
    self.spinBallLimit = tonumber(data.spinBallLimit) -- 字母球收集上限
    self.collect = tonumber(data.collect) -- 收集能量数量
    self.max = tonumber(data.max) -- 最大收集数量
    self.characterStatus = {}
    for i = 1, 78 do
        self.characterStatus[i] = data.characterStatus[i]
    end
    self.rewardCoins = data.rewardCoinsV2 -- 所有关卡完成奖励金币
    self.items = data.items -- 所有关卡完成奖励物品

    self.rank = tonumber(data.rank) -- 排行榜排名
    self.points = tonumber(data.points) -- 排行榜积分
    self.rankUp = tonumber(data.rankUp) -- 排行榜排名上升的幅度

    self.p_leftScoops = data.leftScoops -- 剩余铲子数量

    -- 进度条奖励
    self.p_progressData = nil
    if data.progressData ~= nil then
        self.p_progressData = WordProgressData:create()
        self.p_progressData:parseData(data.progressData)
    end

    -- jackpot奖池
    self.p_jackpots = {}
    if data.jackpots and #data.jackpots > 0 then
        for i = 1, #data.jackpots do
            local wjData = WordJackpotData:create()
            wjData:parseData(data.jackpots[i])
            table.insert(self.p_jackpots, wjData:getJackpot(), wjData)
        end
    end

    -- 玛雅小游戏
    self.p_wordMayaData = nil
    if data.mayaGameData ~= nil then
        self.p_wordMayaData = WordMayaGameData:create()
        self.p_wordMayaData:parseData(data.mayaGameData)
    end

    -- 数据刷新事件
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.Word})
end

-- message WordChapter {
--     optional WordCard card = 1;  //场上卡片信息
--     optional int32 cardCount = 2; //卡片总数
--     optional int64 rewardCoins = 3;   //完成奖励金币
--     repeated ShopItem items = 4;      //完成奖励物品
--     optional int32 rewardCoinsMultiple = 6;  //章节奖励金币加成
--     optional string rewardCoinsV2 = 7;   //完成奖励金币
-- }
-- 解析章节数据
function WordData:parseChapterData(data)
    local chapterData = {}
    for i, chapter in ipairs(data) do
        local info = {}
        chapterData[i] = info
        info.card = self:parseCardData(chapter.card)
        info.cardCount = tonumber(chapter.cardCount)
        info.rewardCoins = chapter.rewardCoinsV2
        info.status = chapter.status
        info.items = self:parseItemData(chapter.items)
        info.rewardCoinsMultiple = chapter.rewardCoinsMultiple
    end
    return chapterData
end

-- message WordCard {
--     repeated WordCell cells = 1;   //棋盘
--     optional int32 minLines = 2;   //最少完成单词数量
--     optional int64 coins = 3;      //金币奖励
--     optional string coinsV2 = 4;      //金币奖励
-- }
-- 解析活动阶段数据
function WordData:parseCardData(data)
    local cardData = {}
    cardData.cells = self:parseCellData(data.cells)
    cardData.minLines = data.minLines
    cardData.coins = data.coinsV2
    return cardData
end

function WordData:parseItemData(items)
    local items_list = {}
    local count = 1
    while true do
        if items and items[count] then
            items_list[count] = items[count]
            count = count + 1
        else
            break
        end
    end

    return items_list
end

-- message WordCell {
--     optional int32 position = 1;   //位置
--     optional string character = 2; //字母;ABCDEF..., 没有的是 0
--     optional int32  characterNum = 3;  //字母序号 1-78 每个字母有3种
--     optional int32 status = 4;    //0 初始 1 命中 2 最后一连接
--     optional string icon = 5;     //显示资源,可能需要
--     optional bool hasTreasure = 6; //是否有宝箱 这个字段废弃了 用 positionType 字段
--     optional WordPositionType positionType = 7;
--   }

-- enum WordPositionType {
--     Treasure = 1;//宝箱
--     Jackpot = 2;//jackpot装盘
--     Scoop = 3;//玛雅宝藏铲子道具
--     Plane = 4;//飞机道具
--   }
-- 解析牌面数据
function WordData:parseCellData(data)
    local cellData = {}
    -- print("------------begin--------------")
    for i, cell in ipairs(data) do
        local info = {}
        info.position = tonumber(cell.position)

        info.character = tostring(cell.character)
        info.characterNum = tonumber(cell.characterNum)
        info.status = tonumber(cell.status)
        info.icon = tostring(cell.icon)
        info.hasTreasure = cell.hasTreasure
        info.positionType = cell.positionType
        info.color = 0 -- 颜色 默认没有颜色
        if info.character ~= "0" then
            info.color = math.ceil(info.characterNum / 26) -- 颜色
        -- print("颜色对照 " .. info.characterNum .. "   ".. info.color)
        end

        table.insert(cellData, info.position, info)
        -- print(i, info.position, info.character, info.characterNum, info.status, info.color)
    end
    -- print("-------------end--------------")
    return cellData
end

function WordData:parseWordRankConfig(data)
    if data == nil then
        return
    end

    if not self.wordRankConfig then
        self.wordRankConfig = BaseActivityRankCfg:create()
    end
    self.wordRankConfig:parseData(data)

    local myRankConfigInfo = self.wordRankConfig:getMyRankConfig()
    if myRankConfigInfo ~= nil then
        self:setRank(myRankConfigInfo.p_rank)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.Word})
end

------------------------------------    游戏翻牌下发数据    ------------------------------------
function WordData:parseRankData(data)
    self.rank = tonumber(data.rank) -- 排行榜排名
    self.points = tonumber(data.points) -- 排行榜积分
    self.rankUp = tonumber(data.rankUp) -- 排行榜排名上升的幅度
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.Word})
end

function WordData:getJackpotData()
    return self.p_jackpots or {}
end

-- local play_data = {
--     cardFinish = false,
--     chapterFinish = false,
--     currentChapterNum = 1,
--     这里只有一个
--     playResult = {
--         [1] = {
--             character = "A",
--             characterNum = 27,
--             playStatus = "target",
--             position = 33,
--             treasure = {},
--         },
--     }
-- }

-- 用plane数据替换play结果数据
function WordData:resetPlayResult()
    if not self.record_data then
        return
    end
    local play_data = self.record_data
    if play_data and play_data.playResult and table.nums(play_data.playResult) > 1 then
        table.remove(play_data.playResult, 1)
        self:setPlayData(play_data)
        return true
    end
end

function WordData:setPlayData(play_data)
    assert(play_data, "玩家play数据丢失")
    dump(play_data, "play_data", 5)
    self.record_data = play_data
    self.play_data = {}
    self.play_data.bl_cardFinish = play_data.cardFinish
    self.play_data.bl_chapterFinish = play_data.chapterFinish
    self.play_data.bl_finalFinish = play_data.sequenceFinish
    self.play_data.finishLine = play_data.finishLine

    self.play_data.rewards = {
        cardRewards = {
            coins = play_data.cardCoins
        },
        chapterReward = {
            coins = play_data.chapterCoins,
            items = play_data.chapterItems,
            cards = play_data.chapterCard
        },
        finalReward = {
            coins = play_data.finalCoins,
            items = play_data.finalItems,
            cards = play_data.finalCard
        }
    }

    self.currentChapterNum = play_data.currentChapterNum
    self:setIsNewChapter(self.currentChapterNum ~= self:getCurrentChapterId())

    self.currentChapterCoinsMultiple = play_data.currentChapterCoinsMultiple
    self.currentChapterCoins = play_data.currentChapterCoins

    self.play_data.data = {}
    self.play_data.data[1] = play_data.playResult[1]
    if self.play_data.data[1] then
        self.play_data.data[1].color = math.ceil(self.play_data.data[1].characterNum / 26) -- 颜色
        self.play_data.data[1].status = 1
    end

    if self:isNewChapter() then
        self.play_data.data[1].coin_percent = play_data.currentChapterCoinsMultiple
        self.play_data.data[1].coins = play_data.currentChapterCoins
    else
        self.play_data.data[1].coin_percent = self:getCoinPercent()
        self.play_data.data[1].coins = self:getRewardCoins()
    end

    if play_data.playResult[2] then
        self.play_data.plane_data = play_data.playResult[2]
    end
end

function WordData:getPlayResult()
    if self.play_data then
        assert(self.play_data.data, "WordManager:getPlayResult 数据缺失")
        return self.play_data.data
    end
    return nil
end

function WordData:getPlayRewards()
    if self.play_data then
        assert(self.play_data.rewards, "WordManager:getPlayRewards 数据缺失")
        return self.play_data.rewards
    end
end

function WordData:getJackpotPlayData()
    local data = self:getPlayResult()
    if data and data[1] and data[1].jackpotData then
        return data[1].jackpotData
    end
end

function WordData:setIsNewChapter(bl_new)
    self.bl_newChapter = bl_new
end

function WordData:isNewChapter()
    return self.bl_newChapter
end

-- 完成一张卡
function WordData:isCardComplete()
    if self.play_data then
        return self.play_data.bl_cardFinish or false
    end
    return false
end

-- 完成一个章节
function WordData:isStageComplete()
    if self.play_data then
        return self.play_data.bl_chapterFinish or false
    end
    return false
end

function WordData:isFinalComplete()
    if self.play_data then
        return self.play_data.bl_finalFinish or false
    end
    return false
end

function WordData:getFinishLine()
    if self.play_data then
        return self.play_data.finishLine or {}
    end
    return {}
end

function WordData:getSequence()
    return self.sequence or 0
end

function WordData:getChapterData()
    return self.chapters or {}
end

-- 获取章节信息
function WordData:getChapterDataByIndex(index)
    local chapterData = self:getChapterData()
    return chapterData[index]
end

-- 当前章节数据
function WordData:getCurrentChapterData()
    local cur_id = self:getCurrentChapterId()
    return self:getChapterDataByIndex(cur_id)
end

-- 当前章节id
function WordData:getCurrentChapterId()
    return self.current
end

-- 当前章节id
function WordData:getCurrent()
    return self:getCurrentChapterId()
end

-- 获取卡牌上字母信息
function WordData:getCurrentChapterLetterByIndex(index)
    local data = self:getCurrentChapterData()
    if not data then
        return
    end

    return data.card.cells[index]
end

-- 获取废弃字母收集状态数据(id)
function WordData:getLetterStatusById(id)
    return self.characterStatus[id] or 0
end

function WordData:getLetterStatusByChapter(chapter)
    assert(chapter and type(chapter) == "string", "WordData:getLetterStatusByChapter 数据或数据类型不对" .. tostring(chapter))
    chapter = string.upper(chapter)
    local idx = string.byte(chapter) - string.byte("A") + 1
    -- 颜色顺序 蓝 绿 粉
    local blue_word = self:getLetterStatusById(idx)
    local green_word = self:getLetterStatusById(idx + 26)
    local pink_word = self:getLetterStatusById(idx + 26 + 26)

    return {["blue"] = blue_word, ["green"] = green_word, ["pink"] = pink_word}
end

-- 当前进行中的卡牌id
function WordData:getPlayingCardId()
    return self.cardNum
end

-- 当前章节卡牌总数
function WordData:getChapterCardCounts()
    local data = self:getCurrentChapterData()
    if not data then
        return
    end

    return data.cardCount
end

-- 总章节数
function WordData:getChapterCounts()
    local data = self:getCurrentChapterData()
    if not data then
        return 0
    end
    return table.nums(data)
end

-- 获取奖励数据
function WordData:getCurrentChapterRewards()
    local data = self:getCurrentChapterData()
    if not data then
        return
    end

    return data.rewardCoins, data.items
end

-- 获取奖励加成
function WordData:getCoinPercent()
    local data = self:getCurrentChapterData()
    if not data then
        return
    end

    return data.rewardCoinsMultiple or 0
end

-- 获取次数
function WordData:getBalls()
    return self.balls or 0
end

-- 获取必中球的数量
function WordData:getHits()
    return self.hitBalls or 0
end

-- 获取必中球持有的最大值(商城和促销购买获得的)
function WordData:getHitsMax()
    return self.maxHitBalls or 0
end

function WordData:getSpinBallsLimit()
    return self.spinBallLimit
end

function WordData:getCollect()
    return self.collect
end

function WordData:getMax()
    return self.max
end

function WordData:getRewardCoins()
    return self.rewardCoins
end

function WordData:getItems()
    return self.items
end

function WordData:getRank()
    return self.rank
end

function WordData:getRankUp()
    return self.rankUp
end

function WordData:getPoints()
    return self.points
end

function WordData:getLeftScoops()
    return self.p_leftScoops
end

function WordData:getWordGameData()
    return self.p_wordMayaData
end

--获取入口位置 1：左边，0：右边
function WordData:getPositionBar()
    return 1
end

return WordData
