---
--xcyy
--2018年5月23日
--StarryFestFreeOverView.lua
local PublicConfig = require "StarryFestPublicConfig"
local StarryFestFreeOverView = class("StarryFestFreeOverView",util_require("Levels.BaseLevelDialog"))

function StarryFestFreeOverView:initUI(params)
    local machineRootScale = params.machineRootScale
    local winCoins = params.winCoins
    self.m_callFunc = params.func

    self.m_spineNode = util_spineCreate("FeatureOver",true,true)
    self:addChild(self.m_spineNode)
    self.m_spineNode:setScale(machineRootScale)

    self.m_btn_csb = util_createAnimation("StarryFest_anniu.csb")
    util_spinePushBindNode(self.m_spineNode,"anniu",self.m_btn_csb)

    local btn = self.m_btn_csb:findChild("Button_1")  
    btn:setVisible(true)
    btn:setTouchEnabled(false)
    self:addClick(btn)

    util_spinePlay(self.m_spineNode,"start")
    util_spineEndCallFunc(self.m_spineNode,"start",function(  )
        util_spinePlay(self.m_spineNode,"idle",true)
        btn:setTouchEnabled(true)
    end)

    util_setCascadeOpacityEnabledRescursion(self, true)
end

--[[
    点击按钮
]]
function StarryFestFreeOverView:clickFunc(sender)
    if self.m_isClick then
        return
    end
    self.m_isClick = true
    util_spinePlay(self.m_spineNode,"over")
    util_spineEndCallFunc(self.m_spineNode,"over",function(  )
        self:setVisible(false)
        if type(self.m_callFunc) == "function" then
            self.m_callFunc()
        end

        performWithDelay(self,function(  )
            self:removeFromParent()
        end,0.1)
    end)
end

return StarryFestFreeOverView
