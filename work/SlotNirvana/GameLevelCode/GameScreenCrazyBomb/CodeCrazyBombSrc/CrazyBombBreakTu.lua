---
--xhkj
--2018年6月11日
--CrazyBombBreakTu.lua

local CrazyBombBreakTu = class("CrazyBombBreakTu", util_require("base.BaseView"))

function CrazyBombBreakTu:initUI(name)

    local resourceFilename = "CrazyBomb_Tu.csb"
    self:createCsbNode(resourceFilename)

end


function CrazyBombBreakTu:onEnter()
   
end


function CrazyBombBreakTu:onExit()
    
end

function CrazyBombBreakTu:setlabString(str )
   local lab =  self:findChild("BitmapFontLabel_1")
   if lab then
        lab:setString(str)
   end
end


return CrazyBombBreakTu