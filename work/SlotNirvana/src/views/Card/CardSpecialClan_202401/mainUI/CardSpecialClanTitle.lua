--[[
    特殊卡册标题
]]
local CardSpecialClanTitle = class("CardSpecialClanTitle", BaseView)

function CardSpecialClanTitle:initDatas(_pageIndex)
    self.m_pageIndex = _pageIndex
end

function CardSpecialClanTitle:getCsbName()
    return "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/main/MagicClanTitle.csb"
end

function CardSpecialClanTitle:initCsbNodes()
    self.m_nodeNormal = self:findChild("node_title")
    self.m_nodeCompleted = self:findChild("node_title_set")

    self.m_nodeCoin = self:findChild("node_coin")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")

    self.m_lbBuffQuest = self:findChild("lb_buffQuest")
    self.m_lbBuffCard = self:findChild("lb_buffCard")
end

function CardSpecialClanTitle:initUI()
    CardSpecialClanTitle.super.initUI(self)
    self:updateComplete()
    
    self:updateBuffs()
end

function CardSpecialClanTitle:onEnter()
    CardSpecialClanTitle.super.onEnter(self)
    self:initRewards()
end

function CardSpecialClanTitle:updateUI(_pageIndex)
    self.m_pageIndex = _pageIndex
    self:updateComplete()
    self:initRewards()
    self:updateBuffs()
end

function CardSpecialClanTitle:updateComplete()
    local isCompleted = self:isCompleted()
    self.m_nodeNormal:setVisible(isCompleted == false)
    self.m_nodeCompleted:setVisible(isCompleted == true)
end

function CardSpecialClanTitle:initRewards()
    local clanData = self:getClanData(self.m_pageIndex)
    if not clanData then
        return 
    end    
    -- 金币
    local UIList = {}
    local coinNum = clanData:getCoins()
    if coinNum and coinNum > 0 then
        self.m_lbCoin:setString(util_getFromatMoneyStr(coinNum))
        table.insert(UIList, {node = self.m_spCoin, scale = 0.5})
        table.insert(UIList, {node = self.m_lbCoin, scale = 0.4, alignX = 5, alignY = 2})
    end
    -- 道具
    if self.m_itemNodes and #self.m_itemNodes > 0 then
        for i = #self.m_itemNodes, 1, -1 do
            self.m_itemNodes[i]:removeFromParent()
            self.m_itemNodes[i] = nil
        end
    end
    self.m_itemNodes = {}
    local itemDatas = clanData:getRewardItems()
    if itemDatas and #itemDatas > 0 then
        local scale = 0.4
        local width = 128 * scale
        for i = 1, #itemDatas do
            if not itemDatas[i]:isBuff() then
                local itemNode = gLobalItemManager:createRewardNode(itemDatas[i], ITEM_SIZE_TYPE.REWARD)
                if itemNode then
                    self.m_nodeCoin:addChild(itemNode)
                    itemNode:setScale(scale)
                    table.insert(self.m_itemNodes, itemNode)
                    table.insert(UIList, {node = itemNode, size = cc.size(width, width), scale = scale, alignX = 25, alignY = 2})
                end
            end
        end
    end
    util_alignCenter(UIList)
end

function CardSpecialClanTitle:updateBuffs()
    local clanData = self:getClanData(self.m_pageIndex)
    if not clanData then
        return 
    end
    local cardBuffItem = clanData:getBuffItemByBuffType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
    if cardBuffItem then
        local multi = cardBuffItem:getBuffMultiple() or 0
        self.m_lbBuffCard:setString(multi .. "%")
    end
    local questBuffItem = clanData:getBuffItemByBuffType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_ALBUM)
    if questBuffItem then
        local multi = questBuffItem:getBuffMultiple() or 0
        self.m_lbBuffQuest:setString(multi .. "%")
    end
end

function CardSpecialClanTitle:playStart(_over)
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

-- function CardSpecialClanTitle:playOver(_over)
--     self:runCsbAction("over", false, _over, 60)
-- end

function CardSpecialClanTitle:isCompleted()
    local clanData = self:getClanData(self.m_pageIndex)
    if clanData then
        return clanData:isCompleted()
    end
    return false
end

function CardSpecialClanTitle:getClanData(_index)
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if data then
        local clanData = data:getSpecialClanByIndex(_index)
        return clanData
    end
    return nil
end



return CardSpecialClanTitle
