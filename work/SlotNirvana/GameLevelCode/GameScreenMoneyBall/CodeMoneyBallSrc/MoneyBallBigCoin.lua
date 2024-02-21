---
--xcyy
--2018年5月23日
--MoneyBallBigCoin.lua

local MoneyBallBigCoin = class("MoneyBallBigCoin",util_require("base.BaseView"))


function MoneyBallBigCoin:initUI()

    self:createCsbNode("MoneyBall_BigCoins.csb")

    -- self:runCsbAction("idleframe") -- 播放时间线
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
    self.m_particle = self:findChild("Particle_1")
    self.m_particle:stopSystem()
    self:idleAnim()
end

function MoneyBallBigCoin:idleAnim()
    self:runCsbAction("idleframe", true)
end

function MoneyBallBigCoin:idleFSAnim()
    self:runCsbAction("idleframe2", true)
end

function MoneyBallBigCoin:hideAnim()
    self:runCsbAction("over")
end

function MoneyBallBigCoin:triggerAnim(func)
    self.m_particle:resetSystem()
    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            func()
        end
        self:runCsbAction("idleframe1", true)
    end)
end

function MoneyBallBigCoin:onEnter()

end

function MoneyBallBigCoin:showAdd()
    
end
function MoneyBallBigCoin:onExit()
 
end

--默认按钮监听回调
function MoneyBallBigCoin:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return MoneyBallBigCoin