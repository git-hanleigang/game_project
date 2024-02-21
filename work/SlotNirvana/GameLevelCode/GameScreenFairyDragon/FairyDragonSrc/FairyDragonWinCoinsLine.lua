---
--FairyDragonWinCoinsLine.lua

local FairyDragonWinCoinsLine = class("FairyDragonWinCoinsLine", util_require("base.BaseView"))

function FairyDragonWinCoinsLine:initUI()
    self:createCsbNode("FairyDragon_Jackpot_wanfa_jinbishengzhang.csb")
    for i = 1, 43 do
        local node = self:findChild("jin_" .. i)
        node:setVisible(false)
    end
end

function FairyDragonWinCoinsLine:onEnter()
end

function FairyDragonWinCoinsLine:onExit()
end

function FairyDragonWinCoinsLine:showLines(_num)
    if _num > 43 then
        return
    end
    self:findChild("jinbishengzhangzong"):setVisible(true)
    
    local node = self:findChild("jin_" .. _num)
    node:setVisible(true)
    local pos = cc.p(node:getPosition())

    local yanhua1 = self:createYanHua()
    yanhua1:runCsbAction("actionframe",false,function ( )
        yanhua1:removeFromParent()
    end)
    self:findChild("jinbishengzhangzong"):addChild(yanhua1,100)
    yanhua1:setPosition(cc.p(pos.x,pos.y + 20))
end

function FairyDragonWinCoinsLine:createYanHua( )
    local yanhua = util_createAnimation("FairyDragon_Jackpot_wanfa_bengjianhuohua.csb")
    return yanhua
end
function FairyDragonWinCoinsLine:showNewLines(_num)
    for i = 1, _num do
        local node = self:findChild("jin_" .. i)
        node:setVisible(true)
    end
end

return FairyDragonWinCoinsLine
