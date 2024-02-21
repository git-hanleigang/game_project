---
--xcyy
--2018年5月23日
--BlazingMotorsFreespinStartView.lua

local BlazingMotorsFreespinStartView = class("BlazingMotorsFreespinStartView",util_require("base.BaseView"))


function BlazingMotorsFreespinStartView:initUI()

    self:createCsbNode("BlazingMotors/FreeSpinStart.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
 

end


function BlazingMotorsFreespinStartView:onEnter()
 

end

function BlazingMotorsFreespinStartView:showAdd()
    
end
function BlazingMotorsFreespinStartView:onExit()
 
end

--默认按钮监听回调
function BlazingMotorsFreespinStartView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return BlazingMotorsFreespinStartView