----
--系统常量读取 目前只定义了系统解锁等级相关
--
--
local ConstantData = class("ConstantData")
ConstantData.OPENLEVEL_PIGBANK = nil -- 小猪开启等级
ConstantData.OPENLEVEL_DAILYMISSION = nil -- 每日任务开启等级
ConstantData.OPENLEVEL_DAILYMISSION_NOVICE = nil -- 每日任务开启等级
ConstantData.OPENLEVEL_FIRSTQUEST = nil -- 新手quest 开启等级
ConstantData.OPENLEVEL_NORMALQUEST = nil -- normal quest 开启等级
ConstantData.OPENLEVEL_VIP = nil -- vip 开启等级
ConstantData.OPENLEVEL_CASHBONUS = nil -- cash bonus 开启等级
ConstantData.OPENLEVEL_INBOX = nil -- 邮件开启等级
ConstantData.OPENLEVEL_NORMALSALE = nil -- 常规促销开启等级
ConstantData.OPENLEVEL_PAYROULETTE = nil -- 二次付费轮盘开启等级
ConstantData.OPENLEVEL_STORE = nil -- 商店开启等级
ConstantData.OPENLEVEL_ACTIVITY_NEWLEVEL = nil --新关卡推荐班子
ConstantData.PUSHVIEW_POS = nil -- 推送弹版位置信息
ConstantData.ACTIVITY_FIND_BASETIME = nil -- find活动，基础倒计时时间
ConstantData.ACTIVITY_FIND_WRONGTIME = nil -- find活动，连续点击，冷却时间
ConstantData.ACTIVITY_OPEN_LEVEL = nil --7日活动开启等级
ConstantData.ACTIVITY_BET_LIMIT = nil --7日活动参与的bet值 (>=)

ConstantData.CARD_OPEN_LEVEL = nil --集卡活动开启
ConstantData.NEW_CARD_OPEN_LEVEL = nil --新手集卡活动开启

ConstantData.CARD_RecycleCD = nil --卡牌回收冷却时间/h
ConstantData.CARD_GoldenCardCoinAddition = nil --金卡回收加成
ConstantData.CARD_LinkCardStarAddition = nil --Link卡回收星数加成
ConstantData.CARD_LinkRewardCoinsWorth = nil --Link小游戏 奖励的最大金币值多少$

ConstantData.OPENLEVEL_NEWQUEST = nil --quest开启等级
ConstantData.ACTIVITY_QUEST_BUFFTIME = nil --questbuff
ConstantData.ACTIVITY_QUEST_EXTRAPRIZE = nil --剩余时间开启

ConstantData.PIG_SHOW_VALUE = nil --小猪展示美元差值，小猪每提升X刀，展示1次
ConstantData.PIG_SHOW_TIME = nil --UI单次展示时间，S
ConstantData.FREE_QUEST_BUFF_OPEN_TIME = nil --免费questbuff开启时间，只持续1天
ConstantData.PIG_SHOW_SPIN_TIMES = nil --spin X次弹1次小猪
ConstantData.PIG_SHOW_LEVEL = nil --小猪曝光点显示等级
ConstantData.FIND_EXTRATIME_BUFFLIMIT = nil --Find活动额外时间促销buff持续时间，单位S
ConstantData.FIND_DOUBLE_BUFFLIMIT = nil --Find活动双倍掉落促销buff持续时间，单位Ss

ConstantData.BIG_REWARD_INTERVEL = 10
ConstantData.CLUB_OPEN_LEVEL = 50 --高倍场开启等级
ConstantData.CLUB_OPEN_LEVEL_NOVICE = nil --高倍场开启等级_新手期
ConstantData.CLUB_OPEN_LEVEL_COPY = ConstantData.CLUB_OPEN_LEVEL --高倍场开启等级COPY

ConstantData.CLUB_OPEN_POINTS = nil
ConstantData.FREE_CLUB_POINTS_TIMES = nil
ConstantData.CLUB_EVERY_DURATION = nil
ConstantData.CLUB_BENEFIT_STORE_EXTRA_COIN_MUL = nil
ConstantData.CLUB_BENEFIT_BONUS_EXTRA_REWARD = nil

ConstantData.FREE_CLUB_POINT_SPIN_GET_MAX = nil
ConstantData.FREE_CLUB_POINT_LEVEL_UP_MAX = nil
ConstantData.FREE_CLUB_POINT_VAULT = nil
ConstantData.FREE_CLUB_POINT_DAILY_BONUS = nil
ConstantData.FREE_CLUB_POINT_LEVEL_HOURLY_BONUS = nil
ConstantData.FREE_CLUB_POINT_LEVEL_QUATER_BONUS = nil
ConstantData.FREE_CLUB_POINT_LEVEL_STORE_GIFT = nil
ConstantData.FREE_CLUB_POINT_LEVEL_JACKPOT = nil
ConstantData.FREE_CLUB_POINT_SPIN_LIMIT = nil

ConstantData.FBFANS_URL = nil --FBFansUrl
ConstantData.FBFANS_OPEN_DAY = nil --FBFans开发时间
ConstantData.FBFANS_SHOW_TIMES = nil --FBFans每日展示次数
ConstantData.FBSHOW_TIMES = nil --FBFans单次展示次数
ConstantData.FBSHOW_LEVEL = nil --FBFans显示等级

ConstantData.TEST_PAY_LEVEL = nil --试探性付费

ConstantData.UPDATE_TIPS_LEVEL = nil --新手引导，版本更新提示等级
ConstantData.MOREGAME_TIPS_LEVEL = nil --新手引导，更多关卡可玩的提示等级
ConstantData.MAXBET_TIPS_LEVEL = nil --新手引导，再次提示提高BET的等级
ConstantData.FBSLIDSHOW_TIPS_LEVEL = nil --新手引导，FB登陆（轮播）展示等级
ConstantData.RATEUSSLID_TIPS_LEVEL = nil --新手引导，rete us（轮播）展示等级
ConstantData.FIRSTPAYSLID_TIPS_LEVEL = nil --新手引导，首充（轮播）展示等级
ConstantData.ALLTIPSSHOWINHALL_LEVEL = nil --新手引导，X级以前返回大厅不弹任何提示和引导
ConstantData.STOREBONUSTIPSSHOW_LEVEL = nil --新手引导，商店bonus引导等级

ConstantData.OPEN_NEWLEVEL_ID = nil --新关卡推荐id

ConstantData.LINK_SHOWTIME_LIMIT = nil --link 显示弹出次数

ConstantData.RATEUS_REWARD_COINS = nil --rateus 奖励钱数

ConstantData.ROULETTE_RANDOMS = nil --轮盘
ConstantData.CASHVAULT_GOLDBOX_RANDOMS = nil --cashbonus 金 奖励钱数
ConstantData.CASHVAULT_SILVERBOX_RANDOMS = nil --cashbonus 银 奖励钱数

ConstantData.OPENLEVEL_NEWUSERQUEST = 5 --新手的quest开启等级

ConstantData.QUEST_JACKPOT_POOL_BOTTOM = nil --quest rank奖池上线%
ConstantData.QUEST_JACKPOT_POOL_TOP = nil --quest rank奖池下线%
ConstantData.QUEST_JACKPOT_POOL_ADD = nil --quest rank奖池增量%
ConstantData.QUEST_JACKPOT_POOL_TOP_MAX = nil --quest rank奖池滚动超量上限
ConstantData.QUEST_JACKPOT_POOL_TOP_SPEED_MAX = nil --quest rank奖池超量滚动速度

ConstantData.NEW_USER_GUIDE_LEVEL = nil --新手期

ConstantData.CHALLENGE_MAX_LEVEL = 6 --luckchallenge max level
ConstantData.CHALLENGE_OPEN_LEVEL = 40 --luckchallenge open level
ConstantData.CHALLENGE_OPEN_LEVEL_NOVICE = nil --luckchallenge open level_新手期
ConstantData.CHALLENGE_SALE_TIMES = nil --luckchallenge 促销弹出时间间隔

ConstantData.INBOX_FACEBOOK_COIN = nil -- 邮箱赠送金币开启等级
ConstantData.INBOX_FACEBOOK_CARD = nil -- 邮箱赠送卡牌开启等级
ConstantData.RATEUS_SWITCH = nil -- rateus开启标志  0： 都不打开 1： ios打开 2： 安卓打开 3： 都打开
ConstantData.RATEUS_SWITCH_SETTINGS = nil -- rateus(设置界面中)开启标志  0： 都不打开 1： ios打开 2： 安卓打开 3： 都打开

ConstantData.BATTLEPASS_OPEN_LEVEL = 25 --battlePass open level
ConstantData.DRAW_OPEN_LEVEL = nil -- 充值抽奖活动开启等级

ConstantData.WINNER_NOTIFICATIONS_FLAG = 0 --推送开关默认值 0 是关闭 1开启

ConstantData.UPGRADE_IOS_FIX_FLAG = 0 --ios1.3.9默认是修复的 1屏蔽修复

ConstantData.CLAN_OPEN_LEVEL = 20 -- 公会开启等级
ConstantData.CLAN_OPEN_SIGN = false -- 公会功能是否开启
ConstantData.CLAN_REMIND_OPEN_LEVEL = 45 -- 未加入公会提醒弹窗最低弹出等级 >=
ConstantData.CLAN_REMIND_OPEN_TIMES = 5 -- 未加入公会提醒弹窗最多弹出次数 >
ConstantData.ATT_BIGWIN_SPIN_LIMIT = 100 --ATT 上次弹板弹出后玩家spin次数
ConstantData.ATT_BIGWIN_WIN_MULTIPLE = 8 --ATT spin结果赢钱倍数
ConstantData.ATT_BIGWIN_POP_CDTIME = {} --ATT 弹板间隔时间
ConstantData.ATT_BIGWIN_POP_MAXTIMES = 3 --ATT 大赢弹板最大弹出次数

ConstantData.CARD_STATUE_UNLOCK_TIME = "" -- 神像章节解锁日期

ConstantData.USERDATA_TRANSFER_LEVEL = 0 --用户数据转移功能开启等级

ConstantData.ACT_IGNORE_LEVEL_NOVICE = 0 --ab分组该玩家检测活动是是否忽略等级判断

ConstantData.NOVICE_LEFT_FRAME_GUIDE_LEVEL = 21 -- 关卡内悬浮窗引导最低等级
ConstantData.NOVICE_CARD_LEFT_FRAME_SHOW_LEVEL = 0 -- 关卡内左边条集卡入口显示最低等级
ConstantData.NOVICE_NEWUSERQUEST_LEVELUP_CONTENT = nil -- 新手quest 升级弹板文
ConstantData.NOVICE_NEWUSERQUEST_LEVELUP_REWARD = nil -- 新手quest 升级弹板奖励金币
ConstantData.NOVICE_NEWUSERQUEST_LOGIN_CONTENT = nil -- 新手quest 登录弹板文字
ConstantData.NOVICE_NEWUSERQUEST_LOGIN_REWARD = nil -- 新手quest 登录弹板奖励金币
ConstantData.NOVICE_FIRSTPAY_ENDLEVEL = 100 -- 首充结束等级
ConstantData.NOVICE_ACT_ENTRANCE_GUIDE_LEVEL = 0 -- 活动总入口引导最低等级
-- season_3 新增特性
ConstantData.NOVICE_NOCOINS_OPEN_LEVEL = 100 --新手期 nocoins 开启等级
ConstantData.NOVICE_INOBXRED_SHOW_LEVEL = 20 --新手期 设置界面inbox红点显示等级
ConstantData.NOVICE_CASHBONUS_OPEN_LEVEL = 20 --新手期 金银库开放等级
ConstantData.NOVICE_PUSH_ADAPT_DAYS = 7 --新手期 推送限制注册天数
ConstantData.NOVICE_PUSH_TYPE_1_TIMES = 3 --新手期 type1推送限制次数
ConstantData.NOVICE_PUSH_TYPE_2_TIMES = nil --新手期 type2推送限制次数
ConstantData.NOVICE_PUSH_TYPE_2_COINS = nil --新手期 type2推送限制 持金数
ConstantData.NOVICE_PUSH_TYPE_2_NOSPIN_TIME = 3600 --新手期 type2推送限制 x时间内没操作
ConstantData.NOVICE_PUSH_TYPE_2_LEVEL_RANGE = nil --新手期 type2推送等级限制 [x,y] 闭区间
ConstantData.NOVICE_FIRSTPAY_OPENLEVEL = 1 --新手期 首充展示等级
ConstantData.NOVICE_FACEBOOK_GROUP_OPENLEVEL = 40 --新手期3.0 FB 新弹板流程 限制等级
ConstantData.NOVICE_DAILYPASS_PRUCHASES_LEVEL = 25 -- 新手期4.0 pass关闭主界面弹出购买弹板限制等级   NoviceDailyPassPurchaseLevel
ConstantData.NOVICE_UNLOCK_NEW_LEVEL = 25 -- 新手期4.0 关卡内新关提示限制等级  NoviceNewGameReOpenLevel
ConstantData.NOVICE_FIRSTPAY_POPLEVEL = nil -- 新手期全组通用的 升级首充促销弹出等级限制

ConstantData.NOVICE_FEATURES_GROUP = nil --是否支持 新手期修改特性

ConstantData.NEWPASS_OPEN_LEVEL = 20 --newPass open level
ConstantData.NEWUSERPASS_OPEN_LEVEL = 5 --newUserPass open level 新手pass开启等级
ConstantData.NEWUSERPASS_OPEN_SWITCH = 0 --newUserPass open 开关 新手pass开启 0 关闭 1 开启

ConstantData.DAILYBOUNS_OPEN_LEVEL = 20 -- 每日签到开启等级
ConstantData.LOTTERY_OPEN_LEVEL = 18 -- 乐透彩票开启等级
ConstantData.LOTTERY_OPEN_SIGN = false -- 乐透彩票是否开启
ConstantData.NOVICE_CHECK_OPEN_LEVEL = nil -- 新手期每日签到开启等级
ConstantData.NOVICE_CHECK_V2_OPEN_LEVEL = nil -- 新手期每日签到开启等级 B组
ConstantData.NOVICE_NEWUSER_SIGNIN_SWITCH = nil -- 新手期每日签到开关

ConstantData.POKER_PAYTABLE = nil -- 扑克paytable

ConstantData.QUESTIONNAIRE_URL = nil
ConstantData.BIGRCONTACT_URL = nil

ConstantData.COMMON_JACKPOT = nil
ConstantData.COMMON_JACKPOT_GAME_NAMES = {} -- 公共jackpot关卡名字
ConstantData.CARD_NADOMACHINE_BUBBLE_DOLLOR = 0

ConstantData.INVITE_LEVEL = 0
ConstantData.FBSHARE_URL = nil
ConstantData.CARD_SPECIAL_REWAR = 1 -- 集卡赛季末收益提升
ConstantData.FB_VIP_INVITE_URL = ""

ConstantData.QUEST_NEWUSER_THEME = 0
ConstantData.NEWBIE_TASK_COINS = {} -- 新手任务 给的奖励
ConstantData.AVATAR_TASK_OPEN_LV = 10 -- 头像框任务开启等级
ConstantData.NOVICE_BLAST_COLLECT_LAYER_LV = 0 -- 新手blat50级前不弹  收集弹板
ConstantData.NOVICE_SERVER_INIT_COINS = 0 -- 玩家第一次登录服务器初始化的金币值
ConstantData.NOVICE_ICE_BROKEN_SALE_GTL_POP_CD = 0 -- 新破冰促销未购买关卡返回大厅弹窗cd
ConstantData.BEST_DEAL = "" -- 促销入口
ConstantData.NEW_SUER_FIRST_GUIDE_GO_SLOT_GAMME = false -- 玩家第一步引导是否是 直接进入关卡
ConstantData.FIRST_COMMON_SALE_SPECIAL_THEME = false -- 首充礼包使用特殊主题
ConstantData.NOVICE_SHOP_CARNIVAL_ANI_ACTIVE = true -- 商城膨胀动画 是否显示
ConstantData.NOVICE_NEW_QUEST_OPEN = true -- 是否支持新手quest
ConstantData.NOVICE_NEW_USER_CARD_OPEN = false  -- 新手期集卡 开启开关
ConstantData.FIRST_COMMON_SALE_HIDE_TIME  = false -- 首充礼包 隐藏倒计时
ConstantData.RATE_US_LAYER_SPAN_TIME  = nil -- rateus弹板 间隔cd时间
ConstantData.RATE_US_LAYER_MAX_COUNT  = nil -- rateus弹板 最大弹出次数
ConstantData.RATE_US_LAYER_CD_CONFIG_OPEN  = false -- rateus弹板 spin次数区间 不同cd开关
ConstantData.RATE_US_LAYER_SPIN_COUNT  = nil -- rateus弹板 spin次数区间
ConstantData.RATE_US_LAYER_OPEN_LEVEL  = nil -- rateus弹板 限制等级
ConstantData.SIDE_KICKS_OPEN_LEVEL = 100 -- 宠物系统开启等级
ConstantData.RATE_US_SETTING_ENTRY_OPEN_LEVEL  = nil -- rateus 设置处入口显示 限制等级
ConstantData.RATE_US_LAYER_ONE_STAR_ADD_CD  = 0 -- 评分5星以下每低1星，评分弹板 CD增加 24小时
ConstantData.RATE_US_LAYER_SPECIAL_SPIN_WIN_FORCE_POP  = false --  rateus弹板 特殊大赢就算 评论过了 也弹出
ConstantData.RATE_US_LAYER_USE_NEW_FIVE_DESC_RES  = false --  rateus弹板 使用新版 资源 5分描述
ConstantData.LOCALPUSH_CODE  = nil -- 离线推送领奖码

-- RouletteRandoms
-- CashVaultGoldBoxRandoms
-- CashVaultSilverBoxRandoms
function ConstantData:ctor()
    self.PUSHVIEW_POS = {}
    self.NEW_USER_GUIDE_LEVEL = 19 --新手期
end

function ConstantData:parseData(datas)
    for i = 1, #datas do
        local data = datas[i]
        if data.systemKey == "PigBankOpenLevel" then
            self.OPENLEVEL_PIGBANK = tonumber(data.value) -- 小猪开启等级
        elseif data.systemKey == "DailyMissionOpenLevel" then
            if not self.OPENLEVEL_DAILYMISSION_NOVICE then
                self.OPENLEVEL_DAILYMISSION = tonumber(data.value) or 0 -- 每日任务开启等级
            end
        elseif data.systemKey == "FirstQusetOpenLevel" then
            self.OPENLEVEL_FIRSTQUEST = tonumber(data.value) -- 新手quest 开启等级
        elseif data.systemKey == "NormalQusetOpenLevel" then
            self.OPENLEVEL_NORMALQUEST = tonumber(data.value) -- 新手quest 开启等级
        elseif data.systemKey == "VipOpenLevel" then
            self.OPENLEVEL_VIP = tonumber(data.value) -- vip 开启等级
        elseif data.systemKey == "CashBonusOpenLevel" then
            self.OPENLEVEL_CASHBONUS = tonumber(data.value) -- cash bonus 开启等级
        elseif data.systemKey == "InboxOpenlevel" then
            self.OPENLEVEL_INBOX = tonumber(data.value) -- 邮件开启等级
        elseif data.systemKey == "NormalSaleOpenLevel" then
            self.OPENLEVEL_NORMALSALE = tonumber(data.value) -- 常规促销开启等级
        elseif data.systemKey == "PayRouletteOpenLevel" then
            self.OPENLEVEL_PAYROULETTE = tonumber(data.value) -- 二次付费轮盘开启等级
        elseif data.systemKey == "StoreOpenLevel" then
            self.OPENLEVEL_STORE = tonumber(data.value) -- 商店开启等级
        elseif data.systemKey == "NewLevelOpenLevel" then
            --新关卡推荐班子
            self.OPENLEVEL_ACTIVITY_NEWLEVEL = tonumber(data.value)
        elseif
            data.systemKey == PushViewPosType.LoginToLobby or data.systemKey == PushViewPosType.LevelToLobby or data.systemKey == PushViewPosType.CloseStore or
                data.systemKey == PushViewPosType.NoCoinsToSpin
         then
            self.PUSHVIEW_POS[data.systemKey] = tonumber(data.value)
        elseif data.systemKey == "ActivityFindBaseTime" then
            self.ACTIVITY_FIND_BASETIME = tonumber(data.value)
        elseif data.systemKey == "ActivityFindWrongTimes" then
            self.ACTIVITY_FIND_WRONGTIME = tonumber(data.value)
        elseif data.systemKey == "ActivityBetLimit" then
            self.ACTIVITY_BET_LIMIT = tonumber(data.value)
        elseif data.systemKey == "ActivityOpenLevel" then
            self.ACTIVITY_OPEN_LEVEL = tonumber(data.value)
        elseif data.systemKey == "CardOpenLevel" then
            self.CARD_OPEN_LEVEL = tonumber(data.value)
        elseif data.systemKey == "NewCardOpenLevel" then
            self.NEW_CARD_OPEN_LEVEL = tonumber(data.value)
        elseif data.systemKey == "RecycleCD" then
            self.CARD_RecycleCD = tonumber(data.value)
        elseif data.systemKey == "RecycleGoldenCardAddition" then
            -- 解析集卡系统 回收系统金卡提供的金币加成比例 --
            self.CARD_GoldenCardCoinAddition = {}
            local list = util_string_split(data.value, ";")
            if list and #list > 0 then
                for j = 1, #list do
                    local config = util_string_split(list[j], "-", true)
                    local star = config[1]
                    local mul = config[2]
                    self.CARD_GoldenCardCoinAddition[star] = mul
                end
            end
        elseif data.systemKey == "RecyclePuzzleCardAddition" then
            self.CARD_PuzzleCardCoinAddition = tonumber(data.value)
        elseif data.systemKey == "RecycleSpecialCoinCardAddition" then
            self.CARD_StatueCardCoinAddition = {}
            local list = util_string_split(data.value, ";")
            if list and #list > 0 then
                for j = 1, #list do
                    local config = util_string_split(list[j], "-", true)
                    local star = config[1]
                    local mul = config[2]
                    self.CARD_StatueCardCoinAddition[star] = mul
                end
            end
        elseif data.systemKey == "RecycleSpecialCardStarAddition" then
            self.CARD_StatueCardStarAddition = tonumber(data.value)
        elseif data.systemKey == "RecycleLinkCardStarAddition" then
            self.CARD_LinkCardStarAddition = tonumber(data.value)
        elseif data.systemKey == "LinkGameMaxPrize" then
            self.CARD_LinkRewardCoinsWorth = tonumber(data.value)
        elseif data.systemKey == "QuestOpenLevel" then
            self.OPENLEVEL_NEWQUEST = tonumber(data.value)
        elseif data.systemKey == "QuestBuffTime" then
            self.ACTIVITY_QUEST_BUFFTIME = tonumber(data.value)
        elseif data.systemKey == "QuestExtraPrize" then
            self.ACTIVITY_QUEST_EXTRAPRIZE = tonumber(data.value)
        elseif data.systemKey == "PigShowValue" then
            self.PIG_SHOW_VALUE = tonumber(data.value)
        elseif data.systemKey == "PigShowTime" then
            self.PIG_SHOW_TIME = tonumber(data.value)
        elseif data.systemKey == "FreeQuestBuffOpenTime" then
            self.FREE_QUEST_BUFF_OPEN_TIME = data.value
        elseif data.systemKey == "PigShowSpinTimes" then
            self.PIG_SHOW_SPIN_TIMES = tonumber(data.value)
        elseif data.systemKey == "PigShowLevel" then
            self.PIG_SHOW_LEVEL = tonumber(data.value)
        elseif data.systemKey == "FindExtraTimeBuffLimit" then
            self.FIND_EXTRATIME_BUFFLIMIT = tonumber(data.value)
        elseif data.systemKey == "FindDoubleBuffLimit" then
            self.FIND_DOUBLE_BUFFLIMIT = tonumber(data.value)
        elseif data.systemKey == "ClubOpenLevel" then
            if not self.CLUB_OPEN_LEVEL_NOVICE then
                self.CLUB_OPEN_LEVEL = tonumber(data.value)
            end
        elseif data.systemKey == "NoviceClubOpenLevel" then
            self.CLUB_OPEN_LEVEL = tonumber(data.value)
            self.CLUB_OPEN_LEVEL_NOVICE = self.CLUB_OPEN_LEVEL
        elseif data.systemKey == "ClubEveryDuration" then
            --高倍场持续时间
            self.CLUB_EVERY_DURATION = tonumber(data.value)
        elseif data.systemKey == "FreeClubPointSpinTimes" then
            --高倍场普通spin次数
            self.FREE_CLUB_POINTS_TIMES = tonumber(data.value)
        elseif data.systemKey == "ClubOpenPoints" then
            --高倍场点数
            self.CLUB_OPEN_POINTS = tonumber(data.value)
        elseif data.systemKey == "FreeClubPointSpinGetMax" then
            --高倍场spin一轮最多获得的点数
            self.FREE_CLUB_POINT_SPIN_GET_MAX = tonumber(data.value)
        elseif data.systemKey == "FreeClubPointLevelUpGetMax" then
            --高倍场spin一轮最多获得的点数
            self.FREE_CLUB_POINT_LEVEL_UP_MAX = tonumber(data.value)
        elseif data.systemKey == "FreeClubPointVault" then
            --高倍场spin一轮最多获得的点数
            self.FREE_CLUB_POINT_VAULT = tonumber(data.value)
        elseif data.systemKey == "FreeClubPointDailyBonus" then
            --高倍场spin一轮最多获得的点数
            self.FREE_CLUB_POINT_DAILY_BONUS = tonumber(data.value)
        elseif data.systemKey == "FreeClubPointHourlyBonus" then
            --高倍场spin一轮最多获得的点数
            self.FREE_CLUB_POINT_LEVEL_HOURLY_BONUS = tonumber(data.value)
        elseif data.systemKey == "FreeClubPointQuaterBonus" then
            --高倍场spin一轮最多获得的点数
            self.FREE_CLUB_POINT_LEVEL_QUATER_BONUS = tonumber(data.value)
        elseif data.systemKey == "FreeClubPointStoreGift" then
            --高倍场spin一轮最多获得的点数
            self.FREE_CLUB_POINT_LEVEL_STORE_GIFT = tonumber(data.value)
        elseif data.systemKey == "FreeClubPointJackpot" then
            --高倍场spin一轮最多获得的点数
            self.FREE_CLUB_POINT_LEVEL_JACKPOT = tonumber(data.value)
        elseif data.systemKey == "ClubBenefitStoreExtraCoinMul" then
            self.CLUB_BENEFIT_STORE_EXTRA_COIN_MUL = tonumber(data.value) --高倍场商店免费金币加成
        elseif data.systemKey == "ClubBenefitBonusExtraReward" then
            self.CLUB_BENEFIT_BONUS_EXTRA_REWARD = tonumber(data.value) -- 高倍场免费金币加成
        elseif data.systemKey == "FreeClubPointSpinlimit" then
            self.FREE_CLUB_POINT_SPIN_LIMIT = tonumber(data.value) -- spin 获取高倍场积分最低bet
        elseif data.systemKey == "FBFansUrl" then
            --facebook fans url
            self.FBFANS_URL = data.value
        elseif data.systemKey == "FBVideoUrl" then
            --facebook video url
            self.FB_VIDEO_URL = data.value
        elseif data.systemKey == "FBGroupsUrl" then
            --facebook groups url
            self.FB_GROUPS_URL = data.value
        elseif data.systemKey == "FBFansOpenDay" then
            self.FBFANS_OPEN_DAY = data.value
        elseif data.systemKey == "FBFansShowTimes" then
            --fb展示总次数
            self.FBFANS_SHOW_TIMES = tonumber(data.value)
        elseif data.systemKey == "FBShowTimes" then
            --fb单次展示数
            self.FBSHOW_TIMES = tonumber(data.value)
        elseif data.systemKey == "FBShowLevel" then
            --fb显示等级
            self.FBSHOW_LEVEL = tonumber(data.value)
        elseif data.systemKey == "TestPayLevel" then
            --试探性付费
            self.TEST_PAY_LEVEL = tonumber(data.value)
        elseif data.systemKey == "UpdateTipsLevel" then
            self.UPDATE_TIPS_LEVEL = tonumber(data.value)
        elseif data.systemKey == "MoreGameTipsLevel" then
            self.MOREGAME_TIPS_LEVEL = tonumber(data.value)
        elseif data.systemKey == "MaxBetTipsLevel" then
            self.MAXBET_TIPS_LEVEL = tonumber(data.value)
        elseif data.systemKey == "FBSlidShowLevel" then
            self.FBSLIDSHOW_TIPS_LEVEL = tonumber(data.value)
        elseif data.systemKey == "RateUsSlidShowLevel" then
            self.RATEUSSLID_TIPS_LEVEL = tonumber(data.value)
        elseif data.systemKey == "FirstPaySlidShowLevel" then
            self.FIRSTPAYSLID_TIPS_LEVEL = tonumber(data.value)
        elseif data.systemKey == "AllTipsShowInHallLevel" then
            self.ALLTIPSSHOWINHALL_LEVEL = tonumber(data.value)
        elseif data.systemKey == "StoreBonusTipsShowLevel" then
            self.STOREBONUSTIPSSHOW_LEVEL = tonumber(data.value)
        elseif data.systemKey == "NewLevelOpenID" then
            self.OPEN_NEWLEVEL_ID = tonumber(data.value)
        elseif data.systemKey == "LinkShowTimeLimit" then
            self.LINK_SHOWTIME_LIMIT = tonumber(data.value)
        elseif data.systemKey == "ChallengeMaxLevel" then
            self.CHALLENGE_MAX_LEVEL = tonumber(data.value)
        elseif data.systemKey == "LuckyChallengeOpenLevel" then
            if not self.CHALLENGE_OPEN_LEVEL_NOVICE then
                self.CHALLENGE_OPEN_LEVEL = tonumber(data.value)
            end
        elseif data.systemKey == "NoviceLuckyChallengeOpenLevel" then
            self.CHALLENGE_OPEN_LEVEL = tonumber(data.value)
            self.CHALLENGE_OPEN_LEVEL_NOVICE = self.CHALLENGE_OPEN_LEVEL
        elseif data.systemKey == "RateUsRewardCoins" then
            self.RATEUS_REWARD_COINS = tonumber(data.value)
        elseif data.systemKey == "MegaCashPlayTimes" then
            self.MEGACASH_PLAY_TIMES = tonumber(data.value)
        elseif data.systemKey == "MegaCashMultiply" then
            self.MEGACASH_MULTIPLY = tonumber(data.value)
        elseif data.systemKey == "RouletteRandoms" then
            self.ROULETTE_RANDOMS = tonumber(data.value)
        elseif data.systemKey == "CashVaultGoldBoxRandoms" then
            self.CASHVAULT_GOLDBOX_RANDOMS = tonumber(data.value)
        elseif data.systemKey == "CashVaultSilverBoxRandoms" then
            self.CASHVAULT_SILVERBOX_RANDOMS = tonumber(data.value)
        elseif data.systemKey == "NewUserQuestOpenLevel" then
            self.OPENLEVEL_NEWUSERQUEST = tonumber(data.value)
        elseif data.systemKey == "QuestJackpotBottom" then
            self.QUEST_JACKPOT_POOL_BOTTOM = tonumber(data.value)
        elseif data.systemKey == "QuestJackpotTop" then
            self.QUEST_JACKPOT_POOL_TOP = tonumber(data.value)
        elseif data.systemKey == "QuestJackpotSpeed" then
            self.QUEST_JACKPOT_POOL_ADD = tonumber(data.value)
        elseif data.systemKey == "QuestJackpotTopMax" then
            self.QUEST_JACKPOT_POOL_TOP_MAX = tonumber(data.value)
        elseif data.systemKey == "QuestJackpotSpeedMax" then
            self.QUEST_JACKPOT_POOL_TOP_SPEED_MAX = tonumber(data.value)
        elseif data.systemKey == "ChallengeSaleTimes" then
            self.CHALLENGE_SALE_TIMES = tonumber(data.value)
        elseif data.systemKey == "FriendGiftCoinOpenLevel" then
            self.INBOX_FACEBOOK_COIN = tonumber(data.value)
        elseif data.systemKey == "FriendGiftCardOpenLevel" then
            self.INBOX_FACEBOOK_CARD = tonumber(data.value)
        elseif data.systemKey == "RTSwitch" then
            self.RATEUS_SWITCH = tonumber(data.value)
        elseif data.systemKey == "RTSwitchSettings" then
            self.RATEUS_SWITCH_SETTINGS = tonumber(data.value)
        elseif data.systemKey == "BattlePassOpenLevel" then
            self.BATTLEPASS_OPEN_LEVEL = tonumber(data.value)
        elseif data.systemKey == "DrawOpenLevel" then
            self.DRAW_OPEN_LEVEL = tonumber(data.value)
        elseif data.systemKey == "winner_notifications" then
            self.WINNER_NOTIFICATIONS_FLAG = tonumber(data.value)
        elseif data.systemKey == "upgrade_ios_fix" then
            -- att 相关配置
            self.UPGRADE_IOS_FIX_FLAG = tonumber(data.value)
        elseif data.systemKey == "attSpinTime" then
            self.ATT_BIGWIN_SPIN_LIMIT = tonumber(data.value)
        elseif data.systemKey == "attWinMul" then
            self.ATT_BIGWIN_WIN_MULTIPLE = tonumber(data.value)
        elseif data.systemKey == "attPopTime" then
            local list = util_string_split(data.value, ";")
            if list and #list > 0 then
                self.ATT_BIGWIN_POP_CDTIME = list
            end
        elseif data.systemKey == "attNum" then
            self.ATT_BIGWIN_POP_MAXTIMES = tonumber(data.value)
        elseif data.systemKey == "SpecialCardOpenTime" then
            self.CARD_STATUE_UNLOCK_TIME = data.value
        elseif data.systemKey == "UserDateTransferLv" then
            self.USERDATA_TRANSFER_LEVEL = tonumber(data.value) or 50
        elseif data.systemKey == "NoviceActivityIgnoreLevel" then -- ab分组该玩家检测活动是是否忽略等级判断
            self.ACT_IGNORE_LEVEL_NOVICE = tonumber(data.value) or 0
        elseif data.systemKey == "NoviceSpecialCardWindowBootLevel" then -- 关卡内左边条集卡入口显示最低等级
            self.NOVICE_CARD_LEFT_FRAME_SHOW_LEVEL = tonumber(data.value) or 0
        elseif data.systemKey == "NoviceSuspensionWindowBootLevel" then -- 关卡内悬浮窗引导最低等级
            self.NOVICE_LEFT_FRAME_GUIDE_LEVEL = tonumber(data.value) or 21
        elseif data.systemKey == "NoviceNewUserQuestTriggerText" then
            self.NOVICE_NEWUSERQUEST_LEVELUP_CONTENT = data.value
        elseif data.systemKey == "NoviceNewUserQuestTriggerNum" then
            self.NOVICE_NEWUSERQUEST_LEVELUP_REWARD = data.value
        elseif data.systemKey == "NoviceNewUserQuestLoginText" then
            self.NOVICE_NEWUSERQUEST_LOGIN_CONTENT = data.value
        elseif data.systemKey == "NoviceNewUserQuestLoginNum" then
            self.NOVICE_NEWUSERQUEST_LOGIN_REWARD = data.value
        elseif data.systemKey == "Novicefirstpayendlevel" then
            self.NOVICE_FIRSTPAY_ENDLEVEL = tonumber(data.value) or 100
        elseif data.systemKey == "NoviceEntrance" then -- 活动总入口引导最低等级
            self.NOVICE_ACT_ENTRANCE_GUIDE_LEVEL = tonumber(data.value) or 0
        elseif data.systemKey == "NoviceGroup" then -- 是否支持 新手期修改特性
            self.NOVICE_FEATURES_GROUP = data.value or "A"
        elseif data.systemKey == "NewPassOpenLevel" then
            self.NEWPASS_OPEN_LEVEL = tonumber(data.value) or 20
        elseif data.systemKey == "NovicePassOpenLevel" then
            self.NEWUSERPASS_OPEN_LEVEL = tonumber(data.value) or 5
        elseif data.systemKey == "NoviceNewUserPassSwitch" then
            self.NEWUSERPASS_OPEN_SWITCH = tonumber(data.value) or 0
        elseif data.systemKey == "NoviceDailyBonusOpenLevel" then -- 每日签到开启等级
            self.DAILYBOUNS_OPEN_LEVEL = tonumber(data.value) or 20
        elseif data.systemKey == "NoviceDailyMissionOpenLevel" then -- 每日任务开启等级
            self.OPENLEVEL_DAILYMISSION = tonumber(data.value) or 0
        elseif data.systemKey == "NoviceGameGroupOpenLevel" then
            self.NoviceGameGroupOpenLevel = tonumber(data.value) or 1
        elseif data.systemKey == "NoviceGameGroupOtherOpenLevel" then
            self.NoviceGameGroupOtherOpenLevel = tonumber(data.value) or 1
        elseif data.systemKey == "NoviceNoCoinsOpenLevel" then -- 新手期 nocoins 开启等级
            self.NOVICE_NOCOINS_OPEN_LEVEL = tonumber(data.value) or 100
        elseif data.systemKey == "NoviceInboxRedShield" then -- 新手期 设置界面inbox红点显示等级
            self.NOVICE_INOBXRED_SHOW_LEVEL = tonumber(data.value) or 20
        elseif data.systemKey == "NoviceCashBonusOpenLevel" then -- 新手期 金银库开放等级
            self.NOVICE_CASHBONUS_OPEN_LEVEL = tonumber(data.value) or 20
        elseif data.systemKey == "NovicePushAdaptDays" then -- 新手期 推送限制注册天数
            self.NOVICE_PUSH_ADAPT_DAYS = tonumber(data.value) or 7
        elseif data.systemKey == "NovicePushType1Times" then -- 新手期 type1推送限制次数
            self.NOVICE_PUSH_TYPE_1_TIMES = tonumber(data.value) or 3
        elseif data.systemKey == "NovicePushType2Times" then -- 新手期 type2推送限制次数
            self.NOVICE_PUSH_TYPE_2_TIMES = {}
            local list = util_string_split(data.value, "|")
            if list and #list > 0 then
                self.NOVICE_PUSH_TYPE_2_TIMES = list
            end
        elseif data.systemKey == "NovicePushType2Coins" then -- 新手期 type2推送限制 持金数
            self.NOVICE_PUSH_TYPE_2_COINS = {}
            local list = util_string_split(data.value, "|")
            if list and #list > 0 then
                self.NOVICE_PUSH_TYPE_2_COINS = list
            end
        elseif data.systemKey == "NovicePushType2Hour" then -- 新手期 type2推送限制 1h内没操作
            self.NOVICE_PUSH_TYPE_2_NOSPIN_TIME = tonumber(data.value) or 3600
        elseif data.systemKey == "NovicePushType2Level" then -- 新手期 type2推送等级限制 [x,y] 闭区间
            local list = util_string_split(data.value, "|")
            if list and #list > 0 then
                self.NOVICE_PUSH_TYPE_2_LEVEL_RANGE = {}
                for j = 1, #list do
                    local levelList = util_string_split(list[j], ";")
                    if levelList and #levelList > 0 then
                        self.NOVICE_PUSH_TYPE_2_LEVEL_RANGE[j] = levelList
                    end
                end
            end
        elseif data.systemKey == "NoviceFirstPayShowOpenLevel" then -- 新手期 首充开启等级
            self.NOVICE_FIRSTPAY_OPENLEVEL = tonumber(data.value) or 2
        elseif data.systemKey == "ClanUnlockMinLevel" then -- 公会解锁等级
            self.CLAN_OPEN_LEVEL = tonumber(data.value) or 20
        elseif data.systemKey == "ClanOpen" then -- 公会功能是否开启
            local bOpen = (tonumber(data.value) or 0) == 1 --1 开启  0 关闭
            self.CLAN_OPEN_SIGN = bOpen
        elseif data.systemKey == "ClanRemindOpenLevel" then -- 未加入公会提醒弹窗最低弹出等级 >=
            self.CLAN_REMIND_OPEN_LEVEL = tonumber(data.value) or 45
        elseif data.systemKey == "ClanRemindOpenTimes" then -- 未加入公会提醒弹窗最多弹出次数 >
            self.CLAN_REMIND_OPEN_TIMES = tonumber(data.value) or 5
        elseif data.systemKey == "QuestionnaireUrl" then
            self.QUESTIONNAIRE_URL = data.value
        elseif data.systemKey == "NoviceFBGroupOpenLevel" then -- 新手期 首充开启等级
            self.NOVICE_FACEBOOK_GROUP_OPENLEVEL = tonumber(data.value) or 40
        elseif data.systemKey == "BigRContactUrl" then
            self.BIGRCONTACT_URL = data.value
        elseif data.systemKey == "NoviceDailyPassPurchaseLevel" then -- 新手期4.0 pass关闭主界面弹出购买弹板限制等级
            self.NOVICE_DAILYPASS_PRUCHASES_LEVEL = tonumber(data.value) or 25
        elseif data.systemKey == "NoviceNewGameReOpenLevel" then -- 新手期4.0 关卡内新关提示限制等级
            self.NOVICE_UNLOCK_NEW_LEVEL = tonumber(data.value) or 25
        elseif data.systemKey == "LotteryOpenSign" then
            local bOpen = (tonumber(data.value) or 0) == 1 --1 开启  0 关闭
            self.LOTTERY_OPEN_SIGN = bOpen
        elseif data.systemKey == "LotteryOpenLevel" then
            self.LOTTERY_OPEN_LEVEL = tonumber(data.value) or 18
        elseif data.systemKey == "NoviceFirstPayPopControl" then
            -- 结构为 ” 10;13 | 20;25....“  |隔开为一组, ;隔开 左边为当前被限制等级 右边为弹出等级
            local list = util_string_split(data.value, "|")
            if list and #list > 0 then
                self.NOVICE_FIRSTPAY_POPLEVEL = {}
                for j = 1, #list do
                    local levelList = util_string_split(list[j], ";")
                    if levelList and #levelList > 0 then
                        self.NOVICE_FIRSTPAY_POPLEVEL[j] = levelList
                    end
                end
            end
        elseif data.systemKey == "CommonJackpot" then
            -- 结构 等级-基础金币-增长金币;......
            self.COMMON_JACKPOT = {}
            local list = util_string_split(data.value, ";")
            if list and #list > 0 then
                local lastLv = -1
                for j = 1, #list do
                    local levelList = util_string_split(list[j], "-")
                    if levelList and #levelList > 0 then
                        local lv = tonumber(levelList[1])
                        local base = tonumber(levelList[2])
                        local add = tonumber(levelList[3])
                        if j == #list then
                            self.COMMON_JACKPOT[j] = {minLv = tonumber(lastLv) + 1, maxLv = math.huge, base = base, add = add}
                        else
                            self.COMMON_JACKPOT[j] = {minLv = tonumber(lastLv) + 1, maxLv = lv, base = base, add = add}
                            lastLv = levelList[1]
                        end
                    end
                end
            end
        elseif data.systemKey == "JillionJackpotGames" then
            -- 公共jackpot关卡名字
            self.COMMON_JACKPOT_GAME_NAMES = {} 
            local list = util_string_split(data.value, ";")
            if list and #list > 0 then
                for j = 1, #list do
                    self.COMMON_JACKPOT_GAME_NAMES[j] = list[j]
                end
            end
        elseif data.systemKey == "Poker_Paytable" then
            local list = util_string_split(data.value, "-")
            if list and #list > 0 then
                self.POKER_PAYTABLE = {}
                for j = 1, #list do
                    self.POKER_PAYTABLE[i] = tonumber(list[j])
                end
            end
        elseif data.systemKey == "NadoBigCoinsUsd" then
            self.CARD_NADOMACHINE_BUBBLE_DOLLOR = data.value
        elseif data.systemKey == "InviteMaxLevel" then
            self.INVITE_LEVEL = tonumber(data.value)
        elseif data.systemKey == "FBShareUrl" then
            self.FBSHARE_URL = data.value
        elseif data.systemKey == "AdvertiseOpenLevel" then
            self.ADCHALLABGE_OPENLEVEL = tonumber(data.value) or 20
        elseif data.systemKey == "CardCoinRewardCoe" then
            self.CARD_SPECIAL_REWAR = tonumber(data.value)
        elseif data.systemKey == "ColdTime" then
            self.BROKENSALE_COLDTIME = tonumber(data.value)
        elseif data.systemKey == "PopUpTimes" then
            self.BROKENSALE_POPUPTIMES = tonumber(data.value)
        elseif data.systemKey == "FBVipInviteUrl" then
            self.FB_VIP_INVITE_URL = data.value
        elseif data.systemKey == "NoviceQuestTheme" then
            self.QUEST_NEWUSER_THEME = data.value
        elseif data.systemKey == "NoviceCheckOpenLevel" then
            self.NOVICE_CHECK_OPEN_LEVEL = tonumber(data.value)
        elseif data.systemKey == "NoviceCheckV2OpenLevel" then
            self.NOVICE_CHECK_V2_OPEN_LEVEL = tonumber(data.value)
        elseif data.systemKey == "NoviceNewUserSignInSwitch" then
            self.NOVICE_NEWUSER_SIGNIN_SWITCH = tonumber(data.value)
        elseif data.systemKey == "NoviceBlastOpenLevel" then
            self.NoviceBlastOpenLevel = tonumber(data.value)
        elseif data.systemKey == "NoviceNewUserBlastSwitch" then
            self.NoviceNewUserBlastSwitch = data.value
        elseif data.systemKey == "NewbieTaskSpinCountCoins" then
            self.NEWBIE_TASK_COINS[NewbieTaskType.spin_count] = tonumber(data.value) or 0 -- 新手任务 spin10次给的奖励
        elseif data.systemKey == "NewbieTaskReachLVCoins" then
            self.NEWBIE_TASK_COINS[NewbieTaskType.reach_level] = tonumber(data.value) or 0 -- 新手任务 达到5级给的奖励
        elseif data.systemKey == "NoviceBlastCollectLayerOpenLevel" then
            self.NOVICE_BLAST_COLLECT_LAYER_LV = tonumber(data.value) or 0 -- 新手blat50级前不弹  收集弹板
        elseif data.systemKey == "NoviceInitCoins" then
            self.NOVICE_SERVER_INIT_COINS = tonumber(data.value) or 0
        elseif data.systemKey == "NoviceIceBrokenSaleCD" then
            self.NOVICE_ICE_BROKEN_SALE_GTL_POP_CD = tonumber(data.value) or 0 -- 新破冰促销未购买关卡返回大厅弹窗cd
        elseif data.systemKey == "BestDeal" then -- 促销入口
            self.BEST_DEAL = data.value or ""
        elseif data.systemKey == "NoviceFirstGuideGoSlotGame" then
            self.NEW_SUER_FIRST_GUIDE_GO_SLOT_GAMME = (tonumber(data.value) or 0) == 1  -- 玩家第一步引导是否是 直接进入关卡
        elseif data.systemKey == "NoviceFirstSaleSpecialTheme" then
            self.FIRST_COMMON_SALE_SPECIAL_THEME = (tonumber(data.value) or 0) == 1 --首充礼包使用特殊主题
        elseif data.systemKey == "NoviceShopCarnivalAniActive" then
            self.NOVICE_SHOP_CARNIVAL_ANI_ACTIVE = (tonumber(data.value) or 0) == 1 -- 商城膨胀动画 是否显示
        elseif data.systemKey == "NoviceQuestOpen" then
            -- NoviceQuestOpen -- 大厅入口是不是显示 普通quest 
            self.NOVICE_NEW_QUEST_OPEN = (tonumber(data.value) or 0) == 0 -- 是否支持新手quest
        elseif data.systemKey == "NoviceNewUserCardOpen" then
            -- 新手期集卡 开启开关
            self.NOVICE_NEW_USER_CARD_OPEN = (tonumber(data.value) or 0) == 1 --新手期集卡 开启开关、
        elseif data.systemKey == "NoviceFirstSaleGiftHideTime" then
            self.FIRST_COMMON_SALE_HIDE_TIME = (tonumber(data.value) or 0) == 1 --首充礼包 隐藏倒计时
        elseif data.systemKey == "NoviceRateUsSpanTime" then
            self.RATE_US_LAYER_SPAN_TIME = data.value or "" -- rateus弹板 间隔cd时间
        elseif data.systemKey == "NoviceRateUsMaxCount" then
            self.RATE_US_LAYER_MAX_COUNT = data.value or "" -- rateus弹板 最大弹出次数
        elseif data.systemKey == "NoviceRateUsOpen" then
            self.RATE_US_LAYER_CD_CONFIG_OPEN = (tonumber(data.value) or 0) == 1  -- rateus弹板 spin次数区间 不同cd开关
        elseif data.systemKey == "NoviceRateSpin" then
            self.RATE_US_LAYER_SPIN_COUNT = data.value or "" -- rateus弹板 spin次数区间
        elseif data.systemKey == "NoviceRateUsOpenLevel" then
            self.RATE_US_LAYER_OPEN_LEVEL = tonumber(data.value) -- rateus弹板 限制等级
        elseif data.systemKey == "SideKicksOpenLevel" then
            self.SIDE_KICKS_OPEN_LEVEL = tonumber(data.value) or 0 -- 宠物系统开启等级
        elseif data.systemKey == "NoviceRateSettingEntryOpenLevel" then
            self.RATE_US_SETTING_ENTRY_OPEN_LEVEL = tonumber(data.value) -- rateus 设置处入口显示 限制等级
        elseif data.systemKey == "NoviceRateUsOneStarAddCD" then
            self.RATE_US_LAYER_ONE_STAR_ADD_CD = tonumber(data.value) or 0 -- 评分5星以下每低1星，评分弹板 CD增加 24小时
        elseif data.systemKey == "NoviceRateUsSpecialSpinWinForcePop" then
            self.RATE_US_LAYER_SPECIAL_SPIN_WIN_FORCE_POP = (tonumber(data.value) or 0) == 1 -- rateus弹板 特殊大赢就算 评论过了 也弹出
        elseif data.systemKey == "NoviceRateNewRes" then
            self.RATE_US_LAYER_USE_NEW_FIVE_DESC_RES = (tonumber(data.value) or 0) == 1 -- rateus弹板 使用新版 资源 5分描述
        elseif data.systemKey == "RecallPushCode" then
            self.LOCALPUSH_CODE = data.value
        else
            self[data.systemKey] = data.value
        end
    end

    self.CLUB_OPEN_LEVEL_COPY = self.CLUB_OPEN_LEVEL -- 存储下配置的高倍场等级
end

--获取同意类型弹窗最大次数
function ConstantData:getPushViewMaxCount(vType)
    if self.PUSHVIEW_POS == nil or not self.PUSHVIEW_POS[vType] then
        return 0
    end

    return self.PUSHVIEW_POS[vType]
end

-- ab分组该玩家检测活动是是否忽略等级判断
function ConstantData:checkIsIgnoreActLevel()
    if not self.ACT_IGNORE_LEVEL_NOVICE or self.ACT_IGNORE_LEVEL_NOVICE == 0 then
        return false
    end


    if globalData.GameConfig:checkABtestGroup("Novice", "C") and G_GetMgr(ACTIVITY_REF.Quest):isNewUserQuestCompleted() then
        -- 重置普通quest开启等级(新手quest完了就开启)
        -- self.OPENLEVEL_NEWQUEST = 1
        return true
    end

    return false --(活动未完成或者还没激活新手quest)
end

function ConstantData:getFbVideoUrl()
    local url = self.FB_VIDEO_URL or ""
    if url ~= "" then
        return url
    end

    return "https://www.facebook.com/Cash-Link-Slots-725940274524191/?eid=ARBoKBJiQCwfVsPWFb2Y4nM5Yr_yKU_zmgi1s4e3aUZZ242b-CjCjizqWEHI6A-RktE4sgWWX3z98BtU"
end

function ConstantData:getFbFansUrl()
    local url = self.FBFANS_URL or ""
    if url ~= "" then
        return url
    end

    return "https://www.facebook.com/100063590979385"
end

function ConstantData:getFbGroupsUrl()
    local url = self.FB_GROUPS_URL or ""
    if url ~= "" then
        return url
    end

    return "https://www.facebook.com/groups/254848145641446"
end

function ConstantData:getFbVipGroupsUrl()
    local url = self.FB_VIP_INVITE_URL or ""
    if url ~= "" then
        return url
    end

    return "https://www.facebook.com/groups/433145655279024"
end

return ConstantData
