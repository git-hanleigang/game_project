---
--xcyy
--2018年5月23日
--QuickSpinWheelBgLight.lua

local QuickSpinWheelBgLight = class("QuickSpinWheelBgLight",util_require("base.BaseView"))


function QuickSpinWheelBgLight:initUI()

    self:createCsbNode("QuickSpin_Wheel_bglight.csb")

    self:runCsbAction("actionframe", true) -- 播放时间线
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


function QuickSpinWheelBgLight:onEnter()
 

end

function QuickSpinWheelBgLight:onExit()
 
end

return QuickSpinWheelBgLight