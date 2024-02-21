---
--xcyy
--2018年5月23日
--FarmMainReels_CornView.lua

local FarmMainReels_CornView = class("FarmMainReels_CornView",util_require("base.BaseView"))


function FarmMainReels_CornView:initUI()

    self:createCsbNode("Farm_yumi_zi.csb")
    self:runCsbAction("idle")

    
end


function FarmMainReels_CornView:onEnter()
 

end


function FarmMainReels_CornView:onExit()
 
end

--默认按钮监听回调
function FarmMainReels_CornView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    
end


return FarmMainReels_CornView