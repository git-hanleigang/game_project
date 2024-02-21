---
--xcyy
--2018年5月23日
--OwlsomeWizardSpineRoleFree.lua
local PublicConfig = require "OwlsomeWizardPublicConfig"
local NetSpriteLua = require("views.NetSprite")
local OwlsomeWizardSpineRoleFree = class("OwlsomeWizardSpineRoleFree",util_require("base.BaseView"))

function OwlsomeWizardSpineRoleFree:initUI()

end

function OwlsomeWizardSpineRoleFree:initSpineUI()
    self.m_spine_role = util_spineCreate("OwlsomeWizard_free_juese",true,true)
    self:addChild(self.m_spine_role)
    self:runIdleAni()
end

--[[
    idle
]]
function OwlsomeWizardSpineRoleFree:runIdleAni()
    self.m_spine_role:setVisible(true)
    util_spinePlay(self.m_spine_role,"idle",true)
end

--[[
    大赢庆祝动作
]]
function OwlsomeWizardSpineRoleFree:runBigWinAni(func)
    util_spinePlay(self.m_spine_role,"actionframe_qingzhu")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_qingzhu",function()
        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end

--[[
    过场动作
]]
function OwlsomeWizardSpineRoleFree:changeSceneAni(func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_OwlsomeWizard_change_scene_to_free_second)
    util_spinePlay(self.m_spine_role,"actionframe_guochang")
    util_spineEndCallFunc(self.m_spine_role,"actionframe_guochang",function()

        self:runIdleAni()
        if type(func) == "function" then
            func()
        end
    end)
end


return OwlsomeWizardSpineRoleFree