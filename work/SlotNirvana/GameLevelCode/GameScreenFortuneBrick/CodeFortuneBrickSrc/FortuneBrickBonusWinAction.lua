---
--island
--2018年6月5日
--FortuneBrickBonusWinAction.lua

local FortuneBrickBonusWinAction = class("FortuneBrickBonusWinAction", util_require("base.BaseView"))

function FortuneBrickBonusWinAction:initUI(data)

    local resourceFilename="Socre_FortuneBrick_Top_2.csb"
    self:createCsbNode(resourceFilename)


    
end

function FortuneBrickBonusWinAction:onEnter()
    
    
end

---
-- 扫光
--
function FortuneBrickBonusWinAction:showAction(func,loop)
    self:runCsbAction("animation0",loop,func)
end



function FortuneBrickBonusWinAction:onExit()
    
end


return FortuneBrickBonusWinAction