--[[
    卡组的标题
    201904
]]
local CardClanTitle201903 = util_require("GameModule.Card.season201903.CardClanTitle")
local CardClanTitle = class("CardClanTitle", CardClanTitle201903)

function CardClanTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanTitleRes, "season302301")
end

function CardClanTitle:initUI()
    CardClanTitle.super.initUI(self)

    -- 新手集卡双倍奖励加成tagUI
    self:initDoubleRewardSignUI()

    if G_GetMgr(G_REF.CardNoviceSale):isRunning() then
        -- 双倍 促销奖励 客户端显示* 2  结束实时刷新 金币值
        schedule(self, util_node_handler(self, self.updateCoin), 1)
    end
end

-- 不需要灯光
function CardClanTitle:initTitleLight()
end

-- 子类重写
function CardClanTitle:getQuestInfoLua()
    return "GameModule.Card.season302301.CardClanQuestInfo"
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
        local coins = self.m_clanData.coins or 0
        if G_GetMgr(G_REF.CardNoviceSale):isRunning() then
            -- 双倍 促销奖励 客户端显示* 2
            coins = tonumber(coins) * 2
        end
        lb_coins:setString(util_formatCoins(coins, 30))

        local size = lb_coins:getContentSize()
        local scale = lb_coins:getScale()
        local pos = cc.p(lb_coins:getPosition())
        sp_coins:setPositionX(pos.x - ((scale * size.width) / 2 + 30))

        self.m_coinNormal:setVisible(true)
        self.m_coinCompleted:setVisible(false)
    end
end

-- 新手集卡双倍奖励加成tagUI
function CardClanTitle:initDoubleRewardSignUI()
    local view = G_GetMgr(G_REF.CardNoviceSale):createDoubleRewardSignUI()
    local nodeTag = self:findChild("node_biaoqian")
    if view then
        nodeTag:addChild(view)
    end
end

return CardClanTitle
