---
-- 全局属性定义在这里 , 这里存储非持久化数据， 也就是运行时数据
GD.TASK_TIME = "TASK_TIME" --任务时间戳
GD.RELIEF_FUNDS_TIMES = "RELIEF_FUNDS_TIMES" --救济金
--广告
GD.ADS_INTERVAL_TIME = "ads_interval_time" --广告时间间隔
GD.SALE_BUY_TYPE = "saleBuyType"
GD.LAST_UPDATE_VERSION = "last_update_version"

--FB 字段
GD.FB_TOKEN = "fbtoken"
GD.FB_USERID = "fbuserid"
GD.FB_NAME = "fbname"
GD.FB_EMAIL = "fbemail"

-- Apple
GD.APPLE_ID = "appleId"

--内购数据
GD.INAPP_PURCHASE_TOTAL = "INAPP_PURCHASE_COUNT" -- 购买总钱数
GD.INAPP_PURCHASE_COUNT = "INAPP_PURCHASE_TOTAL" -- 购买次数

GD.IAP_RECEIPT = "iap_receipt"
GD.IAP_SIGNATURE = "iap_signature"
GD.IAP_ORDER_ID = "iap_order_id"

--支付
GD.BUY_COIN_TYPE_A = "slot_slotcashlink_coin_a" -- 2.99  -- GD.BUY_TYPE.STORE_TYPE
GD.BUY_COIN_TYPE_B = "slot_slotcashlink_coin_b" -- 5.99
GD.BUY_COIN_TYPE_C = "slot_slotcashlink_coin_c" -- 9.99
GD.BUY_COIN_TYPE_D = "slot_slotcashlink_coin_d" -- 19.99
GD.BUY_COIN_TYPE_E = "slot_slotcashlink_coin_e" -- 49.99
GD.BUY_COIN_TYPE_F = "slot_slotcashlink_coin_f" -- 99.99
-- buff
GD.BUY_BUFF_TYPE_A = "slot_slotcashlink_buff_a" -- buff_1_day 抽成 1.99 -- GD.BUY_TYPE.STORE_TYPE
GD.BUY_BUFF_TYPE_B = "slot_slotcashlink_buff_b" -- buff_2_day 抽成 4.99
GD.BUY_BUFF_TYPE_C = "slot_slotcashlink_buff_c" -- buff_3_day 抽成 8.99
GD.BUY_BUFF_TYPE_D = "slot_slotcashlink_buff_d" -- buff_1_day 升级 1.99
GD.BUY_BUFF_TYPE_E = "slot_slotcashlink_buff_e" -- buff_2_day 升级 2.99
GD.BUY_BUFF_TYPE_F = "slot_slotcashlink_buff_f" -- buff_3_day 升级 4.99
GD.BUY_BUFF_TYPE_G = "slot_slotcashlink_buff_g" -- buff_1_day 双BUFF 1.99
GD.BUY_BUFF_TYPE_H = "slot_slotcashlink_buff_h" -- buff_2_day 双BUFF 4.99
GD.BUY_BUFF_TYPE_I = "slot_slotcashlink_buff_i" -- buff_3_day 双BUFF 9.99
GD.BUY_BUFF_TYPE_J = "slot_slotcashlink_buff_j" -- buff_2_day 双BUFF（首购） super 1.99
GD.BUY_BUFF_TYPE_K = "slot_slotcashlink_buff_k" -- buff_6_day 双BUFF （首购） super 4.99
GD.BUY_BUFF_TYPE_L = "slot_slotcashlink_buff_l" -- buff_14_day 双BUFF （首购） super 9.99

--促销

GD.BUY_DAY_SALE_1P99 = "slot_slotcashlink_day_sale_1p99"
GD.BUY_DAY_SALE_4P99 = "slot_slotcashlink_day_sale_4p99"
GD.BUY_DAY_SALE_9P99 = "slot_slotcashlink_day_sale_9p99"

GD.BUY_TIME_SALE_1_1P99 = "slot_slotcashlink_time_sale_1_1p99"
GD.BUY_TIME_SALE_2_1P99 = "slot_slotcashlink_time_sale_2_1p99"
GD.BUY_TIME_SALE_3_1P99 = "slot_slotcashlink_time_sale_3_1p99"
GD.BUY_TIME_SALE_4_1P99 = "slot_slotcashlink_time_sale_4_1p99"
GD.BUY_TIME_SALE_5_1P99 = "slot_slotcashlink_time_sale_5_1p99"
GD.BUY_TIME_SALE_6_1P99 = "slot_slotcashlink_time_sale_6_1p99"
GD.BUY_TIME_SALE_7_1P99 = "slot_slotcashlink_time_sale_7_1p99"
GD.BUY_TIME_SALE_8_1P99 = "slot_slotcashlink_time_sale_8_1p99"
GD.BUY_TIME_SALE_9_1P99 = "slot_slotcashlink_time_sale_9_1p99"
GD.BUY_TIME_SALE_10_1P99 = "slot_slotcashlink_time_sale_10_1p99"
GD.BUY_TIME_SALE_11_1P99 = "slot_slotcashlink_time_sale_11_1p99"
GD.BUY_TIME_SALE_12_1P99 = "slot_slotcashlink_time_sale_12_1p99"

GD.BUY_NEW_SALE_0P99 = "slot_slotcashlink_new_sale_0p99"
GD.BUY_NEW_SALE_1P99 = "slot_slotcashlink_new_sale_1p99"
GD.BUY_NEW_SALE_4P99 = "slot_slotcashlink_new_sale_4p99"
GD.BUY_NEW_SALE_9P99 = "slot_slotcashlink_new_sale_9p99"
GD.BUY_NEW_SALE_19P99 = "slot_slotcashlink_new_sale_19p99"

-- 物品类型信息
GD.ITEMTYPE = {
    ITEMTYPE_COIN = 101, -- 金币
    ITEMTYPE_VIPPOINT = 102, -- VIP点数
    ITEMTYPE_HELP = 103, -- help次数
    ITEMTYPE_PAKAGE = 104, -- 促销礼盒
    ITEMTYPE_CARD = 105, -- 促销礼盒
    ITEMTYPE_LUCKYSTAMP = 106, -- luckystamp
    ITEMTYPE_CLUBPOINT = 108, -- Club点数
    ITEMTYPE_SENDCOUPON = 600001
}

GD.TAGTYPE = {
    TAGTYPE_MOST = 1001, -- 商城tag 标签 most popular
    TAGTYPE_BEST = 1002 -- 商城tag 标签 best popular
}

-- Buff ID
GD.BUFFID = {
    BUFFID_DOUBLE_EXP = 10001, -- 双倍经验
    BUFFID_LEVEL_UP_DOUBLE_COIN = 10002 -- 升级双倍金币
}

-- Buff TYPY
GD.BUFFTYPY = {
    BUFFTYPY_DOUBLE_EXP = "double xp * hrs", -- 双倍经验
    BUFFTYPY_LEVEL_UP_DOUBLE_COIN = "double level rewards * hrs", -- 升级双倍金币
    BUFFTYPY_LEVEL_BOOM = "LevelBoom", --levelboom活动buff
    BUFFTYPY_LEVEL_BURST = "LevelBurst", --商城购买levelboom道具buff
    BUFFTYPY_QUEST_FAST = "QuestFast", --quest活动buff
    BUFFTYPY_FIND_EXTRATIME = "TimePlus", --额外持续时间
    BUFFTYPY_FIND_DOUBLEPRIZE = "DoubleFind", --双倍奖励
    BUFFTYPE_BINGO_DOUBLEBALL = "BingoDoubleBall", --bingo booster buff
    BUFFTYPE_STORE_COUPON = "StoreCoupon",
    BUFFTYPE_DELUXE_EXP = "ClubDoubleXp",
    BUFFTYPE_MULTIPLE_EXP = "QuestXP", --quest活动经验加成
    BUFFTYPE_BINGO_TREASUREBUFF = "BingoTreasureBuff",
    BUFFTYPE_RICH_DOBLEDICE = "RichDoubleDice", --大富翁双倍骰子
    BUFFTYPE_RICH_COINBUFF = "RichDoubleAwardBuff", -- 大富翁金币buff
    BUFFTYPE_WORLDTRIP_DOBLEDICE = "WorldTripDoubleDiceBuff", --新版大富翁双倍骰子
    BUFFTYPE_WORLDTRIP_COINBUFF = "WorldTripDoubleCoinsBuff", -- 新版大富翁金币buff
    BUFFTYPE_LUCKYCHALLENGE_FAST = "LuckyChallengeFast",
    BUFFTYPE_BLAST_TREASURE_BUFF = "BlastTreasureBuff", -- 宝箱
    BUFFTYPE_BLAST_DOUBLE_PICK = "BlastDoublePick",
    -- 电池buff
    BUFFTYPE_DINNERLAND_DINNERPROGRESS = "DinnerProgress", -- 能量进度buff
    BUFFTYPE_DINNERLAND_DINNERPACKAGE = "DinnerPackage", -- 食材包Buff
    BUFFTYPE_DINNERLAND_DINNERFOOD = "DinnerFood", -- 菜品奖励Buff
    BUFFTYPE_DININGROOM_PROGRESS = "DiningProgress", -- 能量进度buff
    -- BUFFTYPE_DININGROOM_PACKAGE = "DinnerPackage", -- 食材包Buff
    BUFFTYPE_DININGROOM_FOOD = "DiningDoubleAward", -- 菜品奖励Buff
    BUFFTYPE_COINPUSHER_WALL = "CoinPusherWallBuff", --推币机升墙
    BUFFTYPE_COINPUSHER_PRIZE = "CoinPusherDoubleAwardBuff", --推币机奖励
    BUFFTYPE_COINPUSHER_PUSHER = "CoinPusherLengthBuff", --推币机长推
    BUFFTYPE_BATTLEPASS_BOOSTER = "BattlePassBooster", --battlepass buff
    BUFFTYPE_WORD_DOUBLE_COLLECT = "WordDoubleCollect", -- 集字活动 双倍buff
    BUFFTYPE_WORD_TREASURE = "WordTreasureBuff", -- 集字活动 宝箱buff
    -- 关卡比赛加速
    BUFFTYPE_ARENA_DOUBLE_SCORE = "ArenaDoubleScore",
    -- 集卡神像提供的6个buff
    BUFFTYPE_CARD_LOTTO_COIN_BONUS = "SpecialLetto", -- LOTTO结算时，金币加成
    BUFFTYPE_CARD_NADO_REWARD_BONUS = "SpecialNado", -- NADO机结算时，金币、高倍场点数、vip点数加成
    BUFFTYPE_CARD_COMPLETE_COIN_BONUS = "SpecialCardCoin", -- 章节以及赛季集齐结算时，金币加成
    BUFFTYPE_GEMSHOP_GEM_BONUS = "SpecialGems", -- 钻石商城购买时，钻石加成
    BUFFTYPE_COINSHOP_CARD_PACKAGE_BONUS = "SpecialCardDouble", -- 金币商城购买时，卡包数量翻倍，
    BUFFTYPE_COINSHOP_CARD_STAR_BONUS = "SpecialCardStarUp", -- 金币商城购买时，卡包内卡牌的星级提升
    -- 装修促销提供的3个buff
    BUFFTYPE_REDECORATE_PROGRESS = "RedecorateProgress", -- 装修，能量双倍，票双倍
    BUFFTYPE_REDECORATE_DOUBLE_AWARD = "RedecorateDoubleAward", -- 装修，章节奖励双倍，宝箱奖励双倍
    -- 扑克促销提供的buff
    BUFFTYPE_POKER_PROGRESS = "PokerDoubleSpinDrop", -- 关卡收集双倍
    BUFFTYPE_NEWCOINPUSHER_WALL = "NewCoinPusherWallBuff", --新版推币机升墙
    BUFFTYPE_NEWCOINPUSHER_PRIZE = "NewCoinPusherDoubleItemBuff", --新版推币机双倍道具
    BUFFTYPE_NEWCOINPUSHER_PUSHER = "NewCoinPusherSpinStrengthenBuff", --新版推币机spin加强
    BUFFTYPE_FACTION_FIGHT = "FactionFightDoubleBuff", -- 红蓝对决双倍积分

    BUFFTYPE_PIPECONNECT_DOUBLE_BUFF = "PipeConnectDoubleItemBuff", -- 接水管双倍道具
    BUFFTYPE_PIPECONNECT_DOUBLE_COIN = "PipeConnectDoubleCoinsBuff",  --接水管双倍金币
    BUFFTYPE_PIPECONNECT_WILD = "PipeConnectSlotWildBuff", --接水管固定WILD
    BUFFTYPE_ZOMBIECONNECT_DOUBLE = "ZombieDoubleDrop", --zombie
    
    BUFFTYPE_SPECIALCLAN_QUEST = "CardQuestMoreBuff", -- 特殊集卡 在QUEST中的buff
    BUFFTYPE_SPECIALCLAN_ALBUM = "CardAlbumMoreBuff", -- 特殊集卡 在集卡中的buff

    BUFFTYPE_QUESTICONS_MORE = "QuestMore", -- quest pass 中金币加成
    BUFFTYPE_LUCKYRACE_BOOST = "LuckyRaceBoost", -- 单人限时比赛 buff

    BUFFTYPE_OUTSIDECAVE_DOUBLE_FORWARD = "OutsideCaveStepDoubleBuff", -- 大富翁双倍前进步数
    BUFFTYPE_OUTSIDECAVE_DOUBLE_COIN = "OutsideCaveCoinsDoubleBuff",  --大富翁双倍金币
    BUFFTYPE_OUTSIDECAVE_WILD = "OutsideCaveFixWildBuff", --大富翁固定WILD

    BUFFTYPE_EGYPTCOINPUSHER_WALL = "CoinPusherV3WallBuff", --埃及推币机 升墙
    BUFFTYPE_EGYPTCOINPUSHER_PRIZE = "CoinPusherV3DoubleAwardBuff", --埃及推币机 双倍奖励
    BUFFTYPE_EGYPTCOINPUSHER_ITEM = "CoinPusherV3DoubleItemBuff", --埃及推币机 掉落双倍
    BUFFTYPE_NEWDCJC_BOOST = "LuckyChallengeV2Boost", -- 钻石挑战加成 buff

    BUFFTYPE_DIY_BATTERY = "DIYDOUBLEDROP", -- 限定时间内每次集齐所获取的道具数量*2

}

------------------LocalGame-----------------------
GD.SPIN = "SPIN"
GD.BONUS_ACTION_PROCESS = "BONUS_ACTION_PROCESS"
GD.FREE_SPIN = "FREE_SPIN"
GD.RESPIN = "RESPIN"

---------------------------------------------------
-- 登陆前需要用的模块，登陆后才用到的模块不要在这里添加 ---
local SlotRunData = require "data.baseDatas.SlotRunData"
local UserRunData = require "data.baseDatas.UserRunData"
local GameGlobalConfig = require "data.baseDatas.GameGlobalConfig"
local RateUsData = require "data.baseDatas.RateUsData"
-- =============================================

-- 付费掉落
local PurchaseCardConfig = nil
-- jackpot 推送
local JackpotPushData = nil
-- 高倍场
local DeluexeClubData = nil

-- 每日任务4个任务活动
local PowerMissionData = nil

-- 每日任务每个任务都送卡活动
local EveryCardMissionData = nil
local SpinBonusData = nil

--gameCraze 关卡featurebuff
-- local GameCrazeData = nil
-- battlePass活动
-- local BattlePassData = nil
-- 背包
local ItemsConfig = nil
--七日签到
local SevenDaySignData = nil
--活动任务
local ActivityTaskData = nil
--新版活动任务
local ActivityTaskNewData = nil
--每日签到
local DailySignData = nil
--新手期 每日签到
local DailyBonusNoviceData = nil
-- FB奖励
local FBRewardData = nil
-- FB生日礼物
local FBBirthdayRewardData = nil
-- 弹板CD数据
local PopCdData = nil
-- 乐透数据
local LotteryData = nil
-- 头像框数据
local AvatarFrameData = nil
--广告激励相关 任务
local AdChallengeData = nil

-- 浇花数据
local FlowerData = nil
-- 新手7日目标数据
local NewUser7DayData = nil
local userInfoData = nil
local InviteData = nil
local FriendData = nil

local LuckySpinV2Data = nil

local CollectLevelData = nil

local GlobalData = class("GlobalData", BaseSingleton)
GlobalData.skipForeGround = nil -- 防止后台回来时无效重启游戏

GlobalData.coinsSoundType = 0 --金币音乐类型

GlobalData.lobbyScorllx = nil -- 大厅滑动坐标
GlobalData.DeluexeClubScorllx = nil -- 高倍场滑动坐标
GlobalData.unlockMachineName = nil --解锁关卡名称
GlobalData.activityCount = 0 --大厅活动占用位置
GlobalData.lastLevelName = nil --热门关卡最后一个的名字
GlobalData.lobbyFirstLevelNodeIndex = nil -- 大厅关卡位置索引

GlobalData.topUICoinCount = nil --上ui显示金币数量
GlobalData.recordLastWinCoin = nil --上ui显示金币数量
GlobalData.topUIScale = nil --金币飞行落点

GlobalData.flyCoinsEndPos = nil --金币飞行落点
GlobalData.recordHorizontalEndPos = nil --记录大厅金币落点 用在竖版关卡进入横屏集卡
GlobalData.flyCoinsRotationEndPos = nil --金币竖屏飞行落点
GlobalData.seqId = nil -- 当前全局 seqid -- 仅仅用作记录
GlobalData.lobbyVedioNode = nil --大厅的广告节点
GlobalData.lobbyVedioChallgeNode = nil --大厅的广告任务节点
GlobalData.lobbyScale = 1 --大厅缩放
--------------------  救济金   --------------------
GlobalData.reliefFundsTimes = nil

--------------------  每日任务相关   --------------------
GlobalData.tasksDailyData = nil
GlobalData.tasksDailyTime = nil
GlobalData.tasksCollectPoints = nil
GlobalData.tasksCollectstate = nil

--------------------  Quest相关   --------------------
GlobalData.questData = nil
GlobalData.averageBet = nil
--------------------  功能相关   --------------------
GlobalData.taskTime = nil
GlobalData.rewardTime = nil -- 每小时奖励记录的时间
GlobalData.rewardCount = nil --领过几次
GlobalData.rewardID = nil --使用时间为ID
GlobalData.operaId = nil

GlobalData.userRate = nil
GlobalData.isOpenUserRate = nil

GlobalData.activity_entry = nil --活动入口csv

GlobalData.newPeriod = nil

GlobalData.timeScale = 1 --当前倍速

GlobalData.slotRunData = nil
GlobalData.userRunData = nil
GlobalData.iapRunData = nil
GlobalData.shopRunData = nil
GlobalData.jackpotRunData = nil
GlobalData.levelRunData = nil
GlobalData.missionRunData = nil
GlobalData.buffConfigData = nil
GlobalData.constantData = nil --- 常量数据
GlobalData.saleRunData = nil --促销(基础、主题、多档)
GlobalData.adsRunData = nil
GlobalData.GameConfig = nil --打开游戏同步过来的配置
GlobalData.rateUsData = nil --引导评价数据

GlobalData.commonActivityData = nil --开启活动信息

GlobalData.findLock = nil --bet开启条件
GlobalData.bingoCollectPos = nil -- bingo 收集的起点
GlobalData.deluexeClubData = nil -- 高倍场 数据
GlobalData.deluexeStatus = nil -- 高倍场 状态进游戏初始化，弹窗Flag
GlobalData.deluexeHall = nil -- 打开高倍场大厅

GlobalData.isForceUpgrade = nil --强更
GlobalData.isUpgradeTips = nil --热更提示

GlobalData.luckySpinData = nil
GlobalData.luckySpinSaleData = nil
GlobalData.luckySpinCardData = nil
GlobalData.luckySpinAppointCardData = nil
GlobalData.levelDashData = nil

GlobalData.hasPurchase = nil --用户是否付费

GlobalData.requestId = nil --requestId

GlobalData.jackpotPushList = nil --jackpot推送

GlobalData.isSpinEnd = nil --是否在spin中

GlobalData.iapLuckySpinFunc = nil --是否正在luckyspin补单

GlobalData.purchaseCards = nil --付费卡牌掉落
GlobalData.purchaseActCards = nil --付费卡牌掉落--卡牌促销活动提升星级开启时用
GlobalData.purchaseBuffCards = nil --付费卡牌掉落--卡牌促销活动提升星级开启时用

GlobalData.isPurchaseCallback = nil -- 是否购买回调
GlobalData.sendCouponFlag = nil -- 是否送促销卷
GlobalData.PowerMissionData = nil -- 每日任务4个任务活动
GlobalData.everyCardMissionData = nil -- 每日任务每个任务都送卡活动
GlobalData.spinBonusData = nil -- spinbonus

-- GlobalData.cardStarData = nil
-- GlobalData.doubleCardData = nil

-- GlobalData.bonusHuntData = nil

-- GlobalData.gameCrazeData = nil

GlobalData.isMoreGames2Lobby = nil
GlobalData.jump2Lobby2Level = nil
GlobalData.jump2Lobby2LevelId = nil
GlobalData.jump2Lobby2LevelOrder = nil
GlobalData.playCardGame = nil --是否需要断线重连集卡小游戏
GlobalData.inCardSmallGame = nil --是否需要断线重连集卡小游戏
GlobalData.wheelParam = nil --通用轮盘参数
GlobalData.rateUsNeedReward = nil --商店评价之后给奖励

GlobalData.questJackpotCoins = nil -- questjackpot滚动值
GlobalData.openDebugCode = nil --正式服打印开关
GlobalData.luckyChallengeData = nil --luckyChallenge数据

GlobalData.gameLobbyHomeNodePos = nil --游戏内大厅节点坐标
GlobalData.gameRealViewsSize = nil --游戏内除去上下ui的可视区域
GlobalData.newMessageNums = nil -- 多少条未读的客服消息

GlobalData.itemsConfig = nil -- 背包

GlobalData.popCdData = nil -- 弹板CD数据
GlobalData.jackpotPushFlag = nil --大奖推送开关

GlobalData.activityTaskData = nil --活动任务
GlobalData.activityTaskNewData = nil --新版活动任务

GlobalData.dailySignData = nil --每日签到
GlobalData.dailyBonusNoviceData = nil -- 新手期每日签到
GlobalData.FBRewardData = nil -- FB奖励
GlobalData.FBBirthdayRewardData = nil -- FB生日礼物
GlobalData.InboxFbJumpData = {} -- 邮件大R玩家跳转数据

GlobalData.AdChallengeData = nil --广告激励相关 任务
GlobalData.winFlyNodePos = nil -- 赢钱的起点

GlobalData.LevelRushLuckyStampCoinsEndPos = nil --levelRush购买盖章金币飞的位置

function GlobalData:ctor()
    GlobalData.super.ctor(self)
    self.currLevelExper = 0

    self.questData = nil

    self.tasksDailyData = nil
    self.tasksDailyTime = 0
    self.tasksCollectPoints = 0
    self.tasksCollectstate = {0, 0}

    self.averageBet = {}

    self.activity_entry = nil

    self.newPeriod = nil
    self.findLock = false
    self.activityCount = 0

    self.openDebugCode = 0

    self.recordLastWinCoin = 0
    self.questJackpotCoins = 0

    self.GameConfig = GameGlobalConfig:create()
    self.userRunData = UserRunData:create()
    self.slotRunData = SlotRunData:create()
    self.rateUsData = RateUsData:create()
end

--[[
    @desc: 初始化游戏内数据模块（游戏内功能的数据模块都在这里导入）
    author:{author}
    time:2022-10-08 10:53:47
    @return:
]]
function GlobalData:initGameData()
    local IAPRunData = require("data.baseDatas.IAPRunData")
    self.iapRunData = IAPRunData:create()

    local ShopRunData = require("data.baseDatas.ShopRunData")
    self.shopRunData = ShopRunData:create()

    local JackpotRunData = require "data.baseDatas.JackpotRunData"
    self.jackpotRunData = JackpotRunData:create()

    local LevelRunData = require("data.baseDatas.LevelRunData")
    self.levelRunData = LevelRunData:create()

    local MissionRunData = require("data.baseDatas.MissionRunData")
    self.missionRunData = MissionRunData:create()

    local BuffConfigData = require("data.baseDatas.BuffConfigData")
    self.buffConfigData = BuffConfigData:create()

    local ConstantData = require("data.baseDatas.ConstantData")
    self.constantData = ConstantData:create()

    local SaleRunData = require("data.baseDatas.SaleConfig")
    self.saleRunData = SaleRunData:create()

    local ActivityData = require("data.baseDatas.ActivityData")
    self.commonActivityData = ActivityData:create()

    local AdsRunData = require("data.baseDatas.AdsRunData")
    self.adsRunData = AdsRunData:create()

    -- lucky spin
    local LuckySpinData = require("data.baseDatas.LuckySpinData")
    self.luckySpinData = LuckySpinData:create()

    local LuckySpinSaleData = require("data.luckySpin.LuckySpinSaleData")
    self.luckySpinSaleData = LuckySpinSaleData:create()

    local LuckySpinCardData = require("data.baseDatas.LuckySpinCardData")
    self.luckySpinCardData = LuckySpinCardData:create()

    local LuckySpinAppointCardData = require("data.baseDatas.LuckySpinAppointCardData")
    self.luckySpinAppointCardData = LuckySpinAppointCardData:create()
    --好友
    FriendData = require("GameModule.Friend.model.FriendData")
    --付费掉落
    PurchaseCardConfig = require("data.baseDatas.PurchaseCardConfig")
    -- jackpot 推送
    JackpotPushData = require("data.baseDatas.JackpotPushData")
    -- 高倍场
    DeluexeClubData = require("data.baseDatas.DeluexeClubData")

    -- 每日任务4个任务活动
    PowerMissionData = require("data.baseDatas.PowerMissionData")

    -- 每日任务每个任务都送卡活动
    EveryCardMissionData = require("data.baseDatas.EveryCardMissionData")
    SpinBonusData = require("data.baseDatas.SpinBonusData")

    --gameCraze 关卡featurebuff
    -- GameCrazeData = require("data.baseDatas.GameCrazeData")
    -- battlePass活动
    -- BattlePassData = require("data.battlePass.BattlePassData")
    -- 背包
    ItemsConfig = require("data.baseDatas.ItemsConfig")
    --七日签到
    SevenDaySignData = require("data.baseDatas.SevenDaySignData")
    --活动任务
    ActivityTaskData = require("data.baseDatas.ActivityTaskData")
    --新版活动任务
    ActivityTaskNewData = require("data.baseDatas.ActivityTaskNewData")
    --每日签到
    DailySignData = require("data.baseDatas.DailySignData")
     --新手期 每日签到
    DailyBonusNoviceData = require("data.baseDatas.DailyBonusNoviceData")
    -- FB奖励
    FBRewardData = require("data.FB.FBRewardData")
    -- FB生日礼物
    FBBirthdayRewardData = require("data.FB.FBBirthdayRewardData")
    -- 弹板CD数据
    PopCdData = require("data.popUp.PopCdData")
    -- 乐透数据
    LotteryData = require("GameModule.Lottery.model.LotteryData")
    -- 头像框数据
    AvatarFrameData = require("GameModule.Avatar.model.AvatarFrameData")
    --广告激励相关 任务
    AdChallengeData = require("data.baseDatas.AdChallengeData")

    -- 浇花数据
    FlowerData = require("GameModule.Flower.model.FlowerData")
    -- 新手7日目标数据
    NewUser7DayData = require("GameModule.NewUser7Day.model.NewUser7DayData")
    userInfoData = require("GameModule.UserInfo.model.UserInfoData")
    InviteData = require("GameModule.Invite.model.InviteData")
    CollectLevelData = require("GameModule.CollectLevel.model.CollectLevelData")

    LuckySpinV2Data = require("GameModule.LuckySpin.model.LuckySpinV2Data")

    -- self.levelDashData = LevelDashData:create()
    -- self.sendCouponConfig = SendCouponConfig:create()
    self.powerMissionData = PowerMissionData:create()
    self.everyCardMissionData = EveryCardMissionData:create()
    self.spinBonusData = SpinBonusData:create()

    self.itemsConfig = ItemsConfig:create()

    self.activityTaskData = ActivityTaskData:create()
    self.activityTaskNewData = ActivityTaskNewData:create()
    self.dailySignData = DailySignData:create()
    self.dailyBonusNoviceData = DailyBonusNoviceData:create()
    self.FBRewardData = FBRewardData:create()
    self.lotteryData = LotteryData:create()
    self.newUser7DayData = NewUser7DayData:create()
    self.FBBirthdayRewardData = FBBirthdayRewardData:create()
    self.avatarFrameData = AvatarFrameData:create()

    self.AdChallengeData = AdChallengeData:create()

    local UserRate = require "data.UserRate"
    self.userRate = UserRate:create()

    self.deluexeClubData = DeluexeClubData:create()

    -- self.gameCrazeData = GameCrazeData:create()

    self.popCdData = PopCdData:create()

    self.flowerData = FlowerData:create()
    self.userInfoData = userInfoData:create()

    self.inviteData = InviteData:create()

    self.collectLevelData = CollectLevelData:create()
    self.friendData = FriendData:create()
    self.luckySpinV2 = LuckySpinV2Data:create()
end

local BASE_PRICE = 5
----
--根据金币计算出 约等于多少刀$
function GlobalData.getPriceCollect(coinCount)
    local price = 0
    if coinCount < 60000000 then
        price = BASE_PRICE + (coinCount - 15000000) / 9000000
    elseif coinCount < 180000000 then
        price = BASE_PRICE + (60000000 - 15000000) / 9000000 + (coinCount - 60000000) / 12000000
    elseif coinCount < 650000000 then
        price = BASE_PRICE + (60000000 - 15000000) / 9000000 + (180000000 - 60000000) / 12000000 + (coinCount - 180000000) / 15600000
    else
        price = BASE_PRICE + (60000000 - 15000000) / 9000000 + (180000000 - 60000000) / 12000000 + (650000000 - 180000000) / 15600000 + (coinCount - 650000000) / 27000000
    end

    return price
end

--[[
    @desc:
    time:2019-04-12 14:11:51
    @param: commonConfig 配置文件
    @return:
]]
function GlobalData.syncUserConfig(commonConfig, bLogon)
    -- 策划配置的常量
    if commonConfig.constants ~= nil and #commonConfig.constants > 0 then
        local constantsData = commonConfig.constants
        globalData.constantData:parseData(constantsData)
    end

    ---------------------------- 关卡数据相关 ----------------------------
    if bLogon then
        -- syncUserConfig 会进入多次，只负责登录了的处理, 登录同步玩家是哪个分组

        -- C组 新手初始金币为0
        if globalData.GameConfig:checkUseNewNoviceFeatures() then
            FIRST_LOBBY_COINS = 0
        end
    end

    -- 服务器给的关卡数据 各个if and后面跟的判断条件都是判断当前数据是否发生了改变
    if commonConfig.games ~= nil and commonConfig.games ~= "" and #commonConfig.games > 0 then
        local machineConfigs = commonConfig.games -- 如果此字段是数组那么不允许使用HasField 判断
        globalData.syncMachineConfigs(machineConfigs, bLogon)
    end
    ---------------------------- 关卡数据相关 ----------------------------

    if commonConfig:HasField("shop") then
        local shopConfig = commonConfig.shop
        globalData.syncShopConfig(shopConfig)
    end

    if commonConfig:HasField("buckStore") then
        G_GetMgr(G_REF.ShopBuck):parseData(commonConfig.buckStore)
    end

    if commonConfig:HasField("levels") then
        local levelConfig = commonConfig.levels
        globalData.syncLevelConfig(levelConfig)
    end

    if commonConfig:HasField("bets") then
        local betsData = commonConfig.bets
        globalData.syncBetsConfig(betsData)
    end

    if commonConfig:HasField("flower") then
        local flowerData = commonConfig.flower
        globalData.parseFlowerConfig(flowerData)
    end

    if commonConfig:HasField("vip") then
        G_GetMgr(G_REF.Vip):parseData(commonConfig.vip)
    end

    if commonConfig:HasField("cashBonus") then
        G_GetMgr(G_REF.CashBonus):parseData(commonConfig.cashBonus)

        -- TODO 这条数据 cashBonus数据 是依存关系 这两条数据应该合到一起 服务器不好改 客户端自己处理了
        if commonConfig.allMultiple ~= nil and #commonConfig.allMultiple > 0 then
            G_GetMgr(G_REF.CashBonus):parseAllMultipleDatas(commonConfig.allMultiple)
        end
    end

    if commonConfig.buffs ~= nil and #commonConfig.buffs > 0 then
        local buffs = commonConfig.buffs
        globalData.syncBuffs(buffs)
    end

    --促销相关
    if commonConfig:HasField("sales") then
        local saleConfig = commonConfig.sales
        globalData.syncSaleConfig(saleConfig)
    end

    if commonConfig:HasField("jackpots") then
        local jackpots = commonConfig.jackpots
        globalData.syncJackpotsConfig(jackpots)
    end

    -- 解析本地关卡全局配置文件
    globalData.syncLevelRunDatesConfig()

    --是否是付费用户
    if commonConfig:HasField("hasPurchase") then
        globalData.hasPurchase = commonConfig.hasPurchase
    end

    if commonConfig.highLimitGames ~= nil and commonConfig.highLimitGames ~= "" and #commonConfig.highLimitGames > 0 then
        local highBetMachine = commonConfig.highLimitGames
        globalData.syncMachineConfigs(highBetMachine)
    end

    if commonConfig:HasField("highLimitBets") then
        local highLimitBets = commonConfig.highLimitBets
        globalData.syncBetsConfig(highLimitBets)
    end

    if commonConfig:HasField("highLimit") then
        local highLimit = commonConfig.highLimit
        globalData.syncDeluexeClubData(highLimit)
    end
    --付费掉落
    if commonConfig.purchaseCards ~= nil and #commonConfig.purchaseCards > 0 then
        globalData.syncPurchaseCardConfig(commonConfig.purchaseCards)
    end

    --付费掉落(提升卡牌星级活动用)
    if commonConfig.purchaseActCards ~= nil and #commonConfig.purchaseActCards > 0 then
        globalData.syncPurchaseActCardConfig(commonConfig.purchaseActCards)
    end

    if commonConfig:HasField("advertisement") == true then
        globalData.syncAdsExtraConfig(commonConfig.advertisement)
    end

    -- 当前的赛季id
    if commonConfig:HasField("cardAlbumId") == true then
        globalData.cardAlbumId = commonConfig.cardAlbumId
    end

    -- cardnewuser todo 是否是新手期集卡
    -- if commonConfig:HasField("noviceCard") == true then
    --     CardSysManager:setLoginNovice(commonConfig.noviceCard)
    -- end

    if commonConfig:HasField("items") == true then
        globalData.parseItemsConfig(commonConfig.items)
    end
    --每日签到
    if commonConfig:HasField("dailySign") == true then
        globalData.parseDailySignConfig(commonConfig.dailySign)
    end

    --新手期 每日签到
    if commonConfig:HasField("noviceCheckV2") == true then
        G_GetMgr(G_REF.NoviceSevenSign):parseData(commonConfig.noviceCheckV2)
    elseif commonConfig:HasField("noviceCheck") == true then
        globalData.parseDailyBonusNoviceConfig(commonConfig.noviceCheck)
    end

    -- 付费掉落神像buff双倍掉落
    if commonConfig.purchaseBuffCards ~= nil and #commonConfig.purchaseBuffCards > 0 then
        globalData.syncPurchaseBuffCardConfig(commonConfig.purchaseBuffCards)
    end

    -- free spin 免费次数
    if commonConfig:HasField("freeGame") == true then
        globalData.syncFreeGameRewards(commonConfig.freeGame)
    end

    -- FB奖励
    if commonConfig:HasField("facebookReward") == true then
        globalData.parseFBRewardConfig(commonConfig.facebookReward)
    end

    -- 乐透数据
    if commonConfig:HasField("lottery") == true then
        globalData.parseLotteryConfig(commonConfig.lottery)
    end

    -- facebook 成员生日礼物
    if commonConfig:HasField("birthdayReward") == true then
        globalData.parseFBBirthdayReward(commonConfig.birthdayReward)
    end

    -- 头像框数据
    if commonConfig:HasField("avatarFrame") == true then
        globalData.parseAvatarFrameData(commonConfig.avatarFrame)
    end

    -- 广告激励相关
    if commonConfig:HasField("adRewards") == true then
        globalData.parseAdChallengeData(commonConfig.adRewards)
    end

    -- 新手七日目标数据
    if commonConfig:HasField("vegasTrip") then
        globalData:parseNewUser7DayData(commonConfig.vegasTrip)
    end

    -- 邮件大R玩家跳转数据
    if commonConfig:HasField("messageName") == true then
        globalData.parseInboxFbJumpData(commonConfig.messageName)
    end

    -- 当前的赛季轮次
    if commonConfig:HasField("cardRound") == true then
        globalData.cardAlbumRound = commonConfig.cardRound
    end

    -- 集卡排行榜
    if commonConfig:HasField("cardRank") == true then
        G_GetMgr(G_REF.CardRank):parseData(commonConfig.cardRank)
    end

    -- 农场
    if commonConfig:HasField("farm") == true then
        G_GetMgr(G_REF.Farm):parseData(commonConfig.farm)
    end

    -- vip重置数据
    if commonConfig:HasField("vipReset") == true then
        local vipData = G_GetMgr(G_REF.Vip):getData()
        if vipData then
            vipData:parseResetData(commonConfig.vipReset)
        end
    end

    -- 新手集卡
    if commonConfig:HasField("cardSimpleInfo") == true then
        local mgr = G_GetMgr(G_REF.CardNovice)
        if mgr then
            mgr:setNoviceCardSimpleInfo(commonConfig.cardSimpleInfo)
        end

        local mgr = G_GetMgr(ACTIVITY_REF.CardOpenNewUser)
        if mgr then
            mgr:setNoviceCardSimpleInfo(commonConfig.cardSimpleInfo)
        end
    end

    -- 新版破冰促销
    if commonConfig:HasField("iceBrokenSale") == true then
        G_GetMgr(G_REF.IcebreakerSale):parseData(commonConfig.iceBrokenSale)
    end
    
    -- 成长基金
    if commonConfig:HasField("growthFundV3") == true then
        G_GetMgr(G_REF.GrowthFund):parseData(commonConfig.growthFundV3, true)
    elseif commonConfig:HasField("growthFund") == true then
        G_GetMgr(G_REF.GrowthFund):parseData(commonConfig.growthFund)
    end

    -- 月卡
    if commonConfig:HasField("monthlyCard") == true then
        G_GetMgr(G_REF.MonthlyCard):parseData(commonConfig.monthlyCard)
    end
    
    -- 破圈系统
    if commonConfig:HasField("expandCircle") == true then
        G_GetMgr(G_REF.NewUserExpand):parseData(commonConfig.expandCircle)
    end

    -- 等级膨胀点
    if commonConfig.inflationLevels and #commonConfig.inflationLevels > 0 then
        globalData.GameConfig:parseInflationLevels(commonConfig.inflationLevels)
    end

    -- 限时促销
    if commonConfig:HasField("hourDeal") == true then
        G_GetMgr(G_REF.HourDeal):parseData(commonConfig.hourDeal)
    end

    -- 4周年抽奖分奖
    if commonConfig:HasField("fourBirthdayDrawReward") == true then
        G_GetMgr(ACTIVITY_REF.dayDraw4B):parseRewardData(commonConfig.fourBirthdayDrawReward)
    end
    
    -- 新手集卡 促销
    if commonConfig:HasField("albumSale") == true then
        G_GetMgr(G_REF.CardNoviceSale):parseData(commonConfig.albumSale)
    end

    -- 等级里程碑
    if commonConfig:HasField("levelRoad") == true then
        G_GetMgr(G_REF.LevelRoad):parseData(commonConfig.levelRoad)
    end
    
    -- 次日礼物
    if commonConfig:HasField("tomorrowGift") then
        G_GetMgr(G_REF.TomorrowGift):parseData(commonConfig.tomorrowGift)
    end
    
    -- 新手任务 (新加任务， 优化服务器维护任务信息）
    if commonConfig:HasField("newUserGuide") == true then
        G_GetMgr(G_REF.SysNoviceTask):parseData(commonConfig.newUserGuide)
    end
    --新版luckySpinV2
    if commonConfig:HasField("luckySpinV2") == true then
        globalData.luckySpinV2:parseData(commonConfig.luckySpinV2)
    end

    -- 合成pass
    if commonConfig:HasField("mergePass") then
        G_GetMgr(ACTIVITY_REF.MergePass):parseData(commonConfig.mergePass)
    end

    -- appCharge
    if commonConfig:HasField("appCharge") then
        G_GetMgr(G_REF.AppCharge):parseData(commonConfig.appCharge)
    end
    
    --亿万赢家挑战
    if commonConfig:HasField("trillionsWinnerChallenge") == true then
        G_GetMgr(G_REF.TrillionChallenge):parseData(commonConfig.trillionsWinnerChallenge)
    end

    -- 运营引导弹窗 功能配置
    if commonConfig:HasField("guidePopups") then
        G_GetMgr(G_REF.OperateGuidePopup):parseData(commonConfig.guidePopups)
    end
    
    -- 宠物系统
    if commonConfig:HasField("sidekicks") then
        G_GetMgr(G_REF.Sidekicks):parseData(commonConfig.sidekicks)
    end

    -- 神秘宝箱系统
    if commonConfig:HasField("passMysteryBox") then
        G_GetMgr(G_REF.BoxSystem):parseData(commonConfig.passMysteryBox)
    end
end

--[[
    @desc:
    time:2019-04-20 11:56:31
    @return:
]]
function GlobalData.syncSevenDaySign(data)
    -- if globalData.sevenDaySignData then
    --     globalData.sevenDaySignData:parseData(data)
    -- end
    globalData.commonActivityData:parseActivityData(data, ACTIVITY_REF.SevenDaySign)
end

-- --[[
--     @desc: 解析同步 vip config
--     time:2019-04-16 16:48:28
--     --@vipConfig:
--     @return:
-- ]]
-- function GlobalData.syncVipConfig(vipConfig)
--     if vipConfig ~= nil and vipConfig.config ~= nil and #vipConfig.config > 0 then
--         glVipCsvData.parseVipDatas(vipConfig.config)
--     end
-- end

--[[
    @desc: 解析同步 jackpots 数据
    time:2019-04-16 16:47:52
    --@jackpots:
    @return:
]]
function GlobalData.syncJackpotsConfig(jackpots)
    if jackpots ~= nil and jackpots.maxBets ~= nil and #jackpots.maxBets > 0 then
        globalData.jackpotRunData:parseJackpotConfig()
        globalData.jackpotRunData:parseMaxToalBets(jackpots)
        globalData.jackpotRunData:readJackpotData()
    end
end

--[[
    @desc: 解析同步 levelRunDate 数据
    time:2019-04-16 16:47:52
    @return:
]]
function GlobalData.syncLevelRunDatesConfig()
    -- local levelRunDatas = gLobalResManager:parseCsvDataByName("Csv/Csv_Level_RunData.csv")
    -- globalData.levelRunData:parseLevelRunConfig(levelRunDatas)
end

--[[
    @desc: 解析同步 machine configs
    time:2019-04-16 16:47:04
    --@machineConfigs:
    @return:
]]
function GlobalData.syncMachineConfigs(_machineConfigs, _bLogon)
    if _machineConfigs ~= nil and #_machineConfigs > 0 then
        globalData.slotRunData:parseMachineBaseData(_machineConfigs, _bLogon)
    end
end

--[[
    @desc: 解析 levelconfig 信息
    time:2019-04-16 16:46:22
    --@levelConfig:
    @return:
]]
function GlobalData.syncLevelConfig(levelConfig)
    if levelConfig ~= nil and levelConfig.current ~= nil and levelConfig.current ~= "" then
        globalData.userRunData:parsePrevLevelData(levelConfig["prev"])
        globalData.userRunData:parseCurLevelData(levelConfig["current"])
        globalData.userRunData:parseNextLevelData(levelConfig["next"])
    end
end

--[[
    @desc: 解析 bets config信息
    time:2019-04-16 16:45:49
    --@betsData:
    @return:
]]
function GlobalData.syncBetsConfig(betsData)
    if betsData ~= nil then
        local machienData = globalData.slotRunData.machineData
        if machienData ~= nil then
            machienData:parseMachineBetsData(betsData)
        end
    end
end

--[[
    @desc:同步解析 商城配置
    time:2019-04-16 16:10:10
    --@shopConfig:
    @return:
]]
function GlobalData.syncShopConfig(shopConfig)
    if shopConfig ~= nil and shopConfig.coins ~= nil and #shopConfig.coins > 0 then
        globalData.shopRunData:parseShopData(shopConfig)
        if globalData.luckySpinV2 then
            globalData.luckySpinV2:upDateGear()
        end
    end
end
--[[
    @desc: 解析用户的基础信息
    time:2019-04-19 21:16:03
    --@simpleUserInfo: 用户的基础信息
    @return:
]]
function GlobalData.syncSimpleUserInfo(simpleUserInfo)
    if simpleUserInfo ~= nil then
        if globalData.userRunData.parseSimpleUserInfo then
            globalData.userRunData:parseSimpleUserInfo(simpleUserInfo)
        else
            local newGems = tonumber(simpleUserInfo.gems)
            -- local newCoins = tonumber(simpleUserInfo.coins)
            local newCoins = simpleUserInfo.coinsV2
            local newLevel = tonumber(simpleUserInfo.level)
            local newExp = tonumber(simpleUserInfo.exp)

            globalData.userRunData.gemNum = newGems
            globalData.userRunData:setCoins(newCoins)
            globalData.userRunData.levelNum = newLevel
            globalData.userRunData.currLevelExper = newExp

            globalData.userRunData.vipLevel = simpleUserInfo.vipLevel
            globalData.userRunData.vipPoints = simpleUserInfo.vipPoint

            globalData.userRunData.rcId = simpleUserInfo.rcId
        end

        -- 消耗钻石数量
        globalData.syncConsumeGems(simpleUserInfo.useGems)
    end
end

-- 消耗钻石数量
function GlobalData.syncConsumeGems(_userGems)
    if _userGems ~= nil and _userGems ~= "" then
        local useGems = tonumber(_userGems)
        if useGems and useGems > 0 then
            -- 请求三合一小猪的数据，同步钻石小猪的数据
            local trioMgr = G_GetMgr(ACTIVITY_REF.TrioPiggy)
            if trioMgr then
                trioMgr:requestTrioPigInfo()
            end
            -- 显示收集弹框
            local gemMgr = G_GetMgr(ACTIVITY_REF.GemPiggy)
            if gemMgr then
                gemMgr:showGemPiggyCollectLayer()
            end
        end    
    end
end

-- free spin 免费次数
function GlobalData.syncFreeGameRewards(data)
    if data ~= nil then
        local freeGameData = globalData.iapRunData:getFreeGameData()
        if freeGameData then
            freeGameData:parseData(data)
        end
    end
end

--[[
    @desc: 解析小猪银行数据
    time:2019-04-16 16:50:04
    @return:
]]
function GlobalData.syncPigCoin(pigConfig)
    if pigConfig ~= nil and pigConfig.price ~= nil and pigConfig.price ~= "" then
        local pigMgr = G_GetMgr(G_REF.PiggyBank)
        if pigMgr then
            pigMgr:parseData(pigConfig)
        end
    end
end

-- 解析每日任务，周任务数据
function GlobalData.syncMission(missionConfig)
    if missionConfig ~= nil then
        globalData.missionRunData:parseData(missionConfig)
    end
end

-- 解析 lucky spin 数据
function GlobalData.syncLuckySpin(lsConfig)
    if lsConfig ~= nil then
        globalData.luckySpinData:parseData(lsConfig)
    end
end

-- 解析 lucky spin 数据
function GlobalData.syncLuckySpinSale(lsConfig)
    if lsConfig ~= nil then
        globalData.luckySpinSaleData:parseData(lsConfig)
    end
end

-- 解析 lucky spin 活动数据
function GlobalData.syncLuckySpinCard(lsConfig)
    if lsConfig ~= nil then
        globalData.luckySpinCardData:parseData(lsConfig)
    end
end

-- 解析 lucky spin 送固定卡
function GlobalData.syncLuckySpinAppointCard(lsConfig)
    if lsConfig ~= nil then
        globalData.luckySpinAppointCardData:parseData(lsConfig)
    end
end

-- 解析 双倍送卡 活动数据
function GlobalData.syncDoubleCard(lsConfig)
    if lsConfig ~= nil then
        globalData.commonActivityData:parseActivityData(lsConfig, ACTIVITY_REF.DoubleCard)
    end
end

-- 解析 bonushunt活动
function GlobalData.syncBonusHunt(lsConfig)
    if lsConfig ~= nil then
        -- if not globalData.bonusHuntData then
        --     globalData.bonusHuntData = BonusHuntData:create()
        -- end
        -- globalData.bonusHuntData:parseData(lsConfig)
        if globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.BonusHunt) then
            globalData.commonActivityData:parseActivityData(lsConfig, ACTIVITY_REF.BonusHunt)
        else
            globalData.commonActivityData:parseActivityData(lsConfig, ACTIVITY_REF.BonusHuntCoin)
        end
    end
end

--解析GameCraze
-- function GlobalData.syncGameCraze(gcData)
--     if gcData ~= nil then
--         if not globalData.gameCrazeData then
--             globalData.gameCrazeData = GameCrazeData:create()
--         end
--         globalData.gameCrazeData:parseData(gcData)
--     end
-- end

-- 解析DinnerLand
function GlobalData.syncDinnerLand(dlData)
    if dlData ~= nil then
        globalData.commonActivityData:parseActivityData(dlData, ACTIVITY_REF.DinnerLand)
    end
end

-- 餐厅排行榜数据
-- function GlobalData.parseDinnerLandRankConfig(data)
--     if data ~= nil then
--         local dinnerLandData = G_GetActivityDataByRef(ACTIVITY_REF.DinnerLand)
--         if dinnerLandData then
--             dinnerLandData.dinnerLandRankConfig = BaseActivityRankCfg:create()
--             dinnerLandData.dinnerLandRankConfig:parseData(data)
--         end
--     end
-- end

-- 解析 商城卡牌星级提升 活动数据
function GlobalData.syncCardStar(lsConfig)
    if lsConfig ~= nil then
        -- globalData.cardStarData:parseData(lsConfig)
        globalData.commonActivityData:parseActivityData(lsConfig, ACTIVITY_REF.CardStar)
    end
end

-- 解析 lucky spin 活动数据
function GlobalData.syncEveryCardMission(lsConfig)
    if lsConfig ~= nil then
        globalData.everyCardMissionData:parseData(lsConfig)
    end
end

-- 解析 每日任务4个任务的活动数据
function GlobalData.syncPowerMissionData(lsConfig)
    if lsConfig ~= nil then
        globalData.powerMissionData:parseData(lsConfig)
    end
end

-- 解析 spinbonus
function GlobalData.syncSpinBonusData(lsConfig)
    if lsConfig ~= nil then
        globalData.spinBonusData:parseData(lsConfig)
    end
end

-- 解析 buffs 信息
function GlobalData.syncBuffs(buffs)
    if buffs ~= nil and #buffs > 0 then
        globalData.buffConfigData:parseData(buffs)
    end
end

function GlobalData.syncSaleConfig(saleConfig)
    if saleConfig ~= nil then
        globalData.commonActivityData:parseSaleDatas(saleConfig)

        globalData.saleRunData:parseData(saleConfig)
    end
end

--游戏全局配置
function GlobalData.syncGameGlobalConfig(config)
    if config ~= nil then
        globalData.GameConfig:parseData(config)
    end
end

--jackpot推送
function GlobalData.syncJackpotPushData(config)
    if not globalData.jackpotPushList then
        globalData.jackpotPushList = {}
    end
    for i = #globalData.jackpotPushList, 1, -1 do
        if globalData.jackpotPushList[i].p_udid ~= globalData.userRunData.userUdid then
            table.remove(globalData.jackpotPushList, i)
        end
    end
    for i = 1, #config do
        local tempData = JackpotPushData:create()
        tempData:parseData(config[i])
        globalData.jackpotPushList[#globalData.jackpotPushList + 1] = tempData
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_JACKPOT_PUSH)
end

-- 更新battlePass数据
-- function GlobalData.syncBattlePassData(data)
--     globalData.commonActivityData:parseActivityData(data, ACTIVITY_REF.BattlePass)
-- end

-- 更新Action数据
function GlobalData:syncActionData(data)
    if not data then
        return
    end

    -- 检测是否需要更新 CommonConfig 信息
    if data:HasField("config") == true then
        globalData.syncUserConfig(data.config)
    end

    if data:HasField("pig") == true then
        globalData.syncPigCoin(data.pig)
    end

    if data:HasField("simpleUser") == true then
        globalData.syncSimpleUserInfo(data.simpleUser)
    end

    --活动相关
    if data:HasField("activity") == true then
        globalData.syncActivityConfig(data.activity)
    end

    -- if data:HasField("gameCrazy") == true then
    --     globalData.syncGameCraze(data.gameCrazy)
    -- end

    if data:HasField("fbCoins") == true then
        globalData.userRunData:setFbBindReward(data.fbCoins)
    end

    --非支付接口返回先不动
    if data.adConfig ~= nil and #data.adConfig > 0 then
        globalData.syncAdConfig(data.adConfig)
    end

    -- 卡片掉落相关 --
    if data.cardDrop ~= nil and #data.cardDrop > 0 then
        CardSysManager:doDropCardsData(data.cardDrop)
    end

    if data:HasField("dailyTask") == true then
        globalData.syncMission(data.dailyTask)
    end

    -- if data:HasField("vegasTornado") == true then
    --     CardSysRuntimeMgr:parsePuzzleGameData(data.vegasTornado)
    -- end

    --关卡 lottoparty
    if data:HasField("teamMission") == true then
        if data:HasField("user") then
            local userData = data.user
            globalData.syncSimpleUserInfo(userData)
            -- local serverCoins = tonumber(userData.coins)
            -- globalData.userRunData:setCoins(serverCoins)
        end
        if LottoPartyManager then
            LottoPartyManager:parseLottoPartyData(data.teamMission)
        end

        --抛出房间数据
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PARSE_ROOM_DATA, {data = data.teamMission})
    end

    -- pass 任务刷新
    if data:HasField("passTask") == true then
        G_GetMgr(ACTIVITY_REF.NewPass):refreshPassTaskData(data.passTask)
    end

    -- MiniGame
    if data:HasField("miniGame") == true then
        gLobalMiniGameManager:parseData(data.miniGame)
    end

    -- 集卡鲨鱼
    if data:HasField("adventureGame") == true then
        G_GetMgr(G_REF.CardSeeker):parseData(data.adventureGame)
    end

    -- 集卡商店
    if data:HasField("store") == true then
        G_GetMgr(G_REF.CardStore):parseData(data.store)
    end

    -- 集卡排行榜
    if data.cardRank ~= nil and data:HasField("cardRank") == true then
        G_GetMgr(G_REF.CardRank):parseData(data.cardRank)
    end
    --好友
    if data:HasField("friendList") == true then
        G_GetMgr(G_REF.Friend):parseData(data.friendList)
    end

    -- 新手 pass 任务刷新
    if data:HasField("newUserPassTask") == true then
        G_GetMgr(ACTIVITY_REF.NewPass):refreshPassTaskData(data.newUserPassTask)
    end

    -- 回归 pass 任务刷新
    if data:HasField("returnTask") == true then
        G_GetMgr(G_REF.Return):refreshTaskData(data.returnTask)
    end    
end

--游戏活动数据
function GlobalData.syncActivityConfig(config, isLogin)
    if config ~= nil then
        -- 解析普通活动数据
        globalData.commonActivityData:parseCommonActivitiesData(config.commonActivities)

        if config:HasField("passTaskExtra") == true then
            globalData.commonActivityData:parseActivityData(config.passTaskExtra, ACTIVITY_REF.Activity_SeasonMission_Dash)
        end

        if config:HasField("levelDashPlus") == true then
            globalData.commonActivityData:parseActivityData(config.levelDashPlus, ACTIVITY_REF.LevelDashPlus)
        end

        if config:HasField("missionRush") == true then
            globalData.commonActivityData:parseActivityData(config.missionRush, ACTIVITY_REF.DailySprint_Coupon)
        end

        if config:HasField("bingo") == true then
            globalData.commonActivityData:parseActivityData(config.bingo, ACTIVITY_REF.Bingo)
        end

        if config:HasField("missionRush") then
            globalData.commonActivityData:parseActivityData(config.missionRush, ACTIVITY_REF.ActivityMissionRushNew)
        end

        -- 大富翁
        if config:HasField("rich") then
            globalData.commonActivityData:parseActivityData(config.rich, ACTIVITY_REF.RichMan)
        end

        -- 新版大富翁
        if config:HasField("worldTrip") then
            globalData.commonActivityData:parseActivityData(config.worldTrip, ACTIVITY_REF.WorldTrip)
        end

        if config:HasField("blast") then
            local blastdata = globalData.commonActivityData:getActivityDataByRef(ACTIVITY_REF.Blast)
            if blastdata and blastdata:isNovice() then
                local config = globalData.GameConfig:getActivityConfigById(config.blast.activityId,ACTIVITY_TYPE.COMMON)
                if config then
                    blastdata:parseNormalActivityData(config)
                end
            end
            local _data = globalData.commonActivityData:parseActivityData(config.blast, ACTIVITY_REF.Blast)
            if _data then
                _data:setNewUser(false)
                G_GetMgr(ACTIVITY_REF.Blast):setNewUserOver(true)
            end
        elseif config:HasField("newUserBlast") then
            local newblast = config.newUserBlast
            if newblast then
                -- local blastdata = globalData.commonActivityData:getActivityDataByRef(ACTIVITY_REF.Blast)
                local blastdata = globalData.commonActivityData:getActivityDataById(newblast.activityId)
                if blastdata and blastdata:getRound() and newblast.round == 2 then
                    G_GetMgr(ACTIVITY_REF.Blast):setNewUserOver(true)
                    blastdata:setConfigData(newblast)
                    blastdata:setNewUser(true)
                elseif newblast.round == 2 then
                    G_GetMgr(ACTIVITY_REF.Blast):setNewUserOver(true)
                    if not isLogin then
                        blastdata = globalData.commonActivityData:parseActivityData(newblast, ACTIVITY_REF.Blast)
                        if blastdata then
                            blastdata:setCompleted(true)
                            blastdata:setNewUser(true)
                        end
                    else
                        -- 登陆是如果新手期已完成，则检查是否有普通活动
                        local config = globalData.GameConfig:getActivityConfigByRef(ACTIVITY_REF.Blast, ACTIVITY_TYPE.COMMON)
                        if config and blastdata then
                            blastdata:parseNormalActivityData(config)
                        else
                            if blastdata then
                                blastdata:setCompleted(true)
                                blastdata:setNewUser(true)
                            end
                        end
                    end
                else
                    blastdata = globalData.commonActivityData:parseActivityData(config.newUserBlast, ACTIVITY_REF.Blast)
                    if blastdata then
                        blastdata:setNewUser(true)
                    end
                end
            end
        end

        if config:HasField("coinPusher") then
            globalData.commonActivityData:parseActivityData(config.coinPusher, ACTIVITY_REF.CoinPusher)
        end

        if config:HasField("bingoRush") then
            globalData.commonActivityData:parseActivityData(config.bingoRush, ACTIVITY_REF.BingoRush)
        end

        --充值抽奖
        if config:HasField("draw") then
            globalData.commonActivityData:parseActivityData(config.draw, ACTIVITY_REF.LuckyChipsDraw)
        end

        if config:HasField("word") then
            globalData.commonActivityData:parseActivityData(config.word, ACTIVITY_REF.Word)
        end

        if config:HasField("redecorate") then
            globalData.commonActivityData:parseActivityData(config.redecorate, ACTIVITY_REF.Redecor)
        end

        if config:HasField("luckySpinSale") then
            globalData.syncLuckySpinSale(config.luckySpinSale)
        end

        if config:HasField("luckySpinCard") then
            globalData.syncLuckySpinCard(config.luckySpinCard)
        end

        if config:HasField("luckySpinGoldenCard") then
            -- globalData.syncLuckySpinGoldenCard(config.luckySpinGoldenCard)
            globalData.commonActivityData:parseActivityData(config.luckySpinGoldenCard, ACTIVITY_REF.LuckySpinGoldenCard)
        end

        if config:HasField("luckySpinCardAppoint") then
            globalData.syncLuckySpinAppointCard(config.luckySpinCardAppoint)
        end

        if config:HasField("cardMission") then
            globalData.syncEveryCardMission(config.cardMission)
        end

        if config:HasField("cardStoreStar") then
            globalData.syncCardStar(config.cardStoreStar)
        end
        if config:HasField("cardStoreDouble") then
            globalData.syncDoubleCard(config.cardStoreDouble)
        end

        -- 每日任务4个任务活动
        if config:HasField("powerMission") == true then
            GlobalData.syncPowerMissionData(config.powerMission)
        end

        --spinbonus
        --[[if config:HasField("spinBonus") == true then
            globalData.syncSpinBonusData(config.spinBonus)
        end]]
        if config:HasField("levelDash") then
            -- globalData.syncLevelDashData(config.levelDash)
            globalData.commonActivityData:parsePromotionData(config.levelDash, ACTIVITY_REF.LevelDash)
        end

        if config.mega ~= nil and #config.mega > 0 then
            globalData.saleRunData:parseMegaResult(config.mega)
        end

        if config:HasField("newUserRepeatWin") == true then
            globalData.commonActivityData:parsePromotionData(config.newUserRepeatWin, ACTIVITY_REF.RepartWin, nil, true)
        elseif config:HasField("repeatWin") == true then
            globalData.commonActivityData:parsePromotionData(config.repeatWin, ACTIVITY_REF.RepartWin)
        end

        if config:HasField("newUserEchoWins") == true then
            globalData.commonActivityData:parsePromotionData(config.newUserEchoWins, ACTIVITY_REF.EchoWin, nil, true)
        elseif config:HasField("echoWins") == true then
            globalData.commonActivityData:parsePromotionData(config.echoWins, ACTIVITY_REF.EchoWin)
        end

        if config:HasField("newUserCoupon") then
            local actData = globalData.commonActivityData:parseActivityData(config.newUserCoupon, ACTIVITY_REF.Coupon)
            if actData then
                actData:setNovice(true)
            end
        elseif config:HasField("coupon") == true then
            globalData.commonActivityData:parseActivityData(config.coupon, ACTIVITY_REF.Coupon)
        end

        if config:HasField("gemCoupon") == true then
            globalData.commonActivityData:parseActivityData(config.gemCoupon, ACTIVITY_REF.GemStoreSale)
        end

        if config:HasField("levelBoom") == true then
            -- globalData.saleRunData:parseLevelBoomResult(config.levelBoom)
            globalData.commonActivityData:parsePromotionData(config.levelBoom, ACTIVITY_REF.LevelBoom)
        end

        if config:HasField("cashBack") == true then
            -- globalData.saleRunData:parseCashBackConfig(config.cashBack)
            G_GetMgr(ACTIVITY_REF.CashBackNovice):parseData(config.cashBack)
            globalData.commonActivityData:parseNoCfgActivityData(config.cashBack, ACTIVITY_REF.CashBack)
        end
        if config:HasField("newUserCashBack") then
            G_GetMgr(ACTIVITY_REF.CashBackNovice):parseNoviceData(config.newUserCashBack)
        end

        -- 小猪银行加成促销 --
        if config:HasField("pigCoins") == true then
            -- globalData.saleRunData:parsePiggyCommonSale(config.pigCoins)
            globalData.commonActivityData:parsePromotionData(config.pigCoins, ACTIVITY_REF.PigCoins)
        end
        -- 小猪银行booster活动 --
        if config:HasField("pigBooster") == true then
            -- globalData.saleRunData:parsePiggyBoostSale(config.pigBooster)
            globalData.commonActivityData:parsePromotionData(config.pigBooster, ACTIVITY_REF.PigBooster)
        end
        -- 公会小猪折扣 活动 --
        if config:HasField("clanPigBankDiscount") == true then
            globalData.commonActivityData:parsePromotionData(config.clanPigBankDiscount, ACTIVITY_REF.PigClanSale)
        end
        if config:HasField("fantasyQuest") == true then
            -- quest 挑战活动
            if config:HasField("questChallenge") then
                -- 补丁代码，以后删掉  原因未问出来
                local _data = G_GetActivityDataByRef(ACTIVITY_REF.QuestNewRush, true)
                if _data then
                    globalData.commonActivityData:parseActivityData(config.questChallenge, ACTIVITY_REF.QuestNewRush)
                end
            end

            if config:HasField("newUserQuest") then
                -- globalData.saleRunData:parseNewUserQuestConfig(config.newUserQuest)
                local newUserQuest = config.newUserQuest
                if newUserQuest then
                    local _oldData = globalData.commonActivityData:getActivityDataByRef(ACTIVITY_REF.Quest)
                    if not ((not _oldData or not _oldData:getOpenFlag()) and newUserQuest.expire <= 0) then
                        -- 本地没有新手Quest或有数据未开启时 且 服务器通知新手Quest结束，则不解析新手Quest
                        local _data = globalData.commonActivityData:parseNoCfgActivityData(newUserQuest, ACTIVITY_REF.Quest)
                        if _data then
                            _data:setNewUserQuest(true)
                            _data:setThemeName("Activity_QuestNewUser")
                            -- TODU 新手quest可以当做quest的一个主题来做 或者当做与常规quest平行的新活动来做 使用quest的数据硬包装成新手quest 对扩展很不友好
                            _data:setStage(newUserQuest.stage) -- 新手quest的特殊操作 解析quest数据的时候 不能确定是不是新手quest
                            G_GetMgr(ACTIVITY_REF.Quest):updateQuestConfig()
                        end
                    end
                    if newUserQuest.offRounds and newUserQuest.offRounds == (newUserQuest.round - 1) then
                        local _data = globalData.commonActivityData:parseActivityData(config.fantasyQuest, ACTIVITY_REF.QuestNew)
                    end
                end
            else
                local _data = globalData.commonActivityData:parseActivityData(config.fantasyQuest, ACTIVITY_REF.QuestNew)
            end
        else
            -- quest 挑战活动
            if config:HasField("questChallenge") then
                -- 补丁代码，以后删掉
                local _data = G_GetActivityDataByRef(ACTIVITY_REF.QuestRush, true)
                if _data then
                    globalData.commonActivityData:parseActivityData(config.questChallenge, ACTIVITY_REF.QuestRush)
                end
            end

            if config:HasField("quest") == true then
                local _data = globalData.commonActivityData:parseActivityData(config.quest, ACTIVITY_REF.Quest)
                if _data then
                    _data:setNewUserQuest(false)

                    -- 新手Quest完成状态特殊处理，也是无奈
                    local hasNewQuest = config:HasField("newUserQuest")
                    if hasNewQuest then
                        local newQuest = config.newUserQuest
                        if newQuest and newQuest.offRounds and newQuest.offRounds == (newQuest.round - 1) then
                            G_GetMgr(ACTIVITY_REF.Quest):setNewUserQuestCompleted(true)
                        end
                    end
                end
            else
                if config:HasField("newUserQuest") then
                    -- globalData.saleRunData:parseNewUserQuestConfig(config.newUserQuest)
                    local newUserQuest = config.newUserQuest
                    if newUserQuest then
                        local _oldData = globalData.commonActivityData:getActivityDataByRef(ACTIVITY_REF.Quest)
                        if not ((not _oldData or not _oldData:getOpenFlag()) and newUserQuest.expire <= 0) then
                            -- 本地没有新手Quest或有数据未开启时 且 服务器通知新手Quest结束，则不解析新手Quest
                            local _data = globalData.commonActivityData:parseNoCfgActivityData(newUserQuest, ACTIVITY_REF.Quest)
                            if _data then
                                _data:setNewUserQuest(true)
                                _data:setThemeName("Activity_QuestNewUser")
                                -- TODU 新手quest可以当做quest的一个主题来做 或者当做与常规quest平行的新活动来做 使用quest的数据硬包装成新手quest 对扩展很不友好
                                _data:setStage(newUserQuest.stage) -- 新手quest的特殊操作 解析quest数据的时候 不能确定是不是新手quest
                                G_GetMgr(ACTIVITY_REF.Quest):updateQuestConfig()
                            end
                        end
                        if newUserQuest.offRounds and newUserQuest.offRounds == (newUserQuest.round - 1) then
                            G_GetMgr(ACTIVITY_REF.Quest):setNewUserQuestCompleted(true)
                        end
                    end
                end
            end
        end

        

        --vip体验
        if config:HasField("vipBoost") == true then
            local vipboost = globalData.commonActivityData:parseActivityData(config.vipBoost, ACTIVITY_REF.VipBoost)
            if not vipboost then
                globalData.commonActivityData:parseNoCfgActivityData(config.vipBoost, ACTIVITY_REF.VipBoost)
            end
        end

        if config:HasField("challenge") == true then
            globalData.syncLuckyChallengeData(config.challenge)
        end

        if config:HasField("bonusHunt") then
            globalData.syncBonusHunt(config.bonusHunt)
        end

        -- if config:HasField("gameCrazy") then
        --     globalData.syncGameCraze(config.gameCrazy)
        -- end

        -- 厨房活动
        if config:HasField("dinnerLand") then
            globalData.syncDinnerLand(config.dinnerLand)
        end
        -- if config:HasField("fbCoins") == true  then
        --     globalData.userRunData:setFbBindReward(config.fbCoins)
        -- end

        -- battlePass
        -- if config:HasField("battlePass") then
        --     globalData.syncBattlePassData(config.battlePass)
        -- end

        if config:HasField("weekTreat") == true then
            globalData.syncSevenDaySign(config.weekTreat)
        end

        if config:HasField("saleTicket") then
            globalData.commonActivityData:parseActivityData(config.saleTicket, ACTIVITY_REF.SaleTicket)
        end

        --jackpot
        if config:HasField("newUserJackpotReturn") then
            local actData = globalData.commonActivityData:parseActivityData(config.newUserJackpotReturn, ACTIVITY_REF.RepartJackpot)
            if actData then
                actData:setNovice(true)
            end
        elseif config:HasField("jackpotReturn") then
            globalData.commonActivityData:parseActivityData(config.jackpotReturn, ACTIVITY_REF.RepartJackpot)
        end
        --repeatFreeSpin
        if config:HasField("newUserFreeGamesFever") then
            local actData = globalData.commonActivityData:parseActivityData(config.newUserFreeGamesFever, ACTIVITY_REF.RepeatFreeSpin)
            if actData then
                actData:setNovice(true)
            end
        elseif config:HasField("freeGamesFever") then
            globalData.commonActivityData:parseActivityData(config.freeGamesFever, ACTIVITY_REF.RepeatFreeSpin)
        end
        -- 剁手星期一
        if config:HasField("newUserCyberMonday") then
            local actData = globalData.commonActivityData:parseActivityData(config.newUserCyberMonday, ACTIVITY_REF.CyberMonday)
            if actData then
                actData:setNovice(true)
            end
        elseif config:HasField("cyberMonday") then
            globalData.commonActivityData:parseActivityData(config.cyberMonday, ACTIVITY_REF.CyberMonday)
        end
        -- 小猪挑战 累冲活动
        if config:HasField("pigChallenge") then
            globalData.commonActivityData:parseActivityData(config.pigChallenge, ACTIVITY_REF.PiggyChallenge)
        end
        -- 高倍场 小猫活动
        if config:HasField("highLimitActivity") then
            globalData.commonActivityData:parseActivityData(config.highLimitActivity, ACTIVITY_REF.DeluxeClubCat)
        end
        -- 圣诞树活动(以后这个字段就当做统一的节日挑战使用)
        if config:HasField("christmasTour") then
            globalData.commonActivityData:parseActivityData(config.christmasTour, ACTIVITY_REF.HolidayChallenge)
        end

        -- 活动任务
        if config.activityMissions ~= nil and #config.activityMissions > 0 then
            globalData.activityTaskData:parseTaskData(config.activityMissions)
        end
        -- luckyspin送配置卡活动
        if config:HasField("luckySpinNewCard") then
            globalData.commonActivityData:parseActivityData(config.luckySpinNewCard, ACTIVITY_REF.LuckySpinRandomCard)
        end
        -- 小猪送卡活动 送的卡走配置
        if config:HasField("pigCard") then
            globalData.commonActivityData:parseActivityData(config.pigCard, ACTIVITY_REF.PigRandomCard)
        end
        -- 双倍盖戳
        if config:HasField("doubleStamp") then
            globalData.commonActivityData:parseActivityData(config.doubleStamp, ACTIVITY_REF.MulLuckyStamp)
        end

        globalData.syncLeagueData(config)
        globalData.syncLeagueSummitData(config)

        if config:HasField("levelRush") then
            -- 活动到期了 有数据也可以玩
            globalData.commonActivityData:parseNoCfgActivityData(config.levelRush, ACTIVITY_REF.LevelRush)
        end

        -- 商城缺卡活动
        if config:HasField("shopCard") then
            globalData.commonActivityData:parseActivityData(config.shopCard, ACTIVITY_REF.StoreSaleRandomCard)
        end
        -- 新关挑战
        -- if config:HasField("slotChallenge") then
        --     globalData.commonActivityData:parseActivityData(config.slotChallenge, ACTIVITY_REF.SlotChallenge)
        -- end
        -- 新版餐厅
        if config:HasField("diningRoom") then
            globalData.commonActivityData:parseActivityData(config.diningRoom, ACTIVITY_REF.DiningRoom)
        end

        -- 钻石商城赠送优惠券活动
        if config:HasField("gemSaleTicket") then
            globalData.commonActivityData:parseActivityData(config.gemSaleTicket, ACTIVITY_REF.ShopGemCoupon)
        end

        -- HAT TRICK DELUXE 活动 购买充值触发的活动
        if config:HasField("hatTrick") then
            globalData.commonActivityData:parseActivityData(config.hatTrick, ACTIVITY_REF.PurchaseDraw)
        end

        -- Rippledash活动
        if config:HasField("rippleDash") then
            globalData.commonActivityData:parseActivityData(config.rippleDash, ACTIVITY_REF.RippleDash)
        end
        -- lucky stemp 送卡
        if config:HasField("luckyStampCard") then
            globalData.commonActivityData:parseActivityData(config.luckyStampCard, ACTIVITY_REF.LuckyStampCard)
        end

        -- 2周年签到
        if config:HasField("twoYearsSign") then
            globalData.commonActivityData:parseActivityData(config.twoYearsSign, ACTIVITY_REF.Years2)
        end
        
        if config:HasField("pass") == true then
             -- newPass
            local _data = globalData.commonActivityData:parseActivityData(config.pass, ACTIVITY_REF.NewPass)
            if _data then
                _data:setIsNewUserPass(false)
            end
        else
            -- 新手pass数据
            if config:HasField("newUserPass") then
                local newUserPass = config.newUserPass
                if newUserPass then
                    local _oldData = globalData.commonActivityData:getActivityDataByRef(ACTIVITY_REF.NewPass)
                    if not ((not _oldData or not _oldData:getOpenFlag()) and newUserPass.expire <= 0) then
                        local _data = globalData.commonActivityData:parseActivityData(newUserPass, ACTIVITY_REF.NewPass)
                        if _data then
                            _data:setIsNewUserPass(true)
                            _data:setThemeName("Activity_NewPass_New")
                        end
                    end
                end
            elseif config:HasField("newUserTriplePass") then -- 新手pass数据 3行pass
                local newUserPass = config.newUserTriplePass
                if newUserPass then
                    local _oldData = globalData.commonActivityData:getActivityDataByRef(ACTIVITY_REF.NewPass)
                    if not ((not _oldData or not _oldData:getOpenFlag()) and newUserPass.expire <= 0) then
                        local _data = globalData.commonActivityData:parseActivityData(newUserPass, ACTIVITY_REF.NewPass)
                        if _data then
                            _data:setIsNewUserPass(true)
                            _data:setThemeName("Activity_NewPass_New")
                        end
                    end
                end
            end
        end

        --  highLimitMerge  高倍场合成 游戏
        if config:HasField("highLimitMerge") then
            globalData.commonActivityData:parseActivityData(config.highLimitMerge, ACTIVITY_REF.DeluxeClubMergeActivity)
        end

        -- 邮箱收集
        if config:HasField("mailReward") then
            globalData.commonActivityData:parseActivityData(config.mailReward, ACTIVITY_REF.collectEmail)
        end

        -- fb200k
        if config:HasField("facebookAttentionReward") then
            globalData.commonActivityData:parseActivityData(config.facebookAttentionReward, ACTIVITY_REF.FBGift200K)
        end

        -- 乐透挑战 活动 --
        if config:HasField("lotteryChallenge") == true then
            globalData.commonActivityData:parseActivityData(config.lotteryChallenge, ACTIVITY_REF.LotteryChallenge)
        end

        -- 乐透额外送奖 活动 --
        if config:HasField("lotteryExtra") == true then
            globalData.commonActivityData:parseActivityData(config.lotteryExtra, ACTIVITY_REF.LotteryJackpot)
        end

        -- 扑克活动
        if config:HasField("poker") then
            globalData.commonActivityData:parseActivityData(config.poker, ACTIVITY_REF.Poker)
        end

        -- 合成周卡
        if config:HasField("mergeWeek") then
            globalData.commonActivityData:parseActivityData(config.mergeWeek, ACTIVITY_REF.DeluxeClubMergeWeek)
        end
        
        -- dailymissionRush (直接修改了以前的luckymission)
        if config:HasField("luckyMission") then
            globalData.commonActivityData:parseActivityData(config.luckyMission, ACTIVITY_REF.DailyMissionRush)
        end
        -- seasonMissionRush   -暂时不开这个活动 没有测试过
        -- if config:HasField("seasonMission") then
        --     globalData.commonActivityData:parseActivityData(config.seasonMission, ACTIVITY_REF.SeasonMissionRush)
        -- end

        -- NiceDice
        if config:HasField("niceDice") then
            globalData.commonActivityData:parseActivityData(config.niceDice, ACTIVITY_REF.NiceDice)
        end

        -- fb分享后获得优惠券
        if config:HasField("facebookShare") then
            globalData.commonActivityData:parseActivityData(config.facebookShare, ACTIVITY_REF.FBShare)
        end

        -- 小猪折扣送金卡
        if config:HasField("pigNormalCard") then
            globalData.commonActivityData:parseActivityData(config.pigNormalCard, ACTIVITY_REF.PigGoldCard)
        end

        -- 3日行为付费聚合活动
        if config:HasField("newUserWildChallenge") then
            local actData = globalData.commonActivityData:parseActivityData(config.newUserWildChallenge, ACTIVITY_REF.WildChallenge)
            if actData then
                actData:setNovice(true)
            end
        elseif config:HasField("wildChallenge") then
            globalData.commonActivityData:parseActivityData(config.wildChallenge, ACTIVITY_REF.WildChallenge)
        end

        -- 小猪转盘
        if config:HasField("pigDish") then
            globalData.commonActivityData:parseActivityData(config.pigDish, ACTIVITY_REF.GoodWheelPiggy)
        end
        -- 涂色
        if config:HasField("paint") then
            globalData.commonActivityData:parseActivityData(config.paint, ACTIVITY_REF.Coloring)
        end

        -- 10M每日任务送优惠券
        if config:HasField("smashHammer") then
            globalData.commonActivityData:parseActivityData(config.smashHammer, ACTIVITY_REF.CouponChallenge)
        end

        -- 1000W扭蛋机
        if config:HasField("capsuleToys") then
            globalData.commonActivityData:parseActivityData(config.capsuleToys, ACTIVITY_REF.Gashapon)
        end

        -- 比赛聚合
        if config:HasField("compete") then
            globalData.commonActivityData:parseNoCfgActivityData(config.compete, ACTIVITY_REF.BattleMatch)
        end
        -- 调查问卷
        if config:HasField("survey") then
            globalData.commonActivityData:parseActivityData(config.survey, ACTIVITY_REF.SurveyinGame)
        end

        -- 刮刮卡
        if config:HasField("scratchCard") then
            globalData.commonActivityData:parseNoCfgActivityData(config.scratchCard, ACTIVITY_REF.ScratchCards)
        end

        -- 三周年分享挑战
        if config:HasField("memoryLane") then
            globalData.commonActivityData:parseActivityData(config.memoryLane, ACTIVITY_REF.MemoryLane)
        end

        -- 限时任务 气球挑战
        if config:HasField("newUserConsumeResult") then
            local actData = globalData.commonActivityData:parseActivityData(config.newUserConsumeResult, ACTIVITY_REF.BalloonRush)
            if actData then
                actData:setNovice(true)
            end
        elseif config:HasField("consumeResult") then
            globalData.commonActivityData:parseActivityData(config.consumeResult, ACTIVITY_REF.BalloonRush)
        end

        -- spin送道具
        if config:HasField("thirdAnniversary") then
            globalData.commonActivityData:parseActivityData(config.thirdAnniversary, ACTIVITY_REF.SpinItem)
        end

        -- 单日特殊任务
        if config:HasField("oneDaySpecialMission") then
            globalData.commonActivityData:parseActivityData(config.oneDaySpecialMission, ACTIVITY_REF.Wanted)
        end

        -- 品质头像框挑战
        if config:HasField("qualityAvatarFrameChallenge") then
            globalData.commonActivityData:parseActivityData(config.qualityAvatarFrameChallenge, ACTIVITY_REF.SpecialFrame_Challenge)
        end

        -- 头像框挑战
        if config:HasField("avatarFrameChallenge") then
            globalData.commonActivityData:parseActivityData(config.avatarFrameChallenge, ACTIVITY_REF.FrameChallenge)
        end
        -- 商城指定档位送道具
        if config:HasField("purchaseGift") then
            globalData.commonActivityData:parseActivityData(config.purchaseGift, ACTIVITY_REF.PurchaseGift)
        end

        -- 聚合挑战结束促销
        if config:HasField("christmasTourDeposit") then
            G_GetMgr(G_REF.HolidayEnd):parseData(config.christmasTourDeposit)
        end

        -- 公共jackpot
        if config:HasField("jillionJackpot") then
            globalData.commonActivityData:parseActivityData(config.jillionJackpot, ACTIVITY_REF.CommonJackpot)
        end

        -- 圣诞节台历
        if config:HasField("christmasCalendar") then
            globalData.commonActivityData:parseActivityData(config.christmasCalendar, ACTIVITY_REF.ChristmasCalendar)
        end

        -- vip双倍积分
        if config:HasField("vipDoublePoints") then
            globalData.commonActivityData:parseActivityData(config.vipDoublePoints, ACTIVITY_REF.VipDoublePoint)
        end

        -- 新推币机
        if config:HasField("newCoinPusher") then
            globalData.commonActivityData:parseActivityData(config.newCoinPusher, ACTIVITY_REF.NewCoinPusher)
        end

        -- 红蓝对决
        if config:HasField("factionFight") then
            globalData.commonActivityData:parseActivityData(config.factionFight, ACTIVITY_REF.FactionFight)
        end

        -- quest送nado卡
        if config:HasField("questNado") then
            globalData.commonActivityData:parseNoCfgActivityData(config.questNado, ACTIVITY_REF.QuestNado)
        end

        -- 疯狂购物车
        if config:HasField("crazyShoppingCart") then
            globalData.commonActivityData:parseActivityData(config.crazyShoppingCart, ACTIVITY_REF.CrazyCart)
        end

        -- 黑五全服累充
        if config:HasField("blackFridayCarnival") then
            globalData.commonActivityData:parseActivityData(config.blackFridayCarnival, ACTIVITY_REF.BFDraw)
        end

        -- 年终总结
        if config:HasField("annualSummary") then
            globalData.commonActivityData:parseActivityData(config.annualSummary, ACTIVITY_REF.YearEndSummary)
        end

        -- 新关挑战
        if config:HasField("newSlotChallenge") then
            globalData.commonActivityData:parseActivityData(config.newSlotChallenge, ACTIVITY_REF.SlotTrial)
        end

        -- 新版活动任务
        if config:HasField("activityMissionV2") then
            globalData.activityTaskNewData:parseTaskData(config.activityMissionV2)
        end

        -- 全服累充活动
        if config:HasField("accumulatedRecharge") then
            globalData.commonActivityData:parseActivityData(config.accumulatedRecharge, ACTIVITY_REF.Allpay)
        end

        -- 新手期个人累充
        if config:HasField("newUserCharge") then
            local activityData = globalData.commonActivityData:getActivityDataByRef(ACTIVITY_REF.SevenDaysPurchase)
            if activityData then
                activityData:parseData(config.newUserCharge)
            end
        end

        -- 个人累充活动
        if config:HasField("superBowlRecharge") then
            globalData.commonActivityData:parseActivityData(config.superBowlRecharge, ACTIVITY_REF.AddPay)
        end

        -- 新年送礼
        if config:HasField("endYearReward") then
            globalData.commonActivityData:parseActivityData(config.endYearReward, ACTIVITY_REF.NewYearGift)
        end

         -- 接水管活动
        if config:HasField("pipeConnect") then
            globalData.commonActivityData:parseActivityData(config.pipeConnect, ACTIVITY_REF.PipeConnect)
        end

        -- 3倍盖戳
        if config:HasField("tripleStamp") then
            globalData.commonActivityData:parseActivityData(config.tripleStamp, ACTIVITY_REF.TripleStamp)
        end

        -- 自选任务
        if config:HasField("optionalTask") then
            globalData.commonActivityData:parseActivityData(config.optionalTask, ACTIVITY_REF.PickTask)
        end

        -- 黑曜卡Jackpot活动
        if config:HasField("shortCardJackpot") then
            globalData.commonActivityData:parseActivityData(config.shortCardJackpot, ACTIVITY_REF.CardObsidianJackpot)
        end

        -- 宝石返还
        if config:HasField("mergeBack") then
            globalData.commonActivityData:parseActivityData(config.mergeBack, ACTIVITY_REF.CrystalBack)
        end

        -- vip点数池
        if config:HasField("vipPointsPool") then
            globalData.commonActivityData:parseActivityData(config.vipPointsPool, ACTIVITY_REF.VipPointsBoost)
        end
        
        -- 黑曜卡幸运轮盘
        if config:HasField("shortCardDraw") then
            globalData.commonActivityData:parseActivityData(config.shortCardDraw, ACTIVITY_REF.ObsidianWheel)
        end

        -- 限时促销
        if config:HasField("newUserLimitedGift") then
            local actData = globalData.commonActivityData:parseActivityData(config.newUserLimitedGift, ACTIVITY_REF.LimitedOffer)
            if actData then
                actData:setNovice(true)
            end
        elseif config:HasField("limitedGift") then
            globalData.commonActivityData:parseActivityData(config.limitedGift, ACTIVITY_REF.LimitedOffer)
        end

        -- bigwin活动
        if config:HasField("bigWinChallenge") then
            globalData.commonActivityData:parseActivityData(config.bigWinChallenge, ACTIVITY_REF.BigWin_Challenge)
        end

        -- wildDraw
        if config:HasField("wildDraw") then
            globalData.commonActivityData:parseActivityData(config.wildDraw, ACTIVITY_REF.WildDraw)
        end

        -- bingo连线
        if config:HasField("bingoLineSale") then
            globalData.commonActivityData:parseActivityData(config.bingoLineSale, ACTIVITY_REF.LineSale)
        end

        -- 集卡赛季末聚合
        if config:HasField("chaseForChip") then
            globalData.commonActivityData:parseActivityData(config.chaseForChip, ACTIVITY_REF.ChaseForChips)
        end

        -- 第二货币抽奖
        if config:HasField("gemMayWin") then
            globalData.commonActivityData:parseActivityData(config.gemMayWin, ACTIVITY_REF.GemMayWin)
        end

        -- zombie
        if config:HasField("zombieOnslaught") then
            globalData.commonActivityData:parseActivityData(config.zombieOnslaught, ACTIVITY_REF.Zombie)
        end
        
        -- 集卡赛季末个人累充PLUS
        if config:HasField("topUpBonus") then
            globalData.commonActivityData:parseActivityData(config.topUpBonus, ACTIVITY_REF.TopUpBonus)
        end

        -- 付费目标
        if config:HasField("getMorePayLess") then
            globalData.commonActivityData:parseActivityData(config.getMorePayLess, ACTIVITY_REF.GetMorePayLess)
        end
        
        -- 行尸走肉预热活动
        if config:HasField("zombiePrebook") then
            globalData.commonActivityData:parseActivityData(config.zombiePrebook, ACTIVITY_REF.ZombieWarmUp)
        end

        -- 合成转盘
        if config:HasField("magicGarden") then
            globalData.commonActivityData:parseActivityData(config.magicGarden, ACTIVITY_REF.MagicGarden)
        end

        -- Minz
        if config:HasField("minz") then
            local minzData = globalData.commonActivityData:parseActivityData(config.minz, ACTIVITY_REF.Minz)
            if not minzData then
                globalData.commonActivityData:parseNoCfgActivityData(config.minz, ACTIVITY_REF.Minz)
            end
        end

        -- 充值抽奖池
        if config:HasField("prizeGame") then
            globalData.commonActivityData:parseActivityData(config.prizeGame, ACTIVITY_REF.PrizeGame)
        end

        -- 第二货币消耗挑战
        if config:HasField("gemChallenge") then
            globalData.commonActivityData:parseActivityData(config.gemChallenge, ACTIVITY_REF.GemChallenge)
        end

        -- 钻石挑战通关挑战
        if config:HasField("diamondMania") then
            globalData.commonActivityData:parseActivityData(config.diamondMania, ACTIVITY_REF.DiamondMania)
        end

        -- 返回持金极大值促销
        if config:HasField("timeBack") then
            globalData.commonActivityData:parseActivityData(config.timeBack, ACTIVITY_REF.TimeBack)
        end

        -- 生日信息及促销
        if config:HasField("birthday") then
            globalData.commonActivityData:parseNoCfgActivityData(config.birthday, ACTIVITY_REF.Birthday)
        end

        -- 组队打BOSS
        if config:HasField("dragonChallenge") then
            globalData.commonActivityData:parseActivityData(config.dragonChallenge, ACTIVITY_REF.DragonChallenge)
        end

        -- 付费排行榜
        if config:HasField("payRank") then
            globalData.commonActivityData:parseNoCfgActivityData(config.payRank, ACTIVITY_REF.PayRank)
        end

        -- flamingo Jackpot
        if config:HasField("flamingoJackpot") then
            globalData.commonActivityData:parseActivityData(config.flamingoJackpot, ACTIVITY_REF.FlamingoJackpot)
        end

        -- 商城停留送优惠券
        if config:HasField("storeStayCoupon") then
            globalData.commonActivityData:parseActivityData(config.storeStayCoupon, ACTIVITY_REF.StayCoupon)
        end

        -- 高倍场体验卡促销
        if config:HasField("highClubSale") then
            globalData.commonActivityData:parseNoCfgActivityData(config.highClubSale, ACTIVITY_REF.HighClubSale)
        end

        -- 三指针转盘促销
        if config:HasField("diyWheel") then
            globalData.commonActivityData:parseNoCfgActivityData(config.diyWheel, ACTIVITY_REF.DIYWheel)
        end
        
        -- 新手三日任务
        if config:HasField("noviceTrail") then
            local actData = globalData.commonActivityData:parseActivityData(config.noviceTrail, ACTIVITY_REF.NoviceTrail)
            if actData then
                actData:setNovice(true)
            end
        end

        -- 集卡小猪
        if config:HasField("pigChip") then
            globalData.commonActivityData:parseActivityData(config.pigChip, ACTIVITY_REF.ChipPiggy)
        end

        -- 第二货币小猪银行活动
        if config:HasField("pigGems") then
            globalData.commonActivityData:parseActivityData(config.pigGems, ACTIVITY_REF.GemPiggy)
        end

        -- 小猪三合一促销
        if config:HasField("pigTrioSale") then
            globalData.commonActivityData:parseActivityData(config.pigTrioSale, ACTIVITY_REF.TrioPiggy)
        end

        -- 赛季末返新卡
        if config:HasField("grandFinale") then
            globalData.commonActivityData:parseNoCfgActivityData(config.grandFinale, ACTIVITY_REF.GrandFinale)
        end

        -- 4周年抽奖+分奖
        if config:HasField("fourBirthdayDraw") then
            globalData.commonActivityData:parseNoCfgActivityData(config.fourBirthdayDraw, ACTIVITY_REF.dayDraw4B)
        end

        -- 限时膨胀
        if config:HasField("timeLimitExpansion") then
            globalData.commonActivityData:parseActivityData(config.timeLimitExpansion, ACTIVITY_REF.TimeLimitExpansion)
        end

        -- 限时集卡多倍奖励
        if config:HasField("albumMoreAward") then
            globalData.commonActivityData:parseNoCfgActivityData(config.albumMoreAward, ACTIVITY_REF.AlbumMoreAward)
        end

        -- 三联优惠券
        if config:HasField("couponRewards") then
            if isLogin then
                G_GetMgr(ACTIVITY_REF.CouponRewards):setShowStage(config.couponRewards.currentStage)
            end
            globalData.commonActivityData:parseNoCfgActivityData(config.couponRewards, ACTIVITY_REF.CouponRewards)
        end

        -- LEVEL UP PASS
        if config:HasField("levelUpPass") then
            globalData.commonActivityData:parseNoCfgActivityData(config.levelUpPass, ACTIVITY_REF.LevelUpPass)
        end

        -- diyFeature
        if config:HasField("diyFeature") then
            globalData.commonActivityData:parseNoCfgActivityData(config.diyFeature, ACTIVITY_REF.DiyFeature)
        end

        -- diyFeature 结束促销
        if config:HasField("diyFeatureOverSale") then
            globalData.commonActivityData:parseActivityData(config.diyFeatureOverSale, ACTIVITY_REF.DiyFeatureOverSale)
        end

        -- diyFeature 普通促销
        if config:HasField("diyFeatureSale") then
            globalData.commonActivityData:parseActivityData(config.diyFeatureSale, ACTIVITY_REF.DiyFeatureNormalSale)
        end        

        -- mythicGame促销
        if config:HasField("mythicGameSale") then
            globalData.commonActivityData:parseNoCfgActivityData(config.mythicGameSale, ACTIVITY_REF.MythicGameSale)
        end

        if config:HasField("clanDoublePoints") then
            globalData.commonActivityData:parseNoCfgActivityData(config.clanDoublePoints, ACTIVITY_REF.ClanDoublePoints)
        end

        -- 单人限时比赛
        if config:HasField("luckyRace") then
            globalData.commonActivityData:parseActivityData(config.luckyRace, ACTIVITY_REF.LuckyRace)
        end
        
        -- 大R高性价比礼包促销
        if config:HasField("superValue") then
            globalData.commonActivityData:parseNoCfgActivityData(config.superValue, ACTIVITY_REF.SuperValue)
        end

        -- 新版小猪挑战
        if config:HasField("piggyGoodies") then
            globalData.commonActivityData:parseActivityData(config.piggyGoodies, ACTIVITY_REF.PiggyGoodies)
        end

        if config:HasField("diyFeatureMission") then
            globalData.commonActivityData:parseActivityData(config.diyFeatureMission, ACTIVITY_REF.DIYFeatureMission)
        end

        if config:HasField("outsideGave") then
            globalData.commonActivityData:parseActivityData(config.outsideGave, ACTIVITY_REF.OutsideCave)
        end
        
        --  集装箱大亨
        if config:HasField("blindBox") then
            globalData.commonActivityData:parseNoCfgActivityData(config.blindBox, ACTIVITY_REF.BlindBox)
        end
        
        -- 挖矿挑战
        if config:HasField("jewelMania") == true then
            globalData.commonActivityData:parseActivityData(config.jewelMania, ACTIVITY_REF.JewelMania)
        end    
        
        -- 第二货币商城折扣送道具
        if config:HasField("storeGemGift") == true then
            globalData.commonActivityData:parseActivityData(config.storeGemGift, ACTIVITY_REF.GemCoupon)
        end   

        -- 膨胀消耗1v1比赛
        if config:HasField("flameClash") then
            globalData.commonActivityData:parseActivityData(config.flameClash, ACTIVITY_REF.FrostFlameClash)
        end

        -- 新版钻石挑战
        if config:HasField("luckyChallengeV2") == true then
            globalData.commonActivityData:parseActivityData(config.luckyChallengeV2, ACTIVITY_REF.NewDiamondChallenge)
        end 

        --新版钻石挑战之限时活动
        if config:HasField("luckyChallengeV2TimeLimit") == true then
            globalData.commonActivityData:parseActivityData(config.luckyChallengeV2TimeLimit, ACTIVITY_REF.NewDCRush)
        end
            -- SuperSpin送道具
        if config:HasField("superSpinSendItem") then
            globalData.commonActivityData:parseActivityData(config.superSpinSendItem, ACTIVITY_REF.LuckySpinSpecial)
        end

        -- 大活动PASS
        if config:HasField("functionSalePass") then
            globalData.commonActivityData:parseNoCfgActivityData(config.functionSalePass, ACTIVITY_REF.FunctionSalePass)
        end
        
        -- 第二货币两张优惠券
        if config:HasField("twoGemCoupons") then
            globalData.commonActivityData:parseActivityData(config.twoGemCoupons, ACTIVITY_REF.TwoGemCoupons)
        end

        -- 圣诞节新聚合签到
        if config:HasField("holidayAdventCalendar") then
            globalData.commonActivityData:parseActivityData(config.holidayAdventCalendar, ACTIVITY_REF.AdventCalendar)
        end

        -- 圣诞节新聚合
        if config:HasField("holidayNewChallenge") then
            globalData.commonActivityData:parseActivityData(config.holidayNewChallenge, ACTIVITY_REF.HolidayNewChallenge)
        end

        -- 圣诞节新聚合商店
        if config:HasField("holidayStore") then
            globalData.commonActivityData:parseActivityData(config.holidayStore, ACTIVITY_REF.HolidayStore)
        end

        -- 圣诞节新聚合Pass
        if config:HasField("holidayPass") then
            globalData.commonActivityData:parseActivityData(config.holidayPass, ACTIVITY_REF.HolidayPass)
        end

        -- 圣诞节新聚合小游戏
        if config:HasField("holidaySideGame") then
            globalData.commonActivityData:parseActivityData(config.holidaySideGame, ACTIVITY_REF.HolidaySideGame)
        end

        -- 指定用户分组送指定档位可用优惠券
        if config:HasField("couponGift") then
            globalData.commonActivityData:parseActivityData(config.couponGift, ACTIVITY_REF.VCoupon)
        end
        
        -- 抽奖转盘
        if config:HasField("crazyWheel") then
            globalData.commonActivityData:parseActivityData(config.crazyWheel, ACTIVITY_REF.CrazyWheel)
        end
        
        -- 寻宝之旅
        if config:HasField("treasureHunt") then
            local actData = globalData.commonActivityData:parseActivityData(config.treasureHunt, ACTIVITY_REF.TreasureHunt)
            if actData then
                actData:setNovice(true)
            end
        end

        -- SuperSpin高级版送缺卡
        if config:HasField("luckySpinV2NewCard") then
            globalData.commonActivityData:parseActivityData(config.luckySpinV2NewCard, ACTIVITY_REF.FireLuckySpinRandomCard)
        end 
        -- 收集邮件抽奖
        if config:HasField("mailLottery") then
            globalData.commonActivityData:parseActivityData(config.mailLottery, ACTIVITY_REF.MailLottery)
        end

        -- 大赢家宝箱
        if config:HasField("megaWin") then
            globalData.commonActivityData:parseActivityData(config.megaWin, ACTIVITY_REF.MegaWinParty)
        end

        -- 打开推送通知送奖
        if config:HasField("messagePush") then
            globalData.commonActivityData:parseActivityData(config.messagePush, ACTIVITY_REF.Notification)
        end
        -- 埃及推币机
        if config:HasField("coinPusherV3") then
            globalData.commonActivityData:parseActivityData(config.coinPusherV3, ACTIVITY_REF.EgyptCoinPusher)
        end

        -- 完成任务装饰圣诞树
        if config:HasField("missionsToDiy") then
            globalData.commonActivityData:parseActivityData(config.missionsToDiy, ACTIVITY_REF.MissionsToDIY)
        end 

        -- 圣诞充值分奖
        if config:HasField("holidayNewChallengeCraze") then
            globalData.commonActivityData:parseActivityData(config.holidayNewChallengeCraze, ACTIVITY_REF.XmasCraze2023)
        end

        -- 圣诞累充分奖
        if config:HasField("xmasSplit") then
            globalData.commonActivityData:parseActivityData(config.xmasSplit, ACTIVITY_REF.XmasSplit2023)
        end

        -- 商城充值饭代币
        if config:HasField("paySendBuck") then
            globalData.commonActivityData:parseActivityData(config.paySendBuck, ACTIVITY_REF.BucksBack)
        end 
        
        -- 收集手机号
        if config:HasField("collectPhone") then
            globalData.commonActivityData:parseActivityData(config.collectPhone, ACTIVITY_REF.CollectPhone)
        end

        -- 宠物-7日任务
        if config:HasField("petMission") then
            globalData.commonActivityData:parseActivityData(config.petMission, ACTIVITY_REF.PetMission)
        end

        util_nextFrameFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.UPDATE_SLIDEANDHALL_FINISH)
            end
        )
    end
end

-- 解析关卡比赛数据(普通 资格赛)
function GlobalData.syncLeagueData(data)
    if not data or not data:HasField("arena") then
        return
    end

    local actRef = ACTIVITY_REF.League
    if data.arena:HasField("type") and data.arena.type == "LEAGUES_QUALIFIED" then
        -- 资格赛
        actRef = ACTIVITY_REF.LeagueQualified
    end
    local leagueData = globalData.commonActivityData:parseActivityData(data.arena, actRef)
    if not leagueData then
        globalData.commonActivityData:parseNoCfgActivityData(data.arena, actRef)
    end
end
-- 解析关卡比赛数据(巅峰赛)
function GlobalData.syncLeagueSummitData(data)
    if not data or not data:HasField("peakArena") then
        return
    end

    local leagueData = globalData.commonActivityData:parseActivityData(data.peakArena, ACTIVITY_REF.LeagueSummit)
    if not leagueData then
        globalData.commonActivityData:parseNoCfgActivityData(data.peakArena, ACTIVITY_REF.LeagueSummit)
    end
end

function GlobalData.syncAdConfig(adConfig)
    --广告强制刷新不需要检测是否存在
    globalData.adsRunData:parseAdsData(adConfig)
end

function GlobalData.syncAdsExtraConfig(data)
    if data ~= nil then
        globalData.adsRunData:parseAdsExtraData(data)
    end
end

function GlobalData.syncPurchaseCardConfig(purchaseCardConfig)
    if purchaseCardConfig ~= nil and #purchaseCardConfig > 0 then
        globalData.purchaseCards = {}
        for i = 1, #purchaseCardConfig do
            local data = purchaseCardConfig[i]
            local config = PurchaseCardConfig:create()
            config:parseData(data)
            globalData.purchaseCards[#globalData.purchaseCards + 1] = config
        end
    end
end

function GlobalData.syncPurchaseActCardConfig(purchaseActCardConfig)
    if purchaseActCardConfig ~= nil and #purchaseActCardConfig > 0 then
        globalData.purchaseActCards = {}
        for i = 1, #purchaseActCardConfig do
            local data = purchaseActCardConfig[i]
            local config = PurchaseCardConfig:create()
            config:parseData(data)
            globalData.purchaseActCards[#globalData.purchaseActCards + 1] = config
        end
    end
end

function GlobalData.syncPurchaseBuffCardConfig(purchaseBuffCards)
    if purchaseBuffCards ~= nil and #purchaseBuffCards > 0 then
        globalData.purchaseBuffCards = {}
        for i = 1, #purchaseBuffCards do
            local data = purchaseBuffCards[i]
            local config = PurchaseCardConfig:create()
            config:parseData(data)
            globalData.purchaseBuffCards[#globalData.purchaseBuffCards + 1] = config
        end
    end
end

function GlobalData.syncDeluexeClubData(highLimit)
    if highLimit ~= nil then
        globalData.deluexeClubData:parseData(highLimit)
    end
end

-- function GlobalData.parseBingoRankConfig(data)
--     if data ~= nil then
--         local bingoData = G_GetMgr(ACTIVITY_REF.Bingo):getRunningData()
--         if bingoData then
--             bingoData.bingoRankConfig = BaseActivityRankCfg:create()
--             bingoData.bingoRankConfig:parseData(data)
--         end
--     end
-- end

--缓存 LevelDashData 数据
-- function GlobalData.syncLevelDashData(data)
--     if data ~= nil then
--         globalData.levelDashData:parseData(data)
--     end
-- end

function GlobalData.syncLuckyStampData(_luckyStamp, _isLogon, _isPay)
    G_GetMgr(G_REF.LuckyStamp):parseData(_luckyStamp, _isLogon, _isPay)
end

function GlobalData.rotationFlyCoinEndPos(flag)
    if globalData.flyCoinsEndPos ~= nil and globalData.slotRunData.isPortrait == true then
        if flag and globalData.flyCoinsRotationEndPos == nil then
            globalData.flyCoinsRotationEndPos = globalData.flyCoinsEndPos
            local cloneEndPos = clone(globalData.flyCoinsEndPos)
            globalData.flyCoinsEndPos = cloneEndPos
            cloneEndPos.x, cloneEndPos.y = display.width - (display.height - cloneEndPos.y), display.height - cloneEndPos.x
        elseif globalData.flyCoinsRotationEndPos ~= nil then
            globalData.flyCoinsEndPos = clone(globalData.flyCoinsRotationEndPos)
            globalData.flyCoinsRotationEndPos = nil
        end
    end
end
--将轮盘跟数据绑定
function GlobalData.bindWheelParam(key, wheel)
    if not key or not wheel then
        return
    end
    if not globalData.wheelParam then
        globalData.wheelParam = {}
    end
    local has = false
    for i = 1, #globalData.wheelParam do
        if globalData.wheelParam[i].key == key then
            has = true
            globalData.wheelParam[i] = {key = key, data = wheel}
        end
    end
    if not has then
        globalData.wheelParam[#globalData.wheelParam + 1] = {key = key, data = wheel}
    end
end
--轮盘和数据解除绑定
function GlobalData.removeWheelParam(key)
    if not key or not globalData.wheelParam then
        return
    end
    for i = 1, #globalData.wheelParam do
        if globalData.wheelParam[i].key == key then
            table.remove(globalData.wheelParam, i)
            break
        end
    end
end

--同步LuckyChallenge数据
function GlobalData.syncLuckyChallengeData(data)
    -- if data ~= nil then
    --     if globalData.luckyChallengeData == nil then
    --         globalData.luckyChallengeData = LuckyChallengeData:create()
    --     end
    --     globalData.luckyChallengeData:parseData(data)
    -- end
    globalData.commonActivityData:parseNoCfgActivityData(data, ACTIVITY_REF.LuckyChallenge)
end

--同步LuckyChallenge数据
function GlobalData.syncLuckyChallengeTaskData(data)
    -- if data ~= nil then
    --     if globalData.luckyChallengeData == nil then
    --         globalData.luckyChallengeData = LuckyChallengeData:create()
    --     end
    --     globalData.luckyChallengeData:parseSingleTaskData(data)
    -- end
    local luckyChallenge = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallenge then
        luckyChallenge:parseSingleTaskData(data)
    end
end

function GlobalData.parseLuckyChallengeRankConfig(data)
    local luckyChallenge = G_GetMgr(ACTIVITY_REF.LuckyChallenge):getRunningData()
    if luckyChallenge then
        luckyChallenge:parseRankData(data)
    end
end

function GlobalData.parseItemsConfig(data)
    if data ~= nil then
        if globalData.itemsConfig then
            globalData.itemsConfig:parseData(data)
        end
    end
end

function GlobalData.parseDropsConfig(data)
    if data ~= nil then
        if globalData.itemsConfig then
            globalData.itemsConfig:parseDropsData(data)
        end
    end
end

function GlobalData.parseDailySignConfig(data)
    if data ~= nil then
        if globalData.dailySignData then
            globalData.dailySignData:parseData(data)
        end
    end
end

function GlobalData.parseDailyBonusNoviceConfig(data)
    if data ~= nil then
        if globalData.dailyBonusNoviceData then
            globalData.dailyBonusNoviceData:parseData(data)
        end
    end
end

function GlobalData.parseFBRewardConfig(data)
    if data ~= nil then
        if globalData.FBRewardData then
            globalData.FBRewardData:parseData(data)
        end
    end
end

-- 解析乐透数据
function GlobalData.parseLotteryConfig(data)
    if data ~= nil then
        if globalData.lotteryData then
            globalData.lotteryData:parseData(data)
        end
    end
end

function GlobalData.parseFBBirthdayReward(data)
    if data ~= nil then
        if globalData.FBBirthdayRewardData then
            globalData.FBBirthdayRewardData:parseData(data)
        end
    end
end

-- 解析头像框数据
function GlobalData.parseAvatarFrameData(data)
    if data ~= nil then
        if globalData.avatarFrameData then
            globalData.avatarFrameData:parseData(data)
        end
    end
end
-- 解析乐透数据
function GlobalData.parseAdChallengeData(data)
    if data ~= nil then
        if globalData.AdChallengeData then
            globalData.AdChallengeData:parseData(data)
        end
    end
end

function GlobalData.parseFlowerConfig(data)
    if data ~= nil then
        if globalData.flowerData then
            globalData.flowerData:parseData(data)
        end
    end
end
-- 解析新手7日目标数据
function GlobalData:parseNewUser7DayData(data)
    if data ~= nil then
        if globalData.newUser7DayData then
            globalData.newUser7DayData:parseData(data)
        end
    end
end

-- 邮件大R玩家跳转数据
function GlobalData.parseInboxFbJumpData(data)
    if globalData.InboxFbJumpData and data then
        globalData.InboxFbJumpData = {}
        globalData.InboxFbJumpData.fbJumpName = data.messageName --跳转名字
        globalData.InboxFbJumpData.fbJumpUrl = data.fbAddress --fb跳转地址
    end
end

-- 登录数据里 服务器发送的 是否是新手期集卡
function GlobalData:isCardNovice()
    if globalData.cardAlbumId and CardNoviceCfg and tonumber(globalData.cardAlbumId) == tonumber(CardNoviceCfg.ALBUMID) then
        return true
    end

    return false
end

return GlobalData
