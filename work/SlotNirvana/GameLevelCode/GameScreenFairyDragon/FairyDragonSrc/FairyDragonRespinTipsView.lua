---
--xcyy
--2018年5月23日
--FairyDragonRespinTipsView.lua

local FairyDragonRespinTipsView = class("FairyDragonRespinTipsView",util_require("base.BaseView"))


function FairyDragonRespinTipsView:initUI()
    self:createCsbNode("FairyDragon_shuoming.csb")
end


function FairyDragonRespinTipsView:onEnter()

end

function FairyDragonRespinTipsView:onExit()
 
end

return FairyDragonRespinTipsView