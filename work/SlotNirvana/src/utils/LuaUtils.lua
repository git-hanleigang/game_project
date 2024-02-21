-- 打印出tbl的所有(key, value)

-- 该函数主要功能是自动计算缩进层次打印出table内容

local tab_indent_count = 0
----
--打印table,并可以为table指定一个标记名称
--@param tname string table标记名称
--@param tbl table 打印的表
function GD.print_table(tname, tbl)
    if DEBUG < 2 then
        return
    end

    if (tname == nil or tbl == nil) then
        print('Error, in LuaUtil.lua file. You must pass "table name" and "table`s data" to print_table function.', tname)

        return
    end

    if tab_indent_count == 0 then
        print(string.format("===============================table-%s-begin===========================", tname))
    end

    local tabs = ""

    for i = 1, tab_indent_count do
        tabs = tabs .. "    "
    end

    local param_type = type(tbl)

    if param_type == "table" then
        for k, v in pairs(tbl) do
            -- 如果value还是一个table，则递归打印其内容

            --            if k~="class" then
            if (type(v) == "table") then
                print(string.format("T %s.%s", tabs, k))

                -- 子table加一个tab缩进

                tab_indent_count = tab_indent_count + 1

                print_table(k, v)

                -- table结束，则退回一个缩进

                tab_indent_count = tab_indent_count - 1
            elseif (type(v) == "number") then
                local i, f = math.modf(v)
                if f <= 0 then
                    print(string.format("N %s.%s: %d", tabs, k, v))
                else
                    print(string.format("N %s.%s: %.15f", tabs, k, v))
                end
            elseif (type(v) == "string") then
                print(string.format('S %s.%s: "%s"', tabs, k, v))
            elseif (type(v) == "boolean") then
                print(string.format("B %s.%s: %s", tabs, k, tostring(v)))
            elseif (type(v) == "nil") then
                print(string.format("N %s.%s: nil", tabs, k))
            else
                print(string.format("%s%s=%s: unexpected type value? type is %s", tabs, k, v, type(v)))
            end
        end
    --        end
    end

    if tab_indent_count == 0 then
        --        print("\n")
        print(string.format("===============================table-%s-end===========================\n", tname))
    end
end

---class标记名称,并可以为class标记名称
--@param cname string class标记名称
--@param cls userdata 要打印的class
function GD.print_class(cname, cls)
    if not _LOG_OUT_ then
        return
    end

    local showparent = false

    if (cname == nil or cls == nil) then
        print('Error, in LuaUtil.lua file. You must pass "table name" and "table`s data" to print_table function.')

        return
    end

    if tab_indent_count == 0 then
        print(string.format("===============================class-%s-begin===========================", cname))
    end

    local tabs = ""

    for i = 1, tab_indent_count do
        tabs = tabs .. "    "
    end

    local param_type = type(cls)

    if param_type == "table" then
        for k, v in pairs(cls) do
            -- 如果value还是一个table，则递归打印其内容

            if showparent or k ~= "class" then
                if (type(v) == "table") then
                    print(string.format("T %s.%s", tabs, k))

                    -- 子table加一个tab缩进

                    tab_indent_count = tab_indent_count + 1

                    if k ~= "__index" then
                        print_class(k, v, showparent)
                    end
                    -- table结束，则退回一个缩进

                    tab_indent_count = tab_indent_count - 1
                elseif (type(v) == "number") then
                    local i, f = math.modf(v)
                    if f <= 0 then
                        print(string.format("N %s.%s: %d", tabs, k, v))
                    else
                        print(string.format("N %s.%s: %.5f", tabs, k, v))
                    end
                elseif (type(v) == "string") then
                    print(string.format('S %s.%s: "%s"', tabs, k, v))
                elseif (type(v) == "boolean") then
                    print(string.format("B %s.%s: %s", tabs, k, tostring(v)))
                elseif (type(v) == "nil") then
                    print(string.format("N %s.%s: nil", tabs, k))
                else
                    print(string.format("%s%s=%s: unexpected type value? type is %s", tabs, k, v, type(v)))
                end
            end
        end
    end

    if tab_indent_count == 0 then
        --        print("\n")
        print(string.format("===============================class-%s-end===========================\n", cname))
    end
end

---class标记名称,并可以为class标记名称
--@param cname string class标记名称
--@param cls userdata 要打印的class
--@param showparent boolean 是否要打印该类的父类信息
function GD.print_class_all(cname, cls, showparent)
    if not _LOG_OUT_ then
        return
    end

    if (cname == nil or cls == nil) then
        print('Error, in LuaUtil.lua file. You must pass "table name" and "table`s data" to print_table function.')

        return
    end

    if tab_indent_count == 0 then
        print(string.format("===============================class-%s-begin===========================", cname))
    end

    local tabs = ""

    for i = 1, tab_indent_count do
        tabs = tabs .. "    "
    end

    local param_type = type(cls)

    if param_type == "table" then
        for k, v in pairs(cls) do
            -- 如果value还是一个table，则递归打印其内容

            if showparent or k ~= "class" then
                if (type(v) == "table") then
                    print(string.format("T %s.%s", tabs, k))

                    -- 子table加一个tab缩进

                    tab_indent_count = tab_indent_count + 1

                    if k ~= "__index" then
                        print_class(k, v, showparent)
                    end
                    -- table结束，则退回一个缩进

                    tab_indent_count = tab_indent_count - 1
                elseif (type(v) == "number") then
                    local i, f = math.modf(v)
                    if f <= 0 then
                        print(string.format("N %s.%s: %d", tabs, k, v))
                    else
                        print(string.format("N %s.%s: %.5f", tabs, k, v))
                    end
                elseif (type(v) == "string") then
                    print(string.format('S %s.%s: "%s"', tabs, k, v))
                elseif (type(v) == "boolean") then
                    print(string.format("B %s.%s: %s", tabs, k, tostring(v)))
                elseif (type(v) == "nil") then
                    print(string.format("N %s.%s: nil", tabs, k))
                else
                    print(string.format("%s%s=%s: unexpected type value? type is %s", tabs, k, v, type(v)))
                end
            end
        end
    end

    if tab_indent_count == 0 then
        --        print("\n")
        print(string.format("===============================class-%s-end===========================\n", cname))
    end
end

function GD.log(formatStr, ...)
    if not _LOG_OUT_ then
        return
    end

    if ... ~= nil then
        --        print ("log Error argc is nil 1")
        for _, v in pairs {...} do
            --            print ("log Error argc is nil 2",v)
            if v == nil then
                print("log Error argc is nil", formatStr, ...)
                return
            end
        end
    else
        print(formatStr)
        netloginfo(formatStr)
        return
    end
    print(string.format(formatStr, ...))
    netloginfo(string.format(formatStr, ...))
end

--和print用法完全一样，只不过加了一层控制而已
function GD.print_debug(formatStr, ...)
    if not _LOG_OUT_ then
        return
    end
    print(formatStr, ...)
end

---
-- lua层面继承  ， 这个只能实现模拟接口， 不能再类的定义中实现变量， 因为在copy过程中， 变量未初始化则不会被copy。
-- 如果要使用其实现多重继承， 那么必须将所有变量初始化。
--@param target table 子类
--@param parent table 要被扩展的基类
function GD.util_extendLua(target, parent)
    for k, v in pairs(parent) do
        --        if k~="extend" then
        --        log("k=%s", k)
        target[k] = v
        --        end
    end
end

function GD.createCCBNode(_ccb)
    local __proxy = cc.CCBProxy:create()
    local __owner = {}
    ccb[_ccb] = __owner
    local __node = CCBReaderLoad(_ccb .. ".ccbi", __proxy, __owner)
    local __anim = __owner["mAnimationManager"]
    __node.anim = __anim
    return __node, __anim
end

function GD.randomShuffle(_t)
    assert(type(_t) == "table", "param is wrong!")

    for k, v in ipairs(_t) do
        local __num = math.random(#_t)
        local __temp = _t[k]
        _t[k] = _t[__num]
        _t[__num] = __temp
    end
end

function GD.luaCallOCStaticMethod(className, functionName, params)
    local LuaOC = require("cocos.cocos2d.luaoc")
    params = params or {}
    local ok, ret = LuaOC.callStaticMethod(className, functionName, params)
    if ok then
        -- release_print(className .. ":" .. functionName .. " = " .. tostring(ret))
        ret = loadstring(string.format("return %s", ret))()
    else
        release_print(string.format("call oc function error!className:%s,functionName:%s", className, functionName))
        release_print(string.format("error ret %s", ret))
        release_print(debug.traceback())
    end
    return ok, ret
end

function GD.util_multiLanguage(node, text, fontSize)
    if not node then
        return
    end

    local isMulti = false
    -- 判断字符串是否要使用多国语言
    for i = 1, string.len(text) do
        local _byte = string.sub(text, i, i)
        local _value = string.byte(_byte)
        if _value < 33 or _value > 126 then
            isMulti = true
            break
        end
    end

    local mulNodeName = "txtMulLang_" .. node:getName()

    if isMulti then
        node:setVisible(false)
        local mulNode = node:getParent():getChildByName(mulNodeName)
        if not mulNode then
            -- 创建多国语言节点
            mulNode = cc.Label:create()
            mulNode:setName(mulNodeName)
            node:getParent():addChild(mulNode)
        end
        mulNode:setSystemFontSize(fontSize)
        mulNode:setPosition(cc.p(node:getPosition()))
        mulNode:setAnchorPoint(cc.p(node:getAnchorPoint()))
        mulNode:setString(text)
        node.mulNode = mulNode
    else
        local mulNode = node:getParent():getChildByName(mulNodeName)
        if mulNode then
            mulNode:removeFromParent()
            node.mulNode = nil
        end
        node:setString(text)
        node:setVisible(true)
    end
end

--尝试解析本地json文件
function GD.util_checkJsonDecode(jsonFilePath)
    local content = nil
    local strJsonData = cc.FileUtils:getInstance():getStringFromFile(jsonFilePath)
    if strJsonData == nil or string.len(strJsonData) <= 5 or string.find(strJsonData, "<html") ~= nil or string.find(strJsonData, "<HTML") ~= nil then -- 读取文件失败
        return content
    end
    xpcall(
        function()
            content = cjson.decode(strJsonData)
        end,
        function()
            content = nil
        end
    )
    return content
end

function GD.util_cjsonDecode(strJsonData)
    local content = {}
    strJsonData = strJsonData or ""
    if strJsonData == "" then
        return content
    end

    xpcall(
        function()
            content = cjson.decode(strJsonData)
        end,
        function(error)
            -- __G__TRACKBACK__(error)
            local sendErrMsg = ""
            -- local versionCode = 0
            -- if util_getUpdateVersionCode then
            --     versionCode = util_getUpdateVersionCode(false)
            --     sendErrMsg = "V" .. tostring(versionCode) .. "|"
            -- end
            sendErrMsg = sendErrMsg .. tostring(strJsonData) .. "|"
            sendErrMsg = sendErrMsg .. tostring(error)
            
            if DEBUG == 0 then
                -- release_print(error)
                -- gLobalBuglyControl:luaException(tostring(sendErrMsg), debug.traceback())
                if util_sendToSplunkMsg ~= nil then
                    util_sendToSplunkMsg("luaError", sendErrMsg)
                end
            else
                printError(sendErrMsg)
            end
            content = {}
        end
    )
    return content
end

--[[
    冒泡排序
    @params
    arr 待排序数组
    sortFunc 排序条件
]]
function GD.util_bubbleSort(arr, sortFunc)
    for index1 = 1, #arr do
        for index2 = 1, index1 do
            if sortFunc(arr[index1], arr[index2]) then
                arr[index1], arr[index2] = arr[index2], arr[index1]
            end
        end
    end
end

function GD.util_node_handler(_obj, _method)
    return function(...)
        if type(_obj) == "userdata" and tolua.isnull(_obj) then
            util_printLog("c++ 节点没了，别回调了!!")
            return
        end

        return _method(_obj, ...)
    end
end

math.randomseed(os.time())
