---
--xcyy
--2018年5月23日
---
--LuxeVegasColorfulItem.lua

local LuxeVegasColorfulItem = class("LuxeVegasColorfulItem",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "LuxeVegasPublicConfig"

LuxeVegasColorfulItem.m_machine = nil
LuxeVegasColorfulItem.m_jackpot_machine = nil
LuxeVegasColorfulItem.m_curIndex = nil
LuxeVegasColorfulItem.m_cilck = nil

function LuxeVegasColorfulItem:initUI(_machine, _jackpot_machine, _index)
    self.m_isClicked = false    --是否已经点击
    self:createCsbNode("LuxeVegas_dfdc_Item.csb")

    self.m_jackpotNode = self:findChild("Node_jackpot")

    self.m_jackpotNodeSpine = util_spineCreate("Socre_LuxeVegas_Bonus",true,true)
    self.m_jackpotNode:addChild(self.m_jackpotNodeSpine)
    
    self.m_machine = _machine
    self.m_jackpot_machine = _jackpot_machine
    self.m_curIndex = _index
    self.m_cilck = true

    self.m_scWaitNode = cc.Node:create()
    self:addChild(self.m_scWaitNode)

    self:addClick(self:findChild("click_panel")) -- 非按钮节点得手动绑定监听
end

function LuxeVegasColorfulItem:onExit()
    LuxeVegasColorfulItem.super.onExit(self)
end

function LuxeVegasColorfulItem:refreshReward(_rewardIndex, isClickState)
    if isClickState then
        self.m_cilck = true
    end
    local rewardIndex = _rewardIndex
    self.m_rewardIndex = _rewardIndex
    if rewardIndex == 6 then
        util_spinePlay(self.m_jackpotNodeSpine, "idleframe4", true)
    else
        local switchName = ""
        if rewardIndex == 5 then
            switchName = "switch_mini"
        elseif rewardIndex == 4 then
            switchName = "switch_minor"
        elseif rewardIndex == 3 then
            switchName = "switch_major"
        elseif rewardIndex == 2 then
            switchName = "switch_mega"
        elseif rewardIndex == 1 then
            switchName = "switch_grand"
        end
        self.m_jackpot_machine:setJackpotNodeState(self.m_curIndex)
        util_spinePlay(self.m_jackpotNodeSpine, switchName, false)
        -- 第10帧切
        performWithDelay(self, function()
            self.m_jackpot_machine:refreshTopJackpot(_rewardIndex, self.m_curIndex)
        end, 10/30)
        -- util_spineEndCallFunc(self.m_jackpotNodeSpine, switchName, function()
        --     self.m_jackpot_machine:refreshTopJackpot(_rewardIndex, self.m_curIndex)
        -- end)
    end
end

--默认按钮监听回调
function LuxeVegasColorfulItem:clickFunc(sender)
    local name = sender:getName()

    if name == "click_panel" and self.m_cilck and self.m_jackpot_machine:isCanTouch() then
        print("当前点击第"..self.m_curIndex.."个奖励")
        self:playEndAni()
    end
end

function LuxeVegasColorfulItem:playEndAni()
    self.m_cilck = false
    gLobalSoundManager:playSound(PublicConfig.Music_Click_Bonus)
    local curRewardIndex = self.m_jackpot_machine:getCurRewardIndex()
    self:refreshReward(curRewardIndex)
end

function LuxeVegasColorfulItem:playActionFrame()
    local actName = {"actionframe_grand", "actionframe_mega", "actionframe_major", "actionframe_minor", "actionframe_mini"}
    if self.m_rewardIndex <= 5 then
        util_spinePlay(self.m_jackpotNodeSpine, actName[self.m_rewardIndex], false)
    end
end

function LuxeVegasColorfulItem:playDarkIdle(randomType)
    local idleName = {"dark_grand", "dark_mega", "dark_major", "dark_minor", "dark_mini"}
    local idleLoopName = {"darkidle_grand", "darkidle_mega", "darkidle_major", "darkidle_minor", "darkidle_mini"}
    if randomType <= 5 then
        util_spinePlay(self.m_jackpotNodeSpine, idleName[randomType], false)
        util_spineEndCallFunc(self.m_jackpotNodeSpine, idleName[randomType], function()
            util_spinePlay(self.m_jackpotNodeSpine, idleLoopName[randomType], true)
        end)
    end
end

function LuxeVegasColorfulItem:playOtherDarkIdle()
    local idleName = {"darkidle_grand", "darkidle_mega", "darkidle_major", "darkidle_minor", "darkidle_mini"}
    if self.m_rewardIndex <= 5 then
        util_spinePlay(self.m_jackpotNodeSpine, idleName[self.m_rewardIndex], true)
    end
end

--随机抖动三个金币
function LuxeVegasColorfulItem:runRandomAction()
    util_spinePlay(self.m_jackpotNodeSpine, "idleframe3", true)
end

--恢复初始状态
function LuxeVegasColorfulItem:recoverActionState()
    util_spinePlay(self.m_jackpotNodeSpine, "idleframe4", true)
end

function LuxeVegasColorfulItem:getCurJackpotNodeType()
    return self.m_rewardIndex
end

return LuxeVegasColorfulItem
