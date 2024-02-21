--大地图上的标题节点
local QuestLobbyTitle = class("QuestLobbyTitle", util_require("base.BaseView"))

function QuestLobbyTitle:getCsbNodePath()
    return QUEST_RES_PATH.QuestLobbyTitile
end

function QuestLobbyTitle:initUI(data)
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self:createCsbNode(self:getCsbNodePath())
    self:initView()
    self:updatePhaseReward()
    self:initSpecialClanBuffNode()
    self:updataTime()
    self:createJackpotCoinsNode()
end

function QuestLobbyTitle:getLanguageTableKeyPrefix()
    local theme = self.m_config:getThemeName()
    return theme .. "Title"
end

function QuestLobbyTitle:updataTime()
    self:updateLeftTime()
    self.m_leftTimeScheduler = schedule(self, handler(self, self.updateLeftTime), 1)
end

function QuestLobbyTitle:updateLeftTime()
    local nMuti = 0
    local buffInfo = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
    if buffInfo then
        nMuti = tonumber(buffInfo.buffMultiple) or 0
    end

    local buffInfo_1 = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_QUESTICONS_MORE)
    if buffInfo_1 then
        nMuti = nMuti + (tonumber(buffInfo_1.buffMultiple) -1) * 100
    end
    if self.m_nMuti_init ~= nMuti then
        self.m_nMuti_init = nMuti 
        self:updatePhaseReward()
    end
    local hasDiscount = self.m_config:hasDiscount()
    if nMuti == 0 then
        if self.lb_coins_base:isVisible() and not hasDiscount then
            self.lb_coins_base:setVisible(false)
        end
    end
end

function QuestLobbyTitle:initView()
    self:runCsbAction("sweep", true)

    self.sp_more = self:findChild("sp_more")
    self.sp_more:setVisible(false)

    self.lb_coins_base = self:findChild("lb_coins_base")
    if not tolua.isnull(self.lb_coins_base) then
        self.lb_coins_base:setVisible(false)
    end
    self.sp_line = self:findChild("sp_line")

    self.lb_phase = self:findChild("lb_phase")

    self.lb_more = self:findChild("lb_more")

    self.sp_coins = self:findChild("sp_coins")
    self.lb_coins = self:findChild("lb_coins")
    self.sp_add = self:findChild("sp_add")
    self.sp_wheel = self:findChild("sp_wheel")

    self.node_Jackpot = self:findChild("node_Jackpot")
end

function QuestLobbyTitle:createJackpotCoinsNode()
    if self.node_Jackpot then
        if not self.m_config or not self.m_config:isRunning() then
            return 
        end
        local hasWheel ,wheelData = self.m_config:getCurrentPhaseJackpotWheelData()
        if not hasWheel then
            return 
        end
        local jackpotCoinsNode = util_createView(QUEST_CODE_PATH.QuestJackpotWheelTitleNode)
        self.node_Jackpot:addChild(jackpotCoinsNode)
    end
end

-- 初始化特殊卡册buff节点
function QuestLobbyTitle:initSpecialClanBuffNode()
    local node_mythic = self:findChild("node_mythic")
    if not node_mythic then
        return
    end
    local buffInfo = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
    if buffInfo then
        local nMuti = tonumber(buffInfo.buffMultiple)
        local mythicBuff = G_GetMgr(G_REF.CardSpecialClan):createSpecialClanBuffNode()
        if mythicBuff then
            mythicBuff:updateBuffMultiple(nMuti)
            node_mythic:addChild(mythicBuff)
        end
    end
end

function QuestLobbyTitle:onEnter()
    -- 解锁新关 刷新奖励
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updatePhaseReward()
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK
    )
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updatePhaseReward()
        end,
        ViewEventType.NOTIFY_MULEXP_END
    )
    -- 新赛季开启清除buff刷新ui
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updatePhaseReward()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )    
end

function QuestLobbyTitle:getCoins()
    if not self.m_config or not self.m_config:isRunning() then
        return 0
    end
    local rewardData = self.m_config:getPhaseReward()
    if not rewardData then
        return 0
    end

    local jackpotPool = 0
    if self.m_config.p_questJackpot then
        jackpotPool = self.m_config.p_questJackpot
    end

    local coins = 0
    if rewardData.p_coins then
        coins = tonumber(rewardData.p_coins)
    end
    if coins > 0 then
        --quest活动倍数加成
        local buffmul = 1
        if rewardData.p_multiple then
            buffmul = tonumber(rewardData.p_multiple)
        end
        local buffInfo = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
        if buffInfo then
            local nMuti = tonumber(buffInfo.buffMultiple)
            buffmul = buffmul + nMuti / 100
        end

        local buffInfo_1 = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_QUESTICONS_MORE)
        if buffInfo_1 then
            local nMuti = tonumber(buffInfo_1.buffMultiple) -1
            buffmul = buffmul + nMuti 
        end

        coins = (coins + jackpotPool) * buffmul
    end
    return coins
end

-- 更新顶部的阶段奖励
function QuestLobbyTitle:updatePhaseReward()
    if not self.m_config or not self.m_config:isRunning() then
        return
    end

    local coins = self:getCoins()
    if not coins or coins <= 0 then
        self:setVisible(false)
        return
    end

    self:setVisible(true)

    self.lb_coins:setString(util_formatCoins(coins, 9))
    -- 道具
    local rewardData = self.m_config:getPhaseReward()
    local rewardSize = cc.size(0,0)
    local nodeReward = self:findChild("node_reward")
    nodeReward:removeAllChildren()
    if rewardData and rewardData.p_items then
        local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP) * 0.6
        local itemNode  = gLobalItemManager:addPropNodeList(rewardData.p_items, ITEM_SIZE_TYPE.TOP, 0.6, width, true)
        local tWidth = width * #(rewardData.p_items)
        rewardSize = cc.size(tWidth, width)
        itemNode:addTo(nodeReward)
    end

    util_alignCenter(
        {
            {node = self.sp_coins, scale = 0.52},
            {node = self.lb_coins, scale = 0.35, alignX = 5, alignY = 1},
            {node = self.sp_add, scale = 0.35, alignX = 2, alignY = 1},
            {node = self.sp_wheel, scale = 0.18, alignX = 2, alignY = 1},
            {node = nodeReward, scale = 1, alignX = 2, alignY =1, size = rewardSize}
        }
    )

    self.lb_phase:setString(self.m_config:getPhaseIdx())

    local baseCoins = 0
    local nMuti = 0
    local buffInfo = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
    if buffInfo then
        nMuti = tonumber(buffInfo.buffMultiple) or 0
    end

    local buffInfo_1 = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_QUESTICONS_MORE)
    if buffInfo_1 then
        nMuti = nMuti + (tonumber(buffInfo_1.buffMultiple) -1) * 100
    end

    self.m_nMuti_init = nMuti

    local hasDiscount = self.m_config:hasDiscount()
    self.sp_more:setVisible(hasDiscount)
    self.lb_coins_base:setVisible(hasDiscount)
    if hasDiscount then
        self.lb_more:setString("+" .. self.m_config.p_discount .. "%")

        local discount = self.m_config.p_discount + nMuti
        baseCoins = coins / (1 + discount / 100)
    else
        if nMuti > 0 then
            self.lb_coins_base:setVisible(true)
            baseCoins = coins / (1 + nMuti / 100)
        end
    end

    if baseCoins > 0 then
        self.lb_coins_base:setString(util_formatCoins(baseCoins, 9))

        local size = self.lb_coins_base:getContentSize()
        self.sp_line:setContentSize(size.width + 4, 6)
        self.sp_line:setPositionX(size.width / 2)
    end
end

return QuestLobbyTitle
