--[[
    特殊卡册标题奖励
]]
local CardSpecialClanTitleReward = class("CardSpecialClanTitleReward", BaseView)

function CardSpecialClanTitleReward:initDatas(_phaseIndex)
    self.m_phaseIndex = _phaseIndex
end

function CardSpecialClanTitleReward:getCsbName()
    return "CardRes/" .. G_GetMgr(G_REF.CardSpecialClan):getThemeName() .. "/csb/main/MagicAlbum_title_reward.csb"
end

function CardSpecialClanTitleReward:initCsbNodes()
    self.m_lbChips = self:findChild("lb_chips")
    self.m_lbCompleted = self:findChild("lb_completed")

    self.m_nodeCoin = self:findChild("node_coin")
    self.m_spCoin = self:findChild("sp_coin")
    self.m_lbCoin = self:findChild("lb_coin")
    -- self.m_nodeCard = self:findChild("node_card")
end

function CardSpecialClanTitleReward:initUI()
    CardSpecialClanTitleReward.super.initUI(self)
    self:initRewards()
    self:initChipNum()
end

function CardSpecialClanTitleReward:initRewards()
    local clanData = self:getClanData()
    if not clanData then
        return
    end
    local rewardData = clanData:getPhaseRewardByIndex(self.m_phaseIndex)
    if not rewardData then
        return
    end    
    if clanData:isPhaseRewardCompleted(self.m_phaseIndex) then
        self.m_nodeCoin:setVisible(false)
        self.m_lbCompleted:setVisible(true)
    else
        self.m_nodeCoin:setVisible(true)
        self.m_lbCompleted:setVisible(false)
        -- 金币
        local UIList = {}
        local coinNum = rewardData:getCoins()
        if coinNum and coinNum > 0 then
            self.m_lbCoin:setString(util_formatCoins(coinNum, 4))
            table.insert(UIList, {node = self.m_spCoin, scale = 0.43})
            table.insert(UIList, {node = self.m_lbCoin, scale = 0.3, alignX = 5, alignY = 2})
        end
        -- 卡
        local itemDatas = rewardData:getItems()
        if itemDatas and #itemDatas > 0 then
            local scale = 0.4
            local width = 128 * scale
            for i = 1, #itemDatas do
                local itemNode = gLobalItemManager:createRewardNode(itemDatas[i], ITEM_SIZE_TYPE.REWARD)
                if itemNode then
                    self.m_nodeCoin:addChild(itemNode)
                    itemNode:setScale(scale)
                    table.insert(UIList, {node = itemNode, size = cc.size(width, width), scale = scale, alignX = 25, alignY = 2})
                end
            end
        end
        util_alignCenter(UIList)
    end
end

function CardSpecialClanTitleReward:initChipNum()
    local clanData = self:getClanData()
    if not clanData then
        return
    end
    local rewardData = clanData:getPhaseRewardByIndex(self.m_phaseIndex)
    if not rewardData then
        return
    end
    local chipNum = rewardData:getNum()
    self.m_lbChips:setString(chipNum .. " CHIPS")
end

function CardSpecialClanTitleReward:getClanData()
    local data = G_GetMgr(G_REF.CardSpecialClan):getData()
    if not data then
        return
    end
    local clanData = data:getSpecialClanByIndex()
    return clanData
end

return CardSpecialClanTitleReward
