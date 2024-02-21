---
--xcyy
--2018年5月23日
--FrogPrinceCollectEff2.lua

local FrogPrinceCollectEff2 = class("FrogPrinceCollectEff2",util_require("base.BaseView"))


function FrogPrinceCollectEff2:initUI()

    self:createCsbNode("FrogPrince_jindutiao_3.csb")

end


function FrogPrinceCollectEff2:onEnter()
 

end
function FrogPrinceCollectEff2:showIdle()
    self:runCsbAction("idleframe",true)

end
function FrogPrinceCollectEff2:onExit()
 
end


return FrogPrinceCollectEff2