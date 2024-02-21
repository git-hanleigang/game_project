--
--island
--2017年8月15日
--UserDataManager.lua
--

local UserDataManager = class("UserDataManager")

GD.PROPERTIES_FIELD_TYPE = {
    -- 数据持久化的是数字类型， 无论 int float double 因为lua 不区分这个统一都是Number
    SAVE_FIELD_TYPE_NUMBER = 1,
    -- 数据持久化的是Bool类型
    SAVE_FIELD_TYPE_BOOL = 2,
    -- 数据持久化的是String类型
    SAVE_FIELD_TYPE_STRING = 3
}

-- 默认获取属性从本地文件读取还是从缓存读取。 false 从缓存， true 本地文件
local DEFAULT_GET_PROPERTIES_FROM_FILE = false

---
--所有数据都保存在这个table中 ,
--如果想将数据分离开来那么只需要调用这个table，并且对其赋值就ok了
--例如：  Global_UserData["userID"] = "value"
-- GD.Global_UserData = {}

UserDataManager.m_instance = nil --创建属性
UserDataManager.m_markIsFlushData = nil --

function UserDataManager:getInstance()
    if UserDataManager.m_instance == nil then
        UserDataManager.m_instance = UserDataManager.new()
    end

    return UserDataManager.m_instance
end

-- 构造函数
function UserDataManager:ctor()
    self.m_userData = {}
    self.m_markIsFlushData = false

    scheduler.scheduleUpdateGlobal(
        function(dt)
            self:flushData()
        end
    )
end

-- 最新热更版本号
function UserDataManager:getLastUpdateVer()
    local _lastVer = xcyy.XcyyField:getInstance():getStringForKey("lastUpdateVer")
    if not _lastVer or _lastVer == "" then
        release_print("--xy-- not find lastUpdateVer!!")
        -- if not xcyy.XcyyField:isXMLFileExist() then
            -- 如果文件不存在，重置单例
            xcyy.XcyyField:destroyInstance()
        -- end
        local packageUpdateVersion = xcyy.GameBridgeLua:getPackageUpdateVersion()
        -- self:setVersion("lastUpdateVer", tostring(packageUpdateVersion))
        _lastVer = packageUpdateVersion
    end

    return tonumber(_lastVer)
end

function UserDataManager:setVersion(key, value)
    value = tostring(value)
    -- release_print(string.format("--xy--key:%s|md5=%s", key, value))
    xcyy.XcyyField:getInstance():setStringForKey(key, value)
end

function UserDataManager:getVersion(key)
    return xcyy.XcyyField:getInstance():getStringForKey(key)
end

--TODO 数据存储
------------------------------------------------------

---
-- 获取bool 类型的数据
-- @param defaultValue bool 默认数据
-- @param isGetFromFile bool 是否从本地文件读取， 默认为false(直接从全局缓存中去拿)  true 直接从本地文件读取
-- @return #如果未设置defaultValue ， 并且未在存储内容中找到， 则返回false
--
function UserDataManager:getBoolByField(fieldName, defaultValue, isGetFromFile)
    fieldName = "" .. (fieldName or "")
    if fieldName == "" then
        return
    end

    -- if DEBUG > 1 then
    --     print("------------------getBool_PropertyByFieldName = " .. fieldName)
    --     release_print("------------------getBool_PropertyByFieldName = " .. fieldName)
    -- end
    isGetFromFile = isGetFromFile or DEFAULT_GET_PROPERTIES_FROM_FILE

    local fieldValue = nil
    if not isGetFromFile then
        fieldValue = self.m_userData[fieldName]
        if fieldValue == nil then
            fieldValue = cc.UserDefault:getInstance():getStringForKey(fieldName)
            self.m_userData[fieldName] = fieldValue
        else
            fieldValue = tostring(fieldValue)
        end
    else
        fieldValue = cc.UserDefault:getInstance():getStringForKey(fieldName)
        self.m_userData[fieldName] = fieldValue
    end

    if fieldValue == "" then
        if type(defaultValue) == "boolean" then
            return defaultValue
        else
            return false
        end
    else
        if fieldValue == "true" then
            return true
        else
            return false
        end
    end
end

---
-- 获取String 类型的数据
-- @param defaultValue bool 默认数据
-- @param isGetFromFile bool 是否从本地文件读取， 默认为false(直接从全局缓存中去拿)  true 直接从本地文件读取
function UserDataManager:getStringByField(fieldName, defaultValue, isGetFromFile)
    fieldName = "" .. (fieldName or "")
    if fieldName == "" then
        return
    end

    -- if DEBUG > 1 then
    --     -- print("------------------getString_PropertyByFieldName = " .. fieldName)
    --     release_print("------------------getString_PropertyByFieldName = " .. fieldName)
    -- end
    isGetFromFile = isGetFromFile or DEFAULT_GET_PROPERTIES_FROM_FILE

    local fieldValue = nil
    if not isGetFromFile then
        fieldValue = self.m_userData[fieldName]
        if fieldValue == nil then
            fieldValue = cc.UserDefault:getInstance():getStringForKey(fieldName)
            self.m_userData[fieldName] = fieldValue
        end
    else
        fieldValue = cc.UserDefault:getInstance():getStringForKey(fieldName)
        self.m_userData[fieldName] = fieldValue
    end

    -- release_print("fieldName:" .. fieldName .. ":" .. tostring(fieldValue))

    if fieldValue == "" then
        if type(defaultValue) == "string" then
            return defaultValue
        else
            return ""
        end
    else
        return fieldValue
    end
end

---
-- 获取Number 类型数据
-- @param defaultValue bool 默认数据
-- @param isGetFromFile bool 是否从本地文件读取， 默认为false(直接从全局缓存中去拿)  true 直接从本地文件读取
function UserDataManager:getNumberByField(fieldName, defaultValue, isGetFromFile)
    fieldName = "" .. (fieldName or "")
    if fieldName == "" then
        return
    end

    -- if DEBUG > 1 then
    --     print("------------------getNumber_PropertyByFieldName = " .. fieldName)
    --     release_print("------------------getNumber_PropertyByFieldName = " .. fieldName)
    -- end
    isGetFromFile = isGetFromFile or DEFAULT_GET_PROPERTIES_FROM_FILE

    local fieldValue = nil
    if not isGetFromFile then
        fieldValue = self.m_userData[fieldName]
        if fieldValue == nil then
            fieldValue = cc.UserDefault:getInstance():getStringForKey(fieldName)
            self.m_userData[fieldName] = fieldValue
        else
            fieldValue = tostring(fieldValue)
        end
    else
        fieldValue = cc.UserDefault:getInstance():getStringForKey(fieldName)
        self.m_userData[fieldName] = fieldValue
    end

    if fieldValue == "" then
        if type(defaultValue) == "number" then
            return defaultValue
        else
            return 0
        end
    else
        return tonumber(fieldValue) or 0
    end
end

---
-- 保存内容 , 数据写入到UserDefault 后并不会立即flush ，自动在0.2秒后保存数据，降低flush()的次数，如果多次那么会合并成一次
--          如果想立即写入数据，那么调用 UserDataManager:getInstance():flushData()
--
-- function UserDataManager:savePropertyByField(fieldName, fieldValue, fieldType)
--     if DEBUG > 1 then
--         print("------------------savePropertyByField = " .. fieldName)
--         release_print("------------------savePropertyByField = " .. fieldName)
--     end
--     fieldType = fieldType or PROPERTIES_FIELD_TYPE.SAVE_FIELD_TYPE_STRING

--     local isNumber = false
--     if fieldType == PROPERTIES_FIELD_TYPE.SAVE_FIELD_TYPE_NUMBER then
--         fieldValue = fieldValue .. ""
--         isNumber = true
--     elseif fieldType == PROPERTIES_FIELD_TYPE.SAVE_FIELD_TYPE_BOOL then
--         if fieldValue == true then
--             fieldValue = "true"
--         else
--             fieldValue = "false"
--         end
--     end

--     if isNumber then
--         xcyy.SlotsUtil:saveDataWithNumber(fieldName, fieldValue)
--     else
--         xcyy.SlotsUtil:saveData(fieldName, fieldValue)
--     end

--     cc.UserDefault:getInstance():flush()

--     self.m_userData[fieldName] = fieldValue -- 缓存数据

--     self.m_markIsFlushData = true
-- end

---
-- 保存bool 值类型数据
function UserDataManager:setBoolByField(fieldName, fieldValue, isFlush)
    fieldName = "" .. (fieldName or "")
    if fieldName == "" then
        return
    end

    -- if DEBUG > 1 then
    --     print("------------------saveBool_PropertyByFieldName = " .. fieldName)
    --     release_print("------------------saveBool_PropertyByFieldName = " .. fieldName)
    -- end

    fieldValue = fieldValue or false
    if type(fieldValue) ~= "boolean" then
        return
    end

    if fieldValue == true then
        fieldValue = "true"
    else
        fieldValue = "false"
    end
    -- 缓存数据
    self.m_userData[fieldName] = fieldValue

    -- xcyy.SlotsUtil:saveData(fieldName, fieldValue)
    cc.UserDefault:getInstance():setStringForKey(fieldName, fieldValue)

    self.m_markIsFlushData = true
    if isFlush then
        self:flushData()
    end
end

---
-- 保存string 值类型数据
function UserDataManager:setStringByField(fieldName, fieldValue, isFlush)
    fieldName = "" .. (fieldName or "")
    if fieldName == "" then
        return
    end

    -- if DEBUG > 1 then
    --     print("------------------saveString_PropertyByFieldName = " .. fieldName)
    --     release_print("------------------saveString_PropertyByFieldName = " .. fieldName)
    -- end

    fieldValue = fieldValue or ""
    if type(fieldValue) ~= "string" then
        return
    end
    -- 缓存数据
    self.m_userData[fieldName] = fieldValue

    -- xcyy.SlotsUtil:saveData(fieldName, fieldValue)
    cc.UserDefault:getInstance():setStringForKey(fieldName, fieldValue)

    self.m_markIsFlushData = true
    if isFlush then
        self:flushData()
    end
end

---
-- 保存Number 值类型数据
function UserDataManager:setNumberByField(fieldName, fieldValue, isFlush)
    fieldName = "" .. (fieldName or "")
    if fieldName == "" then
        return
    end

    -- if DEBUG > 1 then
    --     print("------------------saveNumber_PropertyByFieldName = " .. fieldName)
    --     release_print("------------------saveNumber_PropertyByFieldName = " .. fieldName)
    -- end

    fieldValue = fieldValue or 0
    if type(fieldValue) ~= "number" then
        return
    end
    -- 缓存数据
    fieldValue = tostring(fieldValue)
    self.m_userData[fieldName] = fieldValue

    -- xcyy.SlotsUtil:saveDataWithNumber(fieldName, fieldValue)
    cc.UserDefault:getInstance():setStringForKey(fieldName, fieldValue)

    self.m_markIsFlushData = true
    if isFlush then
        self:flushData()
    end
end

function UserDataManager:delValueByField(fieldName)
    fieldName = "" .. (fieldName or "")
    if fieldName == "" then
        return
    end

    -- if DEBUG > 1 then
    --     print("------------------deleteValue_PropertyByFieldName = " .. fieldName)
    --     release_print("------------------deleteValue_PropertyByFieldName = " .. fieldName)
    -- end

    local fieldValue = self.m_userData[fieldName]
    if not fieldValue or fieldValue == "" then
        fieldValue = cc.UserDefault:getInstance():getStringForKey(fieldName)
    end
    if fieldValue ~= "" then
        self.m_userData[fieldName] = nil
        cc.UserDefault:getInstance():deleteValueForKey(fieldName)
    end
end

--[[
    @desc: 删除所有数据
    author:{author}
    time:2022-02-26 16:51:23
    @return:
]]
function UserDataManager:deleteAllValues()
    -- if DEBUG > 1 then
    --     print("------------------deleteAllValues")
    --     release_print("------------------deleteAllValues")
    -- end

    if next(self.m_userData) then
        self.m_userData = {}
        cc.UserDefault:getInstance():deleteAllValues()
    end
end

---
-- 立即保存数据
--
function UserDataManager:flushData()
    if self.m_markIsFlushData then
        cc.UserDefault:getInstance():flush()
        self.m_markIsFlushData = false
    end
end

return UserDataManager
