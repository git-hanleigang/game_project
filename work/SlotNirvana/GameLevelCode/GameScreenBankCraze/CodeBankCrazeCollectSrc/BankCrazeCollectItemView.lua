---
--xcyy
--2018年5月23日
--BankCrazeCollectItemView.lua
local PublicConfig = require "BankCrazePublicConfig"
local BankCrazeCollectItemView = class("BankCrazeCollectItemView",util_require("Levels.BaseLevelDialog"))

function BankCrazeCollectItemView:initUI()
    self:createCsbNode("BankCraze_Jindutiao_CollectItem.csb")

    self.m_collectNodeTbl = {}
    self.m_collectNodeTbl[1] = self:findChild("Tong")
    self.m_collectNodeTbl[2] = self:findChild("Yin")

    self:playIdle(1)
end

-- 收集前的idle
function BankCrazeCollectItemView:playIdle(_curLevel)
    self.m_isCollect = false
    self:showCollectByType(_curLevel)
    self:runCsbAction("idle1", true)
end

-- 收集后的idle
function BankCrazeCollectItemView:playCollectIdle(_curLevel)
    self.m_isCollect = true
    self:showCollectByType(_curLevel)
    self:runCsbAction("idle2", true)
end

-- 等级三（金银行隐藏）
function BankCrazeCollectItemView:playHeightIdle()
    self.m_isCollect = false
    self:runCsbAction("idle4", true)
end

-- 集满触发；清空特效
function BankCrazeCollectItemView:playTriggerAct(_curLevel)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over", false, function()
        self:playIdle(_curLevel)
    end)
end

-- 收集到最高级；消失
function BankCrazeCollectItemView:playHeightOverAct()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("over2", false, function()
        self:playHeightIdle()
    end)
end

-- 收集特效
function BankCrazeCollectItemView:playCollectAct(_curLevel)
    self:showCollectByType(_curLevel)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", false, function()
        self:playCollectIdle(_curLevel)
    end)
end

-- 显示铜和银
function BankCrazeCollectItemView:showCollectByType(_curLevel)
    local curLevel = _curLevel
    for i=1, 2 do
        self.m_collectNodeTbl[i]:setVisible(i==curLevel)
    end
end

-- 差一个集满
function BankCrazeCollectItemView:showBeAboutToAllAct(_curLevel)
    self:showCollectByType(_curLevel)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle3", true)
end

-- 最高级到最低级转换
function BankCrazeCollectItemView:playHeightToLowAct(_isHeightLevel)
    util_resetCsbAction(self.m_csbAct)
    if _isHeightLevel then
        self:runCsbAction("start", false, function()
            self:playIdle(1)
        end)
    else
        if self.m_isCollect then
            self:runCsbAction("over", false, function()
                self:playIdle(1)
            end)
        else
            self:playIdle(1)
        end
    end
end

return BankCrazeCollectItemView
