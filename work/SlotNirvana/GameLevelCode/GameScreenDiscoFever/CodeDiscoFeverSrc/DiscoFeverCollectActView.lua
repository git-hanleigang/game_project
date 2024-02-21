---
--xcyy
--2018年5月23日
--DiscoFeverCollectActView.lua

local DiscoFeverCollectActView = class("DiscoFeverCollectActView",util_require("base.BaseView"))


function DiscoFeverCollectActView:initUI()

    self:createCsbNode("DiscoFever_shouji_shanuang.csb")

end


function DiscoFeverCollectActView:onEnter()
 

end

function DiscoFeverCollectActView:onExit()
 
end

return DiscoFeverCollectActView