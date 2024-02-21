---
--xcyy
--2018年5月23日
--ClassicCashLinesView.lua

local ClassicCashLinesView = class("ClassicCashLinesView",util_require("base.BaseView"))


function ClassicCashLinesView:initUI(index)


    local name = "ClassicCash_bonus_jiesuan.csb"

    self:createCsbNode(name)

   
end


function ClassicCashLinesView:onEnter()
 

end

function ClassicCashLinesView:showAdd()
    
end
function ClassicCashLinesView:onExit()
 
end

--默认按钮监听回调
function ClassicCashLinesView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ClassicCashLinesView