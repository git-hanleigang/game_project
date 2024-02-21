---
--xcyy
--2018年5月23日
--PomiFireBallView.lua

local PomiFireBallView = class("PomiFireBallView",util_require("base.BaseView"))


function PomiFireBallView:initUI()

    self:createCsbNode("LinkReels/PomiLink/4in1_Pomi_huoQiu.csb")

end


function PomiFireBallView:onEnter()
 

end


function PomiFireBallView:onExit()
 
end

return PomiFireBallView