---
--xcyy
--2018年5月23日
--AllStarLinesView.lua

local AllStarLinesView = class("AllStarLinesView",util_require("base.BaseView"))


function AllStarLinesView:initUI(index)


    local name = "AllStar_lianxian_1.csb"
    if name then
        name = "AllStar_lianxian_" .. index ..".csb"
    end
    self:createCsbNode(name)

   
end


function AllStarLinesView:onEnter()
 

end

function AllStarLinesView:showAdd()
    
end
function AllStarLinesView:onExit()
 
end

--默认按钮监听回调
function AllStarLinesView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return AllStarLinesView