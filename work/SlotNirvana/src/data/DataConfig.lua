---
-- Author: island
-- Date: 2017-08-11 10:47:19
-- FIX IOS 139

--金币缩放
GD.COIN_LEVEL_1 = 100000000
GD.COIN_LEVEL_2 = 10000000000
GD.COIN_LEVEL_3 = 100000000000
GD.COIN_LEVEL_4 = 10000000
GD.COIN_LEVEL_5 = 1000000
GD.COIN_LEVEL_6 = 100000
GD.COIN_LEVEL_7 = 1000000000
GD.COIN_LEVEL_8 = 1000000000000

----
-- 支付部分内容
--

---  支付部分 ， 类型 buyType  BUY_COIN_DIAMOND_TYPE
GD.BUY_TYPE = {
    PIGGYBANK_TYPE = "Pig", -- 小猪银行
    CASHBONUS_TYPE = "CashBonus",
    CASHBONUS_TYPE_NEW = "CashBonusNew",
    TwoChooseOneGiftSale = "TwoChooseOneGiftSale",
    OnePlusOneSale = "OnePlusOneSale",
    STORE_TYPE = "Store", -- 金币商城类型
    GEM_TYPE = "Gem", -- 钻石商城类型
    SPECIALSALE = "SpecialSale", --促销
    NOCOINSSPECIALSALE = "NoCoinsSpecialSale", --没钱促销
    THEME_TYPE = "Theme", --主题促销
    CHOICE_TYPE = "Choice", --多档促销
    CHOICE_TYPE_NOVICE = "NewUserChoice", --新手多档促销
    SEVEN_DAY = "SevenDay", --七日类型促销
    BOOST_TYPE = "Boost", -- 在商城里面购买 boost me 道具
    LUCKY_SPIN_TYPE = "LuckySpin", -- 购买 lucky spin
    LUCKY_SPINV2_TYPE = "LuckySpinV2", -- 购买 lucky spinV2
    KEEPRECHARGE = "Continuous", --连续充值
    NOVICE_KEEPRECHARGE = "NewUserContinuous", --新手连续充值
    LEVEL_DASH_TYPE = "LevelDash",
    ATTEMPT = "Attempt", --常识性购买
    SEVEN_DAY_NO_COIN = "SevenDayNoCoins", --七日类型无金币促销
    QUEST_SALE = "QuestSale",
    BINGO_SALE = "BingoSale",
    DINNERLAND_SALE = "DinnerLandSale",
    QUEST_SKIPSALE = "QuestSkipSale", -- QUEST 跳关
    QUEST_SKIPSALE_PlanB = "QuestSkipSaleItem", -- QUEST 跳关 购买跳关道具
    --大富翁
    RICHMAN_SALE = "RichManSale",
    --新版大富翁
    WORLDTRIP_SALE = "WorldTripSale",
    DartsGame = "DartsGame",
    --blast活动购买
    BLAST_SALE = "BlastSale",
    NEWBLAST_SALE = "NewUserBlastSale",
    LUCKYCHALLENGE_SALE = "LuckyChallengeSale",
    COINPUSHER_SALE = "CoinPusherSale",
    --CoinPusher活动购买
    -- BattlePass购买
    BP_UNLOCK = "BattlePassUnlock",
    BP_UNLOCK_ADDLV = "BattlePassUnlockAddLevel",
    BP_BUY_LV = "BattlePassBuyLevel",
    BP_SALE = "BattlePassSale",
    WORD_SALE = "WordSale",
    --集字活动购买
    SPECIALSALE_FIRST = "FirstSale", --促销首充
    BETWEENTWO_SALE = "DoubleSale",
    --破产2
    BROKENSALE2 = "BankruptcySale",
    --二选一活动
    -- 关卡比赛购买
    ARENA_SALE = "ArenaSale",
    LEVEL_RUSH_TYPE = "LevelRush",
    DININGROOM_SALE = "DiningRoomSale", -- 新版餐厅促销
    RIPPLE_DASH = "RippleDashUnlock", -- RippleDash(levelrush聚合挑战内购)
    CHALLENGEPASS_UNLOCK = "ChallengePassUnlock", -- 新版聚合挑战内购
    MEMORY_FLYING = "MemoryFlyingSale", -- 6个箱子 购买
    NOVICE_MEMORY_FLYING = "NewUserMemoryFlyingSale", -- 新手6个箱子 购买
    REDECOR_SALE = "RedecorateSale", -- 装修活动促销
    NEWPASS_PASSTICKET = "NewPass", -- newpass 购买促销
    NEWPASS_LEVELSTORE = "NewPassLevelStore", --
    CHALLENGEPASS_LASTSALE = "HolidayChallengeLastSale", -- 新版聚合最后一天促销
    -- bingo比赛付费
    BINGO_RUSH_SALE = "BingoRushSale", -- bingoRush比赛促销
    BINGO_RUSH_NOCOIN_SALE = "BingoRushNoCoinSale", -- bingoRush比赛没钱促销
    BINGO_RUSH_PASS = "BingoRushPass", -- bingoRush比赛pass
    POKER_RECALL_TYPE = "PokerRecall",
    VIDEO_POKER_SALE = "PokerSale", --VideoPoker促销
    MERGE_WEEK = "MergeWeek", -- 合成周卡
    SHOP_DAILYSALE = "DailySale",
    --商城推荐位购买
    DIVINATION = "DivineSale", --占卜促销
    DUCK_SHOT_TYPE = "DuckShot", -- DuckShot
    EASTER_EGGSALE = "EasterEggSale", --2022复活节无线砸蛋
    COLORING = "PaintUnlock", --涂色
    FLOWER = "Flower", --浇花
    MINI_GAME_CASHMONEY = "CashMoney", --CashMoney小游戏购买类型
    NEW_DOUBLE_SALE = "NewDoubleSale", -- 新版二选一
    PIGGY_CLICKER_PAY = "PiggyClicker", -- 快速点击小游戏
    INVITEE_BUY_TYPE = "InviteePass", --被邀请付费
    SCRATCHCARD = "ScratchCard", --刮刮卡
    PINBALLGO = "PinballGo", --弹珠小游戏
    LUCKY_FISH = "LuckFish", -- luckyfish
    PERL_LINK = "PearlsLink", -- PearlsLink
    HOLIDAY_END_SALE = "ChristmasTourDepositSale", -- 聚合挑战结束促销
    NEW_COINPUSHER_SALE = "NewCoinPusherSale", -- 新版推币机
    FACTION_FIGHT_SALE = "FactionFightSale", -- 红蓝对决buff
    TopSale = "StoreUpscaleSale",--商城最高档位付费后促销礼包功能
    PIPECONNECT_SALE = "PipeConnectSale",
    PIPECONNECT_SPECIAL_SALE = "PipeConnectSpecialSale",
    TEAM_RED_GIFT = "ClanRedPackage", --公会红包
    DartsGameV2 = "DartsGameV2",
    NEWUSERPASS_PASSTICKET = "NewUserPass", -- newpass 购买促销
    GROWTH_FUND_UNLOCK = "GrowthFund", -- 成长基金解锁
    GROWTH_FUND_UNLOCK_V3 = "GrowthFundV3", -- 成长基金解锁V3
    SHORT_CARD_DRAW_LOW = "ShortCardDrawLow", -- 黑曜卡单抽
    SHORT_CARD_DRAW_HIGH = "ShortCardDrawHigh", -- 黑曜卡连抽
    LimitedGift = "LimitedGift", -- 限时促销
    NOVICE_LimitedGift = "NewUserLimitedGift", -- 新手限时促销
    VIP_POINTS_BOOST = "VipPointsPool",    -- vip点数池
    ICE_BROKEN_SLAE = "IceBrokenSale", -- 新版破冰促销
    HIGH_MERGE_PURCHASE_STORE = "HighMergePurchaseStore", -- 合成商店
    MONTHLY_CARD = "MonthlyCard", --月卡
    HOLIDAY_WHEEL_PAY = "ChristmasTourPayWheelUnlock", -- 复活节付费转盘
    WILD_DRAW = "WildDraw", -- wild卡转盘
    BINGO_LINE_SALE = "BingoLineSale", -- bingo连线购买
    QUEST_PASS = "QuestPass", 
    CHASE_FOR_CHIPS = "ChaseForChipsPass",    -- 集卡赛季末聚合
    StoreHotSale = "StoreHotSale", --商城热卖
    NEW_SPECIAL_SALE = "NewSpecialSale",  -- 新的促销
    HOUR_DEAL_SALE = "HourDealSale", -- 限时促销
    MAGIC_GARDEN_SALE = "MagicGardenSale",    -- 合成转盘
    TRIPLEXPASS_PASSTICKET = "TriplexPass", -- 三行 newpass 购买促销
    TRIPLEXPASS_LEVELSTORE = "TriplexPassLevelStore", --三行  购买等级商店类型
    DiyComboDealSale = "DiyComboDealSale", --自选促销礼包
    ZOMBIE_RECOVER_SALE = "ZombieRecoverArms", -- zombie回收购买
    RETURN_PASS = "ReturnSignPass", -- 回归签到pass付费解锁
    BIRTHDAY_SALE = "BirthdaySale", -- 生日礼物促销
    TRIPLEXPASS_PASSTICKET_NOVICE = "NewUserTriplePass", -- 三行 新手newpass 购买促销
    TRIPLEXPASS_LEVELSTORE_NOVICE = "NewUserTriplexPassLevelStore", --三行 新手newpass 购买等级商店类型
    PIG_TRIO_SALE = "PigTrioSale", -- 小猪三合一促销
    KEEPRECHARGE4 = "KeepRechargeFour", -- 4格连续充值
    CARD_NOVICE_SALE = "NewUserAlbumSale", --新手期集卡促销
    FIRST_SALE_MULTI = "MultiFirstSale", --三档首充
    PIG_CHIP = "PigChip", -- 集卡小猪
    PIG_GEM = "GemPiggy", -- 第二货币小猪银行
    LEVELROADGAME = "levelRoadGame", -- 里程碑小游戏
    LEVEL_ROAD_SALE = "levelRoadSale", -- 等级里程碑促销
    DIYFEATURE_SALE = "DIYFeatureSale", -- DIY 促销
    DIYFEATURE_OVERSALE = "DIYFeatureOverSale", -- DIY 结束促销
    ALBUM_MORE_AWARD = "AlbumMoreAwardSale", -- 限时集卡多倍奖励
    PERL_NEW_LINK = "PearlsLinkOptimize", -- PearlsLink
    ZOMBIE_ARMS_SALE = "ZombieOnslaughtSale", -- zombie促销购买
    DIY_BUFFSALE = "DiyFeatureBuffSale", -- zDIY
    OUTSIDECAVE_SALE = "OutsideCaveSale",  -- 新版大富翁OutsideCave 促销
    OUTSIDECAVE_SPECIAL_SALE = "OutsideCaveSpecialSale",  -- 新版大富翁OutsideCave 特殊促销
    BLIND_BOX_SALE = "BlindBoxSale", -- 集装箱大亨
    JEWELMANIASALE = "JewelManiaSale", --挖矿付费
    MERGE_PASS_UNLOCK = "MergePassSale", -- 合成pass 解锁
    DRAGON_CHALLENGE_PASS_UNLOCK = "DragonChallengePass", --组队打bossPass
    BROKENSALEV2 = "GoBrokeSale", -- 破产促销V2
    FUNCTION_SALE_INFINITE = "FunctionSaleInfinite", -- 无限促销
    LUCKY_CHALLENGEV2_REFRESHSALE_BUY = "LuckyChallengeV2RefreshSale", --钻石挑战V2 购买刷新券
    FUNCTION_SALE_PASS = "FunctionSalePass", -- 大活动PASS
    APP_CHARGE = "AppCharge",
    HolidayNewChallengePass = "HolidayNewChallengePass", -- 圣诞聚合新版 pass购买
    ROUTINE_SALE = "RoutineSale", --新版常规促销
    SIDEKICKS_LEVEL_SALE = "SidekicksLevelSale", -- 宠物荣誉促销
    StorePet = "Sidekicks", --商城宠物
    EGYPT_COINPUSHER_SALE = "CoinPusherV3Sale", -- 埃及推币机
    EGYPT_COINPUSHER_PACK_SALE = "CoinPusherV3SpecialSale", -- 埃及推币机 打包促销
    HOLIDAY_NEW_STORE_SALE = "HolidayNewChallengeStoreSale", -- 圣诞聚合新版 促销
    BUCK = "Buck", -- 第三货币 代币
}
-- buy end

--VIP 升级时对应加VIP点数配置表
GD.VIP_LEVELUP_GEAR = 10 -- 每10级为一档
GD.VIP_LEVELUP_BASE_DATA = {
    --  目前配置了10挡 大于最大档位时 会用配置最后一档的配置
    5,
    5,
    8,
    10,
    10,
    12,
    12,
    12,
    12,
    15
}

GD.SHOP_RESET_TIME_LIST = {0, 8, 16, 24} -- 对应重置时间对应 24小时时刻表

-- 商城buff
GD.SHOP_BUFF_MULTIPE_LIST = {2, 30} -- 对应升级倍数
GD.ONE_DAY_TIME_STAMP = 86400 --一天的时间戳增量
GD.SHOP_BUFF_BASE_PRICE = {
    -- 对应三个套餐类型 1、抽成 2、升级 3、抽成加升级 4、firstTimeSpecile (双buff)
    {199, 499, 899}, -- 档位从小到大排列从 1.99 美金到 9.99美金   。存储的是美分转化为美金时需要 / 100
    {199, 299, 499},
    {199, 499, 999},
    {199, 499, 999}
}
GD.SHOP_BUFF_BASE_DAY = {
    -- 对应三个套餐类型的天数 1、抽成 2、升级 3、抽成加升级 4、firstTimeSpecile (双buff)
    {1, 3, 7},
    {1, 3, 7},
    {1, 3, 7},
    {2, 6, 14}
}

--每小时奖励基数根据等级
GD.HOUR_REWARD_LIST = {600000, 800000, 1100000, 1500000, 2000000, 2600000, 3500000, 4800000, 6400000, 8400000, 11000000}

--========== Adjust 升级事件追踪 ========

GD.ADJUST_LEVEL = {3, 5, 10, 15, 20, 25, 30, 35, 40, 45, 50}
GD.ADJUST_LEVEL_EVENT_ID = {
    ADJUST_LEVEL_3 = "y6h9ju",
    ADJUST_LEVEL_5 = "2ojx2y",
    ADJUST_LEVEL_10 = "ibknho",
    ADJUST_LEVEL_15 = "zdpfgn",
    ADJUST_LEVEL_20 = "gynpd1",
    ADJUST_LEVEL_25 = "xsysme",
    ADJUST_LEVEL_30 = "w8902o",
    ADJUST_LEVEL_35 = "y30cue",
    ADJUST_LEVEL_40 = "zg6erv",
    ADJUST_LEVEL_45 = "vjtrxz",
    ADJUST_LEVEL_50 = "4k7b0j"
}

-- 每日签到数据信息
GD.DAILY_REWARDS = {0, 0.1, 0.2, 0.3, 0.5}
-- GD.DAILY_REWARDS = {0,0.1,0.3,0.5,0.7,1,1.5}
---- 关卡赔率信息  , TAG_CTRL_PAYOUT
GD.ENUM_CTRL_PAYOUT = {
    PAYOUT_0P9 = 0,
    PAYOUT_2P0 = 1,
    PAYOUT_0P5 = 2,
    PAYOUT_0P85 = 3,
    PAYOUT_1P0 = 4,
    PAYOUT_1P2 = 5,
    PAYOUT_1P5 = 6,
    PAYOUT_FIXED = 7 --固定赔率控制
}

---救济金---------------------------------------------
GD.MAX_RELIEF_FUNDS_TIMES = 6 --给救济金的次数限制
GD.COIN_NULL_NUM = 5 --快没有钱的区间
GD.COIN_NULL_LIMITED_NUM = 4 --救济金区间个数
GD.RELIEF_FUNDS_LEVEL_NUM = 5 --给救济金的等级个数

GD.RELIEF_LEVEL_NUM = {5, 10, 20, 30, 39} -- 救济金等级区间
GD.COIN_NULL_LIMITED = {
    {20000000, 21000000, 22000000, 23000000, 24000000}, -- 5~9
    {29000000, 31000000, 33000000, 35000000, 37000000}, -- 10~19
    {56000000, 60000000, 65000000, 70000000, 73000000},
    -- 20~ 30
    {89000000, 91000000, 95000000, 100000000, 105000000}
    --30~ 39
}

--大赢类型
GD.RELIEF_TYPE = {
    NORMALSPIN = 1,
    FREESPIN = 2,
    RESPIN = 3
}

---SHOP类型
GD.SHOP_BOOSTER = {
    SHOP = 1,
    BOOSTER = 2
}

-----------------------------------------------救济金-
--大厅滑动广播条类型
GD.LOBBY_LAYOUT_FACEBOOK = 1
GD.LOBBY_LAYOUT_RATEUS = 2
GD.LOBBY_LAYOUT_SALE = 4
GD.LOBBY_LAYOUT_FIRSTBUY = 5
GD.LOBBY_LAYOUT_PIGGYNOVICEDISCOUNT = 6
GD.LOBBY_LAYOUT_NEWUSER_QUEST = 7 -- 新手Quest轮播图
GD.LOBBY_LAYOUT_FIRSTCOMMOMSALE = 8 -- 首充促销
GD.LOBBY_LAYOUT_HOLIDAYENDSALE = 9 -- 首充促销
GD.LOBBY_LAYOUT_ICEBREAKERSLAE = 10 -- 新破冰促销
GD.LOBBY_LAYOUT_BIRTHDAYSLAE = 11 -- 生日礼物促销
GD.LOBBY_LAYOUT_NEW_USER_CARD_OPEN = 12 --- 新手集卡开启活动轮播展示
GD.LOBBY_LAYOUT_CARD_NOVICE_DOUBLE_REWARD = 13 --- 新手集卡双倍奖励轮播展示
GD.LOBBY_LAYOUT_CARD_NOVICE_SALE = 14 --- 新手集卡促销轮播展示
GD.LOBBY_LAYOUT_FIRST_SALE_MULTI = 15 -- 三档首冲

--设计分辨率

--初始显示金币
GD.FIRST_LOBBY_COINS = 1000000

--升级配置表里的名称 对应客户端资源名称
GD.LEVEL_REWARD_ENMU = {
    MAXBET = "maxbet",
    CLUB = "club",
    TEST = "test",
    CASHMONEY = "cash",
    VIP = "vip",
    CASHWHEEL = "wheel",
    COINS = "coins"
}
GD.AdditionTaskId = 4
--是否有大奖推送
GD.WINNER_NOTIFICATIONS = "winner_Notifications"
