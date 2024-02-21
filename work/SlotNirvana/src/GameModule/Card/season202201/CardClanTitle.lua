--[[
    卡组的标题
    201904
]]
local CardClanTitle201903 = util_require("GameModule.Card.season201903.CardClanTitle")
local CardClanTitle = class("CardClanTitle", CardClanTitle201903)

function CardClanTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanTitleRes, "season202201")
end

-- 不需要灯光
function CardClanTitle:initTitleLight()
end

-- 子类重写
function CardClanTitle:getQuestInfoLua()
    return "GameModule.Card.season202201.CardClanQuestInfo"
end

--[[-- 赛季新增雕塑buff 开始------------------------------------------------- ]]
function CardClanTitle:initUI()
    CardClanTitle.super.initUI(self)
    self:initStatueBuffNode()
end

function CardClanTitle:initCsbNodes()
    CardClanTitle.super.initCsbNodes(self)
    self.m_nodeStatueBuff = self:findChild("diaosu_buff")
end

function CardClanTitle:initStatueBuffNode()
    self.m_nodeStatueBuff:removeAllChildren()
    local nMuti = CardSysManager:getBuffDataByType(BUFFTYPY.BUFFTYPE_CARD_COMPLETE_COIN_BONUS)
    if nMuti and nMuti > 0 then
        -- local statueBuffUI = util_createView("GameModule.Card.season202201.CardBuffTipNode", nMuti)
        local albumId = CardSysRuntimeMgr:getSelAlbumID()
        local _logic = CardSysRuntimeMgr:getSeasonLogic(albumId)
        if _logic then
            local statueBuffUI = _logic:createCardSpecialGameBuffNode(nMuti)
            self.m_nodeStatueBuff:addChild(statueBuffUI)
        end
    end
end
--[[-- 赛季新增雕塑buff 结束------------------------------------------------- ]]
function CardClanTitle:onEnter()
    CardClanTitle.super.onEnter(self)

    -- -- TODO:MAQUN 赛季结束发送消息刷新buff标签
    -- gLobalNoticManager:addObserver(self, function(target, params)
    --     self:initStatueBuffNode()
    -- end, "CARD_SEASON_OVER")

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initStatueBuffNode()
        end,
        ViewEventType.NOTIFY_MULEXP_END
    )
    -- 新赛季开启清除buff刷新ui
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:initStatueBuffNode()
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
        lb_coins:setString(util_formatCoins(tonumber(self.m_clanData.coins), 30))

        local size = lb_coins:getContentSize()
        local scale = lb_coins:getScale()
        local pos = cc.p(lb_coins:getPosition())
        sp_coins:setPositionX(pos.x - ((scale * size.width) / 2 + 30))

        self.m_coinNormal:setVisible(true)
        self.m_coinCompleted:setVisible(false)
    end
end

return CardClanTitle
