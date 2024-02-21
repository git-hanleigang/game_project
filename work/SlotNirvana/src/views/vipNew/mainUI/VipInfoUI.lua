--[[
    说明界面
]]
local VipInfoUI = class("VipInfoUI", BaseLayer)
function VipInfoUI:initDatas()
    self:setLandscapeCsbName("VipNew/csd/mainUI/Vip_main_Info.csb")
end

function VipInfoUI:initCsbNodes()
    self.m_lizi1 = self:findChild("Particle_1")
    self.m_lizi2 = self:findChild("Particle_1_0")
    self.m_lizi3 = self:findChild("Particle_1_0_0")
end

function VipInfoUI:initView()
    self:runCsbAction("idle",true)
end

function VipInfoUI:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        if self.m_lizi3 then
            self.m_lizi1:setVisible(false)
            self.m_lizi2:setVisible(false)
            self.m_lizi3:setVisible(false)
        end
        self:closeUI()
    end
end

return VipInfoUI
