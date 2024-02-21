---
--xcyy
--2018年5月23日
--FarmGuoChangView.lua

local FarmGuoChangView = class("FarmGuoChangView",util_require("base.BaseView"))


function FarmGuoChangView:initUI()

    self:createCsbNode("Farm_switch.csb")


end


function FarmGuoChangView:onEnter()
 

end

function FarmGuoChangView:showAdd()
    
end
function FarmGuoChangView:onExit()
 
end

--默认按钮监听回调
function FarmGuoChangView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FarmGuoChangView