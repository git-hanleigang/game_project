local JungleKingpinTransitionView = class("JungleKingpinTransitionView",util_require("base.BaseView"))


function JungleKingpinTransitionView:initUI()
    local csbName = "Socre_JungleKingpin_guochang.csb"
    self:createCsbNode(csbName)
     -- self:runCsbAction("actionframe")
end

function JungleKingpinTransitionView:onEnter()
 
end

function JungleKingpinTransitionView:playTransitionEffect(func)
  self:runCsbAction("actionframe",false,func)
end

function JungleKingpinTransitionView:onExit()
 
end


return JungleKingpinTransitionView