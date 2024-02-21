---
--xcyy
--2018年5月23日
--AladdinWheelBtn.lua

local AladdinWheelBtn = class("AladdinWheelBtn",util_require("base.BaseView"))


function AladdinWheelBtn:initUI()

    self:createCsbNode("Aladdin_Wheel_anniu.csb")

    self:runCsbAction("idleframe") -- 播放时间线
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


function AladdinWheelBtn:onEnter()
 

end

function AladdinWheelBtn:showClickAnim(func)
    self:runCsbAction("idleframe", false, function()
        self:runCsbAction("idleframe", true)
        if func ~= nil then
            func()
        end
    end)
end

function AladdinWheelBtn:showIdle()
    self:runCsbAction("idleframe2")
end

function AladdinWheelBtn:showAdd()
    
end
function AladdinWheelBtn:onExit()
 
end

--默认按钮监听回调
function AladdinWheelBtn:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AladdinWheelBtn