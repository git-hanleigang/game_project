---
--xcyy
--2018年5月23日
--JackpotElvesJackPotBarView.lua

local JackpotElvesJackPotBarView = class("JackpotElvesJackPotBarView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "JackpotElvesPublicConfig"
local EpicName = "m_lb_coins_epic"
local GrandName = "m_lb_coins_grand"
local UltraName = "m_lb_coins_ultra"
local MegaName = "m_lb_coins_mega"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini" 

local jackpotAim = {
    "epic",
    "grand",
    "ultra",
    "mega",
    "major",
    "minor",
    "mini",
}

function JackpotElvesJackPotBarView:initUI(params)
    self:initMachine(params.machine)
    self:createCsbNode("JackpotElves_jackpot_base.csb")
    self:runCsbAction("idle", true)

    self.m_nodeEpicLock = util_createAnimation("JackpotElves_jackpotsuo_epic.csb")
    self:findChild("Node_epic_suo"):addChild(self.m_nodeEpicLock)
    self.m_nodeEpicLock:setVisible(false)
    self.m_darkEpicLab = self:findChild("Node_lock_epic")
    self.m_darkEpicLab:setVisible(false)
    
    self.m_nodeGrandLock = util_createAnimation("JackpotElves_jackpotsuo_grand.csb")
    self:findChild("Node_grand_suo"):addChild(self.m_nodeGrandLock)
    self.m_nodeGrandLock:setVisible(false)
    self.m_darkGrandLab = self:findChild("Node_lock_grand")
    self.m_darkGrandLab:setVisible(false)

    self.lockGrandNode = cc.Node:create()
    self:addChild(self.lockGrandNode)
    self.lockEpicNode = cc.Node:create()
    self:addChild(self.lockEpicNode)

    self:addClick(self:findChild("unLock_epic"))
    self:addClick(self:findChild("unLock_grand"))
    self.isClick = true
    self.curBetLevel = 0
    
    
end

function JackpotElvesJackPotBarView:initLockUI(betLevel)
    if betLevel == 1 then
        self.m_nodeEpicLock:setVisible(true)
        self.m_nodeEpicLock:playAction("suoding")
        self.m_darkEpicLab:setVisible(true)
    elseif betLevel == 0 then
        self.m_nodeEpicLock:setVisible(true)
        self.m_nodeEpicLock:playAction("suoding")
        self.m_darkEpicLab:setVisible(true)

        self.m_nodeGrandLock:setVisible(true)
        self.m_nodeGrandLock:playAction("suoding")
        self.m_darkGrandLab:setVisible(true)
    end
    self.curBetLevel = betLevel
end

function JackpotElvesJackPotBarView:unlockAnim(betLevel, distance)
    self.lockEpicNode:stopAllActions()
    self.lockGrandNode:stopAllActions()
    if betLevel == 2 then
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_betUnLock)
        if distance == 2 then
            self.m_nodeEpicLock:playAction("jiesuo", false)
            
            performWithDelay(self.lockEpicNode,function ()
                self.m_nodeEpicLock:setVisible(false)
            end,62/60)
            self.m_nodeGrandLock:playAction("jiesuo", false)
            performWithDelay(self.lockGrandNode,function ()
                self.m_nodeGrandLock:setVisible(false)
            end,62/60)
            performWithDelay(self, function()
                self.m_darkEpicLab:setVisible(false)
                self.m_darkGrandLab:setVisible(false)
            end, 0.25)
        else
            self.m_nodeEpicLock:playAction("jiesuo", false)
            performWithDelay(self.lockEpicNode,function ()
                self.m_nodeEpicLock:setVisible(false)
            end,62/60)
            performWithDelay(self, function()
                self.m_darkEpicLab:setVisible(false)
            end, 0.25)
        end
    elseif betLevel == 1 then
        if distance == -1 then
            self.m_nodeEpicLock:setVisible(true)
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_betLock)
            self.m_nodeEpicLock:playAction("suoding")
            performWithDelay(self, function()
                self.m_darkEpicLab:setVisible(true)
            end, 0.25)
        else
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_betUnLock)
            self.m_nodeGrandLock:playAction("jiesuo")
            performWithDelay(self.lockGrandNode,function ()
                self.m_nodeGrandLock:setVisible(false)
            end,62/60)
            performWithDelay(self, function()
                self.m_darkGrandLab:setVisible(false)
            end, 0.25)
        end
    else
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_betLock)
        if distance == -2 then
            
            self.m_nodeEpicLock:setVisible(true)
            self.m_nodeEpicLock:playAction("suoding")
            self.m_nodeGrandLock:setVisible(true)
            self.m_nodeGrandLock:playAction("suoding")
            performWithDelay(self, function()
                self.m_darkEpicLab:setVisible(true)
                self.m_darkGrandLab:setVisible(true)
            end, 0.25)
        else
            self.m_nodeGrandLock:setVisible(true)
            self.m_nodeGrandLock:playAction("suoding")
            performWithDelay(self, function()
                self.m_darkGrandLab:setVisible(true)
            end, 0.25)
        end
    end
    self.curBetLevel = betLevel
end

function JackpotElvesJackPotBarView:onEnter()
    JackpotElvesJackPotBarView.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self,true)
    schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function JackpotElvesJackPotBarView:onExit()
    JackpotElvesJackPotBarView.super.onExit(self)
end

function JackpotElvesJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function JackpotElvesJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    self:changeNode(self:findChild(EpicName),1,true)
    self:changeNode(self:findChild(GrandName),2,true)
    self:changeNode(self:findChild(UltraName),3,true)
    self:changeNode(self:findChild(MegaName),4,true)
    self:changeNode(self:findChild(MajorName),5,true)
    self:changeNode(self:findChild(MinorName),6,true)
    self:changeNode(self:findChild(MiniName),7,true)

    self:updateSize()
end

function JackpotElvesJackPotBarView:updateSize()

    local label1=self.m_csbOwner[EpicName]
    local info1={label=label1,sx=1,sy=1}
    self:updateLabelSize(info1,351)

    local label2=self.m_csbOwner[GrandName]
    local info2={label=label2,sx=0.93,sy=0.93}
    self:updateLabelSize(info2,351)

    local label3=self.m_csbOwner[UltraName]
    local info3={label=label3,sx=0.93,sy=0.93}
    self:updateLabelSize(info3,351)

    local label4=self.m_csbOwner[MegaName]
    local info4={label=label4,sx=0.84,sy=0.84}
    self:updateLabelSize(info4,351)

    local label5=self.m_csbOwner[MajorName]
    local info5={label=label5,sx=0.84,sy=0.84}
    self:updateLabelSize(info5,351)

    local label6=self.m_csbOwner[MinorName]
    local info6={label=label6,sx=0.75,sy=0.75}
    self:updateLabelSize(info6,351)

    local label7=self.m_csbOwner[MiniName]
    local info7={label=label7,sx=0.75,sy=0.75}
    self:updateLabelSize(info7,351)

    --压暗字体
    local label1_1 = self.m_csbOwner["m_lb_coins_epic_0"]
    local info1_1 = {label = label1_1, sx = 1, sy = 1}
    self:updateLabelSize(info1_1, 351)

    local label2_1 = self.m_csbOwner["m_lb_coins_grand_0"]
    local info2_1 = {label = label2_1, sx = 0.93, sy = 0.93}
    self:updateLabelSize(info2_1, 351)
end

function JackpotElvesJackPotBarView:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20,nil,nil,true))
    if index == 1 then
        self:findChild("m_lb_coins_epic_0"):setString(util_formatCoins(value,20,nil,nil,true))
    elseif index == 2 then
        self:findChild("m_lb_coins_grand_0"):setString(util_formatCoins(value,20,nil,nil,true))
    end
end

--默认按钮监听回调
function JackpotElvesJackPotBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if self.isClick == false then
        return
    end
    if self.curBetLevel == 2 or self.m_machine:getCurrSpinMode() == AUTO_SPIN_MODE then
        return
    end
    if name == "unLock_epic" then
        if self.curBetLevel == 0 then
            self:unlockAnim(2,2)
            
        elseif self.curBetLevel == 1 then
            self:unlockAnim(2,1)
        end
        self:changeBetVal(1)
    elseif name == "unLock_grand" then
        if self.curBetLevel == 1 then
            return
        elseif self.curBetLevel == 0 then
            self:unlockAnim(1,1)
            self:changeBetVal(2)
        end
    end
end

function JackpotElvesJackPotBarView:changeBetVal(clickBetNum)
    local unLockBet  = self.m_machine.m_grandLockBet
    if clickBetNum == 1 then
        unLockBet  = self.m_machine.m_grandLockBet
    else
        unLockBet  = self.m_machine.m_epicLockBet
    end
    local betId = globalData.slotRunData:changeMoreThanBet(unLockBet)
    globalData.slotRunData.iLastBetIdx =   betId
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
end

function JackpotElvesJackPotBarView:isShowClickJackpot(isShow)
    self:findChild("unLock_epic"):setVisible(isShow)
    self:findChild("unLock_grand"):setVisible(isShow)
end

function JackpotElvesJackPotBarView:isClickShow(isclick)
    self.isClick = isclick
end

function JackpotElvesJackPotBarView:hideJackpotAim(jackpotList)
    if jackpotList == nil then
        return
    end
    -- local typeList = {}
    for i,v in ipairs(jackpotAim) do
        self:findChild(v):setVisible(false)
    end
    for i,v in ipairs(jackpotList) do
        -- typeList[#typeList + 1] = jackpotList[i][1]
        self:findChild(jackpotList[i][1]):setVisible(true)
    end
    self:showJackpotAim()
end

function JackpotElvesJackPotBarView:showJackpotAim()
    self:runCsbAction("actionframe",true)
end

function JackpotElvesJackPotBarView:showJackpotIdleAim()
    self:runCsbAction("idle",true)
end

return JackpotElvesJackPotBarView