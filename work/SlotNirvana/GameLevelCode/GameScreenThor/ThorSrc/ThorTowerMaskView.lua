---
--xcyy
--2018年5月23日
--ThorTowerMaskView.lua

local ThorTowerMaskView = class("ThorTowerMaskView",util_require("base.BaseView"))


function ThorTowerMaskView:initUI(_type)

    local strName 
    if _type == 1 then
        strName = "Thor/GameScreenThor_lvta"
    elseif _type == 2 then
        strName = "Thor/GameScreenThor_hongta"
    elseif _type == 3 then
        strName = "Thor/GameScreenThor_lanta"
    end
    self:createCsbNode(strName .. ".csb")
    -- self:runCsbAction("open",false)
end

function ThorTowerMaskView:onEnter()
 

end

function ThorTowerMaskView:showAdd()
    
end

function ThorTowerMaskView:onExit()
 
end

return ThorTowerMaskView