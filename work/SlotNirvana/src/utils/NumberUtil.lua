---
-- 处理所有的数字工具类 随机数、比大小、
--
--

---
--返回num1,num2中的较大值
--@param num1 int 数字一
--@param num2 int 数字二
function GD.util_max(num1, num2)
    if num1 >= num2 then
        return num1
    else
        return num2
    end
end

---
--返回num1,num2中的较小值
--@param num1 int 数字一
--@param num2 int 数字二
function GD.util_min(num1, num2)
    if num1 >= num2 then
        return num2
    else
        return num1
    end
end

function GD.util_limit(value, min, max)
    if min ~= nil and value < min then
        return min
    elseif max ~= nil and value > max then
        return max
    else
        return value
    end
end

---
-- 问号表达式
-- @param cond boolean 测试条件
-- @param a any 条件成立的返回值
-- @param b any 条件不成立的返回值
function GD.util_cond_test(cond, a, b)
    if cond then
        return a
    end

    return b
end

---
--产生随机数，[min, max]
--@param min number 最小值
--@param max number 最大值
function GD.util_random(min, max)
    --    assert(min>=0 and max > min, "wrong args in function GD.rndInt")
    return math.random(min, max)
end

---
--产生随机数，[min, max)
--@param min number 最小值
--@param max number 最大值,不包含
function GD.util_randomWithoutMax(min, max)
    assert(min >= 0 and max > min, "wrong args in function GD.rndInt")
    return math.random(min, max - 1)
end

---
--对一个数字进行四舍五入
--@param num 需要进行四舍五入的数字
--@return #int 四舍五入后的结果整数
function GD.util_round(num)
    local min = math.floor(num)
    if num - min >= .5 then
        min = min + 1
    end

    return min
end

---
--highNum
function GD.util_highNum(num)
    if num then
        local num = string.format("%d", num)
        local len = string.len(num)
        log("highNum len=%d", len)
        --        string.gsub(s,pattern,repl,n)
        local h = string.sub(num, 1, 1)
        local l = len - 1
        while l > 0 do
            h = h .. "0"
            l = l - 1
        end
        return tonumber(h)
    end
    return 0
end

---
--对数组进行随机洗牌操作
--@param tbl table 数组
function GD.util_shuffle(tbl)
    for i = 1, #tbl do
        local rnd = math.random(1, #tbl)
        local rnd2 = math.random(1, #tbl)

        ---rnd2可能会与rnd相同，但不影响整体乱序
        --最坏情况，rnd2===rnd,顺序未改变
        if rnd ~= rnd2 then
            local temp = tbl[rnd]
            tbl[rnd] = tbl[rnd2]
            tbl[rnd2] = temp
        end
    end
end

function GD.float_equal(x, v)
    return ((v - -0.001) < x) and (x < (v + -0.001))
end

--传入权重列表,随机获得一个权重索引
function GD.util_getIndexForWeightList(weightList)
    if not weightList then
        return
    end
    local weightAmount = 0
    for i = 1, #weightList do
        weightAmount = weightAmount + weightList[i]
    end
    local currentWeight = math.random(1, weightAmount)
    for index = 1, #weightList do
        if currentWeight <= weightList[index] then
            return index
        else
            currentWeight = currentWeight - weightList[index]
        end
    end
end

function GD.util_getAngleRadXY(x1, y1, x2, y2)
    local rad = math.atan2(y2 - y1, x2 - x1)
    return rad < 0 and (rad + 2 * math.pi) or rad
end

function GD.util_isNumber(nums)
    if type(nums) == "number" then
        return true
    end
    local _str = "" .. nums
    for i = 1, string.len(_str) do
        local _b = string.sub(_str, i, i)
        if string.byte(_b) < 48 or string.byte(_b) > 57 then
            return false
        end
    end
    return true
end

-- 指定数字字符替换成随机数
function GD.util_replaceNum2Rand(sNum, rep)
    local _len = string.len(sNum)
    if _len < 3 then
        return sNum
    end

    -- rep = rep or "0"
    local _str = ""
    local _idx = 1
    -- 取整数位
    local tbNum = string.split(sNum, ".")
    local numTemp = {2, 3, 6, 7}
    local nCount = #numTemp

    for w in string.gmatch(tbNum[1], "%d") do
        if _idx > 2 then
            if (not rep) or w == rep then
                local idx = math.random(1, nCount)
                _str = _str .. numTemp[idx]
            else
                _str = _str .. w
            end
        else
            _str = _str .. w
        end
        _idx = _idx + 1
    end

    if tbNum[2] then
        _str = _str .. "." .. tbNum[2]
    end

    return _str
end

import(".BigNumberUtil")
import(".LongNumber")