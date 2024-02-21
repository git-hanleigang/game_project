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
end

function CardSpecialClanTitleReward:initUI()
    CardSpecialClanTitleReward.super.initUI(self)
    self:initCoins()
    self:initChips()
end

function CardSpecialClanTitleReward:initCoins()
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
        local coinNum = rewardData:getCoins()
        self.m_lbCoin:setString(util_formatCoins(coinNum, 4))
        util_alignCenter(
            {
                {node = self.m_spCoin, scale = 0.5},
                {node = self.m_lbCoin, scale = 0.4, alignX = 10}
            }
        )
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
