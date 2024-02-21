---
--xcyy
--2018年5月23日
--QuickSpinWheelStart.lua

local QuickSpinWheelStart = class("QuickSpinWheelStart",util_require("base.BaseView"))
QuickSpinWheelStart.m_clickFlag = nil
QuickSpinWheelStart.m_clickCallback = nil
function QuickSpinWheelStart:initUI()

    self:createCsbNode("QuickSpin_Wheel_start.csb")

    self:runCsbAction("idle") -- 播放时间线
    local btn = self:findChild("btn") -- 获得子节点
    self:addClick(btn) -- 非按钮节点得手动绑定监听
    self.m_clickFlag = false
    self:setVisible(false)
    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end

function QuickSpinWheelStart:show(func)
    self:setVisible(true)
    self.m_clickCallback = func
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        self.m_clickFlag = true
    end)
end

function QuickSpinWheelStart:onEnter()
 

end

function QuickSpinWheelStart:onExit()
 
end

function QuickSpinWheelStart:clickFunc(sender)
    if self.m_clickFlag == false then
        return
    end
    self.m_clickFlag = false
    gLobalSoundManager:playSound("QuickSpinSounds/sound_QuickSpin_wheel_start_click.mp3")
    self:runCsbAction("over", false, function()
        self:setVisible(false)
        if self.m_clickCallback ~= nil then
            self.m_clickCallback()
        end
    end)
end

return QuickSpinWheelStart