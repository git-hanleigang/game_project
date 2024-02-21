---
--xcyy
--2018年5月23日
--QuickSpinRespinStart.lua

local QuickSpinRespinStart = class("QuickSpinRespinStart",util_require("base.BaseView"))

function QuickSpinRespinStart:initUI()

    self:createCsbNode("QuickSpin/QuickSpin_Wheel_words2.csb")
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

function QuickSpinRespinStart:show(callback)
    self:setVisible(true)
    self:runCsbAction("auto", false, function()
        self:setVisible(false)
        if callback then
            callback()
        end
    end)
end


function QuickSpinRespinStart:onEnter()


end

function QuickSpinRespinStart:onExit()

end

return QuickSpinRespinStart