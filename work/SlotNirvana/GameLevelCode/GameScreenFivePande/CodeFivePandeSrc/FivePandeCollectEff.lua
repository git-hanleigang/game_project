---
--xcyy
--2018年5月23日
--CollectEff.lua

local CollectEff = class("CollectEff",util_require("base.BaseView"))


function CollectEff:initUI()

    self:createCsbNode("FivePande/FivePande_Progress.csb")

end


function CollectEff:onEnter()
 

end
function CollectEff:showAdd()
    self:runCsbAction("actionframe")

end
function CollectEff:onExit()
 
end


return CollectEff