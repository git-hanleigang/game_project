---
--xcyy
--2018年5月23日
--VegasTip.lua

local VegasTip = class("VegasTip", util_require("base.BaseView"))

function VegasTip:initUI()
    self:createCsbNode("vegas_jushu.csb")

   
end

function VegasTip:showTip()
    self:runCsbAction("animation0",false)
end

function VegasTip:HideTip()
    self:runCsbAction("animation1",false,function(  )
        self:setVisible(false)
    end)
end

function VegasTip:onEnter()
end

function VegasTip:onExit()
end

return VegasTip
