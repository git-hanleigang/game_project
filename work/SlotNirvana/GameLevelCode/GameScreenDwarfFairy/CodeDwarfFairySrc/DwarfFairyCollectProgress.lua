---
--island
--2018年4月12日
--DwarfFairyCollectProgress.lua
---- respin 玩法结算时中 mini mijor等提示界面
local DwarfFairyCollectProgress = class("DwarfFairyCollectProgress", util_require("base.BaseView"))

DwarfFairyCollectProgress.PROGRESS_WIDTH = 149
function DwarfFairyCollectProgress:initUI(data)
    self.m_click = false

    local resourceFilename = "DwarfFairy_Lock_jindutiao.csb"
    self:createCsbNode(resourceFilename)
    self.m_progress = self:findChild("LoadingBar_1")
    self.m_particleLayer = self:findChild("particle_layer")
end

function DwarfFairyCollectProgress:setProgress(progress)
    if progress > 100 then
        progress = 100
    end
    self.m_progress:setPercent(progress)
    if progress > 3 then
        self.m_particleLayer:setContentSize(self.PROGRESS_WIDTH * (progress - 3) * 0.01, 27)
        local particle =  self:findChild("Particle_2")
        particle:resetSystem()
        particle:setPositionX(self.PROGRESS_WIDTH * progress * 0.01 - 8) 
    else
        self.m_particleLayer:setContentSize(0, 27)
    end
    
    if progress >= 100 then
        gLobalSoundManager:playSound("DwarfFairySounds/sound_DwarfFairy_trigger_bonus.mp3")
    end
end

function DwarfFairyCollectProgress:onEnter()
end

function DwarfFairyCollectProgress:onExit()
end


return DwarfFairyCollectProgress