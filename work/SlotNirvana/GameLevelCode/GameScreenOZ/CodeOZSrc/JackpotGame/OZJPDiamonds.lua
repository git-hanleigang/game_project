---
--xcyy
--2018年5月23日
--OZJPDiamonds.lua

local OZJPDiamonds = class("OZJPDiamonds",util_require("base.BaseView"))


function OZJPDiamonds:initUI(csbpath)

    self:createCsbNode( csbpath .. ".csb")

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


function OZJPDiamonds:onEnter()
 

end

function OZJPDiamonds:showAdd()
    
end
function OZJPDiamonds:onExit()
 
end

--默认按钮监听回调
function OZJPDiamonds:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return OZJPDiamonds