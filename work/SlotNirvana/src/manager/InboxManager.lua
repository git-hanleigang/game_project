--[[--
    Inbox管理
    主要处理：
        数据处理类的句柄
        请求接口
]]
--fix ios 0224
local ParseInboxData = util_require("data.inboxData.ParseInboxData")
local InboxFriendRunData = util_require("data.inboxData.InboxFriendRunData")
local InboxCollectRunData = util_require("data.inboxData.InboxCollectRunData")
local InboxFriendNetwork = util_require("data.inboxData.InboxFriendNetwork")
local InboxCollectNetwork = util_require("data.inboxData.InboxCollectNetwork")

local InboxManager = class("InboxManager")
InboxManager.m_instance = nil

InboxManager.m_showInboxTimes = nil

InboxManager.m_collectCoin = nil
InboxManager.m_collectGems = nil
InboxManager.m_readTime = nil

-- InboxManager.m_lastRequestSDKTime = nil
InboxManager.m_isClickRewardVideo = false

InboxManager.m_updateTime = 300

-- 服务器下发邮件ID
InboxManager.TYPE_NET = {
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
}

-- 自定义邮件类型 （注意:优惠劵以icon为key）
InboxManager.TYPE_LOCAL = {
    spinBonusReward = "spinBonusReward",
    -- sendCoupon = "sendCoupon",      -- 废弃
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
    Coupon_Register_newYear2022 = "Coupon_Register_newYear2022", -- 新年签到优惠卷
    GemSale_newYear2022 = "GemSale_newYear2022", -- 新年签到钻石商城优惠卷
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
}

-- 构造函数
function InboxManager:ctor()
    self.m_parseData = ParseInboxData:create()
    self.m_sysRunData = InboxCollectRunData:create()
    self.m_sysNetwork = InboxCollectNetwork:create()
    self.m_friendRunData = InboxFriendRunData:create()
    self.m_friendNetwork = InboxFriendNetwork:create()

    -- self.m_lastRequestSDKTime = 0

    self:registerObserveEvent()
end

function InboxManager:getInstance()
    if InboxManager.m_instance == nil then
        InboxManager.m_instance = InboxManager.new()
    end
    return InboxManager.m_instance
end

function InboxManager:registerObserveEvent()
    -- 刷新本地邮件
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            gLobalInboxManager:getSysRunData():updataLocalMail()
            gLobalInboxManager:getSysRunData():addLocalMail()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_PAGE)
        end,
        ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL
    )
end
--------------------特殊逻辑处理-------------------------------
function InboxManager:getNewAppVer()
    -- local filePath = device.writablePath .. "/Version.json"
    local content = globalData.GameConfig.versionData
    if not content then
        return "1.0.0"
    end

    local newAppVer = "1.0.0" -- 最新app version
    if device.platform == "ios" then
        newAppVer = content["ios"]["new_app_version"] -- 最新app version
    elseif device.platform == "android" then
        newAppVer = content["new_app_version"] -- 最新app version
        if MARKETSEL == AMAZON_MARKET then
            newAppVer = content["amazon"]["new_app_version"] -- 最新app version
        end
    end

    return newAppVer
end

-- 数据埋点
function InboxManager:setSourceData(data)
    self.m_sourceData = data
end

function InboxManager:sendFireBaseClickLog()
    if globalFireBaseManager.sendFireBaseLogDirect then
        if self.m_sourceData then
            globalFireBaseManager:sendFireBaseLogDirect(self.m_sourceData)
        else
            globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.InboxMailClick)
        end
    end
end

function InboxManager:initReadTime()
    self.m_readTime = os.time()
end

function InboxManager:getReadTime()
    return self.m_readTime
end
---------------------------------------------------

function InboxManager:getParseData()
    return self.m_parseData
end

function InboxManager:getSysRunData()
    return self.m_sysRunData
end

function InboxManager:getSysNetwork()
    return self.m_sysNetwork
end

function InboxManager:getFriendRunData()
    return self.m_friendRunData
end

function InboxManager:getFriendNetwork()
    return self.m_friendNetwork
end

function InboxManager:setShowInboxTimes(count)
    self.m_showInboxTimes = count
end

function InboxManager:getShowInboxTimes()
    return self.m_showInboxTimes or 0
end

function InboxManager:addShowInboxTimes()
    self.m_showInboxTimes = (self.m_showInboxTimes or 0) + 1
end

function InboxManager:setInboxCollectStatus(_status)
    self.m_collectStatus = _status
end

function InboxManager:getInboxCollectStatus()
    return self.m_collectStatus
end

function InboxManager:getLobbyBottomNum()
    return self:getMailCount()
end

-- 获取礼物数量
function InboxManager:getMailCount()
    return self.m_sysRunData:getMailCount() + self.m_friendRunData:getMailCount()
end

-- 获取inbox中所有礼物的消息
-- _isFB: 是否请求FB好友邮件数据
function InboxManager:getDataMessage(_successCallFun, _failedCallFun, _isFB)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    self:initReadTime()

    local refreshTimes = 1
    if _isFB then
        refreshTimes = refreshTimes + 1
    end

    local function callback()
        refreshTimes = refreshTimes - 1
        if refreshTimes == 0 then
            -- 刷新红点数据
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, self:getMailCount())
            if _successCallFun then
                _successCallFun()
            end
        end
    end

    -- 请求系统邮件列表
    self.m_sysNetwork:requestMailList(
        callback,
        function()
            if _failedCallFun then
                _failedCallFun()
            end
        end
    )

    -- 请求好友邮件列表
    if _isFB then
        self.m_friendNetwork:requestMailList(callback)
    end
    --300秒更新一次邮箱状态
    self:updateInboxData()
end

function InboxManager:setWatchRewardVideoFalg(state)
    self.m_isClickRewardVideo = state
end

function InboxManager:getWatchRewardVideoFalg()
    return self.m_isClickRewardVideo
end

------------------------------------------------------------------------------
-- -- 向SDK发送请求 时间限制
-- function InboxManager:setRequestSDKTime()
--     self.m_lastRequestSDKTime = globalData.userRunData.p_serverTime
-- end

-- function InboxManager:getRequestSDKTime()
--     return self.m_lastRequestSDKTime
-- end

-- function InboxManager:canRequestSDK()
--     -- if self.m_lastRequestSDKTime and self.m_lastRequestSDKTime > 0 then
--     --     if math.floor(globalData.userRunData.p_serverTime - self.m_lastRequestSDKTime) <= 300000 then
--     --         return false
--     --     end
--     -- end
--     return true
-- end

-- function InboxManager:GetFacebookFriendList()
--     if self.m_friendRunData:isLoginFB() then
--         if self:canRequestSDK() then
--             self:setRequestSDKTime()
--             self:SDK_GetFacebookFriendList()
--         end
--     end
-- end

-- -- 向FACEBOOK SDK请求，拉取好友列表
-- function InboxManager:SDK_GetFacebookFriendList()
--     local function callback(data)
--         local jsonData = util_cjsonDecode(data)
--         if jsonData and jsonData.friendList ~= nil and jsonData.friendList.data ~= nil then
--             if jsonData.flag then
--                 self.m_friendRunData:setFaceBookFriendList(jsonData.friendList.data)
--             end
--             gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_FACEBOOK_FRIEND_LIST, {flag = jsonData.flag})
--         end
--     end
--     globalFaceBookManager:getFaceBookFriendList(callback)
-- end
------------------------------------------------------------------------------
function InboxManager:showInboxLayer(_params)
    if gLobalViewManager:getViewByName("Inbox") ~= nil then
        return
    end
    gLobalViewManager:addLoadingAnimaDelay()
    gLobalInboxManager:getDataMessage(
        function()
            gLobalViewManager:removeLoadingAnima()
            -- 打开邮箱
            local view = util_createView("views.inbox.Inbox", _params)
            view:setName("Inbox")
            if _params and _params.rootStartPos then
                view:setRootStartPos(_params.rootStartPos)
            end
            if _params and _params.senderName and _params.dotUrlType and _params.dotEntrySite and _params.dotEntryType then
                gLobalSendDataManager:getLogPopub():addNodeDot(view, _params.senderName, _params.dotUrlType, true, _params.dotEntrySite, _params.dotEntryType)
            end
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end,
        function()
            gLobalViewManager:removeLoadingAnima()
        end,
        true
    )
end

function InboxManager:updateInboxData()
    if self.m_schduleID then
        scheduler.unscheduleGlobal(self.m_schduleID)
        self.m_schduleID = nil
    end
    self.m_schduleID =
        scheduler.scheduleGlobal(
        function()
            self:getDataMessage(nil, nil, true)
        end,
        300
    )
end

return InboxManager
