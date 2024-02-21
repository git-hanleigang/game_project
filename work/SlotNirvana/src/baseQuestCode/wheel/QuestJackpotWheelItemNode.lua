--转盘上奖励节点
local QuestJackpotWheelItemNode = class("QuestJackpotWheelItemNode", util_require("base.BaseView"))

function QuestJackpotWheelItemNode:initDatas(data)
    self.m_data = data.item_data
    self.m_type = data.type or 1
    self.m_isNormal = true
    self.m_updateFrame = 60
    if self.m_type == 4 then
        self.m_isNormal = false
        self.m_isUnlock = data.isUnlock 
        self.m_updateFrame = 30
    end
end

function QuestJackpotWheelItemNode:getCsbName()
    return QUEST_RES_PATH.QuestJackpotWheelItemNode
end

function QuestJackpotWheelItemNode:initUI()
    self:createCsbNode(self:getCsbName())
    --self:runCsbAction("idle", true, nil, self.m_updateFrame)
    self:initView()
end

function QuestJackpotWheelItemNode:refreshByData(data)
    self.m_data = data
    self.m_index = data.p_id
    self:initView()
end

function QuestJackpotWheelItemNode:initCsbNodes()
    
    local node_rewards1 = self:findChild("node_rewards1") 
    local node_rewards2 = self:findChild("node_rewards2") 
    local node_rewards3 = self:findChild("node_rewards3") 

    self.m_node_rewardsVec = {node_rewards1,node_rewards2,node_rewards3}
end

function QuestJackpotWheelItemNode:initView()
    local difficulty =  G_GetMgr(ACTIVITY_REF.Quest):getCurDifficulty()
    for i,node in ipairs(self.m_node_rewardsVec) do
        node:setVisible( i== self.m_type)
    end
    self.m_useRewardNode = self.m_node_rewardsVec[self.m_type]
    local node_coin = self.m_useRewardNode:getChildByName("node_coin")
    if node_coin then
        if self.m_data:getType() == "Coin" and self.m_isNormal and self.m_data:getCoins() > 0 then
            local lb_coin = node_coin:getChildByName("lb_num")
            lb_coin:setString(util_formatCoins(self.m_data:getCoins(), 4))
        else
            node_coin:setVisible(false)
        end
    end

    local node_arrow = self.m_useRewardNode:getChildByName("node_arrow")
    if node_arrow then
        node_arrow:setVisible(self.m_data:getType() == "Pointer")
    end

    local node_jackpot = self.m_useRewardNode:getChildByName("node_jackpot")
    if node_jackpot then
        node_jackpot:setVisible(self.m_data:isJackpotType())
    end 

    
    local node_reward = self.m_useRewardNode:getChildByName("node_reward")
    -- local itemReward = self.m_data:getItem()
    -- if node_reward and itemReward then
    --     local itemNode = gLobalItemManager:createRewardNode(itemReward, ITEM_SIZE_TYPE.REWARD)
    --     itemNode:setIconTouchEnabled(self.m_data.p_gridId <= difficulty + 1)
    --     node_reward:addChild(itemNode)
    -- end
    if node_reward then
        local rewards_list = {}
        local items = self.m_data:getItem()
        if items and #items > 0 then
            for i, item_data in ipairs(items) do
                if #rewards_list >= 2 then
                    break
                end
                local itemNode = gLobalItemManager:createRewardNode(item_data, ITEM_SIZE_TYPE.REWARD)
                if itemNode then
                    itemNode:setIconTouchEnabled(self.m_data.p_gridId <= difficulty + 1)
                    table.insert(rewards_list, itemNode)
                    node_reward:addChild(itemNode)
                end
            end
        end

        if #rewards_list >= 2 then
            local distance = 40 -- 两张卡岔开的位移
            for i, node_item in ipairs(rewards_list) do
                node_item:setLocalZOrder(-1 * i)
                node_item:setScale(0.8)
                if i == 1 then
                    node_item:setPositionX(distance / 2 * -1)
                    node_item:setRotation(-15)
                else
                    node_item:setPositionX(distance / 2)
                    node_item:setRotation(30)
                end
            end
        end
    end
end

return QuestJackpotWheelItemNode
