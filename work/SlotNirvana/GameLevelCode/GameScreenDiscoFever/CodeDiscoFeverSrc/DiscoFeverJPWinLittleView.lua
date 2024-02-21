---
--xcyy
--2018年5月23日
--DiscoFeverJPWinLittleView.lua

local DiscoFeverJPWinLittleView = class("DiscoFeverJPWinLittleView",util_require("base.BaseView"))


function DiscoFeverJPWinLittleView:initUI()

    self:createCsbNode("DiscoFever_levelup.csb")

end


function DiscoFeverJPWinLittleView:onEnter()
 

end

function DiscoFeverJPWinLittleView:showAdd()
    
end
function DiscoFeverJPWinLittleView:onExit()
 
end

--默认按钮监听回调
function DiscoFeverJPWinLittleView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return DiscoFeverJPWinLittleView