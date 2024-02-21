---
--xhkj
--2018年6月11日
--CrazyBombWheelRewordGift.lua

local CrazyBombWheelRewordGift = class("CrazyBombWheelRewordGift", util_require("base.BaseView"))

function CrazyBombWheelRewordGift:initUI(name)

    local resourceFilename = "Socre_CrazyBomb_lunpanxuanzhong.csb"
    self:createCsbNode(resourceFilename)

end


function CrazyBombWheelRewordGift:onEnter()
   
end


function CrazyBombWheelRewordGift:onExit()
    
end


return CrazyBombWheelRewordGift