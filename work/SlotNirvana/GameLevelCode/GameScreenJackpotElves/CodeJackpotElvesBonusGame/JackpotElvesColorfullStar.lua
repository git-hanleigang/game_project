---
--xcyy
--2018年5月23日
--JackpotElvesColorfullStar.lua

local JackpotElvesColorfullStar = class("JackpotElvesColorfullStar",util_require("Levels.BaseLevelDialog"))

local JACKPOT_TYPE = {
    "epic",
    "grand",
    "ultra",
    "mega",
    "major",
    "minor",
    "mini"
}

function JackpotElvesColorfullStar:initUI(params)
    
    self:createCsbNode("JackpotElves_jackpot_gift_green_buff.csb")

    local effectNode = util_createAnimation("JackpotElves_jackpot_gift_green_buff_guang.csb")
    self:findChild("Node_guang"):addChild(effectNode)
    effectNode:playAction("idle", true)

    self.m_vecJackptPng = 
    {
        "JackpotElvesUi/JackpotElves_Epic2.png",
        "JackpotElvesUi/JackpotElves_Grand2.png", 
        "JackpotElvesUi/JackpotElves_Ultra2.png", 
        "JackpotElvesUi/JackpotElves_Mega2.png", 
        "JackpotElvesUi/JackpotElves_Major2.png", 
        "JackpotElvesUi/JackpotElves_Minor2.png", 
        "JackpotElvesUi/JackpotElves_Mini2.png"}
end

function JackpotElvesColorfullStar:updateUI(params)
    local result = params
    util_shuffle(self.m_vecJackptPng)
    for index = 1, #JACKPOT_TYPE, 1 do
        local jackpot = JACKPOT_TYPE[index]
        self:findChild(jackpot):setVisible(jackpot == result)

        local changeJackpot = self:findChild("qh_"..jackpot)
        util_changeTexture(changeJackpot, self.m_vecJackptPng[index])
    end
end

function JackpotElvesColorfullStar:showStar(params, func)
    self:updateUI(params)
    self:runCsbAction("start", false, function()
        if func then
            func()
        end
    end)
end

function JackpotElvesColorfullStar:changeJackpotAnim(func)
    self:runCsbAction("idle", false, function()
        self:runCsbAction("idle2", false, function()
            if func then
                func()
            end
            self:rewardAnim()
        end)
    end)
end

function JackpotElvesColorfullStar:rewardAnim()
    self:runCsbAction("actionframe")
end

function JackpotElvesColorfullStar:hideStar(func)
    self:runCsbAction("over", false, function()
        if func then
            func()
        end
    end)
end

return JackpotElvesColorfullStar