---
--xhkj
--2018年6月11日
--FrogPrinceBonusLab.lua

local FrogPrinceBonusLab = class("FrogPrinceBonusLab", util_require("base.BaseView"))

function FrogPrinceBonusLab:initUI(data)
    self:createCsbNode("FrogPrince_bonus.csb")
    local num = data._num 
    self:setNum(num)
end


function FrogPrinceBonusLab:onEnter()
 
end

function FrogPrinceBonusLab:setNum(num)
    local label =  self:findChild("BitmapFontLabel_1") -- 获得子节点
    label:setString(num .. "x")
end

function FrogPrinceBonusLab:onExit()
    
end

return FrogPrinceBonusLab