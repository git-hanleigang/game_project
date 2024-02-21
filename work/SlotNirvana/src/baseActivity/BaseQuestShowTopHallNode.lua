--展示图
local BaseQuestShowTopHallNode = class("BaseQuestShowTopHallNode", util_require("views.lobby.HallNode"))
BaseQuestShowTopHallNode.m_rankPoolCoin = nil
BaseQuestShowTopHallNode.JackpotTimer = nil

function BaseQuestShowTopHallNode:initUI(data)
    BaseQuestShowTopHallNode.super.initUI(self, data)

    schedule(
        self,
        function()
            if self.isClose then
                return
            end
            self:updateTime()
        end,
        1
    )
end

function BaseQuestShowTopHallNode:initCsbNodes()
    self.m_JackpotLabel = self:findChild("BitmapFontLabel_2")

    self.m_nodeJp = self:findChild("nodeJp")
    self.m_spNoRank = self:findChild("spNoRank")

    self.m_bingoRankLabel = self:findChild("BitmapFontLabel_3")
end

function BaseQuestShowTopHallNode:initView()
    self.m_bingoRankLabel:setString("NO RANK")

    self:hideJpNode()

    self.JackpotTimer = nil
    self.m_rankPoolCoin = nil

    self:sendQuryRankDate()
end

function BaseQuestShowTopHallNode:updateView()
    if self.m_data == nil then
        return
    end

    self:updateTime()
    self:updateRankNum()
end

function BaseQuestShowTopHallNode:hideJpNode()
    self.m_nodeJp:setVisible(false)
    self.m_spNoRank:setVisible(true)
end

function BaseQuestShowTopHallNode:showJpNode()
    self.m_nodeJp:setVisible(true)
    self.m_spNoRank:setVisible(false)
end

function BaseQuestShowTopHallNode:updateTime()
    local config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    local leftTime = 0
    if config then
        leftTime = config:getLeftTime()
    end
    local strTime = util_daysdemaining1(leftTime, "DAYS LEFT")
    self:findChild("BitmapFontLabel_1"):setString(strTime)
    self:updateLabelSize({label = self:findChild("BitmapFontLabel_1")}, 120)
end

function BaseQuestShowTopHallNode:getJPCoinsByTime()
    local coins, jpPool, jpLastLoginTime = 0, 0, 0
    local jpPool, jpLastLoginTime, lastBeginRunCoins = self:getData()

    if lastBeginRunCoins ~= 0 then
        coins = lastBeginRunCoins
    end

    return coins
end

function BaseQuestShowTopHallNode:saveData(times, pool, beginCoins)
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.p_expireAt then
        gLobalDataManager:setNumberByField("chinese_quest_jp_beginCoins" .. questConfig.p_expireAt, beginCoins)
    end
end

function BaseQuestShowTopHallNode:getData()
    local jpPool, jpLastLoginTime = 0, 0
    local beginCoins = 0
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.p_expireAt then
        beginCoins = gLobalDataManager:getNumberByField("chinese_quest_jp_beginCoins" .. questConfig.p_expireAt, beginCoins)
    end
    return jpPool, jpLastLoginTime, beginCoins
end

function BaseQuestShowTopHallNode:getRateInfo(pool)
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

function BaseQuestShowTopHallNode:getBeginRunCoins(baseCoin)
    local beginRunCoins = 0
    if globalData.questJackpotCoins == 0 then
        local coins = self:getJPCoinsByTime()

        if coins <= baseCoin then
            beginRunCoins = baseCoin
        else
            beginRunCoins = coins
        end
    else
        beginRunCoins = globalData.questJackpotCoins
    end
    return beginRunCoins
end

function BaseQuestShowTopHallNode:updateJackPot()
    --获取上次登录的时间
    local baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd = self:getRateInfo(self.m_rankPoolCoin)

    local perAddCount = 0
    local perAdd1 = perAdd * 0.08
    local perAdd2 = topMaxperAdd * 0.08
    self:showJpNode()
    self.m_jackpotCurCoin = self:getBeginRunCoins(baseCoin)
    self.m_JackpotLabel:setString(util_formatMoneyStr(tostring(math.ceil(self.m_jackpotCurCoin))))

    self:updateLabelSize({label = self.m_JackpotLabel}, 190)
    globalData.questJackpotCoins = self.m_jackpotCurCoin

    if self.JackpotTimer then
        self:stopAction(self.JackpotTimer)
    end

    self.JackpotTimer =
        schedule(
        self.m_JackpotLabel,
        function()
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

            self:showJpNode()
            globalData.questJackpotCoins = self.m_jackpotCurCoin
            --  self.m_JackpotLabel:setString(util_formatCoins(math.ceil(self.m_jackpotCurCoin), 10))
            self.m_JackpotLabel:setString(util_formatMoneyStr(tostring(math.ceil(self.m_jackpotCurCoin))))
            self:updateLabelSize({label = self.m_JackpotLabel}, 190)
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

function BaseQuestShowTopHallNode:updateRankNum()
    local config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not config then
        self:hideJpNode()
        return
    end
    local rankConfig = config:getRankCfg()

    if not rankConfig then
        self:hideJpNode()
        return
    end

    local rankNum = rankConfig.p_myRank.p_rank
    if rankNum == 0 then
        rankNum = "NO RANK"
    else
        rankNum = "RANK: " .. rankNum
    end

    self.m_bingoRankLabel:setString(rankNum)

    --刷新金币池
    self.m_rankPoolCoin = rankConfig.p_prizePool
    -- self:findChild("BitmapFontLabel_2"):setString(util_formatCoins(self.m_rankPoolCoin, 10))
    self:findChild("BitmapFontLabel_2"):setString(util_formatMoneyStr(tostring(math.ceil(self.m_rankPoolCoin))))
    self:updateLabelSize({label = self:findChild("BitmapFontLabel_2")}, 190)
    self:updateJackPot()
end

function BaseQuestShowTopHallNode:sendQuryRankDate()
    gLobalNoticManager:addObserver(
        self,
        function(self, rankData)
            if not tolua.isnull(self) then
                self:updateRankNum()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_RANK
    )

    --请求quest排行数据
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestRank()
end

function BaseQuestShowTopHallNode:onExit()
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

return BaseQuestShowTopHallNode
