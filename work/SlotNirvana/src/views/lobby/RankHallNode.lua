-- 排行榜广告页

local RankHallNode = class("RankHallNode", util_require("views.lobby.HallNode"))

function RankHallNode:initUI(data)
    RankHallNode.super.initUI(self, data)
    self:updateRemoveSelf(data)
end

function RankHallNode:initCsbNodes()
    self.lb_coin = self:findChild("lb_CoinNum")
    assert(self.lb_coin, "RankHallNode lb_CoinNum 必要的节点缺失")
    self.lb_rank = self:findChild("lb_Rank")
end

function RankHallNode:initView()
    self.JackpotTimer = nil
    self.m_rankPoolCoin = nil

    self:runCsbAction("idle", true, nil, 30)

    self:sendQuryRankDate()

    local activityConfig = self:getActivityConfig()
    if not activityConfig or not activityConfig.p_expire or activityConfig.p_expire <= 0 then
        self.lb_coin:setString("0")
        self.lb_rank:setString("NO RANK")
        return
    end

    -- 没有排行榜数据 再次请求
    self:sendActionWordRank()
end

function RankHallNode:updateView()
    self:updateRankNum()
end

function RankHallNode:updateRemoveSelf(data)
    if data and self.m_data then
        schedule(
            self,
            function()
                if tolua.isnull(self) then
                    return
                end
                self.m_data.p_expire = self.m_data.p_expire - 1
                if self.m_data.p_expire <= 0 then
                    self.m_data.p_expire = 0
                    if data.key and data.key ~= "" then
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_CLOSE, data.key)
                    end
                end
            end,
            1
        )
    end
end

-- function RankHallNode:updateTime()
--     local config = self:getActivityConfig()
--     local strTime = util_daysdemaining1(config.p_expire,"DAYS LEFT")
--     self:findChild("BitmapFontLabel_1"):setString(strTime)
-- end

function RankHallNode:getActivityConfig()
    return G_GetMgr(ACTIVITY_REF.Word):getRunningData()
end

function RankHallNode:getRankCfg()
    local wordData = self:getActivityConfig()
    if wordData then
        return wordData.wordRankConfig
    end
    return nil
end

-- function RankHallNode:getRankHelpName()
--     return "Activity/BingoGame/BingoRuleView"
-- end

function RankHallNode:getJackpotBeginCoinKey()
    return "blast_jackpot_beginCoin"
end

function RankHallNode:getJPCoinsByTime()
    local coins, jpPool, jpLastLoginTime = 0, 0, 0
    local jpPool, jpLastLoginTime, lastBeginRunCoins = self:getData()

    if lastBeginRunCoins ~= 0 then
        coins = lastBeginRunCoins
    end

    return coins
end

function RankHallNode:saveData(times, pool, beginCoins)
    local activityConfig = self:getActivityConfig()
    if activityConfig and activityConfig.getExpireAt ~= nil and activityConfig:getExpireAt() then
        gLobalDataManager:setNumberByField(self:getJackpotBeginCoinKey() .. tostring(activityConfig:getExpireAt()), beginCoins)
    end
end

function RankHallNode:getData()
    local jpPool, jpLastLoginTime = 0, 0
    local beginCoins = 0
    local activityConfig = self:getActivityConfig()
    if activityConfig ~= nil and activityConfig.getExpireAt ~= nil and activityConfig:getExpireAt() then
        beginCoins = gLobalDataManager:getNumberByField(self:getJackpotBeginCoinKey() .. tostring(activityConfig:getExpireAt()), beginCoins)
    end
    return jpPool, jpLastLoginTime, beginCoins
end

function RankHallNode:getRateInfo(pool)
    local bottomRate = globalData.constantData.QUEST_JACKPOT_POOL_BOTTOM or 1
    local topRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP or 1
    local perRate = globalData.constantData.QUEST_JACKPOT_POOL_ADD or 0
    local topMaxRate = globalData.constantData.QUEST_JACKPOT_POOL_TOP_MAX or 1
    local topMaxSpeed = globalData.constantData.QUEST_JACKPOT_POOL_TOP_SPEED_MAX or 0

    local baseCoin = pool * bottomRate
    local maxCoin = pool * topRate
    local perAdd = pool * perRate
    local topMaxCoin = pool * topMaxRate
    local topMaxperAdd = pool * topMaxSpeed
    return baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd
end

function RankHallNode:getBeginRunCoins(baseCoin)
    local wordData = self:getActivityConfig()
    if not wordData then
        return baseCoin
    end

    local beginRunCoins = wordData:getRankJackpotCoins()
    local coins = self:getJPCoinsByTime()
    if coins <= baseCoin then
        beginRunCoins = baseCoin
    else
        beginRunCoins = coins
    end
    return beginRunCoins
end

function RankHallNode:updateJackPot()
    --获取上次登录的时间
    local baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd = self:getRateInfo(self.m_rankPoolCoin)

    local perAddCount = 0
    local perAdd1 = perAdd * 0.08
    local perAdd2 = topMaxperAdd * 0.08
    self.m_jackpotCurCoin = self:getBeginRunCoins(baseCoin)
    self.lb_coin:setString(util_formatMoneyStr(tostring(math.ceil(self.m_jackpotCurCoin))))

    self:updateLabelSize({label = self.lb_coin}, 190)
    local wordData = self:getActivityConfig()
    if not wordData then
        return
    end
    wordData:setRankJackpotCoins(self.m_jackpotCurCoin)
    if self.JackpotTimer then
        self:stopAction(self.JackpotTimer)
    end

    self.JackpotTimer =
        schedule(
        self.lb_coin,
        function()
            local wordData = self:getActivityConfig()
            if not wordData then
                -- 活动过期
                self.lb_coin:stopAllActions()
                return
            end
            --判断更新增量
            if self.m_jackpotCurCoin <= maxCoin then
                if perAddCount ~= perAdd1 then
                    perAddCount = perAdd1
                end
            elseif self.m_jackpotCurCoin < topMaxCoin then
                if perAddCount ~= perAdd2 then
                    perAddCount = perAdd2
                end
            end

            self.m_jackpotCurCoin = perAddCount + self.m_jackpotCurCoin

            if self.m_jackpotCurCoin >= topMaxCoin then
                self.m_jackpotCurCoin = topMaxCoin
            end

            wordData:setRankJackpotCoins(self.m_jackpotCurCoin)
            self.lb_coin:setString(util_formatMoneyStr(tostring(math.ceil(self.m_jackpotCurCoin))))
            self:updateLabelSize({label = self.lb_coin}, 190)
        end,
        0.08
    )

    self:saveData(socket.gettime(), self.m_rankPoolCoin, self.m_jackpotCurCoin)

    self.jpSaveSchedule =
        schedule(
        self,
        function()
            self:saveData(socket.gettime(), self.m_rankPoolCoin, self.m_jackpotCurCoin)
        end,
        5
    )
end

function RankHallNode:updateRankNum()
    local rankConfig = self:getRankCfg()
    if not rankConfig then
        self.lb_coin:setString("0")
        self.lb_rank:setString("NO RANK")
        return
    end

    local rankNum = rankConfig.p_myRank.p_rank
    local rankStr = ""
    if rankNum == 0 then
        rankStr = "NO RANK"
    else
        rankStr = "RANK:" .. rankNum
    end

    self.lb_rank:setString(rankStr)
    self.lb_coin:setVisible(true)
    --刷新金币池
    local rankConfig = self:getRankCfg()
    self.m_rankPoolCoin = rankConfig.p_prizePool
    self.lb_coin:setString(util_formatMoneyStr(tostring(math.ceil(self.m_rankPoolCoin))))
    self:updateLabelSize({label = self.lb_coin}, 190)
    self:updateJackPot()
end

function RankHallNode:sendQuryRankDate()
    --获取排行信息
    gLobalNoticManager:addObserver(
        self,
        function(self, param)
            if param and param.refName == ACTIVITY_REF.Word then
                if not tolua.isnull(self) then
                    self:updateRankNum()
                end
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH
    )
end

function RankHallNode:sendActionWordRank()
    --请求word排行数据
    if util_IsFileExist("Activity/BlastGame/BlastManager.lua") or util_IsFileExist("Activity/BlastGame/BlastManager.luac") then
        G_GetMgr(ACTIVITY_REF.Blast):getRank()
    end
end

function RankHallNode:onExit()
    gLobalNoticManager:removeAllObservers(self)

    self:saveData(socket.gettime(), self.m_rankPoolCoin, self.m_jackpotCurCoin)
    if self.JackpotTimer then
        self:stopAction(self.JackpotTimer)
        self.JackpotTimer = nil
    end

    if self.jpSaveSchedule then
        self:stopAction(self.jpSaveSchedule)
        self.jpSaveSchedule = nil
    end
end

return RankHallNode
