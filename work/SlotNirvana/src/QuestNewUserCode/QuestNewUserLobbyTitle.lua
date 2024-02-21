--大地图上的标题节点

local QuestNewUserLobbyTitle = class("QuestNewUserLobbyTitle", BaseView)

function QuestNewUserLobbyTitle:getCsbNodePath()
    return QUEST_RES_PATH.QuestLobbyTitile
end

function QuestNewUserLobbyTitle:initUI(data)
    self.act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self:createCsbNode(self:getCsbNodePath())
    self:initView()
    self:updatePhaseReward()
end

function QuestNewUserLobbyTitle:getLanguageTableKeyPrefix()
    return "QuestNewUserLobbyTitle"
end

function QuestNewUserLobbyTitle:initView()
    self:runCsbAction("sweep", true)
    self.node_coins = self:findChild("node_coins")
    self.lb_phase = self:findChild("lb_phase")
    self.sp_coins = self:findChild("sp_coins")
    self.lb_coins = self:findChild("lb_coins")
end

function QuestNewUserLobbyTitle:onEnter()
    -- 解锁新关 刷新奖励
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            self:updatePhaseReward()
        end,
        ViewEventType.NOTIFY_ACTIVITY_QUEST_NEXT_UNLOCK
    )
end

function QuestNewUserLobbyTitle:getCoins()
    if not self.act_data or not self.act_data:isRunning() then
        return 0
    end
    local rewardData = self.act_data:getPhaseReward()
    if not rewardData then
        return 0
    end

    local jackpotPool = 0
    if self.act_data.p_questJackpot then
        jackpotPool = self.act_data.p_questJackpot
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
function QuestNewUserLobbyTitle:updatePhaseReward()
    if not self.act_data or not self.act_data:isRunning() then
        return
    end

    local coins = self:getCoins()
    if not coins or coins <= 0 then
        self:setVisible(false)
        return
    end

    self:setVisible(true)
    local phase_data = self.act_data:getCurPhaseData()
    local hasRewwards = (phase_data and phase_data.p_phaseItems and #phase_data.p_phaseItems > 0)
    if hasRewwards then
        self.lb_coins:setString(util_formatCoins(coins, 9) .. " +")
    else
        self.lb_coins:setString(util_formatCoins(coins, 9))
    end

    local ui_list = {}
    table.insert(ui_list, {node = self.sp_coins})
    table.insert(ui_list, {node = self.lb_coins, alignX = 5})
    if hasRewwards and not tolua.isnull(self.node_coins) then
        local item_data = phase_data.p_phaseItems[1]
        if item_data then
            if not self.reward_item then
                local shopItemUI = gLobalItemManager:createRewardNode(item_data, ITEM_SIZE_TYPE.TOP)
                if shopItemUI then
                    shopItemUI:addTo(self.node_coins)
                    self.reward_item = shopItemUI
                end
            end
            if not tolua.isnull(self.reward_item) then
                self.reward_item:setVisible(true)
                gLobalItemManager:updateItem(self.reward_item, item_data)
                local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP)
                table.insert(ui_list, {node = self.reward_item, size = cc.size(width, width), anchor = cc.p(0.5, 0.5)})
            end
        else
            if not tolua.isnull(self.reward_item) then
                self.reward_item:setVisible(false)
            end
        end
    else
        if not tolua.isnull(self.reward_item) then
            self.reward_item:setVisible(false)
        end
    end
    util_alignCenter(ui_list)

    if self.lb_phase then
        self.lb_phase:setString(self.act_data:getPhaseIdx())
    end
end

return QuestNewUserLobbyTitle
