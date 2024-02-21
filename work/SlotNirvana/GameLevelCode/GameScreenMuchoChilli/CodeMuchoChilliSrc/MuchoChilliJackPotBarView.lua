---
--xcyy
--2018年5月23日
--MuchoChilliJackPotBarView.lua

local MuchoChilliJackPotBarView = class("MuchoChilliJackPotBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "MuchoChilliPublicConfig"

local jackpotName = {"MuchoChilli_jackpot_grand", "MuchoChilli_jackpot_mega", "MuchoChilli_jackpot_major", "MuchoChilli_jackpot_minor", "MuchoChilli_jackpot_mini"}
local jackpotNodeName = {"Node_Grand", "Node_Mega", "Node_Major", "Node_Minor", "Node_Mini"}
local jackpotNodeRespinName = {"Grand", "Other"}
MuchoChilliJackPotBarView.m_jackpotNode = {}
MuchoChilliJackPotBarView.m_jackpotNodeRespin = {}
MuchoChilliJackPotBarView.m_playOtherIndex = 1

function MuchoChilliJackPotBarView:initUI()

    self:createCsbNode("JackPotBarMuchoChilli.csb")

    for _index, _jackpotName in ipairs(jackpotName) do
        self.m_jackpotNode[_index] = util_createAnimation(_jackpotName .. ".csb")
        self:findChild(jackpotNodeName[_index]):addChild(self.m_jackpotNode[_index])
        self.m_jackpotNode[_index]:runCsbAction("idle",true)
        self.m_jackpotNode[_index]:findChild("Node_respin"):setVisible(false)
        if _index == 1 then
            self:addClick(self.m_jackpotNode[_index]:findChild("click_layout1"))
            self.m_jackpotNode[_index]:findChild("base_Particle_1"):setVisible(false)
            self.m_jackpotNode[_index]:findChild("base_Particle_2"):setVisible(false)
            self.m_jackpotNode[_index]:findChild("Node_lock1"):setVisible(false)
        end
    end
    
    for _index, _jackpotName in ipairs(jackpotName) do
        self.m_jackpotNodeRespin[_index] = util_createAnimation(_jackpotName .. ".csb")
        if _index == 1 then
            self:findChild(jackpotNodeRespinName[1]):addChild(self.m_jackpotNodeRespin[_index])
            self.m_jackpotNodeRespin[_index]:findChild("Particle_1"):setVisible(false)
            self.m_jackpotNodeRespin[_index]:findChild("Particle_2"):setVisible(false)
            self.m_jackpotNodeRespin[_index]:findChild("Node_lock1"):setVisible(false)
        else
            self:findChild(jackpotNodeRespinName[2]):addChild(self.m_jackpotNodeRespin[_index])
        end
        self.m_jackpotNodeRespin[_index]:runCsbAction("idle",true)
        self.m_jackpotNodeRespin[_index]:findChild("Node_base"):setVisible(false)
    end

    -- 延时节点
    self.m_effectNode = cc.Node:create()
    self:findChild("Node"):addChild(self.m_effectNode)
end

function MuchoChilliJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

function MuchoChilliJackPotBarView:onEnter()

    MuchoChilliJackPotBarView.super.onEnter(self)

    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function MuchoChilliJackPotBarView:onExit()
    MuchoChilliJackPotBarView.super.onExit(self)
end

--默认按钮监听回调
function MuchoChilliJackPotBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "click_layout1" then 
        gLobalNoticManager:postNotification("SHOW_UNLOCK_JACKPOT")
    end
end

-- 更新jackpot 数值信息
--
function MuchoChilliJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self.m_jackpotNode[1]:findChild("m_lb_coins1"),1,true)
    self:changeNode(self.m_jackpotNode[2]:findChild("m_lb_coins1"),2,true)
    self:changeNode(self.m_jackpotNode[3]:findChild("m_lb_coins1"),3)
    self:changeNode(self.m_jackpotNode[4]:findChild("m_lb_coins1"),4)
    self:changeNode(self.m_jackpotNode[5]:findChild("m_lb_coins1"),5)

    self:changeNode(self.m_jackpotNodeRespin[1]:findChild("m_lb_coins2"),1,true)
    self:changeNode(self.m_jackpotNodeRespin[2]:findChild("m_lb_coins2"),2,true)
    self:changeNode(self.m_jackpotNodeRespin[3]:findChild("m_lb_coins2"),3)
    self:changeNode(self.m_jackpotNodeRespin[4]:findChild("m_lb_coins2"),4)
    self:changeNode(self.m_jackpotNodeRespin[5]:findChild("m_lb_coins2"),5)

    self:updateSize()
end

function MuchoChilliJackPotBarView:updateSize()

    local label1 = self.m_jackpotNode[1]:findChild("m_lb_coins1")
    local info1 = {label=label1, sx=1, sy=1}
    local label2 = self.m_jackpotNode[2]:findChild("m_lb_coins1")
    local info2 = {label=label2, sx=0.9, sy=0.9}
    local label3 = self.m_jackpotNode[3]:findChild("m_lb_coins1")
    local info3 = {label=label3, sx=0.9, sy=0.9}
    local label4 = self.m_jackpotNode[4]:findChild("m_lb_coins1")
    local info4 = {label=label4, sx=0.8, sy=0.8}
    local label5 = self.m_jackpotNode[5]:findChild("m_lb_coins1")
    local info5 = {label=label5, sx=0.8, sy=0.8}
    self:updateLabelSize(info1, 338)
    self:updateLabelSize(info2, 288)
    self:updateLabelSize(info3, 288)
    self:updateLabelSize(info4, 288)
    self:updateLabelSize(info5, 288)

    local label1 = self.m_jackpotNodeRespin[1]:findChild("m_lb_coins2")
    local info1 = {label=label1, sx=1, sy=1}
    local label2 = self.m_jackpotNodeRespin[2]:findChild("m_lb_coins2")
    local info2 = {label=label2, sx=1, sy=1}
    local label3 = self.m_jackpotNodeRespin[3]:findChild("m_lb_coins2")
    local info3 = {label=label3, sx=1, sy=1}
    local label4 = self.m_jackpotNodeRespin[4]:findChild("m_lb_coins2")
    local info4 = {label=label4, sx=1, sy=1}
    local label5 = self.m_jackpotNodeRespin[5]:findChild("m_lb_coins2")
    local info5 = {label=label5, sx=1, sy=1}
    self:updateLabelSize(info1, 338)
    self:updateLabelSize(info2, 252)
    self:updateLabelSize(info3, 252)
    self:updateLabelSize(info4, 252)
    self:updateLabelSize(info5, 252)
end

function MuchoChilliJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,30,nil,nil,true))
end

function MuchoChilliJackPotBarView:playTriggerEffect(_nJackpotType)
    if self:findChild("Node_1"):isVisible() then
        self.m_jackpotNode[_nJackpotType]:runCsbAction("actionframe", false, function()
            self.m_jackpotNode[_nJackpotType]:runCsbAction("idle",true)
        end)
    end

    if self:findChild("Node_2"):isVisible() then
        if _nJackpotType > 1 then
            self:resetPlayOtherJackpot(_nJackpotType)
        end

        self.m_jackpotNodeRespin[_nJackpotType]:runCsbAction("actionframe", false, function()
            self.m_jackpotNodeRespin[_nJackpotType]:runCsbAction("idle",true)
        end)
    end
end

--[[
    显示不同的jackpot
]]
function MuchoChilliJackPotBarView:showRespinOrBaseJackpot(_isShowRespin)
    self:findChild("Node_1"):setVisible(_isShowRespin == false)
    self:findChild("Node_2"):setVisible(_isShowRespin == true)
    if _isShowRespin then
        self.m_playOtherIndex = 1
        self:playOtherJackpot()
    end
end

--[[
    锁定grand
]]
function MuchoChilliJackPotBarView:lockGrand()
    if not self.m_isUnLockClicking and self.m_jackpotNode[1]:findChild("Node_lock1"):isVisible() then
        return
    end

    -- 防止快速切换bet 显示出错
    if self.m_isLockClicking then
        return
    end

    self.m_isLockClicking = true

    if self.m_jackpotNode[1] and self.m_jackpotNode[1].m_csbAct then
        util_resetCsbAction(self.m_jackpotNode[1].m_csbAct)
        self.m_isUnLockClicking = false
    end

    self.m_jackpotNode[1]:findChild("Node_lock1"):setVisible(true)
    self.m_jackpotNodeRespin[1]:findChild("Node_lock2"):setVisible(true)
    self.m_jackpotNode[1]:runCsbAction("lock", false, function()
        self.m_jackpotNode[1]:runCsbAction("dark_idle", false)
        self.m_isLockClicking = false
    end)
    self.m_jackpotNodeRespin[1]:runCsbAction("lock", false)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_bet_lock)
end

--[[
    解锁grand
]]
function MuchoChilliJackPotBarView:unLockGrand(_isFirstComeIn)
    if _isFirstComeIn then
        self.m_jackpotNode[1]:runCsbAction("idle", false)
        self.m_jackpotNode[1]:runCsbAction("idle", false)
        self.m_jackpotNode[1]:findChild("Node_lock1"):setVisible(false)
        self.m_jackpotNodeRespin[1]:findChild("Node_lock2"):setVisible(false)
        return
    end

    if not self.m_isLockClicking and not self.m_jackpotNode[1]:findChild("Node_lock1"):isVisible() then
        return
    end

    -- 防止快速切换bet 显示出错
    if self.m_isUnLockClicking then
        return
    end

    self.m_isUnLockClicking = true

    for _index = 1, 2 do
        self.m_jackpotNode[1]:findChild("base_Particle_".._index):setVisible(true)
        self.m_jackpotNode[1]:findChild("base_Particle_".._index):resetSystem()
    end

    if self.m_jackpotNode[1] and self.m_jackpotNode[1].m_csbAct then
        util_resetCsbAction(self.m_jackpotNode[1].m_csbAct)
        self.m_isLockClicking = false
    end

    self.m_jackpotNode[1]:runCsbAction("unlock", false, function()
        self.m_jackpotNode[1]:runCsbAction("idle", false)
        self.m_jackpotNode[1]:findChild("Node_lock1"):setVisible(false)
        self.m_jackpotNodeRespin[1]:findChild("Node_lock2"):setVisible(false)
        self.m_isUnLockClicking = false
    end)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_MuchoChilli_bet_unlock)
end

--[[
    轮播显示除grand之外 其他四个
]]
function MuchoChilliJackPotBarView:playOtherJackpot()
    if not self:findChild("Node_2"):isVisible() then
        return
    end
    for _index = 2, 5 do
        self.m_jackpotNodeRespin[_index]:setVisible(false)
    end
    self.m_playOtherIndex = self.m_playOtherIndex + 1
    local curJackpotNode = self.m_jackpotNodeRespin[self.m_playOtherIndex]
    curJackpotNode:setVisible(true)
    util_nodeFadeIn(curJackpotNode, 0.3, 180, 255, nil, nil)

    local lastJackpotNode
    if self.m_playOtherIndex ~= 2 then
        lastJackpotNode = self.m_jackpotNodeRespin[self.m_playOtherIndex-1]
    else
        lastJackpotNode = self.m_jackpotNodeRespin[5]
    end
    lastJackpotNode:setVisible(true)
    util_nodeFadeIn(lastJackpotNode, 0.3, 255, 180, nil, function()
        lastJackpotNode:setVisible(false)
    end)

    performWithDelay(
        self.m_effectNode,
        function()
            if self.m_playOtherIndex >= 5 then
                self.m_playOtherIndex = 1
            end
            self:playOtherJackpot()
        end,
        5
    )
end

--[[
    重置轮播
]]
function MuchoChilliJackPotBarView:resetPlayOtherJackpot(_playOtherIndex)
    self.m_playOtherIndex = _playOtherIndex - 1
    self.m_effectNode:stopAllActions()
    self:playOtherJackpot()
end

return MuchoChilliJackPotBarView