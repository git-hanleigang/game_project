
local GoldenGhostFreeSpinTopUI = class("GoldenGhostFreeSpinTopUI", util_require("base.BaseView"))

function GoldenGhostFreeSpinTopUI:updateScore()
    local machine = self.machine
    local fsExtraData = machine.m_runSpinResultData.p_fsExtraData
    local totalScore = 0
    if fsExtraData ~= nil then
        totalScore = fsExtraData.bonusMultiples
    else
        local storedIcons = machine.m_runSpinResultData.p_storedIcons -- 存放的是respinBonus的网络数据
        if storedIcons ~= nil then
            for k, v in ipairs(storedIcons) do
                local score = machine:getReSpinSymbolScore(v[1]) or 0 --获取分数（网络数据）
                totalScore = totalScore + score
            end
        end
    end

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local numStr = machine:getCoinsByScore(totalScore)

    self.lbLeftCoin:setString(numStr)
end

function GoldenGhostFreeSpinTopUI:initUI()
    self:createCsbNode("GoldenGhost_Jackpot_1.csb")
    self:runCsbAction("idle",true)
    self.lbLeftCoin = self:findChild("m_lb_leftCoins")
    self.lbLeftCoin:setString("0")
end

function GoldenGhostFreeSpinTopUI:setTopScore(leftScore)
    if leftScore ~= nil then
        self.lbLeftCoin:setString(leftScore)
    end
end

function GoldenGhostFreeSpinTopUI:setExtraInfo(machine)
    self.machine = machine
end


return GoldenGhostFreeSpinTopUI