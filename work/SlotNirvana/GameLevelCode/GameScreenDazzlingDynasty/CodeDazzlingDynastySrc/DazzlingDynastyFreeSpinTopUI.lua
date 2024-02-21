--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:JohnnyFred
    time:2019-08-01 20:56:53
]]
local DazzlingDynastyFreeSpinTopUI = class("DazzlingDynastyFreeSpinTopUI", util_require("base.BaseView"))

function DazzlingDynastyFreeSpinTopUI:initUI()
    self:createCsbNode("DazzlingDynasty_Jackpot_1.csb")
    self:runCsbAction("idle",true)
    self.lbLeftCoin = self:findChild("m_lb_LeftCoins")
    self.lbLeftCoin:setString("0")
end

function DazzlingDynastyFreeSpinTopUI:setExtraInfo(machine)
    self.machine = machine
end

function DazzlingDynastyFreeSpinTopUI:updateScore()
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
    self.lbLeftCoin:setString(totalScore)
end

function DazzlingDynastyFreeSpinTopUI:setTopScore(leftScore)
    if leftScore ~= nil then
        self.lbLeftCoin:setString(leftScore)
    end
end
return DazzlingDynastyFreeSpinTopUI