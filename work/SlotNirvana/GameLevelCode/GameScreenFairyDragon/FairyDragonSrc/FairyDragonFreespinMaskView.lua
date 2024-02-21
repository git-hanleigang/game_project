---
--xcyy
--2018年5月23日
--FairyDragonFreespinMaskView.lua

local FairyDragonFreespinMaskView = class("FairyDragonFreespinMaskView",util_require("base.BaseView"))


function FairyDragonFreespinMaskView:initUI()

    self:createCsbNode("FairyDragon_Mask.csb")
    self:runCsbAction("show")
end

function FairyDragonFreespinMaskView:onEnter()
 
end

function FairyDragonFreespinMaskView:onExit()
 
end

return FairyDragonFreespinMaskView