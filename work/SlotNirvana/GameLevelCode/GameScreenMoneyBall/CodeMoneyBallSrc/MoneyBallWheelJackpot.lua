---
--xcyy
--2018年5月23日
--MoneyBallWheelJackpot.lua

local MoneyBallWheelJackpot = class("MoneyBallWheelJackpot",util_require("base.BaseView"))


function MoneyBallWheelJackpot:initUI(data)

    self:createCsbNode("MoneyBall_jackpot_zi.csb")
    self.m_type = data
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
    self:showIdle()
    util_setCascadeOpacityEnabledRescursion(self,true)
end

function MoneyBallWheelJackpot:showAnim()
    self:runCsbAction("reward_"..self.m_type, true)
end

function MoneyBallWheelJackpot:showIdle()
    self:runCsbAction("idle_"..self.m_type)
end

function MoneyBallWheelJackpot:onEnter()

end

function MoneyBallWheelJackpot:onExit()
 
end

--默认按钮监听回调
function MoneyBallWheelJackpot:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return MoneyBallWheelJackpot