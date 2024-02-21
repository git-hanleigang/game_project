--[[
    初始化管理(控制)类对象
    author: 徐袁
    time: 2021-07-04 14:51:52
]]

require("manager.Novice.UserNoviceMgr"):getInstance()
-- 关卡spin时额外消耗bet
require("GameModule.BetExtraCosts.controller.BetExtraCostsMgr"):getInstance()
-- 扩圈新用户
require("GameModule.NewUserExpand.controller.NewUserExpandManager"):getInstance()

-- 导入集卡模块 --
require("GameModule.Card.CardSysManager")

-- 活动功能
require("activities.Activity_Leagues.controller.LeagueActCtrlManager"):getInstance()
require("activities.Activity_LevelDashPlus.controller.Activity_LevelDashPlusManager"):getInstance()
require("activities.Activity_BrokenSale.controller.BrokenSaleSaleControl"):getInstance()
require("activities.Activity_Bingo.controller.BingoControl"):getInstance()
require("activities.Activity_Bingo.controller.BingoSaleControl"):getInstance()
require("activities.Activity_BingoRush.controller.BingoRushManager"):getInstance()
require("activities.Activity_BingoRush.controller.BingoRushLoadingManager"):getInstance()
require("activities.Activity_Quest.controller.QuestManager"):getInstance()
require("activities.Activity_Quest.controller.QuestSaleManager"):getInstance()
require("activities.Activity_Quest.controller.QuestShowTopManager"):getInstance()
require("activities.Activity_Quest.controller.QuestRushManager"):getInstance()
require("activities.Activity_MissionRushNew.controller.Activity_MissionRushNewManager"):getInstance()
require("activities.Activity_SeasonMission_Dash.controller.Activity_SeasonMission_DashManager"):getInstance()
require("activities.Activity_DailySprint_Coupon.controller.Activity_DailySprint_CouponManager"):getInstance()
require("activities.Activity_QuestNew.controller.QuestNewManager"):getInstance()
require("activities.Activity_QuestNew.controller.QuestNewSaleManager"):getInstance()
require("activities.Activity_QuestNew.controller.QuestNewRushManager"):getInstance()

require("activities.Activity_RichMan.controller.RichManManager"):getInstance()
require("activities.Activity_RichMan.controller.RichManTaskMgr"):getInstance()
require("activities.Activity_RichMan.controller.RichManSaleManager"):getInstance()
require("activities.Activity_RichMan.controller.RichManShowTopMgr"):getInstance()
require("activities.Activity_WorldTrip.controller.WorldTripManager"):getInstance()
require("activities.Activity_WorldTrip.controller.WorldTripTaskMgr"):getInstance()
require("activities.Activity_WorldTrip.controller.WorldTripSaleManager"):getInstance()
require("activities.Activity_WorldTrip.controller.WorldTripShowTopMgr"):getInstance()
require("activities.Activity_DartsGame.controller.DartsGameManager"):getInstance()
require("activities.Activity_DartsGame_Loading.controller.Activity_DartsGame_LoadingManager"):getInstance()
require("activities.Activity_Blast.controller.BlastManager"):getInstance()
require("activities.Activity_Blast.controller.BlastSaleManager"):getInstance()
require("activities.Activity_Blast.controller.BlastShowTopManager"):getInstance()
require("activities.Activity_Blast.controller.BlastNoviceTaskManager"):getInstance()
require("activities.Activity_CoinPusher.controller.CoinPusherManager"):getInstance()
require("activities.Activity_CoinPusher.controller.CoinPusherSaleMgr"):getInstance()
require("activities.Activity_CoinPusher.controller.CoinPusherTaskMgr"):getInstance()
require("activities.Activity_CoinPusher.controller.CoinPusherTaskNewMgr"):getInstance()
require("activities.Activity_CoinPusher.controller.CoinPusherShowTopMgr"):getInstance()
require("activities.Activity_LuckySpinGoldenCard.controller.LuckySpinGoldenCardManager"):getInstance()
require("activities.Activity_RippleDash.controller.ActivityRippleDashManager"):getInstance()
require("activities.Activity_DoubleCatFood.controller.DoubleCatFoodManager"):getInstance()
require("activities.Promotion_RepartWin.controller.RepartWinSaleMgr"):getInstance()
require("activities.Activity_LuckySpinRandomCard.controller.LuckySpinRandomCardManager"):getInstance()
require("activities.Activity_LuckyChipsDraw.controller.LuckyChipsDrawManager"):getInstance()
require("activities.LuckyStamp.controller.LuckyStampCardActMgr"):getInstance()
require("activities.LuckyStamp.controller.MulLuckyStampActMgr"):getInstance()
require("activities.Activity_Blast.controller.BlastTaskMgr"):getInstance()
require("activities.Activity_Blast.controller.BlastBombMgr"):getInstance()
require("activities.Activity_DeluxeCat.controller.DeluxeCatManager"):getInstance()
require("activities.Activity_CardsOneKeyRecover.controller.CardsOneKeyRecoverMgr"):getInstance()
require("activities.Activity_CardOpen.controller.CardOpenMgr"):getInstance()
require("activities.Activity_CardEnd.controller.CardEndCountdownMgr"):getInstance()
require("activities.Activity_Redecor.controller.RedecorManager"):getInstance()
require("activities.Activity_Redecor.controller.RedecorSaleManager"):getInstance()
require("activities.Activity_Redecor.controller.RedecorShowTopManager"):getInstance()
require("activities.Activity_Redecor.controller.RedecorTaskMgr"):getInstance()
require("activities.Activity_NewPass.controller.NewPassManager"):getInstance()
require("activities.Activity_NewPass.controller.NewPassBuyTicketManager"):getInstance()
require("activities.Activity_NewPass.controller.NewPassDoubleMedalManager"):getInstance()
require("activities.Activity_NewPass.controller.NewPassCountDownManager"):getInstance()
require("activities.Activity_NewPass.controller.NewPassThreeLineLoadingManager"):getInstance()
require("activities.Activity_Word.controller.WordManager"):getInstance()
require("activities.Activity_Word.controller.WordSaleMgr"):getInstance()
require("activities.Activity_Word.controller.WordShowTopMgr"):getInstance()
require("activities.Activity_Word.controller.WordTaskMgr"):getInstance()
-- blast任务新版
require("activities.Activity_Word.controller.WordTaskNewMgr"):getInstance()

require("activities.Activity_DiningRoom.controller.DiningRoomSaleMgr"):getInstance()
require("activities.Activity_PigSaleTeam.controller.PigSaleTeamManager"):getInstance()
require("activities.Promotion_MemoryFlying.controller.MemoryFlyingSaleMgr"):getInstance()
require("activities.Activity_PigSale.controller.PigSaleMgr"):getInstance()
require("activities.Activity_SaleTicket.controller.SaleTicketMgr"):getInstance()
require("activities.Activity_VipBoost.controller.VipBoosterMgr"):getInstance()
require("activities.Activity_CashBack.controller.CashBackMgr"):getInstance()
require("activities.Activity_CashBack.controller.CashBackNoviceMgr"):getInstance()
require("activities.Activity_StoreSaleRandomCard.controller.StoreSaleRandomCardMgr"):getInstance()
require("activities.Activity_OpenNewLevel.controller.OpenNewLvMgr"):getInstance()
require("activities.Activity_FBCommunity.controller.FBCommunityMgr"):getInstance()
require("activities.Activity_FBGroup.controller.FBGroupMgr"):getInstance()
require("activities.Activity_Entrance.controller.EntranceMgr"):getInstance()
require("activities.Activity_PiggyChallenge.controller.PigChallengeMgr"):getInstance()
-- require("manager.Activity.ActivtiyPurchaseDrawManager"):getInstance()
-- require("manager.Activity.EchoWinSpinManager"):getInstance()
-- require("manager.Activity.LuckySpinRandomCardManager"):getInstance()
-- require("manager.Activity.RepartJackpotManager"):getInstance()
-- require("manager.Activity.RepeatFreeSpinManager"):getInstance()
-- require("manager.Activity.SaleTicketManager"):getInstance()
-- require("manager.Activity.StoreSaleRandomCardManager"):getInstance()
-- require("manager.System.HolidayChallengeManager"):getInstance()
require("activities.Promotion_MultiSpan.controller.MultiSpanControl"):getInstance()
require("activities.Activity_EchoWin.controller.EchoWinControl"):getInstance()
require("activities.Activity_GemStoreSale.controller.GemStoreSaleControl"):getInstance()
require("activities.Activity_ShopGemCoupon.controller.ShopGemCouponControl"):getInstance()
require("activities.Activity_SevenDaySign.controller.SevenDaySignControl"):getInstance()
require("activities.Activity_CoinExpand_Store.controller.CoinExpandStoreManager"):getInstance()
require("activities.Activity_PigSaleBooster.controller.PigSaleBoosterControl"):getInstance()
require("activities.Activity_BetweenTwo.controller.BetweenTwoControl"):getInstance()
require("activities.Activity_KeepRecharge.controller.KeepRechargeControl"):getInstance()
require("activities.Activity_RepartJackpot.controller.RepartJackpotControl"):getInstance()
require("activities.Activity_RepeatFreeSpin.controller.RepeatFreeSpinControl"):getInstance()
require("activities.Activity_CollectEmail.controller.CollectEmailControl"):getInstance()
require("activities.Activity_LuckyChallenge.controller.LuckyChallengeManager"):getInstance()
require("activities.Activity_LuckyChallenge.controller.LuckyChallengeSaleMgr"):getInstance()
require("activities.Activity_LuckyFish.controller.LuckyFishMgr"):getInstance()
require("activities.Activity_Coupon.controller.CouponMgr"):getInstance()
require("activities.Activity_LuckySpin.controller.LuckySpinSaleMgr"):getInstance()
require("activities.Activity_AllGamesUnlocked.controller.AllGamesUnlockedMgr"):getInstance()
require("activities.Activity_SaleGroup.controller.SaleGroupControl"):getInstance()
require("activities.Activity_CommonJackpot.controller.CommonJackpotMgr"):getInstance()
require("activities.Activity_Poker.controller.PokerMgr"):getInstance()
require("activities.Activity_Poker.controller.PokerSaleMgr"):getInstance()
require("activities.Activity_Poker.controller.PokerTaskMgr"):getInstance()
require("activities.Activity_Poker.controller.PokerShowTopMgr"):getInstance()
require("activities.Activity_Shop_Loading.controller.ShopLoadingControl"):getInstance()
require("activities.Activity_ShopCarnival.controller.ShopCarnivalControl"):getInstance()
require("activities.Activity_DoubleCard.controller.DoubleCardMgr"):getInstance()
require("activities.Activity_NiceDice.controller.NiceDiceControl"):getInstance()
require("activities.Activity_FBShare.controller.FBShareMgr"):getInstance()
require("activities.Activity_Coloring.controller.ColoringController"):getInstance()
require("activities.Promotion_NewDouble.controller.NewDoubleControl"):getInstance()
require("activities.Activity_SlotTrials.controller.SlotTrialsManager"):getInstance()

-- 系统功能

require("GameModule.Inbox.controller.InboxManager"):getInstance()
require("manager.ShopManager"):getInstance()
require("GameModule.Shop2023.controller.ShopDailySaleManager"):getInstance()
require("GameModule.Avatar.controller.AvatarManager"):getInstance()
require("GameModule.Avatar.controller.AvatarFrameManager"):getInstance()
require("GameModule.AvatarGame.controller.AvatarGameManager"):getInstance()
require("activities.AvatarFrameAct.controller.AvatarFrameLoadingActMgr"):getInstance()
require("activities.AvatarFrameAct.controller.AvatarFrameRuleActMgr"):getInstance()
require("activities.AvatarFrameAct.controller.AvatarFrameChangeWayActMgr"):getInstance()
require("activities.UserInfoNewAct.controller.NewProfileLoadingActMgr"):getInstance()
require("activities.UserInfoNewAct.controller.NewProfileChangeActMgr"):getInstance()
require("GameModule.JumpTo.JumpToManager"):getInstance()
--免费金币-cashbonus
require("activities.Activity_CoinExpand_CashBonus.controller.CoinExpandCashBonusManager"):getInstance()
-- require("manager.System.LuckyChooseManager"):getInstance()
-- require("manager.System.LuckySpinManager"):getInstance()
-- require("manager.System.LuckyStampManager"):getInstance()
-- require("manager.System.DeluexeClubManager"):getInstance()
require("GameModule.Lottery.controller.LotteryManager"):getInstance()
require("activities.Activity_Lottery_Open_source.controller.LotteryOpenSourceManager"):getInstance()
require("activities.Activity_LotteryChallenge.controller.LotteryChallengeActMgr"):getInstance()
require("activities.Activity_Lottery_Jackpot.controller.LotteryJackpotActMgr"):getInstance()
require("GameModule.MileStoneCoupon.controller.MileStoneCouponRegisterManager"):getInstance()
require("GameModule.MileStoneCoupon.controller.MileStoneCouponManager"):getInstance()
require("GameModule.PokerRecall.controller.PokerRecallMgr"):getInstance()
require("GameModule.DuckShot.controller.DuckShotControl"):getInstance()
require("GameModule.CashMoney.controller.CashMoneyMgr"):getInstance()

require("GameModule.PiggyBank.controller.PiggyBankMgr"):getInstance()
require("GameModule.Vip.controller.VipManager"):getInstance()

require("activities.Activity_HolidayChallenge.controller.HolidayChallengeManager"):getInstance()
require("activities.Activity_HolidayChallenge.controller.ChallengePassExtraStarManager"):getInstance()
require("activities.Activity_HolidayChallenge.controller.ChallengePassLastDayManager"):getInstance()
require("activities.Activity_HolidayChallenge.controller.ChallengePassPayManager"):getInstance()
require("activities.Activity_HolidayChallenge.controller.ChallengePassLastSaleManager"):getInstance()
require("activities.Activity_HolidayChallenge.controller.ChallengePassBoxManager"):getInstance()
require("GameModule.GiftPickBonus.controller.GPBonusMgr"):getInstance()
require("GameModule.TreasureSeeker.controller.TreasureSeekerMgr"):getInstance()
require("GameModule.FBShareCoupon.controller.FBShareCouponMgr"):getInstance()

-- cash bonus 管理类(每日轮盘 金库 银库 钞票游戏)
require("GameModule.CashBonus.controller.CashBonusManager"):getInstance()

-- mrege
require("activities.Activity_DeluxeMerge.controller.ActivityDeluxeMergeManager"):getInstance()
require("activities.Activity_DeluxeMerge.controller.MergeDoubleActManager"):getInstance()
require("activities.Activity_DeluxeMerge.controller.MergeLoadingActManager"):getInstance()
require("activities.Activity_DeluxeMerge.controller.MergeRuleActManager"):getInstance()
require("activities.Activity_DeluxeMerge.controller.MergeCountDownActManager"):getInstance()
require("activities.Activity_DeluxeMerge.controller.MergeWayToGetActManager"):getInstance()
require("activities.Activity_DeluxeMerge.controller.MergeWeekActManager"):getInstance()
-- mrege
require("GameModule.FirstSale.controller.FirstSaleMgr"):getInstance()
require("activities.Activity_Team.controller.TeamRankActMgr"):getInstance()
require("activities.Activity_Team.controller.TeamRushActMgr"):getInstance()
require("activities.Activity_Team.controller.TeamGiftLoadingActMgr"):getInstance()

require("activities.Promotion_Divination.controller.DivinationManager"):getInstance()
-- DailyMissionRush
require("activities.Activity_MissionRush.controller.DailyMissionRushManager"):getInstance()
require("activities.Activity_MissionRush.controller.SeasonMissionRushManager"):getInstance()
-- 小猪折扣送金卡（新活动）
require("activities.Activity_PigGoldCard.controller.PigGoldCardMgr"):getInstance()
require("activities.Activity_WildChallenge.controller.WildChallengeActMgr"):getInstance()
-- 小猪转盘
require("activities.Activity_GoodWheelPiggy.controller.GoodWheelPiggyMgr"):getInstance()
--2022复活节无线砸蛋
require("activities.Promotion_Infinity_Easter22.controller.PromotionInfinityEaster22Mgr"):getInstance()

require("activities.Activity_PushNotifications.controller.ActivityPushNotificationsMgr"):getInstance()
--拉新活动
require("GameModule.Invite.controller.InviteManager"):getInstance()
-- 10m每日任务送优惠券
require("activities.Activity_CouponChallenge_10M.controller.CouponChallengeMgr"):getInstance()
-- 1000W扭蛋机
require("activities.Activity_Gashapon.controller.GashaponMgr"):getInstance()
--二选一
require("activities.Promotion_TornadoMagicStore.controller.PromotionTornadoMagicStoreManager"):getInstance()
require("activities.Promotion_OnePlusOne.controller.Promotion_OnePlusOneManager"):getInstance()
require("GameModule.Currency.controller.CurrencyMgr"):getInstance()

--商城最高档位付费后促销礼包功能
require("activities.Promotion_TopSale.controller.Promotion_TopSaleManager"):getInstance()
-- 乐透促销
require("activities.Activity_Lottery_Sale.controller.LotterySaleManager"):getInstance()
-- 乐透STATISTICS
require("activities.Activity_Lottery_Statistics.controller.LotteryStatisticsManager"):getInstance()
--浇花系统
require("GameModule.Flower.controller.FlowerManager"):getInstance()
require("activities.Activity_FlowerLoading.controller.FlowerLoadingMgr"):getInstance()
require("activities.Activity_LuckySpin_Loading.controller.LuckyV2LoadingMgr"):getInstance()

--膨胀宣传-🐷
require("GameModule.NewUser7Day.controller.NewUser7DayMgr"):getInstance()
-- 新手七日目标
require("GameModule.NewUser7Day.controller.NewUser7DayMgr"):getInstance()
--比赛聚合
require("activities.Activity_BattleMatch.controller.BattleMatchManager"):getInstance()
require("activities.Activity_BattleMatch.controller.BattleMatchRuleManager"):getInstance()

-- 卡牌商店
require("GameModule.Card.CardStore.controller.CardStoreManager"):getInstance()
-- 卡牌排行榜
require("GameModule.Card.CardRank.controller.CardShowTopMgr"):getInstance()
-- 集卡神庙探险小游戏
require("GameModule.CardMiniGames.CardSeeker.controller.CardSeekerMgr"):getInstance()
-- 集卡特殊章节
require("GameModule.CardSpecialClans.controller.CardSpecialClanMgr"):getInstance()
--金币宣传-合成
require("activities.Activity_CoinExpand_Merge.controller.CoinExpandMergeManager"):getInstance()
--ActivityFBVideo
require("activities.Activity_FBVideo.controller.Activity_FBVideoManager"):getInstance()
--系统功能个人信息
require("GameModule.UserInfo.controller.UserInfoManager"):getInstance()
-- 广告任务
require("activities.Activity_AdChallenge.controller.AdChallengeMgr"):getInstance()
-- 快速点击小游戏
require("GameModule.PiggyClicker.controller.PiggyClickerGameMgr"):getInstance()
-- 调查问卷
require("activities.Activity_SurveyinGame.controller.SurveyinGameControl"):getInstance()
require("activities.Activity_InviteLoading.controller.InviteLoadingManager"):getInstance()
-- 集卡赛季末收益提升
require("activities.Activity_CardEnd_Special.controller.CardEndSpecialMgr"):getInstance()
--集卡规则变化
require("activities.Activity_SwimPool_Card.controller.SwimPoolCardMgr"):getInstance()
--集卡商城宣传
require("activities.Activity_PoolCard_Store.controller.PoolCardStoreMgr"):getInstance()
--送卡规则变化宣传
require("activities.Activity_PoolCard_SendCard.controller.PoolCardSendCardMgr"):getInstance()
-- 泳池赛季特殊卡册宣传
require("activities.Activity_MagicChip.controller.MagicChipMgr"):getInstance()
--金币宣传
require("activities.Activity_CoinExpand.controller.CoinExpandManager"):getInstance()
--
require("activities.Activity_CoinExpand_Start.controller.CoinExpandStartManager"):getInstance()
require("activities.Activity_CoinExpand_Loading.controller.CoinExpandLoadingManager"):getInstance()
-- 刮刮卡
require("activities.Activity_ScratchCards.controller.ScratchCardsMgr"):getInstance()
require("activities.Activity_ScratchCards.controller.ScratchCardsLoadingMgr"):getInstance()
require("activities.Activity_ScratchCards.controller.ScratchCardsBuyMgr"):getInstance()
require("activities.Activity_ScratchCards.controller.ScratchCardsRuleMgr"):getInstance()
require("activities.Activity_ScratchCards.controller.ScratchCardsCountDownMgr"):getInstance()
--三周年分享挑战
require("activities.Activity_MemoryLane.controller.MemoryLaneMgr"):getInstance()
-- 限时任务 气球挑战
require("activities.Activity_BalloonRush.controller.BalloonRushManager"):getInstance()
-- 弹珠小游戏
require("GameModule.PinBallGo.controller.PinBallGoManager"):getInstance()
require("GameModule.PinBallGo.controller.PinBallGosLoadingMgr"):getInstance()
-- spin送道具
require("activities.Activity_SpinItem.controller.SpinItemControl"):getInstance()
require("activities.SpinGetItem.controller.SpinGetItem"):getInstance()
require("GameModule.MachineGrandShare.controller.MachineGrandShareManager"):getInstance()
-- 单日特殊任务
require("activities.Activity_Wanted.controller.WantedManager"):getInstance()
-- 品质头像框挑战
require("activities.Activity_SpecialFrame_Challenge.controller.SpecialFrame_ChallengeMgr"):getInstance()
-- 头像框挑战
require("activities.Activity_FrameChallenge.controller.FrameChallengeMgr"):getInstance()
-- 弹珠小游戏
require("GameModule.Plinko.controller.PlinkoMgr"):getInstance()
-- 商城指定档位送道具
require("activities.Activity_PurchaseGift.controller.PurchaseGiftMgr"):getInstance()
-- 聚合挑战结束促销
require("activities.Promotion_HolidayEnd.controller.HolidayEndControl"):getInstance()
-- 新推币机
require("activities.Activity_NewCoinPusher.controller.NewCoinPusherManager"):getInstance()
require("activities.Activity_NewCoinPusher.controller.NewCoinPusherSaleMgr"):getInstance()
require("activities.Activity_NewCoinPusher.controller.NewCoinPusherTaskMgr"):getInstance()
require("activities.Activity_NewCoinPusher.controller.NewCoinPusherShowTopMgr"):getInstance()
-- 鲨鱼游戏特殊轮次卡
require("activities.Activity_MagicGame_Guarantee.controller.MagicGameGuaranteeMgr"):getInstance()
-- 盖戳功能
require("GameModule.LuckyStamp.controller.LuckyStampMgr"):getInstance()
require("activities.Activity_LuckyStamp.controller.Activity_LuckyStampMgr"):getInstance()
require("activities.Activity_LuckyStampRule.controller.Activity_LuckyStampRuleMgr"):getInstance()
-- 金卡日(渠道)
require("activities.Activity_GoldenDayRule.controller.GoldenDayRuleMgr"):getInstance()
-- 金卡日(开启)
require("activities.Activity_GoldenDayOpen.controller.GoldenDayOpenMgr"):getInstance()
-- 购买权益
require("GameModule.PBInfo.controller.PBInfoController"):getInstance()
-- 小猪送缺卡
require("activities.Activity_PigRandomCard.controller.PigRandomCardMgr"):getInstance()
-- 集卡特殊卡册
require("GameModule.CardObsidian.controller.ObsidianCardMgr"):getInstance()
require("GameModule.CardObsidian.controller.CardObsidianCountDownMgr"):getInstance()
require("GameModule.CardObsidian.controller.CardObsidianOpenMgr"):getInstance()
require("GameModule.CardObsidian.controller.CardObsidianRulePublicizeMgr"):getInstance()
require("GameModule.CardObsidian.controller.CardObsidianRuleMgr"):getInstance()
require("GameModule.CardObsidian.controller.CardObsidianJackpotMgr"):getInstance()
-- 绑定手机
require("views.BindPhone.BindPhoneCtrl"):getInstance()
-- 疯狂购物车
require("activities.Activity_CrazyCart.controller.CrazyCartMgr"):getInstance()
-- 红蓝对决
require("activities.Activity_FactionFight.controller.FactionFightControl"):getInstance()
require("activities.Activity_CyberMonday.controller.CyberMondayMgr"):getInstance()
-- 黑五全服累充
require("activities.Activity_GrandPrize.controller.GrandPrizeMgr"):getInstance()
-- 黑五全服累充
require("activities.Activity_GrandPrizeStart.controller.GrandPrizeStartMgr"):getInstance()
-- 黑五代币抽奖
require("activities.Activity_BFDraw.controller.BFDrawMgr"):getInstance()
-- 圣诞节台历
require("activities.Activity_ChristmasAdventCalendar.controller.ChristmasCalendarMgr"):getInstance()
-- vip双倍积分
require("activities.Activity_VIPDoublePoint.controller.VipDoublePointMgr"):getInstance()
require("activities.Activity_VIPResetOpen.controller.VipResetOpenMgr"):getInstance()
require("activities.Activity_VIPResetRule.controller.VipResetRuleMgr"):getInstance()
--收藏关卡
require("GameModule.CollectLevel.controller.CollectLevelManager"):getInstance()
--好友系统
require("GameModule.Friend.controller.FriendManager"):getInstance()
--好友系统
require("GameModule.FBFriend.controller.FBFriendMgr"):getInstance()
-- blast任务新版
require("activities.Activity_Blast.controller.BlastTaskNewMgr"):getInstance()
-- 全服累充活动
require("activities.Activity_Allpay.controller.AllpayManager"):getInstance()
-- 个人累充活动
require("activities.Activity_AddPay.controller.AddPayManager"):getInstance()
-- 接水管活动
require("activities.Activity_PipeConnect.controller.PipeConnectManager"):getInstance()
require("activities.Activity_PipeConnect.controller.PipeConnectSaleManager"):getInstance()
require("activities.Activity_PipeConnect.controller.PipeConnectShowTopManager"):getInstance()
require("activities.Activity_PipeConnect.controller.PipeConnectTaskMgr"):getInstance()
--年终总结
require("activities.Activity_YearEndSummary.controller.YearEndSummaryManager"):getInstance()
-- 新年送礼
require("activities.Activity_NewYearGift.controller.NewYearGiftMgr"):getInstance()
-- 调查问卷通用弹版
require("GameModule.SurveyInGame.controller.SurveyInGameMgr"):getInstance()
--钻石挑战关闭活动
require("activities.Activity_DiamondChallengeClose.controller.DiamondChallengeCloseMgr"):getInstance()
--钻石挑战倒计时活动
require("activities.Activity_DiamondChallenge_CountDown.controller.DiamondChallenge_CountDownMgr"):getInstance()
-- 农场
require("GameModule.Farm.controller.FarmControl"):getInstance()
require("GameModule.Farm.controller.FarmLoadingControl"):getInstance()
require("GameModule.Farm.controller.FarmRuleControl"):getInstance()
require("GameModule.Farm.controller.FarmRuleControl2"):getInstance()
-- 新手期集卡
require("GameModule.CardNovice.controller.CardNoviceMgr"):getInstance()
-- 新手期集卡开启宣传活动
require("activities.Activity_CardOpen_NewUser.controller.CardOpenNewUserMgr"):getInstance()

-- 钻石挑战重开活动
require("activities.Activity_DiamondChallengeOpen.controller.DiamondChallengeOpenMgr"):getInstance()
require("activities.Activity_DartsGameNew.controller.DartsGameManager"):getInstance()
require("activities.Activity_DartsGameNew_Loading.controller.DartsGameLoadingMgr"):getInstance()
require("activities.Activity_7DaysPurchase.controller.SevenDaysPurchaseManager"):getInstance()
-- 3倍盖戳
require("activities.Activity_TripleStamp.controller.TripleStampMgr"):getInstance()
-- 自选任务
require("activities.Activity_PickTask.controller.PickTaskManager"):getInstance()
require("GameModule.GrowthFund.controller.GrowthFundCtrl"):getInstance()
require("activities.Activity_HolidayWheel.controller.HolidayWheelManager"):getInstance()
-- 宝石返还
require("activities.Activity_CrystalBack.controller.CrystalBackMgr"):getInstance()
-- 支付二次确认弹板
require("GameModule.PaymentConfirm.controller.PaymentConfirmCtr"):getInstance()
-- 黑曜卡幸运轮盘
require("activities.Activity_ObsidianWheel.controller.ObsidianWheelMgr"):getInstance()
-- 3倍vip点数
require("activities.Activity_3xVip.controller.TripleVipMgr"):getInstance()
-- 限时促销
require("activities.Activity_LimitedOffer.controller.LimitedOfferMgr"):getInstance()
-- vip点数池
require("activities.Activity_VipPoints_Boost.controller.VipPointsBoostMgr"):getInstance()
-- 新破冰促销
require("GameModule.IcebreakerSale.controller.IcebreakerSaleCtrl"):getInstance()
-- 月卡
require("GameModule.MonthlyCard.controller.MonthlyCardMgr"):getInstance()
-- bigwin
require("activities.Activity_BigWin_Challenge.controller.BigWinChallengeMgr"):getInstance()
require("activities.Activity_legendary_win.controller.LegendaryWinMgr"):getInstance()
require("activities.Activity_HolidayChallenge.controller.HolidayChallengeRankManager"):getInstance()
require("activities.Activity_HolidayChallenge.controller.HolidayChallengeSpecialManager"):getInstance()
-- wild卡转盘
require("activities.Activity_WildDraw.controller.WildDrawMgr"):getInstance()
-- bingo连线
require("activities.Activity_LineSale.controller.LineSaleMgr"):getInstance()
-- album race额外发放新赛季卡包奖励
require("activities.Activity_AlbumRaceNewChips.controller.AlbumRaceNewChipsMgr"):getInstance()
-- 集卡赛季末聚合
require("activities.Activity_ChaseForChips.controller.ChaseForChipsMgr"):getInstance()
--集卡赛季末个人累充PLUS
require("activities.Activity_TopUpBonus.controller.TopUpBonusManager"):getInstance()
require("activities.Activity_TopUpBonus.controller.TopUpBonusLastManager"):getInstance()
-- 膨胀宣传 集卡
require("activities.Activity_BigBang_Album.controller.BigBangAlbumMgr"):getInstance()
-- 膨胀宣传 金币商店
require("activities.Activity_BigBang_CoinStore.controller.BigBangCoinStoreMgr"):getInstance()
-- 膨胀宣传 免费金币
require("activities.Activity_BigBang_FreeCoin.controller.BigBangFreeCoinMgr"):getInstance()
-- 膨胀宣传 主图
require("activities.Activity_BigBang_Start.controller.BigBangStartMgr"):getInstance()
-- 膨胀宣传 合成
require("activities.Activity_BigBang_Merge.controller.BigBangMergeMgr"):getInstance()
-- 第二货币抽奖    
require("activities.Activity_GemMayWin.controller.GemMayWinMgr"):getInstance()
-- 膨胀宣传-预热
require("activities.Activity_BigBang_WarmUp.controller.BigBangWarmUpMgr"):getInstance()
-- 商城改版宣传活动
require("activities.Activity_ShopUp.controller.Activity_ShopUpMgr"):getInstance()
-- 常规促销
require("GameModule.SpecialSale.controller.SpecialSaleMgr"):getInstance()
-- 限时抽奖
require("GameModule.HourDeal.controller.HourDealMgr"):getInstance()
-- 付费目标
require("activities.Activity_GetMorePayLess.controller.GetMorePayLessMgr"):getInstance()
-- 关卡促销入口
require("GameModule.BestDeal.controller.BestDealMgr"):getInstance()
-- 行尸走肉预热活动
require("activities.Activity_Zombie_WarmUp.controller.ZombieWarmUpMgr"):getInstance()
-- 合成转盘
require("activities.Activity_MagicGarden.controller.MagicGardenMgr"):getInstance()
-- Minz
require("activities.Activity_Minz.controller.MinzMgr"):getInstance()
require("activities.Activity_Minz.controller.MinzLoadingMgr"):getInstance()
require("activities.Activity_Minz.controller.MinzRuleMgr"):getInstance()
--自选促销礼包
require("activities.Promotion_DIYComboDeal.controller.DIYComboDealMgr"):getInstance()
-- zombie
require("activities.Activity_Zombie.controller.ZombieManager"):getInstance()
require("activities.Activity_Zombie.controller.ZombieRuleManager"):getInstance()
-- 充值抽奖池
require("activities.Activity_PrizeGame.controller.PrizeGameMgr"):getInstance()
-- 第二货币消耗挑战
require("activities.Activity_GemChallenge.controller.GemChallengeMgr"):getInstance()
-- 公会对决 开启宣传
require("activities.Activity_TeamDuel_loading.controller.TeamDuelLoadingMgr"):getInstance()
-- 钻石挑战通关挑战
require("activities.Activity_DiamondMania.controller.DiamondManiaMgr"):getInstance()
--返回持金极大值促销
require("activities.Activity_TimeBack.controller.TimeBackMgr"):getInstance()
-- 新版回归签到
require("GameModule.Return.controller.ReturnMgr"):getInstance()
-- 生日信息
require("activities.Activity_Birthday.controller.BirthdayMgr"):getInstance()
require("activities.Activity_Birthday.controller.BirthdayPubilcityMgr"):getInstance()
-- 公会宝箱宣传
require("activities.Activity_TeamChest_Loading.controller.Activity_TeamChest_LoadingMgr"):getInstance()
-- 组队打BOSS
require("activities.Activity_DragonChallenge.controller.DragonChallengeMgr"):getInstance()
--MINZ：最后一天雕像增加
require("activities.Activity_Minz_Extra.controller.MinzExtraMgr"):getInstance()
--Quest中增加MINZ道具宣传
require("activities.Activity_QuestMinz_Intro.controller.QuestMinzIntroMgr"):getInstance()
-- 付费排行榜
require("activities.Activity_PayRank.controller.PayRankMgr"):getInstance()
-- flamingo jackopt 活动
require("activities.Activity_FlamingoJackpot.controller.FlamingoJackpotMgr"):getInstance()
-- Promotion_LevelDash
require("activities.Promotion_LevelDash.controller.PromotionLevelDashMgr"):getInstance()
-- 商城停留送优惠券
require("activities.Activity_StayCoupon.controller.StayCouponMgr"):getInstance()
-- 高倍场体验卡促销
require("activities.Activity_HighClubSale.controller.HighClubSaleMgr"):getInstance()
-- 三指针转盘促销
require("activities.Activity_DIYWheel.controller.DIYWheelMgr"):getInstance()
-- 公会表情包宣传
require("activities.Activity_NewStickers_loading.controller.NewStickersLoadingMgr"):getInstance()
-- 新手三日任务
require("activities.Activity_NoviceTrail.controller.ActNoviceTrailMgr"):getInstance()
-- luckySpin superSpin
require("GameModule.LuckySpin.controller.LuckySpinMgr"):getInstance()
-- 组队boss预告
require("activities.Activity_DragonChallenge_warning.controller.DragonChallengeWarningMgr"):getInstance()
require("activities.Activity_QuestMinz_Intro/controller.QuestMinzIntroMgr"):getInstance()
--集卡小猪
require("activities.Activity_ChipPiggy.controller.ChipPiggyMgr"):getInstance()
--集卡小猪loading宣传
require("activities.Activity_ChipPiggy.controller.ChipPiggyLoadingMgr"):getInstance()
--集卡小猪countdown宣传
require("activities.Activity_ChipPiggy.controller.ChipPiggyCountDownMgr"):getInstance()
--集卡小猪rule宣传
require("activities.Activity_ChipPiggy.controller.ChipPiggyRuleMgr"):getInstance()
--小猪三合一打包促销
require("activities.Activity_TrioPiggy.controller.TrioPiggyMgr"):getInstance()
-- 赛季末返新卡
require("activities.Activity_GrandFinale.controller.GrandFinaleMgr"):getInstance()
-- 4格连续充值
require("activities.Activity_KeepRecharge4.controller.KeepRecharge4Mgr"):getInstance()
require("activities.Activity_CardMythic_Loading.controller.CardMythicLoadingMgr"):getInstance()
require("activities.Activity_CardMythic_SourceLoading.controller.CardMythicSourceLoadingMgr"):getInstance()
-- LeveDashLink小游戏
require("GameModule.LeveDashLinko.controller.LeveDashLinkoMgr"):getInstance()
-- 4周年抽奖+分奖
require("activities.Activity_4BdayDraw.controller.dayDraw4BMgr"):getInstance()
-- 新手期集卡促销
require("GameModule.CardNovice.controller.CardNoviceSaleMgr"):getInstance()
-- 限时膨胀 loading宣传
require("activities.Activity_TimeLimitExpansion.controller.TimeLimitExpansionLoadingMgr"):getInstance()
-- 限时膨胀
require("activities.Activity_TimeLimitExpansion.controller.TimeLimitExpansionMgr"):getInstance()
require("GameModule.BetUpNotice.controller.BetUpNoticeMgr"):getInstance()
-- 三档首冲
require("GameModule.FirstSaleMulti.controller.FirstSaleMultiMgr"):getInstance()
-- 限时集卡多倍奖励
require("activities.Activity_AlbumMoreAward.controller.AlbumMoreAwardMgr"):getInstance()
--第二货币小猪
require("activities.Activity_GemPiggy.controller.GemPiggyMgr"):getInstance()
require("activities.Activity_GemPiggy.controller.GemPiggyLoadingMgr"):getInstance()
require("activities.Activity_GemPiggy.controller.GemPiggyCountDownMgr"):getInstance()
require("activities.Activity_GemPiggy.controller.GemPiggyRuleMgr"):getInstance()
-- 三联优惠券
require("activities.Activity_CouponRewards.controller.CouponRewardsMgr"):getInstance()
-- 等级里程碑
require("GameModule.LevelRoad.controller.LevelRoadMgr"):getInstance()
--等级里程碑小游戏
require("activities.Activity_LevelRoadGame.controller.LevelRoadGameMgr"):getInstance()
--DIY专题活动
require("activities.Activity_DiyFeature.controller.DiyFeatureManager"):getInstance()
require("activities.Activity_DiyFeature.controller.DiyFeatureLoadingManager"):getInstance()
require("activities.Activity_DiyFeature.controller.DiyFeatureRuleManager"):getInstance()
require("activities.Activity_DiyFeature.controller.DiyFeaturePromotionManager"):getInstance()
require("activities.Activity_DiyFeature.controller.DiyFeatureNormalSaleManager"):getInstance()
-- LEVEL UP PASS
require("activities.Activity_LevelUpPass.controller.LevelUpPassMgr"):getInstance()
-- 鲨鱼游戏道具化
require("GameModule.MythicGame.controller.MythicGameMgr"):getInstance()
-- 鲨鱼游戏道具化促销
require("activities.Activity_CardGame_Sale.controller.MythicGameSaleMgr"):getInstance()
-- 周三公会积分双倍
require("activities.Activity_ClanDoublePoints.controller.ClanDoublePointsControl"):getInstance()
--单日限时比赛
require("activities.Activity_LuckyRace.controller.LuckyRaceMgr"):getInstance()
-- 次日礼物
require("GameModule.TomorrowGift.controller.TomorrowGiftMgr"):getInstance()
-- 大R高性价比礼包促销
require("activities.Activity_SuperValue.controller.SuperValueMgr"):getInstance()
-- 新手任务
require("GameModule.SysNoviceTask.controller.SysNoviceTaskMgr"):getInstance()
-- 新版小猪挑战
require("activities.Activity_PiggyGoodies.controller.PiggyGoodiesMgr"):getInstance()
-- 合成商店折扣
require("activities.Activity_DeluxeClub_Merge_StoreCoupon.controller.MergeStoreCouponMgr"):getInstance()
-- DIYFEATURE新手任务
require("activities.Activity_DIYFeatureMission.controller.DIYFeatureMissionMgr"):getInstance()
require("activities.Activity_DiySale.controller.Activity_DiySaleMgr"):getInstance()
--大富翁
require("activities.Activity_OutsideCave.controller.OutsideCaveManager"):getInstance()
--砸龙蛋
require("activities.Activity_OutsideCave.controller.OutsideCaveEggsMgr"):getInstance()
--促销
require("activities.Activity_OutsideCave.controller.OutsideCaveSaleManager"):getInstance()
require("activities.Activity_OutsideCave.controller.OutsideCaveShowTopManager"):getInstance()
--任务
require("activities.Activity_OutsideCave.controller.OutsideCaveTaskNewMgr"):getInstance()
require("activities.Activity_OutsideCave.controller.OutsideCaveTaskMgr"):getInstance()
-- 新手期7日签到 v2
require("GameModule.NoviceSevenSign.controller.NoviceSevenSignMgr"):getInstance()
-- 集装箱大亨
require("activities.Activity_BlindBox.controller.BlindBoxMgr"):getInstance()
-- 挖钻石聚合
require("activities.Activity_JewelMania.controller.JewelManiaMgr"):getInstance()
-- 合成pass
require("activities.Activity_MergePass.controller.MergePassMgr"):getInstance()
require("activities.Activity_MergePassLayer.controller.MergePassLayerMgr"):getInstance()
--礼物兑换码
require("GameModule.GiftCodes.controller.GiftCodesMgr"):getInstance()
-- 膨胀消耗1v1比赛
require("activities.Activity_FrostFlameClash.controller.FrostFlameClashMgr"):getInstance()
require("activities.Activity_FrostFlameClash_loading.controller.Activity_FrostFlameClash_LoadingManager"):getInstance()
-- 膨胀宣传 集卡 Monster版
require("activities.Activity_Monster_Album.controller.MonsterAlbumMgr"):getInstance()
-- 膨胀宣传 合成
require("activities.Activity_Monster_Merge.controller.MonsterMergeMgr"):getInstance()
-- 膨胀宣传-预热
require("activities.Activity_Monster_WarmUp.controller.MonsterWarmUpMgr"):getInstance()
-- 膨胀宣传（怪兽） 金币商店
require("activities.Activity_Monster_CoinStore.controller.MonsterCoinStoreMgr"):getInstance()
-- 膨胀宣传（怪兽） 免费金币
require("activities.Activity_Monster_FreeCoins.controller.MonsterFreeCoinsMgr"):getInstance()
-- 膨胀宣传（怪兽） 总
require("activities.Activity_Monster_Start.controller.MonsterStartMgr"):getInstance()
-- 膨胀宣传（怪兽） 小猪
require("activities.Activity_Monster_Piggy.controller.MonsterPiggyMgr"):getInstance()
-- 新版钻石挑战
require("activities.Activity_NewDiamondChallenge.controller.NewDChallengeMgr"):getInstance()
-- 新版钻石挑战 宣传图
require("activities.Activity_NewDiamondChallenge_End.controller.NewDiamondChallenge_EndMgr.lua"):getInstance()
-- 新版钻石挑战 宣传图
require("activities.Activity_NewDiamondChallenge_Loading.controller.NewDiamondChallenge_LoadingMgr.lua"):getInstance()
-- 新版钻石挑战 宣传图
require("activities.Activity_NewDiamondChallenge_Rule.controller.NewDiamondChallenge_RuleMgr.lua"):getInstance()
-- 新版钻石挑战限时活动
require("activities.Activity_NewDiamondChallengeRush.controller.NewDCRushMgr.lua"):getInstance()
-- AppCharge
require("GameModule.ACharge.controller.AChargeControl"):getInstance()
require("GameModule.FloatView.controller.FloatViewMgr"):getInstance()
-- 万亿赢家挑战功能
require("GameModule.TrillionChallenge.controller.TrillionChallengeMgr"):getInstance()
-- SuperSpin送道具
require("activities.Activity_LuckySpinSpecial.controller.LuckySpinSpecialManager"):getInstance()
-- 破产促销V2
require("GameModule.BrokenSaleV2.controller.BrokenSaleV2Mgr"):getInstance()
-- 无限促销
require("activities.Activity_FunctionSale_Infinite.controller.FunctionSaleInfiniteMgr"):getInstance()
-- 大活动PASS
require("activities.Activity_FunctionSale_Pass.controller.FunctionSalePassMgr"):getInstance()
-- 第二货币两张优惠券
require("activities.Activity_TwoGemCoupons.controller.TwoGemCouponsMgr"):getInstance()
-- 圣诞聚合签到
require("activities.Activity_HolidayNewChallenge.AdventCalendar.controller.AdventCalendarMgr"):getInstance()
-- 圣诞聚合小游戏
require("activities.Activity_HolidayNewChallenge.HolidaySideGame.controller.HolidaySideGameMgr"):getInstance()
-- 圣诞聚合pass
require("activities.Activity_HolidayNewChallenge.HolidayPass.controller.HolidayPassMgr"):getInstance()
-- 圣诞聚合商店
require("activities.Activity_HolidayNewChallenge.HolidayStore.controller.HolidayStoreMgr"):getInstance()
-- 圣诞聚合排行榜
require("activities.Activity_HolidayNewChallenge.HolidayRank.controller.HolidayRankMgr"):getInstance()
-- 圣诞聚合
require("activities.Activity_HolidayNewChallenge.HolidayChallenge.controller.HolidayChallengeMgr"):getInstance()
-- 圣诞聚合商店宣传（pass）
require("activities.Activity_HolidayNewChallenge.HolidayStoreNewItem.controller.HolidayStoreNewItemMgr"):getInstance()
-- 圣诞聚合商店宣传（最后一天）
require("activities.Activity_HolidayNewChallenge.HolidayStoreFinalDay.controller.HolidayStoreFinalDayMgr"):getInstance()
-- 第二货币商城折扣送道具
require("activities.Activity_GemCoupon.controller.GemCouponMgr"):getInstance()
-- 指定用户分组送指定档位可用优惠券
require("activities.Activity_VCoupon.controller.VCouponMgr"):getInstance()
-- 抽奖轮盘
require("activities.Activity_CrazyWheel.controller.CrazyWheelMgr"):getInstance()
-- 预热 NewDC
require("activities.Activity_NewDC_WarmUp.controller.NewDCWarmUpMgr"):getInstance()
-- 寻宝之旅
require("activities.Activity_TreasureHunt.controller.ActTreasureHuntMgr"):getInstance()
-- SuperSpin高级版送缺卡
require("activities.Activity_FireLuckySpinRandomCard.controller.FireLuckySpinRandomCardMgr"):getInstance()
-- 新版常规促销
require("GameModule.RoutineSale.controller.RoutineSaleMgr"):getInstance()
-- 收集邮件抽奖
require("activities.Activity_MailLottery.controller.MailLotteryMgr"):getInstance()

require("GameModule.OperateGuidePopup.controller.OperateGuidePopupMgr"):getInstance()
-- 宠物系统
require("GameModule.Sidekicks.controller.SidekicksManager"):getInstance()
-- 大赢宝箱
require("activities.Activity_MegaWinParty.controller.MegaWinPartyMgr"):getInstance()
require("activities.Activity_MegaWinParty.controller.MegaWinPartyLoadingMgr"):getInstance()
-- 打开推送通知送奖
require("activities.Activity_Notification.controller.NotificationMgr"):getInstance()
-- 埃及推币机
require("activities.Activity_EgyptCoinPusher.controller.EgyptCoinPusherManager"):getInstance()
require("activities.Activity_EgyptCoinPusher.controller.EgyptCoinPusherSaleMgr"):getInstance()
require("activities.Activity_EgyptCoinPusher.controller.EgyptCoinPusherTaskMgr"):getInstance()
require("activities.Activity_EgyptCoinPusher.controller.EgyptCoinPusherShowTopMgr"):getInstance()
-- 完成任务装饰圣诞树
require("activities.Activity_MissionsToDIY.controller.MissionsToDIYMgr"):getInstance()
-- 宠物规则宣传
require("activities.Activity_PetRule.controller.PetRuleMgr"):getInstance()
-- 代币预热
require("activities.Activity_BucksPre.controller.BucksPreMgr"):getInstance()
-- 圣诞充值分奖
require("activities.Activity_XmasCraze2023.controller.XmasCraze2023Mgr"):getInstance()
-- 圣诞累充分奖
require("activities.Activity_XmasSplit2023.controller.XmasSplit2023Mgr"):getInstance()
-- 第三货币
require("GameModule.ShopBuck.controller.ShopBuckMgr"):getInstance()
-- 商城充值返代币
require("activities.Activity_BucksBack.controller.BucksBackMgr"):getInstance()
-- 代币宣传
require("activities.Activity_Bucks_Loading.controller.BucksLoadingMgr"):getInstance()
-- 神秘宝箱系统
require("GameModule.BoxSystem.controller.BoxSystemMgr"):getInstance()
-- 收集手机号
require("activities.Activity_CollectPhone.controller.CollectPhoneMgr"):getInstance()
-- 代币 支持点位新增宣传
require("activities.Activity_Bucks_New.controller.BucksNewMgr"):getInstance()
-- SuperSpin 提高倍数
require("activities.Activity_LuckySpinUpgrade.controller.LuckySpinUpgradeMgr"):getInstance()
-- 关卡bet上的气泡
require("GameModule.BetBubbles.controller.BetBubblesMgr"):getInstance()
-- 宠物-预热宣传
require("activities.Activity_PetLoading.controller.PetLoadingMgr"):getInstance()
-- 宠物-开启宣传
require("activities.Activity_PetStart.controller.PetStartMgr"):getInstance()
-- 宠物-7日任务
require("activities.Activity_PetMission.controller.PetMissionMgr"):getInstance()