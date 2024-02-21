---
--xcyy
--2018年5月23日
--DiscoFeverJPWinView.lua

local DiscoFeverJPWinView = class("DiscoFeverJPWinView",util_require("base.BaseView"))


function DiscoFeverJPWinView:initUI()

    self:createCsbNode("DiscoFecer_jackpotWinAction.csb")


end


function DiscoFeverJPWinView:onEnter()
 

end

function DiscoFeverJPWinView:onExit()
 
end


return DiscoFeverJPWinView