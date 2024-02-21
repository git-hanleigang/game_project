---
--xcyy
--2018年5月23日
--FourInOneGuoChangView.lua

local FourInOneGuoChangView = class("FourInOneGuoChangView",util_require("base.BaseView"))


function FourInOneGuoChangView:initUI()

    self:createCsbNode("FourInIne_guochang.csb")

end


function FourInOneGuoChangView:onEnter()
 

end


function FourInOneGuoChangView:onExit()
 
end


return FourInOneGuoChangView