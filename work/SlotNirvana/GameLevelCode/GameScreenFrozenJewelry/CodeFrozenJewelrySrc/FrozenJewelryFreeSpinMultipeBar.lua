---
--xcyy
--2018年5月23日
--FrozenJewelryFreeSpinMultipeBar.lua

local FrozenJewelryFreeSpinMultipeBar = class("FrozenJewelryFreeSpinMultipeBar",util_require("Levels.BaseLevelDialog"))


function FrozenJewelryFreeSpinMultipeBar:initUI(params)
    self.m_machine = params.machine
    self:createCsbNode("FrozenJewelry_Free_Multiplier.csb")

    self:idleAni1()
end

function FrozenJewelryFreeSpinMultipeBar:idleAni1()
    self:runCsbAction("idle1")
    self.m_isFirst = true
end

function FrozenJewelryFreeSpinMultipeBar:idleAni()
    self:runCsbAction("idle")
end

--刷光特效
function FrozenJewelryFreeSpinMultipeBar:lightAni(func)
    self:runCsbAction("actionframe1",false,func)
    self.m_isFirst = false
end

--爆点特效
function FrozenJewelryFreeSpinMultipeBar:pointAni(func)
    self:runCsbAction("actionframe",false,func)
end

--刷新倍数
function FrozenJewelryFreeSpinMultipeBar:refreshMutiple(multiple,isNeedAni,func)
    if not multiple then
        return
    end
    if isNeedAni then
        gLobalSoundManager:playSound("FrozenJewelrySounds/sound_FrozenJewelry_super_free_multiple_refresh.mp3")
        if self.m_isFirst then
            self:lightAni(func)
        else
            self:pointAni(func)
        end
        self.m_machine:delayCallBack(20 / 60,function()
            self:findChild("m_lb_multiplier"):setString("X"..multiple)
        end)
    else
        self:findChild("m_lb_multiplier"):setString("X"..multiple)
        self:idleAni()
    end
    
end


return FrozenJewelryFreeSpinMultipeBar