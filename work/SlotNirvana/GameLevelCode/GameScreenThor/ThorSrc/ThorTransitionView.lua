---

local ThorTransitionView = class("ThorTransitionView",util_require("base.BaseView"))


function ThorTransitionView:initUI()

  
    self:createCsbNode("Socre_Thor_guochang.csb")
    -- self:runCsbAction("actionframe",false)

end

function ThorTransitionView:onEnter()
 
end

function ThorTransitionView:onExit()
 
end

return ThorTransitionView