---
--xcyy
--2018年5月23日
--StarryXmasCollectActView.lua

local StarryXmasCollectActView = class("StarryXmasCollectActView",util_require("base.BaseView"))


function StarryXmasCollectActView:initUI(path)

    self:createCsbNode(path .. ".csb")

end


function StarryXmasCollectActView:onEnter()
 

end

function StarryXmasCollectActView:showAdd()
    
end
function StarryXmasCollectActView:onExit()
 
end

--默认按钮监听回调
function StarryXmasCollectActView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return StarryXmasCollectActView