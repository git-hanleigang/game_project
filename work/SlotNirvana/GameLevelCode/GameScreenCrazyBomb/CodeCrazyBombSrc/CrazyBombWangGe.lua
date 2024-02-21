---
--xhkj
--2018年6月11日
--CrazyBombWangGe.lua

local CrazyBombWangGe = class("CrazyBombWangGe", util_require("base.BaseView"))

function CrazyBombWangGe:initUI(data)

    local resourceFilename="CrazyBomb/CrazyBomb_WangGe.csb"
    self:createCsbNode(resourceFilename)

end


function CrazyBombWangGe:onEnter()
   
end


function CrazyBombWangGe:onExit()
    

end


return CrazyBombWangGe