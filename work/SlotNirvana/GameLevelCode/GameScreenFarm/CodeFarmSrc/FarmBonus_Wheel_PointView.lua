---
--xcyy
--2018年5月23日
--FarmBonus_Wheel_PointView.lua

local FarmBonus_Wheel_PointView = class("FarmBonus_Wheel_PointView",util_require("base.BaseView"))


function FarmBonus_Wheel_PointView:initUI()

    self:createCsbNode("Farm_zhuanpan_jiantou.csb")


    self:runCsbAction("idleframe",true,nil,60)
    

end


function FarmBonus_Wheel_PointView:onEnter()
 

end


function FarmBonus_Wheel_PointView:onExit()
 
end

--默认按钮监听回调
function FarmBonus_Wheel_PointView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FarmBonus_Wheel_PointView