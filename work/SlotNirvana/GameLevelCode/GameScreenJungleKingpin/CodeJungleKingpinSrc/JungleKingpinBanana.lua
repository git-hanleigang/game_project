local JungleKingpinBanana = class("JungleKingpinBanana",util_require("base.BaseView"))


function JungleKingpinBanana:initUI(_type)
    self._type = _type
    local csbName = "JungleKingpin_Banana.csb"
    self:createCsbNode(csbName)
end

function JungleKingpinBanana:showBananaType()
    if  self._type  == 2 then
        self:findChild("mini"):setVisible(false)
        self:findChild("major"):setVisible(false)
        self:findChild("grand"):setVisible(false)
        self:findChild("m_lb_num"):setVisible(true)
    elseif  self._type  == 3 then
        self:findChild("mini"):setVisible(false)
        self:findChild("major"):setVisible(false)
        self:findChild("grand"):setVisible(false)
        self:findChild("m_lb_num"):setVisible(true)
    elseif  self._type  == 4 then
        self:findChild("mini"):setVisible(true)
        self:findChild("major"):setVisible(false)
        self:findChild("grand"):setVisible(false)
        self:findChild("m_lb_num"):setVisible(false)
        -- self:runCsbAction("Mini",true)
    elseif  self._type  == 5 then
        self:findChild("mini"):setVisible(false)
        self:findChild("major"):setVisible(true)
        self:findChild("grand"):setVisible(false)
        self:findChild("m_lb_num"):setVisible(false)
        -- self:runCsbAction("Major",true)
    elseif  self._type  == 6 then
        self:findChild("mini"):setVisible(false)
        self:findChild("major"):setVisible(false)
        self:findChild("grand"):setVisible(true)
        self:findChild("m_lb_num"):setVisible(false)
        -- self:runCsbAction("Grand",true)
    end
end

function JungleKingpinBanana:changeBonusNum(value)
    local label = self:findChild("m_lb_num")
    label:setString(util_formatCoins(value,3,nil,nil,true))
end


function JungleKingpinBanana:onEnter()
 

end

function JungleKingpinBanana:onExit()
 
end


return JungleKingpinBanana