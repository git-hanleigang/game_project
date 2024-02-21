---
--xcyy
--2018年5月23日
--QuickSpinWheelMultip.lua

local QuickSpinWheelMultip = class("QuickSpinWheelMultip",util_require("base.BaseView"))
QuickSpinWheelMultip.m_iMultip = nil

function QuickSpinWheelMultip:initUI()

    self:createCsbNode("QuickSpin_2345.csb")

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


function QuickSpinWheelMultip:onEnter()
 

end

function QuickSpinWheelMultip:show(multip, func)
    self.m_iMultip = multip
    self:runCsbAction("show"..self.m_iMultip, false, function()
        self:runCsbAction("idle"..self.m_iMultip, true)
        if func ~= nil then
            func()
        end
    end)
end

function QuickSpinWheelMultip:hide(func)
    self:runCsbAction("over"..self.m_iMultip, false, function()
        if func ~= nil then
            func()
        end
    end)
end

function QuickSpinWheelMultip:onExit()
 
end

--默认按钮监听回调
function QuickSpinWheelMultip:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return QuickSpinWheelMultip