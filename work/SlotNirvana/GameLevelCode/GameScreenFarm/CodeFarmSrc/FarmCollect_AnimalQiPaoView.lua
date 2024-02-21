---
--xcyy
--2018年5月23日
--FarmCollect_AnimalQiPaoView.lua

local FarmCollect_AnimalQiPaoView = class("FarmCollect_AnimalQiPaoView",util_require("base.BaseView"))



function FarmCollect_AnimalQiPaoView:initUI()

    local csbPath = "Farm_game_qipao.csb"
 

    self:createCsbNode(csbPath)

    -- self:findChild("Node_1"):setPosition(-180,-50)
    
    
    self:findChild("Panel_1"):setVisible(false)
    -- self:addClick(self:findChild("Panel_1"))
  
    
end


function FarmCollect_AnimalQiPaoView:onEnter()
 

end


function FarmCollect_AnimalQiPaoView:onExit()
 
end

--默认按钮监听回调
function FarmCollect_AnimalQiPaoView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    self:setVisible(false)

end


return FarmCollect_AnimalQiPaoView