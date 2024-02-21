---
--xhkj
--2018年6月11日
--QuickHitAddWildSymbol.lua

local QuickHitAddWildSymbol = class("QuickHitAddWildSymbol", util_require("base.BaseView"))

function QuickHitAddWildSymbol:initUI(data)

    local resourceFilename = data

    self:createCsbNode(resourceFilename)
  
end


function QuickHitAddWildSymbol:onEnter()
 

end


function QuickHitAddWildSymbol:onExit()
    
end

return QuickHitAddWildSymbol