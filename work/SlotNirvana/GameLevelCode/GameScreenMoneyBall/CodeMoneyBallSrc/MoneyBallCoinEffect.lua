---
--xcyy
--2018年5月23日
--MoneyBallCoinEffect.lua

local MoneyBallCoinEffect = class("MoneyBallCoinEffect",util_require("base.BaseView"))


function MoneyBallCoinEffect:initUI(data)

    self:createCsbNode("MoneyBall_Coin_collectxian"..data..".csb")

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
    -- self:setVisible(false)
end

function MoneyBallCoinEffect:showAnim(func)
    self:setVisible(true)
    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            func()
        end
        self:setVisible(false)
    end)
end

function MoneyBallCoinEffect:onEnter()

end

function MoneyBallCoinEffect:onExit()
 
end

return MoneyBallCoinEffect