---
--xcyy
--2018年5月23日
--AliceMapGameIconEffect.lua

local AliceMapGameIconEffect = class("AliceMapGameIconEffect",util_require("base.BaseView"))


function AliceMapGameIconEffect:initUI(data)

    self:createCsbNode("Alice_Map_lizi.csb")
    
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


function AliceMapGameIconEffect:onEnter()
 

end

function AliceMapGameIconEffect:showIdle()
    self:runCsbAction("idle", true)
end

function AliceMapGameIconEffect:showAnim()
    gLobalSoundManager:playSound("AliceSounds/sound_Alice_map_icon_effect.mp3")
    self:runCsbAction("actionframe", false, function()
        self:showIdle()
    end)
end

function AliceMapGameIconEffect:onExit()
 
end

return AliceMapGameIconEffect