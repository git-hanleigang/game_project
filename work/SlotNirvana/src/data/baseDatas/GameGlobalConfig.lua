--
--版权所有:{company}
-- Author:{author}
-- Date: 2019-05-09
-- FIX IOS 123
local ActivityItemConfig = require("data.baseDatas.ActivityItemConfig")
local RecommendConfig = require("data.baseDatas.RecommendConfig")
local CaseVersionConfig = require("data.baseDatas.CaseVersionConfig")
local ActivityEntranceConfig = require("data.baseDatas.ActivityEntranceConfig")
local DynamicZOrderConfig = require("common.DynamicZOrderConfig")
local LoadingControl = require("views.loading.LoadingControl")

local GameGlobalConfig = class("GameGlobalConfig")
-- 所有活动配置
GameGlobalConfig.dinnerLandSaleActivities = nil --餐厅活动
GameGlobalConfig.activityConfigs = {}
GameGlobalConfig.caseVersions = nil --版本兼容控制
GameGlobalConfig.recentActivityConfigs = {} -- 近期会开启的活动配置

GameGlobalConfig.popupConfigs = nil --开启的弹窗配置
GameGlobalConfig.recommendConfigs = nil --关卡推荐配置

GameGlobalConfig.abTestConfig = nil --abtest数据
GameGlobalConfig.userCategoryConfig = nil --abtest分组信息

--VersionConfig
GameGlobalConfig.versionData = nil --版本信息
GameGlobalConfig.dynamicData = nil --动态下载信息
GameGlobalConfig.levelsData = nil --关卡信息
GameGlobalConfig.serverAddrConfig = nil --服务器地址配置及热更配置
GameGlobalConfig.isInitVersionConfig = nil --是否使用versionConfig控制热更
-- 活动公告配置
GameGlobalConfig.activityNoticeDatas = nil

GameGlobalConfig.m_themeResName = nil --替换资源活动主题名
--服务器传过来下个版本弃用
GD.ABTEST_LEVELS = {
    GameScreenFiveDragon = {A = {10005, "FiveDragon"}, B = {10030, "FiveDragonV2"}},
    GameScreenDwarfFairy = {A = {10015, "DwarfFairy"}, B = {10029, "DwarfFairyV2"}},
    GameScreenCrazyBomb = {A = {10016, "CrazyBomb"}, B = {10035, "CrazyBombV2"}},
    GameScreenFivePande = {A = {10001, "FivePande"}, B = {10034, "PandaRichesV2"}},
    GameScreenCharms = {A = {10020, "Charms"}, B = {10031, "CharmsV2"}},
    GameScreenKangaroos = {A = {10019, "Kangaroos"}, B = {10038, "KangaroosV2"}},
    GameScreenCandyBingo = {A = {10022, "CandyBingo"}, B = {10039, "CandyBingoV2"}},
    GameScreenLinkFish = {A = {10011, "PandaBless"}, B = {10040, "PandaBlessV2"}},
    GameScreenPowerUp = {A = {10027, "PowerUp"}, B = {10045, "PowerUpV2"}}
}

GD.CHANGE_THTMERES_TYPE = {
    PNG_LOBBY = 1, --大厅背景图
    BGM_LOBBY = 2 --大厅背景音乐
}

--协议超链接
GD.PRIVACY_POLICY = "https://www.cashtornado-slots.com/privacy.html"
GD.TERMS_OF_SERVICE = "https://www.cashtornado-slots.com/TermOfService.html"

function GameGlobalConfig:ctor()
    self.recommendConfigs = {}
    self.caseVersions = {}
    self.abTestConfig = {}
    self.userCategoryConfig = {}

    self.dinnerLandSaleActivities = {}
    -- 活动配置
    self.activityConfigs = {}
    self.recentActivityConfigs = {}
    -- 活动公告表
    self.activityNoticeDatas = {}

    self.m_isNewPlayer = false
    self.m_createTs = -1
    self.m_loadingIgnoreZips = {}
    self.m_clientConfig = {}

    self.m_defTheme = "casino"

    self.inflationLevels = {}
end

function GameGlobalConfig:isNewPlayer()
    return self.m_isNewPlayer
end

function GameGlobalConfig:setNewPlayer(isNew)
    self.m_isNewPlayer = isNew or false
end

function GameGlobalConfig:setNewUserInfo(data)
    if not data then
        return
    end
    local isNew, level, timestamp
    if data:HasField("newUser") then
        isNew = data.newUser
    end

    if gLobalSendDataManager:getLogGameLoad().setFirstLink then
        gLobalSendDataManager:getLogGameLoad():setFirstLink(isNew)
    end

    if data:HasField("userLevel") then
        level = data.userLevel
    end

    if data:HasField("userRegisterTime") then
        timestamp = data.userRegisterTime
    end

    self.m_isNewPlayer = isNew or false
    
    if level then
        -- udid用户等级
        self.m_userLv = tonumber(level)
        release_print("GameGlobalConfig user level:" .. level)
        -- 10级前认为是新用户
        if self.m_userLv < 10 then
            self.m_isNewPlayer = true
        else
            self.m_isNewPlayer = false
        end
    end

    if timestamp then
        self.m_createTs = tonumber(timestamp)
    end
end
-- 新用户期
function GameGlobalConfig:isNoviceLogin()
    -- if self.m_createTs >= 0 then
    --     return (self.m_createTs == 0) or globalData.userRunData:isNewUser(7, self.m_createTs)
    -- else
    --     return false
    -- end
    if self.m_userLv and self.m_userLv <= 50 then
        -- 新手期登陆
        return true
    else
        return false
    end
end

function GameGlobalConfig:parseClientCfg(strCfg)
    if strCfg and strCfg ~= "" then
        local _clientConfig = cjson.decode(strCfg)
        local _mod = require("data.baseDatas.ClientCfgInfo")
        for _, _value in ipairs(_clientConfig) do
            local _info = _mod:create()
            _info:parseData(_value)
            local _key = _info:getKey()
            local _cfgs = self.m_clientConfig[_key]
            if not _cfgs then
                self.m_clientConfig[_key] = {}
            end
            table.insert(self.m_clientConfig[_key], _info)
        end
    end
end

function GameGlobalConfig:getClientCfg(key, keyDef,defIndependentReturn)
    key = key or ""
    -- local _info = self.m_clientConfig[key]
    keyDef = keyDef or ""
    -- local _infoDef = self.m_clientConfig[keyDef]
    -- if _info and _info:isExpire() then
    --     return _info
    -- elseif _infoDef then
    --     return _infoDef
    -- else
    --     return nil
    -- end
    local _infos = self.m_clientConfig[key] or {}
    for i = 1, #_infos do
        local _info = _infos[i]
        if _info and _info:isExpire() then
            return _info,nil
        end
    end

    local _defInfos = self.m_clientConfig[keyDef] or {}
    for j = 1, #_defInfos do
        local _infoDef = _defInfos[j]
        if _infoDef and _infoDef:isExpire() then
            if defIndependentReturn then
                return nil,_infoDef
            else
                return _infoDef,nil
            end
        end
    end

    return nil,nil
end

function GameGlobalConfig:getThemeCsb(tbThemes, openTheme)
    local _path = ""
    local bPos, ePos = string.find(openTheme, "[/%.]")
    if not bPos then
        _path = tbThemes[openTheme] or ""
    else
        _path = openTheme
    end

    local _isExist = util_IsFileExist(_path)
    if _isExist then
        return _path
    else
        return ""
    end
end

-- 登陆主题
function GameGlobalConfig:getLoginTheme()
    local _isNoviceLogin = self:isNoviceLogin()
    local themeCfg, defThemeCfg = self:getClientCfg("loginTheme", "", true)
    local openTheme = ""
    if themeCfg and (not _isNoviceLogin) then
        openTheme = themeCfg:getValue()
    else
        if _isNoviceLogin then
            openTheme = self.m_defTheme
        else
            local isCheckout, weektheme = LoadingControl:getInstance():getCurrentWeekLoadingBg(1)
            if isCheckout then
                openTheme = weektheme
            else
                if defThemeCfg then
                    openTheme = defThemeCfg:getValue()
                -- else
                --     if _isNoviceLogin then
                --         openTheme = self.m_defTheme
                --     end
                end
            end
        end
    end
    return openTheme
end

function GameGlobalConfig:getLoginThemeCsb(tbThemes, isNewInstall)
    tbThemes = tbThemes or {}
    if isNewInstall then
        return tbThemes[self.m_defTheme]
    end

    local openTheme = self:getLoginTheme()
    -- local _path = ""
    -- local bPos, ePos = string.find(openTheme, "[/%.]")
    -- if not bPos then
  --     _path = tbThemes[openTheme] or ""
    -- else
    --     _path = openTheme
    -- end

    -- local _isExist = util_IsFileExist(_path)
    -- if (not _isExist) then
    local _path = self:getThemeCsb(tbThemes, openTheme)
    if _path == "" then
        local _oldTheme = gLobalDataManager:getStringByField("LoginTheme", self.m_defTheme)
        local _path2 = self:getThemeCsb(tbThemes, _oldTheme)
        if _path2 == "" then
            return tbThemes[self.m_defTheme]
        else
            return _path2
        end
    else
        return _path
    end
end

function GameGlobalConfig:isLoginThemeChange()
    local _openTheme = self:getLoginTheme()
    local _loginTheme = gLobalDataManager:getStringByField("LoginTheme", self.m_defTheme)
    if (_openTheme ~= "" and _openTheme ~= _loginTheme) then
        gLobalDataManager:setStringByField("LoginTheme", _openTheme)
        gLobalDataManager:flushData()
        if _openTheme == self.m_defTheme then
            return true
        else
            -- 新的主题资源是否存在
            local _path = self:getThemeCsb({}, _openTheme)
            if _path == "" then
                return false
            else
                return true
            end
        end
    else
        return false
    end
end

-- 加载主题
function GameGlobalConfig:getLoadingThemeCsb(tbThemes)
    tbThemes = tbThemes or {}
    -- local themeCfg = self:getClientCfg("loadingTheme")
    -- local _loadingTheme = gLobalDataManager:getStringByField("LoadingTheme", self.m_defTheme)
    -- local openTheme = _loadingTheme
    local openTheme = ""
    local _isNoviceLogin = self:isNoviceLogin()
    if _isNoviceLogin then
        openTheme = self.m_defTheme
    else
        local themeCfg, defThemeCfg = self:getClientCfg("loadingTheme", "",true)
        if themeCfg then
            openTheme = themeCfg:getValue()
        else
            local isCheckout,weektheme = LoadingControl:getInstance():getCurrentWeekLoadingBg(2)
            if isCheckout then
                openTheme = weektheme
            else
                if defThemeCfg then
                    openTheme = defThemeCfg:getValue()
                end
            end
        end
    end
    
    local _path = ""
    local bPos, ePos = string.find(openTheme, "[/%.]")
    if not bPos then
        _path = tbThemes[openTheme] or ""
    else
        _path = openTheme
    end

    local _isExist = util_IsFileExist(_path)
    if (not _isExist) then
        return tbThemes[self.m_defTheme]
    else
        return _path
    end
end

-- 大厅背景
function GameGlobalConfig:getLobbyBg()
    local tbThemes = {
        normal = "Lobby/ui/lobby_bg_new.jpg"
    }
    local clientCfg = self:getClientCfg("lobbyBg", "lobbyBgDef")
    local openTheme = ""
    if clientCfg then
        openTheme = clientCfg:getValue()
    end
    local _path = ""
    local bPos, ePos = string.find(openTheme, "[/%.]")
    if not bPos then
        _path = tbThemes[openTheme] or ""
    else
        _path = openTheme
    end

    local _isExist = util_IsFileExist(_path)
    if (not _isExist) then
        return tbThemes.normal
    else
        return _path
    end
end

-- 大厅背景音乐
function GameGlobalConfig:getLobbyBGM()
    local tbThemes = {
        normal = "Sounds/bkg_lobby_new.mp3",
        easter = "Sounds/bkg_lobby_easter.mp3",
        tmPlayers = "Sounds/bkg_lobby_10m.mp3"
    }
    local clientCfg = self:getClientCfg("lobbyBgm", "lobbyBgmDef")
    local openTheme = ""
    if clientCfg then
        openTheme = clientCfg:getValue()
    end

    local _path = ""
    local bPos, ePos = string.find(openTheme, "[/%.]")
    if not bPos then
        _path = tbThemes[openTheme] or ""
    else
        _path = openTheme
    end

    local _isExist = util_IsFileExist(_path)
    if (not _isExist) then
        return tbThemes.normal
    else
        return _path
    end
end

function GameGlobalConfig:checkNewPlayerIgnoreZip(zipName)
    if not self:isNewPlayer() then
        return false
    end

    local isIgnore = false
    local dyInfo = self.dynamicData[zipName] or {}
    isIgnore = (tonumber(dyInfo.npIgnore or "0") == 1)

    return isIgnore
end

--当前版本是否支持
function GameGlobalConfig:checkOpenVersion(id)
    if not self.caseVersions or #self.caseVersions == 0 then
        return true
    end

    for i = 1, #self.caseVersions do
        local versionConfig = self.caseVersions[i]
        if versionConfig:checkIncompatible(id) then
            return false
        end
    end
    return true
end

-- 解析活动配置
function GameGlobalConfig:parseActivityConfig(configs, nType)
    -- 判断configs是否有效
    if not configs or configs == "" then
        return
    end

    nType = nType or ACTIVITY_TYPE.COMMON

    if not self.activityConfigs["" .. nType] then
        self.activityConfigs["" .. nType] = {}
    end

    for key, value in ipairs(configs) do
        if self:checkOpenVersion(value.activityId) then
            local info = ActivityItemConfig:create()
            info:parseData(value, nType)
            self.activityConfigs["" .. nType][info.p_id] = info
        end
    end
    local a = 0
end

--根据类型获取配置列表
function GameGlobalConfig:getActivityConfigs(nType)
    if not nType then
        return self.activityConfigs
    else
        return self.activityConfigs["" .. nType]
    end
end

--根据Ref引用名获得活动配置
function GameGlobalConfig:getActivityConfigByRef(refName, nType)
    local callFunc = function(tbInfo)
        -- return tbInfo[refName]
        for k, v in pairs(tbInfo) do
            if v and v:getRefName() == refName then
                return v
            end
        end
    end

    local _info = nil
    if nType then
        local infoList = self:getActivityConfigs(nType)
        if infoList then
            _info = callFunc(infoList)
        end
    else
        for k, v in pairs(self.activityConfigs) do
            _info = callFunc(v)
            if _info then
                break
            end
        end
    end
    return _info
end

--根据活动Id获得活动配置
function GameGlobalConfig:getActivityConfigById(activityId, nType)
    local callFunc = function(tbInfo)
        return tbInfo["" .. activityId]
    end

    local _info = nil
    if nType then
        local infoList = self:getActivityConfigs(nType)
        if infoList then
            _info = callFunc(infoList)
        end
    else
        for k, v in pairs(self.activityConfigs) do
            _info = callFunc(v)
            if _info then
                break
            end
        end
    end
    return _info
end

-- 解析近期到来的活动配置
function GameGlobalConfig:parseRecentActivityConfig(configs, nType)
    -- 判断configs是否有效
    if not configs or configs == "" then
        return
    end

    nType = nType or ACTIVITY_TYPE.COMMON

    if not self.recentActivityConfigs["" .. nType] then
        self.recentActivityConfigs["" .. nType] = {}
    end

    for key, value in ipairs(configs) do
        if self:checkOpenVersion(value.activityId) then
            local info = ActivityItemConfig:create()
            info:parseData(value, nType)
            self.recentActivityConfigs["" .. nType][info.p_id] = info
        end
    end
    local a = 0
end

--根据类型获取配置列表
function GameGlobalConfig:getRecentActivityConfigs(nType)
    if not nType then
        return self.recentActivityConfigs
    else
        return self.recentActivityConfigs["" .. nType]
    end
end

--根据Ref引用名获得活动配置
function GameGlobalConfig:getRecentActivityConfigByRef(refName, nType)
    local callFunc = function(tbInfo)
        -- return tbInfo[refName]
        for k, v in pairs(tbInfo) do
            if v and v:getRefName() == refName then
                return v
            end
        end
    end

    local _info = nil
    if nType then
        local infoList = self:getRecentActivityConfigs(nType)
        if infoList then
            _info = callFunc(infoList)
        end
    else
        for k, v in pairs(self.recentActivityConfigs) do
            _info = callFunc(v)
            if _info then
                break
            end
        end
    end
    return _info
end

-- 解析数据
function GameGlobalConfig:parseData(data)
    if not data then
        return
    end

    --解析热更新配置
    self:parseVersionConfigs(data)
    --ABTEST
    self:parseDataABTest(data)
    if data.caseVersions ~= nil and data.caseVersions ~= "" then
        local configs = data.caseVersions
        if configs ~= nil and #configs > 0 then
            for i = 1, #configs do
                local item = CaseVersionConfig:create()
                item:parseData(configs[i])
                self.caseVersions[#self.caseVersions + 1] = item
            end
        end
    end

    -- 解析活动配置
    self:parseActivityConfigs(data)
    -- 解析弹板配置
    self:parsePopConfigs(data)
    -- 解析活动总入口数据
    self:parseActivityNoticeConfig(data.activityPopups)
    -- 扩圈系统 数据 判断该玩家是否是 支持扩圈系统
    self:parseExpandCircleConfig(data.expandCircleConfig)
    -- ===========
    --解析修改主题资源活动数据
    -- self:parseChangeThemeResConfig(data.commonActivities)
end

function GameGlobalConfig:clearVerCfg()
    self.versionData = {}
    self.dynamicData = {}
    self.levelsData = {}
    self.serverAddrConfig = {}
    self.isInitVersionConfig = false
end

--解析热更新配置
function GameGlobalConfig:parseVersionConfigs(data)
    --热更新控制
    release_print("GameGlobalConfig VersionConfig")
    if data:HasField("versions") == true then
        release_print("GameGlobalConfig VersionConfig init")
        local configCount = 0
        local versionConfig = data.versions

        local function cjson_decode(strJsonData)
            local ok, content =
                pcall(
                function()
                    return cjson.decode(strJsonData)
                end
            )
            return ok, content
        end

        --版本信息
        if versionConfig:HasField("version") == true then
            release_print("GameGlobalConfig VersionConfig version")
            local ok, content = cjson_decode(versionConfig.version)
            if ok then
                self.versionData = content
                configCount = configCount + 1
            else
                util_sendToSplunkMsg("reqGlobalConfig", "decode version json error!!!\n"..tostring(content))
            end
        end
        --动态下载信息
        if versionConfig:HasField("dynamic") == true then
            release_print("GameGlobalConfig VersionConfig dynamic")
            local ok, content
            if device.platform == "mac" then
                -- 使用本地Dynimic配置
                content = util_checkJsonDecode(GD_DynamicName)
                if content then
                    ok = true
                end
            else
                ok, content = cjson_decode(versionConfig.dynamic)
            end
            if ok then
                self.dynamicData = self:initDynamicData(content)
                if self.dynamicData then
                    configCount = configCount + 1
                end
            else
                util_sendToSplunkMsg("reqGlobalConfig", "decode dynamic json error!!!\n"..tostring(content))
            end
        end
        --关卡信息
        if versionConfig:HasField("levels") == true then
            release_print("GameGlobalConfig VersionConfig levels")
            local ok, content
            if device.platform == "mac" then
                -- 使用本地Dynimic配置
                content = util_checkJsonDecode(GD_LevelsName)
                if content then
                    ok = true
                end
            else
                ok, content = cjson_decode(versionConfig.levels)
            end
            if ok then
                self.levelsData = content
                if self.levelsData then
                    configCount = configCount + 1
                end
            else
                util_sendToSplunkMsg("reqGlobalConfig", "decode levels json error!!!\n"..tostring(content))
            end
        end
        --服务器地址信息
        if versionConfig:HasField("address") then
            release_print("GameGlobalConfig ServerAddrConfig levels")
            local ok, content = cjson_decode(versionConfig.address)
            if ok then
                self.serverAddrConfig = content
                configCount = configCount + 1
            else
                util_sendToSplunkMsg("reqGlobalConfig", "decode address json error!!!\n"..tostring(content))
            end
        end
        -- 忽略loading下载列表
        local ignoreZips = versionConfig["ignoreZips"]
        if ignoreZips and #ignoreZips > 0 then
            for i = 1, #ignoreZips do
                self.m_loadingIgnoreZips[ignoreZips[i]] = true
            end
        -- configCount = configCount + 1
        end

        --是否4个配置文件都存在
        if configCount == 4 then
            release_print("GameGlobalConfig VersionConfig parseData")
            self.isInitVersionConfig = true
            if self:getIsUseDynamicDLDispather() then
                if util_IsFileExist("common/DynamicDLDispatcher.lua") or util_IsFileExist("common/DynamicDLDispatcher.luac") then
                    globalDynamicDLControl = require("common.DynamicDLDispatcher"):getInstance()
                end
            end
            globalDynamicDLControl:initDynamicZipTable()
        else
            gLobalBuglyControl:luaException("parseVersionConfigs error configCount~=5!", debug.traceback())
        end

        release_print("GameGlobalConfig VersionConfig end")
    end
end

-- 获取版本配置
function GameGlobalConfig:getVerInfo()
    local verInfo = {}
    local gVer = globalData.GameConfig.versionData
    if gVer then
        if device.platform == "android" then
            if MARKETSEL == AMAZON_MARKET then
                -- Amazon
                local amazonContent = gVer["amazon"]
                if amazonContent then
                    verInfo = amazonContent
                end
            else
                -- Google
                verInfo = gVer
            end
        elseif device.platform == "ios" then
            local iosContent = gVer["ios"]
            if iosContent then
                verInfo = iosContent
            end
        else
            verInfo = gVer
        end
    end

    return verInfo
end

function GameGlobalConfig:resetDynamicData()
    globalDynamicDLControl:initDynamicZipTable()
end

-- 初始化动态资源配置
function GameGlobalConfig:initDynamicData(dynamicData)
    if not dynamicData then
        return {}
    end

    local _dynamicData = {}
    local datas = dynamicData["Dynamic"]

    for index, info in ipairs(datas) do
        local key = info["zipName"]
        if device.platform == "mac" then
            -- 检查是否有重复
            local _dynamicInfo = _dynamicData[key]
            if _dynamicInfo then
                local errTxt = "Repeat Dy config " .. key .. ", Please fix!!!!"
                -- printError(errTxt)
                assert(nil, errTxt)
            end
        end
        _dynamicData[key] = info
    end
    return _dynamicData
end

--重新排序关卡入口下载优先级
function GameGlobalConfig:resortDownloadZOrder(newQuestLevelIconList)
    local dynamicData = self.dynamicData
    if dynamicData ~= nil then
        for zipName, info in pairs(dynamicData) do
            self:resortLevelZOrder(newQuestLevelIconList, zipName, info)
            self:resortLobbyZOrder(zipName, info)
        end
    end
end

-- 获得关卡名
function GameGlobalConfig:getLevelName(lvName)
    local iconHead = "Level_"
    local gameHead = "GameScreen"

    local _lvName = ""
    local st, ov = string.find(lvName, "^" .. iconHead)
    if ov then
        _lvName = string.sub(lvName, ov + 1)
    end

    st, ov = string.find(lvName, "^" .. gameHead)
    if ov then
        _lvName = string.sub(lvName, ov + 1)
    end

    return _lvName ~= "CommingSoon" and _lvName or ""
end

-- 计算关卡入口Zorder
function GameGlobalConfig:getLevelIconDLOrder(newQuestLevelIconList)
    newQuestLevelIconList = newQuestLevelIconList or {}
    -- if #newQuestLevelIconList <= 0 then
    --     return {}
    -- end

    local minOrder = 1
    local maxOrder = 1
    local tbLevelIconsOrder = {}

    -- 排序新手quest
    for i = 1, #newQuestLevelIconList do
        local _iconName = newQuestLevelIconList[i]
        maxOrder = maxOrder + 1
        tbLevelIconsOrder[_iconName] = maxOrder
    end

    -- 排序关卡推荐位
    -- local levelsDataConfig = self.levelsData.config or {}
    -- local firstList = levelsDataConfig.firstList or {}
    local LevelRecmdData = require("views.lobby.LevelRecmd.LevelRecmdData")
    if LevelRecmdData then
        local firstList = LevelRecmdData:getInstance():getLevelsDLOrderList()
        for j = 1, #firstList do
            local levelName = self:getLevelName(firstList[j])
            local levelIconName = "Level_" .. levelName
            if not tbLevelIconsOrder[levelIconName] and levelName ~= "" then
                maxOrder = maxOrder + 1
                tbLevelIconsOrder[levelIconName] = maxOrder
            end
        end
    end

    --levels102.json配置中的levels列表中showOrder从小到大排序
    local levelsList = self.levelsData.levels or {}
    if #levelsList > 0 then
        -- table.sort(
        --     levelsList,
        --     function(p1, p2)
        --         local showOrder1 = tonumber(p1["showOrder"]) or 1000
        --         local showOrder2 = tonumber(p2["showOrder"]) or 1000
        --         return showOrder1 < showOrder2
        --     end
        -- )
        local levelMaxShowZOrder = 0
        for k, v in ipairs(levelsList) do
            local vLevelName = v.levelName

            local levelName = self:getLevelName(vLevelName)
            local levelIconName = "Level_" .. levelName
            if not tbLevelIconsOrder[levelIconName] and levelName ~= "" then
                -- maxOrder = maxOrder + 1
                local _zOrder = maxOrder + (tonumber(v.showOrder) or 1000)
                tbLevelIconsOrder[levelIconName] = _zOrder
                levelMaxShowZOrder = math.max(levelMaxShowZOrder, _zOrder)
            end
        end
    -- maxZOrder = levelMaxShowZOrder
    end

    return tbLevelIconsOrder
end

-- 更新 登录前levels配置
function GameGlobalConfig:updateLevelInfo()
    if not self.levelsData then
        return
    end

    local levelsList = self.levelsData.levels or {}
    for i = 1, #levelsList do
        local levelData = levelsList[i]
        local gameId = levelData["ID"]
        local machineData = globalData.slotRunData:getLevelInfoById(gameId)
        if machineData then
            levelData["showOrder"] = machineData.p_showOrder or 1
        end
    end
end

-- 大厅下载顺序
function GameGlobalConfig:getLobbyDLOrder()
    local tbLobbyOrder = {}
    if not DynamicZOrderConfig then
        return tbLobbyOrder, nil
    end

    local startDLOrder = 10
    local maxDownloadZOrder = startDLOrder + #DynamicZOrderConfig + 1

    for k, v in ipairs(DynamicZOrderConfig) do
        tbLobbyOrder[v] = startDLOrder + k
    end

    return tbLobbyOrder, maxDownloadZOrder
end

--重新排序关卡入口下载优先级
function GameGlobalConfig:resortLevelZOrder(newQuestLevelIconList, zipName, info)
    local levelsInfo = self.levelsData

    local lvIconName = "Level_" .. self:getLevelName(zipName)
    if levelsInfo ~= nil and lvIconName == zipName then
        local newZOrder = self:getDownloadZOrder(levelsInfo, newQuestLevelIconList, zipName)
        if newZOrder ~= nil then
            info.zOrder = newZOrder
        end
    end
end

--重新排序大厅下载优先级
function GameGlobalConfig:resortLobbyZOrder(zipName, info)
    if DynamicZOrderConfig ~= nil then
        local startDownloadZOrder = 10
        local maxDownloadZOrder = startDownloadZOrder + #DynamicZOrderConfig + 1
        local downloadZOrder = info.zOrder
        local downloadType = info.type
        local levelSepIndex = string.find(zipName, "Level_")
        --不是关卡入口
        if levelSepIndex == nil and downloadType == "1" then
            for k, v in ipairs(DynamicZOrderConfig) do
                if v == zipName then
                    info.zOrder = startDownloadZOrder + k
                    return
                end
            end
            info.zOrder = maxDownloadZOrder
        end
    end
end

function GameGlobalConfig:getDownloadZOrder(levelsInfo, newQuestLevelIconList, levelName)
    local minZOrder = 1
    local maxZOrder = minZOrder + #newQuestLevelIconList
    local function getNewQuestLevelZOrder(key)
        for k, v in ipairs(newQuestLevelIconList) do
            if v == key then
                return minZOrder + k
            end
        end
        return nil
    end

    local zOrder = getNewQuestLevelZOrder(levelName)
    if zOrder == nil then
        local headLevelName = "GameScreen"
        local headIconLevelName = "Level_"
        local lastLevelName = string.sub(levelName, string.len(headIconLevelName) + 1)
        local levelFullName = headLevelName .. lastLevelName
        --默认关卡推荐位（levels102.json配置中的，firstList中的关卡入口）
        local levelsDataConfig = levelsInfo.config
        if levelsDataConfig ~= nil then
            local firstList = levelsDataConfig.firstList
            if firstList ~= nil then
                for k, v in ipairs(firstList) do
                    if v == levelFullName then
                        return maxZOrder + k
                    end
                end
                maxZOrder = maxZOrder + #firstList
            end
        end

        --levels102.json配置中的levels列表中showOrder从小到大排序
        local levelsList = levelsInfo.levels
        if levelsList ~= nil then
            table.sort(
                levelsList,
                function(p1, p2)
                    local showOrder1 = tonumber(p1["showOrder"]) or 1000
                    local showOrder2 = tonumber(p2["showOrder"]) or 1000
                    return showOrder1 < showOrder2
                end
            )
            local levelMaxZOrder = 0
            for k, v in ipairs(levelsList) do
                local vLevelName = v["levelName"]
                if vLevelName ~= "CommingSoon" then
                    levelMaxZOrder = math.max(levelMaxZOrder, tonumber(v["showOrder"]) or 1000)
                    if levelFullName == vLevelName then
                        return maxZOrder + (tonumber(v["showOrder"]) or 1000)
                    end
                end
            end
            maxZOrder = maxZOrder + levelMaxZOrder
        end
    end
    return zOrder
end

-- 解析活动配置
function GameGlobalConfig:parseActivityConfigs(data)
    if not data then
        return
    end

    -- 设置是否新用户
    self:setNewUserInfo(data)

    --开启的主题促销活动配置
    self:parseActivityConfig(data.themeActivities, ACTIVITY_TYPE.THEME)
    --二选一活动
    self:parseActivityConfig(data.twoChooseOneGiftActivities, ACTIVITY_TYPE.COMMON)
    --1+1
    self:parseActivityConfig(data.onePlusOneSaleActivities, ACTIVITY_TYPE.COMMON)
    --商城最高档位付费后促销礼包功能
    self:parseActivityConfig(data.storeUpscaleSaleActivities, ACTIVITY_TYPE.COMMON)
    --开启的多档促销活动配置
    self:parseActivityConfig(data.choiceActivities, ACTIVITY_TYPE.CHOICE)

    --开启的七日促销类型数据
    self:parseActivityConfig(data.sevenDayActivities, ACTIVITY_TYPE.SEVENDAY)

    --服务器quest促销是额外逻辑前端没有变化还是7日促销
    self:parseActivityConfig(data.questSaleActivities, ACTIVITY_TYPE.SEVENDAY)

    self:parseActivityConfig(data.challengeSaleActivities, ACTIVITY_TYPE.SEVENDAY)

    --Bingo促销结构修改，保留原始促销逻辑
    self:parseActivityConfig(data.bingoSaleActivities, ACTIVITY_TYPE.BINGO)

    -- 餐厅促销活动数据
    self:parseActivityConfig(data.dinnerLandSaleActivities, ACTIVITY_TYPE.DINNERLAND)

    --活动内容表
    self:parseActivityConfig(data.commonActivities, ACTIVITY_TYPE.COMMON)

    self:parseRecentActivityConfig(data.recentActivities, ACTIVITY_TYPE.COMMON)
    -- battlePass促销
    self:parseActivityConfig(data.battlePassSaleActivities, ACTIVITY_TYPE.COMMON)
    --连续充值活动
    self:parseActivityConfig(data.continuousActivities, ACTIVITY_TYPE.KEEPRECHARGE)

    --大富翁
    self:parseActivityConfig(data.richSaleActivities, ACTIVITY_TYPE.RICHMAIN)
    -- 新版大富翁
    self:parseActivityConfig(data.worldTripSaleActivities, ACTIVITY_TYPE.WORLDTRIP)
    --blast
    self:parseActivityConfig(data.blastSaleActivities, ACTIVITY_TYPE.BLAST)
    --推币机
    self:parseActivityConfig(data.coinPusherActivities, ACTIVITY_TYPE.COINPUSHER)
    --集字
    self:parseActivityConfig(data.wordSaleActivities, ACTIVITY_TYPE.WORD)
    -- battlePass促销
    self:parseActivityConfig(data.battlePassSaleActivities, ACTIVITY_TYPE.COMMON)
    --二选一数据
    self:parseActivityConfig(data.doubleActivities, ACTIVITY_TYPE.BETWEENTWO)
    -- 关卡比赛促销
    self:parseActivityConfig(data.arenaSaleActivities, ACTIVITY_TYPE.LEAGUE)
    -- 新版餐厅
    self:parseActivityConfig(data.diningRoomSaleActivities, ACTIVITY_TYPE.DININGROOM)
    -- 六个箱子
    self:parseActivityConfig(data.memoryFlyingSaleActivities, ACTIVITY_TYPE.MEMORY_FLYING)
    --装修促销
    self:parseActivityConfig(data.redecorateSaleActivities, ACTIVITY_TYPE.REDECOR)
    --扑克促销
    self:parseActivityConfig(data.pokerSaleActivities, ACTIVITY_TYPE.POKER)
    --print(data)
    --占卜促销
    self:parseActivityConfig(data.divineSaleActivities, ACTIVITY_TYPE.DIVINATION)
    -- Client配置
    self:parseClientCfg(data.clientInitConfig)
    --2022复活节无限砸蛋促销
    self:parseActivityConfig(data.easterEggSaleActivities, ACTIVITY_TYPE.EASTER_EGGSALE)
    -- 新版二选一
    self:parseActivityConfig(data.newDoubleActivities, ACTIVITY_TYPE.NEWDOUBLE)
    -- 新版推币机
    self:parseActivityConfig(data.newCoinPusherActivities, ACTIVITY_TYPE.NEWCOINPUSHER)
    -- 接水管促销
    self:parseActivityConfig(data.pipeConnectSaleActivities, ACTIVITY_TYPE.PIPECONNECT)
    -- 自选促销礼包
    self:parseActivityConfig(data.diyComboDealActivities, ACTIVITY_TYPE.DIYCOMBODEAL)
    -- 4格连续充值
    self:parseActivityConfig(data.keepRechargeFourActivities, ACTIVITY_TYPE.KEEPRECHARGE4)
    -- 新版大富翁OutsideCave 促销
    self:parseActivityConfig(data.outsideCaveSaleActivities, ACTIVITY_TYPE.OUTSIDECAVE)
    -- 埃及推币机
    self:parseActivityConfig(data.coinPusherV3Activities, ACTIVITY_TYPE.EGYPTCOINPUSHER)
end

-- 解析弹板配置
function GameGlobalConfig:parsePopConfigs(data)
    if not data then
        return
    end
    --开启的弹窗配置
    if PopUpManager and PopUpManager.parsePopUpItemConfigs then
        PopUpManager:parsePopUpItemConfigs(data.popups)
    end
    --弹窗控制数据
    if PopUpManager and PopUpManager.parsePopUpControlDatas then
        PopUpManager:parsePopUpControlDatas(data.hallShowPopups)
    end
    --开启的弹窗配置
    if data.recommendConfig ~= nil and data.recommendConfig ~= "" then
        local d = data.recommendConfig
        if d ~= nil and #d > 0 then
            for i = 1, #d do
                if self:checkOpenVersion(d[i].id) then
                    local item = RecommendConfig:create()
                    item:parseData(d[i])
                    self.recommendConfigs[#self.recommendConfigs + 1] = item
                end
            end
        end
    end

    -- 解析 等级膨胀
    self:parseInflationLevels(data.inflationLevels)
end

-- 解析 等级膨胀
function GameGlobalConfig:parseInflationLevels(_inflationLevels)
    if not _inflationLevels or #_inflationLevels == 0 then
        return
    end

    self.inflationLevels = {}
    for i = 1, #_inflationLevels do
        local level = _inflationLevels[i]
        self.inflationLevels["" .. level] = 1
    end
end

--等级膨胀
function GameGlobalConfig:checkInFlationLevels(curLevel)
    local isInFlation = self.inflationLevels["" .. curLevel]
    if isInFlation then
        return true
    end
    return false
end

--获取推荐关卡名称
function GameGlobalConfig:getRecommendLevelName()
    for i = 1, #self.recommendConfigs do
        local d = self.recommendConfigs[i]
        if d and d.p_pushSwitch == true then
            return d.p_name
        end
    end

    return nil
end

--获取所有开启活动程序引用名,确定需要下载的zip包
function GameGlobalConfig:getActivityNeedDownload()
    local ret = {}

    -- 活动配置
    for k, v in pairs(ACTIVITY_TYPE) do
        local _configs = self:getActivityConfigs(v)
        if _configs then
            for key, value in pairs(_configs) do
                local refName = value:getRefName()
                local themeName = value:getThemeName()
                ret[#ret + 1] = themeName
                if v == ACTIVITY_TYPE.COMMON or v == ACTIVITY_TYPE.BLAST or v == ACTIVITY_TYPE.SEVENDAY then
                    self:checkAddRelativeDownload(ret, themeName, refName)
                end
            end
        end
    end

    --推荐弹版配置
    for i = 1, #self.recommendConfigs do
        local d = self.recommendConfigs[i]
        if d and (d.p_pushSwitch == true or d.p_slideSwitch == true or d.p_hallSwitch == true) then
            ret[#ret + 1] = "Level_TJ_" .. d.p_name
        end
    end

    return ret
end

--检测添加关联下载文件
function GameGlobalConfig:checkAddRelativeDownload(ret, themeName, refName)
    if not ret or not themeName or not refName then
        return
    end

    local mgr = G_GetMgr(refName)
    if not mgr then
        -- 老活动
        local function addReletative(ret, reference)
            if ret ~= nil and reference ~= nil then
                table.insert(ret, reference .. "_loading")
                table.insert(ret, reference .. "_Loading")
                table.insert(ret, reference .. "Code")
                table.insert(ret, reference .. "_Code")
            end
        end
        addReletative(ret, themeName)
        return
    end

    --添加该活动 关联下载文件 (宣传，代码)
    mgr:addDefExtendResList(themeName)

    local extendResList = mgr:getExtendResList()
    table.insertto(ret, extendResList)

    -- self:checkActivityExtendRes(ret, themeName)
end

-- 检查活动需要的额外依赖项 活动开启时也要下载
-- function GameGlobalConfig:checkActivityExtendRes(ret, reference)
--     if not ret or not reference then
--         return
--     end

--     local function addReletative(ret, reference)
--         if ret ~= nil and reference ~= nil then
--             table.insert(ret, reference .. "_loading")
--             table.insert(ret, reference .. "Code")
--             table.insert(ret, reference .. "_Code")
--         end
--     end

--     if string.find(reference, "Activity_Blast") ~= nil then
--         if string.find(reference, "Activity_BlastTask") ~= nil and reference ~= "Activity_BlastTaskCode" then
--             -- blast任务开启 需要关联代码下载
--             table.insert(ret, "Activity_BlastTaskCode")
--         elseif reference ~= "Activity_BlastCode" then
--             -- blast主题活动开启 需要关联代码下载
--             table.insert(ret, "Activity_BlastCode")
--             table.insert(ret, reference .. "_loading")
--         end
--     elseif string.find(reference, "Promotion_Blast") ~= nil and reference ~= "Promotion_BlastCode" then
--         -- blast促销活动开启 需要关联代码下载
--         table.insert(ret, "Promotion_BlastCode")
--     elseif reference == "Promotion_LevelDash" then
--         --level_Dash需要做特殊关联，因为通过这个弹版会打开其他包里的资源
--         local activityName = "Activity_LevelDash"
--         table.insert(ret, activityName)
--         addReletative(ret, activityName)
--     elseif string.find(reference, "Activity_CoinPusher") ~= nil then
--         if string.find(reference, "Task") and reference ~= "Activity_CoinPusherTask" then
--             -- 推币机任务主题 需要关联代码下载
--             table.insert(ret, "Activity_CoinPusherTaskCode")
--         elseif string.find(reference, "Task") == nil and reference ~= "Activity_CoinPusher" then
--             -- 推币机主题 需要关联代码下载
--             table.insert(ret, "Activity_CoinPusherCode")
--         end
--     elseif string.find(reference, "Promotion_Quest") ~= nil then
--         local activityName = "Promotion_QuestBase"
--         table.insert(ret, activityName)
--         addReletative(ret, activityName)
--     elseif string.find(reference, "Activity_Leagues") ~= nil then
--         table.insert(ret, "Activity_Leagues")
--         table.insert(ret, "Activity_Leagues_Code")
--     elseif string.find(reference, "Activity_SlotTrials") ~= nil then
--         table.insert(ret, "Activity_SlotTrials")
--         table.insert(ret, "Activity_SlotTrialsCode")
--     elseif string.find(reference, "Activity_AddPay") ~= nil then
--         table.insert(ret, "Activity_AddPayCode") -- 个人累充 需要关联代码下载
--     end
-- end

--获得今日主推的活动
function GameGlobalConfig:getHotTodayConfigs()
    local activityData = G_GetActivityDataByRef(ACTIVITY_REF.Entrance)
    if not activityData then
        return nil
    end

    local _cellDatas = activityData:getCellDatas() or {}
    if #_cellDatas > 0 then
        return _cellDatas
    else
        return nil
    end
end

--解析abtest数据
function GameGlobalConfig:parseDataABTest(data)
    if not CC_ABTEST_ENABLE then
        return
    end

    if data:HasField("gameNewOldAbtestConfig") == true then
        local strConfigs = data.gameNewOldAbtestConfig
        local gameNewOldAbtestConfig = cjson.decode(strConfigs)
        ABTEST_LEVELS = {}
        for key, config in pairs(gameNewOldAbtestConfig) do
            ABTEST_LEVELS[key] = {}
            for i = 1, #config do
                local data = config[i]
                local list = util_string_split(data, ",")
                ABTEST_LEVELS[key].A = {tonumber(list[1]), list[2]}
                ABTEST_LEVELS[key].B = {tonumber(list[3]), list[4]}
            end
        end
    end

    if data:HasField("abTestConfig") == true then
        local strConfigs = data.abTestConfig
        local abConfig = cjson.decode(strConfigs)
        self.abTestConfig = {}
        for key, config in pairs(abConfig) do
            self.abTestConfig[key] = {}
            for i = 1, #config do
                local data = config[i]
                local list = util_string_split(data, ",")
                local groupKey = list[1]
                if not self.abTestConfig[key][groupKey] then
                    self.abTestConfig[key][groupKey] = {}
                end
                self.abTestConfig[key][list[1]][tonumber(list[2])] = {
                    groupKey = groupKey,
                    resType = tonumber(list[3]),
                    name = list[4],
                    md5 = list[5],
                    openLevel = tonumber(list[6]),
                    version = list[7],
                    abtest_key = list[8]
                }
            end
        end
    end
end

--更新分组信息
function GameGlobalConfig:syncABTestGroupConfig(strdata)
    if strdata and strdata ~= "" then
        self.userCategoryConfig = cjson.decode(strdata)
    end
end

--是否属于A组关卡
function GameGlobalConfig:checkABtestGroupA(abKey)
    if self.userCategoryConfig and self.userCategoryConfig[abKey] and self.userCategoryConfig[abKey] == "A" then
        return true
    end
    return false
end

-- 获取分组信息
function GameGlobalConfig:getABtestGroup(abKey)
    return self.userCategoryConfig[abKey] or ""
end

-- 判断AB分组
function GameGlobalConfig:checkABtestGroup(abKey, group)
    -- 默认A组
    group = group or "A"
    local abGroup = self:getABtestGroup(abKey)
    if abGroup == group then
        return true
    end
    return false
end

--检测轮盘是否是正常的滚动 A返回True（不走特殊等待逻辑）
function GameGlobalConfig:checkNormalReel()
    return false --self:checkABtestGroupA("SpinSpeed")
end

--是否是旧的集卡link标签
function GameGlobalConfig:checkOldCardLink()
    return self:checkABtestGroupA("TargetLink")
end

--是否是旧的弹窗
function GameGlobalConfig:checkOldFindUI()
    return self:checkABtestGroupA("FindItemUI")
end

--是否是旧的弹窗
function GameGlobalConfig:checkBingoUI()
    return self:checkABtestGroupA("BingoUI")
end

-- 是否spin没钱送金币
function GameGlobalConfig:checkNoCoin()
    return self:checkABtestGroupA("Novice")
end

--是否需要选择bet
function GameGlobalConfig:checkSelectBet()
    return self:checkABtestGroupA("BetSelect")
end
--是否采用新任务 questabtest
function GameGlobalConfig:checkNewUserCoins()
    return self:checkABtestGroupA("NewUserCoins")
end

--是否采用竖版常规促销
function GameGlobalConfig:checkOldSaleUI()
    return self:checkABtestGroupA("SaleUI")
end

--是否采用新的商店礼物提示
function GameGlobalConfig:checkNewShowTips()
    return self:checkABtestGroupA("Store")
end
--levelName关卡名称例如:GameScreenCandyBingo key类型LEVEL_ICON_TYPE
function GameGlobalConfig:getLevelIconPath(levelName, key)
    if not levelName then
        return
    end
    local path = nil
    --abtest路径
    if self:checkLevelGroupA(levelName) then
        local abExt = "_abtest.png"
        --关卡解锁图标路径不同
        if key == LEVEL_ICON_TYPE.UNLOCK then
            --test2 "Unlock/ui/GameScreenPowerUp_Unlock_abtest.png
            path = "Unlock/ui/" .. levelName .. "_" .. key .. abExt
        else
            --test2 "newIcons/Order/small/small_level_GameScreenPowerUp_abtest.png
            path = "newIcons/Order/" .. key .. "/" .. key .. "_level_" .. levelName .. abExt
        end
        if util_IsFileExist(path) then
            return path
        end
    end
    --非abtest路径
    local ext = ".png"
    if key == LEVEL_ICON_TYPE.UNLOCK then
        --test1 "Unlock/ui/GameScreenPowerUp_Unlock.png
        path = "Unlock/ui/" .. levelName .. "_" .. key .. ext
    else
        --test1 "newIcons/Order/small/small_level_GameScreenPowerUp.png
        path = "newIcons/Order/" .. key .. "/" .. key .. "_level_" .. levelName .. ext
    end
    return path
end
--关卡是否是A组
function GameGlobalConfig:checkLevelGroupA(levelName)
    -- if not levelName or type(levelName)~="string" or not string.find(levelName,"GameScreen") then
    --     return false
    -- end
    --abtest
    local abtestName = string.sub(levelName, 11, -1) .. "Icon"
    return self:checkABtestGroupA(abtestName)
end

-- 关卡入口显示的AB分组
function GameGlobalConfig:checkLevelVisibleGroup(levelName)
    levelName = levelName or ""
    --abtest
    local abtestName = string.sub(levelName, 11, -1) .. "Visible"
    return (not self:checkABtestGroup(abtestName, "B"))
end

--是否采用新jackpot
function GameGlobalConfig:checkAJackpot(serverName)
    if not serverName then
        return false
    end
    if self.userCategoryConfig and self.userCategoryConfig[serverName .. ":GameOdds"] and self.userCategoryConfig[serverName .. ":GameOdds"] == "B" then
        return true
    end
    return false
end

function GameGlobalConfig:checkABTestDataOpen(data, abtest_key)
    --检测版本是否开启
    if device.platform ~= "mac" then
        if not util_isSupportVersion(data.version) then
            return false
        end
    end
    if abtest_key and abtest_key ~= "" and abtest_key ~= data.abtest_key then
        return false
    end
    --检测等级是否满足
    -- local levelNum = globalData.userRunData.levelNum
    -- if levelNum<data.openLevel then
    --       return false
    -- end
    return true
end

--根据abtest分组名字 分组key 和程序引用名检测是否存在abtest
function GameGlobalConfig:checkUserABTestData(abTestName, groupKey, name, abtest_key)
    local abData = self.abTestConfig[abTestName]
    if not abData then
        return
    end
    local config = abData[groupKey]
    if not config then
        return
    end
    for i = 1, #config do
        local data = config[i]
        if data and data.name == name and self:checkABTestDataOpen(data, abtest_key) then
            return data
        end
    end
end

--获取ABTest数据
function GameGlobalConfig:checkABTestData(name, abtest_key)
    --获取配置信息
    for abTestName, newGroupKey in pairs(self.userCategoryConfig) do
        --检测所有指定分组
        local abData = self:checkUserABTestData(abTestName, newGroupKey, name, abtest_key)
        if abData then
            return abData
        end
    end
end

--获得下载列表
function GameGlobalConfig:getABTestUserList(abTestName, groupKey, resType)
    local abData = self.abTestConfig[abTestName]
    if not abData then
        return
    end
    local config = abData[groupKey]
    if not config then
        return
    end

    local abList = {}
    for i = 1, #config do
        local data = config[i]
        if data and data.resType == resType and self:checkABTestDataOpen(data) then
            abList[#abList + 1] = data
        end
    end
    return abList
end

--获得需要动态下载的内容
function GameGlobalConfig:getABTestDynameicList(vType)
    local dyList = {}
    --获取配置信息
    for abTestName, groupKey in pairs(self.userCategoryConfig) do
        --关卡等进入大厅下载的资源
        if not vType or tonumber(vType) == 1 then
            local abList = self:getABTestUserList(abTestName, groupKey, 2)
            if abList and #abList > 0 then
                for i = 1, #abList do
                    dyList[#dyList + 1] = abList[i]
                end
            end
        end
    end
    return dyList
end

--修改levels.json
function GameGlobalConfig:changeABTestLevelJson()
    for key, var in pairs(ABTEST_LEVELS) do
        local levelInfo = globalData.slotRunData:getLevelInfoByName(key)
        if levelInfo and levelInfo.p_id == var.B[1] then
            local abData = self:checkABTestData(levelInfo.p_levelName, "newLevel")
            if abData and abData.groupKey == "A" then
                levelInfo.p_id = var.A[1]
            end
        end
    end
end

--检测是否存在新的关卡名字
function GameGlobalConfig:getABTestLevelName(levelName)
    local data = self:checkABTestData(levelName)
    if not data then
        --B组为ABtest新的关卡如果存在返回新关卡的服务器名称
        if ABTEST_LEVELS[levelName] and ABTEST_LEVELS[levelName]["B"] and ABTEST_LEVELS[levelName]["B"][2] then
            return ABTEST_LEVELS[levelName]["B"][2]
        end
    end
    return levelName
end
--检测questgameid 是否处于abtest关卡
function GameGlobalConfig:getABTestGameId(gameId)
    for key, var in pairs(ABTEST_LEVELS) do
        if var.A[1] == gameId then
            local data = self:checkABTestData(key, "newLevel")
            if not data then
                return var.B[1]
            end
            return gameId
        end
        if var.B[1] == gameId then
            local data = self:checkABTestData(key, "newLevel")
            if data then
                return var.A[1]
            end
            return gameId
        end
    end
    return gameId
end

function GameGlobalConfig:getABTestGameName(gameName)
    for key, var in pairs(ABTEST_LEVELS) do
        if var.A[2] == gameName then
            local data = self:checkABTestData(key, "newLevel")
            if not data then
                return var.B[2]
            end
            return gameName
        end
        if var.B[2] == gameName then
            local data = self:checkABTestData(key, "newLevel")
            if data then
                return var.A[2]
            end
            return gameName
        end
    end
    return gameName
end

--获取ABTest数据 中首关分组
function GameGlobalConfig:checkABTestFirstGameData()
    --获取配置信息
    local firstGameData = self.userCategoryConfig["FirstGame"]
    if firstGameData then
        return firstGameData
    end
    return nil
end

-- 解析活动公告数据
function GameGlobalConfig:parseActivityNoticeConfig(data)
    data = data or {}
    self.activityNoticeDatas = {}

    for i = 1, #data do
        local _noticeInfo = ActivityEntranceConfig:create()
        _noticeInfo:parseData(data[i])
        table.insert(self.activityNoticeDatas, _noticeInfo)
    end
end

function GameGlobalConfig:getActivityNoticeConfig()
    return self.activityNoticeDatas
end

-- 扩圈系统 数据 判断该玩家是否是 支持扩圈系统
function GameGlobalConfig:parseExpandCircleConfig(_data)
    self.m_expandCircleConfig = _data
end
function GameGlobalConfig:getExpandCircleConfig()
    return self.m_expandCircleConfig
end

-- 检查是否可以弹出 选择关卡bet页面
function GameGlobalConfig:checkChooseBetOpen()
    local currLevel = globalData.userRunData.levelNum
    if currLevel >= globalData.constantData.CLUB_OPEN_LEVEL then
        -- 进入bet 用高倍场开启等级来判断（共用）
        return true
    end

    if globalData.deluexeClubData:getDeluexeClubStatus() then
        return true
    end

    return false
end

-- cxc 2021年06月24日20:36:18 新手期改的功能添加条件判断 B组调整
-- cxc 2021年07月28日20:15:33 新手期改的功能增加C组  C组再B组的基础上增加特性
-- csc 2021年08月25日11:42:30 新手期 A组同步第二期功能 , 同时A组添加第三期新特性
-- csc 2021年10月26日15:00:30 新手期4.0 C组同步第三期特性，同时C组添加4.0
--[[
    --@_groupType: 当前是第几期 
    cxc之前写法:
    NoviceGroup_B 第一期
    NoviceGroup_C 第二期
    csc修改后写法:
    Season_3
    Season_.....
]]
function GameGlobalConfig:checkUseNewNoviceFeatures(_groupType)
    -- _groupType = _groupType or "NoviceGroup_B"
    -- if _groupType == "NoviceGroup_B" then
    --     return globalData.constantData.NOVICE_FEATURES_GROUP == "B" or globalData.constantData.NOVICE_FEATURES_GROUP == "C" or globalData.constantData.NOVICE_FEATURES_GROUP == "A"
    -- elseif _groupType == "NoviceGroup_C" then
    --     return globalData.constantData.NOVICE_FEATURES_GROUP == "C" or globalData.constantData.NOVICE_FEATURES_GROUP == "A"
    -- elseif _groupType == "Season_3" then
    --     return globalData.constantData.NOVICE_FEATURES_GROUP == "A" or globalData.constantData.NOVICE_FEATURES_GROUP == "C"
    -- elseif _groupType == "Season_4" then
    --     return globalData.constantData.NOVICE_FEATURES_GROUP == "C" or globalData.constantData.NOVICE_FEATURES_GROUP == "A"
    -- end

    -- return false
    return true
end

function GameGlobalConfig:getIsUseDynamicDLDispather()
    local verInfo = self:getVerInfo()

    local useNum = verInfo["useDynamicDispatherNum"] or 0

    return useNum > 0 ,useNum
end

return GameGlobalConfig
