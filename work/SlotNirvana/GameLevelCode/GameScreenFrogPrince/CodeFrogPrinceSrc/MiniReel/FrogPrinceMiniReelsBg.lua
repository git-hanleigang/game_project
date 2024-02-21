---
--xcyy
--2018年5月23日
--FrogPrinceMiniReelsBg.lua

local FrogPrinceMiniReelsBg = class("FrogPrinceMiniReelsBg",util_require("base.BaseView"))


function FrogPrinceMiniReelsBg:initUI(data)
    
    local resName ="GameScreenFrogPrince_" .. data .. "rl_mbg.csb"
    self:createCsbNode(resName)
   
end


function FrogPrinceMiniReelsBg:onEnter()
 

end

function FrogPrinceMiniReelsBg:onExit()
 
end

return FrogPrinceMiniReelsBg