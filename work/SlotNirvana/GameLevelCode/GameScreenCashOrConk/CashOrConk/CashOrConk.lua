

local CaiShensCoinsView = class("CaiShensCoinsView",util_require("base.BaseView"))

function CaiShensCoinsView:initUI()

    self:createCsbNode("xxxx/xxxxxxx.csb")


end

--默认按钮监听回调
function CaiShensCoinsView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

return CaiShensCoinsView