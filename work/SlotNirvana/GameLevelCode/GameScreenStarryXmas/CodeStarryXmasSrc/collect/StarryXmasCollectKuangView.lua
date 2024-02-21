---
--xcyy
--2018年5月23日
--StarryXmasCollectKuangView.lua

local StarryXmasCollectKuangView = class("StarryXmasCollectKuangView",util_require("base.BaseView"))


function StarryXmasCollectKuangView:initUI()

    self:createCsbNode("Socre_AliceRuby_FIx_Bonus.csb")

    self:runCsbAction("kuang")
end


function StarryXmasCollectKuangView:onEnter()
 

end

function StarryXmasCollectKuangView:onExit()
 
end

return StarryXmasCollectKuangView