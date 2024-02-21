---
--xhkj
--2018年6月11日
--CrazyBombWheelNode.lua

local CrazyBombWheelNode = class("CrazyBombWheelNode", util_require("base.BaseView"))

function CrazyBombWheelNode:initUI(name)

    local resourceFilename = name
    self:createCsbNode(resourceFilename)

end


function CrazyBombWheelNode:onEnter()
   
end


function CrazyBombWheelNode:onExit()
    
end

function CrazyBombWheelNode:setlabString(str )
   local lab =  self:findChild("BitmapFontLabel_1")
   if lab then
        lab:setString(str)
        self:updateLabelSize({label=lab,sx=1.0,sy=1.0},220)
   end
end


return CrazyBombWheelNode