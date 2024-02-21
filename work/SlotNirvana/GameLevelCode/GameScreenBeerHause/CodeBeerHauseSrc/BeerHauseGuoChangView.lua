---
--xcyy
--2018年5月23日
--BeerHauseGuoChangView.lua

local BeerHauseGuoChangView = class("BeerHauseGuoChangView",util_require("base.BaseView"))


function BeerHauseGuoChangView:initUI()

    self:createCsbNode("Socre_BeerHause_ChangeScene.csb")

end


function BeerHauseGuoChangView:onEnter()
 

end

function BeerHauseGuoChangView:onExit()
 
end


return BeerHauseGuoChangView