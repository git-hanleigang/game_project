---
--xcyy
--2018年5月23日
--AliceMapPoint.lua

local AliceMapPoint = class("AliceMapPoint",util_require("base.BaseView"))


function AliceMapPoint:initUI()

    self:createCsbNode("Alice_Map_point.csb")

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
    self:idle()
end

function AliceMapPoint:idle()
    self:runCsbAction("idleframe1")
end

function AliceMapPoint:pointAnimation()
    self:runCsbAction("actionframe")
end

function AliceMapPoint:ponitIdle()
    self:runCsbAction("idleframe2")
end

function AliceMapPoint:onEnter()
 

end

function AliceMapPoint:showAdd()
    
end
function AliceMapPoint:onExit()
 
end

--默认按钮监听回调
function AliceMapPoint:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AliceMapPoint