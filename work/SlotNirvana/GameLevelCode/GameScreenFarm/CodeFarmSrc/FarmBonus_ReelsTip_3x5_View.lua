---
--xcyy
--2018年5月23日
--FarmBonus_ReelsTip_3x5_View.lua

local FarmBonus_ReelsTip_3x5_View = class("FarmBonus_ReelsTip_3x5_View",util_require("base.BaseView"))


function FarmBonus_ReelsTip_3x5_View:initUI(wildCol)


    local csbPath = "Farm_game_lunpan3x5.csb"
    self:createCsbNode(csbPath)


    for i=1,#wildCol do
        local col = wildCol[i]
        local viewWild = util_createView("CodeFarmSrc.FarmBonus_ReelsTip_3x5_Wild_View") 
        self:findChild("wild"..col):addChild(viewWild)
        
    end

end




function FarmBonus_ReelsTip_3x5_View:onEnter()
 
    util_setCascadeOpacityEnabledRescursion(self,true)
end


function FarmBonus_ReelsTip_3x5_View:onExit()
 
end



return FarmBonus_ReelsTip_3x5_View