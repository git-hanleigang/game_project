---
--xcyy
--2018年5月23日
--PirateCollectShip.lua

local PirateCollectShip = class("PirateCollectShip",util_require("base.BaseView"))


function PirateCollectShip:initUI()

    self:createCsbNode("Pirate_UI_shang_ship.csb")
    self:runCsbAction("idle",true)
end


function PirateCollectShip:onEnter()
 
end

function PirateCollectShip:showAdd()
    self:runCsbAction("add",false,function( )
        self:runCsbAction("idle",true)
    end)
end

function PirateCollectShip:onExit()
 
end


return PirateCollectShip