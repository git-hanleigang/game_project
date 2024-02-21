---
--xcyy
--2018年5月23日
--ClassicCashLogoChangeView.lua

local ClassicCashLogoChangeView = class("ClassicCashLogoChangeView",util_require("base.BaseView"))


function ClassicCashLogoChangeView:initUI()

    self:createCsbNode("ClassicCash_logo_change.csb")


end


function ClassicCashLogoChangeView:onEnter()
 

end

function ClassicCashLogoChangeView:showAdd()
    
end
function ClassicCashLogoChangeView:onExit()
 
end

--默认按钮监听回调
function ClassicCashLogoChangeView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ClassicCashLogoChangeView