---
--island
--2018年4月12日
--MiningManiaBonusCarRedProcess.lua
local MiningManiaBonusCarRedProcess = class("MiningManiaBonusCarRedProcess", util_require("Levels.BaseLevelDialog"))
MiningManiaBonusCarRedProcess.m_isOver = false

function MiningManiaBonusCarRedProcess:onEnter()
    MiningManiaBonusCarRedProcess.super.onEnter(self)
end
function MiningManiaBonusCarRedProcess:onExit()
    MiningManiaBonusCarRedProcess.super.onExit(self)
end

function MiningManiaBonusCarRedProcess:initUI()
    self:createCsbNode("MiningMania_Shejiao2_Time_over.csb")
    self:runCsbAction("idle", true)
end

function MiningManiaBonusCarRedProcess:startAni()
    self.m_isOver = false
    self:setVisible(false)
end

function MiningManiaBonusCarRedProcess:endTimesTrigger()
    self:setVisible(true)
    self:runCsbAction("actionframe", true)
end

function MiningManiaBonusCarRedProcess:overAni()
    if self.m_isOver then
        return 
    end
    self.m_isOver = true
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

return MiningManiaBonusCarRedProcess
