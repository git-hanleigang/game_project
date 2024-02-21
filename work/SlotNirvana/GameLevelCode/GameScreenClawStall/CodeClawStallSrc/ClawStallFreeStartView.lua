---
--xcyy
--2018年5月23日
--ClawStallFreeStartView.lua

local ClawStallFreeStartView = class("ClawStallFreeStartView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "ClawStallPublicConfig"

function ClawStallFreeStartView:initUI(params)
    self.m_endFunc = params.func
    self:createCsbNode("ClawStall/SuperFreeSpinStart.csb")
    self.m_isClicked = true
    self:findChild("m_lb_num"):setString(params.num)

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        self.m_isClicked = false
    end)

    local spine = util_spineCreate("ClawStal_zztb",true,true)
    self:findChild("zhuazi"):addChild(spine)
    util_spinePlay(spine,"start")
    util_spineEndCallFunc(spine,"start",function(  )
        util_spinePlay(spine,"idle",true)
    end)

    self.m_spine = spine

end

--默认按钮监听回调
function ClawStallFreeStartView:clickFunc(sender)
    if self.m_isClicked then
        return
    end
    self.m_isClicked = true

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_click_btn)

    local keyFunc = function(  )
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end
    end

    local endFunc = function(  )
        self:setVisible(false)
        performWithDelay(self,function(  )
            self:removeFromParent()
        end,0.2)
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_change_scene_to_free)
    util_spinePlay(self.m_spine,"actionframe")
    util_spineFrameCallFunc(self.m_spine,"actionframe","swtch",keyFunc,endFunc)

    self:runCsbAction("actionframe")
end




return ClawStallFreeStartView