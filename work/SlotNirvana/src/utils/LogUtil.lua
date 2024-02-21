
-- FIX IOS 139
function GD.dump_value_disk(v)
    if type(v) == "string" then
        v = "\"" .. v .. "\""
    end
    return tostring(v)
end

function GD.dumpStrToDisk(value, description, nesting)
    if device.platform ~= "mac" then
        return
    end
    
    if type(nesting) ~= "number" then nesting = 3 end

    local lookupTable = {}
    local result = {}

    local traceback = string.split(debug.traceback("", 2), "\n")
    --print("dump from: " .. string.trim(traceback[3]))

    local function dump_(value, description, indent, nest, keylen)
        description = description or "<var>"
        local spc = ""
        if type(keylen) == "number" then
            spc = string.rep(" ", keylen - string.len(dump_value_disk(description)))
        end
        if type(value) ~= "table" then
            if description ~= "<var>" then
                result[#result +1 ] = string.format("%s%s%s = %s", indent, dump_value_disk(description), spc, dump_value_disk(value))
            else
                result[#result +1 ] = string.format("%s", dump_value_disk(value))
            end
        elseif lookupTable[tostring(value)] then
            result[#result +1 ] = string.format("%s%s%s = *REF*", indent, dump_value_disk(description), spc)
        else
            lookupTable[tostring(value)] = true
            if nest > nesting then
                result[#result +1 ] = string.format("%s%s = *MAX NESTING*", indent, dump_value_disk(description))
            else
                result[#result +1 ] = string.format("%s%s = {", indent, dump_value_disk(description))
                local indent2 = indent.."    "
                local keys = {}
                local keylen = 0
                local values = {}
                for k, v in pairs(value) do
                    keys[#keys + 1] = k
                    local vk = dump_value_disk(k)
                    local vkl = string.len(vk)
                    if vkl > keylen then keylen = vkl end
                    values[k] = v
                end
                table.sort(keys, function(a, b)
                    if type(a) == "number" and type(b) == "number" then
                        return a < b
                    else
                        return tostring(a) < tostring(b)
                    end
                end)
                for i, k in ipairs(keys) do
                    dump_(values[k], k, indent2, nest + 1, keylen)
                end
                result[#result +1] = string.format("%s}", indent)
            end
        end
    end
    dump_(value, description, " ", 1)

    easyWriteFileLog( result )
end



--[[pathmode:
　　"r": 读模式 (默认);
　　"w": 写模式;
　　"a": 添加模式;
　　"r+": 更新模式，所有之前的数据将被保存
　　"w+": 更新模式，所有之前的数据将被清除
　　"a+": 添加更新模式，所有之前的数据将被保存,只允许在文件尾进行添加
　　"b": 某些系统支持二进制方式
]]--

function GD.easyWriteFileLog(content)
    if device.platform == "mac" then 
        local mode = "a+"
        -- local path = fileLogPath.."/log/fileLog.lua"
        -- local path = getSlotWritePath().."/log/fileLog.lua"
        
        local path = "/Users/js/Desktop/111.lua"

        local file = io.open(path, mode)
        if file then  
            local sTime = os.date("%Y-%m-%d %H:%M:%S", os.time())
            file:write(sTime.."\r\n")

            for i, line in ipairs(content) do
                local sLine = line.."\r\n"
                if file:write(sLine) == nil then 
                    return false 
                end  
            end

            io.close(file)
            return true  
        else  
            return false  
        end
    end
end

-- print on all mode --
function GD.cclog( msg )
    if DEBUG > 1 then
        print( "XCYY----------------->"..msg )
    end
end

--[[
    日志打印
]]
function GD.util_printLog(msg,isRelease)
    if DEBUG == 0 and isRelease then
        release_print(msg)
    elseif DEBUG == 2 then
        print(msg)
    end
end

--[[
    将lua对象转化为json字符串并打印
    @isRelease: 是否在线上环境进行打印
]]
function GD.util_printTable(table,isRelease)
    if not table then
        return
    end
    if not next(table) then
        return
    end

    local json = cjson.encode(table)
    util_printLog(json,isRelease)
end

--[[
    分段打印过长数据
]]
function GD.util_printLongMsgData(str)
    if not str then
        return
    end
    --分割打印字符串
    local strLen = string.len(str)
    local maxLen = 900
    local curLen = 0
    if strLen > maxLen then
        util_printLog("分段打印server数据:",true)

        for index = 1, math.ceil(strLen / maxLen) do
            local str = ""
            if curLen + maxLen < strLen then
                str = string.sub(str, curLen, curLen + maxLen)
                curLen = curLen + maxLen + 1
            else
                str = string.sub(str, curLen, -1)
                curLen = strLen
            end

            util_printLog(str,true)
        end
    end
end

-- print on a simple table --
function GD.dump_table( tb , sInfo )
    local msg = "XCYY----------------->"..sInfo
    for i,v in ipairs(tb) do
        msg = msg.." ["..i.."] = "..v
    end
    print( msg )
end

-- print on screen --
function GD.G_ShowMsg( msg )
    local scene = display.getRunningScene()
    if not scene then
    	return 
    end
    local msgText = scene:getChildByTag( 99901 )
    if not msgText then
    	msgText = ccui.Text:create()
    	scene:addChild( msgText )
    	msgText:setTag( 99901 )
    	msgText:setLocalZOrder( 99999 )
    	msgText:setFontSize( 30 )
    end
    msgText:setString( msg )
    msgText:setPosition( display.cx,display.cy + 100 )
    msgText:setVisible( true )
    msgText:stopAllActions()
    local move_by = cc.MoveBy:create( 2,cc.p( 0,50) )
    local vi_call = cc.CallFunc:create( function()
    	msgText:setVisible( false )
    end )
    local seq = cc.Sequence:create({ move_by,vi_call })
    msgText:runAction( seq )
end

--[[数字滚动
    label数字对象
    startValue起始数字值
    endValue结束数字值
    addValue数字每次增加值
    spendTime数字变动间隔时间
    labelSize数字对象的大小宽，大于范围就缩放
    labelScale数字默认初始缩放，即原始缩放大小
    endCallBack滚动结束回调函数
    sound声音
--]]
function GD.util_jumpNumInSize(label, startValue, endValue, addValue, spendTime, labelSizeWidth, labelScale, endCallBack, sound, dtCallFunc)
    if not label then
        return
    end
    if labelScale == nil then
        labelScale = 1
    end
    label:unscheduleUpdate()
    local curValue = startValue
    label._newNumValue = curValue
    label:setString(util_getFromatMoneyStr(curValue))
    util_formatStringScale(label, labelSizeWidth, labelScale)
    if startValue >= endValue then
        return
    end

    label._curTime = 0
    local function update(dt)
        if curValue >= endValue then
            curValue = endValue
            label:unscheduleUpdate()

            label._newNumValue = curValue
            label:setString(util_getFromatMoneyStr(curValue))
            util_formatStringScale(label, labelSizeWidth, labelScale)
            
            if dtCallFunc then
                dtCallFunc()
            end

            if endCallBack then
                endCallBack()
            end
            return
        end
        label._curTime = label._curTime + dt
        if label._curTime >= spendTime then
            label._curTime = 0
            curValue = curValue + addValue

            label._newNumValue = curValue
            label:setString(util_getFromatMoneyStr(curValue))
            util_formatStringScale(label, labelSizeWidth, labelScale)

            if dtCallFunc then
                dtCallFunc()
            end

            if sound then
                G_GetSoundModel():playSound(sound)
            end
        end
    end
    label:onUpdate(update)
end
--[[
    @desc: 限定字符串宽度缩放
    author:{author}
    time:2019-11-28 18:54:57
    --@node: 文字节点
	--@maxWidth: 最大显示宽度
	--@initScale: 初始缩放
    @return: 坐标值的表
]]
function GD.util_formatStringScale (node, maxWidth, initScale)
    if not maxWidth or type(maxWidth) ~= "number" then
        return
    end
    -- 初始缩放
    initScale = initScale or 1
    -- 显示宽度
    local _width = node:getContentSize().width
    if _width <= maxWidth then
        node:setScale(initScale)
    else
        node:setScale(maxWidth / _width * initScale)
    end
end


--盘面初始数据
function GD.util_saveStrLogToFile(_str)
    local attJson  = _str
    local path = cc.FileUtils:getInstance():getWritablePath()
    local f = io.open(path .. "StrLogFile.lua", "w+")
    f:write(attJson)
    f:close()
end

function GD.util_logAssert(_str)
    if device.platform == "mac" and DEBUG == 2 then
        local str = _str or "传入值为空"
        assert(false,str)
    end
end

function GD.util_logDevAssert(_str)
    local str = _str or "传入值为空"
    if  DEBUG == 2 then
        assert(false,str)
    end
end