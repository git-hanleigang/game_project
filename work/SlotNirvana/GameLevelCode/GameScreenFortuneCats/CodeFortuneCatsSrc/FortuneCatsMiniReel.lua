---
--xcyy
--2018年5月23日
--FortuneCatsMiniReel.lua

local FortuneCatsMiniReel = class("FortuneCatsMiniReel",util_require("base.BaseView"))


function FortuneCatsMiniReel:initUI()
    self:createCsbNode("FortuneCats_small_reel.csb")
end

function FortuneCatsMiniReel:onEnter()

end

function FortuneCatsMiniReel:setOverNum(num1,num2,num3)
    local node1 = self:findChild("num1")
    node1:setString(util_formatCoins(num1, 3))

    local node2 = self:findChild("num2")
    node2:setString(util_formatCoins(num2, 3))
    
    local node3 = self:findChild("num3")
    node3:setString(util_formatCoins(num3, 3))
end
function FortuneCatsMiniReel:onExit()
end

return FortuneCatsMiniReel