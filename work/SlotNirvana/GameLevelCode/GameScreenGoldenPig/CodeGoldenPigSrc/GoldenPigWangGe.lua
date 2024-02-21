---
--xhkj
--2018年6月11日
--GoldenPigWangGe.lua

local GoldenPigWangGe = class("GoldenPigWangGe", util_require("base.BaseView"))

function GoldenPigWangGe:initUI(data)

    local resourceFilename="GoldenPig_WangGe.csb"
    self:createCsbNode(resourceFilename)

end


function GoldenPigWangGe:onEnter()
   
end


function GoldenPigWangGe:onExit()
    

end


return GoldenPigWangGe