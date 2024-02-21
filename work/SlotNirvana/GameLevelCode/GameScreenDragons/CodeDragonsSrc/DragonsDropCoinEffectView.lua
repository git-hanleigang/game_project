---
--xcyy
--2018年5月23日
--DragonsDropCoinEffectView.lua

local DragonsDropCoinEffectView = class("DragonsDropCoinEffectView",util_require("base.BaseView"))


function DragonsDropCoinEffectView:initUI()

    self:createCsbNode("Dragons_jinbisaluo.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
end


function DragonsDropCoinEffectView:onEnter()
 

end
function DragonsDropCoinEffectView:onExit()
end

--默认按钮监听回调
function DragonsDropCoinEffectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
end


return DragonsDropCoinEffectView