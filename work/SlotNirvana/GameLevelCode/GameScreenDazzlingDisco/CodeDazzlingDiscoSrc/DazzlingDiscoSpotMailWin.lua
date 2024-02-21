---
--xcyy
--2018年5月23日
--DazzlingDiscoSpotMailWin.lua
local PublicConfig = require "DazzlingDiscoPublicConfig"
local DazzlingDiscoSpotMailWin = class("DazzlingDiscoSpotMailWin",util_require("Levels.BaseLevelDialog"))


function DazzlingDiscoSpotMailWin:initUI(params)
    local machineRootScale = params.machineRootScale
    local winCoins = params.winCoins
    self.m_callFunc = params.func

    --黑色遮罩
    self.m_mask = util_createAnimation("DazzlingDisco_mask.csb")
    self:addChild(self.m_mask)


    self.m_spineNode = util_spineCreate("DazzlingDisco_SocialOver",true,true)
    self:addChild(self.m_spineNode)
    self.m_spineNode:setScale(machineRootScale)

    self.m_mask:runCsbAction("animation0")

    self.m_btn_csb = util_createAnimation("DazzlingDisco_anniu.csb")
    util_spinePushBindNode(self.m_spineNode,"anniu2",self.m_btn_csb)

    --创建角色
    local spine_juese = util_spineCreate("Socre_DazzlingDisco_Bonus",true,true)
    util_spinePlay(spine_juese,"idle",true)
    util_spinePushBindNode(self.m_spineNode,"juese2",spine_juese)

    self.m_btn_csb:findChild("Button_jackpotstart"):setVisible(false)
    self.m_btn_csb:findChild("Button_socialover"):setVisible(false)
    local btn = self.m_btn_csb:findChild("Button_jackpotover")
    btn:setVisible(true)
    btn:setTouchEnabled(false)
    self:addClick(btn)

    local lbl_csb = util_createAnimation("DazzlingDisco_jackpot_coins.csb")
    util_spinePushBindNode(self.m_spineNode,"shuzi2",lbl_csb)
    self.m_lbl_coins = lbl_csb:findChild("m_lb_coins")
    self.m_lbl_coins:setString(util_formatCoins(winCoins,50))
    local info={label = self.m_lbl_coins,sx = 1,sy = 1}
    self:updateLabelSize(info,640)

    util_spinePlay(self.m_spineNode,"start")
    util_spineEndCallFunc(self.m_spineNode,"start",function(  )
        util_spinePlay(self.m_spineNode,"idle",true)
        btn:setTouchEnabled(true)
    end)

    
end

--[[
    点击按钮
]]
function DazzlingDiscoSpotMailWin:clickFunc(sender)
    if self.m_isClick then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_DazzlingDisco_btn_click)
    self.m_isClick = true
    self.m_mask:runCsbAction("animation2")

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




return DazzlingDiscoSpotMailWin