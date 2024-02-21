---
--xcyy
--2018年5月23日
--DragonsWildLabView.lua

local DragonsWildLabView = class("DragonsWildLabView",util_require("base.BaseView"))


function DragonsWildLabView:initUI(num)

    self:createCsbNode("Socre_Dragons_Wild_Lab.csb")
    local lab = self:findChild("m_lb_Num") -- 获得子节点
    lab:setString("x" .. num)
   
end

function DragonsWildLabView:onEnter()
 

end

function DragonsWildLabView:onExit()
    
end

return DragonsWildLabView