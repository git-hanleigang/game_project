---
--xcyy
--2018年5月23日
--DragonsView.lua

local DragonsView = class("DragonsView",util_require("base.BaseView"))


function DragonsView:initUI()

    self:createCsbNode("xxxx/xxxxxxx.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
 
end


function DragonsView:onEnter()
 

end

function DragonsView:showAdd()
    
end
function DragonsView:onExit()
 
end

--默认按钮监听回调
function DragonsView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return DragonsView