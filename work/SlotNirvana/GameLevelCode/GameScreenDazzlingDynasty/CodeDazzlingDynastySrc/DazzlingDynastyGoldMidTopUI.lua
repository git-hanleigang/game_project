--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-08-06 11:04:43
]]
local DazzlingDynastyGoldMidTopUI = class("DazzlingDynastyGoldMidTopUI", util_require("base.BaseView"))
local CodeGameScreenDazzlingDynastyMachine = util_require("GameScreenDazzlingDynasty.CodeGameScreenDazzlingDynastyMachine")

function DazzlingDynastyGoldMidTopUI:initUI()
    self:createCsbNode("DazzlingDynasty_coins.csb")
    self:runCsbAction("idle",true)
    local lbScore = self:findChild("m_lb_score")
    self.lbScore = lbScore
    lbScore:setVisible(false)
    local effectLabelParent = self:findChild("effectLabel")
    local effectLabel,effectLabelAct = util_csbCreate("DazzlingDynasty_coins_0.csb",true)
    self.effectLabel,self.effectLabelAct = effectLabel,effectLabelAct
    effectLabelParent:addChild(effectLabel)
    util_csbPauseForIndex(effectLabelAct,0)
    local function getScoreLabel(node)
        local name = node:getName()
        if name == "m_lb_score" then
            return node
        else
            for k,v in ipairs(node:getChildren()) do
                local n = getScoreLabel(v)
                if n ~= nil then
                    return n
                end
            end
        end
    end
    local lbEffectScore = getScoreLabel(effectLabel)
    self.lbEffectScore = lbEffectScore
    lbEffectScore:setString("0")
    effectLabel:setVisible(false)
    self.score = 0
end

function DazzlingDynastyGoldMidTopUI:setScore(score,playAnimFlag)
    local effectLabel = self.effectLabel
    local effectLabelAct = self.effectLabelAct
    local lbEffectScore = self.lbEffectScore
    local lbScore = self.lbScore
    self.score = score
    local strScore = util_formatCoins(score,4,true)
    lbScore:setString(strScore)
    if playAnimFlag then
        effectLabel:setVisible(score > 0)
        lbScore:setVisible(false)
        lbEffectScore:setString(strScore)
        util_csbPlayForKey(effectLabelAct,"shouji",false,
        function()
            effectLabel:setVisible(false)
            lbScore:setVisible(score > 0)
        end,20)
    else
        lbScore:setVisible(score > 0)
    end
end

function DazzlingDynastyGoldMidTopUI:setAnimScore(preScore,score)
    self.score = preScore + score
    local lbScore = self.lbScore
    local preScoreScale = lbScore:getScale()
    lbScore:runAction(cc.Sequence:create(cc.ScaleTo:create(0.2,1.3),
        cc.ScaleTo:create(0.1,0,1.3),
        cc.CallFunc:create(function(sender)
            local strScore = util_formatCoins(preScore + score,4,true)
            lbScore:setString(strScore)
        end),cc.ScaleTo:create(0.1,1.3),cc.ScaleTo:create(0.2,preScoreScale))
    )
    gLobalSoundManager:playSound("DazzlingDynastySounds/music_DazzlingDynasty_TopScoreChange.mp3")
end

function DazzlingDynastyGoldMidTopUI:getScore()
    return self.score
end

return DazzlingDynastyGoldMidTopUI