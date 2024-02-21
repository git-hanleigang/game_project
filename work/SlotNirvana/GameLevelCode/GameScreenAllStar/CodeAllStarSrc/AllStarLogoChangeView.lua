---
--xcyy
--2018年5月23日
--AllStarLogoChangeView.lua

local AllStarLogoChangeView = class("AllStarLogoChangeView",util_require("base.BaseView"))


function AllStarLogoChangeView:initUI()

    self:createCsbNode("AllStar_logo_change.csb")


end


function AllStarLogoChangeView:onEnter()
 

end

function AllStarLogoChangeView:showAdd()
    
end
function AllStarLogoChangeView:onExit()
 
end

--默认按钮监听回调
function AllStarLogoChangeView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AllStarLogoChangeView