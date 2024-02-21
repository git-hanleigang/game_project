---
--xcyy
--2018年5月23日
--EgyptView.lua

local EgyptView = class("EgyptView",util_require("base.BaseView"))


function EgyptView:initUI(data)

    self:createCsbNode("Egypt_Jackpot_lock.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    self:addClick(self:findChild("click")) -- 非按钮节点得手动绑定监听

    self.m_level = data
    self.m_lb_bet = self:findChild("m_lb_bet")
    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

end


function EgyptView:onEnter()
 
end


function EgyptView:onExit()
 
end

function EgyptView:showUnlock()
    self:runCsbAction("unlock")
end

function EgyptView:showLock()
    self:runCsbAction("lock")
end

function EgyptView:initLabBet(coins)
    self.m_lb_bet:setString("$"..util_formatCoins(coins, 3,nil,nil))
end

--默认按钮监听回调
function EgyptView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UNLOCK_JACKPOT_BET, self.m_level)
end


return EgyptView