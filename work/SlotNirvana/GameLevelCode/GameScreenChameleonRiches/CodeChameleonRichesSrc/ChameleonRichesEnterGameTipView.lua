---
--xcyy
--2018年5月23日
--ChameleonRichesEnterGameTipView.lua
local PublicConfig = require "ChameleonRichesPublicConfig"
local ChameleonRichesEnterGameTipView = class("ChameleonRichesEnterGameTipView",util_require("Levels.BaseLevelDialog"))


function ChameleonRichesEnterGameTipView:initUI()

    self:createCsbNode("ChameleonRiches/EnterGameTips.csb")

    
end

--[[
    初始化spine动画
]]
function ChameleonRichesEnterGameTipView:initSpineUI()
    self.m_spine = util_spineCreate("ChameleonRiches_tanbanstart",true,true)
    self:findChild("Node_spine"):addChild(self.m_spine)

    self:showView()
end

--[[
    显示界面
]]
function ChameleonRichesEnterGameTipView:showView()
    self:findChild("Button_1"):setTouchEnabled(false)
    local params = {}
    params[1] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self,   --执行动画节点  必传参数
        actionName = "start", --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            self:findChild("Button_1"):setTouchEnabled(true)
        end,  
    }
    params[2] = {
        type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
        node = self,   --执行动画节点  必传参数
        actionName = "idle", --动作名称  动画必传参数,单延时动作可不传
        callBack = function()
            self:hideView()
        end,   --回调函数 可选参数
    }
    util_runAnimations(params)

    util_spinePlay(self.m_spine,"start")
end

--[[
    隐藏界面
]]
function ChameleonRichesEnterGameTipView:hideView()
    if self.m_isOver then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_hide_tip_view)
    self.m_isOver = true
    self:runCsbAction("over",false,function()
        self:removeFromParent()
    end)
end

--[[
    默认点击回调
]]
function ChameleonRichesEnterGameTipView:clickFunc(sender)
    if self.m_isOver then
        return
    end

    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_ChameleonRiches_btn_click)
    
    self:hideView()
end


return ChameleonRichesEnterGameTipView