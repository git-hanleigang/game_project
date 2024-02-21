---
--xcyy
--2018年5月23日
--PudgyPandaCollectView.lua
local PublicConfig = require "PudgyPandaPublicConfig"
local PudgyPandaCollectView = class("PudgyPandaCollectView",util_require("Levels.BaseLevelDialog"))

PudgyPandaCollectView.m_totalLen = 800
PudgyPandaCollectView.m_lastCollectNum = 0
PudgyPandaCollectView.m_isClick = false
PudgyPandaCollectView.m_collectRatio = {3, 4, 5} --三种free在进度条上的收集比例

function PudgyPandaCollectView:initUI(_machine)

    self.m_machine = _machine
    self:createCsbNode("PudgyPanda_shouji.csb")
    self:runCsbAction("idle", true)

    self.m_collectItemNodeAni = {}
    for i=1, 3 do
        self.m_collectItemNodeAni[i] = util_createView("CodePudgyPandaCollectSrc.PudgyPandaCollectItem", self.m_machine, i)
        self:findChild("Node_FreeType"):addChild(self.m_collectItemNodeAni[i])
    end

    -- 收集进度
    self.m_nodeProcess = self:findChild("Node_Process")
    -- 收集的节点
    self.m_bonusNode = self:findChild("Node_bonus")

    -- 进度条上的动画
    self.m_precessAni = util_createAnimation("PudgyPanda_shouji_zhang.csb")
    self.m_nodeProcess:addChild(self.m_precessAni)
    self.m_precessAni:runCsbAction("idle", true)

    self:addClick(self:findChild("Panel_click"))

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)
end

--默认按钮监听回调
function PudgyPandaCollectView:clickFunc(sender)
    local name = sender:getName()

    if (name == "Panel_click" or name == "Button_1") and self.m_machine:tipsBtnIsCanClick() then
        -- self:setCilckState(false)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_PudgyPanda_click)
        self.m_machine:openCollectMap()
    end
end

-- 设置初始位置和初始进度
function PudgyPandaCollectView:initProcess(_curCollectNum)
    local curCollectNum = _curCollectNum
    self.intervalLen = {}
    -- 收集一个的长度（像素）
    for i=1, 3 do
        local totalLen = self.m_totalLen / (self.m_collectRatio[1] + self.m_collectRatio[2] + self.m_collectRatio[3]) * self.m_collectRatio[i]
        if i == 1 then
            totalLen = totalLen - 40 - 15
            self.intervalLen[i] = totalLen / self.m_machine.m_baseCollectConfig[i]
        else
            totalLen = totalLen - 80
            self.intervalLen[i] = totalLen / (self.m_machine.m_baseCollectConfig[i] - self.m_machine.m_baseCollectConfig[i-1])
        end
    end

    for i=1, 3 do
        -- 根据总长度算出freeGame、superGame、megaGame所在的位置
        local freeTypePosX = 0
        local totalLen = self.m_totalLen / (self.m_collectRatio[1] + self.m_collectRatio[2] + self.m_collectRatio[3])
        for index = 1, i do
            freeTypePosX = freeTypePosX + totalLen * self.m_collectRatio[index]
        end
        self.m_collectItemNodeAni[i]:setPositionX(freeTypePosX)
    end

    -- 收集的进度
    self:setCurProcess(curCollectNum, true)
end

-- 设置进度
function PudgyPandaCollectView:setCurProcess(_curCollectNum, _onEnter, _callFunc)
    local curCollectNum = _curCollectNum
    local onEnter = _onEnter
    local callFunc = _callFunc
    local curPosX = 0
    if onEnter then
        if curCollectNum < self.m_machine.m_baseCollectConfig[1] then
            curPosX = curCollectNum * self.intervalLen[1]+15
        elseif curCollectNum < self.m_machine.m_baseCollectConfig[2] then
            curPosX = self.m_machine.m_baseCollectConfig[1] * self.intervalLen[1] + (curCollectNum - self.m_machine.m_baseCollectConfig[1]) * self.intervalLen[2]
            + 84
        else
            curPosX = self.m_machine.m_baseCollectConfig[1] * self.intervalLen[1] + (self.m_machine.m_baseCollectConfig[2] - self.m_machine.m_baseCollectConfig[1]) * self.intervalLen[2]
            + (curCollectNum - self.m_machine.m_baseCollectConfig[2]) * self.intervalLen[3] + 84*2
        end
    else
        if curCollectNum <= self.m_machine.m_baseCollectConfig[1] then
            curPosX = curCollectNum * self.intervalLen[1]+15
        elseif curCollectNum <= self.m_machine.m_baseCollectConfig[2] then
            curPosX = self.m_machine.m_baseCollectConfig[1] * self.intervalLen[1] + (curCollectNum - self.m_machine.m_baseCollectConfig[1]) * self.intervalLen[2]
            + 84
        else
            curPosX = self.m_machine.m_baseCollectConfig[1] * self.intervalLen[1] + (self.m_machine.m_baseCollectConfig[2] - self.m_machine.m_baseCollectConfig[1]) * self.intervalLen[2]
            + (curCollectNum - self.m_machine.m_baseCollectConfig[2]) * self.intervalLen[3] + 84*2
        end
    end

    -- 0:不触发；1：触发free；2：触发super
    local triggerFreeType = 0
    if curCollectNum == self.m_machine.m_baseCollectConfig[1] then
        triggerFreeType = 1
    end

    if curCollectNum == self.m_machine.m_baseCollectConfig then
        triggerFreeType = 2
    end

    if onEnter then
        self.m_nodeProcess:setPositionX(curPosX)
        if self.m_machine.m_baseCollectConfig then
            for k, v in pairs(self.m_machine.m_baseCollectConfig) do
                if curCollectNum >= v then
                    self.m_collectItemNodeAni[k]:setSpecialIdle()
                else
                    self.m_collectItemNodeAni[k]:setIdle()
                end
            end
        end
    else
        local delayTime = 0.6
        local moveToAct = cc.MoveTo:create(delayTime, cc.p(curPosX, 38))
        util_resetCsbAction(self.m_precessAni.m_csbAct)
        self.m_precessAni:runCsbAction("actionframe", false, function()
            self.m_precessAni:runCsbAction("idle", true)
            -- 判断是否触发玩法
            -- if triggerFreeType ~= 0 then
            --     self.m_collectItemNodeAni[triggerFreeType]:setSpecialIdle()
            -- end
            if type(callFunc) == "function" then
                callFunc()
            end
        end)
        self.m_nodeProcess:runAction(moveToAct)
    end

    self.m_lastCollectNum = curCollectNum
end

-- 播放对应free的触发
function PudgyPandaCollectView:playTriggerAction(_triggerFreeType, _callFunc)
    local triggerFreeType = _triggerFreeType
    local callFunc = _callFunc
    self.m_collectItemNodeAni[triggerFreeType]:playTriggerAction(callFunc)
end

-- 收集
function PudgyPandaCollectView:playCollectAction()
    util_resetCsbAction(self.m_csbAct)
    self:runCsbAction("actionframe", false, function()
        self:runCsbAction("idle", true)
    end)
end

function PudgyPandaCollectView:setCilckState(_isClick)
    self.m_isClick = _isClick
end

function PudgyPandaCollectView:isCanTouch()
    return self.m_isClick
end

-- 获取收集最终位置
function PudgyPandaCollectView:getCollectBonusNode()
    return self.m_bonusNode
end

return PudgyPandaCollectView
