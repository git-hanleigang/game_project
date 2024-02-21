---
--xcyy
--2018年5月23日
--QuickSpinWheelWords.lua

local QuickSpinWheelWords = class("QuickSpinWheelWords",util_require("base.BaseView"))

function QuickSpinWheelWords:initUI()

    self:createCsbNode("QuickSpin_Wheel_words.csb")
    self:setVisible(false)
    -- self:runCsbAction("start") -- 播放时间线

    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end

function QuickSpinWheelWords:show()
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle")
    end)
end

function QuickSpinWheelWords:hide()
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

function QuickSpinWheelWords:onEnter()
 

end

function QuickSpinWheelWords:onExit()
 
end

return QuickSpinWheelWords