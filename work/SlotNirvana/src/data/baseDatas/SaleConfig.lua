--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-04-10 17:52:13
-- FIX IOS 123
local SaleItemConfig = require "data.baseDatas.SaleItemConfig"
local MegaResult = require "data.baseDatas.MegaResult"

local SaleConfig = class("SaleConfig")

SaleConfig.p_expireAt = nil --过期时间
-- SaleConfig.p_sale = nil --SaleItemConfig
-- SaleConfig.p_nodeCoinsSale = nil --没钱弹出的常规促销没有时间限制
SaleConfig.p_loginTimesInDay = nil --当日第几次登录
-- SaleConfig.p_saleTheme = nil --主题促销 (多条)
-- SaleConfig.p_saleMultiple = nil --多档促销 (多条)
-- SaleConfig.p_savenDayActivities = nil --7日类型的活动
-- SaleConfig.p_bingoActivities = nil --7日类型的活动
-- SaleConfig.p_attempsData = nil --试探付费
SaleConfig.p_onceBuyAttemps = nil --曾经买过试探付费
-- SaleConfig.p_richMainActivities = nil --大富翁促销

SaleConfig.m_isShowTopSale = true --是否显示顶部栏基础促销

SaleConfig.m_expireHandlerId = nil --过期倒计时刷新

SaleConfig.m_lobbyLayoutNode = nil --大厅轮播图节点
--特殊活动数据
-- SaleConfig.m_repeatWinConfig = nil --任意促销buf
SaleConfig.m_megaResult = nil --mega77活动
-- SaleConfig.m_couponConfig = nil --商城促销卷活动
-- SaleConfig.m_levelBoomResult = nil --levelBoom活动
-- SaleConfig.m_cashBackConfig = nil --cashBack活动
-- SaleConfig.m_questConfig = nil --quest活动
-- SaleConfig.m_keepChargeConfig = nil --连续充值
-- SaleConfig.m_questRankConfig = nil --quest活动排行榜
-- SaleConfig.m_levelDashConfig = nil -- level dash
SaleConfig.m_expireALLHandlerId = nil --所有活动倒计时刷帧

-- 小猪银行促销活动 --
-- SaleConfig.m_PiggyCommonSale = nil -- 小猪银行普通促销 --
-- SaleConfig.m_PiggyBoostSale = nil -- 小猪银行booster促销 --
--VIP体验
-- SaleConfig.m_vipBoostConfig = nil --vip体验

SaleConfig.m_saleTicketList = nil --道具打折券 SaleTicketConfig
SaleConfig.m_dropTicketList = nil --道具打折券 SaleTicketConfig

GD.THEME_CHRISTMAST_QUEST = false --是否为圣诞节主题
GD.THEME_EASTER_QUEST = false --是否为复活节主题

function SaleConfig:ctor()
    self.m_saleDatas = {}
    -- self:startUpdate()
end
--停止刷帧
function SaleConfig:stopUpdate()
    if self.m_expireALLHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_expireALLHandlerId)
        self.m_expireALLHandlerId = nil
    end
end
--开启刷帧 剩余时间是倒计时类型放到这里
function SaleConfig:startUpdate()
    self:stopUpdate()
    self.m_loaclLastTime = socket.gettime()
    self.m_expireALLHandlerId =
        scheduler.scheduleGlobal(
        function()
            --获取真实倒计时
            local delayTime = 1
            if self.m_loaclLastTime then
                local spanTime = socket.gettime() - self.m_loaclLastTime
                self.m_loaclLastTime = socket.gettime()
                if spanTime > 0 then
                    delayTime = spanTime
                end
            end

            --刷新倒计时
            local function updateConfigExpire(config)
                if config and config.p_expire ~= nil and config.p_expire >= 0 then
                    if config.setExpire then
                        -- 新逻辑，在数据解析中添加此函数即可
                        if config:isExist() then
                            config:setExpire(math.max(0, config.p_expire - delayTime * 1000))
                            if not config:isExist() then
                                if config.p_activityId and config.p_activityId ~= "" then
                                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, config.p_activityId)
                                end
                            end
                        end
                    else
                        -- 旧逻辑，但是此代码貌似不生效
                        config.p_expire = config.p_expire - delayTime
                        if config.p_expire <= 0 then
                            config.p_expire = 0
                            if config.p_activityId and config.p_activityId ~= "" then
                                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, config.p_activityId)
                            end
                        end
                    end
                end
            end

            --刷新buff倒计时
            local function updateBuffExpire(config)
                if config and config.p_buffExpire and config.p_buffExpire > 0 then
                    config.p_buffExpire = config.p_buffExpire - delayTime
                    if config.p_buffExpire <= 0 then
                        config.p_buffExpire = 0
                    end
                end
            end

            local cashBack = G_GetMgr(ACTIVITY_REF.CashBack):getRunningData()
            if cashBack then
                updateBuffExpire(cashBack)
            end

            --quest活动
            local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
            if questConfig then
                updateBuffExpire(questConfig)
            end

            -- superspin赠送卡牌活动
            if globalData.luckySpinSaleData then
                updateConfigExpire(globalData.luckySpinSaleData)
            end

            -- superspin赠送卡牌活动
            if globalData.luckySpinCardData then
                updateConfigExpire(globalData.luckySpinCardData)
            end

            -- 每日每个任务送卡活动
            if globalData.everyCardMissionData then
                updateConfigExpire(globalData.everyCardMissionData)
            end

            if globalData.spinBonusData then
                if not globalData.spinBonusData:isTaskOpen() and globalData.spinBonusData.p_activityId then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, globalData.spinBonusData.p_activityId)
                    G_GetMgr(G_REF.Inbox):updateSpinBonusMail()
                end
            end

            if gLobalActivityManager and globalData.missionRunData.p_allMissionCompleted then
                local activityData = gLobalActivityManager:getActivityDataByName("Activity_EveryCardMission")
                if activityData then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, activityData.p_id)
                end
            end

            -- superspin赠送固定卡活动
            if globalData.luckySpinAppointCardData then
                updateConfigExpire(globalData.luckySpinAppointCardData)
            end

            if not globalData.shopRunData:getLuckySpinIsOpen() and globalData.luckySpinAppointCardData and globalData.luckySpinAppointCardData.p_activityId then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, globalData.luckySpinAppointCardData.p_activityId)
            end

            --gameCraze Activity
            -- if globalData.gameCrazeData then
            --     local activityDatas = globalData.gameCrazeData:getActivityDatas()
            --     if activityDatas then
            --         for i = 1, #activityDatas do
            --             local activityData = activityDatas[i]
            --             updateConfigExpire(activityData)
            --         end
            --     end

            -- --GameCraze buff
            -- -- local GameCrazeControl = util_getRequireFile("Activity/GameCrazeControl")
            -- -- if GameCrazeControl then
            -- --     GameCrazeControl:getInstance():pubUpdateLeftTime(delayTime)
            -- -- end
            -- end

            local luckyChallengeData = G_GetMgr(ACTIVITY_REF.LuckyChallenge):getRunningData()
            if luckyChallengeData then
                if not luckyChallengeData:isOpen() then
                    local activityData = gLobalActivityManager:getActivityDataByName("Activity_LuckyChallenge")
                    if activityData then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, activityData.p_id)
                    end

                    local activity2 = gLobalActivityManager:getActivityDataByName("Activity_LuckyChallengeRule")
                    if activity2 then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, activity2.p_id)
                    end

                    local activity3 = gLobalActivityManager:getActivityDataByName("Activity_LuckyChallengeOver")
                    if activity3 then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, activity3.p_id)
                    end

                -- local promotion = gLobalActivityManager:getPromotionDataByName("Promotion_LuckyChallenge")
                -- if promotion then
                --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, promotion.p_id)
                -- end
                end
            end

            --充值抽奖活动结束弹窗提示
            self:checkShowLuckyChipsDrawTips()
            --刷新第二天任务
            self:checkRefreshDrawTask()
        end,
        1
    )
end

function SaleConfig:parseData(data)
    self.p_expireAt = tonumber(data.expireAt) --过期时间
    self.p_loginTimesInDay = data.loginTimesInDay --当日第几次登录

    if self:checkBaicsSale() then
        self.m_isShowTopSale = true
    end
end

--常规促销是否可以弹出
function SaleConfig:isOpenNormalSale()
    local commSale = G_GetMgr(G_REF.SpecialSale):getRunningData()
    if commSale and commSale.p_discounts > 0 then
        return true
    end
    return false
end

function SaleConfig:isNeedPushViewByRef(vType, refName)
    if vType > ACTIVITY_TYPE.COMMON then
        -- local data = self:getPromotionData(vType, activityId)
        local data = G_GetActivityDataByRef(refName)
        if data == nil then
            return false, nil
        end

        return true, data.p_popupImage
    end

    return self:checkBaicsSale(), nil
end

--获取活动数据
function SaleConfig:getPromotionData(vType, activityId)
    if vType == ACTIVITY_TYPE.KEEPRECHARGE then
        local kRecharge = G_GetMgr(ACTIVITY_REF.KRechargeSale):getRunningData()
        if not kRecharge then
            return nil
        end

        local _, saleInfo = kRecharge:getKeepRechargeBuyInfo()
        return saleInfo
    else
        local _datas = self.m_saleDatas["" .. vType]
        if _datas and next(_datas) then
            return _datas[tostring(activityId)]
        else
            return nil
        end
    end

    return nil
end

--获得基础促销开启状态
function SaleConfig:checkBaicsSale()
    local commSale = G_GetMgr(G_REF.SpecialSale):getRunningData()
    local routineSale = G_GetMgr(G_REF.RoutineSale):getRunningData()
    local FirstSaleData = G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData()
    local bCanShowFirstSaleMulti = G_GetMgr(G_REF.FirstSaleMulti):isCanShowLayer()
    if FirstSaleData or bCanShowFirstSaleMulti or commSale or routineSale then
        return true
    end

    return false
end

--是否是首次登陆
function SaleConfig:isFristLogin()
    if not self.p_loginTimesInDay then
        return false
    end
    if self.p_loginTimesInDay == 1 then
        return true
    end
    return false
end

--是否显示顶部栏促销
function SaleConfig:isShowTopSale()
    return self.m_isShowTopSale
end

--设置顶部栏促销状态
function SaleConfig:setShowTopeSale(flag)
    self.m_isShowTopSale = flag
end

function SaleConfig:parseMegaResult(d)
    if d ~= nil and #d > 0 then
        for i = 1, #d do
            local sale = MegaResult:create()
            sale:parseData(d[i])
            self.m_megaResult = sale
        end
    end
end

--清空Mega数据
function SaleConfig:getMegaResultValue()
    if self.m_megaResult ~= nil then
        return self.m_megaResult.p_totalWin
    end

    return 0
end

--是否是quest活动和QuestActivityConfig里面的活动数量对应
function SaleConfig:isQuestActivity(luaName)
    if
        luaName == "Activity_QuestFreeBuff" or luaName == "Activity_QuestLink" or luaName == "Activity_QuestBuffExp" or luaName == "Activity_QuestFirstCoins" or luaName == "Activity_QuestFirstWheel" or
            luaName == "Activity_QuestCollectStar"
     then
        return true
    end
    return false
end

function SaleConfig:triggerVipLevelUp()
    local bVipLevelUp = gLobalSaleManager:checkVipLevelUp()
    if bVipLevelUp then
        G_GetMgr(G_REF.Vip):showLevelUpLayer(
            function()
                gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_DONE_VIEW_AFTER_BUY) --quest关卡中 购买跳关回调
            end
        )
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_VIPLEVEL_UP)
    else
        gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT, "reconnectLuckyStampProgress")
        --弹窗逻辑执行下一个事件
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LEVEL_DASH_PAY_START)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_QUEST_DONE_VIEW_AFTER_BUY) --quest关卡中 购买跳关回调
    end
end

--这里优先检测是否有二选一活动,如果存在等界面刷新做完动画在执行后续操作
function SaleConfig:getCouponGift()
    local manage = G_GetMgr(ACTIVITY_REF.BetweenTwo)
    manage:checkUpdateMainView(handler(self, self.getCouponGiftNew))
end
--这里有折扣卷 还有高倍场开启 vip升级很乱后续整理
function SaleConfig:getCouponGiftNew()
    local function popDeluexeClub()
        -- local isNotStore = globalData.iapRunData.p_lastBuyType ~= BUY_TYPE.STORE_TYPE
        local isDeluexeOpened = globalData.deluexeClubData:getDeluexeClubStatus()
        if globalData.deluexeStatus == false and isDeluexeOpened == true then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PUSH_DELUEXECLUB_VIEWS)
        else
            self:triggerVipLevelUp()
        end
    end
    if globalData.sendCouponFlag == true then
        globalData.sendCouponFlag = false
        local view = util_createFindView("Activity/Promotion_SendCoupon", popDeluexeClub)
        if view ~= nil then
            gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
        else
            popDeluexeClub()
        end
    else
        popDeluexeClub()
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
end

-- 测试性付费
function SaleConfig:getAttemptData()
    local attemps = G_GetActivityDataByRef(ACTIVITY_REF.AttemptSale)
    if attemps then
        return attemps:getSalesData()
    else
        return nil
    end
end

-- 是否曾经买过试探性付费
function SaleConfig:isOnceBuyAttemps()
    local sales = self:getAttemptData()
    for i = 1, #sales do
        local sale = sales[i]
        if sale and sale.p_type == 1 then
            self.p_onceBuyAttemps = true
            return true
        end
    end

    return false
end

--根据reference name 获得saleData
-- function SaleConfig:getSaleDataByReference(reference)
--     local activityTemp = globalData.GameConfig:getActivityConfigByRef(reference, ACTIVITY_TYPE.SEVENDAY)

--     if activityTemp then
--         -- local saleData = self:getPromotionData(ACTIVITY_TYPE.SEVENDAY, activityTemp.p_id)
--         local saleData = G_GetActivityDataById(activityTemp.p_id)
--         return saleData
--     end

--     return nil
-- end

--充值抽奖活动结束弹窗提示
function SaleConfig:checkShowLuckyChipsDrawTips()
    if not gLobalSendDataManager or gLobalSendDataManager:isLogin() == false then
        return
    end
    if gLobalViewManager:isLoadingView() then
        return
    end

    if not gLobalPopViewManager.p_popViewConfig then
        return
    end

    local drawData = G_GetMgr(ACTIVITY_REF.LuckyChipsDraw):getRunningData()
    if drawData == nil or drawData:isRunning() == false then
        --没有数据不刷新
        return
    end

    if gLobalViewManager:isLobbyView() and not drawData.m_isPopView then
        return
    end

    local function showTimeTips(state)
        local timeLeftUI = nil
        local luckyChipsDrawMgr = G_GetMgr(ACTIVITY_REF.LuckyChipsDraw)
        if luckyChipsDrawMgr and luckyChipsDrawMgr.showTimeLeftLayer then
            timeLeftUI = luckyChipsDrawMgr:showTimeLeftLayer()
        end
        if timeLeftUI then
            self.m_luckyChipsDrawState = state
            gLobalDataManager:setNumberByField("LuckyChipsDraw_ShowState" .. drawData.p_expireAt, self.m_luckyChipsDrawState)
        end
    end

    if not self.m_luckyChipsDrawState then
        self.m_luckyChipsDrawState = gLobalDataManager:getNumberByField("LuckyChipsDraw_ShowState" .. drawData.p_expireAt, 0)
    end
    local expireTime = drawData:getLeftTime()
    if expireTime <= 300 and self.m_luckyChipsDrawState < 3 then
        showTimeTips(3)
    elseif expireTime <= 1800 and self.m_luckyChipsDrawState < 2 then
        showTimeTips(2)
    elseif expireTime <= 3600 and self.m_luckyChipsDrawState < 1 then
        showTimeTips(1)
    end
end
--检测第二天任务刷新
function SaleConfig:checkRefreshDrawTask()
    if not gLobalSendDataManager or gLobalSendDataManager:isLogin() == false then
        return
    end
    local drawData = G_GetMgr(ACTIVITY_REF.LuckyChipsDraw):getRunningData()
    if drawData == nil or drawData:isRunning() == false then
        --没有数据不刷新
        return
    end
    local expireAt = drawData.m_drawTaskData:getExpireAt()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    if not self.m_luckyChipsDrawTaskTime then
        self.m_luckyChipsDrawTaskTime = curTime
    end
    if curTime < self.m_luckyChipsDrawTaskTime then
        return
    end
    if expireAt < curTime + 2 then
        self.m_luckyChipsDrawTaskTime = curTime + 10
        gLobalSendDataManager:getNetWorkFeature():sendRefreshDrawTask()
    end
end
--获取通用的支付道具显示
function SaleConfig:checkAddCommonBuyItemTips(extraPropList, key, price)
    if not extraPropList then
        return
    end

    for i,v in ipairs(extraPropList) do
        if v.p_icon == "Vip" then
            if G_GetMgr(ACTIVITY_REF.TripleVip) then
                local data = G_GetMgr(ACTIVITY_REF.TripleVip):getRunningData()
                if data then
                    v:setTempData({p_num = v.p_num * 3})
                end
            end
            break
        end
    end

    local insertIndex = 2 --插入位置 默认集卡第一位

    local isRepartFsAlive = true
    --特殊逻辑处理
    if key then
        if key == "CashBonus" or key == "PokerLinkPlay" or key == "GemStoreItem" or key == "GemStoreTip" or key == "BattlePass" then
            isRepartFsAlive = false
        end
        if key == "GemStoreItem" or key == "CoinStoreItem" then
            insertIndex = 1 --商店没有吧集卡放进来
        end
    end

    --手动添加repeatJackpot
    local repartJackpotData = G_GetMgr(ACTIVITY_REF.RepartJackpot):getRunningData()
    if repartJackpotData and repartJackpotData:isRunning() then
        --活动结束时间
        local expireTime = repartJackpotData:getLeftTime()
        if expireTime and expireTime > 0 then
            --放到集卡之后
            table.insert(extraPropList, insertIndex, gLobalItemManager:createLocalItemData("RepeatJackpot"))
        end
    end
    --手动添加repeatFreeSpin
    local repeatFreeSpinData = G_GetMgr(ACTIVITY_REF.RepeatFreeSpin):getRunningData()
    if isRepartFsAlive and repeatFreeSpinData and repeatFreeSpinData:isRunning() then
        --活动结束时间
        local expireTime = repeatFreeSpinData:getLeftTime()
        if expireTime and expireTime > 0 then
            --放到集卡之后
            table.insert(extraPropList, insertIndex, gLobalItemManager:createLocalItemData("RepeatFreeSpin"))
        end
    end
    --手动添加echowin
    local echowinSpinData = G_GetMgr(ACTIVITY_REF.EchoWin):getRunningData()
    if key and (key == "GemStoreItem" or key == "GemStoreTip") or isRepartFsAlive then
        if echowinSpinData and echowinSpinData:isRunning() then
            --活动结束时间
            local expireTime = echowinSpinData:getLeftTime()
            if expireTime and expireTime > 0 then
                --放到集卡之后
                table.insert(extraPropList, insertIndex, gLobalItemManager:createLocalItemData("EchoWins"))
            end
        end
    end

    --手动添加 聚合挑战充值得到
    local holidayChallengeData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
    if holidayChallengeData and holidayChallengeData:isRunning() then
        local num  = holidayChallengeData:getAddPointByPrice(price)
        if num > 0 then
            table.insert(extraPropList, insertIndex, gLobalItemManager:createLocalItemData("HolidayChallenge", num))
        end
    end

    --手动添加luckystamp
    local stampIndex = insertIndex
    if stampIndex > 4 then
        stampIndex = 4
    end
    table.insert(extraPropList, stampIndex, self:getLuckyStampItemData(price))

    --手动添加GrandPrizeData
    local GrandPrizeData = G_GetMgr(ACTIVITY_REF.GrandPrize):getRunningData()
    if GrandPrizeData and GrandPrizeData:isRunning() then
        --活动结束时间
        local expireTime = GrandPrizeData:getLeftTime()
        if expireTime and expireTime > 0 then
            --加到最后
            local num = GrandPrizeData:getPointByPrice(price)
            if num > 0 then
                table.insert(extraPropList, gLobalItemManager:createLocalItemData("GrandPrize", num))
            end
        end
    end

end
--获取通用的支付成功奖励道具显示
function SaleConfig:getCommonRewardItemList(isRepeatFreeSpinAlive, price)
    local commonItemList = {}
    -- commonItemList[#commonItemList+1] = {key = "类型item.p_icon" , var = "数量倍数等" , char = "+-x等符号",data = "itemdata道具数据"}

    --手动添加luckystamp
    local stampList = self:getLuckyStampItemList()
    if stampList and #stampList > 0 then
        for i = 1, #stampList do
            local stampData = stampList[i]
            commonItemList[#commonItemList + 1] = {key = stampData.p_icon, var = "1", char = "", data = stampData}
        end
    end
    --手动添加repeatJackpot
    local repartJackpotData = G_GetMgr(ACTIVITY_REF.RepartJackpot):getRunningData()
    if repartJackpotData and repartJackpotData:isRunning() then
        --活动结束时间
        local expireTime = repartJackpotData:getLeftTime()
        if expireTime and expireTime > 0 then
            commonItemList[#commonItemList + 1] = {key = "RepeatJackpot", var = "1", char = "", data = gLobalItemManager:createLocalItemData("RepeatJackpot")}
        end
    end
    --手动添加repeatFreeSpin
    local repeatFreeSpinData = G_GetMgr(ACTIVITY_REF.RepeatFreeSpin):getRunningData()
    if isRepeatFreeSpinAlive and repeatFreeSpinData and repeatFreeSpinData:isRunning() then
        --活动结束时间
        local expireTime = repeatFreeSpinData:getLeftTime()
        if expireTime and expireTime > 0 then
            commonItemList[#commonItemList + 1] = {key = "RepeatFreeSpin", var = "1", char = "", data = gLobalItemManager:createLocalItemData("RepeatFreeSpin")}
        end
    end
    --手动添加echowinSpinData
    local echowinSpinData = G_GetMgr(ACTIVITY_REF.EchoWin):getRunningData()
    if echowinSpinData and echowinSpinData:isRunning() then
        --活动结束时间
        local expireTime = echowinSpinData:getLeftTime()
        if expireTime and expireTime > 0 then
            commonItemList[#commonItemList + 1] = {key = "EchoWin", var = "1", char = "", data = gLobalItemManager:createLocalItemData("EchoWins")}
        end
    end
    --手动添加GrandPrizeData
    local GrandPrizeData = G_GetMgr(ACTIVITY_REF.GrandPrize):getRunningData()
    if GrandPrizeData and GrandPrizeData:isRunning() then
        --活动结束时间
        local expireTime = GrandPrizeData:getLeftTime()
        if expireTime and expireTime > 0 then
            --加到最后
            local num = GrandPrizeData:getPointByPrice(price)
            if num > 0 then
                commonItemList[#commonItemList + 1] = {key = "GrandPrize", var = "1", char = "", data = gLobalItemManager:createLocalItemData("GrandPrize", num)}
            end
        end
    end
     --手动添加 聚合挑战充值得到
     local holidayChallengeData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getRunningData()
     if holidayChallengeData and holidayChallengeData:isRunning() then
         local num  = holidayChallengeData:getAddPointByPrice(price)
         if num > 0 then
            commonItemList[#commonItemList + 1] = {key = "HolidayChallenge", var = "1", char = "", data = gLobalItemManager:createLocalItemData("HolidayChallenge", num)}
         end
     end

    return commonItemList
end

function SaleConfig:getLuckyStampItemData(_price)
    local iconName = "LuckyStamp"
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if _price ~= nil and _price ~= "" and data and data:isGoldenStamp(_price) then
        iconName = "LuckyStampGolden"
    end
    local itemData = gLobalItemManager:createLocalItemData(iconName)
    local multi = self:getLuckyStampMultiple()
    if multi and multi > 1 then
        itemData.p_num = itemData.p_num * multi
    end
    return itemData
end

function SaleConfig:getLuckyStampItemList()
    local itemData = {}
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if data then
        local normalStamp, goldenStamp = data:getAllNeedStamp()
        print("!!!getLuckyStampItemList normalStamp, goldenStamp == ", normalStamp, goldenStamp)
        if normalStamp and normalStamp > 0 then
            itemData[#itemData + 1] = gLobalItemManager:createLocalItemData("LuckyStamp", normalStamp)
        end
        if goldenStamp and goldenStamp > 0 then
            itemData[#itemData + 1] = gLobalItemManager:createLocalItemData("LuckyStampGolden", goldenStamp)
        end
    end
    return itemData
end

function SaleConfig:getLuckyStampMultiple()
    local multi = 1
    -- 多倍盖戳活动开启了，要主动乘以倍数
    -- local mulLuckyStampData = G_GetActivityDataByRef(ACTIVITY_REF.MulLuckyStamp)
    local mulLuckyStampData = G_GetMgr(ACTIVITY_REF.MulLuckyStamp):getRunningData()
    if mulLuckyStampData and mulLuckyStampData.isRunning and mulLuckyStampData:isRunning() then
        multi = mulLuckyStampData:getMultiple() or 1
    end

    local tripleStampData = G_GetMgr(ACTIVITY_REF.TripleStamp):getRunningData()
    if tripleStampData then
        multi = tripleStampData:getMultiple() or 1
    end

    return multi
end
return SaleConfig
