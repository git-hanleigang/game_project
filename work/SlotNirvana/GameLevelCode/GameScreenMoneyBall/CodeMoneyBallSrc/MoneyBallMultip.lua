---
--xcyy
--2018年5月23日
--MoneyBallMultip.lua

local MoneyBallMultip = class("MoneyBallMultip",util_require("base.BaseView"))

local MULTIP_ARRAY = {2, 3, 5, 8, 10}

function MoneyBallMultip:initUI()

    self:createCsbNode("MoneyBall_xbei.csb")

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
    for i = 1, #MULTIP_ARRAY, 1 do
        self:findChild("MoneyBall_x"..MULTIP_ARRAY[i]):setVisible(false)
    end
end

function MoneyBallMultip:showMultip(mul, func)
    self:findChild("MoneyBall_x"..mul):setVisible(true)
    self:runCsbAction("show", false, function()
        self:runCsbAction("idle", true)
        if func ~= nil then
            func()
        end
    end)
end

function MoneyBallMultip:hideMultip(mul)
    self:runCsbAction("over", false, function()
        self:findChild("MoneyBall_x"..mul):setVisible(false)
    end)
end

function MoneyBallMultip:onEnter()

end

function MoneyBallMultip:onExit()

end

--默认按钮监听回调
function MoneyBallMultip:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return MoneyBallMultip