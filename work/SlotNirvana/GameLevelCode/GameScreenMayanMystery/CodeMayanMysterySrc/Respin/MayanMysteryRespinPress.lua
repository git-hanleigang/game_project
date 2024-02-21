---
--xcyy
--2018年5月23日
--MayanMysteryRespinPress.lua
local MayanMysteryRespinPress = class("MayanMysteryRespinPress",util_require("base.BaseView"))
local PublicConfig = require "MayanMysteryPublicConfig"

function MayanMysteryRespinPress:initUI()

    self:createCsbNode("MayanMystery_press_start.csb")
    self.m_bclick = true
    self.click = self:findChild("Panel_3")
    
    self:addClick(self.click)
end

function MayanMysteryRespinPress:setCallBack( func )
    self.m_callback = func
end
  
function MayanMysteryRespinPress:showPress()
    self:show()
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_respin_press_start)

    self:runCsbAction("start",false,function()
        self.m_bclick = false
        self:runCsbAction("idle",true)
    end)
  
    local delay = cc.DelayTime:create(3)
    local sequence = cc.Sequence:create(delay, cc.CallFunc:create(function()
        self.m_bclick = true
        self:closePress()
    end))
  
    sequence:setTag(10086)
    self:runAction(sequence)
  
end
  
function MayanMysteryRespinPress:closePress()
    self:runCsbAction("over",false,function()
        self:hide()
        if self.m_callback then
            self.m_callback()
        end
    end)
end
  
  
function MayanMysteryRespinPress:clickFunc(sender)
    local name,tag = sender:getName(),sender:getTag()
    if(name ~= "Panel_3" or self.m_bclick)then
        return
    end
  
    self.m_bclick = true
    print('=======点击!!')
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MayanMystery_click)
    self:stopActionByTag(10086)
    self:closePress()
  
end

return MayanMysteryRespinPress