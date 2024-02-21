--[[
    大数金币计算
    author:{author}
    time:2023-07-09 16:46:57
]]
-- local bigNum = {}
-- 数组的一组数长度
local upperLen = 14
GD.BigNumberLimitLen = upperLen
-- 大整数字符串转整数表
GD.coins2Tab = function(bigNumStr)
    local tbNum = {}
    -- 查找负号
    local st, ed = string.find(bigNumStr, "-")
    if st then
        bigNumStr = string.sub(bigNumStr, ed + 1, string.len(bigNumStr))
    end
    local lens = string.len(bigNumStr)
    local nCount = math.ceil(lens / upperLen)
    local _temp = lens
    -- 高位放在后面
    for i = 1, nCount, 1 do
        local st = math.max(0, _temp - upperLen) + 1
        local strNum = string.sub(bigNumStr, st, _temp)
        tbNum[i] = tonumber(strNum)
        _temp = _temp - upperLen
    end

    if st then
        tbNum[nCount + 1] = "-"
    else
        -- tbNum[nCount + 1] = "+"
    end

    return tbNum
end

-- 整数表转数值字符串
GD.tab2Coins = function(tbNum)
    local strCoins = ""
    local nCount = #(tbNum or {})
    for i = nCount, 1, -1 do
        local temp = ""
        if i == nCount then
            temp = tostring(tbNum[i])
        else
            temp = string.format("%0" .. upperLen .. "d", tbNum[i])
        end
        strCoins = strCoins .. temp
    end
    return strCoins
end

-- 加
-- 大数数组相加
GD.tbNumAdd = function(bNum1, bNum2)
    local rNum = {}
    -- 获得循环长度
    local _len = math.max(#bNum1, #bNum2)
    -- 最大值
    local _value = math.pow(10, upperLen)
    -- 进位
    local _carry = 0

    -- 运算次数
    local _idx = 1
    while (_idx <= _len) or (_carry > 0) do
        local _num1 = tonumber(bNum1[_idx] or 0)
        local _num2 = tonumber(bNum2[_idx] or 0)
        if _num2 > 0 or _carry > 0 then
            local _temp = _num1 + _num2 + _carry
            _carry = math.floor(_temp / _value)
            rNum[_idx] = tostring(math.mod(_temp, _value))
        else
            rNum[_idx] = tostring(_num1)
        end
        _idx = _idx + 1
    end

    return rNum
end

-- 移除负号位
local _removeSymbol = function(tbNum)
    tbNum = tbNum or {}
    local _len = #tbNum
    if _len > 0 and tbNum[_len] == "-" then
        local _sy = table.remove(tbNum, _len)
        return _sy, tbNum
    end
    return "", tbNum
end

-- 大数字符串相加
-- GD.bigNumAdd = function(strNum1, strNum2)
--     local _result = tonumber(strNum1) + tonumber(strNum2)
--     return string.format("%d", _result)
-- end
GD.bigNumAdd = function(strNum1, strNum2)
    strNum1 = tostring(strNum1)
    strNum2 = tostring(strNum2)
    if string.len(strNum1) > upperLen or string.len(strNum2) > upperLen then
        local tbNum1 = coins2Tab(strNum1)
        local tbNum2 = coins2Tab(strNum2)
        local tbTotal = {}
        -- 获得两个数的高位
        local hV1, _tbNum1 = _removeSymbol(tbNum1)
        local hV2, _tbNum2 = _removeSymbol(tbNum2)
        if (hV1 ~= "-" and hV2 ~= "-") then
            -- 都是正数
            tbTotal = tbNumAdd(_tbNum1, _tbNum2)
        elseif (hV1 == "-" and hV2 == "-") then
            -- 都是负数
            tbTotal = tbNumAdd(_tbNum1, _tbNum2)
            tbTotal[#tbTotal + 1] = hV1
        elseif hV1 == "-" then
            tbTotal = tbNumSub(_tbNum2, _tbNum1)
        elseif hV2 == "-" then
            tbTotal = tbNumSub(_tbNum1, _tbNum2)
        end
        return tab2Coins(tbTotal)
    else
        local _total = tonumber(strNum1) + tonumber(strNum2)
        return string.format("%d", _total)
    end
end

-- 减
-- 大数数组相减
GD.tbNumSub = function(bNum1, bNum2)
    local rNum = {}
    -- 获得循环长度
    local _len = math.max(#bNum1, #bNum2)
    -- 进位最大值
    local _value = math.pow(10, upperLen)
    -- 借位变量
    local borrow = 0

    for _idx = 1, _len do
        local _num1 = tonumber(bNum1[_idx] or 0)
        local _num2 = tonumber(bNum2[_idx] or 0)
        local _temp = _num1 - _num2 - borrow
        if _temp >= 0 then
            borrow = 0
        else
            -- 需要借位
            _temp = _temp + _value
            borrow = 1
        end
        rNum[_idx] = tostring(_temp)
    end

    if borrow > 0 then
        -- 结果为负数
        for _idx = 1, #rNum do
            local _temp = 0
            if _idx == 1 then
                _temp = _value - tonumber(rNum[_idx])
            else
                _temp = _value - tonumber(rNum[_idx]) - borrow
            end
            rNum[_idx] = tostring(_temp)
        end
        -- 去除高位为0的结果
        for _idx = #rNum, 1, -1 do
            local _val = rNum[_idx]
            if _val == "0" or _val == "" then
                table.remove(rNum, _idx)
            else
                break
            end
        end
        if #rNum > 0 then
            -- 加上负号
            rNum[#rNum + 1] = "-"
        end
    end

    return rNum
end

-- 大数字符串减
-- GD.bigNumSub = function(strNum1, strNum2)
--     local _result = tonumber(strNum1) - tonumber(strNum2)
--     return string.format("%d", _result)
-- end
GD.bigNumSub = function(strNum1, strNum2)
    strNum1 = tostring(strNum1)
    strNum2 = tostring(strNum2)
    if string.len(strNum1) > upperLen or string.len(strNum2) > upperLen then
        local tbNum1 = coins2Tab(strNum1)
        local tbNum2 = coins2Tab(strNum2)
        local tbTotal = {}
        -- 获得两个数的高位
        local hV1, _tbNum1 = _removeSymbol(tbNum1)
        local hV2, _tbNum2 = _removeSymbol(tbNum2)
        if (hV1 ~= "-" and hV2 ~= "-") then
            -- 都是正数
            tbTotal = tbNumSub(_tbNum1, _tbNum2)
        elseif (hV1 == "-" and hV2 == "-") then
            -- 都是负数
            tbTotal = tbNumSub(_tbNum2, _tbNum1)
        elseif hV1 == "-" then
            tbTotal = tbNumAdd(_tbNum2, _tbNum1)
            tbTotal[#tbTotal + 1] = hV1
        elseif hV2 == "-" then
            tbTotal = tbNumAdd(_tbNum1, _tbNum2)
        end
        return tab2Coins(tbTotal)
    else
        local _total = tonumber(strNum1) - tonumber(strNum2)
        return string.format("%d", _total)
    end
end

-- 乘

-- 除

-- 大数字符串 比较
GD.bigNumCmp = function(strNum1, strNum2, compareType)
    if not compareType then
        return false
    end

    local totalNum = "0"
    if string.find(strNum2, "-") then
        -- 去除负号
        totalNum = bigNumAdd(strNum1, string.sub(strNum2, 2, string.len(strNum2)))
    else
        totalNum = bigNumSub(strNum1, strNum2)
    end
    local calcType = ">"
    if totalNum == "0" then
        calcType = "="
    elseif string.find(totalNum, "-") then
        calcType = "<"
    end

    if string.find(compareType, calcType) then
        return true
    end
    return false
end

-- 取最小值
GD.bigNumMin = function(strNum1, strNum2)
    local isLess = bigNumCmp(strNum1, strNum2, "<")
    if isLess then
        return strNum1
    else
        return strNum2
    end
end

-- 取最大值
GD.bigNumMax = function(strNum1, strNum2)
    local isGreater = bigNumCmp(strNum1, strNum2, ">")
    if isGreater then
        return strNum1
    else
        return strNum2
    end
end
