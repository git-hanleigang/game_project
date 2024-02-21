---
--xcyy
--2018年5月23日
--CatchMonstersChooseBetTipsView.lua

local CatchMonstersChooseBetTipsView = class("CatchMonstersChooseBetTipsView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "CatchMonstersPublicConfig"

function CatchMonstersChooseBetTipsView:initUI()
    self:createCsbNode("CatchMonsters_winbox.csb")
    self:addClick(self:findChild("Panel_7"))
end

function CatchMonstersChooseBetTipsView:onEnter()
    CatchMonstersChooseBetTipsView.super.onEnter(self)
end

function CatchMonstersChooseBetTipsView:onExit()
    CatchMonstersChooseBetTipsView.super.onExit(self)
end

--默认按钮监听回调
function CatchMonstersChooseBetTipsView:clickFunc(sender)
    if not self.m_canClick then
        return
    end
    self.m_canClick = false
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "Button" or name == "Panel_7" then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_CatchMonsters_click)
        self:hideView()
    end
end

function CatchMonstersChooseBetTipsView:hideView()
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end
 
function CatchMonstersChooseBetTipsView:showView()
    self:setVisible(true)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
        self.m_canClick = true
    end)
end

return CatchMonstersChooseBetTipsView