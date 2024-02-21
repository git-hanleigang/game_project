---
--xcyy
--2018年5月23日
--BeerGirlCollectKuangView.lua

local BeerGirlCollectKuangView = class("BeerGirlCollectKuangView",util_require("base.BaseView"))


function BeerGirlCollectKuangView:initUI()

    self:createCsbNode("Socre_BeerGirl_FIx_Bonus.csb")

    self:runCsbAction("kuang")

    

end


function BeerGirlCollectKuangView:onEnter()
 

end

function BeerGirlCollectKuangView:onExit()
 
end

return BeerGirlCollectKuangView