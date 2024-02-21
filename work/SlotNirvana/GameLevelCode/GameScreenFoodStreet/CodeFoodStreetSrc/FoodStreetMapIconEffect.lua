---
--xcyy
--2018年5月23日
--FoodStreetMapIconEffect.lua

local FoodStreetMapIconEffect = class("FoodStreetMapIconEffect",util_require("base.BaseView"))


function FoodStreetMapIconEffect:initUI()

    self:createCsbNode("FoodStreet_anniusaoguang_1.csb")

    self:runCsbAction("idle2", true)
    util_setCascadeOpacityEnabledRescursion(self, true)
end


function FoodStreetMapIconEffect:onEnter()
 

end

function FoodStreetMapIconEffect:showAdd()
    
end
function FoodStreetMapIconEffect:onExit()
 
end

--默认按钮监听回调
function FoodStreetMapIconEffect:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FoodStreetMapIconEffect