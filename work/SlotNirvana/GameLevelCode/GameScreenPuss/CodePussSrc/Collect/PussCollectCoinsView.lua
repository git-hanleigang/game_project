---
--xcyy
--2018年5月23日
--PussCollectCoinsView.lua

local PussCollectCoinsView = class("PussCollectCoinsView",util_require("base.BaseView"))


function PussCollectCoinsView:initUI()

    self:createCsbNode("Puss_jindutiao_coins.csb")

    self:runCsbAction("idleframe")
    
end


function PussCollectCoinsView:onEnter()
 

end


function PussCollectCoinsView:onExit()
 
end




return PussCollectCoinsView