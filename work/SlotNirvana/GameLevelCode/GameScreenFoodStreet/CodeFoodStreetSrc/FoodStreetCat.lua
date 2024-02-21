---
--xcyy
--2018年5月23日
--FoodStreetCat.lua

local FoodStreetCat = class("FoodStreetCat",util_require("base.BaseView"))


function FoodStreetCat:initUI()

    self:createCsbNode("FoodStreet_mao.csb")

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
    
end

function FoodStreetCat:onEnter()

end

function FoodStreetCat:onExit()
 
end

function FoodStreetCat:runAnim(animName,loop,func)
    self:runCsbAction(animName, loop, function()
        if func ~= nil then
            func()
        end
    end)
end

return FoodStreetCat