---
--xcyy
--2018年5月23日
--FortuneCatsFreeSpinStart.lua

local FortuneCatsFreeSpinStart = class("FortuneCatsFreeSpinStart", util_require("base.BaseView"))

function FortuneCatsFreeSpinStart:initUI(_num)
    self:createCsbNode("FortuneCats/FreeSpinStart.csb")

    self.m_guochang = util_spineCreate("FortuneCats_freespins", true, true)
    self:findChild("Node"):addChild(self.m_guochang )
   
    local node=self:findChild("BitmapFontLabel_3")
    node:setString(util_formatCoins(_num,2))
    if  display.height/display.width <= 1024/768 then
        local root  = self:findChild("root")
        root:setScale(0.80)
    end
end

function FortuneCatsFreeSpinStart:showFreeSpinAmi()
    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_guochang.mp3")
    util_spinePlay(self.m_guochang, "animation2", false)
    self:runCsbAction("auto",false,function( )
        if  self.m_func then
            self.m_func()
        end
        self.m_guochang:removeFromParent()
        self:removeFromParent()
    end)
end

function FortuneCatsFreeSpinStart:onEnter()

end

function FortuneCatsFreeSpinStart:setCallFunc(func)
    self.m_func = function ( )
        if func then
            func()
        end
    end
end

function FortuneCatsFreeSpinStart:onExit()
end


return FortuneCatsFreeSpinStart
