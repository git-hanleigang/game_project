local CardSeasonBottomNadoMachine = class("CardSeasonBottomNadoMachine", BaseView)

function CardSeasonBottomNadoMachine:getCsbName()
    return "CardRes/season202204/cash_season_nadoMachine.csb"
end

function CardSeasonBottomNadoMachine:getRedPointLua()
    return "GameModule.Card.season202204.CardRedPoint"
end

function CardSeasonBottomNadoMachine:initCsbNodes()
    local touch = self:findChild("touch")
    self:addClick(touch)
    self.m_nodeRedPoint = self:findChild("Node_num")
end

function CardSeasonBottomNadoMachine:initUI()
    CardSeasonBottomNadoMachine.super.initUI(self)
    self:initRedPoint()
end

function CardSeasonBottomNadoMachine:initRedPoint()
    self.m_redPoint = util_createView(self:getRedPointLua())
    self.m_nodeRedPoint:addChild(self.m_redPoint)
    self:updateNum()
end

function CardSeasonBottomNadoMachine:updateNum()
    -- local linkGameData = CardSysRuntimeMgr:getLinkGameData()
    -- local leftNum = linkGameData and linkGameData.nadoGames or 0
    local leftNum = CardSysRuntimeMgr:getNadoGameLeftCount() or 0
    if leftNum > 0 then
        self.m_redPoint:setVisible(true)
        leftNum = math.min(999, leftNum)
        self.m_redPoint:updateNum(leftNum)
    else
        self.m_redPoint:setVisible(false)
    end
end

function CardSeasonBottomNadoMachine:clickFunc(sender)
    local name = sender:getName()
    if name == "touch" then
        CardSysManager:showNadoMachine("menu")
    end
end

function CardSeasonBottomNadoMachine:onEnter()
    CardSeasonBottomNadoMachine.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function(params)
            self:updateNum()
        end,
        CardSysConfigs.ViewEventType.CARD_NADO_WHEEL_ROLL_OVER
    )
    gLobalNoticManager:addObserver(
        self,
        function(params)
            self:updateNum()
        end,
        ViewEventType.NOTIFY_CARD_SYS_OVER
    )
end

return CardSeasonBottomNadoMachine
