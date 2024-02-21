---
--xcyy
--2018年5月23日
--JackpotElvesColorfullUpgrade.lua

local JackpotElvesColorfullUpgrade = class("JackpotElvesColorfullUpgrade",util_require("Levels.BaseLevelDialog"))

local JACKPOT_TYPE = {
    "epic",
    "grand",
    "ultra",
    "mega",
    "major",
    "minor",
    "mini"
}

function JackpotElvesColorfullUpgrade:initUI()
    
    self:createCsbNode("JackpotElves_jackpot_jiesuan.csb")

    local effectNode = util_createAnimation("JackpotElves_jackpot_gift_green_buff_guang.csb")
    self:findChild("ef_guang"):addChild(effectNode)
    effectNode:playAction("idle", true)

end

function JackpotElvesColorfullUpgrade:initJackpotUI(params)
    local result = params
    for index = 1, #JACKPOT_TYPE, 1 do
        local jackpot = JACKPOT_TYPE[index]
        self:findChild(jackpot):setVisible(jackpot == result)
        self:findChild("bg_"..jackpot):setVisible(jackpot == result)
        if jackpot == result then
            self.m_index = index
        end
    end
end

function JackpotElvesColorfullUpgrade:showUpgradeNode(params, func)
    self:initJackpotUI(params)
    self:runCsbAction("shengji", false, function()
        if func then
            func()
        end
    end)
end

function JackpotElvesColorfullUpgrade:updateJackpotUI(func)
    self:runCsbAction("shengji2", false, function()
        if func then
            func()
        end
    end)
    performWithDelay(self, function ()
        if self.m_index == 1 then
            return
        end
        self:findChild(JACKPOT_TYPE[self.m_index]):setVisible(false)
        self:findChild(JACKPOT_TYPE[self.m_index - 1]):setVisible(true)
        self:findChild("bg_"..JACKPOT_TYPE[self.m_index]):setVisible(false)
        self:findChild("bg_"..JACKPOT_TYPE[self.m_index - 1]):setVisible(true)
    end, 0.2)
end

return JackpotElvesColorfullUpgrade