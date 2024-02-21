---
--xcyy
--2018年5月23日
--FrogPrinceCollectEff.lua

local FrogPrinceCollectEff = class("FrogPrinceCollectEff",util_require("base.BaseView"))


function FrogPrinceCollectEff:initUI()

    self:createCsbNode("FrogPrince_jindutiao_2.csb")

end


function FrogPrinceCollectEff:onEnter()
 

end
function FrogPrinceCollectEff:showAdd()
    self:runCsbAction("actionframe")

end
function FrogPrinceCollectEff:onExit()
 
end


return FrogPrinceCollectEff