--[[
    长数字
    author:{author}
    time:2023-09-03 14:06:05
]]
GD.isBN = function()
    if util_isSupportVersion("1.9.0", "android") or util_isSupportVersion("1.9.3", "ios") or util_isSupportVersion("1.8.3", "mac") then
        return true
    else
        return false
    end
end

GD.LongNumber = {__cname = "LongNumber"}

-- LongNumber最小限制长度
local _limitLen = 15

local _getNum = function(_val)
    local _num = _val or "0"
    if iskindof(_val, "LongNumber") then
        _num = _val.lNum
    elseif type(_val) == "number" then
        _num = string.format("%.f", _val)
        if string.len(_num) > _limitLen then
            local errMsg = string.format("The number %s exceeds the limit length %d and has precision problems. Please use as string!", _num, _limitLen)
            if DEBUG == 2 and isMac() then
                -- showErrorDialog(errMsg)
            else
                -- util_sendToSplunkMsg("LongNumber", errMsg)
            end
        end
    end
    return _num
end

local _getStr = function(_val)
    local _num = _val or ""
    if iskindof(_val, "LongNumber") then
        _num = _val.lNum
    elseif type(_val) == "number" then
        _num = string.format("%.f", _val)
        if string.len(_num) > _limitLen then
            local errMsg = string.format("The number %s exceeds the limit length %d and has precision problems. Please use as string!", _num, _limitLen)
            if DEBUG == 2 and isMac() then
                -- showErrorDialog(errMsg)
            else
                -- util_sendToSplunkMsg("LongNumber", errMsg)
            end
        end
    end
    return _num
end

local _toLNum = function(_val)
    _val = _val or 0
    if iskindof(_val, "LongNumber") then
        return _val
    else
        return LongNumber:new(_val)
    end
end

function LongNumber:new(data)
    data = data or ""
    if data == "" then
        data = 0
    end
    local tb = {}
    setmetatable(tb, self)
    setmetatableindex(tb, self)
    tb.lNum = _getNum(data)
    return tb
end

function LongNumber:setNum(_num)
    self.lNum = _getNum(_num)
end

-- LongNumber.__newindex = function(mytable, key, value)
--     if key == "lNum" then
--         rawset(mytable, key, _getStr(value))
--     end
-- end

-- 运算符'+'
LongNumber.__add = function(a, b)
    local _aNum = _getNum(a)

    local _bNum = _getNum(b)

    local _lNum = "0"
    if isBN() then
        _lNum = xcyy.SlotsUtil:bn_arith(_aNum, _bNum, "+")
    else
        _lNum = bigNumAdd(_aNum, _bNum)
    end
    return LongNumber:new(_lNum)
end

-- 运算符'-'
LongNumber.__sub = function(a, b)
    local _aNum = _getNum(a)

    local _bNum = _getNum(b)

    local _lNum = "0"
    if isBN() then
        _lNum = xcyy.SlotsUtil:bn_arith(_aNum, _bNum, "-")
    else
        _lNum = bigNumSub(_aNum, _bNum)
    end
    -- 减法大部分情况下是获取临时值，使用长整数的地方不多
    if string.len(_lNum) < _limitLen then
        return tonumber(_lNum)
    else
        return LongNumber:new(_lNum)
    end
end

-- 运算符'*'
LongNumber.__mul = function(a, b)
    local _temp = 1
    local _a = a
    local _b = b
    -- 大数运算中出现浮点数的情况
    if type(_a) == "number" then
        local _d, _f = math.modf(_a)
        if _f > 0 then
            _a = _a * math.pow(10,8)
            _temp = _temp * math.pow(10,8)
        end
    end
    if type(_b) == "number" then
        local _d, _f = math.modf(_b)
        if _f > 0 then
            _b = _b * math.pow(10,8)
            _temp = _temp * math.pow(10,8)
        end
    end
    -- =====================
    local _aNum = _getNum(_a)

    local _bNum = _getNum(_b)

    local _lNum = "0"
    if isBN() then
        _lNum = xcyy.SlotsUtil:bn_arith(_aNum, _bNum, "*")

        if _temp > 1 then
            local _sTemp = string.format("%.f", _temp)
            _lNum = xcyy.SlotsUtil:bn_arith(_lNum, _sTemp, "/")
        end
    else
        assert(nil, "The multiplication operation is not implemented!!!")
    end
    return LongNumber:new(_lNum)
end

-- 运算符'/'
LongNumber.__div = function(a, b)
    local _aNum = _getNum(a)

    local _bNum = _getNum(b)

    local _lNum = "0"
    if isBN() then
        _lNum = xcyy.SlotsUtil:bn_arith(_aNum, _bNum, "/")
    else
        assert(nil, "The division operation is not implemented!!!")
    end
    return LongNumber:new(_lNum)
end

-- 运算符'<'
LongNumber.__lt = function(a, b)
    local _aNum = _getNum(a)

    local _bNum = _getNum(b)

    if xcyy.SlotsUtil.bn_cmp then
        local iLt = xcyy.SlotsUtil:bn_cmp(_aNum, _bNum)
        return iLt < 0
    else
        local bLt = bigNumCmp(_aNum, _bNum, "<")
        return bLt
    end
end

-- 运算符'<='
LongNumber.__le = function(a, b)
    local _aNum = _getNum(a)

    local _bNum = _getNum(b)

    if xcyy.SlotsUtil.bn_cmp then
        local iLt = xcyy.SlotsUtil:bn_cmp(_aNum, _bNum)
        return (iLt <= 0)
    else
        local bLe = not (bigNumCmp(_aNum, _bNum, ">"))
        return bLe
    end
end

-- 运算符'=='
LongNumber.__eq = function(a, b)
    local _aNum = _getNum(a)

    local _bNum = _getNum(b)

    if string.len(_aNum) < _limitLen and string.len(_bNum) < _limitLen then
        return tonumber(_aNum) == tonumber(_bNum)
    else
        if xcyy.SlotsUtil.bn_cmp then
            local iEq = xcyy.SlotsUtil:bn_cmp(_aNum, _bNum)
            return (iEq == 0)
        else
            return _aNum == _bNum
        end
    end
end

-- 运算符'..'
LongNumber.__concat = function(a, b)
    local _aStr = _getStr(a)

    local _bStr = _getStr(b)

    return "" .. _aStr .. _bStr
end

-- 输出
LongNumber.__tostring = function(tbLNum)
    local _num = _getNum(tbLNum)
    return _num
end

LongNumber.__call = function(mytb, newtb)
    return mytb:new(newtb)
end

LongNumber.min = function(a, b)
    a = _toLNum(a)
    b = _toLNum(b)
    if a < b then
        return a
    else
        return b
    end
end

LongNumber.max = function(a, b)
    a = _toLNum(a)
    b = _toLNum(b)
    if a > b then
        return a
    else
        return b
    end
end

LongNumber.lnum2num = function(_a)
    return tonumber(tostring(_a))
end

-- 大数tb 转 LongNumber
local _tb2LNum = function(tb)
    if tb and tb.lNum then
        return _toLNum(tb.lNum)
    else
        return tb
    end
end

-- 递归处理tb转包含LongNumber的tb
local tb2LongNumber
tb2LongNumber = function(tb)
    tb = tb or {}
    for k, v in pairs(tb) do
        if type(v) == "table" then
            if table.nums(v) == 1 then
                tb[k] = _tb2LNum(v)
            else
                tb[k] = tb2LongNumber(v)
            end
        end
    end
    return tb
end
LongNumber.tbConvert = tb2LongNumber

-- decode包含LongNumber的字符串
LongNumber.decode = function(tbStr)
    local tb = cjson.decode(tbStr) or {}
    tb = tb2LongNumber(tb)
    return tb
end

-- 转成 LongNumber 数字
GD.toLongNumber = function(_val)
    return _toLNum(_val)
end
GD.toLNum = function(_val)
    return _toLNum(_val)
end
-- =====================================
-- 大整数显示 （ 超过17位缩写，最小缩写单位是M)
GD.util_formatBigNumCoins = function(_strNum, ...)
    local limitCount = 17
    -- _strNum = string.format("%s", _strNum)
    if type(_strNum) ~= "string" then
        _strNum = "" .. toLongNumber(_strNum)
    end
    if string.len(_strNum) <= limitCount then
        return util_formatCoins(_strNum, ...)
    end

    local million = math.pow(10, 6)
    local tempStr = _strNum
    local minCutNumber = 6
    local maxCutNumber = 12
    while true do
        tempStr = string.sub(_strNum, 1, -(minCutNumber + 1))
        if string.len(tempStr) <= limitCount then
            break
        end
        if minCutNumber >= maxCutNumber then
            minCutNumber = minCutNumber + 1
        else
            minCutNumber = minCutNumber + 3
        end
    end

    local formatMoney = function(_testNumStr)
        local formatStr = ""
        local len = #_testNumStr
        for i = len, 1, -3 do
            local sIdx = math.max(i - 2, 1)
            local temp = string.sub(_testNumStr, sIdx, i)
            if i ~= len then
                temp = temp .. ","
            end
            formatStr = temp .. formatStr
        end
        -- formatStr = string.sub(formatStr, 1, -2)
        return formatStr
    end

    local suffixList = {"M", "", "", "B", "", "", "T"}
    local suffixStr = suffixList[minCutNumber - 6 + 1]
    if suffixStr then
        return formatMoney(tempStr) .. suffixStr
    end

    -- 超过 T了
    return formatMoney(string.sub(_strNum, 1, -13)) .. "T"
end
