--[[--
    商城入口
]]
local CardSeasonBottomStore = class("CardSeasonBottomStore", BaseView)

function CardSeasonBottomStore:initDatas()
end

function CardSeasonBottomStore:getCsbName()
    return string.format("CardRes/season202301/cash_season_Store.csb")
end

function CardSeasonBottomStore:initCsbNodes()
    self.m_nodeRedPoint = self:findChild("node_redPoint")
    self.m_nodeTime = self:findChild("node_time")
    self.m_lbTime = self:findChild("lb_time")

    self.m_touch = self:findChild("Panel_touch")
    self:addClick(self.m_touch)
end

function CardSeasonBottomStore:initUI()
    CardSeasonBottomStore.super.initUI(self)
    self:showRedPoint()
end

function CardSeasonBottomStore:clickFunc(sender)
    local name = sender:getName()
    if name == "Panel_touch" then
        G_GetMgr(G_REF.CardStore):showMainLayer()
    end
end

function CardSeasonBottomStore:onEnter()
    CardSeasonBottomStore.super.onEnter(self)

    gLobalNoticManager:addObserver(
        self,
        function()
            self:showRedPoint()
        end,
        ViewEventType.NOTIFY_EVENT_CARD_STORE_REFRESH
    )

    gLobalNoticManager:addObserver(
        self,
        function()
            self:showRedPoint()
        end,
        ViewEventType.NOTIFY_EVENT_CARD_STORE_RESET
    )
end

function CardSeasonBottomStore:showRedPoint()
    local store_data = G_GetMgr(G_REF.CardStore):getRunningData()
    if not store_data then
        return
    end

    if not self.m_redPoint then
        local redPoint = util_createView("GameModule.Card.season202301.CardRedPoint")
        if redPoint then
            redPoint:addTo(self.m_nodeRedPoint)
            redPoint:updateNum(1)
            self.m_redPoint = redPoint
        end
    end

    if self.m_redPoint then
        local bl_collect = store_data:getCanGiftCollect()
        self.m_redPoint:setVisible(bl_collect == true)
    end
end

return CardSeasonBottomStore
