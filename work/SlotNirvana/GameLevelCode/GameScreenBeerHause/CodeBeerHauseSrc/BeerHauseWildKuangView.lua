---
--xcyy
--2018年5月23日
--BeerHauseWildKuangView.lua

local BeerHauseWildKuangView = class("BeerHauseWildKuangView",util_require("base.BaseView"))


function BeerHauseWildKuangView:initUI(name)
    local csbPath = name .. ".csb"
    self:createCsbNode(csbPath)
end


function BeerHauseWildKuangView:onEnter()
 

end


function BeerHauseWildKuangView:onExit()
 
end


return BeerHauseWildKuangView