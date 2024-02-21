local JungleKingpinCoins = class("JungleKingpinCoins",util_require("base.BaseView"))


function JungleKingpinCoins:initUI()
    local csbName = "JungleKingpin_coins.csb"
    self:createCsbNode(csbName)
     -- self:runCsbAction("actionframe")
end

function JungleKingpinCoins:onEnter()
 

end

function JungleKingpinCoins:onExit()
 
end


return JungleKingpinCoins