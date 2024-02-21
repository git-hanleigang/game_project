---
--xcyy
--2018年5月23日
--FoodStreetWheelCoin.lua

local FoodStreetWheelCoin = class("FoodStreetWheelCoin",util_require("base.BaseView"))


function FoodStreetWheelCoin:initUI(data)

    self:createCsbNode(data.name)

    local lab = self:findChild("m_lb_num")
    lab:setString(util_formatCoins(data.coin, 3))
end


function FoodStreetWheelCoin:onEnter()
 

end

function FoodStreetWheelCoin:onExit()
 
end

return FoodStreetWheelCoin