---
--xcyy
--2018年5月23日
--AfricaRiseAnimalIcon.lua

local AfricaRiseAnimalIcon = class("AfricaRiseAnimalIcon", util_require("base.BaseView"))

function AfricaRiseAnimalIcon:initUI(_type)
    local strName = "AfricaRise_Map_lu.csb"
    if _type == 2 then
        strName = "AfricaRise_Map_banma.csb"
    elseif _type == 3 then
        strName = "AfricaRise_Map_niu.csb"
    elseif _type == 4 then
        strName = "AfricaRise_Map_daxiang.csb"
    elseif _type == 5 then
        strName = "AfricaRise_Map_shizi.csb"
    end
    self:createCsbNode(strName)
    self.m_lock = true
end

function AfricaRiseAnimalIcon:runLock()
    self:runCsbAction("idleframe1")
    self.m_lock = true
end

function AfricaRiseAnimalIcon:runOpen(func)
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_map_ani.mp3")
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

function AfricaRiseAnimalIcon:runIdle()
    self:runCsbAction("idleframe2",true)
    self.m_lock = false
end

function AfricaRiseAnimalIcon:runOver()
    if  self.m_lock == true then
        self:runCsbAction("over")
    else
        self:runCsbAction("over2")
    end
end

function AfricaRiseAnimalIcon:onEnter()
end

function AfricaRiseAnimalIcon:onExit()
end

return AfricaRiseAnimalIcon
