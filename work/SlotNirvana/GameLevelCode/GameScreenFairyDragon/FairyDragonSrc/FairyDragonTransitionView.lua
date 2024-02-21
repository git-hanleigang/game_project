---
--xcyy
--2018年5月23日
--FairyDragonTransitionView.lua

local FairyDragonTransitionView = class("FairyDragonTransitionView",util_require("base.BaseView"))


function FairyDragonTransitionView:initUI()

    self:createCsbNode("FairyDragon_Jinbizhuanchang.csb")
    -- self:runCsbAction("actionframe1") -- 播放时间线
end


function FairyDragonTransitionView:onEnter()
 

end

function FairyDragonTransitionView:onExit()
 
end

return FairyDragonTransitionView