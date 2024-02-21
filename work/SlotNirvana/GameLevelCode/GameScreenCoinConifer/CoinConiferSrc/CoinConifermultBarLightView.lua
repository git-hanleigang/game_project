---
--xcyy
--2018年5月23日
--CoinConifermultBarLightView.lua
local PublicConfig = require "CoinConiferPublicConfig"
local CoinConifermultBarLightView = class("CoinConifermultBarLightView",util_require("Levels.BaseLevelDialog"))


function CoinConifermultBarLightView:initUI()

    self:createCsbNode("CoinConifer_chengbei_guang2.csb")

    self.csbName = nil
    self.light = util_createAnimation("CoinConifer_chengbei_guang1.csb")    --转光
    self:findChild("node_light"):addChild(self.light)
    self:hideLight()
    self:runCsbAction("idle2")
    -- util_setCascadeOpacityEnabledRescursion(self, true)
    
end

--[[
    初始化spine动画
    在此处初始化spine,不要放在initUI中
]]
function CoinConifermultBarLightView:initSpineUI()
    
end

function CoinConifermultBarLightView:showLight()
    self.light:setVisible(true)
    self.light:runCsbAction("animation0",true)
    self.csbName = "start"
    self:runCsbAction("start",false,function ()
        self.csbName = "idle1"
        self:runCsbAction("idle1")
    end)
end

function CoinConifermultBarLightView:hideLight()
    if self.csbName == "idle1" or self.csbName == "start" then
        self.csbName = "over"
        self:runCsbAction("over",false,function ()
            self:runCsbAction("idle2")
            self.csbName = "idle2"
            self.light:setVisible(false)
        end) 
    end
    
end

function CoinConifermultBarLightView:showLightIdle2()

    self.light:setVisible(false)
    self:runCsbAction("idle2")
    self.csbName = "idle2"
end

function CoinConifermultBarLightView:onEnter()
    CoinConifermultBarLightView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
end

return CoinConifermultBarLightView