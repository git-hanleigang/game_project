---
--xcyy
--2018年5月23日
--QuickSpinWheelPoint.lua

local QuickSpinWheelPoint = class("QuickSpinWheelPoint",util_require("base.BaseView"))


function QuickSpinWheelPoint:initUI()

    self:createCsbNode("QuickSpin_jiantou.csb")
    self:setVisible(false)
    -- self:runCsbAction("idle") -- 播放时间线
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


function QuickSpinWheelPoint:onEnter()
 

end

function QuickSpinWheelPoint:show()
    self:setVisible(true)
    self:runCsbAction("show", false, function()
        self:runCsbAction("idle", true)
    end)
end

function QuickSpinWheelPoint:hide()
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

function QuickSpinWheelPoint:onExit()
 
end

--默认按钮监听回调
function QuickSpinWheelPoint:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return QuickSpinWheelPoint