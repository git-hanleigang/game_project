---
--xcyy
--2018年5月23日
--AfricaRiseAddWildEffect.lua

local AfricaRiseAddWildEffect = class("AfricaRiseAddWildEffect",util_require("base.BaseView"))

function AfricaRiseAddWildEffect:initUI()

    self:createCsbNode("AfricaRise_AddWild.csb")
end


function AfricaRiseAddWildEffect:onEnter()
end

function AfricaRiseAddWildEffect:onExit()
end


function AfricaRiseAddWildEffect:playAddWildEffect(func)
    gLobalSoundManager:playSound("AfricaRiseSounds/sound_AfricaRise_freespin_diamond.mp3")
    self:runCsbAction("actionframe",false,function (  )
        if func then
            func()
        end
        self:removeFromParent()

    end)
end

return AfricaRiseAddWildEffect