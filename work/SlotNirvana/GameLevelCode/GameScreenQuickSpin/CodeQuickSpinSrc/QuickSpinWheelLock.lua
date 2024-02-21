---
--xcyy
--2018年5月23日
--QuickSpinWheelLock.lua

local QuickSpinWheelLock = class("QuickSpinWheelLock",util_require("base.BaseView"))


function QuickSpinWheelLock:initUI()

    self:createCsbNode("QuickSpin_suo.csb")

    self:runCsbAction("hide", true) -- 播放时间线
    local btn = self:findChild("btn") -- 获得子节点
    self:addClick(btn) -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end


function QuickSpinWheelLock:onEnter()

end

function QuickSpinWheelLock:show()
    self.m_isLock = false
    self:runCsbAction("show", false, function()
        if not self.m_isLock then
            self:runCsbAction("idle", true)
        end
    end)
end

function QuickSpinWheelLock:hide()
    self.m_isLock = true
    self:runCsbAction("animation0")
end

function QuickSpinWheelLock:onExit()

end

--默认按钮监听回调
function QuickSpinWheelLock:clickFunc(sender)
    -- gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_click.mp3")
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET)
end


return QuickSpinWheelLock