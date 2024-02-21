---
--MedusaManiaJackpotNode.lua

local MedusaManiaJackpotNode = class("MedusaManiaJackpotNode",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MedusaManiaPublicConfig"

MedusaManiaJackpotNode.m_machine = nil
MedusaManiaJackpotNode.m_jackpot_machine = nil
MedusaManiaJackpotNode.m_curIndex = nil
MedusaManiaJackpotNode.m_cilck = nil

function MedusaManiaJackpotNode:initUI(_m_machine, _jackpot_machine, _index)

    self:createCsbNode("MedusaMania_duofuduocaiscatter.csb")

    self.m_jackpotNode = self:findChild("Node_jackpot")

    self.m_jackpotNodeSpine = util_spineCreate("Socre_MedusaMania_Scatter",true,true)
    self.m_jackpotNode:addChild(self.m_jackpotNodeSpine)

    -- self.m_jackpotNodeSpine = util_spineCreate("Socre_RedHotDevils_Scatter",true,true)
    -- self.m_jackpotNode:addChild(self.m_jackpotNodeSpine)
    
    self.m_machine = _m_machine
    self.m_jackpot_machine = _jackpot_machine
    self.m_curIndex = _index
    self.m_cilck = true

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:addClick(self:findChild("click_panel")) -- 非按钮节点得手动绑定监听
end

function MedusaManiaJackpotNode:onExit()
    MedusaManiaJackpotNode.super.onExit(self)
end

function MedusaManiaJackpotNode:refreshReward(_rewardIndex, isClickState)
    if isClickState then
        self.m_cilck = true
    end
    local rewardIndex = _rewardIndex
    self.m_rewardIndex = _rewardIndex
    if rewardIndex == 5 then
        util_spinePlay(self.m_jackpotNodeSpine, "idleframe4", true)
    else
        if rewardIndex == 4 then
            self.m_jackpotNodeSpine:setSkin("MedusaMania_dfdcmini")
        elseif rewardIndex == 3 then
            self.m_jackpotNodeSpine:setSkin("MedusaMania_dfdcminor")
        elseif rewardIndex == 2 then
            self.m_jackpotNodeSpine:setSkin("MedusaMania_dfdcmajor")
        elseif rewardIndex == 1 then
            self.m_jackpotNodeSpine:setSkin("MedusaMania_dfdcgrand")
        end
        util_spinePlay(self.m_jackpotNodeSpine, "dianji", false)
        util_spineEndCallFunc(self.m_jackpotNodeSpine, "dianji", function()
            util_spinePlay(self.m_jackpotNodeSpine, "idleframe5", false)
            self.m_jackpot_machine:refreshTopJackpot(_rewardIndex, self.m_curIndex)
        end)
    end
    self:recoverActionState()
    -- self.m_jackpotNodeSpine:setDebugBonesEnabled(true)
end

--默认按钮监听回调
function MedusaManiaJackpotNode:clickFunc(sender)
    local name = sender:getName()

    if name == "click_panel" and self.m_cilck and self.m_jackpot_machine:isCanTouch() then
        print("当前点击第"..self.m_curIndex.."个奖励")
        self:playEndAni()
    end
end

function MedusaManiaJackpotNode:playEndAni()
    self.m_cilck = false
    local curRewardIndex = self.m_jackpot_machine:getCurRewardIndex()
    gLobalSoundManager:playSound(PublicConfig.Music_Click_Jackpot)
    self:refreshReward(curRewardIndex)
end

function MedusaManiaJackpotNode:playActionFrame()
    util_spinePlay(self.m_jackpotNodeSpine, "actionframe2", false)
end

function MedusaManiaJackpotNode:playDarkIdle(randomType)
    if randomType == 4 then
        self.m_jackpotNodeSpine:setSkin("MedusaMania_dfdcmini")
    elseif randomType == 3 then
        self.m_jackpotNodeSpine:setSkin("MedusaMania_dfdcminor")
    elseif randomType == 2 then
        self.m_jackpotNodeSpine:setSkin("MedusaMania_dfdcmajor")
    elseif randomType == 1 then
        self.m_jackpotNodeSpine:setSkin("MedusaMania_dfdcgrand")
    end
    util_spinePlay(self.m_jackpotNodeSpine, "yaan", false)
    util_spineEndCallFunc(self.m_jackpotNodeSpine, "yaan", function()
        util_spinePlay(self.m_jackpotNodeSpine, "yaan_idle", true)
    end)
end

function MedusaManiaJackpotNode:playOtherDarkIdle()
    util_spinePlay(self.m_jackpotNodeSpine, "yaan2", false)
    util_spineEndCallFunc(self.m_jackpotNodeSpine, "yaan2", function()
        util_spinePlay(self.m_jackpotNodeSpine, "yaan_idle", true)
    end)
end

--随机抖动三个金币
function MedusaManiaJackpotNode:runRandomAction()
    local actionList = {}
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, 5)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, -5)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, 4)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, -4)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, 3)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, -1.5)
    actionList[#actionList + 1] = cc.RotateTo:create(0.1, 0)
    local sequence = cc.Sequence:create(actionList)
    self.m_jackpotNode:runAction(sequence)
    -- util_spinePlay(self.m_jackpotNodeSpine, "idleframe3", true)
end

--恢复初始状态
function MedusaManiaJackpotNode:recoverActionState()
    self.m_jackpotNode:setRotation(0)
    self.m_jackpotNode:stopAllActions()
end

function MedusaManiaJackpotNode:getCurJackpotNodeType()
    return self.m_rewardIndex
end

return MedusaManiaJackpotNode
