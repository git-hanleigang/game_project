---
--xcyy
--2018年5月23日
--OZBonus_LSaoGuangNode.lua

local OZBonus_LSaoGuangNode = class("OZBonus_LSaoGuangNode",util_require("base.BaseView"))




function OZBonus_LSaoGuangNode:initUI(path)


    local csbPath =  path
    self:createCsbNode(csbPath ..".csb")


   

end


function OZBonus_LSaoGuangNode:onEnter()
 

end

function OZBonus_LSaoGuangNode:showAdd()
    
end
function OZBonus_LSaoGuangNode:onExit()
 
end

--默认按钮监听回调
function OZBonus_LSaoGuangNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return OZBonus_LSaoGuangNode