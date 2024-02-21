---
-- 处理 游戏内的spin 消息同步等， 处理
--
-- FIX IOS 139
local NetWorkSlots = class("NetWorkSlots", require "network.NetWorkBase")

NetWorkSlots.startSpinTime = nil
NetWorkSlots.levelName = nil
function NetWorkSlots:ctor()
end

---
-- 请求feature data 数据
--
function NetWorkSlots:requestFeatureData(messageData, isShowTournament)
    -- 请求feature 结果数据
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local isFreeSpin = true
    local totalCoin = globalData.userRunData.coinNum
    local currProVal = globalData.userRunData.currLevelExper
    local curLevel = globalData.userRunData.levelNum
    self:sendActionData_Spin(totalBet, totalCoin, 0, isFreeSpin, globalData.slotRunData.gameNetWorkModuleName, false, curLevel, currProVal, messageData, isShowTournament)
end

---
-- 点击spin 请求spin_result 数据
-- @isShowTournament 是否显示Tournament

function NetWorkSlots:sendActionData_Spin(betCoin, currentCoins, winCoin, isFreeSpin, slotName, bLevelUp, nextLevel, nextProVal, messageData, isShowTournament)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    globalData.slotRunData.isClickQucikStop = false

    local actType = nil

    self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    if self.m_handerIdSpinTimeOut ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdSpinTimeOut)
        self.m_handerIdSpinTimeOut = nil
    end
    if self.m_handerIdSpinTimeOut == nil then
        self.m_handerIdSpinTimeOut =
            scheduler.performWithDelayGlobal(
            function(delay)
                self:sendWaitTimeMoreLog()
                if self.m_handerIdSpinTimeOut ~= nil then
                    scheduler.unscheduleGlobal(self.m_handerIdSpinTimeOut)
                    self.m_handerIdSpinTimeOut = nil
                end
            end,
            10,
            "NetWorkSlots"
        ) 
    end
    
    self.levelName = slotName
    actType = ActionType.SpinV2

    local clickPos = nil
    local bonusSelect = nil
    local collectData = nil
    local choose = nil
    local jackpotData = nil
    local unlockFeature = nil
    local betLevel = nil
    local coins = nil
    local extra = nil
    local kangaroosShopData = nil -- 袋鼠商店兑换特殊玩法
    local mermaidVersion = nil -- 美人鱼服务器兼容字段
    if messageData and type(messageData) == "table" then
        if messageData.clickPos then
            clickPos = messageData.clickPos
        end

        if messageData.bonusSelect then
            bonusSelect = messageData.bonusSelect
        end

        if messageData.mermaidVersion then
            mermaidVersion = messageData.mermaidVersion
        end

        if messageData.msg == MessageDataType.MSG_BONUS_COLLECT then
            actType = ActionType.Bonus

            collectData = messageData.data
        elseif messageData.msg == MessageDataType.MSG_BONUS_SELECT then
            actType = ActionType.BonusV2
            choose = messageData.data
            jackpotData = messageData.jackpot
            betLevel = messageData.betLevel
            coins = messageData.coins
            extra = messageData.extra
        elseif messageData.msg == MessageDataType.MSG_SPIN_PROGRESS then
            collectData = messageData.data
            jackpotData = messageData.jackpot
            unlockFeature = messageData.unlockFeature
            betLevel = messageData.betLevel
        elseif messageData.msg == MessageDataType.MSG_MISSION_COMLETED then
            actType = ActionType.MissionCollect
        elseif messageData.msg == MessageDataType.MSG_BONUS_SPECIAL then
            actType = ActionType.BonusSpecial
            choose = messageData.choose
            kangaroosShopData = messageData.data
        elseif messageData.msg == MessageDataType.MSG_LUCKY_SPIN then
            actType = ActionType.LuckSpinAward
        elseif messageData.msg == MessageDataType.MSG_LUCKY_SPINV2 then
            actType = ActionType.LuckySpinV2Spin
        elseif messageData.msg == MessageDataType.MSG_DELUXE_CHANGE_COIN then
            actType = ActionType.HighLimitCollectCoin
        elseif messageData.msg == MessageDataType.MSG_TEAM_MISSION_OPTION then
            --关卡团队任务玩家操作
            actType = ActionType.TeamMissionOption
        elseif messageData.msg == MessageDataType.MSG_TEAM_MISSION_STORE then
            actType = ActionType.TeamMissionStore
        elseif messageData.msg == MessageDataType.MSG_TEAM_MISSION_JOIN then
            actType = ActionType.TeamMissionJoin
        end
    end

    if globalData.slotRunData.isDeluexeClub == true then
        if string.find(self.levelName, "_H") == nil then
            self.levelName = self.levelName .. "_H"
        end

        if actType == ActionType.SpinV2 then
            actType = ActionType.HighLimitSpin
        elseif actType == ActionType.BonusV2 then
            actType = ActionType.HighLimitBonus
        elseif actType == ActionType.BonusSpecial then
            actType = ActionType.HighLimitBonusSpecial
        end
    end

    local actionData = self:getSendActionData(actType, self.levelName)

    -- if winType == 0 then
    --     winType = 1
    -- end
    actionData.data.betCoins = globalData.slotRunData:getCurTotalBet()

    actionData.data.betGems = 0

    actionData.data.winCoins = winCoin
    -- actionData.data.winGems = 0
    actionData.data.balanceCoins = 0
    actionData.data.balanceCoinsNew = get_integer_string(currentCoins)
    actionData.data.balanceGems = 0

    if false then
        local tournamentName = gLobalTournamentData:getTournamentName(betCoin)
        actionData.tournamentName = tournamentName
    end

    -- 判断是否升级
    local addBetExp = betCoin
    local currProVal = nextProVal
    local totalProVal = globalData.userRunData:getLevelUpgradeNeedExp(nextLevel)

    actionData.data.freespin = isFreeSpin
    -- actionData.data.winType = winType
    actionData.data.exp = currProVal
    actionData.data.addExp = addBetExp
    actionData.data.levelup = bLevelUp
    actionData.data.level = nextLevel
    actionData.data.betId = globalData.slotRunData.iLastBetIdx

    actionData.data.version = self:getVersionNum()
    --spin校验码
    if globalData.slotRunData:getSpinDataValidCode() then
        actionData.data.validCode = globalData.slotRunData:getSpinDataValidCode()
    end
    

    -- for i = 1, #slotData do
    --     actionData.data.table:append(slotData[i])
    -- end
    --    actionData.data.table:append(nil)  -- 这里是附加freeSpin下之前获得的spin coin目前不使用了
    local extraData = {}

    extraData[ExtraType.spinAccumulation] = globalData.spinAccumulation or {["time"] = os.time(), ["amount"] = 0}

    --存救济金
    extraData[ExtraType.reliefTimes] = globalData.reliefFundsTimes

    --如果存在收集数据 存储
    if collectData and type(collectData) == "table" and #collectData > 0 then
        extraData.collect = {}
        for i = 1, #collectData do
            extraData.collect[i] = {}
            extraData.collect[i].collectTotalCount = collectData[i].p_collectTotalCount
            extraData.collect[i].collectLeftCount = collectData[i].p_collectLeftCount
            extraData.collect[i].collectCoinsPool = collectData[i].p_collectCoinsPool
            extraData.collect[i].collectChangeCount = collectData[i].p_collectChangeCount
        end
    end

    if jackpotData and type(jackpotData) == "table" and #jackpotData > 0 then
        extraData.jackpot = jackpotData
    end

    local findData = {}
    findData["findLock"] = globalData.findLock
    extraData["find"] = findData

    actionData.data.extra = cjson.encode(extraData)

    local logSpinType = "normal"

    if globalData.slotRunData.currSpinMode == AUTO_SPIN_MODE then
        logSpinType = "auto"
    end

    --spin附加参数
    local paramsData = {}
    paramsData.spinSessionId = gL_logData:getGameSessionId()
    paramsData.type = logSpinType
    local levelName = globalData.slotRunData.machineData.p_levelName
    paramsData.order = gLobalSendDataManager:getLogSlots():getLevelOrder(levelName)
    gLobalSendDataManager:getLogSlots():addSlotData(paramsData)
    local maxBetData = globalData.slotRunData:getMaxBetData()
    if maxBetData then
        paramsData.maxBet = maxBetData.p_totalBetValue
    end
    if choose then
        paramsData["select"] = choose
    end
    if unlockFeature then
        paramsData["unlockFeature"] = unlockFeature
    end
    if jackpotData and type(jackpotData) == "table" and #jackpotData > 0 then
        paramsData.jackpot = jackpotData
    end
    if betLevel ~= nil then
        paramsData["betLevel"] = betLevel
    end

    if kangaroosShopData then
        paramsData["level"] = kangaroosShopData.pageIndex
        paramsData["select"] = kangaroosShopData.pageCellIndex
        paramsData["selectSuperFree"] = kangaroosShopData.selectSuperFree
    end

    if clickPos then
        paramsData["clickPos"] = clickPos
    end

    if bonusSelect then
        paramsData["bonusSelect"] = bonusSelect
    end

    if mermaidVersion then
        paramsData["mermaidVersion"] = mermaidVersion
    end

    if coins then
        paramsData["coins"] = coins
    end

    if extra then
        paramsData["extra"] = extra
    end

    local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
    if minzMgr and minzMgr:getMinzSwitch() then
        local minzSwitch = minzMgr:getMinzSwitch()
        paramsData["minzGame"] = minzSwitch
    end

    local diyFeatureSwitch = G_GetMgr(ACTIVITY_REF.DiyFeature):getDiyFeatureSwitch()
    paramsData["diyFeatureGame"] = diyFeatureSwitch
    
    local frostFlameClashMgr = G_GetMgr(ACTIVITY_REF.FrostFlameClash)
    if frostFlameClashMgr and frostFlameClashMgr:getFrostFlameClashSwitch() then
        local frostFlameClashSwitch = frostFlameClashMgr:getFrostFlameClashSwitch()
        paramsData["flameClashGame"] = frostFlameClashSwitch
    end

    local flamingoJackpotMgr = G_GetMgr(ACTIVITY_REF.FlamingoJackpot)
    if flamingoJackpotMgr and flamingoJackpotMgr:getRunningData() then
        local flamingoJackpotSwitch = flamingoJackpotMgr:getSwitchStatusCacheData() == FlamingoJackpotCfg.SwitchStatus.ON and "true" or "false"
        if flamingoJackpotSwitch == "true" then
            paramsData["flamingoJackpotGame"] = flamingoJackpotSwitch
        else
            paramsData["flamingoJackpotGame"] = "false"
        end
    end
   
    if actType == ActionType.TeamMissionOption then
        paramsData.action = messageData.action
        if not paramsData.extra then
            paramsData.extra = {}
        end
        paramsData.extra.choose = messageData.choose or {}
    end
    if actType == ActionType.TeamMissionStore then
        if not paramsData.extra then
            paramsData.extra = {}
        end
        paramsData.extra.choose = messageData.choose or 0
    end
    if actType == ActionType.TeamMissionJoin then
        if not paramsData.extra then
            paramsData.extra = {}
        end
        paramsData.extra.choose = messageData.choose or 0
        paramsData.game = messageData.game
        paramsData.roomId = messageData.roomId
        paramsData.chairId = messageData.chairId
    end

    actionData.data.params = json.encode(paramsData)

    globalData.slotRunData.gameEffStage = GAME_START_REQUEST_STATE
    globalData.slotRunData.spinNetState = GAME_START_REQUEST_STATE

    if actType == ActionType.TeamMissionJoin then
        self:sendMessageData(actionData)
    else
        self:sendMessageData(actionData, self.spinResultSuccessCallFun, self.spinResultFaildCallFun)
    end
    --spin 重置 firebase 弹窗
    if globalNoviceGuideManager then
        globalNoviceGuideManager.guideBubbleAddBetPopup = nil
        globalNoviceGuideManager.guideBubbleMaxBetPopup = nil
        globalNoviceGuideManager.guideBubbleReturnLobbyPopup = nil
    end
end

--- 成功回调
function NetWorkSlots:spinResultSuccessCallFun(resultData)
    -- print(resultData,"spin回调的数据 消息返回")
    globalData.slotRunData.spinNetState = GAME_EFFECT_OVER_STATE

    if self.m_handerIdSpinTimeOut ~= nil then
        scheduler.unscheduleGlobal(self.m_handerIdSpinTimeOut)
        self.m_handerIdSpinTimeOut = nil
    end
    local result = resultData.result
    local spinData = cjson.decode(result)

    local curValidCode = globalData.slotRunData:getSpinDataValidCode()
    local netValidCode = spinData.validCode
    if curValidCode and netValidCode and netValidCode ~= "" and curValidCode ~= "" and curValidCode ~= netValidCode then
        --无效消息,不做任何处理
        local str = "spin消息校验码未通过!!!!\n"
        str = str.."本地校验码:"..curValidCode.."\n"
        str = str.."服务器返回校验码:"..netValidCode.."\n"
        str = str.."gameName:"..(spinData.game or "").."\n"
        str = str.."requestId = " .. (globalData.requestId or "isnil").."\n"
        str = str.."udid = " ..(globalData.userRunData.userUdid or "isnil")
        -- util_printLog(str,true)
        util_sendToSplunkMsg("ErrorValidCode",str)
        -- return
    end

    local mission = resultData.mission
    -- 存储一下网络数据
    globalData.slotRunData.severGameJsonData = result

    
    local serverCoins = globalData.userRunData.coinNum
    local serverGems = globalData.userRunData.gemNum
    if resultData:HasField("user") then
        local userData = resultData.user
        --关卡升级标志，如果升级了，打开商店需要向服务器重新请求网络数据
        if globalData.userRunData.levelNum ~= tonumber(userData.level) then
            self:sendRequestShopInfo({"Shop", "Vip", "CashBonus", "DailyBonus", "FacebookReward"})
        end
        globalData.syncSimpleUserInfo(userData)
        -- serverCoins = tonumber(userData.coins)
        serverCoins = toLongNumber(userData.coinsV2)
        serverGems = tonumber(userData.gems or 0)
    end

    local luckyChallengeData = G_GetMgr(ACTIVITY_REF.NewDiamondChallenge):getRunningData()
    if luckyChallengeData and spinData.extend ~= nil and spinData.extend.luckyChallengeV2 ~= nil then
        globalData.syncLuckyChallengeTaskData(spinData.extend.luckyChallengeV2)
    end

    local _extendData = spinData.extend
    if _extendData then
        if _extendData.highLimit ~= nil then
            globalData.syncDeluexeClubData(_extendData.highLimit)
        end

        if _extendData.levelUpPopupConfig ~= nil then
            globalData.userRunData:parseRewardOrderData(_extendData.levelUpPopupConfig)
        end

        -- if _extendData.luckyChallenge ~= nil then
        --     globalData.syncLuckyChallengeTaskData(_extendData.luckyChallenge)
        -- -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_LC_UPDATE_VIEW)
        -- end

        self:parseLeagueExtendData(_extendData)

        -- if _extendData.slotChallenge ~= nil then
        --     local SlotChallengeManager = G_GetMgr(ACTIVITY_REF.SlotChallenge)
        --     SlotChallengeManager:updateData(_extendData.slotChallenge)
        -- end

        if _extendData.diyFeature ~= nil then
            G_GetMgr(ACTIVITY_REF.DiyFeature):updateSlotData(_extendData.diyFeature)
        end

        if _extendData.diyFeatureMission ~= nil then
            G_GetMgr(ACTIVITY_REF.DIYFeatureMission):updateSlotData(_extendData.diyFeatureMission)
        end

        -- 有level奖励数据重新解析下 奖励状态(数据解析玩家等级 在 活动数据后边 所以不准确)
        if _extendData.levelRushReward ~= nil then
            gLobalLevelRushManager:reParseLevelRushPhaseReward(_extendData.levelRushReward)
        end

        -- 首充
        if _extendData.firstSale then
            G_GetMgr(G_REF.FirstCommonSale):parseData(_extendData.firstSale)
        end

        -- 更新 wildChallenge 挑战活动
        if _extendData.wildChallenge then
            G_GetMgr(ACTIVITY_REF.WildChallenge):updateTaskData(_extendData.wildChallenge)
        end

        -- 更新 头像框 slot任务数据
        if _extendData.avatarFrame then
            G_GetMgr(G_REF.AvatarFrame):updateSlotTaskData(_extendData.avatarFrame)
        end

        -- 涂色
        if _extendData.paintData then
            G_GetMgr(ACTIVITY_REF.Coloring):parseSlotPaintData(_extendData.paintData)
        end

        -- 更新 NewUser7Day 新手七日目标spin数据
        if _extendData.vegasTrip then
            G_GetMgr(G_REF.NewUser7Day):parseSlotsData(_extendData.vegasTrip)
        end
        -- 更新  比赛聚合
        if _extendData.compete then
            local battleMatchManager = G_GetMgr(ACTIVITY_REF.BattleMatch)
            if battleMatchManager then
                battleMatchManager:updateActivityData(_extendData.compete)
            end
        end

        -- spin送道具
        if _extendData.thirdData then
            G_GetMgr(ACTIVITY_REF.SpinItem):parseSlotata(_extendData.thirdData)
        end

        -- 红蓝对决
        if _extendData.factionFight then
            G_GetMgr(ACTIVITY_REF.FactionFight):parseSpinData(_extendData.factionFight)
        end

        -- 品质头像框挑战
        if _extendData.qualityAvatarFrameChallenge then
            G_GetMgr(ACTIVITY_REF.SpecialFrame_Challenge):parseSlotsData(_extendData.qualityAvatarFrameChallenge)
        end

        -- 头像框挑战
        if _extendData.avatarFrameChallenge then
            G_GetMgr(ACTIVITY_REF.FrameChallenge):parseSlotData(_extendData.avatarFrameChallenge)
        end
        if _extendData.levelDashPlus then
            G_GetMgr(ACTIVITY_REF.LevelDashPlus):setLevelDashPlusIndex(_extendData.levelDashPlus)
        end

        -- 限时促销
        if _extendData.hourDeal then
            G_GetMgr(G_REF.HourDeal):parseSpinData(_extendData.hourDeal)
        end

        if _extendData.minzData then
            local minzMgr = G_GetMgr(ACTIVITY_REF.Minz)
            if minzMgr then
                minzMgr:parseSpinData(_extendData.minzData)
            end
        end

        if _extendData.flamingoJackpot then
            G_GetMgr(ACTIVITY_REF.FlamingoJackpot):parseSpinData(_extendData.flamingoJackpot)
        end

        -- 第二货币消耗挑战
        if _extendData.gemChallengeCurrentPoints then
            G_GetMgr(ACTIVITY_REF.GemChallenge):parseSpinData(_extendData.gemChallengeCurrentPoints)
        end

        -- 返回持金极大值促销
        if _extendData.timeBack then
            G_GetMgr(ACTIVITY_REF.TimeBack):parseSlotData(_extendData.timeBack)
        end

        -- 组队打BOSS
        if _extendData.dragonChallenge then
            G_GetMgr(ACTIVITY_REF.DragonChallenge):parseSpinData(_extendData.dragonChallenge)
        end

        -- 新手三日任务
        if _extendData.noviceTrail then
            G_GetMgr(ACTIVITY_REF.NoviceTrail):spinUpdateTaskList(_extendData.noviceTrail)
        end

        -- 限时膨胀
        if _extendData.timeLimitExpansion then
            local expansionMgr = G_GetMgr(ACTIVITY_REF.TimeLimitExpansion)
            if expansionMgr then
                expansionMgr:parseData(_extendData.timeLimitExpansion)
            end
        end
        
        -- 玩家bet值小于提示bet 弹板气泡
        if _extendData.levelUpBetNotice then
            G_GetMgr(G_REF.BetUpNotice):setCurSpinBetUpShow(true)
        end

        -- 单人限时比赛
        self:parseLuckyRaceExtendData(_extendData)
        
        -- 玩家 spin更新次日礼物 任务奖池
        if _extendData.tomorrowGift then
            G_GetMgr(G_REF.TomorrowGift):updateSpinGiftData(_extendData.tomorrowGift)
        end

        -- 大R高性价比礼包促销
        if _extendData.superValue then
            local superValueData = G_GetMgr(ACTIVITY_REF.SuperValue):getData()
            if superValueData then
                superValueData:parseData(_extendData.superValue)
            end
        end

        globalMachineController:setPushGameId(_extendData.pushGameId)

        -- 新手任务
        if _extendData.newUserGuide then
            G_GetMgr(G_REF.SysNoviceTask):spinUpdateTaskInfo(_extendData.newUserGuide)
        end

        -- FrostFlameClash 数据
        if _extendData.flameClash then
            G_GetMgr(ACTIVITY_REF.FrostFlameClash):parseFrostFlameClashSpinData(_extendData.flameClash)
        end
        
        -- 亿万赢钱挑战
        if _extendData.trillionsWinnerChallenge then
            G_GetMgr(G_REF.TrillionChallenge):spinUpdateRankInfo(_extendData.trillionsWinnerChallenge)
        end

        if _extendData.goBrokeSale then
            G_GetMgr(G_REF.BrokenSaleV2):parseSpinData(_extendData.goBrokeSale)
        end
        
        -- 寻宝之旅
        if _extendData.treasureHunt then
            G_GetMgr(ACTIVITY_REF.TreasureHunt):spinUpdateLevelTaskInfo(_extendData.treasureHunt)
        end

        -- 宠物赢钱 加成信息
        if _extendData.sidekicksSpecial then
            G_GetMgr(G_REF.Sidekicks):spinWinCoinsInfo(_extendData.sidekicksSpecial)
        end
        
        -- 完成任务装饰圣诞树
        if _extendData.MissionsToDIY then
            G_GetMgr(ACTIVITY_REF.MissionsToDIY):parseSpinData(_extendData.MissionsToDIY)
        end
        
        -- 圣诞新聚合pass
        if _extendData.holidayPass then
            G_GetMgr(ACTIVITY_REF.HolidayPass):parseSpinData(_extendData.holidayPass)
        end

        -- 大赢宝箱
        if _extendData.MegaWin then
            G_GetMgr(ACTIVITY_REF.MegaWinParty):parseSpinData(_extendData.MegaWin)
        end

        -- 宠物-7日任务
        if _extendData.PetMission then
            G_GetMgr(ACTIVITY_REF.PetMission):parseSpinData(_extendData.PetMission)
        end
    end

    -- if resultData:HasField("activity") then
    --       globalData.syncActivityConfig(resultData.activity)
    -- end

    -- 有卡片掉落 --
    local bDropCard = false
    if CardSysManager:needDropCards("Random Spin") == true then
        bDropCard = true
        CardSysManager:doDropCards(
            "Random Spin",
            function()
                self:dropHighLimitSpinItems(spinData)
            end
        )
    end

    -- 有卡片掉落 link关卡 --
    if CardSysManager:needDropCards("Link Featured Game") == true then
        bDropCard = true
        CardSysManager:doDropCards(
            "Link Featured Game",
            function()
                self:dropHighLimitSpinItems(spinData)
            end
        )
    elseif CardSysManager:needDropCards("Tornado Featured Game") == true then
        bDropCard = true
        CardSysManager:doDropCards(
            "Tornado Featured Game",
            function()
                self:dropHighLimitSpinItems(spinData)
            end
        )
    end

    -- 有卡片掉落 老号直接给引导包不弹引导界面 --
    if CardSysManager:needDropCards("New Season") then
        bDropCard = true
        CardSysManager:doDropCards(
            "New Season",
            function()
                self:dropHighLimitSpinItems(spinData)
            end
        )
    end

    -- quest关卡掉nado卡 --
    if CardSysManager:needDropCards("Nado Featured Quest") then
        bDropCard = true
        CardSysManager:doDropCards(
            "Nado Featured Quest",
            function()
                self:dropHighLimitSpinItems(spinData)
            end
        )
    end

    -- 高倍场小游戏猫粮 cxc
    if not bDropCard then
        self:dropHighLimitSpinItems(spinData)
    end

    if resultData:HasField("drops") == true then
        globalData.parseItemsConfig(resultData.drops)
    end

    -- 公会 spine 更新的数据
    self:updateClanInfo(spinData)

    local resultCoins = serverCoins
    local resultGems = serverGems
    local gameModuleName = spinData.game
    if gameModuleName == nil or gameModuleName == globalData.slotRunData.gameNetWorkModuleName then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GET_SPINRESULT, {true, spinData, {resultCoins = resultCoins,resultGems = resultGems}})
    end
end

-- 解析关卡比赛奖励数据
function NetWorkSlots:parseLeagueExtendData(_extendData)
    if not _extendData then
        return
    end

    local LeagueControl = G_GetMgr(G_REF.LeagueCtrl):getOpenCtrl()
    if LeagueControl then
        LeagueControl:updateRankInLevel(_extendData)
        local _winType = _extendData.arenaWinType
        if _winType and _winType ~= "" then
            local _cupInfo = {}
            _cupInfo.cupType = _winType
            _cupInfo.addPoints = _extendData.addPoints or 0
            _cupInfo.buffMultiple = _extendData.buffMultiple or 0
            LeagueControl:onSetGainCup(_cupInfo)
        end
        LeagueControl:updateMyPoints(_extendData.myPoints)
    end
end

-- 解析关卡比赛奖励数据
function NetWorkSlots:parseSlotTrialExtendData(_extendData)
    if not _extendData or not _extendData.newSlotChallenge then
        return
    end

    local act_data = G_GetMgr(ACTIVITY_REF.SlotTrial):getRunningData()
    if not act_data then
        return
    end

    local complete_taskId = _extendData.newSlotChallengeFinishTaskIndex
    if complete_taskId and complete_taskId > 0 then
        act_data:onComplete(complete_taskId)
    end
    act_data:parseData(_extendData.newSlotChallenge)
end

-- 解析单人限时比赛数据
function NetWorkSlots:parseLuckyRaceExtendData(_extendData)
    if not _extendData then
        return
    end

    local LuckyRaceControl = G_GetMgr(ACTIVITY_REF.LuckyRace)
    if LuckyRaceControl and _extendData.luckyRace then
        LuckyRaceControl:parseLuckyRaceSpinData(_extendData.luckyRace)
    end
end

--- 失败回调
function NetWorkSlots:spinResultFaildCallFun(errorCode, errorData)
    globalData.slotRunData.gameEffStage = GAME_EFFECT_OVER_STATE
    globalData.slotRunData.spinNetState = GAME_EFFECT_OVER_STATE
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GET_SPINRESULT, {false, errorCode, errorData})
end

--[[
    @desc: lucky spin 老虎机 请求数据
    author:{author}
    time:2019-09-26 17:50:27
    --@slotName:
    @return:
]]
function NetWorkSlots:sendActionData_LuckySpin(betCoin, currentCoins, winCoin, isFreeSpin, slotName, bLevelUp, nextLevel, nextProVal, messageData, isShowTournament)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actType = nil

    self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    self.levelName = slotName

    if messageData and type(messageData) == "table" then
        if messageData.msg == MessageDataType.MSG_LUCKY_SPIN then
            actType = ActionType.LuckSpinAward
        elseif messageData.msg == MessageDataType.MSG_LUCKY_SPIN_ENJOY then
            actType = ActionType.LuckySpinV2Enjoy -- luck spin 小老虎机先享后付费
        elseif messageData.msg == MessageDataType.MSG_LUCKY_SPINV2 then
            actType = ActionType.LuckySpinV2Spin
        end
    end

    local actionData = self:getSendActionData(actType, slotName)

    actionData.data.betCoins = 0
    actionData.data.betGems = 0
    actionData.data.winCoins = 0
    actionData.data.balanceCoins = 0
    actionData.data.balanceCoinsNew = get_integer_string(currentCoins)
    actionData.data.balanceGems = 0
    actionData.data.freespin = isFreeSpin
    actionData.data.exp = 0
    actionData.data.addExp = 0
    actionData.data.levelup = bLevelUp
    actionData.data.level = nextLevel
    actionData.data.betId = 0

    actionData.data.version = self:getVersionNum()

    -- local extraData = {}
    -- actionData.data.extra = cjson.encode(extraData)

    -- local paramsData = {}

    -- actionData.data.params = json.encode(paramsData)

    self:sendMessageData(actionData, self.luckySpinResultSuccessCallFun, self.spinResultFaildCallFun)
end

--- 成功回调
function NetWorkSlots:luckySpinResultSuccessCallFun(resultData)
    --dump(resultData,"spin回调的数据")

    local result = resultData.result

    local mission = resultData.mission
    -- 存储一下网络数据
    globalData.slotRunData.severGameJsonData = result

    local spinData = cjson.decode(result)
    local serverCoins = globalData.userRunData.coinNum
    if resultData:HasField("user") then
        local userData = resultData.user
        globalData.syncSimpleUserInfo(userData)
        -- serverCoins = tonumber(userData.coins)
        serverCoins = toLongNumber(userData.coinsV2)
    end

    local resultCoins = serverCoins
    local gameModuleName = spinData.game
    if gameModuleName == nil or gameModuleName == globalData.slotRunData.gameNetWorkModuleName then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GET_LUCKY_SPINRESULT, {true, spinData, {resultCoins = resultCoins}})
    end
end

---
-- 进入关卡请求上次保存数据
--
function NetWorkSlots:sendActionDataWithEnterGame(slotName)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()
    self.levelName = slotName
    local actionType = nil
    actionType = ActionType.GetGameStatusV2

    local str = "进入关卡发送消息时间:"..self.startSpinTime..";关卡名字:"..self.levelName
    release_print("NetWorkSlots-enterGame", str)

    if globalData.slotRunData.isDeluexeClub == true then
        self.levelName = self.levelName .. "_H"
        actionType = ActionType.HighLimitGetGameStatus
    end

    local actionData = self:getSendActionData(actionType, self.levelName)
    local lastCoin = globalData.userRunData.coinNum

    actionData.data.betCoins = 0
    actionData.data.betGems = 0

    actionData.data.balanceCoins = 0
    actionData.data.balanceCoinsNew = get_integer_string(lastCoin)
    local currProVal = globalData.userRunData.currLevelExper
    actionData.data.exp = currProVal
    actionData.data.level = globalData.userRunData.levelNum
    actionData.data.version = self:getVersionNum()

    local extraData = {}
    extraData[ExtraType.spinAccumulation] = globalData.spinAccumulation or {["time"] = os.time(), ["amount"] = 0}

    --是否是quest关卡
    local entryStatus = "Normal"
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.m_IsQuestLogin then
        if questConfig:isNewUserQuest() then
            entryStatus = "NewQuest"
        else
            if questConfig:getThemeName() == "Activity_QuestIsland" then
                entryStatus = "islandQuestGame"
            else
                entryStatus = "QuestGame"
            end
        end
    end
    if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest() then
        entryStatus = "QuestGame"
    end
    extraData["entryStatus"] = entryStatus

    actionData.data.extra = cjson.encode(extraData)

    --quest活动
    local params = {}
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil and questConfig:isRunning() then
        params["quest"] = questConfig.m_IsQuestLogin
        actionData.data.params = json.encode(params)
    end

    if G_GetMgr(ACTIVITY_REF.QuestNew):isEnterGameFromQuest() then
        params["quest"] = true
        local chapterId = G_GetMgr(ACTIVITY_REF.QuestNew):getEnterGameChapterIdAndPointId()
        if chapterId then
            params["playGamePhase"] = chapterId
        end
        actionData.data.params = json.encode(params)
    end
    
    self:sendMessageData(actionData, self.enterGameSuccessCallFun, self.enterGameFaildCallFun)
end
--- 成功回调
function NetWorkSlots:enterGameSuccessCallFun(resultData)
    local endTime = xcyy.SlotsUtil:getMilliSeconds()
    local str = "进入关卡发送消息时间:"..self.startSpinTime..";收到消息时间:"..endTime..";关卡名字:"..self.levelName
    release_print("NetWorkSlots-enterGame", str)

    local _levelName = self.levelName or ""
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GETGAMESTATUS, {true, resultData, _levelName})
end
--- 失败回调
function NetWorkSlots:enterGameFaildCallFun(errorCode)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_GETGAMESTATUS, {false, errorCode, ""})
end

function NetWorkSlots:sendActionData_DeluxeClubCoin()
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actType = ActionType.HighLimitCollectCoin

    self.startSpinTime = xcyy.SlotsUtil:getMilliSeconds()

    local actionData = self:getSendActionData(actType)

    actionData.data.betCoins = 0
    actionData.data.betGems = 0
    actionData.data.winCoins = 0
    actionData.data.balanceCoins = 0
    actionData.data.balanceGems = 0
    actionData.data.freespin = false
    actionData.data.exp = 0
    actionData.data.addExp = 0
    actionData.data.levelup = false
    actionData.data.betId = 0

    actionData.data.version = self:getVersionNum()

    self:sendMessageData(actionData, self.spinResultSuccessCallFun, self.spinResultFaildCallFun)
end

--请求shop、vip、cashbonus数据
function NetWorkSlots:sendRequestShopInfo(configList, successCallbackFunc, failedCallbackFunc)
    if gLobalSendDataManager:isLogin() == false or configList == nil or #configList == 0 then
        return
    end

    local commonRequest = GameProto_pb.CommonConfigRequest()
    commonRequest.udid = globalData.userRunData.userUdid
    for k, v in ipairs(configList) do
        commonRequest.configs:append(v)
    end

    local offset = self:getOffsetValue()
    local token = globalData.userRunData.loginUserData.token
    local serverTime = globalData.userRunData.p_serverTime
    local url = DATA_SEND_URL .. RUI_INFO.QUERY_COMMONCONFIG -- 拼接url 地址

    local httpSender = xcyy.HttpSender:createSender()
    local bodyData = commonRequest:SerializeToString()
    httpSender:sendMessage(
        bodyData,
        offset,
        token,
        url,
        serverTime,
        function(strResponse, strHeaders)
            httpSender:release()
            local commonCfg = BaseProto_pb.CommonConfig()
            local responseStr = self:parseResponseData(strResponse)
            commonCfg:ParseFromString(responseStr)
            globalData.syncUserConfig(commonCfg)
            if successCallbackFunc then
                successCallbackFunc()
            end
        end,
        function(code, codeData)
            httpSender:release()
            if failedCallbackFunc then
                failedCallbackFunc()
            end
        end
    )
end

-- 掉落高倍场小游戏猫粮 cxc
function NetWorkSlots:dropHighLimitSpinItems(_spinData)
    if not _spinData or not _spinData.extend then
        return
    end

    local shopItemDataList = {}
    local ShopItem = util_require("data.baseDatas.ShopItem")

    -- spin后会掉落 猫粮 道具
    local highLimitSpin = _spinData.extend.highLimitSpin or {}
    if next(highLimitSpin) then
        for k, data in pairs(highLimitSpin) do
            local shopItem = ShopItem:create()
            shopItem:parseData(data, true)
            table.insert(shopItemDataList, shopItem)
        end
    end

    -- spin后升级了 会掉落 猫粮 道具
    local highLimitLevelUp = _spinData.extend.highLimitLevelUp or {}
    if next(highLimitLevelUp) then
        for k, data in pairs(highLimitLevelUp) do
            local shopItem = ShopItem:create()
            shopItem:parseData(data, true)
            table.insert(shopItemDataList, shopItem)
        end
    end
    local isForMerge = false
    if _spinData.extend.highLimitMerge then
        local highLimitMerge_spinDorpItem = _spinData.extend.highLimitMerge.spinDropItem or {}
        if next(highLimitMerge_spinDorpItem) then
            isForMerge = true
            for k, data in pairs(highLimitMerge_spinDorpItem) do
                local shopItem = ShopItem:create()
                shopItem:parseData(data, true)
                table.insert(shopItemDataList, shopItem)
            end
        end
    end

    if not next(shopItemDataList) then
        return
    end
    if isForMerge then
        -- 展示掉落的panel
        local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
        mergeManager:popMergePropsBagRewardPanel(shopItemDataList, nil, true)

        -- 同步最新活动数据
        local bags = _spinData.extend.highLimitMerge.bags or {}
        if next(bags) then
            mergeManager:refreshBagsData(bags)
        end
    else
        -- 展示掉落的panel
        local catManager = G_GetMgr(ACTIVITY_REF.DeluxeClubCat)
        catManager:popCatFoodRewardPanel(shopItemDataList, nil, true)

        -- 同步最新活动数据
        local highLimitActivity = _spinData.extend.highLimitActivity or {}
        if next(highLimitActivity) then
            globalData.commonActivityData:parseActivityData(highLimitActivity, ACTIVITY_REF.DeluxeClubCat)
        end
    end
end

-- 关卡内spine 更新公会任务
function NetWorkSlots:updateClanInfo(_spinData)
    if not _spinData or not _spinData.extend then
        return
    end

    local clanPointsSpin = _spinData.extend.clanPointsSpin
    if not clanPointsSpin then
        return
    end

    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    ClanManager:updateClanMyPointsValue(clanPointsSpin)
    ClanManager:updateEntryProgUI()
end

--[[
    发送退出房间消息
]]
function NetWorkSlots:sendActionData_ExitRoom()
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actType = ActionType.TeamMissionQuit
    --关卡名
    local levelName = globalData.slotRunData.gameNetWorkModuleName
    --高倍场判断
    if globalData.slotRunData.isDeluexeClub == true then
        if string.find(levelName, "_H") == nil then
            levelName = levelName .. "_H"
        end
    end

    local actionData = self:getSendActionData(actType, levelName)

    local paramsData = {}
    paramsData.spinSessionId = gL_logData:getGameSessionId()
    actionData.data.params = json.encode(paramsData)

    actionData.data.betCoins = 0
    actionData.data.betGems = 0
    actionData.data.winCoins = 0
    actionData.data.balanceCoins = 0
    actionData.data.balanceGems = 0
    actionData.data.freespin = false
    actionData.data.exp = 0
    actionData.data.addExp = 0
    actionData.data.levelup = false
    actionData.data.betId = 0

    actionData.data.version = self:getVersionNum()

    self:sendMessageData(actionData, self.spinResultSuccessCallFun, self.spinResultFaildCallFun)
end
function NetWorkSlots:sendWaitTimeMoreLog()
    gLobalSendDataManager:getLogSlots():sendTimeOutLog()
end
return NetWorkSlots
