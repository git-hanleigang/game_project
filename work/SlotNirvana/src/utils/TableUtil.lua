---
-- 处理所有基于table 的函数
--

---
--获取table的长度，尤其是k,v形式的table
--@param tab table table
function GD.table_length(tab)
    if tab == nil then
        printInfo("xcyy : %s","table_length tab is nil")
    	return 0
    end
    local length = 0
    for key, value in pairs(tab) do
        length = length + 1
    end
    return length
end

---
--将多个table连接为1个，注：key相同时覆盖
function GD.join_table(...)
    local tb = {}

    for _, atb in pairs{...} do
        for k,v in pairs(atb) do
            --            table.insert(tb,v)
            tb[k] = v
        end
    end

    return tb

end

---------------  工具类创建二维和三维数组， 这种级别基本就够用了  ， 这些工具谨慎使用 ，
-- ！！！！！ 尽量使用 arr = {1,4,5,6,7} 这种预分配的方式来初始化， 如果感觉预初始化的方式很麻烦，再用下面这三个函数
---
-- 创建一维数组并用 value 填充
function GD.table_createArr(col,defaultValue)
    local arr = {}
    for i=1, col, 1 do
    	local superType = type(defaultValue)
    	if superType == "function" or superType == "table" then -- 创建class 类型的 数据结构，
            if defaultValue then
                if defaultValue.__ctype == 1 then
                    arr[i] = defaultValue:create()
                elseif defaultValue.__ctype == 2 then
                    arr[i] = defaultValue.new()
                end
            end
        else -- 普通类型
            arr[i] = defaultValue
        end
    end

   return arr
end
function GD.table_createSymbolLocalArr(col)
    local arr = {}
    for i=1, col, 1 do
        arr[i] = {iRowIdx = -1,iColumnIdx = -1}
    end

    return arr
end


---
-- 创建二维数组
--
-- @param defaultValue 默认值初始化， 可以是任意值
function GD.table_createTwoArr(row,col,defaultValue)

    local mutilArr = {}
    for i = 1, row, 1 do
        mutilArr[i] = {}
        for j = 1, col, 1 do
            local superType = type(defaultValue)

            if superType == "function" or superType == "table" then -- 创建class 类型的 数据结构，
                if defaultValue then
                    if defaultValue.__ctype == 1 then
                        mutilArr[i][j] = defaultValue:create()
            		elseif defaultValue.__ctype == 2 then
                        mutilArr[i][j] = defaultValue.new()
            		end
            	end
            else -- 普通类型
                mutilArr[i][j] = defaultValue
            end
        end
    end

    return mutilArr
end

---
-- 创建三维数组
-- @param defaultValue 默认值
function GD.table_createThreeArr(row,row2,row3,defaultValue)

    local mutilArr= {}
    for i = 1, row , 1 do
        mutilArr[i]  = {}
        for j = 1, row2, 1 do
            mutilArr[i][j]  = {}
            for k = 1, row3, 1 do
                -- 创建值
                local superType = type(defaultValue)

                if superType == "function" or superType == "table" then -- 创建class 类型的 数据结构，
                    if defaultValue then
                        if defaultValue.__ctype == 1 then
                            mutilArr[i][j] = defaultValue:create()
                        elseif defaultValue.__ctype == 2 then
                            mutilArr[i][j] = defaultValue.new()
                        end
                end
                else -- 普通类型
                    mutilArr[i][j] = defaultValue
                end
                -- 创建值 end

            end
        end
    end

    return mutilArr
end
---
-- 清空table 用 nil的方式
--
function GD.table_clear(tableT)

    for i = 1, #tableT do
    	tableT[i] = nil
    end

end


function GD.table_nums(t)
    local count = 0
    for k, v in pairs(t) do
        count = count + 1
    end
    return count
end

function GD.table_keys(hashtable)
    local keys = {}
    for k, v in pairs(hashtable) do
        keys[#keys + 1] = k
    end
    return keys
end

function GD.table_values(hashtable)
    local values = {}
    for k, v in pairs(hashtable) do
        values[#values + 1] = v
    end
    return values
end

function GD.table_merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
end

function GD.table_insertto(dest, src, begin)
    begin = checkint(begin)
    if begin <= 0 then
        begin = #dest + 1
    end

    local len = #src
    for i = 0, len - 1 do
        dest[i + begin] = src[i + 1]
    end
end

function GD.table_indexof(array, value, begin)
    for i = begin or 1, #array do
        if array[i] == value then return i end
    end
    return false
end

function GD.table_keyof(hashtable, value)
    for k, v in pairs(hashtable) do
        if v == value then return k end
    end
    return nil
end

function GD.table_removebyvalue(array, value, removeall)
    local c, i, max = 0, 1, #array
    while i <= max do
        if array[i] == value then
            table.remove(array, i)
            c = c + 1
            i = i - 1
            max = max - 1
            if not removeall then break end
        end
        i = i + 1
    end
    return c
end

function GD.table_removeByCond(tb,removeAll,func)
    local index = 1
    while index <= #tb do
        if func(index,tb[index]) then
            table.remove(tb,index)
            if not removeAll then
                break
            end
        else
            index = index + 1
        end
    end
end

function GD.table_map(t, fn)
    for k, v in pairs(t) do
        t[k] = fn(v, k)
    end
end

function GD.table_walk(t, fn)
    for k,v in pairs(t) do
        fn(v, k)
    end
end

function GD.table_filter(t, fn)
    for k, v in pairs(t) do
        if not fn(v, k) then t[k] = nil end
    end
end

function GD.table_unique(t, bArray)
    local check = {}
    local n = {}
    local idx = 1
    for k, v in pairs(t) do
        if not check[v] then
            if bArray then
                n[idx] = v
                idx = idx + 1
            else
                n[k] = v
            end
            check[v] = true
        end
    end
    return n
end
--copy
function GD.copyTable(org, res)
    for k,v in pairs(org) do
        if type(v) ~= "table" then
            res[k] = v;
        else
            res[k] = {};
            copyTable(v, res[k])
        end
    end
end

--随机取数组里的几个值 valueNum取值的个数
function GD.randGetValueByTab(tab,valueNum)
    if type(tab) ~= "table" then
        return nil
    end
    if valueNum == nil then
        valueNum = 1
    end
    local temTab = {}
    local resultTab = {}
    copyTable(tab,temTab)
    if #temTab <= valueNum then
        return temTab
    else
        for i = 1,valueNum do
            local randomNum = math.random(1,#temTab)
            table.insert(resultTab,temTab[randomNum])
            table.remove(temTab,randomNum)
        end
    end
    return resultTab
end


-- 查看某值是否为表tbl中的key值
function GD.table_kIn(tbl, key)
    if tbl == nil then
        return false
    end
    for k, v in pairs(tbl) do
        if k == key then
            return true
        end
    end
    return false
end
 
-- 查看某值是否为表tbl中的value值
function GD.table_vIn(tbl, value)
    if tbl == nil then
        return false
    end
 
    for k, v in pairs(tbl) do
        if v == value then
            return true
        end
    end
    return false
end
