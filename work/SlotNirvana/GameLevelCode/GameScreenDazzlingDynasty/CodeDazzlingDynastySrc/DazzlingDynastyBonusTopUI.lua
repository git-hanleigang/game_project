--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:JohnnyFred
    time:2019-08-01 20:56:53
]]
local DazzlingDynastyBonusTopUI = class("DazzlingDynastyBonusTopUI", util_require("base.BaseView"))

function DazzlingDynastyBonusTopUI:initUI()
    self:createCsbNode("DazzlingDynasty_Jackpot_0.csb")
    self:runCsbAction("idle",true)
    self.lbLeftCoin = self:findChild("m_lb_LeftCoins")
    self.lbRightCoin = self:findChild("m_lb_RightCoins")
end

function DazzlingDynastyBonusTopUI:setExtraInfo(machine)
    self.goldMidTopUI = machine.goldMidTopUI
end

function DazzlingDynastyBonusTopUI:setTopScore(leftScore,rightScore,goldScore)
    if leftScore ~= nil then
        self.lbLeftCoin:setString(leftScore)
    end
    if rightScore ~= nil then
        self.lbRightCoin:setString(rightScore)
    end
    if goldScore ~= nil then
        self.goldMidTopUI:setScore(goldScore)
    end
end

function DazzlingDynastyBonusTopUI:addTopScore(leftScore,rightScore,goldScore)
    local lbLeftCoin = self.lbLeftCoin
    local lbRightCoin = self.lbRightCoin
    local goldMidTopUI = self.goldMidTopUI
    if leftScore ~= nil then
        local preLeftScore = tonumber(lbLeftCoin:getString())
        lbLeftCoin:setString(preLeftScore + leftScore)
    end
    if rightScore ~= nil then
        local preRightScoreScale = lbRightCoin:getScale()
        local preRightScore = tonumber(lbRightCoin:getString())
        lbRightCoin:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2,0.9),
            cc.ScaleTo:create(0.1,0,0.9),
            cc.CallFunc:create(function(sender)
                lbRightCoin:setString(preRightScore + rightScore)
            end),cc.ScaleTo:create(0.1,0.9),cc.ScaleTo:create(0.2,preRightScoreScale,preRightScoreScale))
        )
    end
    if goldScore ~= nil then
        local preGoldScore = goldMidTopUI:getScore()
        goldMidTopUI:setAnimScore(preGoldScore,goldScore)
    end
end

return DazzlingDynastyBonusTopUI