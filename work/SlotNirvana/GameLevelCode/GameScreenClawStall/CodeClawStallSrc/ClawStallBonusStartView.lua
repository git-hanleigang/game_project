---
--xcyy
--2018年5月23日
--ClawStallBonusStartView.lua

local ClawStallBonusStartView = class("ClawStallBonusStartView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "ClawStallPublicConfig"

function ClawStallBonusStartView:initUI(params)
    local num = params.num
    self.m_endFunc = params.func
    self.m_machine = params.machine
    self:createCsbNode("ClawStall/BonusStart.csb")
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_bonus_start)

    self.m_isClicked = true
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

    self:findChild("m_lb_num"):setString(num)

end

--默认按钮监听回调
function ClawStallBonusStartView:clickFunc(sender)
    if self.m_isClicked then
        return
    end

    self.m_machine:clearCurMusicBg()

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

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_change_scene_to_bonus)
    util_spinePlay(self.m_spine,"actionframe")
    util_spineFrameCallFunc(self.m_spine,"actionframe","swtch",keyFunc,endFunc)
    
    self:runCsbAction("actionframe")
end




return ClawStallBonusStartView