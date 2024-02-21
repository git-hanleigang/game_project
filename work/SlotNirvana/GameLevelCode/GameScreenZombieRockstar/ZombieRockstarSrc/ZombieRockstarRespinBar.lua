---
--xcyy
--2018年5月23日
--ZombieRockstarRespinBar.lua
local ZombieRockstarRespinBar = class("ZombieRockstarRespinBar",util_require("Levels.BaseLevelDialog"))
local ZombieRockstarPublicConfig = require "ZombieRockstarPublicConfig"

function ZombieRockstarRespinBar:initUI(params)
    self.m_machine = params
    self:createCsbNode("ZombieRockstar_respin_left.csb")

    self.m_iconRoleSpine = util_spineCreate("ZombieRockstar_guochang", true, true)
    self:findChild("icon"):addChild(self.m_iconRoleSpine)
    util_setCascadeOpacityEnabledRescursion(self:findChild("icon"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("icon"), true)

    self.m_mulIconNode = util_createAnimation("ZombieRockstar_respin_left_icon.csb")
    self:findChild("icon_mul"):addChild(self.m_mulIconNode)
    util_setCascadeOpacityEnabledRescursion(self:findChild("icon_mul"), true)
    util_setCascadeColorEnabledRescursion(self:findChild("icon_mul"), true)
end

--[[
    刷新当前次数
]]
function ZombieRockstarRespinBar:updateRespinCount(curCount, totalCount, isPlay)
    if isPlay then
        gLobalSoundManager:playSound(ZombieRockstarPublicConfig.SoundConfig.sound_ZombieRockstar_respin_again_spin_fly_end)
        self:runCsbAction("actionframe", false)
        self:findChild("Particle_1"):resetSystem()
    end
    
    if self.m_machine:isRespinJiMan() then
        self:runCsbAction("actionframe2", false)
        performWithDelay(self, function()
            gLobalSoundManager:playSound(ZombieRockstarPublicConfig.SoundConfig.sound_ZombieRockstar_respin_nums_change)
            self:findChild("m_lb_num_1"):setString(curCount)
            self:findChild("m_lb_num_3"):setString(totalCount)
        end, 20/60)
    else
        self:findChild("m_lb_num_1"):setString(curCount)
        self:findChild("m_lb_num_3"):setString(totalCount)
    end
end

function ZombieRockstarRespinBar:updateIcon(_symbol)
    util_spinePlay(self.m_iconRoleSpine, "idleframe"..(_symbol+1).."_1", true)
end

--[[
    显示 不同描述
]]
function ZombieRockstarRespinBar:showOrHideWenZi(_vis)
    if _vis then
        self:runCsbAction("idle1", false, function()
            self:findChild("Node_respin"):setVisible(_vis)
            self:findChild("Node_mul"):setVisible(not _vis)
        end)
    else
        self:runCsbAction("idle2", false, function()
            self:findChild("Node_respin"):setVisible(_vis)
            self:findChild("Node_mul"):setVisible(not _vis)
        end)
    end
end

return ZombieRockstarRespinBar