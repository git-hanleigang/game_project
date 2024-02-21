---
--xcyy
--2018年5月23日
--BeerHauseLongWildView.lua

local BeerHauseLongWildView = class("BeerHauseLongWildView",util_require("base.BaseView"))


function BeerHauseLongWildView:initUI(name)
    local csbPath = name .. ".csb"
    self:createCsbNode(csbPath)
    -- self.m_wild = util_spineCreate("Socre_BeerHause_CopyWild2", true, true)
    -- self:findChild("Wild_1"):addChild(self.m_wild, 1)
  
end


function BeerHauseLongWildView:onEnter()
 

end


function BeerHauseLongWildView:onExit()
 
end

function BeerHauseLongWildView:playAddWild(animaName)
    self:runCsbAction(animaName) 
    -- if self.m_wild then
    --     util_spinePlay(self.m_wild, animaName, false)
    -- end
end

return BeerHauseLongWildView