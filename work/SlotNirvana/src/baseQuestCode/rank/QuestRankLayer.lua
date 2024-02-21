-- Created by jfwang on 2019-05-21.
-- Quest排行榜界面
--
local BaseRankUI = util_require("baseActivity.BaseRankUI")
local QuestRankLayer = class("QuestRankLayer", BaseRankUI)

-- function QuestRankLayer:ctor()
--     QuestRankLayer.super.ctor(self)

--     self:mergePlistInfos(QUEST_PLIST_PATH.QuestRankLayer)
-- end

-- 规则介绍界面
function QuestRankLayer:getRankRulePath()
    return QUEST_CODE_PATH.QuestRuleView
end
function QuestRankLayer:getCsbName()
    return QUEST_RES_PATH.QuestRankLayer
end
function QuestRankLayer:getActivityRefName()
    return ACTIVITY_REF.Quest
end
function QuestRankLayer:sendRankRequestAction()
    QuestRankLayer.super.sendRankRequestAction(self)
    gLobalSendDataManager:getNetWorkFeature():sendActionQuestRank()
end
function QuestRankLayer:getRankCfg()
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig ~= nil then
        return questConfig:getRankCfg()
    end
    return nil
end
function QuestRankLayer:getCellWidth()
    return 904
end
function QuestRankLayer:getCellHeight()
    return 78
end
function QuestRankLayer:getSelfTopCellOffset()
    return 0, 6
end
function QuestRankLayer:getSelfBottomCellOffset()
    return 0, -1
end
-- 固定显示的父节点
function QuestRankLayer:getFixedParent()
    return self:findChild("node_fixed")
end
function QuestRankLayer:initView()
    BaseRankUI.initView(self)
    for i = 1, #self.m_tabList do
        local tab_btn = self.m_tabList[i]
        self:addClick(tab_btn)
    end
    self.m_spBtnList = {}
    for i = 1, 3 do
        self.m_spBtnList[i] = self:findChild("sp_btn" .. i)
        self.m_spBtnList[i]:setVisible(false)
    end
    self.m_lb_coins = self:findChild("m_lb_coins")
    self.m_sp_noRank = self:findChild("spNoRank")
    self.m_sp_coins = self:findChild("sp_coins")
    self.m_sp_noRankStr = self:findChild("sp_noRankStr")

    local rankConfig = self:getRankCfg()
    if rankConfig then
        self:showJpNode()
        self.m_rankConfig = rankConfig
        -- 刷新金币池
        self:updateRankPol()
    else
        self:hideJpNode()
    end
end

function QuestRankLayer:hideJpNode()
    self.m_sp_coins:setVisible(false)
    self.m_sp_noRank:setVisible(true)
    self.m_lb_coins:setVisible(false)
    self.m_sp_noRankStr:setVisible(true)
end

function QuestRankLayer:showJpNode()
    self.m_lb_coins:setVisible(true)
    self.m_sp_noRank:setVisible(false)
    self.m_sp_coins:setVisible(true)
    self.m_sp_noRankStr:setVisible(false)
end

function QuestRankLayer:initTableView()
    BaseRankUI.initTableView(self)
    local rank_fenge_bg_1 = self.m_tabViewTopCell:findChild("rank_fenge_bg_1")
    rank_fenge_bg_1:setVisible(false)
    local rank_fenge_bg_2 = self.m_tabViewBoomCell:findChild("rank_fenge_bg_1")
    rank_fenge_bg_2:setVisible(false)
    -- 切换到裁切层中
    local node_clipReward = self:findChild("node_clipReward")
    local sp_rewardBg = self:findChild("sp_rewardBg")
    local stencil = display.newSprite("QuestOther/questrank2mask.png")
    stencil:setContentSize(sp_rewardBg:getContentSize())
    local clipNode = cc.ClippingNode:create()
    clipNode:setAlphaThreshold(0.95)
    clipNode:setStencil(stencil)
    node_clipReward:addChild(clipNode)
    util_changeNodeParent(clipNode, self.m_rewardListView)
    -- 时钟
    local node_time = self:findChild("node_time")
    local actTime = util_createAnimation(QUEST_RES_PATH.QuestRankTime)
    actTime:runCsbAction("turn", true)
    node_time:addChild(actTime)
    self.m_rewardListView:setBounceEnabled(true)
    self.m_userListView:setBounceEnabled(true)
    -- 隐藏第三页
    self.m_accountNode = self:findChild("accountNode")
    if self.m_accountNode then
        self.m_accountNode:setVisible(false)
    end
end

function QuestRankLayer:initTitleUI()
end
function QuestRankLayer:getCellLuaName(index)
    return string.format("baseQuestCode.rank.QuestRankCell%d", index)
end
function QuestRankLayer:getTopCellLuaName()
    return "baseQuestCode.rank.QuestRankTopCellUI"
end
function QuestRankLayer:getGameData()
    return G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
end
-- 返回数据后，刷新界面
function QuestRankLayer:updateView(forceRefesh)
    BaseRankUI.updateView(self, forceRefesh)
    self.m_rankConfig = self:getRankCfg()
    -- 刷新金币池
    self:updateRankPol()
end
-- 点击tab按钮
function QuestRankLayer:updateBaseTitle(index)
    for i = 1, #self.m_spBtnList do
        self.m_spBtnList[i]:setVisible(i == index)
    end
    self:setTopThreeUIVisible(index == 1)
end
function QuestRankLayer:onTabClick(index, refreshRankFlag)
    if index == 3 then
        return
    end
    BaseRankUI.onTabClick(self, index, refreshRankFlag)
end

function QuestRankLayer:getJPCoinsByTime()
    local coins, jpPool, jpLastLoginTime = 0, 0, 0
    local jpPool, jpLastLoginTime, lastBeginRunCoins = self:getData()
    if lastBeginRunCoins ~= 0 then
        coins = lastBeginRunCoins
    end
    return coins
end
function QuestRankLayer:saveData(times, pool, beginCoins)
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.p_expireAt then
        gLobalDataManager:setNumberByField("chinese_quest_jp_beginCoins" .. questConfig.p_expireAt, beginCoins)
    end
end
function QuestRankLayer:getData()
    local jpPool, jpLastLoginTime = 0, 0
    local beginCoins = 0
    local questConfig = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if questConfig and questConfig.p_expireAt then
        beginCoins = gLobalDataManager:getNumberByField("chinese_quest_jp_beginCoins" .. questConfig.p_expireAt, beginCoins)
    end
    return jpPool, jpLastLoginTime, beginCoins
end
function QuestRankLayer:getRateInfo(pool)
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
function QuestRankLayer:getBeginRunCoins(baseCoin)
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
function QuestRankLayer:updateRankPol()
    if self.JackpotTimer then
        return
    end
    local rankConfig = self:getRankCfg()
    if not rankConfig then
        self:hideJpNode()
        return
    end
    self.m_rankConfig = rankConfig
    local baseCoin, maxCoin, perAdd, topMaxCoin, topMaxperAdd = self:getRateInfo(self.m_rankConfig.p_prizePool)
    self.m_jackpotCurCoin = self:getBeginRunCoins(baseCoin)
    -- self.m_lb_coins:setString(util_formatCoins(self.m_jackpotCurCoin, 19))
    self:showJpNode()

    self.m_lb_coins:setString(util_formatMoneyStr(tostring(math.ceil(self.m_jackpotCurCoin))))
    self:updateLabelSize(
        {
            label = self.m_lb_coins
        },
        580
    )
    local width = math.min(580, self.m_lb_coins:getContentSize().width) * 0.5
    local posx, posy = self.m_lb_coins:getPosition()
    local sp_coins = self:findChild("sp_coins")
    sp_coins:setPositionX(posx - width - 40)

    globalData.questJackpotCoins = self.m_jackpotCurCoin
    local perAddCount = 0
    local perAdd1 = perAdd * 0.08
    local perAdd2 = topMaxperAdd * 0.08
    self.JackpotTimer =
        schedule(
        self.m_lb_coins,
        function()
            -- 判断更新增量
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
                self:stopAction(self.JackpotTimer)
            end
            globalData.questJackpotCoins = self.m_jackpotCurCoin
            -- self.m_lb_coins:setString(util_formatCoins(math.ceil(self.m_jackpotCurCoin), 19))
            self.m_lb_coins:setString(util_formatMoneyStr(tostring(math.ceil(self.m_jackpotCurCoin))))
            self:updateLabelSize(
                {
                    label = self.m_lb_coins
                },
                580
            )
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
-- 显示规则
function QuestRankLayer:showRuleView()
    local uiView = util_createFindView(self:getRankRulePath())
    if uiView ~= nil then
        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():addNodeDot(uiView, "btn_rule", DotUrlType.UrlName, false)
        end
        gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    end
end
function QuestRankLayer:onKeyBack()
    self:closeUI()
end
function QuestRankLayer:clickFunc(sender)
    BaseRankUI.clickFunc(self, sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "btn_close" then
        -- gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
        sender:setTouchEnabled(false)
        self:closeUI()
    elseif name == "btn_rule" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        sender:setTouchEnabled(false)
        performWithDelay(
            self,
            function()
                sender:setTouchEnabled(true)
            end,
            0.2
        )
        self:showRuleView()
    end
end
function QuestRankLayer:closeUI()
    if self.isClose then
        return
    end
    self.isClose = true
    self:runCsbAction(
        "over",
        false,
        function()
            if self.JackpotTimer then
                self:stopAction(self.JackpotTimer)
                self.JackpotTimer = nil
            end

            if self.jpSaveSchedule then
                self:stopAction(self.jpSaveSchedule)
                self.jpSaveSchedule = nil
            end
            self:removeFromParent()
        end,
        60
    )
end

return QuestRankLayer
