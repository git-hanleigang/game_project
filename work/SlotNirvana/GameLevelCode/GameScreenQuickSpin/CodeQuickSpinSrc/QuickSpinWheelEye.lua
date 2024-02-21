---
--xcyy
--2018年5月23日
--QuickSpinWheelEye.lua

local QuickSpinWheelEye = class("QuickSpinWheelEye",util_require("base.BaseView"))


function QuickSpinWheelEye:initUI()

    self:createCsbNode("QuickSpin_yan.csb")

    self:runCsbAction("idle", true) -- 播放时间线
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


function QuickSpinWheelEye:onEnter()
 

end

function QuickSpinWheelEye:show()
    self:runCsbAction("show", false, function()
        self:runCsbAction("idle", true)
    end)
end

function QuickSpinWheelEye:hide(func)
    self:runCsbAction("over", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function QuickSpinWheelEye:onExit()

end

return QuickSpinWheelEye