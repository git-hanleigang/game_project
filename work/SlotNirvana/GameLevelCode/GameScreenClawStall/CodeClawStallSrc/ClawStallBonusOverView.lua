---
--xcyy
--2018年5月23日
--ClawStallBonusOverView.lua

local ClawStallBonusOverView = class("ClawStallBonusOverView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "ClawStallPublicConfig"

function ClawStallBonusOverView:initUI(params)
    local winCoins = params.winCoins
    self.m_endFunc = params.func

    if winCoins == 0 then
        self:createCsbNode("ClawStall/FreeSpinOver_NoWins.csb")
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_show_bonus_over)
        self:createCsbNode("ClawStall/BonusOver.csb")

        self:findChild("m_lb_coins"):setString(util_formatCoins(winCoins,50))
        self:updateLabelSize({label=self:findChild("m_lb_coins"),sx=1,sy=1},750)

        local symbol1 = util_spineCreate("Socre_ClawStall_5",true,true)
        self:findChild("Birds_lv"):addChild(symbol1)
        local params = {}
        params[1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = symbol1,   --执行动画节点  必传参数
            actionName = "start", --动作名称  动画必传参数,单延时动作可不传
            callBack = function(  )
                util_spinePlay(symbol1,"idle",true)
            end
        }
        util_runAnimations(params)


        local symbol2 = util_spineCreate("Socre_ClawStall_6",true,true)
        self:findChild("Birds_lan"):addChild(symbol2)
        local params = {}
        params[1] = {
            type = "spine",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = symbol2,   --执行动画节点  必传参数
            actionName = "start", --动作名称  动画必传参数,单延时动作可不传
            callBack = function(  )
                util_spinePlay(symbol2,"idle",true)
            end
        }
        util_runAnimations(params)
    end
    
    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
    end)
end

--默认按钮监听回调
function ClawStallBonusOverView:clickFunc(sender)
    if self.m_isClicked then
        return
    end
    self.m_isClicked = true

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ClawStall_click_btn)
    
    self:runCsbAction("over",false,function(  )
        if type(self.m_endFunc) == "function" then
            self.m_endFunc()
        end
        self:removeFromParent()
    end)
end




return ClawStallBonusOverView