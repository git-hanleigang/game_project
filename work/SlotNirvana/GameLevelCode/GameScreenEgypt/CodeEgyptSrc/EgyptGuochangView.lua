---
--xcyy
--2018年5月23日
--EgyptGuochangView.lua

local EgyptGuochangView = class("EgyptGuochangView",util_require("base.BaseView"))


function EgyptGuochangView:initUI()

    self:createCsbNode("WinEgypt_guochang.csb")

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

function EgyptGuochangView:showAnimation(func, overCall)
    gLobalSoundManager:playSound("EgyptSounds/sound_Egypt_guochang.mp3")
    self:runCsbAction("actionframe", false, function()
        if overCall then
            overCall()
        end
    end)
    performWithDelay(self, function ()
	    if func ~= nil then
            func()
        end
    end, 1)
end

function EgyptGuochangView:onEnter()
 
end

function EgyptGuochangView:onExit()
 
end


return EgyptGuochangView