---
--xcyy
--2018年5月23日
--MedusaRiseScatterItem.lua

local MedusaRiseScatterItem = class("MedusaRiseScatterItem",util_require("base.BaseView"))


function MedusaRiseScatterItem:initUI()

    self:createCsbNode("MedusaRise_tishi_collect.csb")

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
    self:showStart()
end


function MedusaRiseScatterItem:onEnter()
 
end

function MedusaRiseScatterItem:showAnimation(func)
    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function MedusaRiseScatterItem:showStart()
    self:runCsbAction("idleframe")
end

function MedusaRiseScatterItem:showIdleframe()
    self:runCsbAction("idleframe1")
end

function MedusaRiseScatterItem:onExit()
 
end


return MedusaRiseScatterItem