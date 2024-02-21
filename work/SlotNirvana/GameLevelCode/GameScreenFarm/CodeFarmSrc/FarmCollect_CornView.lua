---
--xcyy
--2018年5月23日
--FarmCollect_CornView.lua

local FarmCollect_CornView = class("FarmCollect_CornView",util_require("base.BaseView"))


function FarmCollect_CornView:initUI()

    self:createCsbNode("Farm_yumi_zi.csb")

    self:runCsbAction("idle")
end


function FarmCollect_CornView:onEnter()
 

end


function FarmCollect_CornView:onExit()
 
end

--默认按钮监听回调
function FarmCollect_CornView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    
end


return FarmCollect_CornView