---
--xcyy
--2018年5月23日
--FarmBonus_ReelsTipView.lua

local FarmBonus_ReelsTipView = class("FarmBonus_ReelsTipView",util_require("base.BaseView"))


function FarmBonus_ReelsTipView:initUI(data)

    self.m_reelNum = data.m_reelNum
    self.m_reelRow = data.m_reelRow
    self.m_wildCols = data.m_wildCols



    local csbPath = self:getCsbPath() .. ".csb"
    self:createCsbNode(csbPath)

    self:initLittleTip()


    

    

end

function FarmBonus_ReelsTipView:initLittleTip( )
    
    for i=1,self.m_reelNum do
        local node = self:findChild("Node_"..i)

        if node then
            local viewClass = "CodeFarmSrc.FarmBonus_ReelsTip_3x5_View"
            if self.m_reelRow == 4 then
                viewClass = "CodeFarmSrc.FarmBonus_ReelsTip_4x5_View"   
            end
            local view = util_createView(viewClass,self.m_wildCols)
            node:addChild(view)
        end
    end
end

function FarmBonus_ReelsTipView:getCsbPath( )
    local csbName = "Farm_game_lunpan"..self.m_reelRow .."x5_"..self.m_reelNum 
    
    return csbName
end

function FarmBonus_ReelsTipView:onEnter()
 
    util_setCascadeOpacityEnabledRescursion(self,true)
end


function FarmBonus_ReelsTipView:onExit()
 
end

return FarmBonus_ReelsTipView