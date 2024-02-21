---
--xcyy
--2018年5月23日
--MiningManiaBonusCarGateAni.lua

local MiningManiaBonusCarGateAni = class("MiningManiaBonusCarGateAni",util_require("Levels.BaseLevelDialog"))

function MiningManiaBonusCarGateAni:initUI(_machine)

    self:createCsbNode("MiningMania_Shejiao2_Start.csb")

    self:runCsbAction("idle", true)

    self.m_machineCar = _machine
end

function MiningManiaBonusCarGateAni:resetData()
    self:runCsbAction("idle", true)
end

-- 反馈动画
function MiningManiaBonusCarGateAni:playStart(_callfunc)
    local callfunc = _callfunc
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle2", true)
        if type(callfunc) == "function" then
            callfunc()
            callfunc = nil
        end
    end)
end

return MiningManiaBonusCarGateAni
