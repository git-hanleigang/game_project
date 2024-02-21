---
--xcyy
--2018年5月23日
--DazzlingDiscoJackpotReelStartView.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoJackpotReelStartView = class("DazzlingDiscoJackpotReelStartView",util_require("Levels.BaseLevelDialog"))


function DazzlingDiscoJackpotReelStartView:initUI(params)
    local machineRootScale = params.machineRootScale
    self.m_callFunc = params.func

    --黑色遮罩
    self.m_mask = util_createAnimation("DazzlingDisco_mask.csb")
    self:addChild(self.m_mask)


    self.m_spineNode = util_spineCreate("DazzlingDiscoSpineView/JackpotReelsStart",true,true)
    self:addChild(self.m_spineNode)
    self.m_spineNode:setScale(machineRootScale)

    self.m_mask:runCsbAction("animation0")

    self.m_btn_csb = util_createAnimation("DazzlingDisco_anniu.csb")
    util_spinePushBindNode(self.m_spineNode,"anniu2",self.m_btn_csb)
    -- self:addChild(self.m_btn_csb)

    self.m_btn_csb:findChild("Button_jackpotover"):setVisible(false)
    self.m_btn_csb:findChild("Button_socialover"):setVisible(false)
    local btn = self.m_btn_csb:findChild("Button_jackpotstart")  
    btn:setVisible(true)
    btn:setTouchEnabled(false)
    self:addClick(btn)

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_show_jackpot_reel_view)
    util_spinePlay(self.m_spineNode,"start")
    util_spineEndCallFunc(self.m_spineNode,"start",function(  )
        util_spinePlay(self.m_spineNode,"idle",true)
        btn:setTouchEnabled(true)
    end)

    
end

--[[
    点击按钮
]]
function DazzlingDiscoJackpotReelStartView:clickFunc(sender)
    if self.m_isClick then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_btn_click)
    self.m_isClick = true
    self.m_mask:runCsbAction("animation2")

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_hide_jackpot_reel_view)
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




return DazzlingDiscoJackpotReelStartView