---
--island
--2018年4月12日
--MiningManiaBonusCarArrow.lua
local MiningManiaBonusCarArrow = class("MiningManiaBonusCarArrow", util_require("Levels.BaseLevelDialog"))
MiningManiaBonusCarArrow.m_isOver = false

function MiningManiaBonusCarArrow:onEnter()
    MiningManiaBonusCarArrow.super.onEnter(self)
end
function MiningManiaBonusCarArrow:onExit()
    MiningManiaBonusCarArrow.super.onExit(self)
end

function MiningManiaBonusCarArrow:initUI()
    self:createCsbNode("MiningMania_Shejiao_jiantou.csb")
    self:setVisible(false)
end

function MiningManiaBonusCarArrow:startAni()
    self.m_isOver = false
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

function MiningManiaBonusCarArrow:overAni()
    if self.m_isOver then
        return 
    end
    self.m_isOver = true
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false, function()
        self:setVisible(false)
    end)
end

return MiningManiaBonusCarArrow
