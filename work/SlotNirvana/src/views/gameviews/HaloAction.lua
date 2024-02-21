local HaloAction=class("HaloAction",util_require("base.BaseView"))


function HaloAction:initUI(csbpath)
    local isAutoScale =true
    if CC_RESOLUTION_RATIO==3 then
        isAutoScale=false
    end

    self:createCsbNode("Game/halo.csb",isAutoScale)
    --self:setScale(100)
    
    self:setPosition(0,10)
        
end

function HaloAction:onEnter()

end

function HaloAction:onExit()
  
end


return HaloAction