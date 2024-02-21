-- Created by jfwang on 2019-05-21.
-- QuestNewUserTipReward
--
local QuestNewUserTipReward = class("QuestNewUserTipReward", BaseView)

function QuestNewUserTipReward:getCsbName()
    return QUEST_RES_PATH.QuestCellTips
end

function QuestNewUserTipReward:initDatas(phase_idx, stage_idx)
    self.phase_idx = phase_idx
    self.stage_idx = stage_idx
    self.act_data = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not self.act_data then
        return
    end
    self.stage_data = self.act_data:getStageData(self.phase_idx, self.stage_idx)
end

function QuestNewUserTipReward:initUI()
    QuestNewUserTipReward.super.initUI(self)
    self:initView()
    self:setVisible(false)
end

function QuestNewUserTipReward:initCsbNodes()
    self.lb_coins = self:findChild("lb_coins")

    self.m_Image = self:findChild("Image_1") -- 正常情况下的image
    self.m_Image_2 = self:findChild("Image_2")
    -- 有vipboost的情况下才展示
    self.node_reward = self:findChild("node_reward") -- 加载 vip boost道具节点
    self.lb_coins2 = self:findChild("lb_coins_2")
end

function QuestNewUserTipReward:initView()
    if not self.act_data then
        return
    end

    -- 判断当前是否有道具
    local has_items = (self.stage_data.p_items and #self.stage_data.p_items > 0)
    if has_items then
        local itemData = self.stage_data.p_items[1]
        self.m_Image:setVisible(false)
        self.m_Image_2:setVisible(true)
        local newItemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.TOP)
        self.node_reward:addChild(newItemNode)
    end
    if self.stage_idx == 7 then
        local coins = self.stage_data.p_coins + self.act_data.p_questJackpot
        self.lb_coins:setString(util_formatCoins(coins, 9))
        self.lb_coins2:setString(util_formatCoins(coins, 9))
    else
        self.lb_coins:setString(util_formatCoins(self.stage_data.p_coins, 9))
        self.lb_coins2:setString(util_formatCoins(self.stage_data.p_coins, 9))
    end

    -- 默认隐藏
    self.m_Image:setVisible(not has_items)
    self.m_Image_2:setVisible(has_items)
end

function QuestNewUserTipReward:showTipView()
    if self.m_bActing then
        return
    end
    if self:isVisible() then
        -- hide
       self:hideTipView()
       return 
    end

    self.m_bActing = true
    self:setVisible(true)
    self:runCsbAction(
        "show",
        false,
        function()
            self:runCsbAction("idle", true, nil, 60)
            util_performWithDelay(
                self,
                function()
                    if not tolua.isnull(self) then
                        self:hideTipView()
                    end
                end,
                3
            )
            self.m_bActing = false
        end,
        60
    )
end

function QuestNewUserTipReward:hideTipView()
    if self.m_bActing then
        return
    end
    self:stopAllActions()
    self.m_bActing = true
    self:runCsbAction(
        "over",
        false,
        function()
            self:setVisible(false)
            self.m_bActing = false
        end,
        60
    )
end

return QuestNewUserTipReward
