---
--xcyy
--2018年5月23日
--AliceRubyCollectKuangView.lua

local AliceRubyCollectKuangView = class("AliceRubyCollectKuangView",util_require("base.BaseView"))


function AliceRubyCollectKuangView:initUI()

    self:createCsbNode("Socre_AliceRuby_FIx_Bonus.csb")

    self:runCsbAction("kuang")
end


function AliceRubyCollectKuangView:onEnter()
 

end

function AliceRubyCollectKuangView:onExit()
 
end

return AliceRubyCollectKuangView