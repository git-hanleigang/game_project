-- 定义全局变量 ios fix 222
GD.json = require "json"
GD.cjson = require "cjson"

GD.isMac = function()
    return (device.platform == "mac")
end
GD.isIOS = function()
    return (device.platform == "ios")
end
GD.isAndroid = function()
    return (device.platform == "android")
end

GD.BaseSingleton = require("base.BaseSingleton")
GD.scheduler = require("utils.scheduler")
-- 引入各种工具类
require "utils.LuaUtils"
require "utils.DateUtil"
require "utils.StringUtil"
require "utils.NumberUtil"
require "utils.TableUtil"
require "utils.CocosUtil"
require "utils.TouchNode"
require "utils.MachineUtil"
require "utils.CheckErrorUtil"
require "utils.LogUtil"

GD.CC_DOWNLOAD_TYPE = 2

if DEBUG == 2 then
    --测试关卡id,千万不要上传!!!!!!!!!!!!!!!!!!!
    CC_IS_TEST_LEVEL_ID = nil
end

--获取App版本号
local function getAppVersionCode()
    local platform = device.platform
    if platform == "android" then
        local sig = "(F)Ljava/lang/String;"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/XcyyUtil"
        local ok, ret = luaj.callStaticMethod(className, "getPlatformInfo", {7}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    elseif platform == "ios" then
        local ok, ret = luaCallOCStaticMethod("AppController", "getPlatformInfo", {type = 7})
        if not ok then
            return ""
        else
            return ret
        end
    else
        return "1.0.0"
    end
end

GD.gLobalRemoveDir = ""


--检测删除本地热更文件
-- local function checkRemoveCacheFile()
--     if (util_isSupportVersion("1.7.7", "ios")) or (util_isSupportVersion("1.7.1", "android")) or device.platform == "mac" then
--         return
--     end
--     local preAppVersionCode = "0"
--     if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
--         preAppVersionCode = gLobalDataManager:getVersion("appVer")
--     else
--         preAppVersionCode = gLobalDataManager:getStringByField("appVersionCode")
--     end
--     local curAppVersionCode = getAppVersionCode()
--     release_print("checkRemoveCacheFile 1111111111 = " .. tostring(preAppVersionCode) .. "," .. tostring(curAppVersionCode))

--     if preAppVersionCode ~= curAppVersionCode then
--         local writePath = device.writablePath
--         local srcWritePath = writePath .. "src/"
--         local resWritePath = writePath .. "res/"

--         local isRemoved = false
--         if cc.FileUtils:getInstance():isDirectoryExist(srcWritePath) then
--             cc.FileUtils:getInstance():removeDirectory(srcWritePath)
--             release_print("checkRemoveCacheFile 22222222")
--             isRemoved = true
--         end

--         if cc.FileUtils:getInstance():isDirectoryExist(resWritePath) then
--             cc.FileUtils:getInstance():removeDirectory(resWritePath)
--             release_print("checkRemoveCacheFile 33333333")
--             isRemoved = true
--         end

--         cc.FileUtils:getInstance():purgeCachedEntries()

--         if isRemoved then
--             gLobalRemoveDir = gLobalRemoveDir .. ("checkRemoveCacheFile|" .. util_getUpdateVersionCode() .. "|")
--             util_sendToSplunkMsg("removeHotDir", "RemoveCacheDir:preAppVer=" .. preAppVersionCode .. ";curAppVer=" .. curAppVersionCode)
--         end

--         local clearCode = (preAppVersionCode ~= nil and preAppVersionCode ~= "") and tostring(preAppVersionCode) or "nil"
--         clearCode = clearCode .. "|" .. tostring(curAppVersionCode)
--         gLobalDataManager:setStringByField("appDelegate_isClearRes_flag", clearCode, true)

--         if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
--             gLobalDataManager:setVersion("appVer", tostring(curAppVersionCode))
--         else
--             gLobalDataManager:setStringByField("appVersionCode", tostring(curAppVersionCode), true)
--         end
--         gLobalDataManager:delValueByField("ReStartGameStatus")

--         local packageUpdateVersion = xcyy.GameBridgeLua:getPackageUpdateVersion()
--         util_saveUpdateVersionCode(packageUpdateVersion)
--         release_print("checkRemoveCacheFile 44444444 = " .. tostring(curAppVersionCode) .. "," .. tostring(packageUpdateVersion))
--     else
--         local isClear_flag = gLobalDataManager:getStringByField("appDelegate_isClearRes_flag", "0")
--         if isClear_flag ~= "0" then
--             -- 说明C++层有清理
--             gLobalRemoveDir = gLobalRemoveDir .. "C ClearFlag:" .. isClear_flag .. "|"
--             gLobalRemoveDir = gLobalRemoveDir .. ("checkRemoveCacheFile|" .. util_getUpdateVersionCode() .. "|")
--             local _msg = "RemoveCacheDir:preAppVer=" .. preAppVersionCode .. ";curAppVer=" .. curAppVersionCode .. "|" .. gLobalRemoveDir
--             util_sendToSplunkMsg("removeHotDir", _msg)
--         -- release_print(_msg)
--         end
--         gLobalDataManager:setStringByField("appDelegate_isClearRes_flag", "0", true)
--     end
-- end
-- checkRemoveCacheFile()

require("network.NetworkConfig")
require("SoundEnumConfig")
GD.PRODUCTID = "SlotNewCashLink"
GD.DESIGN_SIZE = {width = 1370, height = 768}
if CC_IS_PORTRAIT_MODE then
    GD.DESIGN_SIZE = {width = 768, height = 1370}
end

GD.costRecord = {}
GD.addCostRecord = function(key, secs)
    if not costRecord[key] then
        costRecord[key] = {}
    end
    local oldTotal = costRecord[key]["cost"] or 0
    costRecord[key]["cost"] = oldTotal + (secs or 0)
    local oldCount = costRecord[key]["count"] or 0
    costRecord[key]["count"] = oldCount + 1
end

GD.printCostRecord = function()
    for key, value in pairs(costRecord) do
        printInfo("loading --- " .. key .. " costSecs " .. " = " .. string.format("%0.4f", value["cost"]) --[[.. "; count = " .. value["count"]-]])
    end
end

--定义活动类型
GD.ACTIVITY_TYPE = {
    NORMAL = 1, --普通活动
    COMMON = 1, --兼容新手期
    THEME = 2, --主题促销活动
    CHOICE = 3, --多档促销活动
    SEVENDAY = 4, --七日促销活动
    KEEPRECHARGE = 5, --连续充值
    BINGO = 6, --BINGO
    RICHMAIN = 7, --richMain
    DINNERLAND = 8, --餐厅
    BLAST = 9, --blast
    WORD = 10, --字独
    COINPUSHER = 11, --推币机
    BATTLE_PASS = 12, --BattlePass
    BETWEENTWO = 13, --betweentwo
    LEAGUE = 14, -- 比赛促销
    DININGROOM = 15, -- 新版餐厅
    REDECOR = 16, -- 装修活动
    MEMORY_FLYING = 17, -- 6个箱子促销
    POKER = 18, -- 扑克
    DIVINATION = 38, -- 占卜促销
    EASTER_EGGSALE = 40, --2022复活节无线砸蛋促销
    NEWDOUBLE = 42, -- 新版二选一
    NEWCOINPUSHER = 44, --新版推币机
    WORLDTRIP = 45, -- 新版大富翁促销
    PIPECONNECT = 46, -- 接水管促销
    DIYCOMBODEAL = 47, -- 自选促销礼包
    KEEPRECHARGE4 = 48, -- 4格连续充值
    EGYPTCOINPUSHER = 49, --埃及推币机
    OUTSIDECAVE = 23, -- 新版大富翁OutsideCave 促销
}

--服务器下发的活动类型(不全，如果需要同一种活动下载多个资源的咨询策划)
GD.SERVER_ACTIVITY_TYPE = {
    FINDITEM = 1,
    BINGO = 2,
    DEFENDER = 3,
    QUEST = 4,
    QUEST_SHOWTOP = 42,
    BINGGO_SHOWTOP = 43,
    DINNER_SHOWTOP = 44,
    BINGOWILDBALL = 54
}

-- 活动弹板
GD.ACT_LAYER_POPUP_TYPE = {
    AUTO = 1, -- 登录大厅弹板队列自动弹出来
    HALL = 2, -- 点击大厅 展示图 广告图
    SLIDE = 3, -- 点击大厅 轮播图
    ENTRANCE = 4 -- 活动总入口创建出来的
}

-- 活动引用名定义
GD.ACTIVITY_REF = {
    --leveldashplus
    LevelDashPlus = "Activity_LevelDashPlus",
    -- 促销ran
    CommonSale = "Promotion_Common",
    NoCoinSale = "Promotion_NoCoinSale",
    BrokenSale = "Promotion_BrokenSale",
    MultiSale = "Promotion_MultiSpan",
    KRechargeSale = "Activity_KeepRecharge",
    AttemptSale = "Promotion_AttemptSale",
    -- bingo
    Bingo = "Activity_Bingo",
    BingoSale = "Promotion_Bingo",
    BingoShowTop = "Activity_BingoShowTop",
    BingoWildBall = "Activity_BingoWildBall",
    BingoTask = "Activity_BingoTask", -- bingo活动任务
    -- Quest
    Quest = "Activity_Quest",
    QuestShowTop = "Activity_QuestShowTop",
    QuestSale = "Promotion_Quest",
    QuestRush = "Activity_QuestRush", -- quest挑战活动
    -- piggy
    PigCoins = "Activity_PigSale",
    PigBooster = "Activity_PigSaleBooster",
    PigClanSale = "Activity_PigSaleTeam", -- 公会小猪折扣
    --膨胀预热
    CoinExpandStart = "Activity_CoinExpand_Start",
    CoinExpandLoading = "Activity_CoinExpand_Loading",
    -- cashback
    CashBack = "Activity_CashBack",
    CashBackNovice = "Activity_CashBackNovice",
    LevelBoom = "Activity_LevelBoom",
    LevelDash = "Promotion_LevelDash",
    RepartWin = "Promotion_RepartWin",
    EchoWin = "Activity_EchoWin",
    VipBoost = "Activity_VipBoost",
    --lvd
    Activity_SeasonMission_Dash = "Activity_SeasonMission_Dash",
    --飞镖小游戏
    DartsGame = "Activity_DartsGame",
    Activity_DartsGame_Loading = "Activity_DartsGame_Loading",
    -- Card
    PreCard = "Activity_PreCard",
    --Activity_FBVideo
    ActivityFBVideo = "Activity_FBVideo",
    -- Find
    FindItem = "Activity_FindItem",
    -- Find
    CoinExpandCashBonus = "Activity_CoinExpand_CashBonus",
    --每日任务额外奖励
    ActivityMissionRushNew = "Activity_MissionRush",
    -- LuckySpin
    LuckySpinGoldenCard = "Activity_LuckySpinGoldenCard",
    LuckyChallenge = "Activity_LuckyChallenge",
    LuckyChallengeSale = "Promotion_LuckyChallenge",
    LuckyFish = "Activity_LuckyFish",
    BonusHunt = "Activity_BonusHunt",
    BonusHuntCoin = "Activity_BonusHuntCoin",
    DoubleCard = "Activity_DoubleCard",
    CardStar = "Activity_CardStar",
    CardsOneKeyRecover = "Activity_CardsOneKeyRecover",
    CardOpen = "Activity_CardOpen",
    -- 主题促销
    Theme = "Promotion_Theme",
    Activity_QuestNewLevel = "Activity_QuestNewLevel",
    LuckyChipsDraw = "Activity_LuckyChipsDraw",
    -- battlepass
    BattlePass = "Activity_BattlePass",
    BattlePassSale = "Promotion_BattlePass",
    -- 主题活动
    RichMan = "Activity_RichMan",
    RichManSale = "Promotion_RichMan",
    RichManRank = "Activity_RichManShowTop", --大富翁排行榜
    RichManTask = "Activity_RichManTask",
    -- 主题活动
    WorldTrip = "Activity_WorldTrip",
    WorldTripSale = "Promotion_WorldTrip",
    WorldTripRank = "Activity_WorldTripShowTop", --新版大富翁排行榜
    WorldTripTask = "Activity_WorldTripTask",
    --膨胀宣传-🐷
    CoinExpandPig = "Activity_CoinExpand_Pig",
    DailySprint_Coupon = "Activity_DailySprint_Coupon",
    --大富翁任务
    Blast = "Activity_Blast",
    BlastSale = "Promotion_Blast",
    BlastTask = "Activity_BlastTask", -- Blast活动任务
    BlastSys = "Activity_BlastSys", -- Blast活动 新手期任务
    BlastShowTop = "Activity_BlastShowTop",
    DinnerLand = "Activity_DinnerLand",
    DinnerLandSale = "Promotion_DinnerLand",
    FBInboxCard = "Activity_FBInboxCard",
    CoinPusher = "Activity_CoinPusher",
    CoinPusherSale = "Promotion_CoinPusher",
    CoinPusherTask = "Activity_CoinPusherTask", --推币机任务
    Activity_CoinPusherTask = "Activity_CoinPusherTask", --推币机任务
    CoinPusherTaskNew = "Activity_CoinPusherMissionNew", --xin推币机任务
    Word = "Activity_Word",
    WordShowTop = "Activity_WordShowTop",
    WordSale = "Promotion_Word",
    --金币宣传-合成
    CoinExpandMerge = "Activity_CoinExpand_Merge",
    --word任务
    WordTask = "Activity_WordTask",
    WordTaskNew = "Activity_WordTaskNew", -- WORD活动任务新版
    SaleTicket = "Activity_SaleTicket",
    Coupon = "Activity_Coupon",
    SevenDaySign = "Activity_7DaySign",
    -- 集卡小游戏
    CashPuzzle = "Activity_CashPuzzleOpen",
    -- 活动总入口
    Entrance = "Activity_Entrance",
    -- 个人信息
    UserInfomation = "Activity_UserInfomation",
    RepartJackpot = "Activity_RepartJackpot",
    RepeatFreeSpin = "Activity_RepeatFreeSpin",
    -- 剁手星期一
    CyberMonday = "Activity_CyberMonday",
    -- 小猪挑战 累冲活动
    PiggyChallenge = "Activity_PigChallenge",
    -- vip特权
    VipPrivilege = "Activity_VipPrivilege",
    --大厅节日换背景活动
    changeLobbyBg = "Activity_ChangeLobbyBg",
    -- 高倍场 养猫猫小游戏活动
    DeluxeClubCatActivity = "Activity_DeluxeClub_Cat",
    DeluxeClubCat = "Activity_DeluxeClub_Cat",
    -- 圣诞树活动
    ChristmasMagicTour = "Activity_ChristmasMagicTour",
    -- 每日任务新活动
    LuckyMission = "Activity_LuckyMission",
    -- luckyspin送卡活动卡走配置不写死
    LuckySpinRandomCard = "Activity_LuckySpinRandomCard",
    -- 小猪送配置卡活动
    PigRandomCard = "Activity_PigRandomCard",
    -- 关卡比赛 （普通 -> 资格 -> 巅峰）
    League = "Activity_Leagues", -- 比赛普通赛
    LeagueQualified = "Activity_LeaguesQualified", -- 比赛资格赛
    LeagueSummit = "Activity_LeaguesSummit", -- 比赛巅峰赛
    -- 关卡比赛促销
    LeagueSale = "Promotion_Leagues",
    -- 双倍盖戳
    MulLuckyStamp = "Activity_MulLuckyStamp",
    -- FB加好友活动
    FBAddFriend = "Activity_FBAddFriend",
    -- 社区粉丝宣传活动
    FBCommunity = "Activity_FBCommunity",
    -- fb粉丝200k达成送奖
    FBGift200K = "Activity_FBGift200K",
    -- 钻石商店开始活动
    GemStoreOpen = "Activity_GemStoreOpen",
    --二选一活动
    BetweenTwo = "Activity_BetweenTwo",
    -- 包含 情人节挑战 .圣诞树挑战 等节日挑战的多主题
    HolidayChallenge = "Activity_HolidayChallenge",
    --新版餐厅任务
    DiningRoomTask = "Activity_DiningRoomTask",
    -- 常规促销小游戏
    SuperSaleLuckyChoose = "Activity_SuperSaleLuckyChoose",
    -- 商城缺卡
    StoreSaleRandomCard = "Activity_StoreSaleRandomCard",
    -- 双倍猫粮活动
    DoubleCatFood = "Activity_DoubleCatFood",
    -- nadoParty
    NadoParty = "Activity_NadoParty",
    -- FB小组宣传活动
    FBGroup = "Activity_FBGroup",
    -- 弹珠
    LevelRush = "Activity_LevelRush",
    -- 新关挑战
    -- SlotChallenge = "Activity_SlotChallenge",
    -- luckySpin 促销
    LuckySpinSale = "Activity_LuckySpinSale",
    -- 集卡倒计时
    CardEndCountdown = "Activity_CardEnd_Countdown",
    -- 新版餐厅
    DiningRoom = "Activity_DiningRoom",
    -- 新版餐厅促销
    DiningRoomSale = "Promotion_DiningRoom",
    --
    --
    CardSpecialAlbum = "Activity_SpecialAlbum",
    --
    CardSpecialAlbumGame = "Activity_SpecialAlbumGame",
    --  HAT TRICK DELUXE 活动 购买充值触发的活动
    PurchaseDraw = "Activity_PurchaseDraw",
    --促销弹板 - 母亲节

    SaleGroupMothersDay = "Activity_SaleGroup_MothersDay",
    -- 钻石商城赠送优惠券活动
    ShopGemCoupon = "Activity_ShopGemCoupon",
    --rippledash活动
    RippleDash = "Activity_RippleDash",
    --csc 2021-06-04 后期这种弹板活动会做成多主题,目前先这么加
    ChallengePassPay = "Activity_HolidayPay",
    ChallengePassExtraStar = "Activity_HolidayExtraStar",
    ChallengePassLastDay = "Activity_HolidayLastDay",
    ChallengePassLastSale = "Activity_HolidayLastSale",
    ChallengePassBox = "Activity_HolidayBox",
    -- luckyStemp送卡
    LuckyStampCard = "Activity_LuckyStampCard",
    -- 装修活动
    Redecor = "Activity_Redecor",
    RedecorSale = "Promotion_Redecor",
    RedecorShowTop = "Activity_RedecorShowTop",
    RedecorTask = "Activity_RedecorTask",
    -- 新的battlepass 活动 捆绑了pass任务
    NewPass = "Activity_NewPass",
    NewPassBuy = "Activity_NewPass_Buy",
    NewPassCountDown = "Activity_NewPass_CountDown",
    NewPassDoubleMedal = "Activity_NewPass_DoubleMedal",
    NewPassThreeLineLoading = "Activity_NewPassNew_loading",
    -- 高倍场 合成游戏
    DeluxeClubMergeActivity = "Activity_DeluxeClub_Merge",
    DeluxeClubMergeAdvertiseStart = "Activity_DeluxeClub_Merge_Loading", -- 高倍场 合成小游戏 宣传面板-start
    DeluxeClubMergeAdvertiseEnd = "Activity_DeluxeClub_Merge_CountDown", -- 高倍场 合成小游戏 宣传面板-end
    DeluxeClubMergeAdvertiseRule = "Activity_DeluxeClub_Merge_Rule", -- 高倍场 合成小游戏 宣传面板-规则宣传
    DeluxeClubMergeAdvertiseGetItem = "Activity_DeluxeClub_Merge_WayToGet", -- 高倍场 合成小游戏 宣传面板-道具获取途径宣传
    DeluxeClubMergeDouble = "Activity_Merge_DoublePouches", -- 高倍场合成双倍材料
    DeluxeClubMergeWeek = "Activity_MergeWeek", -- 合成周卡
    -- 2周年
    Years2 = "Activity_2YearsRegister",
    -- 公会宣传活动
    TeamInfo = "Activity_TeamInfo",
    TeamRankInfo = "Activity_TeamRankInfo", -- 公会排行榜宣传
    TeamRushInfo = "Activity_TeamRushInfo", -- 公会Rush任务宣传
    --第二货币商城折扣
    GemStoreSale = "Activity_GemStoreSale",
    -- 6个箱子促销
    MemoryFlyingSale = "Promotion_MemoryFlying",
    -- 邮箱收集
    collectEmail = "Activity_CollectEmail",
    -- 调查问卷
    Questionnaire = "Activity_Questionnaire",
    -- 开新关
    OpenNewLevel = "Activity_OpenNewLevel",
    --乐透活动
    LotteryOpen = "Activity_Lottery_Open",
    --乐透来源
    LotteryOpenSource = "Activity_Lottery_Open_source",
    -- 推币机 排行榜
    CoinPusherShowTop = "Activity_CoinPusherShowTop",
    ------------------- bingo比赛 -------------------
    BingoRush = "Activity_BingoRush",
    BingoRushPass = "Activity_BingoRushPass", -- Blast活动任务
    BingoRushShowTop = "Activity_BingoRushShowTop",
    BingoRushLoading = "Activity_BingoRush_Loading", -- bingo比赛宣传活动
    BingoRush_Foreshow = "Activity_BingoRush_Foreshow", -- bingo比赛宣传活动
    BingoRush_rule = "Activity_BingoRush_Rule", -- bingo比赛宣传活动
    BingoRush_NewRule = "Activity_BingoRush_NewRule", -- bingo比赛宣传活动
    ------------------- bingo比赛 -------------------

    -- 乐透挑战
    LotteryChallenge = "Activity_LotteryChallenge",
    -- 乐透额外送奖活动
    LotteryJackpot = "Activity_Lottery_Jackpot",
    -- 关卡全开活动
    AllGamesUnlocked = "Activity_AllGamesUnlocked",
    -- 促销二选一
    SaleGroup = "Activity_SaleGroup",
    -- 公共jackpot活动
    CommonJackpot = "Activity_CommonJackpot",
    --二选一
    TornadoMagicStore = "Promotion_TornadoMagicStore",
    --1+1
    Promotion_OnePlusOne = "Promotion_OnePlusOne",
    --商城最高档位付费后促销礼包功能
    Promotion_TopSale = "Promotion_TopSale",
    -- 扑克活动
    Poker = "Activity_Poker",
    PokerSale = "Promotion_Poker",
    PokerTask = "Activity_PokerTask", -- Poker活动任务
    PokerShowTop = "Activity_PokerShowTop",
    -- 商城常驻推荐促销 --   不关联活动,单纯的解析数据
    ShopDailySale = "Promotion_ShopDailySale",
    -- 商城改版宣传
    ShopLoading = "Activity_Shop_Loading",
    -- 商城膨胀
    ShopCarnival = "Activity_ShopCarnival",
    -- 占卜促销
    DivinationSale = "Promotion_Divination",
    -- DailyMissionRush
    DailyMissionRush = "Activity_DailyMissionRush",
    -- seasonMissionRush
    SeasonMissionRush = "Activity_SeasonMissionRush",
    -- 小猪折扣送金卡
    PigGoldCard = "Activity_PigGoldCard",
    -- DuckShot
    DuckShot = "Activity_DuckShot",
    -- 三日聚合挑战
    WildChallenge = "Activity_WildChallenge",
    -- 复活节3合1优惠劵
    Coupons3_Easter = "Activity_3Coupons_Easter",
    -- 小猪转盘
    GoodWheelPiggy = "Activity_GoodWheelPiggy",
    -- 2022复活节无线砸蛋促销
    EasterEggInfinitySale = "Promotion_Infinity_Easter22",
    --提醒玩家打开推送开关 活动
    ActivityPushNotifications = "Activity_PushNotifications",
    -- NiceDice
    NiceDice = "Activity_NiceDice",
    -- 头像框
    AvatarFrameLoading = "Activity_AvatarFrameLoading", --宣传活动 loading
    AvatarFrameRule = "Activity_AvatarFrameRule", --宣传活动 rule
    AvatarFrameChangeWay = "Activity_AvatarFrame_changeWay", -- 宣传活动 changeWay
    NewProfileLoading = "Activity_NewProfile_loading", -- 个人信息页宣传 loading
    NewProfileChange = "Activity_NewProfile_change", -- 个人信息页宣传 change
    -- fb分享获取优惠券
    FBShare = "Activity_FBShare",
    -- 涂色
    Coloring = "Activity_Coloring",
    -- 10m每日任务领优惠券
    CouponChallenge = "Activity_CouponChallenge_10M",
    -- 1000W扭蛋机
    Gashapon = "Activity_Gashapon",
    -- 乐透促销
    LotterySale = "Activity_Lottery_Sale",
    -- 乐透宣传
    LotteryStatistics = "Activity_Lottery_Statistics",
    FlowerLoading = "Activity_FlowerLoading", --宣传活动 loading
    -- 金币宣传-商城
    CoinExpand_Store = "Activity_CoinExpand_Store",
    -- 独立日3合1优惠劵
    Coupons3_July4th = "Activity_3Coupons_July4th",
    -- 比赛聚合
    BattleMatch_Rule = "Activity_BattleMatch_Rule", --宣传活动相当于Loading
    BattleMatch = "Activity_BattleMatch", --比赛聚合主活动
    -- 新版二选一
    NewDouble = "Promotion_NewDouble",
    -- 广告任务
    AdChallenge = "Activity_AdChallenge_loading",
    -- 快速点击小游戏
    PiggyClicker = "Activity_PiggyClicker",
    -- 调查问卷
    SurveyinGame = "Activity_SurveyinGame",
    InviteLoading = "Activity_InviteLoading",
    -- 集卡赛季末收益提升
    CardEndSpecial = "Activity_CardEnd_Special",
    -- 集卡规则变化
    SwimPoolCard = "Activity_SwimPool_Card",
    --集卡商城宣传
    PoolCardStore = "Activity_PoolCard_Store",
    -- 集卡 送卡规则变化宣传
    PoolCard_SendCard = "Activity_PoolCard_SendCard",
    -- 泳池赛季特殊卡册宣传
    MagicChip = "Activity_MagicChip",
    --金币宣传-免费金币
    CoinExpand_FreeCoin = "Activity_CoinExpand_FreeCoin",
    ------------------- 刮刮卡 -------------------
    ScratchCards = "Activity_ScratchCards",
    ScratchCardsLoading = "Activity_ScratchCards_loading", -- 刮刮卡开启弹板
    ScratchCardsRule = "Activity_ScratchCards_Rule", -- 刮刮卡规则弹板
    ScratchCardsBuy = "Activity_ScratchCards_Buy", -- 刮刮卡购买弹板
    ScratchCardsCountDown = "Activity_ScratchCards_CountDown", -- 刮刮卡倒计时弹板
    ------------------- 刮刮卡 -------------------
    -- 三周年分享挑战
    MemoryLane = "Activity_MemoryLane",
    BalloonRush = "Activity_BalloonRush", -- 限时任务 气球挑战
    -- 三周年3合1优惠劵
    Coupons3_3rdAnniversary = "Activity_3Coupons_3rdAnniversary",
    --弹珠小游戏
    PinBallGo = "Activity_PinBallGo",
    PinBallGoLoading = "Activity_PinBallGo_loading",
    -- spin送道具
    SpinItem = "Activity_SpinItem",
    Wanted = "Activity_Wanted", -- 单日特殊任务
    -- 品质头像框挑战
    SpecialFrame_Challenge = "Activity_SpecialFrame_Challenge",
    -- 头像框挑战
    FrameChallenge = "Activity_FrameChallenge",
    -- 啤酒节3合1优惠劵
    Coupons_BREWFEST = "Activity_3Coupons_BREWFEST",
    -- 商城指定档位送道具
    PurchaseGift = "Activity_PurchaseGift",
    -- 新推币机
    NewCoinPusher = "Activity_NewCoinPusher",
    NewCoinPusherSale = "Promotion_NewCoinPusher", -- 新推币机 促销
    NewCoinPusherTask = "Activity_NewCoinPusherTask", -- 新推币机 任务
    NewCoinPusherShowTop = "Activity_NewCoinPusherShowTop", -- 新推币机 排行榜
    Activity_NewCoinPusherTask = "Activity_NewCoinPusherTask", --新版 推币机任务
    -- quest送nado卡
    QuestNado = "Activity_QuestNado",
    -- 鲨鱼游戏特殊轮次卡
    MagicGameGuarantee = "Activity_MagicGame_Guarantee",
    Activity_LuckyStamp = "Activity_LuckyStamp",
    Activity_LuckyStampRule = "Activity_LuckyStampRule",
    GoldenDayRule = "Activity_GoldenDayRule", -- 金卡日（渠道）
    GoldenDayOpen = "Activity_GoldenDayOpen", -- 金卡日（开启）
    -- 万圣节三合一优惠券
    Coupons_HALLOWEEN = "Activity_3Coupons_HALLOWEEN",
    --特殊卡册
    CardObsidianCountDown = "Activity_CardObsidianCountDown",
    CardObsidianOpen = "Activity_CardObsidianOpen",
    CardObsidianRule = "Activity_CardObsidianRule",
    CardObsidianRule_Publicize = "Activity_CardObsidianRule_Publicize",
    CardObsidianJackpot = "Activity_CardObsidianJackpot",
    -- 疯狂购物车
    CrazyCart = "Activity_CrazyCart",
    -- 红蓝对决
    FactionFight = "Activity_FactionFight",
    GrandPrize = "Activity_GrandPrize", -- 黑五累充
    GrandPrizeStart = "Activity_GrandPrizeStart", -- 黑五累充弹板
    BFDraw = "Activity_BFDraw", --黑五代币抽奖
    ChristmasCalendar = "Activity_ChristmasAdventCalendar", -- 圣诞台历(签到)
    VipDoublePoint = "Activity_VIPDoublePoint", -- 12月份双倍积分
    VipResetOpen = "Activity_VIPResetOpen",
    VipResetRule = "Activity_VIPResetRule",
    SlotTrial = "Activity_SlotTrials", -- 新关挑战
    BlastTaskNew = "Activity_BlastTaskNew", -- Blast活动任务新版
    Allpay = "Activity_Allpay", -- 全服累充活动
    AddPay = "Activity_AddPay", -- 个人累充活动
    -- 接水管 pipeConnect
    PipeConnect = "Activity_PipeConnect", --接水管
    PipeConnectSale = "Promotion_PipeConnect",
    PipeConnectShowTop = "Activity_PipeConnectShowTop",
    PipeConnectTask = "Activity_PipeConnectTask",
    YearEndSummary = "Activity_YearEndSummary", --年终总结
    TeamGiftLoading = "Activity_GiftLoading",
    NewYearGift = "Activity_NewYearGift", -- 新年送奖
    -- 新版Quest 梦幻Quest
    QuestNew = "Activity_QuestNew",
    QuestNewShowTop = "Activity_QuestNewShowTop",
    QuestNewSale = "Activity_QuestNewSale",
    QuestNewRush = "Activity_QuestNewRush", -- QuestNew挑战活动
    -- 钻石挑战关闭展示活动
    DiamondChallengeClose = "Activity_DiamondChallengeClose",
    --钻石挑战倒数计时活动
    DiamondChallenge_CountDown = "Activity_DiamondChallenge_CountDown",
    -- 农场
    FarmLoading = "Activity_Farm_Loading",
    FarmRule_1 = "Activity_Farm_Rule_Loading1",
    FarmRule_2 = "Activity_Farm_Rule_Loading2",
    CardOpenNewUser = "Activity_CardOpen_NewUser", -- 新手期集卡开启活动
    -- 钻石挑战重开活动
    DiamondChallengeOpen = "Activity_DiamondChallengeOpen",
    --新版飞镖小游戏
    DartsGameNew = "Activity_DartsGameNew",
    DartsGameNewLoading = "Activity_DartsGameNew_Loading",
    SevenDaysPurchase = "Activity_7DaysPurchase",
    -- 3倍盖戳
    TripleStamp = "Activity_TripleStamp",
    -- 自选任务
    PickTask = "Activity_PickTask",
    -- 聚合轮盘宣传
    HolidayWheel = "Activity_HolidayWheel",
    HolidayChallengeRank = "Activity_HolidayRank", --聚合挑战排行榜
    HolidayChallengeSpecial = "Activity_HolidaySpecial", --付费宣传
    -- 宝石返还
    CrystalBack = "Activity_CrystalBack",
    ObsidianWheel = "Activity_ObsidianWheel", -- 黑曜卡抽奖轮盘
    -- 3倍vip点数
    TripleVip = "Activity_3xVip",
    -- 限时促销
    LimitedOffer = "Activity_LimitedOffer",
    -- vip点数池
    VipPointsBoost = "Activity_VipPoints_Boost",
    -- bigwin 挑战
    BigWin_Challenge = "Activity_BigWin_Challenge",
    -- wild卡转盘
    WildDraw = "Activity_WildDraw",
    -- bingo连线
    LineSale = "Activity_LineSale",
    -- album race额外发放新赛季卡包奖励
    AlbumRaceNewChips = "Activity_AlbumRaceNewChips",
    ChaseForChips = "Activity_ChaseForChips", -- 集卡赛季末聚合
    --集卡赛季末个人累充PLUS
    TopUpBonus = "Activity_TopUpBonus",
    --集卡赛季末最后一天追加奖励
    TopUpBonusLast = "Activity_TopUpBonusLast",
    -- 膨胀宣传 集卡
    BigBang_Album = "Activity_BigBang_Album",
    -- 膨胀宣传 金币商城
    BigBang_CoinStore = "Activity_BigBang_CoinStore",
    -- 膨胀宣传 免费金币
    BigBang_FreeCoin = "Activity_BigBang_FreeCoin",
    -- 膨胀宣传 主图
    BigBang_Start = "Activity_BigBang_Start",
    -- 膨胀宣传 合成
    BigBang_Merge = "Activity_BigBang_Merge",
    LegendaryWin = "Activity_legendary_win", --宣传活动 loading
    -- 第二货币抽奖
    GemMayWin = "Activity_GemMayWin",
    BigBang_WarmUp = "Activity_BigBang_WarmUp", -- 膨胀宣传-预热
    --新版商城改版宣传
    ShopUp = "Activity_ShopUp",
    -- 付费目标
    GetMorePayLess = "Activity_GetMorePayLess",
    -- 行尸走肉预热活动
    ZombieWarmUp = "Activity_Zombie_WarmUp",
    -- 合成转盘
    MagicGarden = "Activity_MagicGarden",
    -- Minz
    Minz = "Activity_Minz",
    MinzLoading = "Activity_Minz_Loading",
    MinzRule = "Activity_Minz_Rule",
    --自选促销礼包
    DIYComboDeal = "Promotion_DIYComboDeal",
    --行尸走肉
    Zombie = "Activity_Zombie",
    ZombieRule = "Activity_Zombie_rule",
    -- 充值抽奖池
    PrizeGame = "Activity_PrizeGame",
    -- 第二货币消耗挑战
    GemChallenge = "Activity_GemChallenge",
    --公会对决宣传
    TeamDuel_Loading = "Activity_TeamDuel_loading",
    -- 钻石挑战
    DiamondMania = "Activity_DiamondMania",
    --返回持金极大值促销
    TimeBack = "Activity_TimeBack",
    -- 收集玩家生日信息
    Birthday = "Activity_Birthday",
    BirthdayPublicity = "Activity_Birthday_Publicity",
    TeamChestLoading = "Activity_TeamChest_Loading1", --宣传活动 loading
    -- 组队打BOSS
    DragonChallenge = "Activity_DragonChallenge",
    --MINZ：最后一天雕像增加
    MinzExtra = "Activity_Minz_Extra",
    -- Quest中增加MINZ道具宣传
    QuestMinzIntro = "Activity_QuestMinz_Intro",
    -- 付费排行榜
    PayRank = "Activity_PayRank",
    -- Flamingo Jackpot
    FlamingoJackpot = "Activity_FlamingoJackpot",
    -- 商城停留送优惠券
    StayCoupon = "Activity_StayCoupon",
    -- 高倍场体验卡促销
    HighClubSale = "Activity_HighClubSale",
    -- 三指针转盘促销
    DIYWheel = "Activity_DIYWheel",
    -- 公会表情包宣传
    NewStickersLoading = "Activity_NewStickers_loading",
    -- 新手期三日任务
    NoviceTrail = "Activity_NoviceTrail",
    -- 组队boss预告
    DragonChallengeWarning = "Activity_DragonChallenge_warning",
    -- 集卡小猪
    ChipPiggy = "Activity_ChipPiggy",
    TrioPiggy = "Activity_TrioPiggy",
    ChipPiggyLoading = "Activity_ChipPiggy_loading",
    ChipPiggyCountDown = "Activity_ChipPiggy_CountDown",
    ChipPiggyRule = "Activity_ChipPiggyRule",
    -- 赛季末返新卡
    GrandFinale = "Activity_GrandFinale",
    -- 4格连续充值
    KeepRecharge4 = "Activity_KeepRecharge4",
    CardMythicLoading = "Activity_CardMythic_Loading",
    CardMythicSourceLoading = "Activity_CardMythic_SourceLoading",
    -- 4周年抽奖+分奖
    dayDraw4B = "Activity_4BdayDraw",
    -- 限时膨胀 宣传
    TimeLimitExpansionLoading = "Activity_TimeLimitExpansion_loading",
    -- 限时膨胀
    TimeLimitExpansion = "Activity_TimeLimitExpansion",
    -- 限时集卡多倍奖励
    AlbumMoreAward = "Activity_AlbumMoreAward",
    -- 第二货币小猪
    GemPiggy = "Activity_GemPiggy",
    GemPiggyCountDown = "Activity_GemPiggy_CountDown",
    GemPiggyLoading = "Activity_GemPiggy_loading",
    GemPiggyRule = "Activity_GemPiggyRule",
    -- 三联优惠券
    CouponRewards = "Activity_CouponRewards",
    -- 等级里程碑小游戏
    LevelRoadGame = "Activity_LevelRoadGame",
    BlastBombLoading = "Activity_BlastBlossomBomb_loading", --宣传活动 loading

    DiyFeature = "Activity_DiyFeature",
    DiyFeatureLoading = "Activity_DiyFeature_Loading",
    DiyFeatureRule = "Activity_DiyFeature_Rule",
    DiyFeatureOverSale = "Promotion_DiyFeature",
    DiyFeatureNormalSale = "Promotion_DiyFeatureNormal",
    -- LEVEL UP PASS
    LevelUpPass = "Activity_LevelUpPass",
    -- 鲨鱼游戏道具化促销
    MythicGameSale = "Activity_CardGame_Sale",
    -- 周三公会积分双倍
    ClanDoublePoints = "Activity_ClanDoublePoints",
    --单人限时比赛
    LuckyRace = "Activity_LuckyRace",
    -- 大R高性价比礼包促销
    SuperValue = "Activity_SuperValue",
    BlastNoviceTask = "Activity_BlastNoviceTask",
    -- 新版小猪挑战
    PiggyGoodies = "Activity_PiggyGoodies",
    -- 合成商店折扣
    MergeStoreCoupon = "Activity_DeluxeClub_Merge_StoreCoupon",
    LuckyV2Loading = "Activity_LuckySpin_Loading", --宣传活动 loading
    -- DIYFEATURE新手任务中心
    DIYFeatureMission = "Activity_DIYFeatureMission",
    DiySale = "Activity_DiySale",
    OutsideCave = "Activity_OutsideCave", --大富翁
    CaveEggs = "Activity_Eggs", --砸龙蛋
    OutsideCaveSale = "Promotion_OutsideCave", --大富翁促销
    OutsideCaveShowTop = "Activity_OutsideCaveShowTop", --排行榜
    OutsideCaveTaskNew = "Activity_OutsideCaveMissionNew", -- 任务
    OutsideCaveTask = "Activity_OutsideCaveTask", --旧版任务
    -- 集装箱大亨
    BlindBox = "Activity_BlindBox",
    -- 挖钻石聚合
    JewelMania = "Activity_JewelMania",
    -- 合成pass    
    MergePass = "Activity_MergePass",
    MergePassLayer = "Activity_MergePassLayer",

    --膨胀消耗1v1比赛
    FrostFlameClash = "Activity_FrostFlameClash",
    FrostFlameClash_Loading = "Activity_FrostFlameClash_loading",

    -- 膨胀宣传 集卡 Monster
    Monster_Album = "Activity_Monster_Album",
    -- 膨胀宣传 合成 Monster
    Monster_Merge = "Activity_Monster_Merge",
    -- 膨胀宣传 预热 Monster
    Monster_WarmUp = "Activity_Monster_WarmUp",
    -- 膨胀宣传(怪兽) 金币商城
    Monster_CoinStore = "Activity_Monster_CoinStore",
    -- 膨胀宣传(怪兽) 免费金币
    Monster_FreeCoins = "Activity_Monster_FreeCoins",
    -- 膨胀宣传(怪兽) 主图
    Monster_Start = "Activity_Monster_Start",
    -- 膨胀宣传(怪兽) 合成
    Monster_Piggy = "Activity_Monster_Piggy",
    --新版钻石挑战
    NewDiamondChallenge = "Activity_NewDiamondChallenge",
    -- 新版钻石挑战宣传
    NewDiamondChallenge_End = "Activity_NewDiamondChallenge_End",
    -- 新版钻石挑战宣传
    NewDiamondChallenge_Loading = "Activity_NewDiamondChallenge_Loading",
    -- 新版钻石挑战宣传
    NewDiamondChallenge_Rule = "Activity_NewDiamondChallenge_Rule",
    --新版钻石挑战之限时活动
    NewDCRush = "Activity_NewDiamondChallenge_Rush",
    -- SuperSpin送道具
    LuckySpinSpecial = "Activity_LuckySpinSpecial",
    -- 无限促销
    FunctionSaleInfinite = "Activity_FunctionSale_Infinite",
    -- 大活动PASS
    FunctionSalePass = "Activity_FunctionSale_Pass",
    -- 第二货币两张优惠券
    TwoGemCoupons = "Activity_TwoGemCoupons",
    -- 圣诞聚合
    HolidayNewChallenge = "Activity_HolidayNewChallenge",
    AdventCalendar = "Activity_XmasAdventCalendar", -- 签到
    HolidaySideGame = "Activity_HolidaySideGame",   -- 小游戏
    HolidayPass = "Activity_HolidayPass",           -- pass
    HolidayStore = "Activity_HolidayStore",         -- 商店
    HolidayNewRank = "Activity_HolidayNewRank",     -- 排行榜
    HolidayStore_NewItem = "Activity_HolidayStore_NewItem",    -- 商店宣传（pass 开启）
    HolidayStore_FinalDay = "Activity_HolidayStore_FinalDay",     -- 商店宣传 （最后一天）
    -- 第二货币商城折扣送道具
    GemCoupon = "Activity_GemCoupon",
    -- 特定V用户送优惠卷
    VCoupon = "Activity_VCoupon",
    -- 抽奖轮盘
    CrazyWheel = "Activity_CrazyWheel",
    -- 预热 NewDC
    NewDC_WarmUp = "Activity_NewDC_WarmUp",
    -- 寻宝之旅
    TreasureHunt = "Activity_TreasureHunt",
    -- SuperSpin高级版送缺卡
    FireLuckySpinRandomCard = "Activity_FireLuckySpinRandomCard",
    -- 收集邮件抽奖
    MailLottery = "Activity_MailLottery",
    -- 大赢宝箱
    MegaWinParty = "Activity_MegaWin",
    MegaWinPartyLoading = "Activity_MegaWinParty_Loading", -- 大赢宣传活动
    -- 收集邮件抽奖
    Notification = "Activity_Notification",
    -- 埃及推币机
    EgyptCoinPusher = "Activity_EgyptCoinPusher",
    EgyptCoinPusherSale = "Promotion_EgyptCoinPusher", -- 埃及推币机 促销
    EgyptCoinPusherTask = "Activity_EgyptCoinPusherTask", -- 埃及推币机 任务
    EgyptCoinPusherShowTop = "Activity_EgyptCoinPusherShowTop", -- 埃及推币机 排行榜
    Activity_EgyptCoinPusherTask = "Activity_EgyptCoinPusherTask", -- 埃及推币机 任务
    -- 完成任务装饰圣诞树
    MissionsToDIY = "Activity_MissionsToDIY",
    PetRule = "Activity_PetRule", -- 宠物规则宣传
    BucksPre = "Activity_BucksPre",-- 代币预热
    -- 圣诞付费分奖
    XmasCraze2023 = "Activity_XmasCraze2023",
    -- 圣诞累充分奖
    XmasSplit2023 = "Activity_XmasSplit2023",
    -- 付费返代币
    BucksBack = "Activity_BucksBack",
    -- 预热宣传
    Bucks_Loading = "Activity_Bucks_Loading",
    -- 收集手机号
    CollectPhone = "Activity_CollectPhone",
    Bucks_New = "Activity_Bucks_New",-- 代币 支持点位新增宣传
    LuckySpinUpgrade = "Activity_LuckySpinUpgrade",
    PetLoading = "Activity_PetLoading",-- 宠物-预热宣传
    PetStart = "Activity_PetStart",-- 宠物-开启宣传
    -- 宠物-7日任务
    PetMission = "Activity_PetMission"
}

-- 全局引用名
GD.G_REF = {
    -- 邮件
    Inbox = "Inbox",
    -- 商店
    Shop = "Shop",
    LuckySpin = "LuckySpin",
    -- 盖戳
    LuckyStamp = "LuckyStamp",
    -- 集卡
    Card = "Card",
    -- 集卡特殊章节
    CardSpecialClan = "CardSpecialClan",
    -- 集卡神庙探险小游戏
    CardSeeker = "CardGame_Seeker",
    -- 集卡商城
    CardStore = "CardStore",
    --集卡排行榜
    CardRank = "CardRank",
    CardBetTip = "CardBetTip",
    -- 集卡特殊卡册
    ObsidianCard = "ObsidianCard",
    -- 高倍场
    DeluexeClub = "DeluexeClub",
    -- Vip
    Vip = "Vip",
    -- 乐透
    Lottery = "Lottery",
    MSCRate = "Activity_MileStoneCoupon_Rate",
    MSCRegister = "Activity_MileStoneCoupon_Register",
    GiftPickBonus = "GiftPickBonus",
    PokerRecall = "PokerRecall",
    FirstCommonSale = "Promotion_FirstCommon",
    TreasureSeeker = "TreasureSeeker",
    -- 跳转
    JumpTo = "JumpTo",
    --个人信息
    UserInfo = "UserInfo",
    -- 小猪银行
    PiggyBank = "PiggyBank",
    -- 头像框
    Avatar = "Avatar",
    AvatarFrame = "AvatarFrame",
    AvatarGame = "AvatarGame",
    -- fb用户分享后获取的优惠券
    FBShareCoupon = "FBShareCoupon",
    --每日浇花
    Flower = "Flower",
    -- 每日轮盘
    CashBonus = "CashBonus",
    -- 货币
    Currency = "Currency",
    -- 小游戏 CashMoney
    CashMoney = "CashMoney",
    -- 新手7日目标
    NewUser7Day = "NewUser7Day",
    --拉新
    Invite = "Invite",
    -- spin获得道具
    SpinGetItem = "SpinGetItem",
    -- 关卡grand大奖分享
    MachineGrandShare = "MachineGrandShare",
    -- 弹珠小游戏
    Plinko = "Plinko",
    -- LeveDash小游戏
    LeveDashLinko = "LeveDashLinko",
    -- 比赛ctrl管理
    LeagueCtrl = "LeagueCtrl",
    -- 聚合挑战结束促销
    HolidayEnd = "Promotion_HolidayEnd",
    -- 购买权益
    PBInfo = "PBInfo",
    BindPhone = "BindPhone",
    --收藏关卡
    CollectLevel = "CollectLevel",
    -- sdk fb好友列表
    FBFriend = "FBFriend",
    -- 好友
    Friend = "Friend",
    -- 调查问卷 通用弹版
    SurveyInGame = "SurveyInGame",
    -- 农场
    Farm = "Farm",
    CardNovice = "CardNovice", -- 新手期集卡
    -- 用户新手期
    UserNovice = "UserNovice",
    -- 成长基金
    GrowthFund = "GrowthFund",
    -- 付费二次确认弹板
    PaymentConfirm = "PaymentConfirmation",
    -- 新破冰促销
    IcebreakerSale = "IcebreakerSale",
    -- 月卡
    MonthlyCard = "MonthlyCard",
    -- 扩圈
    NewUserExpand = "NewUserExpand",
    ExpandGameMarquee = "ExpandGameMarquee", -- 扩圈游戏跑马灯
    ExpandGamePlinko = "ExpandGamePlinko", -- 扩圈游戏 弹珠
    -- 常规促销
    SpecialSale = "SpecialSale",
    -- 限时抽奖
    HourDeal = "HourDeal",
    -- 关卡促销入口
    BestDeal = "BestDeal",
    -- 新版回归签到
    Return = "Return",
    -- 关卡额外消耗的bet
    BetExtraCosts = "BetExtraCosts",
    -- LuckySpin SuperSpin
    LuckySpin = "LuckySpin",
    -- 新手期集卡 促销
    CardNoviceSale = "CardNoviceSale",
    -- bet 提升提示
    BetUpNotice = "BetUpNotice",
    -- 三档首充
    FirstSaleMulti = "Promotion_FirstMultiSale",
    -- 等级里程碑
    LevelRoad = "LevelRoad",
    -- 鲨鱼游戏道具化
    MythicGame = "Activity_CardGameSeeker",
    -- 次日礼物
    TomorrowGift = "TomorrowGift",
    -- 新手任务
    SysNoviceTask = "SysNoviceTask",
    -- 浮动view
    FloatView = "FloatView",
    -- 新手期7日签到 v2 (noviceCheck2)
    NoviceSevenSign = "NoviceSevenSign",
    GiftCodes = "GiftCodes",
    -- 万亿赢家挑战功能
    TrillionChallenge = "TrillionChallenge",
    -- 破产促销V2
    BrokenSaleV2 = "BrokenSaleV2",
    AppCharge = "AppCharge",
    -- 新版常规促销
    RoutineSale = "RoutineSale",
    -- 系统引导 rateUs, 绑定fb, 绑定邮箱，打开推送
    OperateGuidePopup = "OperateGuidePopup",
    -- 宠物系统
    Sidekicks = "Sidekicks",
    -- 第三货币
    ShopBuck = "ShopBuck",
    -- 神秘宝箱系统
    BoxSystem = "BoxSystem",
    -- 关卡bet上的气泡
    BetBubbles = "BetBubbles",
}

-- 文本特效
GD.LABEL_EFFECT = {
    NORMAL = 0,
    OUTLINE = 1,
    SHADOW = 2,
    BOTTOMSHADOW = 3,
    GLOW = 4,
    ITALICS = 5,
    BOLD = 6,
    UNDERLINE = 7,
    STRIKETHROUGH = 8,
    ALL = 9
}

local pcall_require = function(file)
    local ok, module =
        pcall(
        function()
            return require(file)
        end
    )

    if ok then
        return module
    else
        local sendErrMsg = "require file " .. tostring(file) .. " error!!"
        release_print(sendErrMsg)
        if util_sendToSplunkMsg ~= nil then
            util_sendToSplunkMsg("luaError", sendErrMsg)
        end
        return nil
    end
end

GD.ViewConfig = require "views.ViewConfig"

local Facade = require("GameMVC.core.Facade")

GD.BaseGameControl = require("GameBase.BaseGameControl")
GD.BaseActivityControl = require("GameBase.BaseActivityControl")
GD.BaseGameModel = require("GameBase.BaseGameModel")

-- 全局获取管理器
GD.G_GetMgr = function(refName)
    local _mgr = Facade:getInstance():getCtrl(refName)
    -- if not _mgr and DEBUG == 2 then
    --     assert(_mgr, "get '" .. tostring(refName) .. "' mgr obj is nil!!!")
    -- end
    return _mgr
end

local LoginMgr = require("GameLogin.LoginMgr")

--初始化protobuf
function GD.initProtobuf()
    -- util_clearSearchPaths()
    if (not util_isSupportVersion("1.8.4", "ios")) and (not util_isSupportVersion("1.7.9", "android")) then
        cc.FileUtils:getInstance():addSearchPath("src/protobuf", true)
        cc.FileUtils:getInstance():addSearchPath(device.writablePath .. "src/protobuf", true)
    end
    pcall_require("BaseProto_pb")
    pcall_require("CardProto_pb")
    pcall_require("ExtendProto_pb")
    pcall_require("FriendProto_pb")
    pcall_require("GameProto_pb")
    pcall_require("LoginProto_pb")
    pcall_require("UserProto_pb")
    pcall_require("ClanProto_pb")
    pcall_require("ChatProto_pb")
end

--每小时奖励时间间隔
GD.HOUR_REWARDTIME = 7200

--find展示 每页只显示5个物品
GD.FINDITEM_MAX_COUNT = 5

--进入后台重启时间
GD.RESET_GAME_TIME = 600
if DEBUG ~= 0 and (device.platform == "ios" or device.platform == "android") then
    RESET_GAME_TIME = 60
end

------ 全局数据内容
GD.GlobalEvent = {
    GEvent_LoadedError = "gevent_loadederror", -- 下载失败
    GEvent_LoadedProcess = "gevent_loadprocess", -- 下载进行中
    GEvent_LoadedSuccess = "gevent_loadedsuccess", -- 下载成功
    GEvent_UncompressSuccess = "gevent_uncompress_success", --解压成功
    FB_LoginStatus = "gevent_login_status", -- 登录状态
    FB_LogoutStatus = "gevent_logout_status", -- 登出状态
    IAP_BuyResult = "iap_buy_result", -- 购买结果
    IAP_ConsumeResult = "iap_consume_result", -- 消耗结果
    ServerTime_Status = "servertime_success" -- 通知服务器时间获取成功
}

GD.DownErrorCode = {
    CREATE_FILE = 0, -- 创建下载数据存储文件时错误
    -- Error caused by network
    -- network unavaivable
    -- timeout
    -- ...
    NETWORK = 1, --网络故障
    -- Error caused in uncompressing stage
    -- can not open zip file
    -- can not read file global information
    -- can not read file information
    -- can not create a directory
    -- ...
    UNCOMPRESS = 2, --解压缩错误
    COMPLETE = 3,
    READ = 4 -- 读取文件失败
}
-- 在这里配置levels.json 文件， 这样所有引用的地方都可以修改了
GD.GD_LevelsName = "levels102.json" --v106
GD.GD_DynamicName = "Dynamic.json"
GD.GD_DynamicCards = "GameModule/Card/DynamicCards.json"

--下载状态
GD.DownLoadType = {
    DOWN_NONE = 0,
    DOWN_ERROR = 1,
    DOWN_SUCCESS = 2,
    DOWN_PROCESS = 3,
    DOWN_UNCOMPRESSED = 4
}

-- @TODO: test
-- local testData = require("GameModule.Guide.test.GuideTestData")
-- gGuideMgr:parseGuideCfgs(testData.testStepCfg)
-- gGuideMgr:parseGuideInfos(testData.testStepInfos)

---
-- 处理缩放， 设置全局参数供调用
function GD.operaScaleMode()
    local winSize = display.size
    local ccDesignSize = cc.size(1370, 768)
    local winSizePro = winSize.width / winSize.height
    local designSizePro = ccDesignSize.width / ccDesignSize.height
    local pro = winSizePro / designSizePro

    GD.UIScalePro = pro
end
operaScaleMode()

-- 初始化全局管理对象
local initGlobalManger = function()
    GD.globalPlatformManager = require("manager.PlatformManager"):getInstance()
    GD.gLobalDataManager = require("manager.UserDataManager"):getInstance()

    GD.globalData = require("data.GlobalData"):getInstance()
    -- 初始化一些非loading 期间使用的全局变量
    GD.globalFireBaseManager = require("sdk.FirebaseManager"):getInstance()
    GD.globalAdjustManager = require("sdk.AdjustManager"):getInstance()
    GD.globalFaceBookManager = require("sdk.FacebookManager"):getInstance()

    GD.MARKETSEL = globalPlatformManager:getMarketSel()

    GD.globalXSDKFaceBookManager = require("manager.Common.XSDKFaceBookManager"):getInstance()
    GD.globalXSDKDeviceInfoManager = require("manager.Common.XSDKDeviceInfoManager"):getInstance()
    GD.globalXSDKThirdPartyManager = require("manager.Common.XSDKThirdPartyManager"):getInstance()
    GD.globalDeviceInfoManager = require("manager.Common.DeviceInfoManager"):getInstance()

    initProtobuf()
    GD.RotateScreen = pcall_require("base.RotateScreen")
    GD.BaseView = pcall_require("base.BaseView")
    GD.BaseLayer = pcall_require("base.BaseLayer")
    GD.BaseScene = pcall_require("base.BaseScene")

    GD.gLobalSendDataManager = require("network.SendDataManager"):getInstance()
    GD.gLobalResManager = require("manager.ResManager"):getInstance()
    GD.gLobalNoticManager = require("manager.NotificationManager"):getInstance()
    GD.gLobalViewManager = require("manager.ViewManager"):getInstance()
    GD.gLobalSoundManager = require("manager.SoundManager"):getInstance()
    local EventKeyControl = require("common.EventKeyControl")
    GD.globalEventKeyControl = EventKeyControl:create()

    --ads
    require("sdk.sdkConfig")
    local AdsControl = require("sdk.AdsControl")
    GD.gLobalAdsControl = AdsControl:create()
    -- 弹板模块
    -- require("PopProgram.PushViewManager")
    GD.PopUpManager = require("data.popUp.PopUpManager"):getInstance()
    -- 新的网络模块
    GD.gLobalNetManager = require("net.NetModelMgr"):getInstance()

    --动态下载控制器
    GD.globalDynamicDLControl = require("common.DynamicDLControl"):getInstance()
    GD.globalCardsDLControl = require("common.CardsDLControl"):getInstance()
    GD.globalCardsManualDLControl = require("common.CardsManualDLControl"):getInstance()
    GD.globalLevelNodeDLControl = require("common.LevelNodeDLControl"):getInstance()
    -- 热更模块
    GD.globalUpgradeDLControl = require("common.UpgradeDLControl"):getInstance()
    -- 推送管理器
    GD.globalLocalPushManager = require("manager.System.LocalPushManager"):getInstance()

    -- 公告管理器
    GD.globalAnnouncementManager = require("manager.AnnouncementManager"):getInstance()
end

--上面的参数需要用到放这里

local GameInit = class("GameInit")
GameInit.m_instance = nil --

function GameInit:ctor()
end

function GameInit:getInstance()
    -- body
    if GameInit.m_instance == nil then
        --todo
        GameInit.m_instance = GameInit.new()
    end

    return GameInit.m_instance
end

function GameInit:init()
    if device.platform == "mac" then
        CC_IS_READ_DOWNLOAD_PATH = false -- 关卡的动态下载
        CC_DYNAMIC_DOWNLOAD = false
    end

    if device.platform == "android" then
        local isLowMem = false
        -- if util_isSupportVersion("1.8.7", "android") or util_isSupportVersion("1.9.0", "ios") then
        --     isLowMem = globalPlatformManager:isLowMemUnused()
        -- else
            isLowMem = util_isLow_endMachine()
        -- end
        -- 低端机默认开启RGBA4444
        local tpFormat = (not isLowMem) and cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888 or cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A4444
        cc.Texture2D:setDefaultAlphaPixelFormat(tpFormat)
    else
        cc.Texture2D:setDefaultAlphaPixelFormat(cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)
    end

    -- 初始化全局管理对象
    initGlobalManger()
    local NetworkLog = util_require("network.NetworkLog")
    GD.logManager = NetworkLog:create()
    if NetworkLog.readLogFromFile ~= nil then
        NetworkLog.readLogFromFile()
    end
    Facade:getInstance()
    LoginMgr:getInstance():init()

    -- 停止正在下载的线程
    util_stopAllDownloadThread()
    self:initDownCall()
    globalPlatformManager:setScreenRotateAnimFlag(false)
    globalData.slotRunData:changeScreenOrientation(false)
    globalAdjustManager:sendAdjustKey("appInit")

    --csc 2022-02-28 登录之前读取一次当前网络状态
    globalDeviceInfoManager:readSystemNetWork()
    -- 本地通知 进入游戏
    globalLocalPushManager:gameInit()
    self:registerDebugLog()
    self:registerEvents()
end

function GameInit:initDownCall()
    -- 初始化下载事件回调
    --
    ---注册统一的加载事件回调, 所有调用下载的人，只需要监听GlobalEvent 下的事件，根据url 判断是否为自己的下载内容
    xcyy.HandlerIF:registerDownloadHandler(
        function(url, errorEnum, key)
            -- 加载失败回调
            -- local msg = string.format("--->加载失败 url = %s, key = %s\n", url, tostring(key)) 
            -- release_print(msg)
            if DEBUG == 0 and globalData.userRunData.userUdid == "3a8749ad-75b5-395b-afbd-47fb5bfeff32:SlotNewCashLink" then
                util_sendToSplunkMsg("DownloadError", string.format("下载失败报送_url:%s, errorEnum:%s", url, errorEnum))
            end
            gLobalNoticManager:postNotification(GlobalEvent.GEvent_LoadedError, {url = url, errorEnum = errorEnum})
        end,
        function(url, loadedByte, totalByte, key) 
            -- 加载进行中回调
            -- local msg = string.format("--->加载进行中.. url = %s, key = %s\n", url, tostring(key))
            -- release_print(msg)
            gLobalNoticManager:postNotification(GlobalEvent.GEvent_LoadedProcess, {url = url, loadPercent = (loadedByte / totalByte)})
        end,
        function(url, key) 
            -- 下载成功回调
            -- local msg = string.format("--->加载成功url = %s, key = %s\n", url, tostring(key))
            -- release_print(msg)
            gLobalNoticManager:postNotification(GlobalEvent.GEvent_LoadedSuccess, url)
        end,
        function(url, key) 
            -- 解压成功回调
            -- local msg = string.format("--->uncompress url = %s, key = %s\n", url, tostring(key))
            -- release_print(msg)
            gLobalNoticManager:postNotification(GlobalEvent.GEvent_UncompressSuccess, url)
        end
    )
end

function GameInit:initAndroidCall()
    if util_isSupportVersion("1.7.3", "android") then
        local sig = "()V"
        local luaj = require("cocos.cocos2d.luaj")
        local className = "org/cocos2dx/lua/AppActivity"
        local ok, ret = luaj.callStaticMethod(className, "LoginCall", {}, sig)
        if not ok then
            return ""
        else
            return ret
        end
    end
end

function GameInit:registerDebugLog()
    if DEBUG == 2 then
        local platform = device.platform
        --后面增加版本号判断
        if (platform == "android" and util_isSupportVersion("1.7.3") or ((platform == "ios" or platform == "mac") and util_isSupportVersion("1.8.0"))) then
            GD.DebugLogList = {}
            xcyy.XCLogFile:registerLuaCallBack(
                function(buffer)
                    if #GD.DebugLogList > 100 then
                        local info = table.remove(GD.DebugLogList, 1)
                    end
                    table.insert(GD.DebugLogList, {buffer = buffer, len = #buffer})
                end
            )
        end
    end
end

function GameInit:registerEvents()
    local customEventDispatch = cc.Director:getInstance():getEventDispatcher()
    customEventDispatch:removeCustomEventListeners("APP_ENTER_BACKGROUND_EVENT")
    local listenerCustomBackGround =
        cc.EventListenerCustom:create(
        "APP_ENTER_BACKGROUND_EVENT",
        function()
            release_print("--切换到后台--")
            if globalEventKeyControl.setEnabled then
                globalEventKeyControl:setEnabled(false)
            end
            gLobalNoticManager:postNotification(ViewEventType.APP_ENTER_BACKGROUND_EVENT)
        end
    )
    customEventDispatch:addEventListenerWithFixedPriority(listenerCustomBackGround, 1)

    customEventDispatch:removeCustomEventListeners("APP_ENTER_FOREGROUND_EVENT")
    local listenerCustomForeGround =
        cc.EventListenerCustom:create(
        "APP_ENTER_FOREGROUND_EVENT",
        function()
            release_print("--切换到前台--")
            if globalEventKeyControl.setEnabled then
                globalEventKeyControl:setEnabled(true)
            end
            gLobalNoticManager:postNotification(ViewEventType.APP_ENTER_FOREGROUND_EVENT)
        end
    )
    customEventDispatch:addEventListenerWithFixedPriority(listenerCustomForeGround, 1)
end

return GameInit
