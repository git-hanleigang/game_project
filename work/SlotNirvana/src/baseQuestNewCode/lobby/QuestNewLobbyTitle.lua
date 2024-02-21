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
end

function QuestLobbyTitle:getLanguageTableKeyPrefix()
    local theme = self.m_config:getThemeName()
    return theme .. "Title"
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
        coins = coins * buffmul + jackpotPool
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
    util_alignCenter({{node = self.sp_coins}, {node = self.lb_coins, alignX = 5}, {node = self.sp_add}, {node = self.sp_wheel}})

    self.lb_phase:setString(self.m_config:getPhaseIdx())

    local hasDiscount = self.m_config:hasDiscount()
    self.sp_more:setVisible(hasDiscount)
    self.lb_coins_base:setVisible(hasDiscount)
    if hasDiscount then
        self.lb_more:setString("+" .. self.m_config.p_discount .. "%")

        local baseCoins = coins / (1 + self.m_config.p_discount / 100)
        self.lb_coins_base:setString(util_formatCoins(baseCoins, 9))

        local size = self.lb_coins_base:getContentSize()
        self.sp_line:setContentSize(size.width + 4, 6)
        self.sp_line:setPositionX(size.width / 2)
    end
end

return QuestLobbyTitle
