---
--xcyy
--2018年5月23日
--BuffaloWildView.lua

local BuffaloWildView = class("BuffaloWildView",util_require("base.BaseView"))


function BuffaloWildView:initUI()

    self:createCsbNode("xxxx/xxxxxxx.csb")

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


function BuffaloWildView:onEnter()
 

end

function BuffaloWildView:showAdd()
    
end
function BuffaloWildView:onExit()
 
end

--默认按钮监听回调
function BuffaloWildView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return BuffaloWildView