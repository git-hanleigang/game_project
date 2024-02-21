local JungleKingpinLockWildView = class("JungleKingpinLockWildView",util_require("base.BaseView"))


function JungleKingpinLockWildView:initUI()
    local csbName = "WinFrameJungleKingpin_superfreespin_wild.csb"
    self:createCsbNode(csbName)
     -- self:runCsbAction("actionframe")
end

function JungleKingpinLockWildView:onEnter()
 
end

function JungleKingpinLockWildView:onExit()
 
end


return JungleKingpinLockWildView