---
--xcyy
--2018年5月23日
--FarmBonus_Little_RoadView.lua

local FarmBonus_Little_RoadView = class("FarmBonus_Little_RoadView",util_require("base.BaseView"))

FarmBonus_Little_RoadView.m_oldCsbName = nil

function FarmBonus_Little_RoadView:initUI(path)

    local csbPath = path.. ".csb"
    self:createCsbNode(csbPath)

    self.m_oldCsbName = path

end


function FarmBonus_Little_RoadView:onEnter()
 

end


function FarmBonus_Little_RoadView:onExit()
 
end

--默认按钮监听回调
function FarmBonus_Little_RoadView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


return FarmBonus_Little_RoadView