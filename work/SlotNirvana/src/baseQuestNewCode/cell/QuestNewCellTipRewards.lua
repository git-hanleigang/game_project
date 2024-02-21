-- 气泡里面的奖励内容

local QuestCellTipRewards = class("QuestCellTipRewards", BaseView)

function QuestCellTipRewards:getCsbName()
    return QUEST_RES_PATH.QuestCellTipRewards
end

function QuestCellTipRewards:initDatas(phase_idx, stage_idx)
    self.m_config = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self.phase_idx = phase_idx
    self.stage_idx = stage_idx
end

function QuestCellTipRewards:initUI()
    QuestCellTipRewards.super.initUI(self)

    self:initView()
end

function QuestCellTipRewards:initCsbNodes()
    -- 金币相关
    self.panel_coins = self:findChild("panel_coins")
    self.node_coins = self:findChild("node_coins")
    self.lb_coins = self:findChild("lb_coins")
    self.lb_coins_base = self:findChild("lb_coins_base")
    self.sp_coins_line = self:findChild("sp_coins_line")

    -- 额外奖励相关
    self.panel_rewards = self:findChild("panel_rewards")
    self.node_star = self:findChild("node_star")
    self.lb_points = self:findChild("lb_points")
    self.lb_points_base = self:findChild("lb_points_base")
    self.sp_points_line = self:findChild("sp_points_line")

    self.sp_buff = self:findChild("sp_buff")
    self.lb_discount = self:findChild("lb_discount")
end

function QuestCellTipRewards:initView()
    if not self.m_config or not self.m_config:isRunning() then
        return
    end

    self:resetCoins()
    self:resetRewards()
    self:resetPos()
end

function QuestCellTipRewards:resetUI()
    if not self.m_config or not self.m_config:isRunning() then
        return
    end

    self:resetCoins()
    self:resetRewards()
    self:resetPos()
end

function QuestCellTipRewards:hasCoins()
    -- 宝箱前的礼盒里面不显示钱 这个钱会在大宝箱里面显示
    if self.stage_idx == 6 then
        return false
    end

    local stage_data = self.m_config:getStageData(self.phase_idx, self.stage_idx)
    if not stage_data or not stage_data.p_coins then
        return false
    end

    return tonumber(stage_data.p_coins) > 0
end

function QuestCellTipRewards:resetCoins()
    if not self:hasCoins() then
        self.panel_coins:setVisible(false)
        return
    end

    self.panel_coins:setVisible(true)
    local stage_data = self.m_config:getStageData(self.phase_idx, self.stage_idx)

    self.lb_coins:setString(util_formatCoins(stage_data.p_coins, 8))

    local panel_size = self.panel_coins:getContentSize()
    local bl_hasDiscount = self.m_config:hasDiscount()
    self.lb_coins_base:setVisible(bl_hasDiscount)
    local height_percent = 0.5 -- 这个是调试值 固定设置就可以了 单独显示的时候 需要居中 非单独显示的时候 向上移动 给其他空间显示预留空间
    if bl_hasDiscount then
        height_percent = 0.73
        local lastCoins = stage_data.p_coins / (1 + self.m_config.p_discount * 0.01)
        self.lb_coins_base:setString(util_formatCoins(lastCoins, 8))

        local size = self.lb_coins_base:getContentSize()
        self.sp_coins_line:setContentSize(size.width + 4, 5)
        self.sp_coins_line:setPositionX(size.width / 2)
    end
    self.node_coins:setPositionY(panel_size.height * height_percent)

    local coins_width = self.lb_coins:getContentSize().width
    local coins_posX = self.lb_coins:getPositionX()
    local world_pos = self.node_coins:convertToWorldSpace(cc.p(coins_posX, 0))
    local node_pos = self.panel_coins:convertToNodeSpace(world_pos)
    local edge_x = 10
    self.panel_coins:setContentSize(node_pos.x + coins_width + edge_x, panel_size.height)
end

function QuestCellTipRewards:hasRewards()
    local stage_data = self.m_config:getStageData(self.phase_idx, self.stage_idx)
    if not stage_data or not stage_data.p_points then
        return false
    end
    return tonumber(stage_data.p_points) > 0
end

function QuestCellTipRewards:resetRewards()
    if not self:hasRewards() then
        self.panel_rewards:setVisible(false)
        return
    end

    self.panel_rewards:setVisible(true)
    local stage_data = self.m_config:getStageData(self.phase_idx, self.stage_idx)
    self.lb_points:setString(math.floor(stage_data.p_points))
    local bl_hasDiscount = self.m_config:hasDiscount()
    self.lb_points_base:setVisible(bl_hasDiscount)
    self.sp_buff:setVisible(bl_hasDiscount)
    if bl_hasDiscount then
        local lastPoints = stage_data.p_points / (1 + self.m_config.p_discount * 0.01)
        self.lb_points_base:setString(math.floor(lastPoints))
        local size = self.lb_points_base:getContentSize()
        self.sp_points_line:setContentSize(size.width + 4, 5)
        self.sp_points_line:setPositionX(size.width / 2)

        self.lb_discount:setString("+" .. self.m_config.p_discount .. "%")
    end

    local panel_size = self.panel_rewards:getContentSize()
    if not bl_hasDiscount then
        local points_width = self.lb_points:getContentSize().width
        local points_posX = self.lb_points:getPositionX()
        local world_pos = self.node_star:convertToWorldSpace(cc.p(points_posX, 0))
        local node_pos = self.panel_rewards:convertToNodeSpace(world_pos)
        local edge_x = 10
        self.panel_rewards:setContentSize(node_pos.x + points_width + edge_x, panel_size.height)
    else
        local buff_width = self.sp_buff:getContentSize().width
        local buff_posX = self.sp_buff:getPositionX()
        local world_pos = self.sp_buff:getParent():convertToWorldSpace(cc.p(buff_posX, 0))
        local node_pos = self.panel_rewards:convertToNodeSpace(world_pos)
        local edge_x = 10
        self.panel_rewards:setContentSize(node_pos.x + buff_width + edge_x, panel_size.height)
    end
end

function QuestCellTipRewards:resetPos()
    if self:hasCoins() and self:hasRewards() then
        local coins_size = self.panel_coins:getContentSize()
        self.panel_coins:setPositionY(coins_size.height / 2)
        local rewards_size = self.panel_rewards:getContentSize()
        self.panel_rewards:setPositionY(-rewards_size.height / 2)
    elseif self:hasCoins() then
        self.panel_coins:setPositionY(0)
    elseif self:hasRewards() then
        self.panel_rewards:setPositionY(0)
    end
end

function QuestCellTipRewards:getWidth()
    local coins_width = 0
    if self:hasCoins() then
        local coins_size = self.panel_coins:getContentSize()
        coins_width = coins_size.width
    end
    local rewards_width = 0
    if self:hasRewards() then
        local rewards_size = self.panel_rewards:getContentSize()
        rewards_width = rewards_size.width
    end
    local width = math.max(coins_width, rewards_width)
    return width
end

function QuestCellTipRewards:getHeight()
    local coins_height = 0
    if self:hasCoins() then
        local coins_size = self.panel_coins:getContentSize()
        coins_height = coins_size.height
    end
    local rewards_height = 0
    if self:hasRewards() then
        local rewards_size = self.panel_rewards:getContentSize()
        rewards_height = rewards_size.height
    end
    local height = coins_height + rewards_height

    return height
end

return QuestCellTipRewards
