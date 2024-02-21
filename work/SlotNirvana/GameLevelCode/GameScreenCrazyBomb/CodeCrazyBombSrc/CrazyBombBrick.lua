---
--island
--2018年6月5日
--CrazyBombBrick.lua
-- 鱼飞行动画

local SlotsNode = util_require("Levels.SlotsNode")
local CrazyBombBrick = class("CrazyBombBrick", SlotsNode)

local SlotsAnimNode = require "Levels.SlotsAnimNode"

CrazyBombBrick.GLODEN_BRICK_NORMAL = 120
CrazyBombBrick.GLODEN_BRICK_MINI = 121
CrazyBombBrick.GLODEN_BRICK_MINOR = 122
CrazyBombBrick.GLODEN_BRICK_MAJOR = 123
CrazyBombBrick.GLODEN_BRICK_GRAND = 124

function CrazyBombBrick:initUI(data)

    local mutil = data.num / globalData.slotRunData:getCurTotalBet()
    local csbName = "Socre_CrazyBomb_shuzi"
    local type = self.GLODEN_BRICK_NORMAL
    if mutil == 20 then
        csbName = "Socre_CrazyBomb_mini"
        type = self.GLODEN_BRICK_MINI
    elseif mutil == 100 then
        csbName = "Socre_CrazyBomb_minor"
        type = self.GLODEN_BRICK_MINOR
    elseif mutil == 1000 then
        csbName = "Socre_CrazyBomb_major"
        type = self.GLODEN_BRICK_MAJOR
    elseif mutil == 5000 then
        csbName = "Socre_CrazyBomb_grand"
        type = self.GLODEN_BRICK_GRAND
    end
    
    self:initSlotNodeByCCBName(csbName, type)
    local node = self:getCCBNode()

    if node.m_csbNode:getChildByName("m_lab_coin") ~= nil then
        node.m_csbNode:getChildByName("m_lab_coin"):setString(self:util_formatCoins(data.num , 3))
        local labCoin = node.m_csbNode:getChildByName("m_lab_coin")
        local size = labCoin:getContentSize()
        if data.shape == "1x1" or data.shape == "1x2" or data.shape == "1x3" then
            labCoin:setScale(0.363)
        elseif data.shape == "2x2" or data.shape == "2x3" then
                labCoin:setScale(0.836)
        elseif data.shape == "3x2" or data.shape == "3x3" then
                labCoin:setScale(1.152)
        elseif data.shape == "4x2" or data.shape == "4x3" then
                labCoin:setScale(1.375)
        elseif data.shape == "5x2" or data.shape == "5x3" then
                labCoin:setScale(1.589)
        end
    end
    

    if node.m_csbNode:getChildByName("Words") ~= nil then
        local labWords = node.m_csbNode:getChildByName("Words")
        if data.shape == "1x1" or data.shape == "1x2" or data.shape == "1x3" then
                labWords:setScale(0.35)
        elseif data.shape == "2x2" or data.shape == "2x3" then
                labWords:setScale(0.787)
        elseif data.shape == "3x2" or data.shape == "3x3" then
                labWords:setScale(1.319)
        elseif data.shape == "4x2" or data.shape == "5x2" then
                labWords:setScale(1.617)
        elseif data.shape == "4x3" or data.shape == "5x3" then
                labWords:setScale(1.841)
        end
    end

    local bg = node.m_csbNode:getChildByName("BG")
    bg:setScaleX(data.width / bg:getContentSize().width)
    bg:setScaleY(data.height / bg:getContentSize().height)
    self.p_slotNodeH = data.height

    -- 破碎墙体
    -- local bg = util_createView("CodeCrazyBombSrc.CrazyBombBrickNodeBg")
    -- bg:changeImage(data)
    -- bg:setName("brickBG")
    -- self:addChild(bg, REEL_SYMBOL_ORDER.REEL_ORDER_2 + 1)
end

-- 还原到初始被创建的状态
function CrazyBombBrick:reset()
    if self:getChildByName("brickBG") then
        self:removeChildByName("brickBG")
    end
    
    SlotsNode.reset(self)

end

function CrazyBombBrick:onEnter()
    
end

function CrazyBombBrick:onExit()

end

-- util_formatCoins(数值,限制大小,是否添加分隔符','}
-- obligate:保留位数 限制大小  notCut=true（不添加分隔符','）
-- 向下取整0.99等于0
-- util_formatCoins(999999.99,2)      输出结果 = 0.9M    --限制2位数
-- util_formatCoins(999999.99,4)      输出结果 = 999.9K  --限制4位数
-- util_formatCoins(999999.99,6)      输出结果 = 999,999 --限制6位数
-- util_formatCoins(999999.99,6,true) 输出结果 = 999999  --不添加分隔符
-- util_formatCoins(999999.99,7)      输出结果 = 999,999 --限制7位数
function CrazyBombBrick:util_formatCoins(coins, obligate, notCut, normal)
    local obK = math.pow(10, 3)
    if type(coins)~="number" then
        return coins
    end
    --不需要限制的直接返回
    if obligate < 1 then
        return coins
    end

    --是否添加分割符
    local isCut = true
    if notCut then
        isCut = false
    end

    local str_coins = nil
    coins = tonumber(coins + 0.00001)
    local nCoins = math.floor(coins)
    local count = math.floor(math.log10(nCoins)) + 1
    if count <= obligate then
        str_coins = util_cutCoins(nCoins, isCut)
    else
        if count < 3 then
            str_coins = util_cutCoins(nCoins / obK, isCut) .. "K"
        else
            local tCoins = nCoins
            local tNum = 0
            local units = { "K", "M", "B", "T" }
            local cell = 1000
            local index = 0
            while
                (1)
            do
                index = index + 1
                if index > 4 then
                    return util_cutCoins(tCoins, isCut) .. units[4]
                end
                tNum = tCoins % cell
                tCoins = tCoins / cell
                local num = math.floor(math.log10(tCoins)) + 1
                if num <= obligate then
                    --应该保留的小数位
                    local floatNum = obligate - num
                    if normal then
                        local changeNum = math.floor( tCoins *10 ) /10 
                        return util_cutCoins(changeNum, isCut, floatNum) .. units[index]
                    end
                    local changeNum1 = tCoins
                    --保留1位小数
                    if num==1 and floatNum>0 then
                        floatNum = 1
                        changeNum1 = math.floor( tCoins *10 ) /10 
                    else
                        --正常模式不保留小数
                        floatNum = 0
                        
                    end
                    return util_cutCoins(changeNum1, isCut, floatNum) .. units[index]
                end
            end
        end
    end
    return str_coins
end

return CrazyBombBrick