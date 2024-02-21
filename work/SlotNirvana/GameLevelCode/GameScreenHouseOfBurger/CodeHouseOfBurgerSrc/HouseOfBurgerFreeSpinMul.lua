local HouseOfBurgerFreeSpinMul = class("HouseOfBurgerFreeSpinMul", util_require("base.BaseView"))
function HouseOfBurgerFreeSpinMul:initUI(data)

    local resourceFilename = "HouseOfBurger_beishu.csb"
    self:createCsbNode(resourceFilename)
    -- self.m_Particle_1 = self:findChild("Particle_1")
    -- self.m_Particle_1:setVisible(false)

    self:runCsbAction("idle",true)
end
function HouseOfBurgerFreeSpinMul:updateView(num)
    if self.m_curNum ~= num then
        self.m_curNum = num
        -- self.m_Particle_1:setVisible(true)
        -- self.m_Particle_1:resetSystem()
        -- performWithDelay(function()

        -- end)
    end
    self:findChild("lbs_num"):setString(num)
end


function HouseOfBurgerFreeSpinMul:onEnter()
end

function HouseOfBurgerFreeSpinMul:onExit()

end
return HouseOfBurgerFreeSpinMul
