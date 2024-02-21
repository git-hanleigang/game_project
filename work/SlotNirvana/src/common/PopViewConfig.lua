--弹窗配置类
local PopViewConfig = class("PopViewConfig")
--弹窗触发类型
GD.POP_VC_TYPE = {
    LOGIN_TO_LOBBY = 1, --登录界面到大厅
    GAME_TO_LOBBY = 2, --关卡界面到大厅
    ACTIVITY_TO_LOBBY = 3, --活动界面到大厅
    CLICK_DAILYWHEEL = 4 --手动点击每日轮盘
}
--检测阶段
GD.POP_VC_STEP = {
    NOTICE = 1, --游戏公告
    NEW_GUDIE = 2, --新手引导阶段
    DAILY_REWARD = 3, --每日轮盘阶段
    RECONNECT = 4, --断线重连阶段
    NOTIFY_REWARD = 5, --推送奖励阶段
    CONFIG_VIEW = 6, --后台配置弹窗阶段
    SHOW_TIP = 7, --系统提示阶段
    ADS_REWARD = 8, --看广告任务检测阶段
    ADS_CHALLENGE = 9 --广告任务
}

function PopViewConfig:ctor()
    self:initConfig()
end
--初始化配置
function PopViewConfig:initConfig()
    self.m_stepConfig = {}
    self.m_eventConfig = {}
    self:initLoginToLobbyStep()
    self:initGameToLobbyStep()
    self:initActivityToLobbyStep()
    self:initDailyWheelStep()
    --公告事件添加
    self:initAnnouncement()
    --新手引导事件添加
    self:initNewGuide()
    --每日奖励事件添加(目前只有每日轮盘)
    self:initDailyReward()
    --断线重连事件添加
    self:initReconnect()
    --推送奖励事件添加
    self:initNotifyReward()
    --后台配置弹窗添加
    self:initConfigView()
    --系统提示阶段
    self:initShowTip()
    --看广告任务检测阶段
    self:initAdsReward()
    --广告任务
    self:initAdsChallenge()
end
--设置阶段信息
function PopViewConfig:setStepInfo(triggerType, list)
    self.m_stepConfig[triggerType] = list
end
--设置事件信息
function PopViewConfig:setEventInfo(stepType, list)
    self.m_eventConfig[stepType] = list
end
--读取配置
function PopViewConfig:getConfig()
    return self.m_stepConfig, self.m_eventConfig
end
--可以手动调用的方法
-- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT,eventTag) --弹窗逻辑执行下一个事件(如果eventTag~=nil只有当前事件标签和eventTag对应上才会执行
-- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_STEP)--弹窗逻辑执行下一个阶段
-- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER,false) --弹窗逻辑执行结束回调 flag 是否不执行结束回调
---------------------------------触发配置 START ---------------------------------
--登录界面到大厅需要检测的阶段配置
function PopViewConfig:initLoginToLobbyStep()
    local stepList = nil
    if globalData.userRunData.levelNum <= globalData.constantData.NEW_USER_GUIDE_LEVEL then
        stepList = {
            POP_VC_STEP.NOTICE,
            POP_VC_STEP.NOTIFY_REWARD,
            POP_VC_STEP.NEW_GUDIE,
            POP_VC_STEP.DAILY_REWARD,
            POP_VC_STEP.RECONNECT,
            POP_VC_STEP.CONFIG_VIEW
        }
    else
        stepList = {
            POP_VC_STEP.NOTICE,
            POP_VC_STEP.NOTIFY_REWARD,
            POP_VC_STEP.NEW_GUDIE,
            POP_VC_STEP.DAILY_REWARD,
            POP_VC_STEP.RECONNECT,
            POP_VC_STEP.CONFIG_VIEW,
            POP_VC_STEP.SHOW_TIP,
            POP_VC_STEP.ADS_CHALLENGE
        }
    end
    self:setStepInfo(POP_VC_TYPE.LOGIN_TO_LOBBY, stepList)
end
--关卡界面到大厅需要检测的阶段配置
function PopViewConfig:initGameToLobbyStep()
    local stepList
    if globalData.userRunData.levelNum <= globalData.constantData.NEW_USER_GUIDE_LEVEL then
        stepList = {
            POP_VC_STEP.NEW_GUDIE,
            POP_VC_STEP.DAILY_REWARD,
            POP_VC_STEP.RECONNECT
        }
    else
        stepList = {
            POP_VC_STEP.NEW_GUDIE,
            POP_VC_STEP.DAILY_REWARD,
            POP_VC_STEP.NOTIFY_REWARD,
            POP_VC_STEP.CONFIG_VIEW,
            POP_VC_STEP.SHOW_TIP
        }
    end
    self:setStepInfo(POP_VC_TYPE.GAME_TO_LOBBY, stepList)
end
--活动界面到大厅
function PopViewConfig:initActivityToLobbyStep()
    --暂无
    local stepList = {}
    self:setStepInfo(POP_VC_TYPE.ACTIVITY_TO_LOBBY, stepList)
end
--手动点击轮盘后续操作
function PopViewConfig:initDailyWheelStep()
    local stepList = {
        POP_VC_STEP.DAILY_REWARD,
        POP_VC_STEP.ADS_REWARD,
        POP_VC_STEP.RECONNECT
    }
    self:setStepInfo(POP_VC_TYPE.CLICK_DAILYWHEEL, stepList)
end
---------------------------------触发配置 END ---------------------------------
---------------------------------事件配置 START ---------------------------------
--游戏公告
function PopViewConfig:initAnnouncement()
    local eventList = {}
    eventList[#eventList + 1] = {handler(self, self.showPrivacyPollcyUI), "showPrivacyPollcyUI"} -- 隐私政策更新
    eventList[#eventList + 1] = {handler(self, self.showAnnouncementUI), "showAnnouncementUI"} -- 公告
    self:setEventInfo(POP_VC_STEP.NOTICE, eventList)
end
--新手引导事件添加
function PopViewConfig:initNewGuide()
    local eventList = {}
    eventList[#eventList + 1] = {handler(self, self.reconnectIapInfo), "reconnectIapInfo"} -- 补单应该放置在每日奖励之前
    -- 新手quest完成 quest 和 大活动 大厅底部入口添加 解锁引导
    eventList[#eventList + 1] = {handler(self, self.checkQuestLobbyBtmGuide), "checkQuestLobbyBtmGuide"}
    -- 新手引导相关
    eventList[#eventList + 1] = {handler(self, self.newGuideNewUser), "newGuideNewUser"}
    -- 关卡比赛领奖
    eventList[#eventList + 1] = {handler(self, self.collectLeagueReward), "leagueReward"}
    -- 4周年抽奖分奖
    eventList[#eventList + 1] = {handler(self, self.collect4BDayDrawReward), "4BDayDrawReward"}
    -- vip点数池
    eventList[#eventList + 1] = {handler(self, self.vipPointsBoost), "vipPointsBoost"}
    -- 充值抽奖池
    eventList[#eventList + 1] = {handler(self, self.prizeGame), "prizeGame"}
    -- 小猪挑战
    eventList[#eventList + 1] = {handler(self, self.piggyGoodies), "piggyGoodies"}
    -- DuckShot
    eventList[#eventList + 1] = {handler(self, self.miniGameDuckShot), "DuckShot"}
    -- 每日签到
    eventList[#eventList + 1] = {handler(self, self.notifyDailyBonus), "notifyDailyBonus"}
    -- 生日礼物
    eventList[#eventList + 1] = {handler(self, self.notifyBirthdayGift), "notifyBirthdayGift"}
    -- 月卡
    eventList[#eventList + 1] = {handler(self, self.notifyMonthlyCard), "notifyMonthlyCard"}
    -- 编辑生日信息
    eventList[#eventList + 1] = {handler(self, self.notifyBirthdayEdit), "notifyBirthdayEdit"}
    -- 新一期quest
    eventList[#eventList + 1] = {handler(self, self.notifyQuestOpen), "notifyQuestOpen"}
    -- 单人限时比赛 开启
    eventList[#eventList + 1] = {handler(self, self.notifyLuckyRaceOpen), "notifyLuckyRaceOpen"}
    -- 单人限时比赛 领奖
    eventList[#eventList + 1] = {handler(self, self.notifyLuckyRace), "notifyLuckyRace"}
    -- 签到
    eventList[#eventList + 1] = {handler(self, self.notifyFirstPriority), "notifyFirstPriority"}
    -- 广告召回 推广
    eventList[#eventList + 1] = {handler(self, self.notifyRewardAds), "notifyRewardAds"}
    -- 自动进入集卡系统 集卡引导相关
    eventList[#eventList + 1] = {handler(self, self.newGuideAutoCard), "newGuideAutoCard"}
    -- 首次登陆检测
    eventList[#eventList + 1] = {handler(self, self.newGuideFirstLogin), "newGuideFirstLogin"}
    -- 聚合挑战 促销领取弹板
    eventList[#eventList + 1] = {handler(self, self.holidayChallengeSalePop), "holidayChallengeSalePop"}
    -- 弹出WILDCHALLENGE付费挑战 弹板
    -- eventList[#eventList + 1] = {handler(self, self.notifyWildChallenge), "notifyWildChallenge"}
    --eventList[#eventList + 1] = {handler(self, self.notifyInviteReward), "notifyInviteReward"}
    self:setEventInfo(POP_VC_STEP.NEW_GUDIE, eventList)
end

--每日奖励事件添加(目前只有每日轮盘)
function PopViewConfig:initDailyReward()
    local eventList = {}
    -- eventList[#eventList+1] = {handler(self,self.reconnectIapInfo),"reconnectIapInfo"} -- 补单应该放置在每日奖励之前
    eventList[#eventList + 1] = {handler(self, self.dailyRewardWheel), "dailyRewardWheel"} --每日轮盘相关
    eventList[#eventList + 1] = {handler(self, self.dailyRewardPayWheelDrop), "dailyRewardPayWheelDrop"} --付费轮盘掉卡相关
    eventList[#eventList + 1] = {handler(self, self.notifyHolidayEndReward), "notifyHolidayEndReward"} -- 聚合挑战结束促销
    eventList[#eventList + 1] = {handler(self, self.newGuideShowFirstBuy), "newGuideShowFirstBuy"} --100%首购弹窗
    eventList[#eventList + 1] = {handler(self, self.questNewUserLogin), "questNewUserLogin"} --首次登陆检测新手quest
    eventList[#eventList + 1] = {handler(self, self.newGuideShowFirstBingoEnter), "newGuideShowFirstBingoEnter"} --bingo活动首次进入
    eventList[#eventList + 1] = {handler(self, self.newGuideShowCashMoney), "newGuideShowCashMoney"} -- 每日转盘收集3次之后的mega money 引导
    eventList[#eventList + 1] = {handler(self, self.newGuideShowNextCashMoney), "newGuideShowNextCashMoney"} -- mega money 转完以后引导明天继续收集cash money
    eventList[#eventList + 1] = {handler(self, self.redecorGuide), "redecorGuide"} --装修引导
    eventList[#eventList + 1] = {handler(self, self.pokerGuide), "pokerGuide"} --扑克引导
    eventList[#eventList + 1] = {handler(self, self.notifyNewUser7Day), "notifyNewUser7Day"} -- 新手7日目标
    eventList[#eventList + 1] = {handler(self, self.popInviteFirst), "popInviteFirst"} --被邀请者首次进入游戏
    eventList[#eventList + 1] = {handler(self, self.popInviteTip), "popInviteTip"} --被邀请者点击链接进入但是超200级
    eventList[#eventList + 1] = {handler(self, self.popIcebreakerSale), "popIcebreakerSale"} -- 新版破冰促销
    eventList[#eventList + 1] = {handler(self, self.configPushZomReward), "configPushZomReward"} -- zombie检测弹窗
    eventList[#eventList + 1] = {handler(self, self.popColNoviceTrail), "popColNoviceTrail"} -- 有可领取的 新手3日任务奖励
    eventList[#eventList + 1] = {handler(self, self.popLevelRoadSale), "popLevelRoadSale"} -- 等级里程碑促销
    eventList[#eventList + 1] = {handler(self, self.popColTomorrowGift), "popColTomorrowGift"} -- 次日礼物 可领取奖励
    eventList[#eventList + 1] = {handler(self, self.popColFrostFlameClash), "popColFrostFlameClash"} -- 1v1比赛 可领取奖励 
    eventList[#eventList + 1] = {handler(self, self.popTrillionChallengeTaskReward), "popTrillionChallengeTaskReward"} -- 亿万赢钱挑战 可领奖
    eventList[#eventList + 1] = {handler(self, self.popRoutineSale), "popRoutineSale"} -- 新版常规促销
    eventList[#eventList + 1] = {handler(self, self.popNotification), "popNotification"} -- 打开推送通知送奖
    self:setEventInfo(POP_VC_STEP.DAILY_REWARD, eventList)
end
--断线重连事件添加
function PopViewConfig:initReconnect()
    local eventList = {}
    eventList[#eventList + 1] = {handler(self, self.reconnectLuckyStampCard), "reconnectLuckyStampCard"}
    eventList[#eventList + 1] = {handler(self, self.reconnectSpinBonus), "reconnectSpinBonus"}
    -- eventList[#eventList + 1] = {handler(self, self.reconnectLuckyStampProgress), "reconnectLuckyStampProgress"}
    -- eventList[#eventList+1] = {handler(self,self.reconnectIapInfo),"reconnectIapInfo"}
    eventList[#eventList + 1] = {handler(self, self.reconnectSendCoupon), "reconnectSendCoupon"}
    eventList[#eventList + 1] = {handler(self, self.reconnectPigBooster), "reconnectPigBooster"}
    eventList[#eventList + 1] = {handler(self, self.reconnectGoodWheelPiggyMainLayer), "reconnectGoodWheelPiggyMainLayer"} --小猪转盘断线重连
    eventList[#eventList + 1] = {handler(self, self.reconnectCardSmallGame), "reconnectCardSmallGame"}
    eventList[#eventList + 1] = {handler(self, self.reconnectLuckyChooseLayer), "reconnectLuckyChooseLayer"} --常规促销小游戏
    eventList[#eventList + 1] = {handler(self, self.reconnectPurchaseDrawActMainLayer), "reconnectPurchaseDrawActMainLayer"} -- 充值抽奖断线重现
    eventList[#eventList + 1] = {handler(self, self.reconnectStarPickMainLayer), "reconnectStarPickMainLayer"} -- PickStar小游戏
    eventList[#eventList + 1] = {handler(self, self.reconnectPokerRecallMainLayer), "reconnectPokerRecallMainLayer"} --PokerRecall断线重连
    eventList[#eventList + 1] = {handler(self, self.reconnectMiniGameTreasureSeeker), "reconnectMiniGameTreasureSeeker"}
    eventList[#eventList + 1] = {handler(self, self.reconnecCouponChallenge), "reconnecCouponChallenge"}
    eventList[#eventList + 1] = {handler(self, self.reconnectMiniGameCashMoney), "reconnectMiniGameCashMoney"}
    eventList[#eventList + 1] = {handler(self, self.reconnectMiniGamePlinko), "reconnectMiniGamePlinko"} -- luckfish
    eventList[#eventList + 1] = {handler(self, self.reconnectMiniGamePerLink), "reconnectMiniGamePerLink"} -- link小游戏
    eventList[#eventList + 1] = {handler(self, self.reconnecSurveyin), "reconnecSurveyin"} -- 调查问卷
    eventList[#eventList + 1] = {handler(self, self.reconnectBalloonRush), "reconnectBalloonRush"} -- 气球挑战
    eventList[#eventList + 1] = {handler(self, self.reconnetGrandShare), "reconnetGrandShare"} -- 关卡grand截屏分享
    eventList[#eventList + 1] = {handler(self, self.reconnectWorldTripRecall), "reconnectWorldTripRecall"} -- 新版大富翁小游戏领奖
    eventList[#eventList + 1] = {handler(self, self.reconnectWorldTripPhase), "reconnectWorldTripPhase"} -- 新版大富翁领奖
    eventList[#eventList + 1] = {handler(self, self.reconnectWorldTripFinal), "reconnectWorldTripFinal"} -- 新版大富翁领奖
    eventList[#eventList + 1] = {handler(self, self.reconnectTopSale), "reconnectTopSale"}
    eventList[#eventList + 1] = {handler(self, self.reconnectMinz), "reconnectMinz"} -- minz游戏重连
    eventList[#eventList + 1] = {handler(self, self.reconnectDiyFeature), "reconnectDiyFeature"} -- DiyFeature游戏重连
    self:setEventInfo(POP_VC_STEP.RECONNECT, eventList)
end
--推送奖励事件添加
function PopViewConfig:initNotifyReward()
    local eventList = {}
    eventList[#eventList + 1] = {handler(self, self.notifyRewardNewApp), "notifyRewardNewApp"} --版本更新
    eventList[#eventList + 1] = {handler(self, self.notifyNewUserReward), "notifyNewUserReward"} --新手金币不足奖励
    eventList[#eventList + 1] = {handler(self, self.notifyChurnReturnReward), "notifyChurnReturnReward"} --领取流失回归奖励
    eventList[#eventList + 1] = {handler(self, self.notifyReturnV2SignReward), "notifyReturnV2SignReward"} --领取流失回归奖励
    eventList[#eventList + 1] = {handler(self, self.notifyRewardBindFB), "notifyRewardBindFB"} --FB绑定奖励
    eventList[#eventList + 1] = {handler(self, self.notifyRewardRoutineSale), "notifyRewardRoutineSale"} --FB绑定奖励
    -- eventList[#eventList+1] = {handler(self,self.notifyRewardAds),"notifyRewardAds"}                --广告召回
    eventList[#eventList + 1] = {handler(self, self.notifyRewardFb), "notifyRewardFb"} --粉丝页奖励
    eventList[#eventList + 1] = {handler(self, self.notifyRewardFireBase), "notifyRewardFireBase"} --firebase推送奖励
    eventList[#eventList + 1] = {handler(self, self.sendRequestAcitvityRank), "sendRequestAcitvityRank"} --发送获取活动排行榜信息
    eventList[#eventList + 1] = {handler(self, self.saveUserHead), "saveUserHead"} --保存下用户头像
    eventList[#eventList + 1] = {handler(self, self.reconnectLuckySpin), "reconnectLuckySpin"}
    eventList[#eventList + 1] = {handler(self, self.reconnectLuckyStamp), "reconnectLuckyStamp"} -- 盖戳
    eventList[#eventList + 1] = {handler(self, self.collectLotteryReward), "lotteryReward"} -- 乐透彩票领奖
    eventList[#eventList + 1] = {handler(self, self.collectLotteryExtraReward), "collectLotteryExtraReward"} -- 领取乐透额外奖励
    eventList[#eventList + 1] = {handler(self, self.sendClanLastWeekReward), "sendClanLastWeekReward"} --公会上一期的奖励
    eventList[#eventList + 1] = {handler(self, self.notifyClanRankUpDown), "notifyClanRankUpDown"} --公会结算排行榜 段位上升下降
    eventList[#eventList + 1] = {handler(self, self.notifyClanFbInvite), "notifyClanFbInvite"} --通过fb公会邀请链接 进来游戏
    eventList[#eventList + 1] = {handler(self, self.checkLotteryChooseNumberLayer), "checkLotteryChooseNumberLayer"} -- 断线重连弹选号面板
    eventList[#eventList + 1] = {handler(self, self.checkLotteryOpenSourceLayer), "checkLotteryOpenSourceLayer"} -- 玩家升级弹乐透来源弹板
    eventList[#eventList + 1] = {handler(self, self.notifyFBFansBirthday), "notifyFBFansBirthday"} --fb 生日礼物
    eventList[#eventList + 1] = {handler(self, self.notifyMergeWeekReward), "notifyMergeWeekReward"} -- 合成周卡有奖励主动弹出
    eventList[#eventList + 1] = {handler(self, self.notifyBattleMatchReward), "notifyBattleMatchReward"} -- 比赛聚合结算 奖励主动弹出
    eventList[#eventList + 1] = {handler(self, self.shopVipResetLayer), "shopVipResetLayer"} -- VIP重置折扣界面
    eventList[#eventList + 1] = {handler(self, self.reshowDiyFeatureMainLayer), "reshowDiyFeatureMainLayer"} --特殊玩法后 再次展示DiyFeature 主界面
    self:setEventInfo(POP_VC_STEP.NOTIFY_REWARD, eventList)
end
--后台配置弹窗添加
function PopViewConfig:initConfigView()
    local eventList = {}
    eventList[#eventList + 1] = {handler(self, self.configDiyFeaturePromotion), "configDiyFeaturePromotion"} -- DiyFeature结束促销 需要在DiyFeature游戏重连之后
    eventList[#eventList + 1] = {handler(self, self.configPushView), "configPushView"} --策划后台弹窗配置
    --eventList[#eventList + 1] = {handler(self, self.configPushAds), "configPushAds"} --广告弹窗
    eventList[#eventList + 1] = {handler(self, self.configPushDeluexeUnlock), "configPushDeluexeUnlock"} --高倍场解锁
    eventList[#eventList + 1] = {handler(self, self.configDeluxePointToCoins), "configDeluxePointToCoins"} --高倍场点数换金币
    eventList[#eventList + 1] = {handler(self, self.configPushFb), "configPushFb"} --fb粉丝页显示
    --eventList[#eventList + 1] = {handler(self, self.configPushActWanted), "configPushActWanted"} --单日特殊任务
    eventList[#eventList + 1] = {handler(self, self.configPushSelectSide), "configPushSelectSide"} -- 红蓝对决选择阵营
    eventList[#eventList + 1] = {handler(self, self.configPushGrandFinale), "configPushGrandFinale"} -- 赛季末返新卡
    --csc 2021年06月15日 取消周任务刷新弹板
    -- eventList[#eventList+1] = {handler(self,self.configPushWeekMission),"configPushWeekMission"}    --周任务刷新
    self:setEventInfo(POP_VC_STEP.CONFIG_VIEW, eventList)
end
--系统提示阶段
function PopViewConfig:initShowTip()
    local eventList = {}
    eventList[#eventList + 1] = {handler(self, self.tipNewVersion), "tipNewVersion"} --新版本提示
    eventList[#eventList + 1] = {handler(self, self.diningRoomGuide), "diningRoomGuide"} --新版本提示
    eventList[#eventList + 1] = {handler(self, self.tipOtherView), "tipOtherView"} --充值抽奖弹窗
    eventList[#eventList + 1] = {handler(self, self.mileStoneCouponRegister), "MileStoneCouponRegister"} --注册里程碑
    eventList[#eventList + 1] = {handler(self, self.checkFBShareCoupon), "checkFBShareCoupon"} -- fb分享后获取的优惠券弹框
    eventList[#eventList + 1] = {handler(self, self.inboxRewardTips), "inboxRewardTips"} --邮箱额外奖励提示
    eventList[#eventList + 1] = {handler(self, self.FBGuide), "FBGuide"} --FB指引
    eventList[#eventList + 1] = {handler(self, self.tipOverShowQueue), "tipOverShowQueue"} --可重复引导提示这个放到最后 后面的事件会自动执行
    eventList[#eventList + 1] = {handler(self, self.popClanRecuritHallView), "popClanRecuritHallView"} --可重复引导提示这个放到最后 后面的事件会自动执行
    self:setEventInfo(POP_VC_STEP.SHOW_TIP, eventList)
end

-- 看广告奖励事件添加
function PopViewConfig:initAdsReward()
    local eventList = {}
    eventList[#eventList + 1] = {handler(self, self.adsReward), "adsReward"} --看广告任务完成
    self:setEventInfo(POP_VC_STEP.ADS_REWARD, eventList)
end

-- 广告任务
function PopViewConfig:initAdsChallenge()
    local eventList = {}
    eventList[#eventList + 1] = {handler(self, self.showAdChallenge), "showAdChallenge"} --看广告任务完成
    self:setEventInfo(POP_VC_STEP.ADS_CHALLENGE, eventList)
end
---------------------------------事件配置 END ---------------------------------
---------------------------------自定义事件---------------------------------
-- function PopViewConfig:xxx()
--     --如果没有执行事件 会自动调用下一个事件
--     local isExecute = false
--     --具体事件(如果执行成功需要暂停后续弹窗 isExecute = true)
--     return isExecute
-- end

-- 隐私政策更新弹板
function PopViewConfig:showPrivacyPollcyUI()
    local create_time = globalData.userRunData.createTime
    local compare_time = 1668700800000 -- 2022-11-18 00:00:00
    if create_time > compare_time then
        return false
    end
    -- gLobalDataManager:delValueByField("PrivacyPolicyUpdate") -- 清除旧的记录
    if gLobalDataManager:getBoolByField("PrivacyPolicyUpdate", false) then
        return false
    end

    local view = util_createFindView("views/dialogs/PrivacyPolicyUpdateLayer")
    if not tolua.isnull(view) then
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        return true
    end
end

-- 公告
function PopViewConfig:showAnnouncementUI()
    if globalAnnouncementManager:checkAnnouncement(2) then
        globalAnnouncementManager:showAnnouncementUI(
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        )
        return true
    end
    return false
end

---------------------------------自定义事件 新手引导相关
--首次登陆检测
function PopViewConfig:newGuideFirstLogin()
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        -- 非激励视频
        if globalData.saleRunData:isFristLogin() == true then
            globalFireBaseManager:sendFireBaseLog("login_", "appearing")
        -- csc 2021-12-14 11:53:19 删除登录检测广告
        end

        if not G_GetMgr(G_REF.NewUserExpand):checkLobbyIsSlotsStyle() then
            return false
        end

        globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.comeCust)
        if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.comeCust) then
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER, false) --弹窗逻辑执行结束回调 flag 是否不执行结束回调
        end
    end
    return false
end

--首次登陆检测
function PopViewConfig:questNewUserLogin()
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local questMgr = G_GetMgr(ACTIVITY_REF.Quest)
        if questMgr:isNewUserQuest() and questMgr:isRunning() then
            local view = util_createView(QUEST_CODE_PATH.QuestLoginView)
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
            return true
        end
    end
    return false
end

function PopViewConfig:newGuideNewUser()
    --如果没有执行事件 会自动调用下一个事件
    if globalNoviceGuideManager:isNoobUsera(true) then --新用户
        if globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.dallyWhell.id) then --轮盘指引完成了
            return false
        end

        --其他新手
        if G_GetMgr(G_REF.NewUserExpand):checkLobbyIsSlotsStyle() and globalData.userRunData.levelNum <= globalData.constantData.NEW_USER_GUIDE_LEVEL then
            local firstGuideInfo = globalNoviceGuideManager:getFirstGuideInfo()
            if not globalNoviceGuideManager:getIsFinish(firstGuideInfo.id) then --新手金币指引没完成
                globalNoviceGuideManager:addQueue(firstGuideInfo)
                globalNoviceGuideManager:NextShow()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER, false) --弹窗逻辑执行结束回调 flag 是否不执行结束回调
                return true
            end
            if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.comeCust.id) then
                globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.comeCust)
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER, false) --弹窗逻辑执行结束回调 flag 是否不执行结束回调
                return true
            end
        end

        --轮盘指引
        local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
        if wheelData.p_coolDown and wheelData.p_coolDown ~= 0 then
            if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.dallyWhell.id) then
                globalNoviceGuideManager:addFinishList(NOVICEGUIDE_ORDER.dallyWhell)
                --轮盘cd时间没好这种情况只有数据bug才会出直接跳过这个引导
                return false
            end
        end

        --已经玩过轮盘今日都不提示
        if self.m_isShowBonusWheelView then
            return false
        end
        --未下载
        if globalDynamicDLControl:checkDownloading("cashBonusDy") then
            return false
        end

        -- cxc 2021年06月25日15:05:12 未开启 新手期功能 走以前引导逻辑
        if not globalData.GameConfig:checkUseNewNoviceFeatures() then
            --尝试执行轮盘指引
            globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.dallyWhell)
            if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.dallyWhell) then
                gLobalPopViewManager:setPause(true)
                -- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER,false) --弹窗逻辑执行结束回调 flag 是否不执行结束回调
                return true
            end
        elseif globalData.userRunData.levelNum >= 10 then
            -- csc 2021-05-21 大于10级才能尝试轮盘引导
            --尝试执行轮盘指引
            globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.dallyWhell, false, true)
            if globalNoviceGuideManager:isCurrentGuide(NOVICEGUIDE_ORDER.dallyWhell) then
                gLobalPopViewManager:setPause(true)
                -- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_OVER,false) --弹窗逻辑执行结束回调 flag 是否不执行结束回调
                return true
            end
        end
    end
    return false
end

-- 新手quest完成 quest 和 大活动 大厅底部入口添加 解锁引导
function PopViewConfig:checkQuestLobbyBtmGuide()
    local isExecute = false
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return isExecute
    end

    local questMgr = G_GetMgr(ACTIVITY_REF.Quest)
    if questMgr and questMgr:checkQuestUlkLobbyBtmGuide() then
        isExecute = questMgr:dealLobbyBtmGuide()
    end

    return isExecute
end

--新手百分百首购
function PopViewConfig:newGuideShowFirstBuy()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return isExecute
    end

    -- cxc 2021-07-12 14:34:20 新手期 忽略检查新手等级
    local bNewNovice = globalData.GameConfig:checkUseNewNoviceFeatures()
    if globalData.shopRunData:isShowFirstBuyLayer(bNewNovice) then
        if not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.initIcons.id) then
            --送金币
            return isExecute
        elseif not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.comeCust.id) then
            --进入关卡引导
            return isExecute
        elseif not bNewNovice and not globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.dallyWhell.id) then
            -- cxc 2021-07-05 20:15:51 B组不检查 轮盘引导
            --轮盘引导
            return isExecute
        end
        isExecute = true

        -- B组互斥判断,建立在当前能弹出100%新手首充弹板的基础上
        local firstCommSaleData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
        local isnew = G_GetMgr(G_REF.FirstCommonSale):isNewMan()
        if not isnew then
            return false
        end
        local bCanShowFirstSaleMulti = G_GetMgr(G_REF.FirstSaleMulti):isCanShowLayer()
        if bCanShowFirstSaleMulti then
            local view = G_GetMgr(G_REF.FirstSaleMulti):showMainLayer({pos = "Login"})
            -- 按钮名字  类型是url
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():addNodeDot(view, "FirstSaleMulti", DotUrlType.UrlName, true, DotEntrySite.UpView, DotEntryType.Lobby)
            end
        elseif firstCommSaleData then
            local view = G_GetMgr(G_REF.FirstCommonSale):showMainLayer({pos = "Login"})
            -- 按钮名字  类型是url
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():addNodeDot(view, "FirstCommonSale", DotUrlType.UrlName, true, DotEntrySite.UpView, DotEntryType.Lobby)
            end
        else
            local view = util_createView("views.newbieTask.FirstBuyLayer")
            -- 按钮名字  类型是url
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():addNodeDot(view, "FirstBuyLayer", DotUrlType.UrlName, true, DotEntrySite.UpView, DotEntryType.Lobby)
            end
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
    return isExecute
end

-- 修改：2019-09-10删除大厅的bingo新手引导
-- BINGO引导：触发
-- 先判断bingo是否下载完
-- 如果从来没有进入过bingo，且bingo活动开启，且达到进入bingo的条件，引导进入bingo
function PopViewConfig:newGuideShowFirstBingoEnter()
    local isExecute = false
    -- if not CC_SHOW_BINGO_GUIDE then
    --     return isExecute
    -- end
    -- -- 正在下载或者未下载完
    -- if globalDynamicDLControl:checkDownloading("Activity_Bingo") then
    --     return isExecute
    -- end
    -- local bingoData = G_GetMgr(ACTIVITY_REF.Bingo):getRunningData()
    -- -- 判断活动是否开启
    -- if bingoData and bingoData:getOpenFlag() then
    --     -- 如果没有进入过，显示引导
    --     local bingoExtra = bingoData:getBingoExtraData()
    --     if not (bingoExtra and bingoExtra.isFirstEntered) then
    --         isExecute = true
    --         globalNoviceGuideManager:addQueue(NOVICEGUIDE_ORDER.bingoFirstEnter_Lobby)
    --         globalNoviceGuideManager:NextShow()
    --     end
    -- end
    return isExecute
end

-- cash money收集完毕提示 明日继续收集cash bonus
function PopViewConfig:newGuideShowNextCashMoney()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false

    local bPop = false
    local bonusType = G_GetMgr(G_REF.CashBonus):getRunningData():getCurCollectBonus()

    if not globalDynamicDLControl:checkDownloaded("cashBonusDy") then -- 还在下载中 直接返回
        return false
    end

    if bonusType == CASHBONUS_TYPE.BONUS_WHEEL then
        gLobalDataManager:setBoolByField("newGuideShowNextCashMoney", true)
        gLobalDataManager:setBoolByField("newGuideShowCashMoney", false) -- 重置cash money 引导状态
        return false
    end

    if gLobalDataManager:getBoolByField("newGuideShowCashMoney", false) and bonusType ~= CASHBONUS_TYPE.BONUS_MONEY and gLobalDataManager:getBoolByField("newGuideShowNextCashMoney", true) == false then
        bPop = true
    end
    if bPop then
        local data = {
            isShowGuide = true,
            id = 2
        }
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_CASHWHEEL_GUIDE_ZORDER, data)
        gLobalDataManager:setBoolByField("newGuideShowNextCashMoney", true)
        gLobalDataManager:setBoolByField("newGuideShowCashMoney", false) -- 重置cash money 引导状态

        isExecute = true
    end

    return isExecute
end

-- cash money 提示
function PopViewConfig:newGuideShowCashMoney()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false

    if not globalDynamicDLControl:checkDownloaded("cashBonusDy") then -- 还在下载中 直接返回
        return false
    end

    -- 首次弹出
    local bPop = false
    if gLobalDataManager:getBoolByField("newGuideShowCashMoney", false) == false then
        -- 判断当前是否判断此时是否可以玩Cash Money
        bPop = true
    else -- 后续弹出（） 	已经完成首次弹出 	距离Cash Money可以玩的时间已经达到两天（48小时）
        local cdTime = gLobalDataManager:getNumberByField("newGuideShowCashMoneyCD", 0)
        local curTime = os.time()
        if curTime - cdTime > 0 then
            bPop = true
        end
    end

    if bPop then
        local bonusType = G_GetMgr(G_REF.CashBonus):getRunningData():getCurCollectBonus()
        if bonusType == CASHBONUS_TYPE.BONUS_MONEY then -- 钞票游戏
            local data = {
                isShowGuide = true,
                id = 1
            }
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_CASHWHEEL_GUIDE_ZORDER, data)
            gLobalDataManager:setBoolByField("newGuideShowCashMoney", true)
            gLobalDataManager:setNumberByField("newGuideShowCashMoneyCD", os.time() + 24 * 2 * 60 * 60)
            gLobalDataManager:setBoolByField("newGuideShowNextCashMoney", false) -- forget 需要重置成没弹出过

            isExecute = true
        end
    end

    return isExecute
end

--自动进入集卡系统引导 lobbyview里面处理的
function PopViewConfig:newGuideAutoCard()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_POPVIEW_EVENT, "autoCard") --弹窗发送的自定义事件需要用的地方接受一下
    return true
end

---------------------------------自定义事件 每日奖励相关
function PopViewConfig:dailyRewardWheel()
    --屏蔽每日轮盘主动弹出
    if true then
        return false
    end

    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    --跳过每日轮盘
    if CC_SKIP_NOVICEGUIDE and DEBUG == 2 then
        return isExecute
    end
    local strCreate = string.sub(util_chaneTimeFormat(globalData.userRunData.createTime * 0.001), 1, 10)
    local strToday = string.sub(util_chaneTimeFormat(globalData.userRunData.p_serverTime * 0.001), 1, 10)
    if strCreate == strToday then
        return
    end
    local wheelData = G_GetMgr(G_REF.CashBonus):getWheelData()
    if wheelData.p_coolDown == 0 then
        self.m_isShowBonusWheelView = true

        local bonusWheelView = util_createView("views.cashBonus.DailyBonus.DailybonusLayer")
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(bonusWheelView, "Push", DotUrlType.UrlName, true, DotEntrySite.LoginLobbyPush, DotEntryType.Lobby)
        end
        gLobalViewManager:showUI(bonusWheelView, ViewZorder.ZORDER_UI)
        bonusWheelView:setOverFunc(
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                --弹窗逻辑执行下一个事件
            end
        )
        isExecute = true
    end
    return isExecute
end
-- 付费轮盘有卡片掉落
function PopViewConfig:dailyRewardPayWheelDrop()
    --掉卡之前的提示
    gLobalViewManager:checkAfterBuyTipList(
        function()
            if CardSysManager:needDropCards("Purchase") == true then
                CardSysManager:doDropCards(
                    "Purchase",
                    function()
                        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                        --弹窗逻辑执行下一个事件
                    end
                )
            else
                --弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        end,
        "CashBonus"
    )
    return true
end
---------------------------------自定义事件 断线重连相关
--LuckSpin
function PopViewConfig:reconnectLuckySpin()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false

    local hasLuckSpin = globalData.luckySpinV2:getRemainTimes()
    if hasLuckSpin and hasLuckSpin > 0 then
        globalData.iapLuckySpinFunc = function()
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "reconnectLuckySpin")
            --弹窗逻辑执行下一个事件
        end
        globalData.userRunData.loginUserData.hasLuckSpin = false
        local index = gLobalDataManager:getNumberByField("lastBuyLuckySpinID", 1)
        local shopDatas = globalData.shopRunData:getShopItemDatas()
        local m_index = 1
        for i,v in ipairs(shopDatas) do
            if v.p_price == globalData.luckySpinV2:getPrice() then
                m_index = i
                break
            end
        end
        local data = {}
        data.buyShopData = shopDatas[m_index]
        data.reconnect = true
        data.buyIndex = index
        data.type = globalData.luckySpinV2:getType()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, globalData.userRunData.coinNum - data.buyShopData.p_coins)

        local luckySipnView = G_GetMgr(G_REF.LuckySpin):popSpinLayer(data)
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(luckySipnView, "Push", DotUrlType.UrlName, true, DotEntrySite.LoginLobbyPush, DotEntryType.Lobby)
        end
        isExecute = true
    end
    return isExecute
end

function PopViewConfig:reconnectTopSale()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute =
        G_GetMgr(ACTIVITY_REF.Promotion_TopSale):isWillShowTopSale(
        function()
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
    )
    if isExecute then
        G_GetMgr(ACTIVITY_REF.Promotion_TopSale):showTopSaleView(true, nil)
    end
    return isExecute
end

-- LuckyStamp断线重连
function PopViewConfig:reconnectLuckyStamp() -- 盖戳
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data and data:checkReconnect() then
        isExecute = true
        G_GetMgr(G_REF.LuckyStamp):enterGame(
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        )
    end
    return isExecute
end

--LuckyStamp断线重连领卡
function PopViewConfig:reconnectLuckyStampCard()
    -- local act_data = G_GetActivityDataByRef(ACTIVITY_REF.LuckyStampCard)
    local act_data = G_GetMgr(ACTIVITY_REF.LuckyStampCard):getRunningData()
    if not act_data or not act_data:isRunning() then
        return false
    end
    if not act_data:isActive() then
        return false
    end
    local function callBack()
        -- 弹窗逻辑执行下一个事件
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end
    local view = util_createFindView("Activity/Activity_LuckyStampCard", {activityId = "LSC001", callBack = callBack})
    if not view then
        return false
    end
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    return true
end

--spinBonus断线重连
function PopViewConfig:reconnectSpinBonus()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if globalData.spinBonusData and globalData.spinBonusData:getCanCollect() then
        local spinBonusResult =
            util_createFindView(
            "Activity/Activity_SpinBonusResult",
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                --弹窗逻辑执行下一个事件
            end
        )
        if spinBonusResult ~= nil then
            isExecute = true
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():addNodeDot(spinBonusResult, "Push", DotUrlType.UrlName, true, DotEntrySite.LoginLobbyPush, DotEntryType.Lobby)
            end
            gLobalSendDataManager:getLogIap():setEnterOpen("autoOpen", "offlineRecovery")
            gLobalViewManager:showUI(spinBonusResult, ViewZorder.ZORDER_UI)
        end
    end
    return isExecute
end
--支付补单
function PopViewConfig:reconnectIapInfo()
    --与sdk交互补单
    if util_isSupportVersion("1.3.3") or device.platform == "mac" then
        ---新版的内购 请求补单信息
        gLobalIAPManager:requestFailReceiptList()
    else
        gLobalSaleManager:checkSendIapInfoData(
            function()
                --与服务器交互补单
                gLobalSaleManager:checkSendUserIapOrder(
                    function()
                        --刷新金币
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_COIN, {coins = globalData.userRunData.coinNum, isPlayEffect = false})
                        --清空订单信息
                        gLobalSaleManager:clearAllUserIapOrder()

                        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                        --弹窗逻辑执行下一个事件
                    end
                )
            end
        )
    end

    return true
end

-- --LuckyStamp断线重连增加进度
-- function PopViewConfig:reconnectLuckyStampProgress()
--     --如果没有执行事件 会自动调用下一个事件
--     local isExecute = false
--     return isExecute
-- end

--送折扣卷断线重连
function PopViewConfig:reconnectSendCoupon()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if globalData.sendCouponFlag == true then
        globalData.sendCouponFlag = false
        local view =
            util_createFindView(
            "Activity/Promotion_SendCoupon",
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                --弹窗逻辑执行下一个事件
            end
        )
        if view ~= nil then
            isExecute = true
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        end
    end
    return isExecute
end
--小猪booster断线重连
function PopViewConfig:reconnectPigBooster()
    local callback = function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        --弹窗逻辑执行下一个事件
    end

    G_GetMgr(ACTIVITY_REF.PigBooster):dealWithSaleProblemsFirst(callback)
    return true
end
--小猪booster断线重连
function PopViewConfig:reconnectCardSmallGame()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    return isExecute
end

-- 查看是否充值过 常规促销触发了小游戏 但没玩
function PopViewConfig:reconnectLuckyChooseLayer()
    local bWillPlay = false
    local saleData = nil

    local noCoinSaleData = G_GetActivityDataByRef(ACTIVITY_REF.NoCoinale) -- 没钱促销
    if noCoinSaleData then
        bWillPlay = noCoinSaleData:getMiniGameTrigger()
        if bWillPlay then
            saleData = noCoinSaleData
        end
    end

    local commSaleData = G_GetMgr(G_REF.SpecialSale):getRunningData() -- 常规促销
    if not bWillPlay and commSaleData then
        -- 没钱促销不触发 小游戏 查看 常规促销是否触发小游戏
        bWillPlay = commSaleData:getMiniGameTrigger()
        if bWillPlay then
            saleData = commSaleData
        end
    end

    if not bWillPlay or not saleData then
        return false
    end

    local miniGameUsd = saleData:getMiniGameUsd()
    -- 给manager设置小游戏最高奖励的 金币价值
    local luckyChooseManager = util_require("manager/System/LuckyChooseManager"):getInstance()
    luckyChooseManager:setMaxRewardCoinsPrice(miniGameUsd)
    luckyChooseManager:popLuckyChooseLayer(
        function()
            -- 界面关闭的时候已经执行了改事件了
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            --弹窗逻辑执行下一个事件
        end
    )

    return true
end

-- 检查 是否要弹出 PurchaseDraw 活动面板
function PopViewConfig:reconnectPurchaseDrawActMainLayer()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) and not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        return false
    end

    local manage = util_require("manager.Activity.ActivtiyPurchaseDrawManager"):getInstance()
    if not manage:checkIsActive() then
        return false
    end

    local callback = function()
        -- 界面关闭的时候已经执行了改事件了
        -- gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)--弹窗逻辑执行下一个事件
    end
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        manage:addAutoPopMainLayerRefCount()
        manage:checkPopMainLayer(callback)
        manage:resetAutoPopMainLayerRefCount()
        return true
    end

    manage:checkPopMainLayer(callback)

    return true
end

function PopViewConfig:reconnectStarPickMainLayer()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end
    if not G_GetMgr(G_REF.GiftPickBonus):isHasPlaying() then
        return false
    end

    local _view = G_GetMgr(G_REF.GiftPickBonus):showMainLayer()
    if _view then
        return true
    end

    return false
end

--PokerRecall断线重连
function PopViewConfig:reconnectPokerRecallMainLayer()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end
    if not G_GetMgr(G_REF.PokerRecall):isHasPlaying() then
        return false
    end
    local status = G_GetMgr(G_REF.PokerRecall):getPokerRecallStatus()
    if not status then
        G_GetMgr(G_REF.PokerRecall):setGuideStatus(true)
    end
    local _view = G_GetMgr(G_REF.PokerRecall):showMainLayer()
    if _view then
        return true
    end
    return false
end

function PopViewConfig:reconnectMiniGameTreasureSeeker()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end
    local data = G_GetMgr(G_REF.TreasureSeeker):getData()
    if not data then
        return false
    end
    -- 一个个的弹出
    local GameDatas = data:getPlayingGameData()
    if GameDatas and #GameDatas > 0 then
        local gameId = GameDatas[1]:getId()
        local _view =
            G_GetMgr(G_REF.TreasureSeeker):enterGame(
            gameId,
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        )
        if _view then
            return true
        end
    end
    return false
end

--小猪转盘断线重连
function PopViewConfig:reconnectGoodWheelPiggyMainLayer()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    local data = G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):getRunningData()
    if data and data:checkIsReconnectPop() then
        isExecute = true
        local callback = function()
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            --弹窗逻辑执行下一个事件
        end
        G_GetMgr(ACTIVITY_REF.GoodWheelPiggy):showMainLayer(callback)
    end
    return isExecute
end

-- 每日任务送优惠券（砸锤子）
function PopViewConfig:reconnecCouponChallenge()
    -- 如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    local data = G_GetMgr(ACTIVITY_REF.CouponChallenge):getRunningData()
    if data and data:isPopupsNum() then
        isExecute = true
        local view = G_GetMgr(ACTIVITY_REF.CouponChallenge):showMainLayer()
        if view then
            view:setOverFunc(
                function()
                    --弹窗逻辑执行下一个事件
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
            )
        end
    end
    return isExecute
end

-- CashMoney断线重连
function PopViewConfig:reconnectMiniGameCashMoney()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end
    -- local data = G_GetMgr(G_REF.TreasureSeeker):getData()
    -- if not data then
    --     return false
    -- end
    local dataType = G_GetMgr(G_REF.CashMoney):getDataType()
    local gameType = G_GetMgr(G_REF.CashMoney):getGameType()
    --当前来源为PUT的小游戏数据（正在玩）
    local gameData = G_GetMgr(G_REF.CashMoney):getPlayStatusGameData(dataType.PUT)
    if gameData then
        local isReward = gameData:getRewardStatus() -- 是否完成普通版
        local isMark = gameData:getMarkStatus() -- 是否带付费项
        local isPay = gameData:getPayStatus() -- 是否购买过付费版次数
        local type = gameType.NORMAL
        if isMark then
            if isReward or isPay then
                type = gameType.PAID
            end
        end
        local viewData = {
            gameData = gameData,
            isReconnc = true
        }

        G_GetMgr(G_REF.CashMoney):showCashMoneyGameView(viewData, type)
        return true
    else
        return false
    end
end

-- luckfish
function PopViewConfig:reconnectMiniGamePlinko()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end
    local data = G_GetMgr(G_REF.Plinko):getData()
    if data then
        local gameId = data:checkReconnectGame()
        if gameId and tonumber(gameId) > 0 then
            local function callBack()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
            G_GetMgr(G_REF.Plinko):enterGame(gameId, false, false, callBack)
            return true
        end
    end
    return false
end

--leveldashLink
function PopViewConfig:reconnectMiniGamePerLink()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end
    local data = G_GetMgr(G_REF.LeveDashLinko):getIsLoginGames()
    if data then
        G_GetMgr(G_REF.LeveDashLinko):enterGame(data)
        return true
    end
    return false
end

function PopViewConfig:reconnectMinz()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end
    local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    if minzMgr and minzMgr:getRunningData() then
        local data = minzMgr:getRunningData()
        local activeAlbum = data:getAlbumDataByActive()
        if activeAlbum then
            local level_list = G_GetMgr(ACTIVITY_REF.Minz):getSlotLevelIdList()
            local _levelId = level_list[activeAlbum.themeId]
            if _levelId then
                gLobalViewManager:lobbyGotoGameScene(_levelId)
                return true
            end
        end
    end
    return false
end

function PopViewConfig:reconnectDiyFeature()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end
    local diyFeatureMgr = G_GetMgr(ACTIVITY_REF.DiyFeature)
    if diyFeatureMgr and diyFeatureMgr:getRunningData() then
        local data = diyFeatureMgr:getRunningData()
        local isInGame = data:isInGame()
        local levelId = data:getInGameLevelId()
        if isInGame then
            gLobalViewManager:lobbyGotoGameScene(levelId)
            return true
        elseif  data:getIsActivateGame() then
            if G_GetMgr(ACTIVITY_REF.DiyFeature):showMainLayer() then
                return true 
            end
        end
    end
    local diyFeatureSaleMgr = G_GetMgr(ACTIVITY_REF.DiyFeatureOverSale)
    if diyFeatureSaleMgr and diyFeatureSaleMgr:isReconnectDiyFeature() then
        return true
    end
    return false
end

---------------------------------自定义事件 推送奖励相关相关
--版本热更奖励
function PopViewConfig:notifyRewardNewApp()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local rewardID = "newVersion"
        isExecute = gLobalSysRewardManager:isOpenReward(rewardID)
        -- isExecute = true
        if isExecute then
            local successCallFun = function(network, resData)
                gLobalViewManager:removeLoadingAnima()
                local _result = resData.result or ""
                local jsonResult = util_cjsonDecode(_result)
                if (jsonResult.addCoins or 0) > 0 then
                    local uiView = gLobalSysRewardManager:showView(rewardID, jsonResult)
                    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
                    uiView:setOverFunc(
                        function()
                            --弹窗逻辑执行下一个事件
                            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "notifyRewardNewApp")
                        end
                    )
                else
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "notifyRewardNewApp")
                end
            end

            local failedCallFun = function()
                gLobalViewManager:removeLoadingAnima()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "notifyRewardNewApp")
            end
            --添加loading
            gLobalViewManager:addLoadingAnima(true)
            -- 发送消息
            gLobalSendDataManager:getNetWorkFeature():sendSystemReward(rewardID, nil, successCallFun, failedCallFun)
        end
    end
    return isExecute
end

--新手金币不足奖励
function PopViewConfig:notifyNewUserReward()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        isExecute = gLobalSysRewardManager:isOpenReward("NewUserProtectReward")
        if isExecute then
            local uiView = gLobalSysRewardManager:showView("NewUserProtectReward")
            gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
            uiView:setOverFunc(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "notifyNewUserReward")
                    --弹窗逻辑执行下一个事件
                end
            )
        end
    end
    return isExecute
end

--领取流失回归奖励
function PopViewConfig:notifyChurnReturnReward()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        isExecute = globalData.userRunData:getIsChurnReturn()
        if isExecute then
            local userChurnReturnInfo = globalData.userRunData:getUserChurnReturnInfo()
            local type = 0
            if userChurnReturnInfo and userChurnReturnInfo.p_returnUser then
                type = 2 -- 回归
            end

            if userChurnReturnInfo and userChurnReturnInfo.p_churnUser then
                type = 3 -- 流失
            end

            if type == 3 then
                local successCB = function(target, resData)
                    release_print("cxc-----领取流失回归奖励 ")
                    if resData:HasField("result") then
                        local result = cjson.decode(resData.result) or {}
                        if result.totalCoins and result.totalCoins > 0 then
                            local cb = function()
                                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                                --弹窗逻辑执行下一个事件
                            end
                            local notifyRewardUI = util_createView("views.NotifyReward.NotifyRewardUI", result, cb, type)
                            gLobalViewManager:showUI(notifyRewardUI)
                            return
                        end
                    end

                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                    --弹窗逻辑执行下一个事件
                end

                local failedCB = function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                    --弹窗逻辑执行下一个事件
                end
                gLobalSendDataManager:getNetWorkLogon():sendChurnReturnReq(successCB, failedCB)
            else
                if userChurnReturnInfo:isRunning() and userChurnReturnInfo:isPopView() then
                    local ReturnSignInManager = util_require("manager.System.ReturnSignInManager")
                    local mainLayer = nil
                    if ReturnSignInManager then
                        if not ReturnSignInManager:isOpenLetter() then
                            mainLayer = ReturnSignInManager:getInstance():openMainLayer("Letter")
                        else
                            mainLayer = ReturnSignInManager:getInstance():openMainLayer("MainUI")
                        end
                    end
                    if not mainLayer then
                        isExecute = false
                    end
                else
                    isExecute = false
                end
            end
        end
    end

    return isExecute
end

-- V2
function PopViewConfig:notifyReturnV2SignReward()
    --如果没有执行事件 会自动调用下一个事件
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) and globalData.userRunData:isReturnUser() then            
        local returnV2Data = G_GetMgr(G_REF.Return):getRunningData()
        if not returnV2Data then
            return false
        end
        if returnV2Data:isSignTodayCollected() then
            return false
        end
        local function callFunc()
            --弹窗逻辑执行下一个事件
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
        local dayIndex = returnV2Data:getSignToday()
        local view = G_GetMgr(G_REF.Return):showMainLayer(1, 1, {autoSign = {dayIndex}}, callFunc)
        if view then
            return true
        end
    end
    return false
end

--fb绑定奖励
function PopViewConfig:notifyRewardBindFB()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local FBSignRewardManager = util_require("manager.System.FBSignRewardManager")
        if FBSignRewardManager then
            isExecute = FBSignRewardManager:getInstance():isOpenReward()
            if isExecute then
                FBSignRewardManager:getInstance():openFBReward()
            end
        end
    end
    return isExecute
end

-- 注册里程碑
function PopViewConfig:mileStoneCouponRegister()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local _mgr = G_GetMgr(G_REF.MSCRegister)
        if _mgr then
            if _mgr:isOpenView() and _mgr:openPopView() then
                isExecute = true
            end
        end
    end
    return isExecute
end

--广告召回
function PopViewConfig:notifyRewardAds()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        isExecute = true
        local loginData = globalData.userRunData.loginUserData
        if loginData ~= nil and loginData:HasField("userBack") and loginData.userBack:HasField("coins") and loginData.userBack:HasField("coinsUsd") then
            local adverCallBackUI =
                util_createView(
                "views.AdverCallBack.AdverCallBackUI",
                function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                    --弹窗逻辑执行下一个事件
                end
            )
            gLobalViewManager:showUI(adverCallBackUI)
        else
            --弹窗逻辑执行下一个事件
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
    end
    return isExecute
end
--签到等 强制优化级最高
function PopViewConfig:notifyFirstPriority()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local sevenDaySignData = G_GetActivityDataByRef(ACTIVITY_REF.SevenDaySign)
        if sevenDaySignData and sevenDaySignData:isRunning() and not sevenDaySignData:checkIsCollectToday() then
            local theme = "Activity_7DaySign"
            if sevenDaySignData.getTheme and sevenDaySignData:getTheme() and sevenDaySignData:getTheme() ~= "" then
                theme = sevenDaySignData:getTheme()
            end
            if not globalDynamicDLControl:checkDownloading(theme) then
                local viewPath = "Activity." .. theme
                local sevenDaySignView = util_createView(viewPath)
                if sevenDaySignView then
                    isExecute = true
                    gLobalViewManager:showUI(sevenDaySignView)
                end
            end
        end
    end
    return isExecute
end

-- 生日礼物
function PopViewConfig:notifyBirthdayGift()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local data = G_GetMgr(ACTIVITY_REF.Birthday):getRunningData()
        if data then
            local isCanPopBirthdayLayer = data:isCanPopBirthdayLayer() -- 是否是生日当天
            if isCanPopBirthdayLayer then
                local _view = G_GetMgr(ACTIVITY_REF.Birthday):showBirthdayCandieLayer()
                if _view then
                    isExecute = true
                end
            end
        end
    end
    return isExecute
end

--月卡
function PopViewConfig:notifyMonthlyCard()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local data = G_GetMgr(G_REF.MonthlyCard):getRunningData()
        if not data then
            return isExecute
        end
        local isCd = G_GetMgr(G_REF.MonthlyCard):isCoolDown()
        local cdTime = gLobalDataManager:getNumberByField("monthlyCardPopCD", 0)
        local isbuyN = data:isBuyMonthlyCardNormal()
        local isbuyD = data:isBuyMonthlyCardDeluxe()
        if cdTime ~= 0 and not isbuyN and not isbuyD then
            return isExecute
        end
        if not isCd then --月卡弹出cd未冷却
            if data then
                local isHasReward = data:isHasReward()
                if isHasReward then
                    local _view = G_GetMgr(G_REF.MonthlyCard):showMainLayer()
                    if _view then
                        isExecute = true
                    end
                end
            end
        else
            local _view = G_GetMgr(G_REF.MonthlyCard):showMainLayer()
            if _view then
                G_GetMgr(G_REF.MonthlyCard):setCoolDownTime()
                isExecute = true
            end
        end
    end
    return isExecute
end

-- 生日编辑
function PopViewConfig:notifyBirthdayEdit()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local view = G_GetMgr(ACTIVITY_REF.BirthdayPublicity):showMainLayer()
        if view then
            isExecute = true
        end
    end
    return isExecute
end

--每日签到
function PopViewConfig:notifyDailyBonus()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local mgr = G_GetMgr(G_REF.NoviceSevenSign)
        if mgr and mgr:checkCanCollect() then
            local view = mgr:showMainLayer()
            isExecute = view ~= nil
        elseif globalData.dailyBonusNoviceData and globalData.dailyBonusNoviceData:checkHasData() then
            local dailyBonusNoviceMgr = require("manager.DailyBonusNoviceMgr")
            if dailyBonusNoviceMgr then
                local _view = dailyBonusNoviceMgr:getInstance():showMainLayer()
                if _view then
                    isExecute = true
                end
            end
        elseif globalData.dailySignData and globalData.dailySignData:checkHasData() then
            local dailyBonusMgr = require("manager.DailySignBonusManager")
            if dailyBonusMgr then
                local _view = dailyBonusMgr:getInstance():showMainLayer()
                if _view then
                    isExecute = true
                end
            end
        end
    end
    return isExecute
end

-- 新一期quest开启
function PopViewConfig:notifyQuestOpen()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local mgr = G_GetMgr(ACTIVITY_REF.Quest)
        if mgr:isNewUserQuest() then
            return isExecute
        end
        if not mgr:isDownloadRes() then
            return isExecute
        end
        local act_data = mgr:getRunningData()
        if not act_data or not act_data:isRunning() then
            return isExecute
        end
        local expireAt = act_data:getExpireAt()
        local bl_poped = gLobalDataManager:getBoolByField("Activity_Quest_" .. expireAt, false)
        if bl_poped then
            return isExecute
        end
        local bl_success = G_GetMgr(ACTIVITY_REF.Quest):showMainLayer()
        if bl_success then
            gLobalDataManager:setBoolByField("Activity_Quest_" .. expireAt, true)
            isExecute = true
        end
    end
    return isExecute
end

-- 单人限时比赛  开启界面
function PopViewConfig:notifyLuckyRaceOpen()
    local isExecute = false
    local data = G_GetMgr(ACTIVITY_REF.LuckyRace):getRunningData()
    if not data then
        return isExecute
    end

    local bCurRoundCanPlay = data:checkCurRoundCanPlay()
    if not bCurRoundCanPlay then
        -- 未激活 本轮比赛 判断是否可激活
        local curTime = util_getCurrnetTime()
        local startConfirmTime = data:getStartResponseTime()
        local endConfirmTime = data:getRoomStartTime()
        if not (curTime >= startConfirmTime and curTime <= (endConfirmTime - 10)) then
            -- 不可激活 return
            return isExecute
        end
    end

    local openView = G_GetMgr(ACTIVITY_REF.LuckyRace):showOpenLayer()
    if openView then
        isExecute = true
    end
    return isExecute
end

-- 单人限时比赛  主界面领奖
function PopViewConfig:notifyLuckyRace()
    local isExecute = false
    local mainView = G_GetMgr(ACTIVITY_REF.LuckyRace):checkOnShowMainLayer()
    if mainView then
        isExecute = true
    end
    return isExecute
end

-- vipPointsBoost
function PopViewConfig:vipPointsBoost()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local gameData = G_GetMgr(ACTIVITY_REF.VipPointsBoost):getRunningData()
        if gameData then
            local isFirstShow = gameData:isFirst()
            if isFirstShow then
                G_GetMgr(ACTIVITY_REF.VipPointsBoost):showBoxLayer()
                isExecute = true
            end
        end
    end
    return isExecute
end

-- DuckShot
function PopViewConfig:miniGameDuckShot()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local mgr = G_GetMgr(ACTIVITY_REF.DuckShot)
        local gameData = mgr:getPlayStatusDuckShotGameData()
        if gameData then
            local showFlag = mgr:showDuckShotGameView(gameData)
            if showFlag then
                mgr:setReconnectStatus(true)
                isExecute = true
            end
        end
    end
    return isExecute
end

-- 领取关卡比赛结算奖励
function PopViewConfig:collectLeagueReward()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        isExecute = G_GetMgr(G_REF.LeagueCtrl):checkPopSeasonFinalLayer()
    end
    return isExecute
end

-- 断线重连弹选号面板
function PopViewConfig:checkLotteryChooseNumberLayer()
    local isExecute = false

    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        G_GetMgr(G_REF.Lottery):onDropLotteryTickets(
            function()
                --弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end,
            true
        )
        isExecute = true
    end

    return isExecute
end
-- 领取乐透彩票结算奖励
function PopViewConfig:collectLotteryReward()
    local isExecute = false

    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        isExecute = G_GetMgr(G_REF.Lottery):triggerOpenRewardLayer()
    end

    return isExecute
end
-- 乐透来源弹板（18级开签到跟活动，但是大于19级才检测登录弹板，需要特殊处理）
function PopViewConfig:checkLotteryOpenSourceLayer()
    local isExecute = false

    if globalData.constantData.LOTTERY_OPEN_LEVEL <= globalData.userRunData.levelNum and globalData.userRunData.levelNum <= globalData.constantData.NEW_USER_GUIDE_LEVEL then
        if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
            local controlData = PopUpManager:getPopupControlDataByRef(ACTIVITY_REF.LotteryOpenSource)
            if not controlData then
                return isExecute
            end

            if controlData.p_loginShow then
                isExecute = G_GetMgr(ACTIVITY_REF.LotteryOpenSource):popLotteryOpenSourceLayer()
            end
        end
    end

    return isExecute
end

-- 领取乐透额外奖励
function PopViewConfig:collectLotteryExtraReward()
    local isExecute = false

    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        isExecute = G_GetMgr(G_REF.Lottery):triggerDropExtraReward()
    end

    return isExecute
end

-- 合成周卡有奖励主动弹出
function PopViewConfig:notifyMergeWeekReward()
    local isExecute = false

    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local mgr = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeWeek)
        local mergeWeekData = mgr:getRunningData()
        if not mergeWeekData then
            return false
        end

        local bCanCollect = mergeWeekData:checkCanCollect()
        if not bCanCollect then
            return false
        end

        local view =
            mgr:showPopLayer(
            nil,
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        )
        isExecute = view ~= nil
    end

    return isExecute
end

-- 新手7日目标五级后从关卡返回大厅只弹出一次
function PopViewConfig:notifyNewUser7Day()
    local isExecute = false

    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        -- 满足等级大于等于5级
        local newUser7DayData = G_GetMgr(G_REF.NewUser7Day):getData()
        if newUser7DayData and newUser7DayData:checkFuncOpen() then
            local mgr = G_GetMgr(G_REF.NewUser7Day)
            local isfirstEnter = mgr:getFirstEnter()
            local currentGameData = mgr:getCurrentGameData()

            if not currentGameData then
                return isExecute
            end

            if isfirstEnter == "NoFirst" then
                -- 判断是不是已经完成了任务是的话弹出界面，不是的话就return
                local taskStatus = currentGameData:getTaskStatus()
                local time = currentGameData:getStartTimeAt()
                local currentTime = util_getCurrnetTime()
                local result = (time / 1000) - currentTime
                if taskStatus == 2 then
                    local view = mgr:showMainLayer()
                    if view then
                        view:setOverFunc(
                            function()
                                --弹窗逻辑执行下一个事件
                                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                            end
                        )
                        isExecute = true
                    end
                    return isExecute
                end
                return isExecute
            end

            local view = mgr:showMainLayer()
            if view then
                view:setOverFunc(
                    function()
                        --弹窗逻辑执行下一个事件
                        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                    end
                )
                isExecute = true
            end
        end
    end
    return isExecute
end

-- fb用户分享后获得优惠券
function PopViewConfig:checkFBShareCoupon()
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        if G_GetMgr(G_REF.FBShareCoupon):checkFBShareCoupon() then
            local view = G_GetMgr(G_REF.FBShareCoupon):showMainLayer()
            if view then
                return true
            end
        end
    end
    return false
end

-- 比赛聚合结算 奖励主动弹出
function PopViewConfig:notifyBattleMatchReward()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local mgr = G_GetMgr(ACTIVITY_REF.BattleMatch_Rule)
        if mgr then
            isExecute = mgr:checkShowResultLayer(nil)
        end
    end

    return isExecute
end

-- -- 弹出WILD CHALLENGE付费挑战 弹板
-- function PopViewConfig:notifyWildChallenge()
--     local isExecute = false
--     if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
--         if not G_GetMgr(ACTIVITY_REF.WildChallenge):checkUncollectedTask() then
--             return false
--         end
--         local view = G_GetMgr(ACTIVITY_REF.WildChallenge):showMainLayer()
--         if view then
--             view:setOverFunc(
--                 function()
--                     --弹窗逻辑执行下一个事件
--                     gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
--                 end
--             )
--             isExecute = true
--         end
--     end
--     return isExecute
-- end

-- 拉新 弹板
function PopViewConfig:notifyInviteReward()
    local isExecute = false

    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local view = G_GetMgr(G_REF.Invite):showUrgeLayer()
        if view then
            view:setOverFunc(
                function()
                    --弹窗逻辑执行下一个事件
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
            )
            isExecute = true
        end
    end

    return isExecute
end

--粉丝页奖励
function PopViewConfig:notifyRewardFb()
    gLobalNoticManager:postNotification(
        ViewEventType.NOTIFY_CHECK_FBLINK_REWARD,
        function()
            --弹窗逻辑执行下一个事件
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        end
    )
    return true
end

--firebase推送奖励
function PopViewConfig:notifyRewardFireBase()
    globalLocalPushManager:readNotifyRewardData(
        function()
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            --弹窗逻辑执行下一个事件
        end
    )
    return true
end

--firebase推送奖励
function PopViewConfig:sendRequestAcitvityRank()
    if G_GetMgr(ACTIVITY_REF.Bingo):isRunning() then
        G_GetMgr(ACTIVITY_REF.Bingo):sendActionBingoRank(false)
    end

    return false
end

--保存下用户头像
function PopViewConfig:saveUserHead()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end

    if not globalData.userRunData.bLoginSaveHead then
        return false
    end

    gLobalSendDataManager:getNetWorkFeature():sendNameEmailHead("", "", {headName = globalData.userRunData.HeadName})
    return false --不用中断 发条消息就行
end

-- 领取关卡比赛结算奖励
function PopViewConfig:holidayChallengeSalePop()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        isExecute = G_GetMgr(ACTIVITY_REF.ChallengePassLastSale):isCanShowRewardLayer()
        if isExecute then
            isExecute = G_GetMgr(ACTIVITY_REF.ChallengePassLastSale):createRewardLayer()
        end
    end
    return isExecute
end

function PopViewConfig:prizeGame()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        isExecute = G_GetMgr(ACTIVITY_REF.PrizeGame):checkReconnect()
    end
    return isExecute
end

---------------------------------自定义事件 后台弹窗配置相关
function PopViewConfig:configPushView()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        gLobalPushViewControl:showView(PushViewPosType.LoginToLobby)
    elseif gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        gLobalPushViewControl:showView(PushViewPosType.LevelToLobby)
    end

    if gLobalPushViewControl:isPushingView() then
        isExecute = true
        gLobalPushViewControl:setEndCallBack(
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                --弹窗逻辑执行下一个事件
            end
        )
    end
    return isExecute
end
--前端额外弹窗配置
function PopViewConfig:tipOtherView()
    local isExecute = false
    local drawData = G_GetMgr(ACTIVITY_REF.LuckyChipsDraw):getRunningData()
    if drawData == nil or drawData:isRunning() == false then
        return isExecute
    end
    drawData.m_isPopView = true
    return isExecute
end
--邮箱额外奖励提示
function PopViewConfig:inboxRewardTips()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GUIDE_INBOX_REWARDTIPS)
    return true
end
--视频广告
-- 如果是激励视频，一定要在界面弹出后再进行打点
-- 插屏广告可以直接打点
function PopViewConfig:configPushAds()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    local vType = nil
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        vType = PushViewPosType.LoginToLobby
    elseif gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        vType = PushViewPosType.LevelToLobby
    end
    -- 广告弹版
    isExecute = globalData.adsRunData:isPlayRewardForPos(vType, nil, true)
    if isExecute then
        -- 广告弹版
        gLobalSendDataManager:getLogAdvertisement():setOpenSite(vType)
        gLobalSendDataManager:getLogAdvertisement():setOpenType("PushOpen")
        gLobalAdsControl:playVideo(AdsRewardDialogType.Normal, vType)
        gLobalSendDataManager:getLogAds():createPaySessionId()
        gLobalSendDataManager:getLogAds():setOpenSite(vType)
        gLobalSendDataManager:getLogAds():setOpenType("PushOpen")
    -- globalFireBaseManager:checkSendFireBaseLog({taskOpenSite = vType})
    end
    return isExecute
end

--高倍场解锁
function PopViewConfig:configPushDeluexeUnlock()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local isDeluexeOpened = globalData.deluexeClubData:getDeluexeClubStatus()
        if globalData.deluexeStatus == false and isDeluexeOpened == true then
            local view =
                globalDeluxeManager:pushDeluexeClubViews(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
            )
            isExecute = view ~= nil
        else
            isExecute = false
        end
    end

    return isExecute
end

-- 高倍场点数换金币监测
function PopViewConfig:configDeluxePointToCoins()
    local isExecute = false
    -- if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) and not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
    --     return false
    -- end

    local clubCrownNum = globalData.deluexeClubData:getDeluexeClubCrownNum()
    local changeCoins = globalData.deluexeClubData:getChangeCoinNum()
    if clubCrownNum == 1 and changeCoins > 0 then
        local view =
            globalDeluxeManager:popupDeluexeClubChangeCoinView(
            function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        )

        isExecute = view ~= nil
    end

    return isExecute
end

--周任务刷新
function PopViewConfig:configPushWeekMission()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    return isExecute
end

-----------------------------------------显示fb粉丝页 START---------
function PopViewConfig:configPushFb()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        --  facebook粉丝页  功能开放时需要打开
        if self:checkFBFansViewShow() then
            local function showFBFansView(callback)
                if globalFireBaseManager.sendFireBaseLogDirect then
                    globalFireBaseManager:sendFireBaseLogDirect("FBFansView" .. "_Popup", false)
                end

                local inboxLayer = util_createView("views.fbFans.FBFansViewNew", callback)
                if gLobalSendDataManager.getLogPopub then
                    gLobalSendDataManager:getLogPopub():addNodeDot(inboxLayer, "Push", DotUrlType.UrlName, true, DotEntrySite.LoginLobbyPush, DotEntryType.Lobby)
                end
                gLobalViewManager:showUI(inboxLayer, ViewZorder.ZORDER_UI)
            end
            isExecute = true
            showFBFansView(
                function()
                    if globalData.constantData.FBSHOW_TIMES and globalData.constantData.FBSHOW_TIMES == 2 then
                        showFBFansView(
                            function()
                                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                                --弹窗逻辑执行下一个事件
                            end
                        )
                    else
                        --弹窗逻辑执行下一个事件
                        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                    end
                end
            )
        end
    end
    return isExecute
end

-- function PopViewConfig:configPushActWanted()
--     --如果没有执行事件 会自动调用下一个事件
--     local isExecute = false
--     if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
--         isExecute = G_GetMgr(ACTIVITY_REF.Wanted):isTaskComplete()
--         -- 返回大厅 弹出集满弹窗
--         if isExecute then
--             local saved_key = G_GetMgr(ACTIVITY_REF.Wanted):getSavedKey()
--             local bl_poped = gLobalDataManager:getBoolByField(saved_key, false)
--             if bl_poped then
--                 gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
--                 return
--             end
--             local bl_success = G_GetMgr(ACTIVITY_REF.Wanted):showCompleteLayer()
--             if not bl_success then
--                 gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
--                 return
--             end
--             gLobalDataManager:setBoolByField(saved_key, true)
--         end
--     end
--     return isExecute
-- end

--是否可以显示facebook粉丝页
function PopViewConfig:checkFBFansViewShow()
    if globalData.constantData.FBFANS_OPEN_DAY and globalData.constantData.FBSHOW_LEVEL and globalData.userRunData.levelNum >= globalData.constantData.FBSHOW_LEVEL then
        local splist = util_split(globalData.constantData.FBFANS_OPEN_DAY, ";")
        if splist and #splist == 2 then
            local nowTb = {}
            local curTime = os.time()
            if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
                curTime = globalData.userRunData.p_serverTime / 1000
            end
            nowTb.year = tonumber(os.date("%Y", curTime))
            nowTb.month = tonumber(os.date("%m", curTime))
            nowTb.day = tonumber(os.date("%d", curTime))
            for i = 1, #splist do
                local temp = splist[i]
                local year = tonumber(string.sub(temp, 1, 4))
                local month = tonumber(string.sub(temp, 5, 6))
                local day = tonumber(string.sub(temp, 7, 8))
                splist[i] = {year = year, month = month, day = day}
            end
            if self:compareDate(nowTb, splist[1]) and not self:compareDate(nowTb, splist[2]) then
                local key = "FBFANS_SHOW_TIMES" .. nowTb.year .. nowTb.month .. nowTb.day
                local curShowTime = gLobalDataManager:getNumberByField(key, 0)
                if globalData.constantData.FBFANS_SHOW_TIMES and curShowTime < globalData.constantData.FBFANS_SHOW_TIMES then
                    curShowTime = curShowTime + 1
                    gLobalDataManager:setNumberByField(key, curShowTime)
                    return true
                end
            end
        end
    end
    return false
end
function PopViewConfig:compareDate(date1, date2)
    local bigThanAfter = true
    if date1.year > date2.year then
        bigThanAfter = true
    elseif date1.year == date2.year then
        if date1.month > date2.month then
            bigThanAfter = true
        elseif date1.month == date2.month then
            if date1.day >= date2.day then
                bigThanAfter = true
            else
                bigThanAfter = false
            end
        else
            bigThanAfter = false
        end
    else
        bigThanAfter = false
    end
    return bigThanAfter
end

-- 公会上次结算
function PopViewConfig:sendClanLastWeekReward()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) and not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        return false
    end

    local currLevel = globalData.userRunData.levelNum
    if currLevel < globalData.constantData.CLAN_OPEN_LEVEL then
        return false
    end

    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    if not ClanManager:checkSupportAppVersion() or not ClanManager:isDownLoadRes() then
        return false
    end

    local ClanConfig = util_require("data.clanData.ClanConfig")
    gLobalNoticManager:addObserver(
        self,
        function()
            gLobalNoticManager:removeObserver(self, ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA)
            gLobalNoticManager:removeObserver(self, ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA_FAILD)

            local bPopPointsReward = ClanManager:checkShowTaskReward()
            if bPopPointsReward and gLobalViewManager:isLobbyView() then
                local callback = function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
                
                ClanManager:requestTaskReward(callback)
            else
                --弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end
        end,
        ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA
    )

    gLobalNoticManager:addObserver(
        self,
        function()
            gLobalNoticManager:removeObserver(self, ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA)
            gLobalNoticManager:removeObserver(self, ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA_FAILD)

            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            --弹窗逻辑执行下一个事件
        end,
        ClanConfig.EVENT_NAME.RECIEVE_CLAN_INFO_DATA_FAILD
    )

    -- 获取公会信息
    ClanManager:sendClanInfo()
    return true
end

--公会结算排行榜 段位上升下降
function PopViewConfig:notifyClanRankUpDown()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) and not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        return false
    end

    local currLevel = globalData.userRunData.levelNum
    if currLevel < globalData.constantData.CLAN_OPEN_LEVEL then
        return false
    end

    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    if not ClanManager:checkSupportAppVersion() or not ClanManager:isDownLoadRes() then
        return false
    end

    local cb = function()
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    end
    local view = ClanManager:checkPopRankUpDownLayer(cb)
    if view then
        return true
    end
    return false
end

-- 通过公会 fb 邀请链接进来游戏
function PopViewConfig:notifyClanFbInvite()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end

    local currLevel = globalData.userRunData.levelNum
    if currLevel < globalData.constantData.CLAN_OPEN_LEVEL then
        return false
    end

    local callback = function(_bInterrupt)
        if not _bInterrupt then
            gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
        --弹窗逻辑执行下一个事件
        end
    end

    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    if not ClanManager:checkSupportAppVersion() and not ClanManager:isDownLoadRes() then
        return false
    end

    -- 解析是否是点击facebook 公会邀请链接进来的
    globalPlatformManager:parseFacebookShareClanId(callback)
    return true
end

-----------------------------------------显示fb粉丝页 END---------
---------------------------------自定义事件 奖励提示配置相关
--新版本提示
function PopViewConfig:tipNewVersion()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    --只有登录会弹
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        if globalData.isUpgradeTips then
            isExecute = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_NEWVERSION_SHOW)
        end
    end
    return isExecute
end

-- 装修引导
function PopViewConfig:redecorGuide()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false

    local redecorData = G_GetMgr(ACTIVITY_REF.Redecor):getRunningData()
    if redecorData then
        if G_GetMgr(ACTIVITY_REF.Redecor):isCanShowLayer() then
            if redecorData:isClean() and G_GetMgr(ACTIVITY_REF.Redecor):getCacheStepId() == 0 then
                local RedecorGuideControl = util_getRequireFile("Activity/RedecorCode/GuideUI/RedecorGuideControl")
                if RedecorGuideControl then
                    -- 新手引导 1 开始
                    RedecorGuideControl:getInstance():startGuide(1)
                    isExecute = true
                end
            end
        end
    end
    return isExecute
end

-- 扑克引导
function PopViewConfig:pokerGuide()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    -- local runData = G_GetMgr(ACTIVITY_REF.Poker):getRunningData()
    -- if runData then
    --     if G_GetMgr(ACTIVITY_REF.Poker):isCanShowLayer() then
    --         local stepId = G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():getUserDefaultStepId()
    --         if stepId == 0 and runData:isLoginTriggerGuide() then
    --             -- poker新手引导 lobby 开始
    --             if G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():checkStartGuide("lobby") then
    --                 G_GetMgr(ACTIVITY_REF.Poker):getGuideMgr():startGuide("lobby")
    --                 isExecute = true
    --             end
    --         end
    --     end
    -- end
    return isExecute
end

-- 看广告任务完成
function PopViewConfig:adsReward()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalAdChallengeManager:isShowMainLayer() then
        isExecute = true
        gLobalAdChallengeManager:showMainLayer()
    end
    return isExecute
end

-- 弹出广告任务
function PopViewConfig:showAdChallenge()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    local isCD = globalData.popCdData:isCoolDown("AdsChallengeMainLayer")
    if isCD then
        isExecute = true
        gLobalAdChallengeManager:showMainLayer()
        globalData.popCdData:addPopCd("AdsChallengeMainLayer", 14400)
    end
    return isExecute
end

--新版餐厅引导
function PopViewConfig:diningRoomGuide()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    local gameData = G_GetActivityDataByRef(ACTIVITY_REF.DiningRoom)
    if gameData and gameData:isRunning() then
        local serverStage = gameData:getGuideStage()
        if not serverStage["1"] and not serverStage["2"] and not serverStage["4"] then
            isExecute = true
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DINING_ROOM_GUIDE, {stage = 1})
        end
    end
    return isExecute
end

--可重复引导提示放到最后
function PopViewConfig:tipOverShowQueue()
    -- local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    -- if questConfig ~= nil and questConfig.m_isQuestLobby then
    --     --进入quest大厅不弹提示
    --     return false
    -- end
    -- if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) and globalData.missionRunData:isPopTip() == true then
    --     globalNoviceGuideManager:addRepetitionQueue(NOVICEGUIDE_ORDER.missionComleted)
    -- end
    -- if globalNoviceGuideManager:isNoobUsera() then --新用户
    --     globalNoviceGuideManager:checkNextShow(NOVICEGUIDE_ORDER.shopReward)
    --     local isCurrentFisnis = globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.shopReward.id)
    --     if isCurrentFisnis  then
    --         globalNoviceGuideManager:setShowState(false)
    --         globalNoviceGuideManager:attemptShowRepetition()
    --     end
    -- else
    --     globalNoviceGuideManager:setShowState(false)
    --     globalNoviceGuideManager:attemptShowRepetition()
    -- end
    return false
end
--点击链接首次进入
function PopViewConfig:popInviteFirst()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local invite_data = G_GetMgr(G_REF.Invite):getData()
        if invite_data then
            if invite_data:getIsFirst() then
                isExecute = true
                G_GetMgr(G_REF.Invite):showInviteeTips()
            end
        end
    end
    return isExecute
end

function PopViewConfig:popInviteTip()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local invite_data = G_GetMgr(G_REF.Invite):getData()
        if invite_data then
            if invite_data:getIsOut() then
                isExecute = true
                G_GetMgr(G_REF.Invite):showTips()
            end
        end
    end
    return isExecute
end

-- 新版破冰促销
function PopViewConfig:popIcebreakerSale()
    local isExecute = false
    local popupType
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        popupType = "Login_Lobby"
    elseif gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        popupType = "Game_Lobby"
    end

    if popupType then
        local view = G_GetMgr(G_REF.IcebreakerSale):checkPopMainUI(popupType)
        if view then
            isExecute = true
        end
    end
    
    return isExecute
end

-- 弹板都弹完后检测下 没有加入公会就去加入公会
function PopViewConfig:popClanRecuritHallView()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        return false
    end

    -- 未加入公会提醒弹窗最低弹出等级
    local currLevel = globalData.userRunData.levelNum
    if currLevel < globalData.constantData.CLAN_REMIND_OPEN_LEVEL then
        return false
    end

    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    if not ClanManager:checkSupportAppVersion() or not ClanManager:isDownLoadRes() then
        return false
    end

    if ClanManager:logonAutoPopRecuritHallView() then
        return true
    end

    return false
end

-- FB 指引
function PopViewConfig:FBGuide()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) and gLobalSendDataManager:getIsFbLogin() == false then
        local FBSignRewardManager = util_require("manager.System.FBSignRewardManager")
        if FBSignRewardManager then
            isExecute = true
            FBSignRewardManager:getInstance():openFBGuide()
        end
    end

    return isExecute
end

--fb绑定奖励
function PopViewConfig:notifyFBFansBirthday()
    --如果没有执行事件 会自动调用下一个事件
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local FBSignRewardManager = util_require("manager.System.FBSignRewardManager")
        if FBSignRewardManager then
            isExecute = FBSignRewardManager:getInstance():checkHasBirthdayReward()
            if isExecute then
                FBSignRewardManager:getInstance():showBirthdayRewardLayer()
            end
        end
    end
    return isExecute
end

function PopViewConfig:reconnecSurveyin()
    local isExecute = false
    local surveyinData = G_GetMgr(ACTIVITY_REF.SurveyinGame):getRunningData()
    if surveyinData and surveyinData:isCanCollect() then
        isExecute = G_GetMgr(ACTIVITY_REF.SurveyinGame):showCollectLayer(true)
    end
    return isExecute
end

function PopViewConfig:reconnectBalloonRush()
    -- 是否触发领奖
    local isExecute = G_GetMgr(ACTIVITY_REF.BalloonRush):isCanCollect()
    if isExecute then
        G_GetMgr(ACTIVITY_REF.BalloonRush):collectRewards(true)
    -- test
    -- G_GetMgr(ACTIVITY_REF.BalloonRush):showMainLayer()
    end
    return isExecute
end

function PopViewConfig:reconnectWorldTripRecall()
    -- 是否触发领奖
    local isExecute = G_GetMgr(ACTIVITY_REF.WorldTrip):isCanRecallRewardCollect()
    if isExecute then
        G_GetMgr(ACTIVITY_REF.WorldTrip):collectRecallReward()
    end
    return isExecute
end

function PopViewConfig:reconnectWorldTripPhase()
    -- 是否触发领奖
    local isExecute = G_GetMgr(ACTIVITY_REF.WorldTrip):isCanPhaseRewardCollect()
    if isExecute then
        G_GetMgr(ACTIVITY_REF.WorldTrip):collectPhaseReward()
    end
    return isExecute
end

function PopViewConfig:reconnectWorldTripFinal()
    -- 是否触发领奖
    local isExecute = G_GetMgr(ACTIVITY_REF.WorldTrip):isCanFinalRewardCollect()
    if isExecute then
        G_GetMgr(ACTIVITY_REF.WorldTrip):collectPhaseReward()
    end
    return isExecute
end

-- 关卡截屏分享，上传图片
function PopViewConfig:reconnetGrandShare()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        local data = G_GetMgr(G_REF.MachineGrandShare):getData()
        local topData = data:getTop()
        if not topData then
            return
        end

        G_GetMgr(G_REF.MachineGrandShare):uploadImgToServerReq(topData:getImagePath(), true)
    end
    return isExecute
end

-- 聚合挑战结束促销
function PopViewConfig:notifyHolidayEndReward()
    local isExecute = false
    local holidayEndData = G_GetMgr(G_REF.HolidayEnd):getRunningData()
    if holidayEndData and not holidayEndData:isPay() then
        isExecute = G_GetMgr(G_REF.HolidayEnd):showMainLayer()
    end
    return isExecute
end

-- 红蓝对决选择阵营
function PopViewConfig:configPushSelectSide()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local gameData = G_GetMgr(ACTIVITY_REF.FactionFight):getRunningData()
        if gameData then
            local side = gameData:getMySide()
            if not side or side == "" then
                isExecute = G_GetMgr(ACTIVITY_REF.FactionFight):showCampSelectLayer()
            end
        end
    end
    return isExecute
end

-- zombie
function PopViewConfig:configPushZomReward()
    local isExecute = false
    local gameData = G_GetMgr(ACTIVITY_REF.Zombie):getRunningData()
    if gameData then
        local status = G_GetMgr(ACTIVITY_REF.Zombie):checkZombieLogin(2)
        if status ~= nil then
            isExecute = status
        end
    end
    return isExecute
end

-- 有可领取的 新手3日任务奖励
function PopViewConfig:popColNoviceTrail()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local gameData = G_GetMgr(ACTIVITY_REF.NoviceTrail):getRunningData()
        if gameData and gameData:getCanColCount() > 0 then
            local view = G_GetMgr(ACTIVITY_REF.NoviceTrail):showPopLayer(nil, function()
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
            end)
            isExecute = view ~= nil
        end
    end
    return isExecute
end

-- 次日礼物 可领取奖励
function PopViewConfig:popColTomorrowGift()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local gameData = G_GetMgr(G_REF.TomorrowGift):getRunningData()
        if gameData and gameData:checkIsUnlock() then
            local view = G_GetMgr(G_REF.TomorrowGift):showMainLayer()
            if view then
                local cb = function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
                view:setOverFunc(cb)
            end
            isExecute = view ~= nil
        end
    end
    return isExecute
end


-- 1v1 比赛 可领取奖励
function PopViewConfig:popColFrostFlameClash()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local gameData = G_GetMgr(ACTIVITY_REF.FrostFlameClash):getRunningData()
        if gameData and gameData:isWillShowResultLayer() then
            local view = G_GetMgr(ACTIVITY_REF.FrostFlameClash):showBattleResultLayer()
            if view then
                local cb = function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
                view:setOverFunc(cb)
            end
            isExecute = view ~= nil
        end
    end
    return isExecute
end
-- 亿万赢钱挑战 可领奖
function PopViewConfig:popTrillionChallengeTaskReward()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) or gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        if G_GetMgr(G_REF.TrillionChallenge):checkCanAutoPopMaiLayer() then
            local view = G_GetMgr(G_REF.TrillionChallenge):showMainLayer()
            if view then
                local cb = function()
                    gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                end
                view:setOverFunc(cb)
            end
            isExecute = view ~= nil
        end
    end
    return isExecute
end

-- 弹框vip跨年重置折扣界面
function PopViewConfig:shopVipResetLayer()
    -- local vipData = G_GetMgr(G_REF.Vip):getData()
    -- if vipData then
    --     local vipResetData = vipData:getResetData()
    --     if vipResetData then
    --         local thisYear = vipResetData:getYear()
    --         local thisYearRewardPoints = vipResetData:getThisYearRewardVipPoints()
    --         local cacheYear = G_GetMgr(G_REF.Vip):getShowVipResetYear()
    --         if thisYear ~= 2022 and thisYear > cacheYear and thisYearRewardPoints > 0 then
    --             local view =
    --                 G_GetMgr(G_REF.Vip):showResetLayer(
    --                 function()
    --                     gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
    --                 end
    --             )
    --             if view then
    --                 G_GetMgr(G_REF.Vip):setShowVipResetYear(thisYear)
    --                 G_GetMgr(G_REF.Vip):sendExtraRequest(thisYear)
    --                 return true
    --             end
    --         end
    --     end
    -- end
    return false
end

function PopViewConfig:reshowDiyFeatureMainLayer()
    if not gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        return false
    end
    -- local diyFeatureMgr = G_GetMgr(ACTIVITY_REF.DiyFeature)
    -- if diyFeatureMgr and diyFeatureMgr:isFreeSpinBackLobby() then
    --     if G_GetMgr(ACTIVITY_REF.DiyFeature):showMainLayer() then
    --         diyFeatureMgr:clearFreeSpinBackLobbyMark()
    --         return true 
    --     end
    -- end
    return false
end

function PopViewConfig:configPushGrandFinale()
    local isExecute = G_GetMgr(ACTIVITY_REF.GrandFinale):checkCollectReward()
    if isExecute then
        G_GetMgr(ACTIVITY_REF.GrandFinale):showMainLayer({gameToLobby = true})
    end
    return isExecute
end

-- 4周年抽奖分奖
function PopViewConfig:collect4BDayDrawReward()
    local isExecute = false
    local rewardData = G_GetMgr(ACTIVITY_REF.dayDraw4B):getRewardData()
    if rewardData and rewardData:getCoins() > 0 then
        isExecute = G_GetMgr(ACTIVITY_REF.dayDraw4B):shwoRewardLayer()
    end
    return isExecute
end


function PopViewConfig:piggyGoodies()
    local isExecute = false
    local hasReward = G_GetMgr(ACTIVITY_REF.PiggyGoodies):hasReward()
    if hasReward then
        isExecute = G_GetMgr(ACTIVITY_REF.PiggyGoodies):showMainLayer({isPop = true})
    end
    return isExecute
end

-- 等级里程碑促销
function PopViewConfig:popLevelRoadSale()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local data = G_GetMgr(G_REF.LevelRoad):getRunningData()
        if data and data:isCanShowEntry() then
            local view = G_GetMgr(G_REF.LevelRoad):showLevelRoadSaleLayer()
            if view then
                isExecute = true
            end
        end
    end
    return isExecute
end

-- diyfeature 结束促销
function PopViewConfig:configDiyFeaturePromotion()
    local isExecute = false
    local view = G_GetMgr(ACTIVITY_REF.DiyFeatureOverSale):showMainLayer()
    if view then
        isExecute = true
    end
    return isExecute
end

function PopViewConfig:notifyRewardRoutineSale()
    local isExecute = false
    local data = G_GetMgr(G_REF.RoutineSale):getData()
    if data and data:hasWheelRward() then
        local wheelReward = data:getWheelReward()
        local params = {}
        params.baseCoins = data:getWheelBaseCoins()
        params.maxUsd = data:getWheelMaxUsd()
        params.wheelChunk = data:getWheelChunk()
        params.count = data:getWheelAllPro()
        params.wheelReward = wheelReward
        params.pop = true
        params.isReward = true
        local view = G_GetMgr(G_REF.RoutineSale):showTurntableLayer(params)
        if view then
            isExecute = true
        end
    end
    
    return isExecute
end

function PopViewConfig:popRoutineSale()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.GAME_TO_LOBBY) then
        local flag = G_GetMgr(G_REF.RoutineSale):checkOpenMainLayer()
        if flag then
            local params = {}
            params.pop = true
            local view = G_GetMgr(G_REF.RoutineSale):showMainLayer(params)
            if view then
                isExecute = true
            end
        end
    end
    
    return isExecute
end

function PopViewConfig:popNotification()
    local isExecute = false
    if gLobalPopViewManager:isTriggerType(POP_VC_TYPE.LOGIN_TO_LOBBY) then
        if util_isSupportVersion("1.9.4", "android") or util_isSupportVersion("1.9.9", "ios") then
            local notify = globalDeviceInfoManager:isNotifyEnabled()
            local canOpen = gLobalDataManager:getBoolByField("NotificationCanOpen", true)
            local hasReward = G_GetMgr(ACTIVITY_REF.Notification):hasReward()
            if notify and canOpen and hasReward then
                local params = {}
                params.pop = true
                local view = G_GetMgr(ACTIVITY_REF.Notification):showMainLayer(params)
                if view then
                    isExecute = true
                end
            end
        end
    end
    
    return isExecute
end

return PopViewConfig
