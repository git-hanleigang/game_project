---
--smy
--2018年5月24日
--FishMainaScreenZhezhao.lua
-- local BaseGame=util_require("base.BaseSimpleGame")
local FishMainaScreenZhezhao = class("FishMainaScreenZhezhao",util_require("base.BaseView"))

function FishMainaScreenZhezhao:initUI()

    self:createCsbNode("FishMania/ShareScreen_0.csb")

end

function FishMainaScreenZhezhao:onEnter()
    
end

function FishMainaScreenZhezhao:onExit(  )

end

-- 点击函数
function FishMainaScreenZhezhao:clickCloseView()

    self:removeFromParent()
    
end

return FishMainaScreenZhezhao