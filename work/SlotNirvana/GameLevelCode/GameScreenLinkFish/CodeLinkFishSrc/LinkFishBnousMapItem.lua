local LinkFishBnousMapItem = class("LinkFishBnousMapItem", util_require("base.BaseView"))
-- 构造函数
function LinkFishBnousMapItem:initUI(data)
    local resourceFilename = "Bonus_LinkFish_zhusunold.csb"
    if data ~= nil then
        resourceFilename = "Bonus_LinkFish_zhusunold_2.csb"
    end
    self:createCsbNode(resourceFilename)
    -- self.m_particle = self.m_csbOwner["Particle_1"]
end

function LinkFishBnousMapItem:idle()
    self:runCsbAction("actionframe", true)
end

function LinkFishBnousMapItem:showParticle()
    -- self.m_particle:resetSystem()
end

function LinkFishBnousMapItem:click(func)
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

function LinkFishBnousMapItem:completed()
    self:runCsbAction("idleframe1", true)
end

function LinkFishBnousMapItem:onEnter()
    
end

function LinkFishBnousMapItem:onExit()
    
end

return LinkFishBnousMapItem