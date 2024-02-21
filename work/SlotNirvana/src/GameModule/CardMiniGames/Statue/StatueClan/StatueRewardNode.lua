--[[
    集齐奖励
]]
local StatueRewardNode = class("StatueRewardNode", BaseView)

function StatueRewardNode:initUI(_statueType)
    self.m_statueType = _statueType
    StatueRewardNode.super.initUI(self)
    self:initData()
    self:initView()
end

function StatueRewardNode:getCsbName()
    if self.m_statueType == 1 then
        return "CardRes/season202102/Statue/Statue_reward_left.csb"
    elseif self.m_statueType == 2 then
        return "CardRes/season202102/Statue/Statue_reward_right.csb"
    end
end

function StatueRewardNode:initCsbNodes()
    self.m_fntWord = self:findChild("font_word")
    self.m_fntCoin = self:findChild("font_coin")
    self.m_nodeItem = self:findChild("node_item")
    self.m_nodeStatueBuff = self:findChild("diaosu_buff")
    self.m_nodeReward = self:findChild("node_reward")
    self.m_nodeComplete = self:findChild("node_completed")
end

function StatueRewardNode:initData()
    release_print("!!! StatueRewardNode m_clanData --- initData " .. self.m_statueType)
    _, self.m_clanData = CardSysManager:getStatueMgr():getRunData():getCurrentStatueClan(self.m_statueType)
    assert(self.m_clanData ~= nil, "StatueRewardNode m_clanData is NULL")
end

function StatueRewardNode:initView()
    self.m_nodeComplete:setVisible(false)
    self.m_nodeReward:setVisible(false)
    if self.m_nodeStatueBuff then
        self.m_nodeStatueBuff:setVisible(false)
    end

    if self.m_clanData and self.m_clanData.getReward == true then
        self.m_nodeComplete:setVisible(true)
    else
        self.m_nodeReward:setVisible(true)
        if self.m_nodeStatueBuff then
            self.m_nodeStatueBuff:setVisible(true)
        end
        self:initStatueBuffNode()
        self:initReward()
    end
end

function StatueRewardNode:initStatueBuffNode()
    if self.m_nodeStatueBuff then
        self.m_nodeStatueBuff:removeAllChildren()
        local nMuti = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_COMPLETE_COIN_BONUS)
        if nMuti and nMuti > 0 then
            local albumId = CardSysRuntimeMgr:getSelAlbumID() or CardSysRuntimeMgr:getCurAlbumID()
            local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
            if _logic then
                local statueBuffUI = _logic:createCardSpecialGameBuffNode(nMuti)
                self.m_nodeStatueBuff:addChild(statueBuffUI)
            end
        end
    end
end

function StatueRewardNode:initReward()
    local clanData = self.m_clanData
    if not clanData then
        return
    end
    local UIList = {}
    local coins = tonumber(clanData.coins)
    local itemDatas = {}

    if clanData.rewards and #clanData.rewards > 0 then
        for i = 1, #clanData.rewards do
            if clanData.rewards[i].p_type ~= "Buff" then
                itemDatas[#itemDatas + 1] = clone(clanData.rewards[i])
            end
        end
    end
    if #itemDatas > 0 then
        self.m_fntCoin:setString(util_formatCoins(coins, 13) .. " + ")
        table.insert(UIList, {node = self.m_fntCoin, size = self.m_fntCoin:getContentSize(), anchor = cc.p(0.5, 0.5)})

        if not self.m_items then
            self.m_items = {}
        end
        if #self.m_items > 0 then
            for i = 1, #self.m_items do
                self.m_items[i]:removeFromParent()
            end
            self.m_items = {}
        end
        for i = 1, #itemDatas do
            local shopItemUI = gLobalItemManager:createRewardNode(itemDatas[i])
            if shopItemUI then
                self.m_items[#self.m_items + 1] = shopItemUI
                shopItemUI:setScale(0.3)
                self.m_nodeItem:addChild(shopItemUI)
                table.insert(UIList, {node = shopItemUI, alignX = 5, scale = 0.3, size = cc.size(128, 128), anchor = cc.p(0.5, 0.5)})
            end
        end
    else
        self.m_fntCoin:setString(util_formatCoins(coins, 13))
        table.insert(UIList, {node = self.m_fntCoin})
    end
    util_alignCenter(UIList)
end

function StatueRewardNode:onEnter()
    StatueRewardNode.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initData()
            self:initView()
            self:initStatueBuffNode()
        end,
        CardSysConfigs.ViewEventType.CARD_STATUE_LEVELUP_ANIMA_OVER
    )
end

return StatueRewardNode
