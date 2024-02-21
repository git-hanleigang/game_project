-- Author: island
-- Date: 2017-08-11 10:50:42
--
-- FIX IOS
----- http message 关联的消息
GD.HTTP_MESSAGE_TYPES = {
    HTTP_TYPE_LOGIN_SUCCESS = "http_type_login_success", --登录成功
    HTTP_TYPE_LOGIN_FAILD = "http_type_login_faild", --登录失败
    HTTP_TYPE_FB_LOGIN_CHOICE = "http_type_fb_login_choice", --登录选择 （fb  guest）
    HTTP_TYPE_LOGOUT = "http_type_logout", --登出
    HTTP_TYPE_QUERY_SUCCESS = "http_type_query_success", --查询成功
    HTTP_TYPE_GLOBALCONFIG_SUCCESS = "http_type_globlconfig_success", --获取全局配置成功
    HTTP_TYPE_GLOBALCONFIG_FAILD = "http_type_globlconfig_faild" --获取全局配置失败
}

GD.WinType = {
    -- 赢钱的类型
    Normal = 1,
    BigWin = 2,
    MegaWin = 3,
    EpicWin = 4
}

GD.MessageDataType = {
    MSG_BONUS_COLLECT = 1, --收集小游戏
    MSG_BONUS_SELECT = 2, --FREESPIN选择小游戏
    MSG_SPIN_PROGRESS = 3, --SPIN收集进度统计
    MSG_MISSION_COMLETED = 4, --任务完成
    MSG_REWARD_VIDEO = 0, --激励视频
    MSG_BONUS_SPECIAL = 5, -- 袋鼠关卡兑换接口
    MSG_LUCKY_SPIN = 6, -- 购买后的 翻倍轮盘
    MSG_DELUXE_CHANGE_COIN = 7, -- 高倍场积分换金币
    MSG_TEAM_MISSION_OPTION = 8, --关卡团队任务玩家操作
    MSG_TEAM_MISSION_STORE = 9, --关卡选择阵营
    MSG_TEAM_MISSION_JOIN = 10, --关卡选择房间座位
    MSG_LUCKY_SPIN_ENJOY = 11, -- 购买后的 翻倍轮盘 先享后付
    MSG_LUCKY_SPINV2 = 12, -- 购买后的 翻倍轮盘
}

GD.RUI_INFO = {
    LOGIN = "/v1.2/login",
    LOGOUT = "/v1/logout",
    FACEBOOK_LOGIN = "/v1.2/connect/facebook", --接上fb sdk 后 换位v1.2接口测试 更换fb账号登录
    FACEBOOK_QUERY = "/v1/connected/facebook",
    BIND_FACEBOOK = "/v1/user/bind/facebook",
    SAVE_NICKNAME = "/v1/user/save",
    USER_BAG_INFO = "/v1/user/package",
    APPLE_LOGIN = "/v1.2/connect/appleid",
    --- 用户数据信息
    QUERY_USER_INFO = "/v1/user/query",
    SAVE_USER_INFO = "/v1/user/save",
    DATA_ACITON = "/v1/game/action", ---  发送log 数据接口
    HEARTBEAT_ACITON = "/v1/game/heartbeat", ---  发送心跳 数据接口
    --- 功能性接口
    TOURNAMENT_QUERY = "/v1/game/tournament/query", -- tournament 查询接口
    GET_UNREAL_MAIL = "/v1.1/mail/get", -- 获取未读邮件
    READ_MAIL = "/v1.1/mail/confirm", -- 读取邮件
    GET_MAIL_REWARD = "/v1.1/mail/read", -- 获取邮件奖励
    SERVER_TIME = "/v1.1/system/time",
    --- 支付相关操作
    PAY_GOOGLE_SUCCESS = "/v1/game/purchase/google",
    PAY_IOS_SUCCESS = "/v1/game/purchase/apple",
    PAY_AMAZON_SUCCESS = "/v1/game/purchase/amazon",
    PAY_COMMON_SUCCESS_V2 = "/v1/game/purchase/v2",
    -- 发送更新商城的请求
    QUERY_SHOP_CONFIG = "/v1/game/config/shop",
    -- 发送更新促销的请求
    QUERY_SALE_CONFIG = "/v1/game/config/sale",
    -- 获取游戏全局配置
    GAME_GLOBAL_CONFIG = "/v1/game/config/activity",
    -- 每日任务零点刷新
    QUERY_DAILY_MISSION = "/v1/game/daily/task",
    -- 多档促销活动弹出
    NOTIFY_MULTIPLE_ACTIVITY = "/v1/game/notify/events",
    QUERY_REPEATWIN_CONFIG = "/v1/game/config/features/repeatWin",
    --更新游戏活动数据
    QUERY_ACTIVITY_CONFIG = "/v1/game/config/features",
    --保存firebase token
    FIREBASE_TOKEN_SAVE = "/v1/game/firebasetoken/save",
    --没钱促销
    NOCOINS_SALE_CONFIG = "/v1/game/config/sale/nocoin",
    NOCOINS2_SALE_CONFIG = "/v1/game/config/sale/nocoinV2",
    --扩展登录请求
    EXTEND_LOGIN_REQUEST = "/v1/game/extend",
    --线上打印开关
    DEBUG_CODE_REQUEST = "/v1/game/debug",
    --商城和其他系统请求消息
    QUERY_COMMONCONFIG = "/v1/game/config/info",
    --更新活动任务数据
    QUERY_ACTIVITY_TASK = "/v1/game/config/features/activity",
    -- 新版pass活动跨天刷新
    QUERY_ACTIVITY_PASS = "/v1/game/config/features/newPass",
    -- 数据迁移——根据token恢复uuid
    RESTORE_TOKEN = "/v1.1/system/token/restore",
    -- 恢复删除账号
    RECOVER_DELETE_ACCOUNT = "/v1/game/undeleteuser",
    -- 关卡中grand 上传分享图片
    SLOT_GRAND_SHARE = "/v1/clan/jackpot/upload"
}

GD.ActionType = {
    Spin = 1, --Spin
    HourlyBonus = 2, --每小时领奖
    DailyBonus = 3, --日常任务奖励
    Rotary = 4, --转盘
    WatchVideo = 5, --观看视频广告
    LoginReward = 6, --登录奖励
    FacebookConnect = 7, --连接 facebook
    SyncUserInfo = 8, --同步用户信息
    TournamentReward = 9, --Tournament 领奖
    GetMailReward = 10, --领取邮件奖励
    TollgateEvaluation = 11, --关卡评价
    UpdateUserProfile = 12, --更新玩家信息（主要是 昵称和邮件地址）
    Questionnaire = 13, --调查问卷
    MissionCompleted = 14, --完成任务
    SpinV11 = 15, --Spin 1.1版本，优化tournament返回
    SetIcon = 16, --设置头像
    MissionUpdate = 17, --任务进度有更新
    LevelUp = 18, --升级奖励
    BonusGame = 19, --每小时奖励金币的小游戏
    SyncBuffInfo = 20, --同步buff信息
    SyncLevelUpRewardInfo = 21, --同步成长基金的信息
    --同步道具信息
    SyncItemInfo = 22,
    --从服务器端返回spin结果的新版spin
    SpinV12 = 23,
    --获取用户当前在该关卡中的状态
    GetGameStatus = 24,
    Bonus = 25,
    --Collect
    SpinV13 = 28, --客户端上传 spin 结果新版
    GetGameStatusV13 = 29, --客户端上传 spin 结果新版，获取关卡状态
    SpinV2 = 30, -- 有服务器端生成 数据结果
    GetGameStatusV2 = 31, -- 请求服务器数据时 请求的编号
    BonusV2 = 32, --客户端上传 bonus 选择结果
    VipUpdate = 33, --更新用户的vip 信息
    MissionCollect = 34, -- 任务收集接口
    ShopGiftCollect = 35, -- 商城领取礼包
    CashBonusCollect = 36, -- cash bonus 领取奖励
    --更新用户extra信息
    SyncUserExtra = 37,
    FindActResult = 38, --find活动结算
    FindNextRound = 39, --find下轮信息
    AdRewardCollect = 40, --领取广告奖励
    FindOneItem = 41, --find活动找到一个物品
    ChooseBooster = 42, --pigbank booster choose
    QuestChooseDifficulty = 43, --quest活动选择难度
    QuestPhaseReward = 44, --quest阶段关卡难度+奖励
    QuestRank = 45, --quest活动排名
    QuestNextStage = 46, --quest活动下一关
    BonusSpecial = 47, --
    NoCoinsAward = 48, --没有金币后增加奖励
    PushGiftCollect = 49, --通过推送获得的奖励
    LuckSpinAward = 50, --lucky spin 购买后再次购买的翻倍老虎机
    CashBonusVaultOpenBox = 51, --cashbonus小游戏开宝箱
    BingoPlay = 52, --bingo摇球
    HighLimitGetGameStatus = 53, -- 进入高倍场初始化
    HighLimitSpin = 54, -- 高倍场关卡 Spin
    HighLimitBonus = 55, -- 高倍场关卡 Bonus
    HighLimitBonusSpecial = 56, -- 高倍场关卡 BonusSpecial
    HighLimitCollectCoin = 57, -- 高倍场领取积分兑换金币
    LuckyStampCollectCoins = 58, --stamp领奖
    BingoRank = 59, --bingo排行榜
    LevelDashPlay = 61, --获取 levelDash 扑克牌数据
    LevelDashCollectCoins = 62, --收集 levelDash 奖励
    QuestWheelCollect = 63, -- quest 轮盘spin请求
    DefenderPlay = 64, --denfender掷骰子
    DefenderSkipTask = 65, --defender跳过任务
    DefenderRank = 66, --defender排行榜
    DefenderSpecialCollect = 67, --defender额外卡包奖励的请求
    QuestRankPointsRewardCollect = 68, -- quest排行星星消耗活动
    SpinBonusCollect = 69, --spinbonus 活动领取奖励
    NewUserGuide = 70, --新手引导
    BingoBallsRewardCollect = 71,
    --bingo活动领取奖励
    UserComment = 72,
    --rateus领奖
    CashVaultCollect = 73,
    MegaCashPlay = 74, -- MegaCash进行一次spin
    MegaCashCollect = 75, -- MegaCash结算
    DailyTaskAwardCollect = 76, -- 每日任务奖励领取
    NewUserQuestNextStage = 77, -- 新手quest下一个结算
    --使用BingoWild球
    BingoWildBallUse = 78,
    -- 购买食材袋
    DinnerLandBuyBag = 85,
    -- 制作食物
    DinnerLandMakeFood = 86,
    -- 餐厅排行榜
    DinnerLandRank = 87,
    -- 餐厅引导步骤
    DinnerLandGuide = 88,
    --luckychallenge排行
    LuckyChallengeRankList = 79,
    --luckychallenge获得奖励
    LuckyChallengeGetReward = 80,
    --luckychallenge pick小游戏
    LuckyChallengePickBoxPlay = 81,
    -- luckychallenge 小游戏
    LuckyChallengeDicePlay = 82,
    --luckychallenge 收集任务
    LuckyChallengeCollectTask = 83,
    --luckychallenge 收集任务
    LuckyChallengeTaskInfo = 84,
    --大富翁掷骰子
    RichPlay = 89,
    --大富翁怪物掷骰子
    RichMonsterPlay = 90,
    --打开blast宝箱
    BlastPickBox = 91,
    FriendGiftMails = 92,
    FriendSendGiftMail = 93,
    FriendCollectGiftMail = 94,
    FriendGiftCards = 95,
    --广告召回
    UserBackRewardCollect = 96,
    -- 获取Facebook好友数据
    FriendInfo = 97,
    --Bingo第二版接口
    BingoPlayV2 = 98,
    --刷新奖池
    DrawRefreshReward = 99,
    DrawCollectReward = 100, --领取奖池
    DrawPlay = 101, --抽奖
    UseTicket = 102, -- 使用折扣券
    WeekTreatCollect = 103,
    --刷新任务奖励
    DrawRefreshTask = 104,
    --字独排行榜
    WordRank = 105,
    WordPlay = 106, --字独摇一摇
    BattlePassCollect = 107,
    BattlePassGuide = 108,
    PusherDropCoins = 109,
    PusherGetCoins = 110,
    PigChallengeCollect = 111, --小猪挑战领取奖励
    FreeContinuousSales = 112, --连续充值免费奖励
    DailySignCollect = 114, --每日签到
    LuckyChallengeSkipTask = 115, --luckychallenge 使用钻石跳过任务
    QuestGemsSkipTask = 116, --quest 使用钻石跳过任务
    DailyTaskSkipTask = 117, --每日任务 使用钻石跳过任务
    BattlePassGemsSkipLevel = 118, --BattlePass 使用钻石跳过任务
    DailySignRefresh = 121, --日常签到跨天
    --lottoparty刷新数据
    TeamMissionData = 123,
    --lottoparty
    TeamMissionReward = 124,
    --lottoparty换房间
    TeamMissionReset = 125,
    HolidayChallengeRefresh = 119, --圣诞树挑战刷新任务
    HolidayChallengeCollect = 120, --圣诞树挑战奖励领取
    HighLimitUserExpBag = 113, -- 使用高倍场小游戏经验包
    HighLimitDailyReward = 122, --领取高倍场小游戏每日奖励
    ArenaRank = 126, --竞技场排行榜
    ArenaRankRewardCollect = 127, --竞技场上赛季排行榜奖励领取
    ArenaLastSeasonRank = 128, --上赛季竞技场排行榜
    ActivityMissionReward = 129, --活动任务奖励领取
    QuestChallengeReward = 130, --Quest挑战
    SpecialSaleMiniGame = 131, -- 常规促销小游戏
    LevelRushGameData = 132, --LevelRush获取数据
    -- RichGemsPlay = 133, -- 消耗宝石
    LevelRushGamePlay = 134, --LevelRush play
    LevelRushGameCollect = 135, --LevelRush 奖励领取
    NewUserProtectReward = 136, --新手登录直接送金币
    FirstSaleDownPrice = 137, --首购促销降档--用于没钱弹窗
    UserFacebookMail = 138, -- 保存facebook Email
    SlotChallengeCollect = 139, --关卡挑战奖励领取
    LevelRushGameRemove = 140, --LevelRush 小游戏删除
    DiningRoomOpenBag = 144, -- DiningRoom 开食材包
    DiningRoomMakeFood = 145, -- DiningRoom 制作食物
    DiningRoomOpenGift = 146, -- DiningRoom 开礼物箱
    TeamMissionOption = 141, --关卡团队任务玩家操作
    TeamMissionRefresh = 288, --关卡团队任务刷新房间
    ArenaSaleUseGem = 147, -- 比赛活动促销购买buff消耗钻石
    TeamMissionQuit = 148, --关卡团队任务玩家操作
    HatTrickCollect = 149, --帽子戏法领取
    DiningRoomRank = 150, --DiningRoom 餐厅排行榜
    ChurnReturnReward = 151, --流失回归奖励金币
    RichUseGems = 152, -- 大富翁 打狼关卡 消耗钻石锁定额外奖励
    LuckyStampCardReward = 155, -- 盖戳送卡活动领奖
    DiningRoomGuide = 156, -- DiningRoom 新手引导
    RedecorateBuild = 153, -- 装修创建风格
    RedecorateOpenTreasure = 154, -- 装修开礼盒
    RedecorateRank = 157, -- 装修排行榜
    RedecoratePass = 158, -- 放弃礼盒
    RippleDashCollect = 159, -- levelRush聚合挑战领奖
    TeamMissionStore = 160, --关卡选择阵营
    FreeGameActivate = 161, -- //激活免费游戏
    RedecorateFullView = 162, -- 旧轮次的装修界面
    RedecorateChangeStyle = 163, -- 旧伦次更换风格
    PassLevelCollect = 164, -- // 领取新版pass奖励
    PassTaskCollect = 165, -- // 领取新版pass任务奖励
    PassTaskGemsSkip = 166, -- // 宝石跳过pass任务
    PassGemBuySale = 167, --// 宝石购买pass促销
    PassRefreshTask = 168, --   // 刷新pass任务
    RedecorateNodeStyle = 169,
    TwoYearsSignCollect = 170, -- 领取2周年签到
    FirstSaleResult = 171, -- 获取首购促销数据
    NewPassGuide = 172, -- //pass引导计数
    CashBonusMultiply = 173,
    -- 请求增倍器数据
    MemoryFlyingReward = 174, -- 六个箱子领奖
    TeamMissionJoin = 175,
    --关卡选择房间座位
    MailRewardData = 176, -- 邮箱收集
    -----------高倍场 合成游戏相关---------start----------
    HighLimitMergeUploadMap = 177, --//高倍场游戏-合图-上传地图
    HighLimitMergeBuyMaterial = 178, --//高倍场游戏-合图-购买材料（宝石或第二货币）
    HighLimitMergePlay = 179, --//高倍场游戏-合图-合成材料
    BlastRank = 180, -- blast 请求排行榜数据
    WordPlayMaya = 181, -- word小游戏挖宝接口
    HighLimitMergeOpenBag = 183, --//高倍场游戏-合图-开礼包
    CashBackRefresh = 184,
    -- 刷新cashback
    HighLimitMergeDailyReward = 185, --//高倍场游戏-合图-领取每日奖励
    HighLimitMergeRank = 186, --//高倍场游戏-合图-排行榜
    HighLimitMergePutMaterial = 189, --//高倍场游戏-合图-一键铺满
    RichRank = 192, -- 大富翁排行榜
    HighLimitMergeCollect = 193, --//高倍场游戏-合图--收集进城堡
    -----------高倍场 合成游戏相关-----------end--------
    MandatoryAnnouncement = 187, -- 强制公告
    FacebookRewardData = 188, --绑定fb奖励
    ReturnSignCollect = 190, -- 回归签到领取
    FacebookAttentionData = 191, --FB200K奖励
    CoinPusherRank = 194, -- 推币机排行榜
    ----------------- 乐透 -----------------
    LotteryCollect = 199, -- 乐透领取奖励
    LotteryHistory = 200, -- 乐透历史开奖
    LotteryMachine = 201, -- 乐透获取机选号码
    LotterySubmit = 202, -- 乐透提交选号
    ----------------- 乐透 -----------------
    PickStarData = 203, -- StarPick小游戏点击
    PokerDeal = 204, -- 扑克 play
    PokerDraw = 205, -- 扑克 换牌 + collect
    PokerDouble = 206, -- 扑克 double or nothing玩法
    PokerGemBack = 209, -- 扑克赎回本金
    ------------PokerRecall----------------
    PokerRecallPlay = 207, --翻牌小游戏Play
    PokerRecallReward = 208, --翻牌小游戏领奖
    ------------PokerRecall---------------
    PokerRank = 217,
    ------------bingo比赛相关---------------
    BingoRushEnterRoom = 210, -- Bingo挑战-加入房间
    BingoRushQuitRoom = 211, -- Bingo挑战-退出房间
    BingoRushStatus = 212, -- Bingo挑战-刷新房间状态
    BingoRushSpin = 213, -- Bingo挑战-Spin
    BingoRushCollect = 214, -- Bingo挑战-收集奖励
    BingoRushPassCollect = 215, -- Bingo挑战-pass收集奖励
    BingoRushRank = 216, -- Bingo挑战-排行榜
    BingoRushContinueResult = 230, -- Bingo挑战-跳过本次结算
    ------------bingo比赛相关---------------
    JillionJackpotPlay = 224, -- 公共jackpot
    ----------------- 乐透 -----------------
    LotteryChallengeCollect = 218, --乐透挑战领取奖励
    LotteryExtraCollect = 219, --乐透送奖
    -- 每日刷新
    DailyRefresh = 220,
    BirthdayRewardData = 222, --生日奖励领取
    MergeWeekCollect = 223, --合成周卡奖励领取
    --占卜GEM第二货币 占卜促销花费宝石
    DivineGem = 225,
    CoinPusherPassReward = 232, --推币机PASS奖励领取
    QuestSaleGems = 233, -- quest促销 消耗第二货币
    WildChallengeCollect = 235, --付费挑战领奖
    ------------- DuckShot -----------------
    DuckShotPlay = 195, -- 激活
    DuckShotCollect = 196, -- 发射
    DuckShotHit = 197, -- 发射是否命中
    DuckShotClear = 198, -- 未付费清除数据
    ------------- DuckShot -----------------
    PigDishRewardData = 236, -- 小猪轮盘
    -- 鲨鱼
    AdventurePlay = 227, -- 4选1小游戏play
    AdventureRewardData = 228, -- 4选1小游戏领奖
    AdventureGemConsume = 229, -- 4选1小游戏消耗宝石
    AdventureClearData = 231, -- 4选1小游戏清除数据
    NiceDiceCollect = 237, -- 新版签到优惠券-领取
    ------------- Invite -----------------
    InviteePassCollect = 242, -- 被邀请者领奖
    InviterCollect = 243, -- 邀请者领奖
    InviteData = 244, -- 获取数据
    InviteLink = 245, -- 邀请关系
    InviteShareCollect = 247, -- 分享链接奖励
    -- 头像框
    AvatarFrameGamePlay = 234, --头像框小游戏
    AvatarFrameHotPlayer = 238, --头像框热玩玩家
    FacebookShareCollect = 246, -- 1000w fb分享领取优惠券
    ------------- pig freebuy -----------------
    PigFreeBuy = 248, -- 小猪免费购买
    ------------- pig freebuy -----------------
    PaintPlay = 226, -- PaintPlay 涂色play
    SmashHammerSmashIt = 239, -- 每日任务领优惠券活动-砸锤子
    SmashHammerRewordExchange = 240, -- 每日任务领优惠券活动-积分商城道具兑换
    SmashHammerPointsShopReset = 241, -- 每日任务领优惠券活动-积分商城道具重置
    CapsuleToysPlay = 252, -- 1000W扭蛋机
    AdIncentiveCollect = 253, -- 激励广告领奖
    FLowerInitReward = 265, --初始化奖励信息
    FlowerWaterFlower = 266, --浇花
    FlowerUpdateGuide = 281, --浇花引导
    FlowerStartWaterDay = 282, -- 浇花日
    FlowerCollectCoins = 287, -- 金币领取
    FlowerInitPayInfo = 264,
    --------------- CashMoney ------------------
    CashMoneyPlay = 249, -- 玩CashMoney小游戏
    CashMoneyCollect = 250, -- CashMoney领取奖励
    CashMoneyClear = 251, -- CashMoney流程结束清除数据
    CashMoneyTake = 261, -- CashMoney记录通用小游戏里Take状态
    --------------- CashMoney ------------------
    VegasTripCollect = 254, -- 新手七日目标领取
    CompeteRank = 255, -- 获取比赛聚合排行榜列表
    CompeteCollect = 256, --领取比赛聚合排行榜奖励
    NewDoubleSaleGiveUp = 283, -- 新版二选.一放弃
    AvatarFrameDetail = 285, --头像框个人信息
    RecoverAccount = 262,
    --删除回复账号
    ---------------------- 快速点击小游戏----------------------
    PiggyClickerCollect = 271, -- 快速点击小游戏结束领奖
    PiggyClickerSave = 272, --保存数据，断线重连
    PiggyClickerClear = 273, -- 删除数据
    PiggyClickerGenerate = 274, -- 快速点击小游戏开始
    ---------------------- 快速点击小游戏----------------------
    -- 集卡商城
    CardStoreV2RefreshStore = 268, --//集卡商店刷新商店
    CardStoreV2FreeGetGift = 269, --//集卡商店免费礼物领取
    CardStoreV2Exchange = 270, --//集卡商店兑换
    CardStoreV2UpdateShowGuide = 295, --//集卡商店上赛季结算引导
    -- 集卡鲨鱼
    CardAdventurePlay = 275, -- 集卡鲨鱼小游戏play
    CardAdventureRewardData = 276, -- 集卡鲨鱼小游戏领奖
    CardAdventureGemConsume = 277, -- 集卡鲨鱼小游戏消耗宝石
    CardAdventureClearData = 278, -- 集卡鲨鱼小游戏清除数据
    BingoRushNoCoinSaleData = 267, -- 获取BingoRush没钱促销数据
    SurveyReward = 279, -- 问卷领奖
    ScratchCardScratch = 257, -- 刮刮刮卡
    ScratchCardFreeGet = 258, -- 刮刮卡免费领取
    ScratchCardOpenFresh = 259, -- 刮刮卡打开界面刷新
    ScratchCardClose = 260, -- 刮刮卡界面关闭
    MemoryLaneCollectReward = 284, --三周年分享挑战领奖
    --弹珠小游戏
    PinballPlay = 262, --弹球小游戏play
    PinballCollect = 263, --弹球小游戏领奖
    PinballHitGrid = 280, --弹球小游戏 命中格子
    -- 新版大富翁
    WorldTripPlay = 289, -- 新版大富翁 掷骰子
    WorldTripRecallPlay = 290, -- 新版大富翁 小游戏掷骰子
    WorldTripRecallEnd = 291, -- 新版大富翁 领取小游戏奖励
    WorldTripRecallResurrection = 292, -- 新版大富翁 小游戏复活
    WorldTripCollectChapterReward = 293, -- 新版大富翁 领取章节奖励
    WorldTripRank = 294, -- 新版大富翁 获取排行榜数据
    TwoChooseOneGiftCollectReward = 305,
    OnePlusOneSaleCollectFreeReward = 309,
    InflateConsumeCollect = 304, -- 膨胀消耗活动领取奖励
    LuckFishActivate = 296, -- luckfish激活
    LuckFishPlay = 297, -- luckFish玩
    LuckFishCollect = 298, -- luckFish领奖
    BingoPlayZeus = 286, -- bingo宝藏小游戏
    OneDaySpecialMissionRefresh = 310, -- 单日特殊任务数据刷新
    ChristmasTourDepositCollect = 313, -- 聚合保险箱收集奖励
    NewCoinPusherDropCoin = 299, --新推币机金币掉落
    NewCoinPusherGetCoin = 300, --新推币机金币掉下台面
    NewCoinPusherRank = 301, --新推币机排行榜
    NewCoinPusherPassReward = 302, --新推币机挑战奖励
    NewCoinPusherPlayFruitMachine = 303, --新推币机水果机
    AvatarFrameFavorite = 306, --喜欢的头像框
    LuckyStampV2Collect = 307, -- LuckyStampV2领奖
    LuckyStampV2Play = 308, -- LuckyStampV2抽奖
    DartsGamePlay = 312, --飞镖小游戏spin
    DartsGameEnd = 318, --飞镖小游戏结算
    DartsGameReward = 319, --飞镖小游戏领奖
    -- 巅峰赛
    PeakArenaRank = 314, --巅峰竞技场排行榜
    PeakArenaRankRewardCollect = 315, --巅峰竞技场上赛季排行榜奖励领取
    PeakArenaLastSeasonRank = 316, --上赛季巅峰竞技场排行榜
    PeakArenaLastRewardRank = 327, --领奖时上赛季排行榜
    CrazyShoppingCartShare = 334, --疯狂购物车分享
    CrazyShoppingCartCollect = 335, --疯狂购物车领奖
    FactionFightSideSelect = 328, -- 红蓝对决选择阵营
    FactionFightCollect = 329, -- 红蓝对决收集进度奖励
    FactionFightRank = 332, -- 红蓝对决排行榜
    FactionFightRefresh = 333, -- 红蓝对决刷新阵营数据
    FactionFightBuySale = 345, -- 红蓝对决购买促销
    BlackFridayLotteryCollect = 358, --黑五活动代币抽奖
    ChristmasCalendarSignIn = 348, --圣诞台历签到
    ChristmasCalendarCollect = 349, --圣诞台历领奖
    BindPhone = 360, --绑定手机
    -- 商城最高档位付费后促销礼包功能
    StoreUpscaleSaleUpdate = 363, -- 商城高档促销更新数据
    PassTaskGemsRefresh = 320, -- 花费宝石刷新pass任务
    DailyTaskGemsRefresh = 321, -- 花费宝石刷新每日任务
    CollectionLevelGet = 367, --获取收藏关卡列表
    CollectionLevelSave = 368, --收藏关卡
    CollectionLevelDelete = 369, --移除收藏
    UserFriends = 337, -- 好友列表
    FriendCommond = 342, -- 推荐列表
    UserFriendSearch = 343, --搜索好友
    UserFriendOperate = 341, --好友申请
    UserFriendRecommend = 342, -- 好友推荐列表
    UserFriendSendCardMail = 344, -- 处理好友请求卡，邮箱送卡送钱，接受别人送卡
    UserFriendAddInfo = 338, --好友申请列表
    UserFriendCardList = 340, --主动要卡和被要卡列表
    UserFriendApplyCard = 339, --向好友要卡
    NewSlotChallengeCollect = 361, -- 新版新关挑战领奖
    ActivityMissionV2Collect = 330, --新版大活动任务领奖
    AccumulatedRechargeGet = 372, --累充获取数据
    -- 前7日大于40级且主动点开付费界面大于等于4次
    SevPurchaseLevelClick = 373,
    AnnualSummaryShare = 366 ,--//年终总结分享领奖
    EndYearRewardCollect = 370 , -- 年终送奖领取
    -- 新版Quest 梦幻Quest
    FantasyQuestRank = 322, -- 请求fantasyQuest排行版信息
    FantasyQuestCollectGift = 323, -- 领取关卡礼盒
    FantasyQuestCollectStarMeters = 324, -- 领取startMeter
    FantasyQuestGetPool = 325, --  获取link jackpot金币
    FantasyQuestPlayWheel = 326, --  play轮盘
    FantasyQuestNextRound = 336, --  quest 切换下一轮
    FantasyQuestCollectWheelReward = 346, -- fantasyQuest领取轮盘奖励
    FantasyQuestSaleGem = 347, --fantasyQuest促销第二货币购买
    FarmSowing = 350,   -- 农场-播种
    FarmHarvest = 351,  -- 农场-收获
    FarmRipen = 352,    -- 农场-立即成熟
    FarmSell = 353,     -- 农场-出售
    FarmBuy = 354,      -- 农场-购买
    FarmFriends = 355,  -- 农场-获取好友列表
    FarmDailyRewardCollect = 356,   -- 农场-领取每日奖励
    FarmInfoUpdate = 357,   -- 农场-修改信息
    FarmSteal = 362,        -- 农场-偷菜
    FarmFriendFarm = 364,   -- 农场-好友农场信息
    FarmStealRecord = 365,  -- 农场-偷取记录
    FarmGuide = 359,  -- 农场-新手引导
    NewUserBlastPickBox = 379 , -- 新手blast点击宝箱
    PipeConnectJigsawPlay = 381, -- 接水管小游戏play
    PipeConnectRank = 382, -- 接水管排行榜
    PipeConnectPlay = 380, -- 接水管老虎机play
    SuperBowlRechargeCollect = 384, --//超级碗个人累充领奖
    NewUserChargeCollect = 386, -- 新手期个人累充
    DartsGameV2Play = 388, --飞镖小游戏spin
    DartsGameV2Skip = 389, --飞镖小游戏结算
    DartsGameV2Collect = 390, --飞镖小游戏领奖   
    NewUserPassTaskCollect = 375,-- 新手pass 领取任务奖励
    NewUserPassRefreshTask = 376,-- 新手pass 刷新任务
    NewUserPassGuide = 377,--/新手pass 新手引导
    NewUserPassLevelCollect = 378,-- 新手pass 领取pass奖励
    NewUserPassTaskGemsRefresh = 385 ,--新手pass 花费宝石刷新pass任务
    BlastPick = 387, --//blast三选一
    NoviceCheckSignIn = 374, --新手期签到
    ChristmasTourWheelPlay = 391, -- 聚合挑战转盘
    OptionalTaskCollect = 392, -- 自选任务领奖
    ShortCardDrawFree = 395, -- 黑曜卡免费抽奖
    OptionalTaskGetConfig = 396, -- 自选任务获得配置
    ExpandCircleActive = 397, --扩圈系统 激活
    ExpandCirclePyiCollect = 398, --扩圈系统 跑马灯游戏
    ExpandCirclePyiNext = 399, --扩圈系统 跑马灯下一关
    VipPointsPoolFirst = 400, -- vip点数池首次弹窗后调
    LimitedGiftCollect = 401,   -- 限时礼包领取
    GrowthFundCollect = 402, -- 成长基金领奖
    MonthlyCardCollect = 394, --月卡领取每日奖励
    BigWinChallengeCollect = 393, --bigwig
    ChristmasTourRank = 404 ,--/圣诞树聚合排行榜
    WildDrawFreeDraw = 407, -- 集卡赛季末抽卡免费抽卡
    QuestPassCollect = 403,  -- quest pass领奖
    QuestPassCollectBox = 408, -- quest pass领宝箱
    ChaseForChipsInfo = 409, -- 获取集卡小聚合活动信息
    ChaseForChipsCollectReward = 410, -- 集卡小聚合pass领奖    
    ExpandCircleTqCollect = 411, --扩圈系统 弹球游戏
    ExpandCircleTqNext = 412, --扩圈系统 弹球下一关
    TopUpBonusCollect = 414, --个人累充Plus领奖
    TopUpBonusWheelPlay = 415, --个人累充Plus转盘抽奖
    IceBrokenSaleCollect = 416, -- 限时礼包领取
    TopUpBonusRefresh = 417, --个人累充Plus数据刷新
    GemMayWinSpin = 423,    -- 第二货币抽奖
    CardAdventureGiveUpAgain = 427, -- 鲨鱼游戏放弃在选一次
    NewUserFreeContinuousSales = 431, --新手连续充值免费奖励
    HourDealDraw = 428, -- 限时抽奖
    GetMorePayLessCollect = 430, -- 付费目标领奖
    NewUserMemoryFlyingReward = 434, --新手六个箱子领奖
    NewUserLimitedGiftCollect = 436, --新手限时礼包领取
    NewUserInflateConsumeCollect = 437, --新手膨胀消耗活动领取奖励
    ZombiePrebookConfig = 435, -- 行尸走肉预约
    MagicGardenFreeDraw = 432,  -- 合成促销免费抽奖
    MagicGardenCollect = 433,   -- 合成促销领奖
    MinzBuyBag = 413, --minz系统购买宝箱
    TriplexPassLevelCollect = 429, --  3行pass领取pass奖励
    ZombieBuySale = 418, --行尸走肉买促销
    ZombieCancelRecoverArms = 419, --行尸走肉取消回收武器
    ZombieStartAttack = 420, --行尸走肉开始进攻
    ZombieInfo = 421, --行尸走肉活动信息
    ZombieCollectReward = 422, --行尸走肉领奖接口
    GemChallengeCollect = 443,  -- 第二货币消耗挑战领取奖励
    ClanDuelRank = 438, -- 公会限时比赛 获取排行榜
    DiamondManiaCollect = 444, -- 钻石挑战活跃活动领奖
    TimeBackClose = 448, -- 返回最大持金关闭弹板通知
    GrowthFundV3Collect = 450, -- 成长基金领奖V3
    NewUserActivityMissionReward = 451,  -- Bingo活动任务奖励领取
    ReturnPassLevelCollect = 424, -- 回归领取pass奖励
    ReturnSignV2Collect = 425, -- 回归签到 v2
    ReturnTaskCollect = 426, -- 回归签到 v2 任务领取    
    BirthdayInformationModify = 447, -- 生日信息修改
    BirthdayCollect = 449, --生日礼品领取
    DragonChallengePlay = 452, -- 组队打boss play
    DragonChallengeBuyBuff = 453, -- 组队打boss buff购买
    DragonChallengeRefresh = 454, -- 组队打boss 刷新
    HighLimitMergeOneClick = 455, -- //合成优化 一键合成 快速合并
    NewUserWildChallengeCollect = 456, --新手期付费挑战领奖
    PayRankRefresh = 457, -- 付费排行榜刷新
    BackWheelPlay = 458, -- 回归转盘抽奖
    StoreStayCouponActivate = 459, -- 商城停留送优惠券激活
    NewUserTriplePassGuide = 460, -- 新手三行pass 新手引导
    NewUserTriplePassLevelCollect = 461, -- 新手三行pass 领取pass奖励
    NewUserTriplePassRefreshTask = 462, -- 新手三行pass 刷新任务
    NewUserTriplePassTaskCollect = 463, -- 新手三行pass 领取任务奖励
    NewUserTriplePassTaskGemsRefresh = 464, -- 新手三行pass 花费宝石刷新pass任务
    NoviceTrailCollect = 467, -- 新手三日任务领奖
    NoviceTrailRefresh = 475, -- 新手三日任务刷新
    LuckSpinEnjoy = 470, -- luck spin 小老虎机 先享后付费
    PigFamilyData = 465, -- 集卡pig相关信息返回
    GrandFinaleCollect = 468, -- 集卡赛季末送新卡领取
    ActivityInfoRefresh = 311, -- 公共活动数据刷新接口
    GrandFinaleRefresh = 469, -- 集卡赛季末送新卡刷新
    FreeKeepRechargeSales = 476, -- 四档连续充值免费奖励
    PearlsLinkRewards = 471, --pearls link领奖接口
    PearlsLinkActivateGame = 472, --pearls link进入游戏接口
    PearlsLinkReSpin = 473, --pearls link的reSpin
    FourBirthdayDrawCollect = 482, -- 四周年抽奖+分奖领奖
    LevelRoadCollect = 495, -- 等级里程碑领奖
    LevelRoadValidation = 493, -- 等级里程碑小游戏效验完成免费任务
    LevelRoadReward = 494, -- 等级里程碑小游戏领奖
    BlastBombBox = 474, -- 点击炸弹
    DiyFeaturePlay = 499, -- Diy 抽取Buf
    DiyFeatureBuffSaleClear = 519, -- Diy
    -- 最低300bet没金币奖励
    MinBetNoCoinsAward = 485,
    LevelUpPassCollect = 483, -- level up pass领奖
    MythicGamePlay = 479, -- MythicGame play
    MythicGameCollect = 480, -- MythicGame领奖
    MythicGameClear = 481, -- MythicGame清除数据
    QuestCostSkipItem = 478, --  花费skip道具 跳关
    PearlsLinkPayLater = 489, -- pearlsLink先想后付钱
    PearlsLinkValidationFinish = 505,
    LuckyRaceCollect = 486, -- 单人限时比赛领奖
    TomorrowGiftCollect = 477, -- 次日礼物领奖
    LuckyRaceRefresh = 487, -- 单人限时比赛刷新
    LuckyRaceBuyBuff = 488, -- 单人限时比赛促销buff购买
    LuckyRaceJoin = 500, --单人限时比赛响应
    ZombieCollectRecycleCoins = 490, --zombie 领取回收金币
    ZombieTimePause = 491, --行尸走肉时间暂停
    ZombieCancelTimePause = 492, --行尸走肉取消时间暂停
    QuestJackpotWheelInfo = 466, -- 获取quest转盘数据
    NewUserGuideCollect = 508, -- 新手任务领取奖励
    CouponRewardsCollect = 512, -- 三联优惠券领奖
    PiggyGoodiesReward = 513, --  新版小猪挑战 领奖
    LuckySpinV2Spin = 509, --spin
    LuckySpinV2Enjoy = 510, --先享后付
    DiyFeatureMissionCollect = 511, -- diyFeature 新手任务领取
    DiyFeatureMissionData = 520, -- diyFeature新手任务数据
    OutsideGaveHammerPlay = 527, --咋龙蛋
    OutsideGaveWheelPlay = 529, --大富翁转盘
    OutsideGavePlay = 525, --大富翁spin
    UserRank = 526, -- 用户排行榜
    OutSideGavePropsLimitGemsBuy = 531, -- 大富翁消耗钻石提升spin掉落道具数限制
    OutsideGaveHammerCollect = 536, --大富翁活动砸龙蛋领奖
    NoviceCheckV2Collect = 515, -- 新手七日签到V2领取奖励
    BlindBoxNext = 501, -- 集装箱大亨刷新下个箱子
    BlindBoxOpen = 502, -- 集装箱大亨开箱
    JewelManiaPlay = 496,
    JewelManiaPlaySpecialChapter = 497,
    JewelManiaRefresh = 498,
    JewelManiaCollect = 514, -- 挖矿挑战领奖
    MergePassCollect = 521, -- 合成pass领奖
    MergePassCollectBox = 523, -- 合成pass保险箱领奖
    ExchangeCodeCollectReward = 524, --礼物兑换码领奖
    DragonChallengePassReward = 503, -- 组队打boss Pass部分
    FlameClashData = 504 , -- 膨胀消耗1v1比赛数据刷新
    FlameClashReward = 506, -- 膨胀消耗1v1比赛结算奖励领取
    FlameClashFailedRetain = 507, -- 膨胀消耗1v1比赛失败保留净胜
    FlameClashStageCollect = 522, -- 膨胀消耗1v1比赛胜场奖励领取
    LuckyChallengeV2Exchange = 539, -- LuckyChallengeV2兑换商品
    LuckyChallengeV2Rank = 540, -- LuckyChallengeV2排行榜
    LuckyChallengeV2ChooseGame = 543, -- LuckyChallengeV2选择关卡
    LuckyChallengeV2Skip = 544, -- LuckyChallengeV2跳过
    LuckyChallengeV2Refresh = 545, -- LuckyChallengev2刷新
    LuckyChallengeV2GameReward = 546, -- 钻石挑战LuckyChallengeV2 小游戏领奖
    LuckyChallengeV2TaskCollect = 548, -- LuckyChallengeV2任务领奖
    LuckyChallengeV2PassCollect = 549, -- LuckyChallengeV2Pass领奖
    LuckyChallengeV2DailyRefresh = 551, --主动刷新任务
    LuckyChallengeV2TimeLimitCollect = 550, --LuckyChallengeV2限时活动领奖
    TrillionsWinnerChallengeCollect = 528, -- 亿万赢家挑战任务奖励
    TrillionsWinnerChallengeRank = 530, -- 亿万赢家挑战排行榜
    GoBrokeSaleBuffReward = 541, -- 新破产促销buff金币领奖
    GoBrokeSaleShowClose = 547, -- 新破产促销弹窗关闭
    FunctionSaleInfiniteCollect = 516, -- 大活动促销-无限促销领奖
    FunctionSalePassCollect = 517, -- 大活动促销-pass领奖
    -- AppCharge用代金券支付领取奖励
    AppChargeCollectReward = 538,
    HolidayNewChallengeAdventRedeemSignIn = 559, -- 圣诞节聚合补签
    HolidayNewChallengeAdventCollectReward = 560, -- 每日签到领奖
    HolidayNewChallengeSideGameCollectReward = 561, -- 圣诞新聚合小游戏领奖
    HolidayNewChallengeGoodsPurchase = 563,--圣诞新聚合商品购买
    HolidayNewChallengeSideGameEnterGame = 565, -- 圣诞新聚合小游戏 进入小游戏
    HolidayNewChallengeSideGamePlay= 566, -- 圣诞新聚合小游戏进入游戏
    HolidayNewChallengeSideGameAddSeconds = 568, --  圣诞新聚合小游戏 记录玩家玩到第几秒
    HolidayNewChallengePassCollectReward = 571, -- 圣诞新聚合pass领奖
    CrazyWheelPlay = 556, -- 抽奖转盘的play接口
    CrazyWheelPayCoupon = 557, -- 抽奖转盘买劵接口
    CrazyWheelCollectReward = 558, -- 抽奖转盘领奖接口    
    TreasureHuntCollect = 537, -- 寻宝之旅领奖
    RoutineSaleWheelGetReward = 552, -- 新版常规促销轮盘领奖
    MailLotteryGetMail = 554, -- 邮箱抽奖获取邮箱
    SidekicksLevelUp = 580, -- 宠物系统 使用升级道具
    SidekicksStarUp = 581, -- 宠物系统 使用升星道具
    SidekicksDailyRewardCollect = 582, -- 宠物系统 每日奖励
    SidekicksPetRename = 585, -- 宠物系统 宠物重命名
    HolidayNewChallengeRank = 572, -- 圣诞新聚合排行榜
    HolidayNewChallengePassTaskRefresh = 583, -- 圣诞新聚合刷新pass任务
    MessagePushCollectReward = 574, -- 消息推送领奖接口
    BlastCollectReward = 569, --blast收集奖励
    CoinPusherV3DropCoin = 532, -- 推币机V3金币掉落
    CoinPusherV3GetCoin = 533, -- 推币机V3金币掉下台面
    CoinPusherV3GameSpin = 535, -- 推币机V3Spin
    CoinPusherV3GetSpin = 542, -- 推币机V3获得Spin次数
    CoinPusherV3CollectReward = 555, -- 推币机V3领取收集的奖励
    MissionsToDiyTaskReward = 573, -- 圣诞装饰任务领奖
    MissionsToDiySaveSteer = 577, -- 圣诞装饰任务存储引导数据
    MissionsToDiyRefreshData = 579, -- 圣诞装饰任务刷新
    BlindBoxRank = 562, -- 集装箱大亨排行榜
    BlindBoxMissionReward = 564, -- 集装箱大亨任务领奖
    BlindBoxPassReward = 567, -- 集装箱大亨pass领奖
    BlindBoxGetData = 570, -- 集装箱大亨获取数据
    OneDaySpecialMissionTaskReward = 578, -- 单日特殊任务领奖
    HolidayNewChallengeCrazeRefresh = 587, -- 圣诞充值分奖
    PassMysteryBoxCollect = 584, -- pass神秘宝箱领取
    CollectPhoneProcess = 586, --收集手机号处理验证码
    -- OtpDeepLink跳转带上code接口
    OtpDeepLink = 589,
    MegaWinCollectReward = 575, --大赢宝箱领奖
    MegaWinDealExtraBox = 576, --大赢宝箱处理额外宝箱
    PetMissionMissionReward = 590, -- 宠物7日任务领奖接口
    PetMissionPet = 591, -- 宠物7日任务宠物互动
    PetMissionPointReward = 592, -- 宠物7日任务点数领奖接口
    PetMissionAllReward = 593, -- 宠物7日任务一键领奖接口
}

GD.ExtraType = {
    signInfo = "signInfo", --登录信息
    fbConnect = "fbConnect", --fb登录
    pig = "pig", --小猪金钱
    pigIndex = "pigIndex", --小猪等级
    pigTimes = "pigTimes", --小猪领取时间
    taskInfo = "taskInfo", --任务
    hourlyBonus = "hourlyBonus", --每小时奖励
    winContral = "winContral", --
    icon = "icon", --头像
    operaId = "operaId", --记录每一关 operaId
    updataUI = "updateUI", --更新ui
    questData = "questData", --quest信息
    averageBet = "averageBet", --平均bet
    reliefTimes = "reliefTimes", --救济金 次数
    shopLevelBurst = "shopLevelBurst", -- 商城buff
    shopBonus = "shopBonus", -- 每日奖励
    spinAccumulation = "spinAcc",
    tasksDailyData = "tasksDailyData", -- 每日任务信息
    tasksDailyTime = "tasksDailyTime", -- 每日任务时间
    tasksCollectPoints = "tasksCollectPoints", -- 每日任务收集点数
    tasksCollectstate = "tasksCollectstate", -- 每日任务收集状态
    tasksCoinsBurstId = "tasksCoinsBurstId", -- 每日任务奖励抽成buff
    newPeriod = "newPeriod", -- 新手期信息
    mulReward = "mulReward", --多倍奖励信息
    custTime = "custTime", --首次进入关卡时间
    custDebugData = "custDebugData", --关卡内测试数据
    newbieTask = "newbieTask",
    --新手任务
    NoviceGuideFinishList = "NoviceGuideFinishList", --新手引导
    rateUsData = "rateUsData",
    OperateGuidePopup = "OperateGuidePopup", -- 运营引导弹板 点位次数List
    OperateGuidePopupSiteCD = "OperateGuidePopupSiteCD", -- 运营引导弹板 点位CdList
    OperateGuidePopupCD = "OperateGuidePopupCD", -- 运营引导弹板 cdList
    DEFENDER_GUIDE_START = "DEFENDER_GUIDE_START", --defender 教程开始
    cashMoneyTake = "cashMoneyTake", -- cashbonus 钞票小游戏是否点击过take按钮
    LuckyChallengeGuide = "LuckyChallengeGuide", -- luckychallenge引导
    BingoExtra = "BingoExtra",
    --头像信息
    HeadName = "HeadName",
    avatarFrameId = "Frame", -- 头像框
    isPuzzleGameBuyMore = "isPuzzleGameBuyMore", -- 是否打开了buymore界面
    CoinPusherGuide = "CoinPusherGuide", --推币机新手引导
    puzzleGuideStepId = "puzzleGuideStepId", -- 集卡小游戏引导步骤
    LastUpdateNickNameTime = "lastUpdateNickNameTime", -- 用户上次换名的时间戳
    mergeGameGuideStepId = "mergeGameGuideStepId", -- 高倍场合成游戏引导步骤
    NewCoinPusherGuide = "NewCoinPusherGuide", -- 新推币机引导步骤
    showVipResetYear = "showVipResetYear", -- vip重置（折扣）界面一年显示一次
    PassMissionRefreshGuide = "PassMissionRefreshGuide", -- 每日任务，任务页签，刷新按钮引导
    PassRewardSafeBoxGuide = "PassRewardSafeBoxGuide", -- 每日任务，奖励页签，奖励最终宝箱提示引导
    NewYearGiftSubmit = "NewYearGiftSubmit",
    QuestNewGuideId = "QuestNewGuideId", -- 新Quest最后一步引导步骤
    QuestNewGuideData = "QuestNewGuideData", -- 新Quest 新版引导 记录数据
    PipeConnectGuideData = "PipeConnectGuideData", -- 接水管 新版引导 记录数据
    NewUserBlastPop = "NewUserBlastPop",
    MermaidOpN = "MermaidOpN", -- 一抵n
    MermaidHg = "MermaidHg", -- 高亮
    MermaidFirst = "MermaidFirst", -- 第一次出现事件
    ZomBieBord = "ZomBieBord", -- 分镜步骤
    ZomBieLine = "ZomBieLine", -- 离线过程
    NDCGuide = "NDCGuide", -- 新版钻石挑战引导
    DiyFeatureGuideData = "DiyFeatureGuideData", -- DiyFeature 新版引导 记录数据
    DiyFeatureGuideData_AllOver = "DiyFeatureGuideData_AllOver", -- DiyFeature 新版引导 记录数据 记录全结束
    EgyptCoinPusherGuide = "EgyptCoinPusherGuide", -- 埃及推币机引导步骤
    SidekicksGuideData = "SidekicksGuideData", -- 宠物引导数据
}

GD.GOOGLE_MARKET = "google" --必须跟android严格对应
GD.AMAZON_MARKET = "amazon"
GD.IOS_MARKET = "ios"
GD.MARKETSEL = GD.GOOGLE_MARKET

GD.HttpRequestType = {
    GET = 0,
    POST = 1,
    PUT = 2,
    DELETE = 3,
    UNKNOWN = 4
}

--设置服务器地址
-- function GD.setServerURL(log, hotUpdate, level, dynamic, dataURL)
--     GD.LOG_RecordServer = log --日志服地址
--     GD.Android_VERSION_URL = hotUpdate --热更服地址
--     GD.LEVELS_ZIP_URL = level --关卡下载地址
--     GD.DYNAMIC_DOWNLOAD_URL = dynamic --动态下载地址
--     if dataURL ~= nil then
--         GD.DATA_SEND_URL = dataURL --游戏服务器地址
--     end
-- end

--这块地址不要修改，切记切记，否则会导致线上用户无法热更
if CC_IS_RELEASE_NETWORK then
    -- 机器人头像
    GD.ROBOT_DOWNLOAD_URL = "https://res.topultragame.com/Robot"
    -- 默认地址
    GD.LOG_RecordServer = "https://log.topultragame.com/collector/v1"
    -- setServerURL(
    --     "https://log.topultragame.com/collector/v1",
    --     "https://res2.topultragame.com/SlotLasvega/version_android/",
    --     "https://res2.topultragame.com/SlotLasvega/Levels_Zip_102/",
    --     "https://res2.topultragame.com/SlotLasvega/DynamicDownload109/",
    --     "https://apinew.topultragame.com/support"
    -- )
    -- 数据服
    GD.DATA_SEND_URL = "https://apinew.topultragame.com/support"
    --热更服地址
    GD.Android_VERSION_URL = nil
    --关卡下载地址
    GD.LEVELS_ZIP_URL = nil
    --动态下载地址
    GD.DYNAMIC_DOWNLOAD_URL = nil
    -- 分享图片地址
    GD.GRAND_SHARE_IMG_URL = "https://pic.cashtornado-slots.com/"
else
    -- GD.DATA_SEND_URL = "http://192.168.1.62"
    -- --日志服地址
    -- GD.LOG_RecordServer = "http://192.168.1.51:80/v1/log"
    -- --机器人头像
    -- GD.ROBOT_DOWNLOAD_URL = "http://192.168.1.150/SlotNewRes/SlotCashLink_Test/Robot"
    -- 机器人头像
    GD.ROBOT_DOWNLOAD_URL = nil
    -- 默认地址
    GD.LOG_RecordServer = nil
    -- 数据服
    GD.DATA_SEND_URL = nil
    --热更服地址
    GD.Android_VERSION_URL = nil
    --关卡下载地址
    GD.LEVELS_ZIP_URL = nil
    --动态下载地址
    GD.DYNAMIC_DOWNLOAD_URL = nil
    -- 分享图片地址
    GD.GRAND_SHARE_IMG_URL = "http://d168spp4pjxmug.cloudfront.net/"
end
