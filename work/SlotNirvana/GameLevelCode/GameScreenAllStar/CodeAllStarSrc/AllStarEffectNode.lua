---
--xcyy
--2018年5月23日
--AllStarEffectNode.lua

local AllStarEffectNode = class("AllStarEffectNode",util_require("base.BaseView"))


function AllStarEffectNode:initUI()

    self:createCsbNode("Bonusshuoming_effect.csb")

end


function AllStarEffectNode:onEnter()
 

end

function AllStarEffectNode:showAdd()
    
end
function AllStarEffectNode:onExit()
 
end

--默认按钮监听回调
function AllStarEffectNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end



return AllStarEffectNode