-- 卡牌商店 上赛季卡牌结算引导

local CardStoreGuideLayer = class("CardStoreGuideLayer", BaseLayer)

function CardStoreGuideLayer:ctor()
    CardStoreGuideLayer.super.ctor(self)

    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    -- 设置横屏csb
    self:setLandscapeCsbName(p_config.GuideUI)
    self:setExtendData("CardStoreGuideLayer")
end

function CardStoreGuideLayer:initCsbNodes()
    self.lb_greenchips = self:findChild("lb_greenchips")
    self.lb_goldchips = self:findChild("lb_goldchips")
end

function CardStoreGuideLayer:initView()
    local act_data = G_GetMgr(G_REF.CardStore):getRunningData()
    local normal_points = act_data:getGuideNormalPoints() or 0
    local golden_points = act_data:getGuideGoldenPoints() or 0
    self.lb_greenchips:setString("X" .. normal_points)
    self.lb_goldchips:setString("X" .. golden_points)

    G_GetMgr(G_REF.CardStore):requestCardStoreGuide()
end

function CardStoreGuideLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_collect" then
        self:closeUI()
    end
end

return CardStoreGuideLayer
