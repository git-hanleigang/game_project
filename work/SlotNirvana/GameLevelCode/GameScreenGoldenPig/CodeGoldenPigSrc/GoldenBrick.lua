---
--island
--2018年6月5日
--GoldenBrick.lua
-- 鱼飞行动画

local GoldenBrick = class("GoldenBrick", util_require("Levels.SlotsNode"))

GoldenBrick.GLODEN_BRICK_NORMAL = 120
GoldenBrick.GLODEN_BRICK_MINI = 121
GoldenBrick.GLODEN_BRICK_MINOR = 122
GoldenBrick.GLODEN_BRICK_MAJOR = 123
GoldenBrick.GLODEN_BRICK_GRAND = 124

function GoldenBrick:initUI(data)

    local mutil = data.num / globalData.slotRunData:getCurTotalBet()
    local csbName = "Socre_GoldenPig_shuzi"
    local type = self.GLODEN_BRICK_NORMAL
    if mutil == 20 then
        csbName = "Socre_GoldenPig_mini"
        type = self.GLODEN_BRICK_MINI
    elseif mutil == 100 then
        csbName = "Socre_GoldenPig_minor"
        type = self.GLODEN_BRICK_MINOR
    elseif mutil == 1000 then
        csbName = "Socre_GoldenPig_major"
        type = self.GLODEN_BRICK_MAJOR
    elseif mutil == 2000 then
        csbName = "Socre_GoldenPig_grand"
        type = self.GLODEN_BRICK_GRAND
    end
    
    self:initSlotNodeByCCBName(csbName, type)
    local node = self:getCCBNode()

    if node.m_csbNode:getChildByName("m_lab_coin") ~= nil then
        node.m_csbNode:getChildByName("m_lab_coin"):setString(util_formatCoins(data.num, 3))
        local labCoin = node.m_csbNode:getChildByName("m_lab_coin")
        if data.shape == "1x1" or data.shape == "1x2" or data.shape == "1x3" then
            labCoin:setScale(0.45)
        elseif data.shape == "2x2" or data.shape == "2x3" then
            labCoin:setScale(0.95)
        elseif data.shape == "3x2" or data.shape == "3x3" then
            labCoin:setScale(1.28)
        elseif data.shape == "4x2" or data.shape == "5x2" then
            labCoin:setScale(1.41)
        elseif data.shape == "4x3" or data.shape == "5x3" then
            labCoin:setScale(1.75)
        end
    end
    

    if node.m_csbNode:getChildByName("Words") ~= nil then
        local labWords = node.m_csbNode:getChildByName("Words")
        if data.shape == "1x1" or data.shape == "1x2" or data.shape == "1x3" then
                labWords:setScale(0.35)
        elseif data.shape == "2x2" or data.shape == "2x3" then
                labWords:setScale(0.7)
        elseif data.shape == "3x2" or data.shape == "3x3" then
                labWords:setScale(0.99)
        elseif data.shape == "4x2" or data.shape == "5x2" then
                labWords:setScale(1.12)
        elseif data.shape == "4x3" or data.shape == "5x3" then
                labWords:setScale(1.26)
        end
    end

    local bg = node.m_csbNode:getChildByName("BG")
    bg:setScaleX(data.width / bg:getContentSize().width)
    bg:setScaleY(data.height / bg:getContentSize().height)
    self.p_slotNodeH = data.height

end

return GoldenBrick