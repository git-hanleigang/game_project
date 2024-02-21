---
--xcyy
--2018年5月23日
--AfricaRiseReelFrameBg.lua

local AfricaRiseReelFrameBg = class("AfricaRiseReelFrameBg",util_require("base.BaseView"))


function AfricaRiseReelFrameBg:initUI()
    self:createCsbNode("AfricaRise_gundong_frame_bg.csb")
end

function AfricaRiseReelFrameBg:changeFrameBg()
   
    local lan1 =  self:findChild("lan1")
    local zi1 =  self:findChild("zi1")
    if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
        lan1:setVisible(false)
        zi1:setVisible(true)
    else
        lan1:setVisible(true)
        zi1:setVisible(false)
    end
end


function AfricaRiseReelFrameBg:onEnter()

end

function AfricaRiseReelFrameBg:onExit()
 
end


return AfricaRiseReelFrameBg