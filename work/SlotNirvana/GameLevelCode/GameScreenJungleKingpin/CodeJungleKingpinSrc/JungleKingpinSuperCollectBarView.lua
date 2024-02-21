---
--xcyy
--2018年5月23日
--JungleKingpinSuperCollectBarView.lua

local JungleKingpinSuperCollectBarView = class("JungleKingpinSuperCollectBarView",util_require("base.BaseView"))


function JungleKingpinSuperCollectBarView:initUI()
    self:createCsbNode("JungleKingpin_SuperBonus.csb")
    self:runCsbAction("idle1",true)
end


function JungleKingpinSuperCollectBarView:onEnter()

end

function JungleKingpinSuperCollectBarView:onExit()

end

function JungleKingpinSuperCollectBarView:showCollectNum(_num)
    for i=1,5 do
        local node = self:findChild("JungleKingpin_jinbi_liang_" .. i)
        if _num >= i then
            node:setVisible(true)
        else
            node:setVisible(false)
        end
    end
end

function JungleKingpinSuperCollectBarView:resetCollectNum()
    for i=1,5 do
        local node = self:findChild("JungleKingpin_jinbi_liang_" .. i)
        node:setVisible(false)
    end
end

function JungleKingpinSuperCollectBarView:getCollectPos(_num)
    if _num >5 then
        return cc.p(0,0)
    end
    local node = self:findChild("JungleKingpin_jinbi_liang_" .. _num)
    local pos = node:getParent():convertToWorldSpace(cc.p(node:getPosition()))
    return pos
end

function JungleKingpinSuperCollectBarView:getEndPos(_num)
    if _num >5 then
        return cc.p(0,0)
    end
    local node = self:findChild("addPos" .. _num)
    local pos = cc.p(node:getPosition())
    return pos
end


function JungleKingpinSuperCollectBarView:setBotTouch(isEnable)
    self:findChild("Button_1"):setBright(isEnable)
    self:findChild("Button_1"):setTouchEnabled(isEnable)
end

function JungleKingpinSuperCollectBarView:clickFunc(sender)
    local name = sender:getName()
    if name == "Button_1" then
        gLobalNoticManager:postNotification("SHOW_TIP1")
    end
end

return JungleKingpinSuperCollectBarView