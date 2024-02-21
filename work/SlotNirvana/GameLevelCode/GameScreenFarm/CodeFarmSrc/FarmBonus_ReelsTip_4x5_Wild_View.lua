---
--xcyy
--2018年5月23日
--FarmBonus_ReelsTip_4x5_Wild_View.lua

local FarmBonus_ReelsTip_4x5_Wild_View = class("FarmBonus_ReelsTip_4x5_Wild_View",util_require("base.BaseView"))


function FarmBonus_ReelsTip_4x5_Wild_View:initUI(data)

    local csbPath = "Farm_game_wild4x5.csb"
    self:createCsbNode(csbPath)



end




function FarmBonus_ReelsTip_4x5_Wild_View:onEnter()
 
    util_setCascadeOpacityEnabledRescursion(self,true)
end


function FarmBonus_ReelsTip_4x5_Wild_View:onExit()
 
end



return FarmBonus_ReelsTip_4x5_Wild_View