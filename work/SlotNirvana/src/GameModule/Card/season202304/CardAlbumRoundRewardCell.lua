--[[
    新增多轮次奖励展示
]]
local MAX_ROUND = 3 -- 最大轮次，之后获得的卡都转化成集卡商城积分
local UIStatus = {
    Normal = 1,
    Complete = 2,
    Lock = 3
}
local CardAlbumRoundRewardCell = class("CardAlbumRoundRewardCell", BaseView)

function CardAlbumRoundRewardCell:getCsbName()
    return "CardRes/season202304/cash_album_title_reward.csb"
end

function CardAlbumRoundRewardCell:initDatas(_index)
    self.m_index = _index
    self.m_UIStatus = self:getUIStatus()
end

function CardAlbumRoundRewardCell:initCsbNodes()
    self.m_nodeNormal = self:findChild("node_normal")
    self.m_nodeComplete = self:findChild("node_completed")
    self.m_nodeLock = self:findChild("node_locked")
end

function CardAlbumRoundRewardCell:initUI()
    CardAlbumRoundRewardCell.super.initUI(self)
    self:initUIStatus()
    self:initRewards()
    self:initRound()
    self:playIdle()
end

function CardAlbumRoundRewardCell:resetUI()
    self.m_UIStatus = self:getUIStatus()
    self:initUIStatus()
    self:initRewards()
    self:initRound()
end

function CardAlbumRoundRewardCell:initUIStatus()
    self.m_nodeNormal:setVisible(self.m_UIStatus == UIStatus.Normal)
    self.m_nodeComplete:setVisible(self.m_UIStatus == UIStatus.Complete)
    self.m_nodeLock:setVisible(self.m_UIStatus == UIStatus.Lock)
end

function CardAlbumRoundRewardCell:initRewards()
    local parentNode = nil
    if self.m_UIStatus == UIStatus.Normal then
        parentNode = self.m_nodeNormal
    elseif self.m_UIStatus == UIStatus.Complete then
        -- parentNode = self.m_nodeComplete
    elseif self.m_UIStatus == UIStatus.Lock then
        parentNode = self.m_nodeLock
    end
    if parentNode then
        -- local roundCoins = self:getRoundCoins()
        -- local lbCoin = parentNode:getChildByName("lb_coin")
        -- lbCoin:setString(util_formatCoins(roundCoins, 30))
        -- self:updateLabelSize({label = lbCoin, sx = 0.39, sy = 0.39}, 890)

        local roundCoins = self:getRoundCoins()
        local showCoins = roundCoins
        local extraMulti = self:getCoinTotalMulti()
        if extraMulti > 0 then
            showCoins = extraMulti * showCoins
        end
        local lbCoin = parentNode:getChildByName("lb_coin")
        lbCoin:setString(util_formatCoins(showCoins, 30))
        self:updateLabelSize({ label = lbCoin, sx = 0.39, sy = 0.39 }, 890)        
    end
end

function CardAlbumRoundRewardCell:initRound()
    local parentNode = nil
    if self.m_UIStatus == UIStatus.Normal then
        parentNode = self.m_nodeNormal
    elseif self.m_UIStatus == UIStatus.Complete then
        parentNode = self.m_nodeComplete
    elseif self.m_UIStatus == UIStatus.Lock then
        parentNode = self.m_nodeLock
    end
    if parentNode then
        local lbRound = parentNode:getChildByName("lb_round")
        lbRound:setString("ROUND " .. self.m_index)
    end
end

function CardAlbumRoundRewardCell:playIdle()
    self:runCsbAction("idle", true, nil, 60)
end

function CardAlbumRoundRewardCell:onEnter()
    CardAlbumRoundRewardCell.super.onEnter(self)
    -- 轮次更改
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:resetUI()
        end,
        CardSysConfigs.ViewEventType.CARD_ALBUM_ROUND_CHANGE
    )

    -- 限时集卡多倍奖励 时间到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:resetUI()
        end,
        ViewEventType.NOTIFY_ALBUM_MORE_AWARD_TIME_END
    )
end

function CardAlbumRoundRewardCell:getUIStatus()
    local round = self:getRound()
    if self.m_index < round then
        return UIStatus.Complete
    elseif self.m_index == round then
        if round == MAX_ROUND and self:isMaxRoundCompleted() then
            return UIStatus.Complete
        else
            return UIStatus.Normal
        end
    elseif self.m_index > round then
        return UIStatus.Lock
    end
end

function CardAlbumRoundRewardCell:getRound()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    if albumData then
        return (albumData:getRound() or 0) + 1
    end
    return 1
end

function CardAlbumRoundRewardCell:getRoundCoins()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    if albumData then
        local roundCoins = albumData:getRoundRewardCoins()
        if roundCoins and #roundCoins >= self.m_index then
            return roundCoins[self.m_index]
        end
    end
    return 0
end

function CardAlbumRoundRewardCell:isMaxRoundCompleted()
    local albumData = CardSysRuntimeMgr:getCardAlbumInfo()
    -- if albumData and albumData.getReward == true then
    if albumData and albumData:isGetAllCards() then
        return true
    end
    return false
end

function CardAlbumRoundRewardCell:getCardEndSpecialMul()
    local mul = 1
    if G_GetMgr(ACTIVITY_REF.CardEndSpecial):getRunningData() then
        mul = globalData.constantData.CARD_SPECIAL_REWAR or 2
    end    
    return mul
end

function CardAlbumRoundRewardCell:getBuffMulti()
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if albumID and CardSysRuntimeMgr:isPastAlbum(albumID) then
        return 0
    end
    local buffInfo = globalData.buffConfigData:getBuffDataByType(BUFFTYPY.BUFFTYPE_SPECIALCLAN_QUEST)
    if buffInfo then
        local nMuti = tonumber(buffInfo.buffMultiple)
        if nMuti and nMuti > 0 then
            return nMuti
        end
    end
    return 0
end

function CardAlbumRoundRewardCell:getAlbumMoreAwardMul()
    local multiply = 0
    multiply = G_GetMgr(ACTIVITY_REF.AlbumMoreAward):getMultiply()
    return multiply
end

-- 每次加buff都要询问计算公式是什么
function CardAlbumRoundRewardCell:getCoinTotalMulti()
    local extraMulti = 0
    local endMul = self:getCardEndSpecialMul()
    if endMul and endMul > 0 then
        extraMulti = extraMulti + endMul
    end
    local multi = self:getBuffMulti()
    if multi and multi > 0 then
        extraMulti = extraMulti + multi/100
    end

    local moreAwardMul = self:getAlbumMoreAwardMul()
    if moreAwardMul and moreAwardMul > 0 then
        extraMulti = extraMulti + moreAwardMul
    end

    return extraMulti
end

return CardAlbumRoundRewardCell
