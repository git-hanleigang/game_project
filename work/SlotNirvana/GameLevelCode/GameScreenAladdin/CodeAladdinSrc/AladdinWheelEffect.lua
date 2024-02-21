---
--xcyy
--2018年5月23日
--AladdinWheelEffect.lua

local AladdinWheelEffect = class("AladdinWheelEffect",util_require("base.BaseView"))


function AladdinWheelEffect:initUI()

    self:createCsbNode("Aladdin_Wheel_zhongjiang.csb")
end


function AladdinWheelEffect:onEnter()
 

end

function AladdinWheelEffect:showRewardAnim(index)
    self:setVisible(true)
    self:runCsbAction("actionframe"..index, true)
end

function AladdinWheelEffect:onExit()
 
end


return AladdinWheelEffect