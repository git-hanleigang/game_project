---
--xcyy
--2018年5月23日
--ReelRocksCollectActView.lua

local ReelRocksCollectActView = class("ReelRocksCollectActView",util_require("base.BaseView"))


function ReelRocksCollectActView:initUI(path)


    self:createCsbNode(path .. ".csb")
end


function ReelRocksCollectActView:onEnter()
 
end

function ReelRocksCollectActView:changeNum(num)
    self:findChild("m_lb_num"):setString(num)
end

function ReelRocksCollectActView:onExit()
 
end

--默认按钮监听回调
function ReelRocksCollectActView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return ReelRocksCollectActView