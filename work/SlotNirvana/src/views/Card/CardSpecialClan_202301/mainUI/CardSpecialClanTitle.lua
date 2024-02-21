--[[
    特殊卡册标题
]]
local CardSpecialClanTitle = class("CardSpecialClanTitle", BaseView)

function CardSpecialClanTitle:initDatas(_pageIndex)
    self.m_pageIndex = _pageIndex
    self.m_rewardLuaPath = "views.Card." .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. ".mainUI.CardSpecialClanTitleReward"
end

function CardSpecialClanTitle:getCsbName()
    return "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/main/MagicAlbum_title.csb"
end

function CardSpecialClanTitle:initCsbNodes()
    self.m_cardLogo = self:findChild("card_logo")
    self.m_lbPro = self:findChild("lb_progress")
    self.m_nodeRewards = {}
    for i = 1, 3 do
        local nodePrize = self:findChild("node_prize_" .. i)
        table.insert(self.m_nodeRewards, nodePrize)
    end
end

function CardSpecialClanTitle:initUI()
    CardSpecialClanTitle.super.initUI(self)
    self:initCoins()
    self:initPro()
end

function CardSpecialClanTitle:initCoins()
    for i = 1, #self.m_nodeRewards do
        local reward = util_createView(self.m_rewardLuaPath, i)
        self.m_nodeRewards[i]:addChild(reward)
    end
end

function CardSpecialClanTitle:initPro()
    local cur, max = self:getPro()
    self.m_lbPro:setString(cur .. "/" .. max)
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

function CardSpecialClanTitle:playOver(_over)
    self:runCsbAction("over", false, _over, 60)
end

function CardSpecialClanTitle:getPro()
    local cur, max = 0, 0
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if data then
        local clanData = data:getSpecialClanByIndex()
        if clanData then
            local cards = clanData:getCards()
            if cards then
                max = table.nums(cards) or 0
            end
            cur = clanData:getHaveCardNum() or 0
        end
    end
    return cur, max
end

return CardSpecialClanTitle
