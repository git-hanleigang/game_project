---
--xcyy
--2018年5月23日
--GoldenMammothIcon.lua

local GoldenMammothIcon = class("GoldenMammothIcon",util_require("base.BaseView"))

function GoldenMammothIcon:initUI()

    self:createCsbNode("GoldenMammoth_top_coins.csb")
    
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
    self:showUnselected()
end

function GoldenMammothIcon:onEnter()
 

end

function GoldenMammothIcon:onExit()
 
end

function GoldenMammothIcon:showUnselected()
    self:runCsbAction("idleframe1")
end

function GoldenMammothIcon:triggerFs(func)
    self:runCsbAction("animation", false, function()
        if func ~= nil then
            func()
        end
    end)
end

function GoldenMammothIcon:showIdle()
    self:runCsbAction("idleframe2")
end

function GoldenMammothIcon:triggerSuperFs(func)
    self:runCsbAction("animation2")
end

return GoldenMammothIcon