---
--xcyy
--2018年5月23日
--PirateCollectEff.lua

local PirateCollectEff = class("PirateCollectEff",util_require("base.BaseView"))


function PirateCollectEff:initUI()

    self:createCsbNode("Pirate_Socre_jindutiao.csb")
    self:runCsbAction("idle_1",true)
end


function PirateCollectEff:onEnter()
 
end

function PirateCollectEff:showAdd()
    self:runCsbAction("qianjin_1",false,function( )
        self:runCsbAction("idle_1",true)
    end)

end

function PirateCollectEff:showIdle()
    self:runCsbAction("idle_1",true)
end

function PirateCollectEff:onExit()
 
end


return PirateCollectEff