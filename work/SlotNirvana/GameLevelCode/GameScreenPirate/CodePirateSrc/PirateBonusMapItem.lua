local PirateBonusMapItem = class("PirateBonusMapItem", util_require("base.BaseView"))
-- 构造函数
function PirateBonusMapItem:initUI(data)
    local resourceFilename = "Bonus_Pirate_baoxiang.csb"
    self:createCsbNode(resourceFilename)
    -- self.m_particle = self.m_csbOwner["Particle_1"]
    self:runCsbAction("close")
end

function PirateBonusMapItem:idle()
    self:runCsbAction("close", true)
end

function PirateBonusMapItem:showParticle()
    -- self.m_particle:resetSystem()
end

function PirateBonusMapItem:click(func)
    self:runCsbAction("open", false, function()
        self:runCsbAction("idle", true)
        if func then
            performWithDelay(self, function()
                if func ~= nil then
                    func()
                end
            end, 0.5)
        end
    end)
end

function PirateBonusMapItem:completed()
    self:runCsbAction("idle", true)
end

function PirateBonusMapItem:onEnter()

end

function PirateBonusMapItem:onExit()

end

return PirateBonusMapItem