---
--xcyy
--2018年5月23日
--PomiFireBallView.lua

local PomiFireBallView = class("PomiFireBallView",util_require("base.BaseView"))


function PomiFireBallView:initUI()

    self:createCsbNode("Pomi_huoQiu.csb")

end


function PomiFireBallView:onEnter()
 

end


function PomiFireBallView:onExit()
 
end

return PomiFireBallView