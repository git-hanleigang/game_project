local PirateSeaView = class("PirateSeaView", util_require("base.BaseView"))

function PirateSeaView:initUI()
    local resourceFilename = "Socre_Pirate_wild_sea.csb"
    self:createCsbNode(resourceFilename)
   
end

function PirateSeaView:playIdle( )
    self:runCsbAction("start", false) 
end

function PirateSeaView:onExit()
end

function PirateSeaView:onEnter()
end

return PirateSeaView
