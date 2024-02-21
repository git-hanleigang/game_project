---
--xcyy
--2018年5月23日
--MagicianJackPotBarView.lua

local MagicianJackPotBarView = class("MagicianJackPotBarView",util_require("Levels.BaseLevelDialog"))

local GrandName = "m_lb_grand"
local MajorName = "m_lb_major"
local MinorName = "m_lb_minor"
local MiniName = "m_lb_mini" 

function MagicianJackPotBarView:initUI()

    -- self:createCsbNode("Magician_Jackpot.csb")

    -- self:runCsbAction("idleframe",true)

    self.m_csbMini = util_createAnimation("Magician_Jackpot_Mini.csb")
    self.m_csbMinor = util_createAnimation("Magician_Jackpot_Minor.csb")
    self.m_csbMajor = util_createAnimation("Magician_Jackpot_Major.csb")
    self.m_csbGrand = util_createAnimation("Magician_Jackpot_Grand.csb")

    self:addChild(self.m_csbMini)
    self:addChild(self.m_csbMinor)
    self:addChild(self.m_csbMajor)
    self:addChild(self.m_csbGrand)

    self.m_csbMini:findChild("Node_SymbolMini"):setVisible(false)
    self.m_csbMinor:findChild("Node_SymbolMinor"):setVisible(false)
    self.m_csbMajor:findChild("Node_SymbolMajor"):setVisible(false)
    self.m_csbGrand:findChild("Node_SymbolGrand"):setVisible(false)
end

function MagicianJackPotBarView:onEnter()

    MagicianJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function MagicianJackPotBarView:onExit()
    MagicianJackPotBarView.super.onExit(self)
end

function MagicianJackPotBarView:initMachine(machine)
    self.m_machine = machine
end



-- 更新jackpot 数值信息
--
function MagicianJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self.m_csbGrand:findChild("m_lb_coins"),1,true)
    self:changeNode(self.m_csbMajor:findChild("m_lb_coins"),2,true)
    self:changeNode(self.m_csbMinor:findChild("m_lb_coins"),3)
    self:changeNode(self.m_csbMini:findChild("m_lb_coins"),4)

    self:updateSize()
end

function MagicianJackPotBarView:updateSize()

    local label1=self.m_csbGrand:findChild("m_lb_coins")
    local label2=self.m_csbMajor:findChild("m_lb_coins")
    local info1={label=label1,sx=1,sy=1}
    local info2={label=label2,sx=1,sy=1}
    local label3=self.m_csbMinor:findChild("m_lb_coins")
    local info3={label=label3,sx=0.9,sy=0.9}
    local label4=self.m_csbMini:findChild("m_lb_coins")
    local info4={label=label4,sx=0.9,sy=0.9}
    self:updateLabelSize(info1,245)
    self:updateLabelSize(info2,245)
    self:updateLabelSize(info3,215)
    self:updateLabelSize(info4,215)
end

function MagicianJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end


--[[
    中jackpot动画
]]
function MagicianJackPotBarView:hitJackpotAni(hitTypes)
    for k,symbolType in pairs(hitTypes) do
        if symbolType == self.m_machine.SYMBOL_MINI then
            self.m_csbMini:runCsbAction("win",true)
        elseif symbolType == self.m_machine.SYMBOL_MINOR then
            self.m_csbMinor:runCsbAction("win",true)
        elseif symbolType == self.m_machine.SYMBOL_MAJOR then
            self.m_csbMajor:runCsbAction("win",true)
        elseif symbolType == self.m_machine.SYMBOL_GRAND then
            self.m_csbGrand:runCsbAction("win",true)
        end
    end
    
end

--[[
    重置jackpot动画
]]
function MagicianJackPotBarView:resetJackpotAni()
    self.m_csbMini:runCsbAction("idle")
    self.m_csbMinor:runCsbAction("idle")
    self.m_csbMajor:runCsbAction("idle")
    self.m_csbGrand:runCsbAction("idle")
end

--[[
    显示宝石
]]
function MagicianJackPotBarView:showDiamond(isVisible)

    if isVisible then
        self.m_csbMini:findChild("Node_SymbolMini"):setVisible(isVisible)
        self.m_csbMinor:findChild("Node_SymbolMinor"):setVisible(isVisible)
        self.m_csbMajor:findChild("Node_SymbolMajor"):setVisible(isVisible)
        self.m_csbGrand:findChild("Node_SymbolGrand"):setVisible(isVisible)
        self.m_csbMini:runCsbAction("start")
        self.m_csbMinor:runCsbAction("start")
        self.m_csbMajor:runCsbAction("start")
        self.m_csbGrand:runCsbAction("start")
    else
        self.m_csbMini:runCsbAction("over",false,function()
            self.m_csbMini:findChild("Node_SymbolMini"):setVisible(false)
        end)
        self.m_csbMinor:runCsbAction("over",false,function()
            self.m_csbMinor:findChild("Node_SymbolMinor"):setVisible(false)
        end)
        self.m_csbMajor:runCsbAction("over",false,function()
            self.m_csbMajor:findChild("Node_SymbolMajor"):setVisible(false)
        end)
        self.m_csbGrand:runCsbAction("over",false,function()
            self.m_csbGrand:findChild("Node_SymbolGrand"):setVisible(false)
        end)
    end
end

--[[
    收集动效
]]
function MagicianJackPotBarView:collectAni(symbolType,leftCount,func)
    if leftCount <= 0 then
        leftCount = 0
    end

    if symbolType == self.m_machine.SYMBOL_MINI then
        self.m_csbMini:runCsbAction("actionframe",false,function()
            if type(func) == "function" then
                func()
            end
        end)
        
    elseif symbolType == self.m_machine.SYMBOL_MINOR then
        self.m_csbMinor:runCsbAction("actionframe",false,function()
            if type(func) == "function" then
                func()
            end
        end)
        
    elseif symbolType == self.m_machine.SYMBOL_MAJOR then
        self.m_csbMajor:runCsbAction("actionframe",false,function()
            if type(func) == "function" then
                func()
            end
        end)
        
    elseif symbolType == self.m_machine.SYMBOL_GRAND then
        self.m_csbGrand:runCsbAction("actionframe",false,function()
            if type(func) == "function" then
                func()
            end
        end)
        
    end

    self.m_machine:delayCallBack(10 / 60,function()
        self:refreshLeftCount(symbolType,leftCount)
    end)
end

--[[
    获取目标节点
]]
function MagicianJackPotBarView:getTargetNode(symbolType)
    if symbolType == self.m_machine.SYMBOL_MINI then
        return self.m_csbMini
    elseif symbolType == self.m_machine.SYMBOL_MINOR then
        return self.m_csbMinor
    elseif symbolType == self.m_machine.SYMBOL_MAJOR then
        return self.m_csbMajor
    elseif symbolType == self.m_machine.SYMBOL_GRAND then
        return self.m_csbGrand
    end
end


--[[
    刷新剩余数量
]]
function MagicianJackPotBarView:refreshLeftCount(symbolType,leftCount)
    if symbolType == self.m_machine.SYMBOL_MINI then
        self.m_csbMini:findChild("m_lb_num1"):setString(leftCount)
        self.m_csbMini:findChild("m_lb_num1"):setVisible(leftCount > 0)
        if leftCount <= 0 then
            self.m_csbMini:runCsbAction("win",true)
        end
    elseif symbolType == self.m_machine.SYMBOL_MINOR then
        self.m_csbMinor:findChild("m_lb_num1"):setString(leftCount)
        self.m_csbMinor:findChild("m_lb_num1"):setVisible(leftCount > 0)
        if leftCount <= 0 then
            self.m_csbMinor:runCsbAction("win",true)
        end
    elseif symbolType == self.m_machine.SYMBOL_MAJOR then
        self.m_csbMajor:findChild("m_lb_num1"):setString(leftCount)
        self.m_csbMajor:findChild("m_lb_num1"):setVisible(leftCount > 0)
        if leftCount <= 0 then
            self.m_csbMajor:runCsbAction("win",true)
        end
    elseif symbolType == self.m_machine.SYMBOL_GRAND then
        self.m_csbGrand:findChild("m_lb_num1"):setString(leftCount)
        self.m_csbGrand:findChild("m_lb_num1"):setVisible(leftCount > 0)
        if leftCount <= 0 then
            self.m_csbGrand:runCsbAction("win",true)
        end
    end
end

return MagicianJackPotBarView