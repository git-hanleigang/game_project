-- 卡牌商店 碎片不足弹窗

local CardStoreLackLayer = class("CardStoreLackLayer", BaseLayer)

function CardStoreLackLayer:ctor()
    CardStoreLackLayer.super.ctor(self)

    local p_config = G_GetMgr(G_REF.CardStore):getConfig()
    -- 设置横屏csb
    self:setLandscapeCsbName(p_config.ChipsLackUI)
    self:setExtendData("CardStoreLackLayer")
end

function CardStoreLackLayer:initCsbNodes()
end

function CardStoreLackLayer:onShowedCallFunc()
    self:runCsbAction("idle", true)
end

function CardStoreLackLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    end
end

return CardStoreLackLayer
