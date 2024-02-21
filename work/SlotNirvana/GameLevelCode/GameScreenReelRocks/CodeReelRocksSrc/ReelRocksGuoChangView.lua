---
--xcyy
--2018年5月23日
--ReelRocksGuoChangView.lua

local ReelRocksGuoChangView = class("ReelRocksGuoChangView",util_require("base.BaseView"))


function ReelRocksGuoChangView:initUI()

    self:createCsbNode("ReelRocks_guochang.csb")

end

function ReelRocksGuoChangView:onEnter()
 
end


function ReelRocksGuoChangView:onExit()
 
end

--默认按钮监听回调
function ReelRocksGuoChangView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ReelRocksGuoChangView