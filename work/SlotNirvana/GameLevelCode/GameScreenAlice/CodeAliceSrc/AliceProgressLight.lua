---
--xcyy
--2018年5月23日
--AliceProgressLight.lua

local AliceProgressLight = class("AliceProgressLight",util_require("base.BaseView"))


function AliceProgressLight:initUI()

    self:createCsbNode("Alice_progress_0.csb")

    self:runCsbAction("idle", true) -- 播放时间线
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
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:setOpacity(0)
end


function AliceProgressLight:onEnter()
 

end

function AliceProgressLight:onExit()
 
end

return AliceProgressLight