---
--xcyy
--2018年5月23日
--JackpotElvesTwoJackpotView.lua
local PublicConfig = require "JackpotElvesPublicConfig"
local JackpotElvesTwoJackpotView = class("JackpotElvesTwoJackpotView",util_require("Levels.BaseLevelDialog"))

local JACKPOT_TYPE = {
    "epic",
    "grand",
    "ultra",
    "mega",
    "major",
    "minor",
    "mini"
}
local show_Zi1 = {
    "JackpotElves_Epic2_24",
    "JackpotElves_Grand2_25",
    "JackpotElves_Ultra2_29",
    "JackpotElves_Mega2_27",
    "JackpotElves_Major2_26",
    "JackpotElves_Minor_28_0",
    "JackpotElves_Mini2_28",
}
local show_Zi2 = {
    "JackpotElves_Epic2",
    "JackpotElves_Grand2",
    "JackpotElves_Ultra2",
    "JackpotElves_Mega2",
    "JackpotElves_Major2",
    "JackpotElves_Minor_0",
    "JackpotElves_Mini2",
}
local show_kuang1 = {
    "EpicDi",
    "di_grand",
    "UltraDi",
    "MegaDi",
    "MajorDi",
    "MinorDi",
    "MiniDi",
}
local show_kuang2 = {
    "EpicDi1",
    "di_grand1",
    "UltraDi1",
    "MegaDi1",
    "MajorDi1",
    "MinorDi1",
    "MiniDi1",
}
function JackpotElvesTwoJackpotView:initUI(params)

    self:createCsbNode("JackpotElves/WheelOver1.csb")
    local jackpotList = params.jackpotList
    self.m_endFunc = params.func
    self.isClick = false
    self:updateShowUi(jackpotList)
    self:findChild("Button"):setEnabled(true)
end

function JackpotElvesTwoJackpotView:updateShowUi(jackpotList)
    local oneJackpotType = jackpotList[1][1]
    local oneJackpotCoins = jackpotList[1][2]
    local twoJackpotCoins = jackpotList[2][2]
    local twoJackpotType = jackpotList[2][1]
    self:showJackpotUi(1,oneJackpotType)
    self:showJackpotUi(2,twoJackpotType)
    self:updateCoins(oneJackpotCoins,twoJackpotCoins)
    self:runCsbAction("start",false,function()
        self.isClick = true
        self:runCsbAction("idle",true)
    end)
end

function JackpotElvesTwoJackpotView:getJackpotIndex(JackpotType)
    for i,v in ipairs(JACKPOT_TYPE) do
        if v == JackpotType then
            return i
        end
    end
end

function JackpotElvesTwoJackpotView:showJackpotUi(showIndex,JackpotType)
    local jackpotIndex = self:getJackpotIndex(JackpotType)
    local showJackpotZi = show_Zi1
    local showJackpotKuang = show_kuang1
    if showIndex == 2 then
        showJackpotZi = show_Zi2
        showJackpotKuang = show_kuang2
    end
    for i,v in ipairs(showJackpotZi) do
        if i == jackpotIndex then
            self:findChild(v):setVisible(true)
        else
            self:findChild(v):setVisible(false)
        end
    end
    for i,v in ipairs(showJackpotKuang) do
        if i == jackpotIndex then
            self:findChild(v):setVisible(true)
        else
            self:findChild(v):setVisible(false)
        end
    end
end

function JackpotElvesTwoJackpotView:updateCoins(oneJackpotCoins,twoJackpotCoins)
    local coins = oneJackpotCoins + twoJackpotCoins
    local label1 = self:findChild("m_lb_coins")
    local label2 = self:findChild("m_lb_coins1")
    local label3 = self:findChild("m_lb_coins2")
    label1:setString(util_formatCoins(oneJackpotCoins,50))
    local info={label = label1,sx = 0.59,sy = 0.59}
    self:updateLabelSize(info,658)
    label2:setString(util_formatCoins(twoJackpotCoins,50))
    local info={label = label2,sx = 0.59,sy = 0.59}
    self:updateLabelSize(info,658)
    label3:setString(util_formatCoins(coins,50))
    local info={label = label3,sx = 0.59,sy = 0.59}
    self:updateLabelSize(info,658)
end

function JackpotElvesTwoJackpotView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.isClick == false then
        return
    end
    self:findChild("Button"):setEnabled(false)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_JackpotElves_click)
    if name == "Button" then
        self:runCsbAction("over",false,function ()
            if type(self.m_endFunc) == "function" then
                self.m_endFunc()
            end
            self:removeFromParent()
        end)
    end
end

return JackpotElvesTwoJackpotView