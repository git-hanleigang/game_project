---
--xcyy
--2018年5月23日
--ScarabChestMulView.lua
local PublicConfig = require "ScarabChestPublicConfig"
local ScarabChestMulView = class("ScarabChestMulView",util_require("Levels.BaseLevelDialog"))
ScarabChestMulView.m_lastMul = 0

function ScarabChestMulView:initUI(_machine)

    self:createCsbNode("ScarabChest_baoxiang_chengbei.csb")

    self.m_machine = _machine

    self.m_mulText = self:findChild("m_lb_num")

    self:setIdle()
    self.m_maxWidth = 357

    self:setMul(0, true)
end

-- idle
function ScarabChestMulView:setIdle()
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("idle", true)
end

-- 进free
function ScarabChestMulView:playFeedBack(_curMul)
    local curMul = _curMul
    self:setVisible(true)
    local actName = "actionframe_fankui1"
    if curMul >= 5 then
        actName = "actionframe_fankui2"
    end
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction(actName, false, function()
        self:runCsbAction("idle", true)
    end)
end

-- 出现
function ScarabChestMulView:showStart()
    self:setMul(0, true)
    self:setVisible(true)
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

-- over
function ScarabChestMulView:closeMul(_isInit)
    local isInit = _isInit
    self:setLastMul(0)
    util_resetCsbAction(self.m_csbAct)
    if isInit then
        self:setVisible(false)
    else
        self:runCsbAction("over", false, function()
            self:setVisible(false)
        end)
    end
end

-- 倍数
-- 一次加的倍数
-- free bonus玩法结束重置
function ScarabChestMulView:setMul(_mul, _isEnd)
    local lastMul = self:getLastMul()
    local curMul = lastMul + _mul
    if _isEnd then
        curMul = _mul
        self:setLastMul(_mul)
    end
    self.m_mulText:setString(curMul.."X")
    self:updateLabelSize({label=self.m_mulText,sx=1.0,sy=1.0},self.m_maxWidth)
    self:setLastMul(curMul)
end

function ScarabChestMulView:setLastMul(_lastMul)
    self.m_lastMul = _lastMul
end

function ScarabChestMulView:getLastMul()
    return self.m_lastMul
end

-- 字体节点
function ScarabChestMulView:getMulTextNode()
    return self.m_mulText
end

return ScarabChestMulView
