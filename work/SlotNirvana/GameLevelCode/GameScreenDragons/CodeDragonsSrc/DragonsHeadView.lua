---
--xcyy
--2018年5月23日
--DragonsHeadView.lua

local DragonsHeadView = class("DragonsHeadView",util_require("base.BaseView"))


function DragonsHeadView:initUI()
    
    self:createCsbNode("Dragons_longtou.csb")

end

function DragonsHeadView:onEnter()
 

end

function DragonsHeadView:showAdd()
    
end
function DragonsHeadView:onExit()
 
end

--默认按钮监听回调
function DragonsHeadView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return DragonsHeadView