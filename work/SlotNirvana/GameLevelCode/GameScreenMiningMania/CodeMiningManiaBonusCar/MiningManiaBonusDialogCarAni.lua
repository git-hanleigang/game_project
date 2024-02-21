---
--xcyy
--2018年5月23日
--MiningManiaBonusDialogCarAni.lua

local MiningManiaBonusDialogCarAni = class("MiningManiaBonusDialogCarAni",util_require("Levels.BaseLevelDialog"))

function MiningManiaBonusDialogCarAni:initUI(_machine, _index)

    self:createCsbNode("MiningMania_Tanban_che.csb")

    self:runCsbAction("idle", true)

    self.m_machineCar = _machine
    self.m_index = _index

    self.ENUM_CAR_TYPE = 
    {
        RED = 1,
        BLUE = 2,
        GREED = 3,
    }

    self:findChild("Node_hong"):setVisible(_index == self.ENUM_CAR_TYPE.RED)
    self:findChild("Node_lan"):setVisible(_index == self.ENUM_CAR_TYPE.BLUE)
    self:findChild("Node_lv"):setVisible(_index == self.ENUM_CAR_TYPE.GREED)

    self.m_textMul = self:findChild("m_lb_num")
end

function MiningManiaBonusDialogCarAni:setMul(_mul)
    local mulStr = "X" .. _mul
    self.m_textMul:setString(mulStr)
end

-- 移动动画
function MiningManiaBonusDialogCarAni:startMoveAni()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("move", true)
end

function MiningManiaBonusDialogCarAni:setIdle()
    self:runCsbAction("idle", true)
end

-- 触发动画
function MiningManiaBonusDialogCarAni:playTriggerAni()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("fly", false, function()
        self:runCsbAction("idle", true)
    end)
end

function MiningManiaBonusDialogCarAni:setNodeVisible()
    self:findChild("Node_bg"):setVisible(false)
end

-- 获取字体位置
function MiningManiaBonusDialogCarAni:getTextNodePosY()
    local textNode = self:findChild("Node_text")
    return textNode:getPositionY()
end

return MiningManiaBonusDialogCarAni
