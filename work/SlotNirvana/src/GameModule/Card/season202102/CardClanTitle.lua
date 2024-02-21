--[[
    卡组的标题
    201904
]]
local CardClanTitle201903 = util_require("GameModule.Card.season201903.CardClanTitle")
local CardClanTitle = class("CardClanTitle", CardClanTitle201903)

function CardClanTitle:getCsbName()
    return string.format(CardResConfig.seasonRes.CardClanTitleRes, "season202102")
end

-- 不需要灯光
function CardClanTitle:initTitleLight()
end

-- 子类重写
function CardClanTitle:getQuestInfoLua()
    return "GameModule.Card.season202102.CardClanQuestInfo"
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
        local statueBuffUI = util_createView("views.buffTip.CardStatueBuffTipNode", nMuti)
        self.m_nodeStatueBuff:addChild(statueBuffUI)
    end
end
--[[-- 赛季新增雕塑buff 结束------------------------------------------------- ]]  

function CardClanTitle:onEnter()
    CardClanTitle.super.onEnter(self)

    -- -- TODO:MAQUN 赛季结束发送消息刷新buff标签
    -- gLobalNoticManager:addObserver(self, function(target, params)
    --     self:initStatueBuffNode()
    -- end, "CARD_SEASON_OVER")

    gLobalNoticManager:addObserver(self, function(target, params)
        self:initStatueBuffNode()
    end, ViewEventType.NOTIFY_MULEXP_END)
end

return CardClanTitle