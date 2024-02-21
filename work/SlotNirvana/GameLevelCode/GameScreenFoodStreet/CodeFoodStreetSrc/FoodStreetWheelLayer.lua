---
--xcyy
--2018年5月23日
--FoodStreetWheelLayer.lua

local FoodStreetWheelLayer = class("FoodStreetWheelLayer",util_require("base.BaseView"))


function FoodStreetWheelLayer:initUI(data)

    self:createCsbNode("FoodStreet/zhuanpantanban.csb")


    local wheel = util_createView("CodeFoodStreetSrc.FoodStreetWheelView", data)
    self:findChild("zhuanpan_0"):addChild(wheel)
    self:runCsbAction("start")
    wheel:initCallBack(function()
         self:rotationOver(function()
             if data.func ~= nil then
                 data.func()
             end
             self:removeFromParent()
         end)                           
    end)
end

function FoodStreetWheelLayer:rotationOver(func)
    self:runCsbAction("over", false, function()
        if func ~= nil then
            func()

        end
    end)
end

function FoodStreetWheelLayer:onEnter()

end

function FoodStreetWheelLayer:onExit()
 
end

--默认按钮监听回调
function FoodStreetWheelLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FoodStreetWheelLayer