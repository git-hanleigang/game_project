SQTools = {}

--- 数字转换为字节
function SQTools.num2bytesTable(num, endian, signed, length)
    if num<0 and not signed then num=-num print"warning, dropping sign from number converting to unsigned" end
    local res={}
    local n = math.ceil(select(2,math.frexp(num))/8) -- number of bytes to be used.
    if signed and num < 0 then
        num = num + 2^n
    end
    for k=n,1,-1 do -- 256 = 2^8 bits per char.
    local mul=2^(8*(k-1))
    res[k]=math.floor(num/mul)
    num=num-res[k]*mul
    end
    assert(num==0)
    if(length and n < length) then
        n = length
        for i=#res + 1, n do
            res[i] = '0'
        end
    end
    if endian == "big" then
        local t={}
        for k=1,n do
            t[k]=res[n-k+1]
        end
        res=t
    end
    return res
end

function SQTools.num2bytes(num, endian, signed, length)
    local res = SQTools.num2bytesTable(num, endian, signed, length)
    return string.char(unpack(res))
end

--- 字节转换为数字
function SQTools.bytes2num(str, endian, signed) -- use length of string to determine 8,16,32,64 bits
    local t={str:byte(1,-1)}
    if endian=="big" then --reverse bytes
        local tt={}
        for k=1,#t do
            tt[#t-k+1]=t[k]
        end
        t=tt
    end
    local n=0
    for k=1,#t do
        n=n+t[k]*2^((k-1)*8)
    end
    if signed then
        n = (n > 2^(#t-1) -1) and (n - 2^#t) or n -- if last bit set, negative.
    end
    return n
end

--- 十六进制串转为字节
function SQTools.hexstr2bytes(str, endian, length)
    if(#str % 2 == 1) then
        str = "0" .. str
    end
    local ret = ""
    for i=#str-1,1,-2 do
        local b = string.sub(str, i, i + 1)
        -- log("", b, type(b))
        if(endian == "big") then
            ret = string.char(tonumber("0x" .. b)) .. ret
        else
            ret = ret .. string.char(tonumber("0x" .. b))
        end
    end
    if(length) then
        for i=#ret,length-1 do
            ret = '\0' .. ret
        end
    end
    return ret
end

function SQTools.num2byte(num)
    return SQTools.num2bytes(num, "big", false, 1)
end

function SQTools.num2short(num)
    return SQTools.num2bytes(num, "big", false, 2)
end

function SQTools.num2int(num)
    return SQTools.num2bytes(num, "big", false, 4)
end

function SQTools.num2long(num)
    return SQTools.num2bytes(num, "big", false, 8)
end

function SQTools.readnum(data, index, length)
    local c = string.sub(data, index, index + length - 1)
    return SQTools.bytes2num(c, "big", false)
end

function SQTools.readbyte(data, index)
    return SQTools.readnum(data, index, 1)
end

function SQTools.readshort(data, index)
    return SQTools.readnum(data, index, 2)
end

function SQTools.readint(data, index)
    return SQTools.readnum(data, index, 4)
end

function SQTools.readlong(data, index)
    return SQTools.readnum(data, index, 8)
end

--- 格式化为十六进制数
function SQTools.hex(num)
    return string.format("%02X", num)
end

--- 数组转表
function SQTools.convertToTable(array)
    local ret = {}
    for i,v in pairs(array) do
        ret[v] = i
    end
    return ret
end

--- 表转数组，原key保存为__srcKey
function SQTools.convertToArray(tbl)
    local ret = {}
    for i,v in pairs(tbl) do
        v.__srcKey = i
        table.insert(ret, v)
    end
    return ret
end

--- 精简掉数组中相同的元素
function SQTools.distinct(array)
    local have = {}
    local ret = {}
    for i,v in pairs(array) do
        if(not have[v]) then
            table.insert(ret, v)
        end
        have[v] = true
    end
    return ret
end

-- 两个表进行比较
function SQTools.compareTable( tbl1, tbl2 )
    for k, v in pairs( tbl1 ) do
        if ( type(v) == "table" and type(tbl2[k]) == "table" ) then
            if (not SQTools.compareTable( v, tbl2[k] ) ) then return false end
        else
            if ( v ~= tbl2[k] ) then return false end
        end
    end
    for k, v in pairs( tbl2 ) do
        if ( type(v) == "table" and type(tbl1[k]) == "table" ) then
            if (not SQTools.compareTable( v, tbl1[k] ) ) then return false end
        else
            if ( v ~= tbl1[k] ) then return false end
        end
    end
    return true
end

function SQTools.sortTable(tbl)
    local keys = table.keys(tbl)
    local ret = {}
    table.sort(keys)
    for i,v in pairs(keys) do
        ret[v] = tbl[v]
    end
    return ret
end

-- 把数组转为table，idName默认为"id"，可传入自定义函数
function SQTools.convertToTableById(array, idName)
    idName = idName or "id"
    local ret = {}
    for i,v in pairs(array) do
        local id = nil
        if(type(idName) == "string") then
            id = v[idName]
        elseif(type(idName) == "function") then
            id = idName(v)
        end
        ret[id] = v
    end
    return ret
end

--转换为字符串table
function SQTools.convertToCharTable(text)
    assert(text, "convertToCharTable with null")
    local chars = {}
    for uchar in string.gmatch(text, "[%z\1-\127\194-\244][\128-\191]*") do
        chars[#chars+1] = uchar
    end
    return chars
end

-- 把value限制在[min, max]之间
function SQTools.limit(value, min, max)
    return math.min(math.max(value, min), max)
end

--按比例分配值
function SQTools.lerp(value,min,max)
    return min + (max - min) * SQTools.limit(0,1,value)
end

--获取枚举值
-- function SQTools.getProtoEnumID(name,msgid)
--     return protobuf.enum_id("net_protocol."..tostring(name),msgid)
-- end

--获取范围随机值
-- function SQTools.rangeRandom(min,max)
--     local randomInstance = SQTools.__random
--     if randomInstance == nil then
--         randomInstance = SQRandom:create(os.time())
--         SQTools.__random = randomInstance
--     end
--     return randomInstance:rangeRandom(min,max)
-- end

-- function SQTools.getUUID(tb)
--     if tb.__preUUID == nil then
--         tb.__preUUID = ""
--     end
--     if tb.__uuid == nil then
--         tb.__uuid = 0
--     elseif tb.__uuid >= 1000000 then
--         tb.__preUUID = tb.__preUUID..tb.__uuid.."_"
--         tb.__uuid = 0
--     end
--     tb.__uuid = tb.__uuid + 1
--     return tb.__preUUID..tostring(tb.__uuid)
--  end

--[[--将百兆以下数字转化为数字加汉字标识（不遵循四舍五入，余下抹除）
function SQTools.toCoverNumber(number,color,isRich)
    local wei = SQShowWords.Number.bai
    local str = "0"
    if number == nil or number <= 0 then
        return "0"
    end
    if number < 1000 then
        str = number
        wei = SQShowWords.Number.hundred
        return string.format("%s%s", str,wei)
    elseif number >= 1000 and number < 10000 then
        str = number / 1000
        wei = SQShowWords.Number.thousand
    elseif number >= 10000 and number < 1000000 then
        str = number / 10000
        wei = SQShowWords.Number.million
    elseif number >= 1000000 and number < 100000000 then
        str = number / 1000000
        wei = SQShowWords.Number.hmillion
    elseif number >= 100000000 and number < 1000000000 then
        str = number / 100000000
        wei = SQShowWords.Number.calculate
    elseif number >= 1000000000 and number < 10000000000 then
        str = number / 1000000000
        wei = SQShowWords.Number.tcalculate
    elseif number >= 10000000000 and number < 1000000000000 then
        str = number / 10000000000
        wei = SQShowWords.Number.hcalculate
    elseif number >= 1000000000000 and number < 10000000000000 then
        str = number / 1000000000000
        wei = SQShowWords.Number.omen
    elseif number >= 10000000000000 and number < 100000000000000 then
        str = number / 10000000000000
        wei = SQShowWords.Number.tomen
    else 
        str = string.format("%s%s", str,wei)
    end
    -- local starPos = string.find(str,'.')
    -- if starPos ~= nil then
    --     str = string.sub(str,0,starPos + 3)
    -- end
    str = math.floor(tonumber(tostring(str * 100))) / 100
    str = SQTools.formatPointNumber(tonumber(str),2)
    if isRich then
        str = string.format("[color=" .. color .. "]%s[/color][color=" .. color .."]%s[/color]", str,wei)
    else
        str = string.format("%s%s", str,wei)
    end
    return str
end]]

--
function SQTools.toCoverNumberEN(num,deperator)  
    local str1 =""  
    local str = tostring(num)  
    local strLen = string.len(str)    
          
    deperator = deperator or ","

    for i=1,strLen do  
        str1 = string.char(string.byte(str,strLen+1 - i)) .. str1  
        if math.mod(i,3) == 0 then  
            --下一个数 还有  
            if strLen - i ~= 0 then  
                str1 = ","..str1  
            end  
        end  
    end  
    return str1  
end

function SQTools.toCoverNumber(value,color,isRich)
    local str = tostring(value)
    if value > 10000 and value <= 10000000 then
        str = tostring(math.floor(value / 1000)).."K"
    elseif value > 10000000 and value <= 10000000000 then
        str = tostring(math.floor(value / 1000000)).."M"
    elseif value > 10000000000 and value <= 10000000000000 then
        str = tostring(math.floor(value / 1000000000)).."B"
    elseif value > 10000000000000 then
        str = tostring(math.floor(value / 1000000000000)).."T"
    end
    if isRich then
        str = string.format("[color=" .. tostring(color) .. "]%s[/color]",str)
    end
    return str
end

--保留小数点后多少位（遵循四舍五入原则）
function SQTools.formatPointNumber(value,saveBit)
    if saveBit > 0 then
        local bitString = string.format("%."..saveBit.."f",value)
        for i = string.len(bitString),1,-1 do
            local lastBitByte = tonumber(string.byte(bitString,i))
            --去除尾数0
            if lastBitByte == 48 then
                bitString = string.sub(bitString,0,string.len(bitString) - 1)
            else
                break
            end
        end
        local bitStringLen = string.len(bitString)
        --去除结尾的"."
        if string.byte(bitString,bitStringLen) == 46 then
            bitString = string.sub(bitString,0,bitStringLen - 1)
        end
        return bitString
    end
    return value
end

-- function SQTools.calculatorToNowTime( time )
--     local nTime = gApp:getServerTime(true)
--     local mTime = time - nTime
--     local cTime = math.floor(mTime / 1000)
--     local difTime = {}
--     difTime.year = math.floor( cTime / 31536000 )
--     difTime.month = math.floor( (cTime - difTime.year * 31536000) / 2592000 )
--     difTime.day = math.floor( (cTime - difTime.year * 31536000 - difTime.month * 2592000) / 86400 )
--     difTime.hour = math.floor( (cTime - difTime.year * 31536000 - difTime.month * 2592000 - difTime.day * 86400) / 3600)
--     difTime.min = math.floor( (cTime - difTime.year * 31536000 - difTime.month * 2592000 - difTime.day * 86400 - difTime.hour * 3600) / 60)
--     difTime.sec = math.floor( (cTime - difTime.year * 31536000 - difTime.month * 2592000 - difTime.day * 86400 - difTime.hour * 3600 - difTime.min * 60) / 1)
--     return difTime,mTime <= 0-- 后面的值如果为true，表示时间已经到了
-- end

-- function SQTools.coverLastToString(time, type )
--     local isInclude = {}
--     isInclude.year = string.find(type,"Y")
--     isInclude.month = string.find(type,"M")
--     isInclude.day = string.find(type,"D")
--     isInclude.hour = string.find(type,"H")
--     isInclude.min = string.find(type,"m")
--     isInclude.sec = string.find(type,"S")
--     local difTime = SQTools.calculatorToNowTime( time )
--     local strTime = ""

--     if year then
--         strTime =string.format("%s%d%s",strTime,difTime.year,SQShowWords.Time.year)
--     end
--     if month then
--         strTime = string.format("%s%d%s",strTime,difTime.month,SQShowWords.Time.month)
--     end
--     if day then
--         strTime = string.format("%s%d%s",strTime,difTime.day,SQShowWords.Time.day)
--     end
--     if hour then
--         strTime = string.format("%s%d%s",strTime,difTime.hour,SQShowWords.Time.hour)
--     end
--     if min then
--         strTime = string.format("%s%d%s",strTime,difTime.min,SQShowWords.Time.min)
--     end
--     if sec then
--         strTime = string.format("%s%d%s",strTime,difTime.sec,SQShowWords.Time.sec)
--     end
--     return strTime

-- end

function SQTools.convertToMemoryList(memory)
    memory = math.ceil(memory)
    -- local m = math.floor(memory / (1024 * 1024))
    -- local k = math.ceil((memory - m * (1024 * 1024)) / 1024)
    -- return {m,k}
    local m = math.ceil(memory / (1024 * 1024) * 100) / 100
    m = SQTools.formatPointNumber(m,2)
    local k = 0
    return {m,k}
end

function SQTools.getMemoryString(memory)
    local foo = SQTools.convertToMemoryList(memory)
    local bar = {
        "M",
        "K"
    }
    local str = nil
    for i,v in pairs(foo) do
        if (v ~= 0) then
            str = v .. bar[i]
            if (foo[i + 1] and foo[i + 1] ~= 0) then
                str = str .. foo[i + 1] .. bar[i + 1]
            end
            break
        end
    end
    if (not str) then
        str = "0K"
    end
    return str
end

function SQTools.convertTimeList(seconds)
    seconds = math.floor(seconds)
    local s = (seconds % 60)
    local m = ((seconds - s) / 60) % 60
    local h = ((seconds - s - m * 60) / 3600) % 24
    local d = (seconds - s - m * 60 - h * 3600) / (24 * 3600)
    return {d,h,m,s}
end

function SQTools.convertTimeList2(seconds)
    seconds = math.floor(seconds)
    local s = (seconds % 60)
    local m = ((seconds - s) / 60) % 60
    local h = math.floor(seconds / 3600)
    local d = 0
    return {d,h,m,s}
end

-- function SQTools.getUnixTime2Date(unixTime)
--     if not unixTime then
--         unixTime = gApp:getServerTime(true)/1000
--     end
--     local tb = {}
--     tb.year = tonumber(os.date("%Y",unixTime))
--     tb.month =tonumber(os.date("%m",unixTime))
--     tb.day = tonumber(os.date("%d",unixTime))
--     tb.hour = tonumber(os.date("%H",unixTime))
--     tb.minute = tonumber(os.date("%M",unixTime))
--     tb.second = tonumber(os.date("%S",unixTime))
--     return tb
-- end

-- 获取时间串
--   时间区间（秒） 时间单位    显示格式    举例
--   n＜60    秒   数字+时间单位（秒）  50秒
--   60≤n＜3600   分钟  数字+时间单位（分钟+秒）   50分钟10秒
--   3600≤n  小时  数字+时间单位（小时+分），秒不显示  1小时30分
--   86400≤n 天   数字+时间单位（天+消失），分、秒不显示    1天2小时
-- function SQTools.getTimeString(seconds)
--     local foo = SQTools.convertTimeList(seconds)
--     local bar = {
--         SQShowWords.Time.day, 
--         SQShowWords.Time.hour,
--         SQShowWords.Time.min,
--         SQShowWords.Time.sec
--     }
--     local str = nil
--     for i,v in pairs(foo) do
--         if(v ~= 0) then
--             str = v .. " " .. bar[i]
--             if(foo[i + 1] and foo[i + 1] ~= 0) then
--                 str = str .. " " .. foo[i + 1] .. " " .. bar[i + 1]
--             end
--             break
--         end
--     end
--     if(not str) then
--         str = SQShowWords.Information.nullString
--     end
--     return str
-- end

function SQTools.getTimeStringStandard(seconds)
    local foo = SQTools.convertTimeList(seconds)
    while(#foo > 2 and foo[1] == 0) do
        table.remove(foo, 1)
    end
    local ret = "--"
    if(#foo == 3) then
        ret = string.format("%01d:%02d:%02d", unpack(foo))
    elseif(#foo == 2) then
        ret = string.format("%01d:%02d", unpack(foo))
    elseif(#foo == 4) then
        ret = string.format("%01d:%01d:%02d:%02d",unpack(foo))
    end
    return ret
end

function SQTools.getTimeStringStandard2(seconds)
    local foo = SQTools.convertTimeList(seconds)
    while(#foo > 3 and foo[1] == 0) do
        table.remove(foo, 1)
    end
    local ret = "--"
    if(#foo == 3) then
        ret = string.format("%02d:%02d:%02d", unpack(foo))
    elseif(#foo == 2) then
        ret = string.format("%02d:%02d", unpack(foo))
    elseif(#foo == 4) then
        ret = string.format("%01d:%01d:%02d:%02d",unpack(foo))
    end
    return ret
end

function SQTools.getTimeStringStandard3(seconds)
    local foo = SQTools.convertTimeList2(seconds)
    while(#foo > 3 and foo[1] == 0) do
        table.remove(foo, 1)
    end
    local ret = "--"
    if(#foo == 3) then
        ret = string.format("%02d:%02d:%02d", unpack(foo))
    elseif(#foo == 2) then
        ret = string.format("%02d:%02d", unpack(foo))
    elseif(#foo == 4) then
        ret = string.format("%01d:%01d:%02d:%02d",unpack(foo))
    end
    return ret
end

-- function SQTools.getTimeStringLast(seconds)
--     local timeStr = SQShowWords.Time2.moment
--     if(seconds > 60) then
--         local foo = SQTools.convertTimeList(seconds)
--         local bar = {
--             SQShowWords.Time2.day, 
--             SQShowWords.Time2.hour,
--             SQShowWords.Time2.min,
--             SQShowWords.Time2.sec
--         }
--         for i,v in pairs(foo) do
--             if(v ~= 0) then
--                 timeStr = v .. bar[i]
--                 timeStr = timeStr .. SQShowWords.Time2.before
--                 break
--             end
--         end
--     end
--     return timeStr
-- end

-- function SQTools.getTimeStringLave(seconds)
--     local timeStr = ""
--     local foo = SQTools.convertTimeList(seconds)
--     local bar = {
--         SQShowWords.Time2.day, 
--         SQShowWords.Time2.hour,
--         SQShowWords.Time2.min,
--         SQShowWords.Time2.sec
--     }
--     for i,v in pairs(foo) do
--         if(v ~= 0) then
--             timeStr = v .. bar[i]
--             timeStr = timeStr
--             break
--         end
--     end
--     return timeStr
-- end

function SQTools.getTimeStringLaveEN(seconds)
    local timeStr = ""
    local foo = SQTools.convertTimeList(seconds)
    local bar = {
        "d", 
        "h",
        "m",
        "s"
    }
    for i,v in pairs(foo) do
        if(v ~= 0) then
            timeStr = v .. bar[i]
            -- timeStr = timeStr
            break
        end
    end
    return timeStr
end

--"[size=34]23[/size][size=26]小时[/size][size=34]16[/size][size=26]分[/size]"
-- function SQTools.getTimeRichString(seconds,numSize,strSize)
--     local foo = SQTools.convertTimeList(seconds)
--     local bar = {
--         SQShowWords.Time.day, 
--         SQShowWords.Time.hour,
--         SQShowWords.Time.min,
--         SQShowWords.Time.sec
--     }
--     for k,v in pairs(bar) do
--         v = string.format("[size=%d]%s[/size]",strSize,v)
--     end
--     for k,v in pairs(foo) do
--         v = string.format("[size=%d]%s[/size]",numSize,tostring(v))
--     end
--     local str = nil
--     for i,v in pairs(foo) do
--         if(v ~= 0) then
--             str = v .. bar[i]
--             if(foo[i + 1] and foo[i + 1] ~= 0) then
--                 str = str .. foo[i + 1] .. bar[i + 1]
--             end
--             break
--         end
--     end
--     if(not str) then
--         str = SQShowWords.Information.nullString
--     end
--     return str
-- end

function SQTools.checkTextIsChinese(text)
    for i = 1,string.len(text) do
        local byte = string.byte(string.sub(text,i,i))
        if byte > 127 then
            return true
        end
    end
    return false
end


--获取字符长度（中文2个 英文1个）
function SQTools.getStringLen(str)
    local count = 0  
    for uchar in string.gfind(str, "([%z\1-\127\194-\244][\128-\191]*)") do     
        if #uchar ~= 1 then      
            count = count +2    
        else      
            count = count +1    
        end  
    end
    return count
end

--获得居中对齐坐标列表
function SQTools.getMidAlignPosList(width,perWidth,gapWidth,count)
    local firstPos = (width - (count - 1) * (perWidth + gapWidth / 2)) / 2
    local tb = {}
    for i = 1,count do
        table.insert(tb,firstPos + (i - 1) * (perWidth + gapWidth / 2))
    end
    return tb
end

function SQTools.getLuaMemory()
    return collectgarbage("count") / 1024
end

-- function SQTools.getAssetsMemoryInfo(detail)
--     local infos = {}
--     -- Cocos2dx缓存的文件
--     local info = cc.Director:getInstance():getTextureCache():getCachedTextureInfo()
--     local infos1 = string.split(info, "\n")
--     infos1[#infos1] = nil
--     infos1[#infos1] = nil
--     for i,v in pairs(infos1) do
--         local index = string.find(v, "res", 1, true)
--         if(index) then
--             local file = "\"" .. string.sub(v, index)
--             infos1[i] = file
--         end
--     end
--     table.insertto(infos, infos1)
--     -- FGUI缓存的文件
--     if(fgui.UIPackage.getCachedTextureInfo) then
--         local info = fgui.UIPackage:getCachedTextureInfo()
--         local infos2 = string.split(info, "\n")
--         infos2[#infos2] = nil
--         infos2[#infos2] = nil
--         table.insertto(infos, infos2)
--     end
--     -- 归整
--     table.sort(infos)
--     local total = 0
--     local other = 0
--     local keys = {
--         "fgui", "spine", "scene", "ui"
--     }
--     local nums = {}
--     if(detail) then
--         print("CACHED TEXTURES:" .. table.nums(infos))
--     end
--     for i,v in pairs(infos) do
--         if(detail) then
--             print("\t", v)
--         end
--         local sbegin = string.find(v, "=> ", -12)
--         local k = string.sub(v, sbegin + 3, -4)
--         local kbs = tonumber(k) / 1000
--         total = total + kbs
--         local findout = false
--         for i,p in pairs(keys) do
--             if(string.find(v, p, 4, true)) then
--                 nums[p] = (nums[p] or 0) + kbs
--                 findout = true
--                 break
--             end
--         end
--         if(not findout) then
--             other = other + kbs
--         end
--     end
--     local ret = {}
--     for i,v in pairs(keys) do
--         if(nums[v]) then
--             table.insert(ret, {v, nums[v]})
--         end
--     end
--     table.sort(ret, function(a, b)
--         if(a[2] > b[2]) then
--             return true
--         end
--     end)
--     if(other > 0) then
--         table.insert(ret, {"other", other})
--     end
--     table.insert(ret, 1, {"ASSERT", total})
--     if(detail) then
--         print("Assert占用(MB)：" .. total)
--         print(json.encode(ret))
--     end
--     return total, ret, infos
-- end