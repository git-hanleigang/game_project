---
--xcyy
--2018年5月23日
--ReelRocksChooseDark.lua

local ReelRocksChooseDark = class("ReelRocksChooseDark",util_require("base.BaseView"))


function ReelRocksChooseDark:initUI()

    self:createCsbNode("ReelRocks_bisaiStart_dark.csb")
end


function ReelRocksChooseDark:onEnter()

end


function ReelRocksChooseDark:onExit()
 
end

--默认按钮监听回调
function ReelRocksChooseDark:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ReelRocksChooseDark