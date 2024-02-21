--[[
    卡组的标题
    201904
]]
local CardClanTitle201903 = util_require("GameModule.Card.season201903.CardClanTitle")
local CardClanTitle = class("CardClanTitle", CardClanTitle201903)

function CardClanTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanTitleRes, "season202304")
end

-- 不需要灯光
function CardClanTitle:initTitleLight()
end

-- 子类重写
function CardClanTitle:getQuestInfoLua()
    return "GameModule.Card.season202304.CardClanQuestInfo"
end

function CardClanTitle:initUI()
    CardClanTitle.super.initUI(self)
    self:initBuffNode()
end

function CardClanTitle:initCsbNodes()
    CardClanTitle.super.initCsbNodes(self)
    self.m_nodeBuff = self:findChild("node_buff")
end

function CardClanTitle:getBuffMulti()
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

function CardClanTitle:initBuffNode()
    local albumID = CardSysRuntimeMgr:getSelAlbumID()
    if albumID and CardSysRuntimeMgr:isPastAlbum(albumID) then
        return
    end
    local multi = self:getBuffMulti()
    if multi and multi > 0 then
        self.m_nodeBuff:setVisible(true)
        if not self.m_buffNode then
            self.m_buffNode = self:createBuffNode()
        end
        if self.m_buffNode then
            self.m_buffNode:updateBuffMultiple(multi)
        end
    else
        self.m_nodeBuff:setVisible(false)
    end
end

function CardClanTitle:createBuffNode()
    local buff = G_GetMgr(G_REF.CardSpecialClan):createSpecialClanBuffNode()
    if buff then
        self.m_nodeBuff:addChild(buff) 
    end
    return buff
end

function CardClanTitle:onEnter()
    CardClanTitle.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initBuffNode()
            self:updateCoin()
        end,
        ViewEventType.NOTIFY_MULEXP_END
    )
    -- 新赛季开启清除buff刷新ui
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initBuffNode()
            self:updateCoin()
        end,
        ViewEventType.CARD_ONLINE_ALBUM_OVER
    )
end

-- 奖励
function CardClanTitle:updateCoin()
    local count = CardSysRuntimeMgr:getClanCardTypeCount(self.m_clanData.cards)
    local isCompleted = count >= #self.m_clanData.cards
    if isCompleted then
        self.m_coinNormal:setVisible(false)
        self.m_coinCompleted:setVisible(true)
    else
        local lb_coins = self:findChild("coins")
        local sp_coins = self:findChild("sp_coins")

        local clanCoins = self:getClanCoins()
        lb_coins:setString(util_formatCoins(tonumber(clanCoins), 30))

        local size = lb_coins:getContentSize()
        local scale = lb_coins:getScale()
        local pos = cc.p(lb_coins:getPosition())
        sp_coins:setPositionX(pos.x - ((scale * size.width) / 2 + 30))

        self.m_coinNormal:setVisible(true)
        self.m_coinCompleted:setVisible(false)
    end
end

function CardClanTitle:getClanCoins()
    local specialReward = 1
    local multi = self:getBuffMulti()
    if multi and multi > 0 then
        specialReward = specialReward + multi/100
    end
    local rewardCoins = (self.m_clanData.coins or 0) * specialReward
    return rewardCoins
end

return CardClanTitle
