--[[
    特殊卡册标题-购物主题
]]
local ObsidianCardTitle = class("ObsidianCardTitle", BaseView)

function ObsidianCardTitle:initDatas(_pageIndex, _seasonId)
    self.m_data = G_GetMgr(G_REF.ObsidianCard):getSeasonData(_seasonId)
    self.m_seasonId = _seasonId
    self.m_pageIndex = _pageIndex
    self.m_isHistory = self.m_data:isHistorySeason(_seasonId) or false
    self.m_rewardLuaPath = "views.Card.CardObsidian_1.mainUI.ObsidianCardTitleReward"
end

function ObsidianCardTitle:getCsbName()
    return "CardRes/CardObsidian_1/csb/main/ObsidianAlbum_title.csb"
end

function ObsidianCardTitle:initCsbNodes()
    self.m_nodeTitle = self:findChild("node_title")
    self.m_nodeTitleHistroy = self:findChild("node_title2")
    self.m_nodeShow1 = self:findChild("node_show1")
    self.m_nodeShow2 = self:findChild("Node_show2")
    self.m_cardLogo = self:findChild("card_logo")
    self.m_lbProgress = self:findChild("lb_progress")
    self.m_nodeRewards = {}
    for i = 1, 3 do
        local nodePrize = self:findChild("node_prize_" .. i)
        table.insert(self.m_nodeRewards, nodePrize)
    end
end

function ObsidianCardTitle:initUI()
    ObsidianCardTitle.super.initUI(self)
    self:initTitle()
end

function ObsidianCardTitle:initTitle()
    if self.m_isHistory then
        self.m_nodeTitle:setVisible(false)
        self.m_nodeTitleHistroy:setVisible(true)
        local isGetAllCards = self.m_data:isGetAllCards()
        self.m_nodeShow1:setVisible(isGetAllCards)
        self.m_nodeShow2:setVisible(not isGetAllCards)
    else
        self.m_nodeTitle:setVisible(true)
        self.m_nodeTitleHistroy:setVisible(false)
        local current = self.m_data:getCurrent()
        local total = self.m_data:getTotal()
        self.m_lbProgress:setString(current .. "/" .. total)
        self:initCoins()
    end
end

function ObsidianCardTitle:initCoins()
    for i = 1, #self.m_nodeRewards do
        local reward = util_createView(self.m_rewardLuaPath, i)
        self.m_nodeRewards[i]:addChild(reward)
    end
end

function ObsidianCardTitle:playStart(_over)
    self:runCsbAction(
        "start",
        false,
        function()
            if _over then
                _over()
            end
            self:runCsbAction("idle", true, nil, 60)
        end,
        60
    )
end

function ObsidianCardTitle:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

return ObsidianCardTitle
