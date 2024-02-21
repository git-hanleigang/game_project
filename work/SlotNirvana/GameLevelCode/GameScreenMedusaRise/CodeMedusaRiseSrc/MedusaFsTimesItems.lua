---
--xcyy
--2018年5月23日
--MedusaFsTimesItems.lua

local MedusaFsTimesItems = class("MedusaFsTimesItems",util_require("base.BaseView"))


function MedusaFsTimesItems:initUI()

    self:createCsbNode("MedusaRise_bet_collect.csb")

     -- 播放时间线
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

function MedusaFsTimesItems:showIdle()
    self:runCsbAction("idleframe")
end

function MedusaFsTimesItems:onEnter()
 

end

function MedusaFsTimesItems:showTriggerAnim(func)
    self:runCsbAction("actionframe", false, function()
        if func ~= nil then
            performWithDelay(self, function()
                func()
            end, 0.5)
        end
        self:runCsbAction("idleframe1")
    end)
end

function MedusaFsTimesItems:showTriggerIdle( )
    self:runCsbAction("idleframe1")
end

function MedusaFsTimesItems:onExit()
 
end


return MedusaFsTimesItems