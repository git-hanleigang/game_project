---
--xcyy
--2018年5月23日
--FoodStreetSpinNum.lua

local FoodStreetSpinNum = class("FoodStreetSpinNum",util_require("base.BaseView"))


function FoodStreetSpinNum:initUI()

    self:createCsbNode("FoodStreet_spinsleft.csb")

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

end

function FoodStreetSpinNum:setLabNum(num)
    self:findChild("m_lb_num"):setString(num)
end

function FoodStreetSpinNum:onEnter()

end

function FoodStreetSpinNum:onExit()
 
end

return FoodStreetSpinNum