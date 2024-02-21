---
--xcyy
--2018年5月23日
--PussKMapNodeView.lua

local PussKMapNodeView = class("PussKMapNodeView",util_require("base.BaseView"))


function PussKMapNodeView:initUI(csbName)

    self:createCsbNode(csbName..".csb")

   

end

function PussKMapNodeView:onEnter()
 

end

function PussKMapNodeView:onExit()
 
end


return PussKMapNodeView