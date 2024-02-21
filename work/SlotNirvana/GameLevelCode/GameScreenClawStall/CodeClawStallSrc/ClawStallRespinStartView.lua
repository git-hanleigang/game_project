---
--xcyy
--2018年5月23日
--ClawStallRespinStartView.lua

local ClawStallRespinStartView = class("ClawStallRespinStartView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "ClawStallPublicConfig"

function ClawStallRespinStartView:initUI(params)
    self.m_endFunc = params.func
    self:createCsbNode("ClawStall/RespinStart.csb")

    self.m_isClicked = true

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_respin_start)
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
function ClawStallRespinStartView:clickFunc(sender)
    if self.m_isClicked then
        return
    end
    self.m_isClicked = true

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_click_btn)

    util_spinePlay(self.m_spine,"over")

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_respin_over)
    self:runCsbAction("over",false,function(  )
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end
        self:removeFromParent()
    end)
end




return ClawStallRespinStartView