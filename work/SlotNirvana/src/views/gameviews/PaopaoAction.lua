local PaopaoAction=class("PaopaoAction",util_require("base.BaseView"))


function PaopaoAction:initUI(csbpath)
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end

    self:createCsbNode("Game/paopao.csb",isAutoScale)
    --self:setScale(100)
    self:runCsbAction("yeti",true)
        
end

function PaopaoAction:onEnter()

end

function PaopaoAction:onExit()
  
end


return PaopaoAction