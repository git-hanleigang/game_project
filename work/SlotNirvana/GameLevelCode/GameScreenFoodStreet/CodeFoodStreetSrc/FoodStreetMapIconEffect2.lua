---
--xcyy
--2018年5月23日
--FoodStreetView.lua

local FoodStreetView = class("FoodStreetView",util_require("base.BaseView"))


function FoodStreetView:initUI()

    self:createCsbNode("FoodStreet_anniusaoguang_2.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)
    self:runCsbAction("idle2", true)
    util_setCascadeOpacityEnabledRescursion(self, true)
end


function FoodStreetView:onEnter()
 

end

function FoodStreetView:showAdd()
    
end
function FoodStreetView:onExit()
 
end

--默认按钮监听回调
function FoodStreetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FoodStreetView