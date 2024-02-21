---
--xcyy
--2018年5月23日
--HallowinJackPotBarView.lua

local HallowinJackPotBarView = class("HallowinJackPotBarView",util_require("base.BaseView"))

local COINS_LAB_SIZE =
{
    {scaleX = 0.95, scaleY = 1.05, width = 424},
    {scaleX = 0.89, scaleY = 0.98, width = 384},
    {scaleX = 0.86, scaleY = 0.95, width = 258},
    {scaleX = 0.86, scaleY = 0.95, width = 236},
    {scaleX = 0.86, scaleY = 0.95, width = 226},
    {scaleX = 0.86, scaleY = 0.95, width = 216},
    {scaleX = 0.86, scaleY = 0.95, width = 206},
    {scaleX = 0.86, scaleY = 0.95, width = 196}
}

function HallowinJackPotBarView:initUI()

    self:createCsbNode("Hallowin_jackpot.csb")

    self:runCsbAction("idle",true)

    local index = 7
    self.m_miltip = 1
    while true do
        local parent = self:findChild("Node_"..index)
        if parent ~= nil then
            local nangua = util_createAnimation("Hallowin_jackpot_nangua.csb")
            parent:addChild(nangua)
            self["nangua_"..index] = nangua
        else
            break
        end
        index = index + 1
    end

    self.m_effectNode = util_createView("CodeHallowinSrc.HallowinJackpotBarEffect")
    self:addChild(self.m_effectNode, 1)
end

function HallowinJackPotBarView:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)
    self.m_updateAction = schedule(self,function()
        self:updateJackpotInfo()
    end,0.08)
end

function HallowinJackPotBarView:onExit()
 
end

function HallowinJackPotBarView:initMachine(machine)
    self.m_machine = machine
end

-- 更新jackpot 数值信息
--
function HallowinJackPotBarView:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    local data=self.m_csbOwner

    for i = 1, 8, 1 do
        self:changeNode(self:findChild("m_lb_coins_"..i), i, true)
    end
    self:updateSize()
end

function HallowinJackPotBarView:updateSize()

    for i = 1, 8, 1 do
        local label = self.m_csbOwner["m_lb_coins_"..i]
        local info = {label = label, sx = COINS_LAB_SIZE[i].scaleX, sy = COINS_LAB_SIZE[i].scaleY}
        self:updateLabelSize(info, COINS_LAB_SIZE[i].width)
    end
end

function HallowinJackPotBarView:setMultip(mul)
    self.m_miltip = mul
end

function HallowinJackPotBarView:changeNode(label,index,isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    local value = math.floor(value * self.m_miltip)
    label:setString(util_formatCoins(value,20,nil,nil,true))
end

function HallowinJackPotBarView:toAction(actionName)

    self:runCsbAction(actionName)
end

function HallowinJackPotBarView:showSelectedAnim(num)
    self.m_jackpotNum = num
    if self.m_jackpotNum > 14 then
        self.m_jackpotNum = 14
    end
    self.m_effectNode:jackpotUpAnim(self.m_jackpotNum, function()
        self:runCsbAction(self.m_jackpotNum)
        self["nangua_"..self.m_jackpotNum]:playAction("actionframe")
    end)
end

function HallowinJackPotBarView:respinStartAnim(num, func)
    local total = 14
    local index = 0
    if num > 14 then
        num = 14
    end
    for i = total, num, -1 do
        performWithDelay(self, function()
            gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_jackpot_down_"..i..".mp3")
            self:runCsbAction(i)
            self["nangua_"..i]:playAction("actionframe")
        end, 0.15 * index)
        index = index + 1
    end
    performWithDelay(self, function()
        if func ~= nil then
            func()
        end
    end, 0.15 * (index + 1))
    self.m_jackpotNum = num
end

function HallowinJackPotBarView:showTriggerAnim(num, func)
    -- gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_jackpot_light.mp3")
    -- self:runCsbAction("actionframe", false, function()
        -- self:respinStartAnim(num, func)
        if num > 14 then
            num = 14
        end
        self.m_jackpotNum = num
        self:toAction(num)
        gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_jackpot_down_"..num..".mp3")
        if func ~= nil then
            performWithDelay(self, function()
                func()
            end, 0.6)
        end
    -- end)
end

function HallowinJackPotBarView:getEndNode(num) 
    if num > 14 then
        num = 14
    end
    local node = self:findChild("kuang_"..num)
    return node
end

function HallowinJackPotBarView:showIdle()
    self:runCsbAction("idle")
end

function HallowinJackPotBarView:getMultipEffectNode()
    return self:findChild("jinyouling_baodian")
end

function HallowinJackPotBarView:mutilpEffect(multip, isFreeSpin)
    self.m_effectNode:updateJackpotNum(isFreeSpin)
    gLobalSoundManager:playSound("HallowinSounds/sound_Hallowin_jackpot_coin_up.mp3")
    if self.m_updateAction ~= nil then
        self:stopAction(self.m_updateAction)
        self.m_updateAction = nil
    end
    self.m_miltip = multip
    for i = 1, 8, 1 do
        local label = self:findChild("m_lb_coins_"..i)
        local value = self.m_machine:BaseMania_updateJackpotScore(i)
        local endValue = math.floor(value * self.m_miltip)
        local addVale = (endValue - value) / 60
        util_jumpNum(label, value, endValue, addVale, 1 / 30, {20}, nil, nil, function ()
            self.m_updateAction = schedule(self,function()
                self:updateJackpotInfo()
            end,0.08)
        end)
    end

end

function HallowinJackPotBarView:getJackpotNum()
    return self.m_jackpotNum
end

return HallowinJackPotBarView