---
--island
--2018年6月5日
--Christmas2021Brick.lua
-- 鱼飞行动画

local SlotsNode = util_require("Levels.SlotsNode")
local Christmas2021Brick = class("Christmas2021Brick", SlotsNode)

local SlotsAnimNode = require "Levels.SlotsAnimNode"

Christmas2021Brick.GLODEN_BRICK_NORMAL = 120
Christmas2021Brick.GLODEN_BRICK_MINI = 121
Christmas2021Brick.GLODEN_BRICK_MINOR = 122
Christmas2021Brick.GLODEN_BRICK_MAJOR = 123
Christmas2021Brick.GLODEN_BRICK_GRAND = 124

function Christmas2021Brick:initUI(data)

    local mutil = data.num / globalData.slotRunData:getCurTotalBet()
    local csbName = "Socre_Christmas2021_bonus_end_"..data.shape
    local type = self.GLODEN_BRICK_NORMAL
    local name = "Node_coins"
    local csbNameTotal = {"Node_coins", "Node_mini", "Node_minor", "Node_major", "Node_grand"}
    if mutil == 20 then
        type = self.GLODEN_BRICK_MINI
        name = "Node_mini"
    elseif mutil == 100 then
        type = self.GLODEN_BRICK_MINOR
        name = "Node_minor"
    elseif mutil == 1000 then
        type = self.GLODEN_BRICK_MAJOR
        name = "Node_major"
    elseif mutil == 2000 then
        type = self.GLODEN_BRICK_GRAND
        name = "Node_grand"
    end
    self:initSlotNodeByCCBName(csbName, type)
    local node = self:getCCBNode()
    -- 隐藏掉图片
    for i,_csbName in ipairs(csbNameTotal) do
        if node.m_csbNode:getChildByName(_csbName) ~= nil then
            node.m_csbNode:getChildByName(_csbName):setVisible(false)
        end
    end
    -- 显示需要的 图片
    if node.m_csbNode:getChildByName(name) ~= nil then
        node.m_csbNode:getChildByName(name):setVisible(true)
    else
        name = "Node_coins"
        node.m_csbNode:getChildByName(name):setVisible(true)
    end

    -- 显示金币
    if name == "Node_coins" then
        node.m_csbNode:getChildByName("Node_coins"):getChildByName("m_lb_coins"):setString(self:util_formatCoins(data.num , 3))
    end

    self.p_slotNodeH = data.height
end

-- 还原到初始被创建的状态
function Christmas2021Brick:reset()

    SlotsNode.reset(self)

end

function Christmas2021Brick:onEnter()
    
end

function Christmas2021Brick:onExit()

end

-- util_formatCoins(数值,限制大小,是否添加分隔符','}
-- obligate:保留位数 限制大小  notCut=true（不添加分隔符','）
-- 向下取整0.99等于0
-- util_formatCoins(999999.99,2)      输出结果 = 0.9M    --限制2位数
-- util_formatCoins(999999.99,4)      输出结果 = 999.9K  --限制4位数
-- util_formatCoins(999999.99,6)      输出结果 = 999,999 --限制6位数
-- util_formatCoins(999999.99,6,true) 输出结果 = 999999  --不添加分隔符
-- util_formatCoins(999999.99,7)      输出结果 = 999,999 --限制7位数
function Christmas2021Brick:util_formatCoins(coins, obligate, notCut, normal)
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

return Christmas2021Brick