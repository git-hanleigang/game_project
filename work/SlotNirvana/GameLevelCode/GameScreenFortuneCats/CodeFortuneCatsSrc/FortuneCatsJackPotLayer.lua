---
--FortuneCatsJackPotLayer.lua
local FortuneCatsJackPotLayer = class("FortuneCatsJackPotLayer", util_require("base.BaseView"))

function FortuneCatsJackPotLayer:initUI(machine)
    self.m_machine = machine
    local resourceFilename = "FortuneCats_jackpot.csb"
    self:createCsbNode(resourceFilename)
    self.m_head = {}
    for i = 1, 5 do
        local head = util_createView("CodeFortuneCatsSrc.FortuneCatsJackpotHead")
        self:findChild("mao_" .. (3 + i)):addChild(head)
        table.insert(self.m_head, head)
    end
    self.m_playNum = 0
    self.m_playChangeMulNum = 6
    self.m_playChangeAddNum = 0
    self.m_bPlayChangeMul = false
    self.m_bPlayChangeStart = false
end

function FortuneCatsJackPotLayer:updateJackpotInfo()
    if not self.m_machine then
        return
    end
    self:changeNode(self:findChild("ml_b_coins1_0"), 1, true)
    self:changeNode(self:findChild("ml_b_coins2_0"), 2, true)
    self:changeNode(self:findChild("ml_b_coins3_0"), 3, true)
    self:changeNode(self:findChild("ml_b_coins4_0"), 4, true)
    self:changeNode(self:findChild("ml_b_coins5_0"), 5, true)
    self:changeNode(self:findChild("ml_b_coins6_0"), 6, true)

    self:updateLabelSize({label = self:findChild("ml_b_coins1_0"), sx = 1, sy = 1}, 464)
    self:updateLabelSize({label = self:findChild("ml_b_coins2_0"), sx = 0.65, sy = 0.65}, 387)
    self:updateLabelSize({label = self:findChild("ml_b_coins3_0"), sx = 0.58, sy = 0.58}, 396)
    self:updateLabelSize({label = self:findChild("ml_b_coins4_0"), sx = 0.58, sy = 0.58}, 342)
    self:updateLabelSize({label = self:findChild("ml_b_coins5_0"), sx = 0.53, sy = 0.53}, 342)
    self:updateLabelSize({label = self:findChild("ml_b_coins6_0"), sx = 0.48, sy = 0.48}, 342)
end

--jackpot算法
function FortuneCatsJackPotLayer:changeNode(label, index, isJump)
    local value = self.m_machine:BaseMania_updateJackpotScore(index)
    if  self.m_bPlayChangeMul  then
        if index >=  self.m_playChangeMulNum  then
            value = self.m_machine.m_jackpotMul * value
        end
    else
        value = self.m_machine.m_jackpotMul * value
    end

    label:setString(util_formatCoins(value, 50))
end

function FortuneCatsJackPotLayer:onEnter()
    schedule(
        self,
        function()
            if  self.m_bPlayChangeMul and  self.m_bPlayChangeStart then
                if self.m_playChangeAddNum > 2 then
                    self.m_playChangeAddNum = 0
                    self.m_playChangeMulNum = self.m_playChangeMulNum  - 1
                end
                self.m_playChangeAddNum = self.m_playChangeAddNum + 1
            end
            self:updateJackpotInfo()
        end,
        0.08
    )
end

function FortuneCatsJackPotLayer:playAddCatEffect(num)
    -- print("FortuneCatsJackPotLayer:slotLocalOneReelDown22 num===" .. num)
    self.m_playNum = num
    if num >= 4 then
        gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_jackpot_change.mp3")
        self:runCsbAction(
            "animationstart" .. num,
            false,
            function()
                if num >= self.m_playNum then
                    self:runCsbAction("animation" .. num, true)
                end
            end
        )
    end
end

function FortuneCatsJackPotLayer:playEndIdle(num)
    for i = 1, 5 do
        self.m_head[i]:runCsbAction("idleframe")
    end
    self:runCsbAction("idle" .. num, false)
end

function FortuneCatsJackPotLayer:playAddCatHeadEffect(num)

    if num >= 4 then
        for i = 1, 5 do
            self.m_head[i]:runCsbAction("idleframe")
        end
        if num >= self.m_playNum then
            if num < 9 then
                self.m_head[num - 3]:runCsbAction("animation", true)
            end
            self:runCsbAction("animation" .. num, true)
        end
    end
end

function FortuneCatsJackPotLayer:playIdle()
    self.m_playNum = 0
    self:runCsbAction("idleframe")
    for i = 1, 5 do
        self.m_head[i]:runCsbAction("idleframe")
    end
end

function FortuneCatsJackPotLayer:playChangeEff(_mul,func)
    local mul = _mul
    local label = self:findChild("fenshu_1")
    label:setString("X" .. util_formatCoins(mul, 3))
    if mul > 1 then
        label:setVisible(true)
    else
        label:setVisible(false)
    end
    self.m_bPlayChangeMul = true
    self.m_playChangeMulNum = 7
    self.m_playChangeAddNum = 0
    gLobalSoundManager:playSound("FortuneCatsSounds/sound_FortuneCats_superfree_jackpot_shine.mp3")
    performWithDelay(self,function(  )
        self.m_bPlayChangeStart = true
    end,2)
    self:runCsbAction(
        "animationframe",
        false,
        function()
            self.m_bPlayChangeMul = false
            self.m_bPlayChangeStart = false
            if func then
                func()
            end
        end
    )
end

return FortuneCatsJackPotLayer
