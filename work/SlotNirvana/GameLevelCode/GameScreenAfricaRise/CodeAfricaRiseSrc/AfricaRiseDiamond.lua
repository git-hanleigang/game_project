---
--xcyy
--2018年5月23日
--AfricaRiseDiamond.lua

local AfricaRiseDiamond = class("AfricaRiseDiamond",util_require("base.BaseView"))


function AfricaRiseDiamond:initUI()
    self:createCsbNode("AfricaRise_Map_dian.csb")
    self.m_lock = true
end


function AfricaRiseDiamond:runLock()
    self:runCsbAction("idleframe1")
    self.m_lock = true
end

function AfricaRiseDiamond:runOpen(func)
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_map_diamond.mp3")
    self:runCsbAction(
        "animation0",
        false,
        function()
            self:runCsbAction("idleframe2",true)
            if func then
                func()
            end
        end
    )
    self.m_lock = false
end

function AfricaRiseDiamond:runIdle()
    self:runCsbAction("idleframe2",true)
    self.m_lock = false
end

function AfricaRiseDiamond:runOver()
    if  self.m_lock == true then
        self:runCsbAction("over")
    else
        self:runCsbAction("over1")
    end
end


function AfricaRiseDiamond:onEnter()

end

function AfricaRiseDiamond:onExit()
 
end


return AfricaRiseDiamond