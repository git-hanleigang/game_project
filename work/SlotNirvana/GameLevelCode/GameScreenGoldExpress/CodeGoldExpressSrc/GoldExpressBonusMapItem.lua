local GoldExpressBonusMapItem = class("GoldExpressBonusMapItem", util_require("base.BaseView"))
-- 构造函数
function GoldExpressBonusMapItem:initUI(data)
    local resourceFilename = "Bonus_GoldExpress_s.csb"--"Bonus_LinkFish_zhusunold.csb"
    if data ~= nil then
        resourceFilename = "Bonus_GoldExpress_s.csb"--"Bonus_LinkFish_zhusunold_2.csb"
    end
    self:createCsbNode(resourceFilename)
    -- self.m_particle = self.m_csbOwner["Particle_1"]
end

function GoldExpressBonusMapItem:idle()
    self:runCsbAction("actionframe", true)
end

function GoldExpressBonusMapItem:showParticle()
    -- self.m_particle:resetSystem()
end

function GoldExpressBonusMapItem:click(func)
    self:runCsbAction("click", false, function()
        self:runCsbAction("idleframe1", true)
        if func then
            performWithDelay(self, function()
                if func ~= nil then
                    func()
                end
            end, 0.5)
        end
    end)
end

function GoldExpressBonusMapItem:completed()
    self:runCsbAction("idleframe1", true)
end

function GoldExpressBonusMapItem:onEnter()

end

function GoldExpressBonusMapItem:onExit()

end

return GoldExpressBonusMapItem