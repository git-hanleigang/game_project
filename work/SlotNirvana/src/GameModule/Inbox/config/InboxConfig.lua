--[[
    邮件配置
]]
_G.InboxConfig = {}

-- todo:maqun 优化邮件服务器请求接口 
-- NetType.Inbox = "Inbox"
-- NetLuaModule.Inbox = "GameModule.Inbox.net.InboxNet"

-- 分组邮件展开和折叠的时间
InboxConfig.GroupFoldActionTime = 0.3
-- 分组中的邮件的上下间隔
InboxConfig.GroupItemIntervalH = 0
-- 分组打开后，底部占位
InboxConfig.GroupBottomEdageH = 20
-- 分组打开后，遮挡板多出的高度
InboxConfig.GroupMaskEdageH = 5

InboxConfig.CELL_WIDTH = 845 -- 最新的效果图是 844 旧的是855
InboxConfig.GROUP_CELL_WIDTH = 831 -- 分组中的cell的长度

-- 邮件种类 【数字做排序用】
InboxConfig.CATEGORY = {
    Coupon = 1, -- 促销类
    MiniGame = 2, -- 小游戏
    Payment = 3, -- 支付类
    Special = 4, -- 特殊
    Notice = 5, -- 通知类
    Award = 6, -- 奖励类
}

-- 邮件分组，分组名以及显示优先级
-- 邮件分组与邮件种类拆开配置，以方便分组中组合不同类型的邮件
InboxConfig.GROUP = {
    {name = "coupon", zOrder = 1, categorys = {InboxConfig.CATEGORY.Coupon}, titleLua = "InboxGroup_coupon", height = 123, unfold = false},
    {name = "miniGame", zOrder = 2, categorys = {InboxConfig.CATEGORY.MiniGame}, titleLua = "InboxGroup_miniGame", height = 120, unfold = false},
}

-- 本地邮件自定义id
InboxConfig.getGroupMailId = function(_name)
    local startIndex = 100000
    local index = 0
    local t = InboxConfig.GROUP
    for i=1,#t do
        if t[i].name == _name then
            index = i
            break
        end
    end
    return startIndex + index
end

InboxConfig.getGroupCfgByName = function(_name)
    for i=1,#InboxConfig.GROUP do
        local groupCfg = InboxConfig.GROUP[i]
        if groupCfg.name == _name then
            return groupCfg
        end
    end
    return 
end

InboxConfig.getGroupCfgByCategory = function(_category)
    for i=1,#InboxConfig.GROUP do
        local groupCfg = InboxConfig.GROUP[i]
        for j=1,#groupCfg.categorys do
            if groupCfg.categorys[j] == _category then
                return groupCfg
            end
        end
    end    
    return 
end

-- 服务器下发邮件ID
InboxConfig.TYPE_NET = {
    giftCode = 1, -- 手动发的补偿邮件
    normal = 4,
    repartwin = 17,
    cashback = 19,
    quest = 20,
    cardLink = 21,
    bingoRank = 22,
    deluxeCards = 23,
    bonusHuntAward = 29,
    luckyChallengeRankAward = 30,
    luckyChallengeAward = 31,
    luckyChallengeTaskPoint = 32,
    dinnerLandRank = 33,
    cashPuzzle = 34,
    DrawTaskAward = 35,
    DrawAward = 36,
    JackpotReturn = 37,
    freeGamesFever = 38,
    BattlePassAward = 39,
    vipGift = 40, --VIP权益奖励
    WordRankAward = 41,
    ActivityMissionAward = 42,
    CoinPusherTaskAward = 43,
    HolidayChallengeAward = 44,
    BlastTaskAward = 45,
    WordTaskAward = 46,
    RichManTaskAward = 47,
    EchoWinsAward = 49,
    DiningRoomRankAward = 50,
    DiningRoomTaskAward = 51,
    DiningRoomStuffAward = 52,
    RedecorRank = 53,
    RedecorTask = 54,
    RippleDashAward = 55, -- rippleDash 活动邮件
    ChefCoinRecycled = 56, -- 老版餐厅厨师币兑换奖励
    PassTaskAward = 57, -- pass任务奖励邮件
    NewPassAward = 58, --pass活动邮件
    NewPassExtraAward = 97,
    MissionRushAward = 99,
    BlastRankAward = 59, -- blast 排行榜结算邮件
    DeluxeExtraTimeReward = 60, -- 高倍场多余时间奖励
    HighLimitMergeRankAward = 61, -- 合图排行榜奖励
    RichRankAward = 62, --Rich排行榜奖励
    HighLimitMergePropsAward = 63, -- 合图材料返还奖励
    CatFoodCoinRecycled = 64, -- 剩余猫粮兑换奖励
    CoinPusherRankAward = 65, -- 推币机排行榜奖励
    LotteryReward = 66, -- 大乐透邮件奖励
    LotteryTicket = 67, -- 大乐透奖券邮件
    HolidayChallengeSaleAward = 68, -- 聚合挑战最后一天促销
    HighLimitMergeNotice = 69, -- 合图新一期开启提示邮件
    PokerRankAward = 70,
    BingoRushRankAward = 71, -- bingo比赛 排行榜奖励邮件
    PokerTaskAward = 72,
    PaintExchangeMail = 73, -- 涂色剩余颜料兑换金币
    DuckShotAward = 74, -- DuckShot掉线未领取奖励
    BingoRushGameAward = 75, -- bingo比赛 游戏结算邮件
    CoinPusherAward = 76, -- 推币机PASS奖励
    BingoRushPassAward = 77, -- bingo比赛 pass结算邮件
    PigDishAward = 78, -- 小猪轮盘
    WildChallengeAward = 79, --付费挑战
    SmashHammerAward = 80, --砸锤子每日任务送优惠券
    CapsuleToysAward = 81, -- 1000w扭蛋机奖励邮件
    PinballAward = 82, --弹球小游戏邮件
    CardAdventureGame = 83, -- 集卡鲨鱼游戏
    HolidayChallengeStarAward = 84, -- 聚合挑战剩余星星返奖邮件
    WorldTripTaskAward = 90, -- worldTrip任务奖励
    WorldTripRankAward = 91, -- worldTrip排行榜奖励
    ClanPoint = 85, -- 公会点数邮件
    ClanRank = 86, -- 公会排行榜邮件
    ClanRush = 92, -- 公会Rush奖励邮件
    QualityAvatarFrame = 96, --品质头像框挑战奖励
    AvatarFrameChallengeReward = 95, --头像框挑战任务奖励
    LevelDashPlusReward = 100,
    OnePlusOneSaleFreeReward = 94,
    --levelDashPlus
    TwoChooseOneGiftReward = 93, --二选一
    NewCoinPusherTaskAward = 87, --新coinPusher活动任务奖励
    NewCoinPusherRankAward = 88, --新coinPusher排行榜奖励
    NewCoinPusherAward = 89, --新coinPusher活动挑战奖励
    VipInvite = 102, -- vip社群邀请邮件
    CrazyShoppingCartAward = 105, --疯狂购物车
    FactionFightRankAward = 103, -- FactionFight挑战排行榜奖励
    FactionFightPassAward = 104, -- FactionFight挑战Pass奖励
    BlackFridayAward = 108, --黑五活动奖励
    BlackFridayLotteryAward = 109, --黑五抽奖邮件
    CardRankAward = 106, --集卡排行榜
    NewSlotChallengeReward = 110, --新关挑战奖励邮件
    PipeConnectRankAward = 111,--接水管排行榜奖励
    PipeConnectTaskAward = 112,--接水管活动任务奖励
    OptionalTaskAward = 113, -- 自选任务
    ShortCardJackpotReward = 116, -- 黑曜卡结束发奖
    HolidayChallengeSaleExtendAward = 115,--聚合挑战双倍补发邮件奖励
    MergeBackReward = 114, -- 合成水晶返还
    BigWinChallengeForgetReward = 117, --bigwin
    ChristmasTourRankReward = 119, -- -聚合挑战排行榜奖励
    QuestPassReward = 118,  -- quest pass未领取奖励
    FarmBackAward = 125, -- 农场回收奖励
    ChaseForChipsForgetReward = 121, -- 集卡赛季末聚合结束补发邮件奖励
    CardAlbumRaceAward = 122, -- -集卡AlbumRace奖励
    IceBrokenSaleAward = 123, --新破冰促销补发奖励
    GetMorePayLessReward = 126, -- 付费目标未领取奖励
    MagicGardenReward = 127,  -- 合成促销转盘未领取奖励
    MagicGardenRedundancyReward = 128, -- 合成促销转盘冗余道具返还奖励
    ZombieOnslaughtReward = 124, --zombie
    PrizeGameReward = 129, -- 充值抽奖未领取奖励
    GemChallengeReward = 130, -- 第二货币消耗挑战未领取奖励
    DiamondManiaReward = 131, -- 钻石挑战活跃活动未领取奖励
    NewUserBlastMissionAward = 132, --新手Blast奖励
    ReturnPassReward = 136, -- 回归签到pass补发邮件
    DragonChallengeTeamReward = 133, -- 组队打boss未领取团队任务
    DragonChallengeRankReward = 134, -- 组队打boss排行榜奖励
    DragonChallengeWheelsReward = 135, -- 组队打boss剩余道具奖励
    NoviceTrailAward = 138, -- 新手三日任务奖励邮件
    FlamingoJackpot = 200,
    PayRankReward = 137, -- 付费排行榜邮件
    LuckyRaceNotCollectedReward = 141, -- 单人限时比赛未领取奖励
    LuckySpinReward = 145, --lucky
    UserRankAward = 148, --排行榜奖励
    JewelManiaNotReward = 144, -- 挖矿挑战未领取奖励
    TrillionsWinnerChallengeRkAward = 150, -- 亿万赢家挑战排行榜奖励
    TrillionsWinnerChallengeTkAward = 151, -- 亿万赢家挑战任务奖励补发
    DragonChallengePassForgetReward = 153, -- 组队打boss的pass部分
    AppChargeFreeGift = 156, -- appCharge每日免费礼物 第三方支付 免费奖励
    FunctionSalePassPipe = 159, -- 大活动pass促销接水管
    FunctionSalePassBlast = 160, -- 大活动pass促销Blast
    FunctionSalePassWord = 161, -- 大活动pass促销Word
    FunctionSalePassCoinPusher = 162, -- 大活动pass促销推币机
    FunctionSalePassNewCoinPusher = 163, -- 大活动pass促销新版推币机
    FunctionSalePassWorldTrip = 164, -- 大活动pass促销大富翁
    FunctionSalePassBingo = 165, -- 大活动pass促销Bingo
    CrazyWheelReward = 168, -- 抽奖转盘未领取的奖励
    BlackFridayPoolAward = 166, -- 黑五狂欢节大奖奖励
    HolidayNewChallengePassMail =178, -- 圣诞pass未领取奖励
    HolidayNewChallengeRankReward = 179, -- 圣诞排行榜未领取奖励
    BlastCollectAward = 170, -- blast
    CoinPusherV3TaskAward = 155, --coinPusherV3活动任务奖励
    LuckyChallengeV2PassReward = 173, --钻石挑战v2pass
    LuckyChallengeV2RankAward = 158,--钻石挑战v2pass
    LuckyChallengeV2TimeMailReward = 176,--钻石挑战限时活动
    HolidayNewChallengeCrazeReward = 180, -- 圣诞充值分奖
    XmasSplitReward = 177, -- 圣诞累充分大奖
    PaySendBuck = 181, -- 商城购买返回代币
    MegaWinReward = 185,  -- 大赢宝箱解锁奖励  
}

-- 自定义邮件类型 （注意:优惠劵以icon为key）
InboxConfig.TYPE_LOCAL = {
    group = "group", -- 分组邮件不是真正的邮件，占位用
    spinBonusReward = "spinBonusReward",
    sendCoupon = "sendCoupon",      -- 【废弃】 -- 
    poker = "poker",
    watchVideo = "watchVideo",
    piggyNoviceDiscount = "piggyNoviceDiscount",
    facebook = "facebook",
    bindPhone = "bindPhone",
    version = "version",
    LevelRush = "LevelRush",
    miniGameLevelFish = "miniGameLevelFish", -- mini游戏 levelrush 的改版-> levelfish
    freeGame = "freeGame", -- free spin 免费次数
    freeGameAds = "freeGameAds", -- 看激励广告 freespin 免费次数
    questionnaire = "questionnaire", -- 调查问卷
    bigRContact = "bigRContact", -- 用户直接沟通
    shopGemCoupon = "shopGemCoupon", -- 第二货币商城优惠券
    Coupon_saleticket = "Coupon_saleticket",
    Coupon_cybermonday = "Coupon_cybermonday",
    Coupon_EasterDay = "Coupon_EasterDay",
    CouponRegister = "CouponRegister", -- 注册里程碑
    vipTicket = "VipCoupon", --VIP劵从 登录CommonConfig中获取
    rateMileStoneCoupon = "CouponLevelUp", -- 等级里程碑优惠券
    ticket = "Coupon",
    GiftPickBonusGame = "GiftPickBonusGame", -- starPick小游戏，第二条任务线小游戏
    Coupon_Register_newYear2022 = "Coupon_Register_newYear2022", -- 新年签到优惠卷      -- 【废弃】 -- 
    GemSale_newYear2022 = "GemSale_newYear2022", -- 新年签到钻石商城优惠卷      -- 【废弃】 -- 
    shopGemCouponNewYear = "shopGemCouponNewYear", -- 新年第二货币商城优惠券
    Coupon_AustraliaDay = "Coupon_AustraliaDay", --澳大利亚日商城优惠券
    Coupon_LunarYear = "Coupon_LunarYear", -- 春节优惠券
    SaleTicket_SuperBowl22 = "SaleTicket_SuperBowl22", -- 超级碗四联
    Coupon_Valentine2022 = "Coupon_Valentine2022", -- 情人节商城优惠券
    shopGemCouponLunarNewYear = "shopGemCouponLunarNewYear", -- 春节第二货币商城优惠券
    Coupon_President22 = "Coupon_President22", --2022总统日商城优惠券
    Coupon_Patrick = "Coupon_Patrick", -- 圣帕特里克商城优惠券
    Coupon_Register_Fool = "Coupon_Register_Fool", -- 愚人节签到优惠券
    GemSale_Fool = "GemSale_Fool", -- 愚人节签到砖石优惠券
    SaleTicket_Easter22 = "SaleTicket_Easter22", --2022复活节四联优惠券
    PokerRecall = "PokerRecall", --PokerRecall小游戏
    miniGameDuckShot = "miniGameDuckShot", -- mini游戏 duckShot
    Coupon_Easter_Gem = "Coupon_Easter_Gem", -- 复活节砖石优惠券
    Coupon_Easter_Coin = "Coupon_Easter_Coin", -- 复活节商城优惠券
    Coupon_Easter_Piggy = "Coupon_Easter_Piggy", -- 复活节小猪优惠券
    Piggy_coupon = "Piggy_coupon", -- 小猪优惠券
    Coupon_ND_Gem = "Coupon_ND_Gem", -- 新版签到砖石优惠券
    Coupon_ND_Coin = "Coupon_ND_Coin", -- 新版签到商城优惠券
    Coupon_ND_Piggy = "Coupon_ND_Piggy", -- 新版签到小猪优惠券
    Invite = "Invite", -- 拉新
    TreasureSeeker = "TreasureSeeker", -- 鲨鱼小游戏
    FBShareCoupon = "FBShareCoupon", -- fb用户分享获得的优惠券
    miniGameCashMoney = "miniGameCashMoney", -- mini游戏 CashMoney
    Coupon_July4th_Coin = "Coupon_July4th_Coin", -- 独立日商城优惠券
    Coupon_July4th_Gem = "Coupon_July4th_Gem", -- 独立日砖石优惠券
    Coupon_July4th_Piggy = "Coupon_July4th_Piggy", -- 独立日小猪优惠券
    miniGamePiggyClicker = "miniGamePiggyClicker", -- 快速点击小游戏
    miniGameDarts = "miniGameDarts", --dartsGame
    SurveyGame = "SurveyGame",
    ScratchCards = "ScratchCards", -- 刮刮卡
    Coupon_3rdAnniversary_Coin = "Coupon_3rdAnniversary_Coin", -- 三周年商城优惠券
    Coupon_3rdAnniversary_Gem = "Coupon_3rdAnniversary_Gem", -- 三周年钻石优惠券
    Coupon_3rdAnniversary_Piggy = "Coupon_3rdAnniversary_Piggy", -- 三周年小猪优惠券
    miniGamePinBallGo = "miniGamePinBallGo", -- mini游戏 弹珠小游戏
    Plinko = "Plinko", -- luckfish BeerPlinko
    YearEndSummary = "YearEndSummary", --年终总结
    NewYearGift = "NewYearGift", -- 新年送礼
    miniGameDartsNew = "miniGameDartsNew", --飞镖小游戏
    Coupon_MC_Coin_Special = "Coupon_MC_Coin_Special", -- 豪华月卡优惠券
    Coupon_MCS_Coin_Special = "Coupon_MCS_Coin_Special", -- 普通月卡优惠券
    PerLinko = "PerLinko", -- PerLinko respin玩法
    Gem_saleTicket = "Gem_saleTicket", -- 三联加道具-促销券第3张-第二货币
    Piggy_saleTicket = "Piggy_saleTicket", -- 三联加道具-促销券第3张-小猪
    MythicGame = "MythicGame", -- 鲨鱼游戏
    miniGameLevelRoad = "miniGameLevelRoad", -- 等级里程碑小游戏
    appChargePay = "appChargePay", -- 第三方支付 付费奖励
    VCoupon = "VCoupon", -- 指定用户分组送指定档位可用优惠券
    BoxSystem = "BoxSystem", -- 神秘宝箱系统
    NotificationReward = "NotificationReward", -- 推送奖励
}

-- 优先级：邮件种类（从上到下，从小到大）
-- 优先级：邮件倒计时：倒计时短的靠上方
-- 优先级为3的话，需要getExpireTiem方法获得时间排序
-- 服务器定义的邮件类型
-- relRes: 关联资源
InboxConfig.InBoxNetNameMap =
{
    ["NetDefault"]                                      = {name = "InboxItem_common",               category = InboxConfig.CATEGORY.Award},  -- 默认服务器邮件
    [""..InboxConfig.TYPE_NET.LuckyChallengeV2RankAward]  = {name = "InboxItem_luckyChallengeRank",   category = InboxConfig.CATEGORY.Award, isDownLoad = false},
    [""..InboxConfig.TYPE_NET.LuckyChallengeV2PassReward]      = {name = "InboxItem_luckyChallengeCoins",  category = InboxConfig.CATEGORY.Award, isDownLoad = false},
    [""..InboxConfig.TYPE_NET.luckyChallengeTaskPoint]  = {name = "InboxItem_luckyChallengeDiamond",category = InboxConfig.CATEGORY.Award, isDownLoad = false},
    [""..InboxConfig.TYPE_NET.LuckyChallengeV2TimeMailReward]  = {name = "InboxItem_luckyChallengeRush",              category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.PaySendBuck]              = {name = "InboxItem_BucksBack",            category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.vipGift]                  = {name = "InboxItem_vipGift",              category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.DrawTaskAward]            = {name = "InboxItem_luckyChipsDraw",       category = InboxConfig.CATEGORY.Award, isDownLoad = true},       
    [""..InboxConfig.TYPE_NET.repartwin]                = {name = "InboxItem_repartwin",            category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.cashback]                 = {name = "InboxItem_boostme",              category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.quest]                    = {name = "InboxItem_quest",                category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.TwoChooseOneGiftReward]   = {name = "InboxItem_TornadoMagicStore",    category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.LevelDashPlusReward]      = {name = "InboxItem_LevelDashPlus",        category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.OnePlusOneSaleFreeReward] = {name = "InboxItem_OnePlusOneSale",       category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.bingoRank]                = {name = "InboxItem_bingoRank",            category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.cardLink]                 = {name = "InboxItem_cardLink",             category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.cashPuzzle]               = {name = "InboxItem_cashPuzzle",           category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.deluxeCards]              = {name = "InboxItem_deluxeCards",          category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.bonusHuntAward]           = {name = "InboxItem_bonusHuntCoin",        category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.DrawAward]                = {name = "InboxItem_luckyChipsDrawCoins",  category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.JackpotReturn]            = {name = "InboxItem_repartJackpot",        category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.freeGamesFever]           = {name = "InboxItem_repartFreeSpin",       category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.WordRankAward]            = {name = "InboxItem_word_Rank",            category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.HolidayChallengeAward]    = {name = "InboxItem_holidayChallenge",     category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.HolidayChallengeSaleAward]= {name = "InboxItem_holidayChallenge",     category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.HolidayChallengeSaleExtendAward]= {name = "InboxItem_holidayChallengeSaleExtendAward",    category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.ChristmasTourRankReward]  = {name = "InboxItem_holidayChallengeRankAward",                category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.ActivityMissionAward]     = {name = "InboxItem_bingoTask",            category = InboxConfig.CATEGORY.Award, isDownLoad = true}, --bingo任务
    [""..InboxConfig.TYPE_NET.CoinPusherTaskAward]      = {name = "InboxItem_coinPusher_Task",      category = InboxConfig.CATEGORY.Award, isDownLoad = true}, --推币机任务
    [""..InboxConfig.TYPE_NET.BlastTaskAward]           = {name = "InboxItem_blastTask",            category = InboxConfig.CATEGORY.Award, isDownLoad = true}, --blast任务
    [""..InboxConfig.TYPE_NET.BlastRankAward]           = {name = "InboxItem_blastRank",            category = InboxConfig.CATEGORY.Award, isDownLoad = true}, --blast排行榜
    [""..InboxConfig.TYPE_NET.BlastCollectAward]        = {name = "InboxItem_blastBox",             category = InboxConfig.CATEGORY.Award, isDownLoad = true}, --blast收集奖励
    [""..InboxConfig.TYPE_NET.WordTaskAward]            = {name = "InboxItem_wordTask",             category = InboxConfig.CATEGORY.Award, isDownLoad = true}, --word任务
    [""..InboxConfig.TYPE_NET.RichManTaskAward]         = {name = "InboxItem_richManTask",          category = InboxConfig.CATEGORY.Award, isDownLoad = true}, --大富翁任务
    [""..InboxConfig.TYPE_NET.EchoWinsAward]            = {name = "InboxItem_echowin",              category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- EchoWin 活动
    [""..InboxConfig.TYPE_NET.ChefCoinRecycled]         = {name = "InboxItem_chefCoinRecycled",     category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 老版餐厅厨师币兑换奖励
    [""..InboxConfig.TYPE_NET.RedecorRank]              = {name = "InboxItem_redecorRank",          category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 装修活动 排行榜奖励
    [""..InboxConfig.TYPE_NET.RedecorTask]              = {name = "InboxItem_redecorTask",          category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 装修活动 任务奖励        
    [""..InboxConfig.TYPE_NET.PassTaskAward]            = {name = "InboxItem_newPassTask",          category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- pass 任务奖励
    [""..InboxConfig.TYPE_NET.NewPassAward]             = {name = "InboxItem_newPass",              category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- pass 活动奖励
    [""..InboxConfig.TYPE_NET.MissionRushAward]         = {name = "InboxItem_MissionRushNew",       category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.NewPassExtraAward]        = {name = "InboxItem_SeasonMissionDash",    category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.DeluxeExtraTimeReward]    = {name = "InboxItem_deluxeExtraTimeReward",category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.RippleDashAward]          = {name = "InboxItem_rippleDash",           category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- pass 活动奖励
    [""..InboxConfig.TYPE_NET.CoinPusherRankAward]      = {name = "InboxItem_coinPusherRank",       category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 推币机排行榜奖励
    [""..InboxConfig.TYPE_NET.HighLimitMergePropsAward] = {name = "InboxItem_MergeGameRecycle",     category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 合图材料返还奖励
    [""..InboxConfig.TYPE_NET.HighLimitMergeRankAward]  = {name = "InboxItem_MergeGameRank",        category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 合图排行榜奖励
    [""..InboxConfig.TYPE_NET.RichRankAward]            = {name = "InboxItem_richMan_RankAward",    category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 大富翁排行奖励
    [""..InboxConfig.TYPE_NET.PokerTaskAward]           = {name = "InboxItem_PokerTask",            category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 扑克任务邮件
    [""..InboxConfig.TYPE_NET.PokerRankAward]           = {name = "InboxItem_PokerRank",            category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 扑克排行榜邮件
    [""..InboxConfig.TYPE_NET.LotteryReward]            = {name = "InboxItem_LotteryRewards",       category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 大乐透邮件奖励
    [""..InboxConfig.TYPE_NET.LotteryTicket]            = {name = "InboxItem_LotteryTicket",        category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- -- 大乐透奖券邮件
    [""..InboxConfig.TYPE_NET.DuckShotAward]            = {name = "InboxItem_duckShotReward",       category = InboxConfig.CATEGORY.MiniGame, isDownLoad = true}, -- 鸭子
    [""..InboxConfig.TYPE_NET.BingoRushRankAward]       = {name = "InboxItem_bingoRush_Rank",       category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- bingo比赛 排行榜奖励邮件
    [""..InboxConfig.TYPE_NET.BingoRushPassAward]       = {name = "InboxItem_bingoRush_Pass",       category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- bingo比赛 排行榜奖励邮件
    [""..InboxConfig.TYPE_NET.BingoRushGameAward]       = {name = "InboxItem_bingoRush_Game",       category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- bingo比赛 过关结算邮件
    [""..InboxConfig.TYPE_NET.CoinPusherAward]          = {name = "InboxItem_coinPusher_Pass",      category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- -- 推币机PASS奖励邮件
    [""..InboxConfig.TYPE_NET.PigDishAward]             = {name = "InboxItem_PigDish",              category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 小猪转盘
    [""..InboxConfig.TYPE_NET.WildChallengeAward]       = {name = "InboxItem_WildChallengeAward",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 付费挑战
    [""..InboxConfig.TYPE_NET.PaintExchangeMail]        = {name = "InboxItem_PaintExchange",        category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 涂色剩余颜料兑换金币
    [""..InboxConfig.TYPE_NET.SmashHammerAward]         = {name = "InboxItem_CouponChallenge",      category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 砸锤子每日任务送优惠券
    [""..InboxConfig.TYPE_NET.CapsuleToysAward]         = {name = "InboxItem_Gashpon",              category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- -- 1000w扭蛋机奖励邮件
    [""..InboxConfig.TYPE_NET.CardAdventureGame]        = {name = "InboxItem_CardSeekerGame",       category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 集卡鲨鱼游戏奖励邮件
    [""..InboxConfig.TYPE_NET.ClanPoint]                = {name = "InboxItem_TeamBoxAward",    category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 公会点数邮件
    [""..InboxConfig.TYPE_NET.ClanRank]                 = {name = "InboxItem_TeamRankAward",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 公会排行榜邮件
    [""..InboxConfig.TYPE_NET.ClanRush]                 = {name = "InboxItem_TeamRushAward",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 公会Rush奖励邮件
    [""..InboxConfig.TYPE_NET.PinballAward]             = {name = "InboxItem_PinBallGo",            category = InboxConfig.CATEGORY.MiniGame, isDownLoad = true}, -- -- 弹球小游戏邮件
    [""..InboxConfig.TYPE_NET.HolidayChallengeStarAward]= {name = "InboxItem_HolidayChallengeStarAward",category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 聚合挑战剩余星星返奖邮件
    [""..InboxConfig.TYPE_NET.QualityAvatarFrame]       = {name = "InboxItem_SpecialFrame_Challenge",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 品质头像框挑战
    [""..InboxConfig.TYPE_NET.AvatarFrameChallengeReward] = {name = "InboxItem_FrameChallengeReward",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 头像框挑战奖励邮件
    [""..InboxConfig.TYPE_NET.WorldTripTaskAward]       = {name = "InboxItem_WorldTripTaskAward",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 新版大富翁活动任务奖励结算邮件
    [""..InboxConfig.TYPE_NET.WorldTripRankAward]       = {name = "InboxItem_WorldTripRankAward",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 新版大富翁排行榜奖励结算邮件
    [""..InboxConfig.TYPE_NET.NewCoinPusherTaskAward]   = {name = "InboxItem_NewCoinPusherTask",    category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 新推币机 任务奖励邮件
    [""..InboxConfig.TYPE_NET.NewCoinPusherRankAward]   = {name = "InboxItem_NewCoinPusherRank",    category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 新推币机 排行榜奖励邮件
    [""..InboxConfig.TYPE_NET.VipInvite]                = {name = "InboxItem_VipGroup",             category = InboxConfig.CATEGORY.Notice, isDownLoad = false}, -- vip社群邀请邮件
    [""..InboxConfig.TYPE_NET.CardRankAward]            = {name = "InboxItem_CardRank",             category = InboxConfig.CATEGORY.Award, isDownLoad = false}, -- 集卡排行榜
    [""..InboxConfig.TYPE_NET.CrazyShoppingCartAward]   = {name = "InboxItem_crazyCart",            category = InboxConfig.CATEGORY.Award, isDownLoad = true},  --疯狂购物车
    [""..InboxConfig.TYPE_NET.FactionFightRankAward]    = {name = "InboxItem_FactionFightRank",     category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- FactionFight挑战排行榜奖励
    [""..InboxConfig.TYPE_NET.FactionFightPassAward]    = {name = "InboxItem_FactionFightReward",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- FactionFight挑战Pass奖励
    [""..InboxConfig.TYPE_NET.BlackFridayAward]         = {name = "InboxItem_GrandPrize",           category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 黑五活动奖励邮件
    [""..InboxConfig.TYPE_NET.BlackFridayLotteryAward]  = {name = "InboxItem_BFDraw",               category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 黑五抽奖邮件
    [""..InboxConfig.TYPE_NET.NewSlotChallengeReward]   = {name = "InboxItem_SlotTrials",           category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 新关挑战邮件
    [""..InboxConfig.TYPE_NET.PipeConnectRankAward]     = {name = "InboxItem_PipeConnectRank",      category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 接水管排行榜奖励
    [""..InboxConfig.TYPE_NET.PipeConnectTaskAward]     = {name = "InboxItem_PipeConnectTask",      category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 接水管活动任务奖励
    [""..InboxConfig.TYPE_NET.OptionalTaskAward]        = {name = "InboxItem_PickTask",             category = InboxConfig.CATEGORY.Award, isDownLoad = false},
    [""..InboxConfig.TYPE_NET.BigWinChallengeForgetReward]   = {name = "InboxItem_bigWin",          category = InboxConfig.CATEGORY.Award, isDownLoad = true},  --bigwin
    [""..InboxConfig.TYPE_NET.ZombieOnslaughtReward]   = {name = "InboxItem_zomBie",                category = InboxConfig.CATEGORY.Award, isDownLoad = true},  --zombie
    [""..InboxConfig.TYPE_NET.ShortCardJackpotReward]   = {name = "InboxItem_CardObsidianJackpot",  category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 黑曜卡结束邮件发奖
    [""..InboxConfig.TYPE_NET.MergeBackReward]          = {name = "InboxItem_CrystalBack",          category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 合成水晶返还
    [""..InboxConfig.TYPE_NET.QuestPassReward]          = {name = "InboxItem_QuestPassRewards",     category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- quest pass未领取奖励
    [""..InboxConfig.TYPE_NET.FarmBackAward]            = {name = "InboxItem_FarmBackAward",        category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 农场关闭回收奖励
    [""..InboxConfig.TYPE_NET.CardAlbumRaceAward]       = {name = "InboxItem_CardAlbumRaceAward",   category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.ChaseForChipsForgetReward]= {name = "InboxItem_ChaseForChips",        category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 集卡赛季末聚合结束补发邮件奖励
    [""..InboxConfig.TYPE_NET.IceBrokenSaleAward]       = {name = "InboxItem_IceBrokenSale",        category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 新版破冰促销奖励
    [""..InboxConfig.TYPE_NET.GetMorePayLessReward]     = {name = "InboxItem_GetMorePayLessReward", category = InboxConfig.CATEGORY.Award, isDownLoad = false}, -- 付费目标
    [""..InboxConfig.TYPE_NET.MagicGardenReward]        = {name = "InboxItem_MagicGardenReward",    category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 合成转盘
    [""..InboxConfig.TYPE_NET.MagicGardenRedundancyReward] = {name = "InboxItem_MagicGardenBack",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 合成转盘
    [""..InboxConfig.TYPE_NET.PrizeGameReward]          = {name = "InboxItem_PrizeGameReward",      category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 充值抽奖未领取奖励
    [""..InboxConfig.TYPE_NET.GemChallengeReward]       = {name = "InboxItem_GemChallengeReward",   category = InboxConfig.CATEGORY.Award, isDownLoad = false}, -- 第二货币消耗挑战未领取奖励
    [""..InboxConfig.TYPE_NET.DiamondManiaReward]       = {name = "InboxItem_DiamondManiaReward",   category = InboxConfig.CATEGORY.Award, isDownLoad = false}, -- 钻石挑战活跃活动未领取奖励
    [""..InboxConfig.TYPE_NET.NewUserBlastMissionAward] = {name = "InboxItem_blastTask",            category = InboxConfig.CATEGORY.Award, isDownLoad = true}, --blast任务_新手期
    [""..InboxConfig.TYPE_NET.ReturnPassReward]         = {name = "InboxItem_ReturnPassReward",     category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 回归签到pass补发邮件
    [""..InboxConfig.TYPE_NET.giftCode]                 = {name = "InboxItem_giftCode",             category = InboxConfig.CATEGORY.Award, isDownLoad = false}, -- 手动发的补偿邮件
    [""..InboxConfig.TYPE_NET.DragonChallengeTeamReward]   = {name = "InboxItem_DragonChallengeTeam",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 组队打boss未领取团队任务
    [""..InboxConfig.TYPE_NET.DragonChallengeRankReward]   = {name = "InboxItem_DragonChallengeRank",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 组队打boss排行榜奖励
    [""..InboxConfig.TYPE_NET.DragonChallengeWheelsReward] = {name = "InboxItem_DragonChallengeWheels", category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 组队打boss剩余道具奖励
    [""..InboxConfig.TYPE_NET.FlamingoJackpot]          = {name = "InboxItem_FlamingoJackpot",      category = InboxConfig.CATEGORY.Award, isDownLoad = true},
    [""..InboxConfig.TYPE_NET.NoviceTrailAward]         = {name = "InboxItem_NoviceTrailAward",     category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 新手三日任务奖励邮件
    [""..InboxConfig.TYPE_NET.PayRankReward]            = {name = "InboxItem_PayRank",              category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 付费排行榜邮件
    [""..InboxConfig.TYPE_NET.LuckyRaceNotCollectedReward] = {name = "InboxItem_LuckyRace",              category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- LuckyRace奖励邮件
    [""..InboxConfig.TYPE_NET.LuckySpinReward]  = {name = "InboxItem_common",   category = InboxConfig.CATEGORY.Award, isDownLoad = false},
    [""..InboxConfig.TYPE_NET.UserRankAward]  = {name = "InboxItem_CommonRank",   category = InboxConfig.CATEGORY.Award, isDownLoad = true}, --通用排行榜
    [""..InboxConfig.TYPE_NET.JewelManiaNotReward]      = {name = "InboxItem_JewelManiaNotReward",  category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 挖矿挑战未领取邮件
    [""..InboxConfig.TYPE_NET.DragonChallengePassForgetReward] = {name = "InboxItem_DragonChallengePass",  category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 组队打boss pass奖励邮件
    [""..InboxConfig.TYPE_NET.AppChargeFreeGift]        = {name = "InboxItem_AppChargeFree",        category = InboxConfig.CATEGORY.Special, isDownLoad = true}, -- 第三方支付 付费奖励
    [""..InboxConfig.TYPE_NET.TrillionsWinnerChallengeRkAward]  = {name = "InboxItem_TrillionChallengeRankAward",   category = InboxConfig.CATEGORY.Award, isDownLoad = false}, -- 亿万赢家挑战排行榜奖励
    [""..InboxConfig.TYPE_NET.TrillionsWinnerChallengeTkAward]  = {name = "InboxItem_TrillionChallengeTaskAward",   category = InboxConfig.CATEGORY.Award, isDownLoad = false}, -- 亿万赢家挑战任务宝箱奖励
    [""..InboxConfig.TYPE_NET.FunctionSalePassPipe] = {name = "InboxItem_FunctionSalePassPipe",  category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 大活动pass促销接水管
    [""..InboxConfig.TYPE_NET.CrazyWheelReward] = {name = "InboxItem_CrazyWheelReward",  category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 抽奖转盘
    [""..InboxConfig.TYPE_NET.BlackFridayPoolAward] = {name = "InboxItem_BlackFridayPoolAward",  category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 黑五分大奖奖励
    [""..InboxConfig.TYPE_NET.CoinPusherV3TaskAward] = {name = "InboxItem_EgyptCoinPusherTask",    category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 埃及推币机 任务奖励邮件
    [""..InboxConfig.TYPE_NET.HolidayNewChallengeCrazeReward] = {name = "InboxItem_XmasCraze2023",  category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 圣诞充值分奖
    [""..InboxConfig.TYPE_NET.XmasSplitReward] = {name = "InboxItem_XmasSplit2023",  category = InboxConfig.CATEGORY.Award, isDownLoad = true}, -- 圣诞累充奖励
    [""..InboxConfig.TYPE_NET.MegaWinReward]   = {name = "InboxItem_MegaWinReward",            category = InboxConfig.CATEGORY.Award, isDownLoad = true},
}

-- 自定义的邮件类型
InboxConfig.InBoxLocalNameMap =
{
    -- 特殊类，通知类在这里定义，优先级为3的话，需要getExpireTiem方法获得时间排序
    [InboxConfig.TYPE_LOCAL.facebook]               = {name = "InboxItem_facebook",             category = InboxConfig.CATEGORY.Special},
    [InboxConfig.TYPE_LOCAL.bindPhone]              = {name = "InboxItem_bindPhone",            category = InboxConfig.CATEGORY.Special},
    [InboxConfig.TYPE_LOCAL.version]                = {name = "InboxItem_update",               category = InboxConfig.CATEGORY.Special},
    [InboxConfig.TYPE_LOCAL.watchVideo]             = {name = "InboxItem_watchRewardVideo",     category = InboxConfig.CATEGORY.Special},  
    [InboxConfig.TYPE_LOCAL.bigRContact]            = {name = "InboxItem_bigRContact",          category = InboxConfig.CATEGORY.Special},
    [InboxConfig.TYPE_LOCAL.freeGameAds]            = {name = "InboxItem_freeGame_ads",         dataName = "FreeGameMailData",      category = InboxConfig.CATEGORY.Special},
    [InboxConfig.TYPE_LOCAL.freeGame]               = {name = "InboxItem_freeGame",             dataName = "FreeGameMailData",      category = InboxConfig.CATEGORY.Special},
    [InboxConfig.TYPE_LOCAL.miniGameLevelFish]      = {name = "InboxItem_miniGameLevelFish",    dataName = "LevelFishMailData",     category = InboxConfig.CATEGORY.MiniGame,   relRes = {"Activity_LevelRush"}}, -- 弃用
    [InboxConfig.TYPE_LOCAL.poker]                  = {name = "InboxItem_poker",                dataName = "PokerMailData",         category = InboxConfig.CATEGORY.Notice}, 
    [InboxConfig.TYPE_LOCAL.spinBonusReward]        = {name = "InboxItem_spinBonusReward",      dataName = "SpinBonusMailData",     category = InboxConfig.CATEGORY.Notice}, 
    [InboxConfig.TYPE_LOCAL.LevelRush]              = {name = "InboxItem_levelRush",            dataName = "LevelRushMailData",     category = InboxConfig.CATEGORY.MiniGame,   relRes = {"Activity_LevelRush"}}, -- 弃用
    [InboxConfig.TYPE_LOCAL.questionnaire]          = {name = "InboxItem_Questionnaire",        dataName = "QuestionnaireMailData", category = InboxConfig.CATEGORY.Notice},
    [InboxConfig.TYPE_LOCAL.GiftPickBonusGame]      = {name = "InboxItem_giftPickBonusGame",    dataName = "GiftPickBonusMailData", category = InboxConfig.CATEGORY.MiniGame,   relRes = {G_REF.GiftPickBonus}},
    [InboxConfig.TYPE_LOCAL.PokerRecall]            = {name = "InboxItem_PokerRecall",          dataName = "PokerRecallMailData",   category = InboxConfig.CATEGORY.MiniGame,   relRes = {G_REF.PokerRecall}},
    [InboxConfig.TYPE_LOCAL.miniGameDuckShot]       = {name = "InboxItem_miniGameDuckShot",     dataName = "DuckShotMailData",      category = InboxConfig.CATEGORY.MiniGame,   relRes = {"Activity_DuckShot"}},
    [InboxConfig.TYPE_LOCAL.TreasureSeeker]         = {name = "InboxItem_MiniGameTreasureSeeker", dataName = "TSMailData",          category = InboxConfig.CATEGORY.MiniGame,   relRes = {G_REF.TreasureSeeker}},
    [InboxConfig.TYPE_LOCAL.Invite]                 = {name = "InboxItem_Invite",               category = InboxConfig.CATEGORY.Special},
    [InboxConfig.TYPE_LOCAL.miniGameCashMoney]      = {name = "InboxItem_miniGameCashMoney",    dataName = "CashMoneyMailData",     category = InboxConfig.CATEGORY.MiniGame,   relRes = {G_REF.CashMoney}}, 
    [InboxConfig.TYPE_LOCAL.miniGamePiggyClicker]   = {name = "InboxItem_miniGamePiggyClicker", dataName = "PiggyClickerMailData",  category = InboxConfig.CATEGORY.MiniGame,   relRes = {"Activity_PiggyClicker"}},
    [InboxConfig.TYPE_LOCAL.miniGameDarts]          = {name = "InboxItem_miniGameDarts",        dataName = "DartsMailData",         category = InboxConfig.CATEGORY.MiniGame,   relRes = {"Activity_DartsGame"}},
    [InboxConfig.TYPE_LOCAL.miniGameDartsNew]       = {name = "InboxItem_miniGameDartsNew",     dataName = "DartsMailData",         category = InboxConfig.CATEGORY.MiniGame,   relRes = {"Activity_DartsGameNew", "Activity_DartsGameNewCode"}},
    [InboxConfig.TYPE_LOCAL.SurveyGame]             = {name = "InboxItem_SurveyGame",           dataName = "SurveyGameMailData",    category = InboxConfig.CATEGORY.Notice,     relRes = {"Activity_SurveyinGame"}},
    [InboxConfig.TYPE_LOCAL.ScratchCards]           = {name = "InboxItem_ScratchCards",         dataName = "ScratchCardMailData",   category = InboxConfig.CATEGORY.MiniGame,   relRes = {"Activity_ScratchCards"}},
    [InboxConfig.TYPE_LOCAL.miniGamePinBallGo]      = {name = "InboxItem_miniGamePinBallGo",    dataName = "PBGMailData",           category = InboxConfig.CATEGORY.MiniGame},
    [InboxConfig.TYPE_LOCAL.Plinko]                 = {name = "InboxItem_MiniGamePlinko",       dataName = "PlinkoMailData",        category = InboxConfig.CATEGORY.MiniGame,   relRes = {G_REF.Plinko}},
    [InboxConfig.TYPE_LOCAL.YearEndSummary]         = {name = "InboxItem_YearEndSummary",       dataName = "YESMailData",           category = InboxConfig.CATEGORY.Notice,     relRes = {"Activity_YearEndSummary"}},
    [InboxConfig.TYPE_LOCAL.NewYearGift]            = {name = "InboxItem_NewYearGift",          dataName = "NewYearGiftMailData",   category = InboxConfig.CATEGORY.Notice},
    [InboxConfig.TYPE_LOCAL.PerLinko]               = {name = "InboxItem_MiniGamePerLink",      dataName = "PerLinkMailData",       category = InboxConfig.CATEGORY.MiniGame},
    [InboxConfig.TYPE_LOCAL.MythicGame]             = {name = "InboxItem_miniGameMythicGame",   dataName = "MythicGameMailData",    category = InboxConfig.CATEGORY.MiniGame,   relRes = {G_REF.MythicGame, G_REF.CardSeeker}},
    [InboxConfig.TYPE_LOCAL.miniGameLevelRoad]      = {name = "InboxItem_miniGameLevelRoad",    dataName = "LevelRoadGameMailData", category = InboxConfig.CATEGORY.MiniGame,   relRes = {"Activity_LevelRoadGame"}},
    [InboxConfig.TYPE_LOCAL.appChargePay]           = {name = "InboxItem_AppChargePay",         category = InboxConfig.CATEGORY.Payment},
    [InboxConfig.TYPE_LOCAL.BoxSystem]              = {name = "InboxItem_BoxSystem",            category = InboxConfig.CATEGORY.Award},
    [InboxConfig.TYPE_LOCAL.NotificationReward]     = {name = "InboxItem_NotificationReward",   category = InboxConfig.CATEGORY.Special},

    -- 优惠劵这里定义，type(类型：coin，gem, piggy)，scope（生效范围：全部档位-all，部分档位-part）
    [InboxConfig.TYPE_LOCAL.shopGemCouponNewYear]   = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "gem", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.shopGemCouponLunarNewYear]= {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "gem", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_LunarYear]         = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.piggyNoviceDiscount]    = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "piggy", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.vipTicket]              = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.ticket]                 = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_saleticket]      = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_cybermonday]     = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_EasterDay]       = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.rateMileStoneCoupon]    = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.CouponRegister]         = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_AustraliaDay]    = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.SaleTicket_SuperBowl22] = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_Valentine2022]   = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_President22]     = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_Patrick]         = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_Register_Fool]   = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.SaleTicket_Easter22]    = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.shopGemCoupon]          = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "gem", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.GemSale_Fool]           = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "gem", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_Easter_Coin]     = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_Easter_Gem]      = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "gem", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_Easter_Piggy]    = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "piggy", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Piggy_coupon]           = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "piggy", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_ND_Coin]         = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_ND_Gem]          = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "gem", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_ND_Piggy]        = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "piggy", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.FBShareCoupon]          = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_July4th_Coin]    = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_July4th_Gem]     = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "gem", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_July4th_Piggy]   = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "piggy", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_3rdAnniversary_Coin]    = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_3rdAnniversary_Gem]     = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "gem", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_3rdAnniversary_Piggy]   = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "piggy", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_MC_Coin_Special]        = {name = "InboxItem_monthlyCardCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Coupon_MCS_Coin_Special]       = {name = "InboxItem_monthlyCardSilverCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Gem_saleTicket]         = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "gem", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.Piggy_saleTicket]       = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "piggy", scope = "all"}},
    [InboxConfig.TYPE_LOCAL.VCoupon]                = {name = "InboxItem_baseCoupon", category = InboxConfig.CATEGORY.Coupon, info = {type = "coin", scope = "part"}},
}

InboxConfig.resetRepeatTypes = function()
    InboxConfig.repeatTypes = {}
end
InboxConfig.resetRepeatTypes()
-- 本地邮件自定义id
InboxConfig.getClientMailId = function(_type)
    InboxConfig.repeatTypes["".._type] = (InboxConfig.repeatTypes["".._type] or 0) + 1
    local index = 0
    local t = InboxConfig.TYPE_LOCAL
    for k, v in pairs(t) do
        index = index + 1
        if v == _type then
            break
        end
    end
    local id = index * 1000 + InboxConfig.repeatTypes["".._type]
    print("InboxConfig.getClientMailId", _type, index, id)
    return id
end

InboxConfig.getNameMapConfig = function(_type, _isNetMail)
    if _type == nil or _type == "" then
        print("InboxConfig.getNameMapConfig, _type is nil")
        return
    end
    local map = nil
    if _isNetMail then
        map = InboxConfig.InBoxNetNameMap["".._type]
        if not map then
            map = InboxConfig.InBoxNetNameMap["NetDefault"]
        end
    else
        map = InboxConfig.InBoxLocalNameMap[_type]
    end
    return map
end