---
--xcyy
--2018年5月23日
--FarmBonus_CornView.lua

local FarmBonus_CornView = class("FarmBonus_CornView",util_require("base.BaseView"))


function FarmBonus_CornView:initUI()

    self:createCsbNode("Farm_yumi_zi.csb")

    self:runCsbAction("idle")
end


function FarmBonus_CornView:onEnter()
 

end


function FarmBonus_CornView:onExit()
 
end

--默认按钮监听回调
function FarmBonus_CornView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    
end


return FarmBonus_CornView