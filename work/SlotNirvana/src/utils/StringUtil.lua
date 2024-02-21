---
-- 处理字符串的工具函数 拆分、拼接等
--
--

---
-- 根据pattern 来查找字符串，并且获取pattern 前或后面字符串
-- @param value string 字符串
-- @param pattern string 查找标识
-- @param subBefore bool 是否切分pattern 前面的标识 , 默认false 切分后面的
--
function GD.util_string_getsubstring_bypattern(value, pattern, subBefore)
    subBefore = subBefore or false

    local index = string.find(value, pattern, pattern)

    if subBefore then
        return string.sub(testStr, 1, index - 1)
    else
        return string.sub(testStr, index + 1)
    end
end

function GD.util_significant_digits(num, digits)
    --local currMoney = gLobalDataManager:getGameData():getMoney() * 5
    --local n = math.log10(currMoney)
    return 0
end

-----
-- 根据split_char 进行拆分字符串
-- reutrn 返回table
-- @param isNumber bool 是否为数字, 当设置为true 时必须要保证分割的字符串里面都是数字，否则会导致table“脏”
function GD.util_string_split(str, split_char, isNumber)
    isNumber = isNumber or false

    local sub_str_tab = string.split(str, split_char)
    if isNumber == true then
        for i = 1, #sub_str_tab do
            sub_str_tab[i] = tonumber(sub_str_tab[i])
        end
    end
    --     if str == nil or str == "" then return sub_str_tab end
    --     local i = 0
    --     local j = 0
    --     while true do
    --         j = string.find(str, split_char,i+1)    --从目标串str第i+1个字符开始搜索指定串

    --         if j == nil then
    --             if isNumber then
    -- --                table.insert(sub_str_tab,tonumber(string.sub(str,i+1)))
    --                 sub_str_tab[#sub_str_tab + 1] = tonumber(string.sub(str,i+1))
    --             else
    -- --                table.insert(sub_str_tab,string.sub(str,i+1))
    --                 sub_str_tab[#sub_str_tab + 1] = string.sub(str,i+1)
    --             end

    --             break
    --         end

    --         if isNumber then
    --             sub_str_tab[#sub_str_tab + 1 ] = tonumber(string.sub(str,i+1,j-1))
    --         else
    --             sub_str_tab[#sub_str_tab + 1 ] = string.sub(str,i+1,j-1)
    --         end

    --         i = j
    --     end
    return sub_str_tab
end

--[[
    @desc: 将字符串格式的 version 转化为数字， 例如1.1.0 转化结果为110
    time:2019-01-25 16:53:13
    --@appCode:
    @return:
]]
function GD.util_convertAppCodeToNumber(appCode)
    if appCode == nil then
        return 0
    end
    local strLen = string.len(appCode)
    local targetStr = ""
    local isFirstP = false
    -- 主要是将字符串格式的 带小数点版本号  .. 例如版本号设置为1.4.5 将其改为1.45 利于数字运算
    for i = 1, strLen do
        local cStr = string.sub(appCode, i, i)
        if cStr ~= "." then
            targetStr = targetStr .. cStr
        elseif isFirstP == false then
            targetStr = targetStr .. cStr
            isFirstP = true
        end
    end
    local targetNum = tonumber(targetStr)
    if targetNum == nil then
        return 0
    end
    return targetNum
end

---
-- 拆分概率类的字符串， 并且计算总pro 数，默认拆分成数字，
--
--@return #{} number 返回拆分的数组， 返回总的pro数量
function GD.util_string_split_pro(str, split_char)
    local sub_str_tab = {}
    if str == nil or str == "" then
        return sub_str_tab
    end
    local i = 0
    local j = 0
    local totalPro = 0
    while true do
        j = string.find(str, split_char, i + 1) --从目标串str第i+1个字符开始搜索指定串

        if j == nil then
            local strNumber = tonumber(string.sub(str, i + 1))
            totalPro = totalPro + strNumber
            sub_str_tab[#sub_str_tab + 1] = strNumber
            break
        end
        local strNumber = tonumber(string.sub(str, i + 1, j - 1))
        totalPro = totalPro + strNumber
        sub_str_tab[#sub_str_tab + 1] = strNumber
        i = j
    end
    return sub_str_tab, totalPro
end

----
--用sep分隔字符串str,返回分隔后字符串数组
--@param str string 要分隔的字符串
--@param sep string 分隔符
--@return table 分隔后的字符串数组
function GD.util_split(str, sep)
    local findStartIndex = 1
    local splitIndex = 1
    local splitedAry = {}
    while true do
        local nFindLastIndex = string.find(str, sep, findStartIndex)
        if not nFindLastIndex then
            splitedAry[splitIndex] = string.sub(str, findStartIndex, string.len(str))
            break
        end
        splitedAry[splitIndex] = string.sub(str, findStartIndex, nFindLastIndex - 1)
        findStartIndex = nFindLastIndex + string.len(sep)
        splitIndex = splitIndex + 1
    end
    return splitedAry
end

---
-- 超额金币数，转换 统计单位。（k,m,b,t）
--
function GD.util_formatLargeMoney(num)
    local str = string.format("%s", num)
    local strLen = string.len(str)
    local unit = ""
    local index = 0

    local resultCoin = num

    if strLen > 3 then
        unit = "K"
        index = 3

        resultCoin = num / 1000
    end
    if strLen > 6 then
        unit = "M"
        index = 6

        resultCoin = num / 1000000
    end
    if strLen > 9 then
        unit = "B"
        index = 9

        resultCoin = num / 1000000000
    end
    if strLen > 12 then
        unit = "T"
        index = 12

        resultCoin = num / 1000000000000
    end

    local _sCoins = ""
    local iVal, fVal = math.modf(resultCoin)
    if fVal > 0.0001 then
        -- 浮点数保留两位
        _sCoins = string.format("%.02f", resultCoin)
    else
        _sCoins = string.format("%d", resultCoin)
    end
    return _sCoins .. unit
end
---
-- 获取金钱格式的字符串， 每三个字符加一个逗号
--

function GD.util_getFromatMoneyStr(num)
    --屏蔽错误类型
    if not num then
        release_print("FromatMoneyStr error type = nil")
        return ""
    end
    local str = ""
    if type(num) == "number" then
        str = string.format("%0.f", num)
    elseif type(num) == "string" then
        str = num
    elseif iskindof(num, "LongNumber") then
        str = str .. num
    end
    local strLen = string.len(str)
    local newStr = {}
    local flag = ","
    local flagEmpty = ""

    local groupCount = math.ceil(strLen / 3)

    local valueCount = groupCount * 2

    for i = 1, groupCount, 1 do
        local subStr = nil
        if i ~= groupCount then
            subStr = string.sub(str, strLen - 2, strLen)
            strLen = strLen - 3
        else
            subStr = string.sub(str, 1, strLen)
        end
        newStr[valueCount - 1] = subStr
        if i == 1 then
            newStr[valueCount] = flagEmpty
        else
            newStr[valueCount] = flag
        end
        valueCount = valueCount - 2
    end

    return table.concat(newStr, "")
end

---
-- 字符串加法
-- @param numA string
-- @param numB string
function GD.util_addNumber(numA, numB) -- 字符串 加法
    local sAddNum = ""

    local len = string.len(numA)
    local size = string.len(numB)

    numA = string.reverse(numA)
    numB = string.reverse(numB)

    --    local times = 0
    --    if len > size then
    --    	times = len
    --    else
    --        times = size
    --    end
    --
    --    local carry = 0
    --    for i = 1,  times , 1 do
    --        local iNuma = 0
    --        local iNumb = 0
    --        if i <= numA.size() then
    --            iNuma = (long)(numA.at(i) - '0')
    --        end
    --
    --        if (i < numB.size())
    --        {
    --            iNumb = (long)(numB.at(i) - '0')
    --        }
    --
    --        int iTotal = iNuma + iNumb + carry
    --        if (iTotal > 9)
    --        {
    --            iTotal = iTotal % 10
    --            carry = 1
    --        }
    --        else
    --        {
    --            carry = 0
    --        }
    --        char ch = '0' + iTotal
    --        sAddNum.push_back(ch)
    --    end
    --    if (carry > 0)
    --    {
    --        char ch = '0' + carry
    --        sAddNum.push_back(ch)
    --    }
    --
    --    reverse(sAddNum.begin(),sAddNum.end())

    return sAddNum
end

function GD.util_getRankEndStr(iPlayerRank)
    local strEndwith = function(strRank, endChar)
        if string.sub(strRank, -1, -1) == endChar then
            return true
        end
        return false
    end

    local strEnd = "th"
    local strRank = tostring(iPlayerRank)

    if iPlayerRank == 11 or iPlayerRank == 12 or iPlayerRank == 13 then
        strEnd = "th"
    elseif strEndwith(strRank, "1") then
        strEnd = "st"
    elseif strEndwith(strRank, "2") then
        strEnd = "nd"
    elseif strEndwith(strRank, "3") then
        strEnd = "rd"
    end

    return strEnd
end

function GD.get_integer_string(num)
    return tostring(num)
end

--获取文件名,去掉后缀
function GD.util_getFileName(str)
    local idx = str:match(".+()%.%w+$")
    if (idx) then
        return str:sub(1, idx - 1)
    else
        return str
    end
end

-- 忽略字符串首尾的空白字符
function GD.trim(input)
    return (string.gsub(input, "^%s*(.-)%s*$", "%1"))
end

--[[
    @desc:  lable文本自动换行 不考虑单词模式
    author:{cxc}
    time:2021-08-28 14:17:44
    --@lbText: 待操作的lb控件
	--@sourceStr: 设置的 label 文本
	--@limitWidth: 限制的宽度
]]
function GD.util_AutoLineNoWordType(lbText, sourceStr, limitWidth)
    local curStr = ""
    local newStr = ""
    local finalStr = ""
    local tempStr = ""
    local lineNum = 1 -- 行数
    for i = 0, #sourceStr do
        curStr = string.sub(sourceStr, i, i)
        tempStr = newStr .. curStr
        --每次载入一个字符后去设置新的文本，得到新的宽度
        lbText:setString(tempStr)

        --当文本最新一行尺寸大于设定的宽度时开始做换行处理
        local scale = 1
        -- if lbText.getScale then
        --     scale = lbText:getScale()
        -- end
        if lbText:getContentSize().width * scale > limitWidth then
            finalStr = finalStr .. newStr .. "\n"
            newStr = curStr
            lineNum = lineNum + 1
        else
            newStr = tempStr
        end
    end

    lbText:setString(finalStr .. newStr)
    return lineNum
end
--[[
    @desc: 
    author:{author}
    time:2021-08-28 14:20:03
    --@lbText: 待操作的lb控件
	--@sourceStr: 设置的 label 文本
	--@limitWidth: 限制的宽度
    --@bWordType: 是否按单词拆分
]]
function GD.util_AutoLine(lbText, sourceStr, limitWidth, bWordType, noTrim)
    local lineNum = 1 -- 行数
    --忽略首尾空字符
    if not noTrim then
        sourceStr = GD.trim(sourceStr)
    end
    local lineNum = 1 -- 行数
    local lineStrVec = {}
    if not bWordType then
        lineNum = util_AutoLineNoWordType(lbText, sourceStr, limitWidth)
        return lineNum
    end

    local splitStr = " "
    local strList = util_split(sourceStr, splitStr)
    if #strList <= 1 then
        lineNum = util_AutoLineNoWordType(lbText, sourceStr, limitWidth)
        return lineNum
    end
    local newStr = ""
    local lineStr = ""
    for i = 1, #strList do
        local subStr = strList[i]
        local tempStr = newStr .. splitStr .. subStr
        if i == 1 then
            tempStr = newStr .. subStr
        end
        lbText:setString(tempStr)
        local scale = 1
        -- if lbText.getScale then
        --     scale = lbText:getScale()
        -- end
        if lbText:getContentSize().width * scale > limitWidth then
            lineNum = lineNum + 1
            -- 加了个新单词 超框了
            lbText:setString(subStr)
            if lbText:getContentSize().width * scale > limitWidth then
                lineNum = lineNum + 1
                -- 新单词一个 单词就超框了
                util_AutoLineNoWordType(lbText, tempStr, limitWidth)
                tempStr = lbText:getString()
            else
                -- 新单词没有超框 下一行重头
                tempStr = newStr .. "\n" .. subStr
                lineStrVec[#lineStrVec + 1] = lineStr
                lineStr = subStr
            end
        else
            lineStr = lineStr .. splitStr .. subStr
        end
        newStr = tempStr
    end
    lineStrVec[#lineStrVec + 1] = lineStr
    lbText:setString(newStr)
    return lineNum, lineStrVec
end

--智能换行
--
-- @param {txt} txt  --  要设置的文本框
-- @param {String} str  --  要设置的字符
-- @param {number} width--  换行的宽度
-- isGroup 按照词组分割
function GD.util_AutoLine_old(txt, str, width, isGroup)
    --忽略首尾空字符
    str = GD.trim(str)

    local FinalStr = ""
    --最终的字符串
    local CurStr = ""
    --循环的时候每次加载的单个字符
    local newStr = "" --每一轮加载的字符串，每次换行为1轮
    if isGroup then
        local strChar = " "
        local strList = util_split(str, strChar)
        if #strList > 1 then
            for i = 1, #strList do
                CurStr = strList[i]
                --每次载入一个字符后去设置新的文本，得到新的宽度
                --这里仍然有隐患 如果间距不足够一个单词显示 还是需要考虑强行拆开
                if newStr == "" then
                    txt:setString(CurStr)
                else
                    txt:setString(newStr .. strChar .. CurStr)
                end

                --当文本最新一行尺寸大于设定的宽度时开始做换行处理
                if txt:getContentSize().width > width then
                    FinalStr = FinalStr .. newStr .. "\n"
                    newStr = CurStr
                else
                    if newStr == "" then
                        newStr = CurStr
                    else
                        newStr = newStr .. strChar .. CurStr
                    end
                end
            end
        else
            for i = 0, #str do
                CurStr = string.sub(str, i, i)
                newStr = newStr .. CurStr
                --每次载入一个字符后去设置新的文本，得到新的宽度
                txt:setString(newStr)

                --当文本最新一行尺寸大于设定的宽度时开始做换行处理
                if txt:getContentSize().width > width then
                    FinalStr = FinalStr .. newStr .. "\n"
                    newStr = ""
                end
            end
        end
    else
        for i = 0, #str do
            CurStr = string.sub(str, i, i)
            newStr = newStr .. CurStr
            --每次载入一个字符后去设置新的文本，得到新的宽度
            txt:setString(newStr)

            --当文本最新一行尺寸大于设定的宽度时开始做换行处理
            if txt:getContentSize().width > width then
                FinalStr = FinalStr .. newStr .. "\n"
                newStr = ""
            end
        end
    end
    txt:setString(FinalStr .. newStr)
end

function GD.util_getLetterPosition(txt, idx)
    if not txt then
        return cc.p(0, 0)
    end

    local str = txt:getString()
    if str == "" then
        return cc.p(0, 0)
    end

    local font_height = txt:getContentSize().height
    local str_list = string.split(str, "\n")

    local label = clone(txt)
    label:setString(str_list[#str_list])
    local width = label:getContentSize().width
    local lines = table.nums(str_list)
    local height = (lines - 1) * font_height + font_height / 2
    return cc.p(width, height)
end

function GD.util_AutoLineWrap(str)
    --忽略首尾空字符
    str = GD.trim(str)
    local result = ""
    for i = 1, #str do
        if i == #str then
            result = result .. string.sub(str, i, i)
        else
            result = result .. string.sub(str, i, i) .. "\n"
        end
    end
    return result
end

--返回实际占用的字符数
function GD.util_SubStringGetByteCount(curByte)
    local byteCount = 1
    if curByte == nil then
        byteCount = 0
    elseif curByte > 0 and curByte <= 127 then
        byteCount = 1
    elseif curByte >= 192 and curByte <= 223 then
        byteCount = 2
    elseif curByte >= 224 and curByte <= 239 then
        byteCount = 3
    elseif curByte >= 240 and curByte <= 247 then
        byteCount = 4
    end
    return byteCount
end

--排行榜限制长度
function GD.util_getRankMaxLenStr(str, len)
    local strLen = string.len(str)
    if len >= strLen then
        return str
    end
    local newLen = 0
    local index = 0
    while (index <= len) do
        index = index + 1
        local curByte = string.byte(str, index)
        local num = util_SubStringGetByteCount(curByte)
        if num == 0 then
            break
        end
        if newLen + num <= len then
            newLen = newLen + num
            index = index + num - 1
        else
            break
        end
    end
    local newStr = string.sub(str, 1, newLen) .. "..."
    return newStr
end

--[[
    @desc: 字符串 前缀替换
    ex: util_getFormatFixSubStr(str, "**")
            abcdefg---**cdefg
            1王老五---**老五
            王老五---**老五
            😊王老五---**王老五
            1😊王老五---**王老五
            12😊王老五---**😊王老五
    --@str: 原字符串
	--@prefix: 前缀
    @return: 前缀+截取的字符串
]]
function GD.util_getFormatFixSubStr(str, prefix)
    prefix = prefix or ""
    if not str or #prefix == 0 then
        -- 没有前缀
        return str
    end
    local strLen = string.len(str)
    if strLen <= #prefix then
        -- 替换的字符还没整个字符长呢
        return str
    end

    local newStr = str
    xpcall(
        function()
            local preCount = 0
            local index = 0
            while (index <= #str) do
                index = index + 1
                local curByte = string.byte(str, index)
                local num = util_SubStringGetByteCount(curByte)
                if num == 0 then
                    break
                end

                preCount = preCount + num
                if preCount >= #prefix then
                    break
                end
            end

            newStr = prefix .. string.sub(str, preCount + 1)
        end,
        function()
            newStr = str
        end
    )

    return newStr
end

--处理任务显示 "aaa%s1%s2" "%s1" {1}
--util_strReplaceBatch(desc,"%s",data.params)
function GD.util_strReplaceBatch(str, pattern, param)
    if not pattern then
        pattern = "%s"
    end
    if param and #param > 0 then
        for i = 1, #param do
            str = util_strReplace(str, pattern .. i, util_formatCoins(tonumber(param[i]), 12))
        end
    end
    return str
end

function GD.util_strListReplaceBatch(strList, pattern, param)
    if not pattern then
        pattern = "%s"
    end
    if param and #param > 0 then
        for i = 1, #param do
            for j = 1, #strList do
                if strList[j] == pattern .. i then
                    strList[j] = util_strReplace(strList[j], pattern .. i, util_formatCoins(tonumber(param[i]), 12))
                    break
                end
            end
        end
    end
    return strList
end

-- 字符串替换【不执行模式匹配】
-- s       源字符串
-- pattern 匹配字符串
-- repl    替换字符串
--
-- 成功返回替换后的字符串，失败返回源字符串
function GD.util_strReplace(s, pattern, repl)
    local i, j = string.find(s, pattern, 1, true)
    if i and j then
        local ret = {}
        local start = 1
        while i and j do
            table.insert(ret, string.sub(s, start, i - 1))
            table.insert(ret, repl)
            start = j + 1
            i, j = string.find(s, pattern, start, true)
        end
        table.insert(ret, string.sub(s, start))
        return table.concat(ret)
    end
    return s
end

--[[
@desc: 十六进制的色值转换成 十进制的 rgb
author:{author}
time:2022-02-09 15:44:16
--@_hex: 十六进制数值 -- 例如 #FFFFFF
@return: #FFFFFF -> color={r = 255 , g = 255 ,b = 255}

]]
function GD.util_changeHexToColor(_hex)
    local len = string.len(_hex)
    if len < 7 then -- 如果少于 7 位，直接返回默认色值
        return {r = 255, g = 255, b = 255}
    end

    -- 判断传入的 数值是否为 16位的色值
    if string.sub(_hex, 1, 1) ~= "#" then
        return {r = 255, g = 255, b = 255}
    end

    -- 将数值转换为可用的色位
    local to_color_bit = function(_color)
        _color = tonumber(_color)
        if _color and _color <= 255 then
            return _color
        end
        return 255
    end

    -- 将 16位转换为 10进制
    local str_to_hex_num = function(_hex)
        return tonumber(_hex, 16) or 255
    end

    local color = {
        r = to_color_bit(str_to_hex_num(string.sub(_hex, 2, 3))),
        g = to_color_bit(str_to_hex_num(string.sub(_hex, 4, 5))),
        b = to_color_bit(str_to_hex_num(string.sub(_hex, 6, 7)))
    }
    return color
end
