--大地图上的促销节点
local QuestNewLobbyStarNode = class("QuestNewLobbyStarNode", util_require("base.BaseView"))

local STATE = {
    NONE = "NONE",
    NOBUFF = "NOBUFF",
    INBUFF = "INBUFF"
}

function QuestNewLobbyStarNode:initDatas(m_chapterId)
    self.m_chapterId = m_chapterId
    self.m_currentChapterData = G_GetMgr(ACTIVITY_REF.QuestNew):getChapterDataByChapterId(m_chapterId)
end

function QuestNewLobbyStarNode:getCsbNodePath()
    return QUESTNEW_RES_PATH.QuestNewLobbyStarNode
end

function QuestNewLobbyStarNode:initUI()
    self:createCsbNode(self:getCsbNodePath())

    self.m_lb_shuzi = self:findChild("lb_shuzi")
    self.m_node_rewards = self:findChild("node_rewards")

    self.m_bar_jdt = self:findChild("LoadingBar_1") 

    local touch = G_GetMgr(ACTIVITY_REF.Quest):makeTouch(cc.size(140, 140), "touch")
    self:addChild(touch, 1)
    self:addClick(touch)

    self:initView()
end

function QuestNewLobbyStarNode:initView()

    local itemData = self.m_currentChapterData:getNextStarRewardData()
    local itemNodeData = nil
    if itemData.p_coins > 0 then
        itemNodeData = gLobalItemManager:createLocalItemData("Coins", tonumber(itemData.p_coins), {p_limit = 3})
    elseif itemData.p_items and #itemData.p_items > 0 then
        itemNodeData= gLobalItemManager:createLocalItemData(itemData.p_items[1].p_icon, itemData.p_items[1].p_num, itemData.p_items[1])
    end

    local newItemNode = gLobalItemManager:createRewardNode(itemNodeData, ITEM_SIZE_TYPE.REWARD_BIG)
    if newItemNode then 
        gLobalDailyTaskManager:setItemNodeByExtraData(itemNodeData, newItemNode)
        newItemNode:setScale(0.5)
        self.m_node_rewards:addChild(newItemNode) 
    end

    local rate = self.m_currentChapterData.p_pickStars / itemData.p_stars *100
    self.m_lb_shuzi:setString("".. self.m_currentChapterData.p_pickStars .. "/" .. itemData.p_stars)
    self.m_bar_jdt:setPercent(rate)

end

function QuestNewLobbyStarNode:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        G_GetMgr(ACTIVITY_REF.QuestNew):showStarPrizeView(self.m_chapterId)
    end
end

return QuestNewLobbyStarNode
