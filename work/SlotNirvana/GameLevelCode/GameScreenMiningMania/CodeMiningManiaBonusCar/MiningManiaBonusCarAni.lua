---
--xcyy
--2018年5月23日
--MiningManiaBonusCarAni.lua

local MiningManiaBonusCarAni = class("MiningManiaBonusCarAni",util_require("Levels.BaseLevelDialog"))

function MiningManiaBonusCarAni:initUI(_machine, _index)

    self:createCsbNode("MiningMania_Shejiao2_che.csb")

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

    self.m_headNodeTbl = {}
    for i=1, 5 do
        self.m_headNodeTbl[i] = self:findChild("Node_head_"..i)
    end

    self.m_lightAni = util_createAnimation("MiningMania_Shejiao2_che_guang.csb")
    self:findChild("Node_guang"):addChild(self.m_lightAni)
    self.m_lightAni:runCsbAction("idle", true)
    self.m_lightAni:setVisible(false)

    self.m_textMul = self:findChild("m_lb_num")
    util_setCascadeOpacityEnabledRescursion(self, true)
end

function MiningManiaBonusCarAni:resetData()
    self.m_curMul = 0
    self:setIdle()
    self:setMul(0)
    for i=1, 5 do
        self.m_headNodeTbl[i]:removeAllChildren()
    end
end

function MiningManiaBonusCarAni:setIdle()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle", true)
end

-- 自己显示光
function MiningManiaBonusCarAni:showLigth(_isShow)
    self.m_lightAni:setVisible(_isShow)
end

-- 减速
function MiningManiaBonusCarAni:reduceSpeedMove()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("move1", true)
end

function MiningManiaBonusCarAni:setMul(_mul)
    self.m_curMul = self.m_curMul + _mul
    local mulStr = "X" .. self.m_curMul
    if self.m_curMul > 0 then
        self.m_textMul:setVisible(true)
    else
        self.m_textMul:setVisible(false)
    end
    self.m_textMul:setString(mulStr)
end

function MiningManiaBonusCarAni:getMul()
    return self.m_curMul
end

-- 移动动画
function MiningManiaBonusCarAni:startMoveAni()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("move", true)
end

-- 反馈动画
function MiningManiaBonusCarAni:playTriggerAni(_isMe)
    util_resetCsbAction(self.m_csbAct)
    local actName = "fankui1"
    if _isMe then
        actName = "fankui"
    end
    self:runCsbAction(actName, false, function()
        self:runCsbAction("move", true)
    end)
end

-- 添加头像
function MiningManiaBonusCarAni:addHead(_item, _index, _arrowAni)
    self.m_headNodeTbl[_index]:addChild(_item)
end

-- 添加箭头
function MiningManiaBonusCarAni:addArrow(_index, _arrowAni)
    _arrowAni:setPositionY(90)
    self.m_headNodeTbl[_index]:addChild(_arrowAni)
end

return MiningManiaBonusCarAni
