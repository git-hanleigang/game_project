---
--island
--2018年4月12日
--GoldExpressJackPotNode.lua
---- respin 玩法结算时中 mini mijor等提示界面
local GoldExpressJackPotNode = class("GoldExpressJackPotNode", util_require("base.BaseView"))
GoldExpressJackPotNode.m_iJackpotNum = nil
local LEAST_EXPRESS_NUM = 6     -- 选中特效最少火车数目 - 1
GoldExpressJackPotNode.m_iLabWidth = {370, 335, 236, 220, 204, 187, 183, 167, 150}
GoldExpressJackPotNode.m_fLabScale = {1, 1, 1, 1, 1, 1, 1, 1,1}
GoldExpressJackPotNode.m_vecJackpotNum = {15, 14, 13, 12}
GoldExpressJackPotNode.m_iMaxJackpotNum = nil

function GoldExpressJackPotNode:initUI(data)
    self.m_click = false

    local resourceFilename = "GoldExpress_JackPot.csb"
    self:createCsbNode(resourceFilename)
    self:runCsbAction("idle")
    self.m_iJackpotNum = LEAST_EXPRESS_NUM
    self.m_labCoins = {}
    -- self.m_particles = {}
    local index = 15
    while true do
        local lab = self:findChild("m_lb_coin_" .. index )
        local particle = self:findChild("Particle_" .. index )
        if particle ~= nil then
            -- self.m_particles[#self.m_particles + 1] = particle
            particle:stopSystem()
        end
        if lab ~= nil then
            self.m_labCoins[#self.m_labCoins + 1] = lab
        else
            break
        end
        index = index - 1
    end

    index = 1
    self.m_lockNode = {}
    while true do
        local lock = self:findChild("lock_node_" .. index )
        if lock ~= nil then
            self.m_lockNode[#self.m_lockNode + 1] = lock
        else
            break
        end
        index = index + 1
    end

    index = 1
    self.m_unlockNode = {}
    while true do
        local unlock = self:findChild("unlock_node_" .. index )
        if unlock ~= nil then
            self.m_unlockNode[#self.m_unlockNode + 1] = unlock
        else
            break
        end
        index = index + 1
    end
end

function GoldExpressJackPotNode:initLockUI(bets, betLevel)
    -- for i = 1, #self.m_lockNode, 1 do
    --     local lock = util_createView("CodeGoldExpressSrc.GoldExpressJackPotLock",{index = i, value = bets[i].p_totalBetValue})
    --     self.m_lockNode[i]:addChild(lock)
    --     lock:setName("lock")
    --     if i >= betLevel then
    --         self.m_lockNode[i]:setVisible(false)
    --     end
    -- end
    self.m_iMaxJackpotNum = 15--self.m_vecJackpotNum[betLevel]
end

function GoldExpressJackPotNode:initMachine(machine)
    self.m_machine = machine
end

function GoldExpressJackPotNode:onEnter()
    schedule(self, function()
        self:updateJackpotInfo()
    end, 0.08)
end

function GoldExpressJackPotNode:onExit()

end


-- 更新jackpot 数值信息
--
function GoldExpressJackPotNode:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    for i = 1, #self.m_labCoins, 1 do
        local lab = self.m_labCoins[i]
        self:changeNode(lab, i, true)
    end

    self:updateSize()
end

function GoldExpressJackPotNode:updateSize()
    for i = 1, #self.m_labCoins, 1 do
        local info = {label = self.m_labCoins[i], sx = self.m_fLabScale[i], sy = self.m_fLabScale[i]}
        self:updateLabelSize(info, self.m_iLabWidth[i])
    end

end

function GoldExpressJackPotNode:changeNode(label,index,isJump)
    local value=self.m_machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoins(value,20))
end


function GoldExpressJackPotNode:showJackptSelected(num)
    if self.m_iJackpotNum < num then
        if num > self.m_iMaxJackpotNum then
            num = self.m_iMaxJackpotNum
        end
        local increase = num - self.m_iJackpotNum
        self:animationSelected(self.m_iJackpotNum + 1, increase)
        self.m_iJackpotNum = num
    end
end

function GoldExpressJackPotNode:animationSelected(index, flag)
    if index ~= self.m_iJackpotNum and flag > 0 then
        flag = flag - 1
        self:runCsbAction("idle"..index, false, function()
            self:animationSelected(index + 1, flag)
        end)
    else
        self:runCsbAction("idle"..self.m_iJackpotNum, true)
    end
end

function GoldExpressJackPotNode:lockJackptByBetLevel(level)
    -- for i = 1, #self.m_lockNode, 1 do
    --     if i < level then
    --         self.m_lockNode[i]:setVisible(true)
    --     end
    -- end
    self.m_iMaxJackpotNum = 15--self.m_vecJackpotNum[level]
end

function GoldExpressJackPotNode:unlockJackptByBetLevel(level)
    -- for i = #self.m_lockNode, 1, -1 do
    --     if i >= level and self.m_lockNode[i]:isVisible() == true then
    --         self.m_lockNode[i]:setVisible(false)
    --         local effect, act = util_csbCreate("GoldExpress_JackPot_LockEffect.csb")
    --         self.m_unlockNode[i]:addChild(effect)
    --         util_csbPlayForKey(act, "animation0", false, function()
    --             effect:removeFromParent(true)
    --         end)
    --     end
    --     if i < level then
    --         local lock = self.m_lockNode[i]:getChildByName("lock")
    --         if lock ~= nil then
    --             lock:playAnimation("actionframe")
    --         end
    --         break
    --     end
    -- end
    self.m_iMaxJackpotNum = 15--self.m_vecJackpotNum[level]
end

function GoldExpressJackPotNode:showJackpotAnimation()
    gLobalSoundManager:playSound("GoldExpressSounds/sound_glod_express_jackpot_reward.mp3")
    local particle = self:findChild("Particle_" .. self.m_iJackpotNum )
    particle:resetSystem()
    local pos = particle:getParent():convertToWorldSpace(cc.p(particle:getPosition()))
    return pos
end

function GoldExpressJackPotNode:resetDataAndAnimation()
    self.m_iJackpotNum = LEAST_EXPRESS_NUM
    self:runCsbAction("idle")
end
--------------------------- Class Base CCB Functions  END---------------------------

-- 如果本界面需要添加touch 事件，则从BaseView 获取

return GoldExpressJackPotNode