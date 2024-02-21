---
--xcyy
--2018年5月23日
--QuickSpinWheelMultipAction.lua

local QuickSpinWheelMultipAction = class("QuickSpinWheelMultipAction",util_require("base.BaseView"))


function QuickSpinWheelMultipAction:initUI()

    self:createCsbNode("QuickSpin_zhizhen_light.csb")

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


function QuickSpinWheelMultipAction:onEnter()
    
end

function QuickSpinWheelMultipAction:showMultip(multip, func)
    self:runCsbAction("show"..multip, false, function()
        if func ~= nil then
            func()
        end
    end)
end

function QuickSpinWheelMultipAction:reset()
    self:runCsbAction("animation1", true)
end

function QuickSpinWheelMultipAction:lowerBetTipShow(func)
    self:runCsbAction("animation0", false, function()
        self:runCsbAction("animation1", true)
        if func ~= nil then
            func()
        end
    end)
end

function QuickSpinWheelMultipAction:onExit()
 
end

--默认按钮监听回调
function QuickSpinWheelMultipAction:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return QuickSpinWheelMultipAction