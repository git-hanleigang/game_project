---
--xhkj
--2018年6月11日
--QuickHitJackPotWinLight.lua

local QuickHitJackPotWinLight = class("QuickHitJackPotWinLight", util_require("base.BaseView"))

function QuickHitJackPotWinLight:initUI()

    local resourceFilename = "QuickHit_zhongjiangLight.csb"
    self:createCsbNode(resourceFilename)
    
    self:runCsbAction("animation0",true)
end


function QuickHitJackPotWinLight:onEnter()
 

end


function QuickHitJackPotWinLight:onExit()
    
end

return QuickHitJackPotWinLight