cc.FileUtils:getInstance():setPopupNotify(false)

require "config"
require "cocos.init"
if DEBUG == 2 then
    local breakSocketHandle, debugXpCall = require("LuaDebugjit")("localhost", 7003)
    cc.Director:getInstance():getScheduler():scheduleScriptFunc(breakSocketHandle, 0.3, false)
    release_print(string.format("该设备的可写路径为:%s", device.writablePath))
end
--[[
    打印传回的服务器数据(分段打印)
]]
local function printServerMsgData()
    --分割打印字符串
    if globalData.slotRunData.severGameJsonData then
        local strLen = string.len(globalData.slotRunData.severGameJsonData)
        local maxLen = 900
        local curLen = 0
        if strLen > maxLen then
            if device.platform == "mac" then
                print("分段打印server数据:")
            else
                release_print("分段打印server数据:")
            end

            for index = 1, math.ceil(strLen / maxLen) do
                local str = ""
                if curLen + maxLen < strLen then
                    str = string.sub(globalData.slotRunData.severGameJsonData, curLen, curLen + maxLen)
                    curLen = curLen + maxLen + 1
                else
                    str = string.sub(globalData.slotRunData.severGameJsonData, curLen, -1)
                    curLen = strLen
                end
                if device.platform == "mac" then
                    print(str)
                else
                    release_print(str)
                end
            end
        end
    end
end

GD.sendBuglyLuaException = function(errMsg, isSendSplunk)
    local _errMsg = errMsg or ""
    local versionCode = 0
    if DEBUG == 0 then
        if util_getUpdateVersionCode then
            versionCode = util_getUpdateVersionCode(false)
        end
        _errMsg = "V" .. tostring(versionCode) .. " " .. tostring(errMsg)
        if MARKETSEL and device.platform == "android" then
            _errMsg = tostring(MARKETSEL) .. " " .. _errMsg
        end
        gLobalBuglyControl:luaException(_errMsg, debug.traceback())
        if isSendSplunk and util_sendToSplunkMsg ~= nil then
            util_sendToSplunkMsg("luaError", _errMsg)
        end
    end
    return versionCode, _errMsg
end

function __G__TRACKBACK__(errorMessage)
    if device.platform == "mac" then
        print(errorMessage)
        print(debug.traceback())
    else
        local versionCode, sendErrMsg = sendBuglyLuaException(errorMessage, true)

        release_print(errorMessage)
        release_print(debug.traceback())

        release_print("res_Code = V" .. tostring(versionCode))
        release_print("下载类型 = " .. tostring(CC_DOWNLOAD_TYPE))
        if globalData then
            -- release_print("sever传回的数据：  " .. (globalData.slotRunData.severGameJsonData or "isnil"))
            release_print("Headers requestId =" .. (globalData.requestId or "isnil"))
            release_print(
                "error_userInfo_ udid=" ..
                    (globalData.userRunData.userUdid or "isnil") ..
                        " machineName=" .. (globalData.slotRunData.gameModuleName or "isLobby") .. " gameSeqID = " .. " gameSeqID = " .. (globalData.seqId or "")
            )

            if globalData.slotRunData.gameModuleName ~= nil and globalData.slotRunData.gameModuleName ~= "" and gLobaLevelDLControl ~= nil and gLobaLevelDLControl.getVersion ~= nil then
                local md5 = gLobaLevelDLControl:getVersion("GameScreen" .. globalData.slotRunData.gameModuleName) or ""
                release_print("关卡存储的md5值" .. md5)
            end

            printServerMsgData()
        end

        if gLobalDataManager then
            gLobalDataManager:flushData()
        end

        --打印搜索路径
        if util_checkPrintSearchPaths then
            util_checkPrintSearchPaths()
        end
    end

    local fixLostFileFunc = function()
        --修复线上热更丢失文件导致的报错，强制重启
        local regularList = {
            "module '.+' not found",
            "attempt to call method '.+' %(a nil value%)",
            "attempt to call field '.+' %(a nil value%)",
            "attempt to index field '.+' %(a nil value%)"
        }
        local flagIdx = nil
        for _key, _value in ipairs(regularList) do
            local errPos1, errPos2 = string.find(errorMessage, _value)
            if errPos1 ~= nil and errPos2 ~= nil then
                flagIdx = _key
                break
            end
        end
        if flagIdx then
            local errorCount = 0
            local loadingErrorFilePath = device.writablePath .. "LoadingError.dat"
            -- if gLobalViewManager == nil or gLobalViewManager.isLogonView == nil or gLobalViewManager:isLogonView() then
            if cc.FileUtils:getInstance():isFileExist(loadingErrorFilePath) then
                errorCount = cc.FileUtils:getInstance():getStringFromFile(loadingErrorFilePath) or "0"
                errorCount = tonumber(errorCount) or 0
            end

            errorCount = errorCount + 1
            cc.FileUtils:getInstance():writeStringToFile(tostring(errorCount), loadingErrorFilePath)
            -- end

            local filePath = ""
            local _str = ""
            if flagIdx == 1 then
                -- 加载模块报错
                local _bPos, _ePos = string.find(errorMessage, "'.+' not found:")
                if _bPos and _ePos and _bPos > 0 and _ePos > 0 and (_bPos + 1) < (_ePos - 12) then
                    _str = string.sub(errorMessage, _bPos + 1, _ePos - 12)
                    filePath, _ = string.gsub(_str, "%.", "/")
                    filePath = filePath .. ".luac"
                end
            else
                -- 调用方法或参数报错
                local _bPos, _ePos = string.find(errorMessage, '%[string ".-"%]')
                if _bPos then
                    filePath = string.sub(errorMessage, _bPos + 9, _ePos - 2)
                end
            end
            if filePath ~= "" then
                local isExist = cc.FileUtils:getInstance():isFileExist(filePath)
                if not isExist then
                    release_print("--main-- " .. _str .. "is not exist!!! filePath = " .. filePath)
                else
                    local _fullPath = cc.FileUtils:getInstance():fullPathForFilename(filePath)
                    local _fileSize = cc.FileUtils:getInstance():getFileSize(filePath) or 0
                    local strMsg = string.format("--main-- ExistFile!!! path = %s  len = %d", _fullPath, _fileSize)
                    release_print(strMsg)
                end
            end

            if errorCount >= 3 then
                if util_sendToSplunkMsg ~= nil then
                    util_sendToSplunkMsg("cleanCacheData", errorMessage)
                end

                if device.platform ~= "mac" then
                    local writePath = device.writablePath
                    release_print("--main-- writablePath = " .. writePath)

                    local srcWritePath = writePath .. "src/"
                    local resWritePath = writePath .. "res/"

                    local isRemoved = false
                    if cc.FileUtils:getInstance():isDirectoryExist(srcWritePath) then
                        cc.FileUtils:getInstance():removeDirectory(srcWritePath)
                        isRemoved = true
                    end

                    if cc.FileUtils:getInstance():isDirectoryExist(resWritePath) then
                        cc.FileUtils:getInstance():removeDirectory(resWritePath)
                        isRemoved = true
                    end

                    if util_getUpdateVersionCode then
                        release_print("--main-- fixLostFileFunc|" .. util_getUpdateVersionCode() .. "|")
                    end

                    cc.FileUtils:getInstance():removeFile(loadingErrorFilePath)
                    cc.FileUtils:getInstance():purgeCachedEntries()

                    -- cc.UserDefault:getInstance():deleteAllValues()
                    local packageUpdateVersion = xcyy.GameBridgeLua:getPackageUpdateVersion()
                    if util_isSupportVersion("1.7.8", "ios") or util_isSupportVersion("1.8.6", "android") then
                        if gLobalDataManager then
                            gLobalDataManager:setVersion("lastUpdateVer", tostring(packageUpdateVersion))
                        end
                    else
                        cc.UserDefault:getInstance():setStringForKey("lastUpdateVersion", packageUpdateVersion)
                        cc.UserDefault:getInstance():flush()
                    end
                end

                if util_restartGame then
                    util_restartGame()
                end
            end

            -- xcyy.XCDownloadManager:stopAllDownload()
            -- xcyy.SlotsUtil:restartGame()
            return
        else
            if gLobalNoticManager ~= nil then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFI_LUA_ERROR, errorMessage)
            end
        end
    end

    if DEBUG == 2 then
        showErrorDialog(errorMessage, fixLostFileFunc)

        if debugXpCall ~= nil then
            debugXpCall()
        end
    else
        fixLostFileFunc()
    end
end

GD.showErrorDialog = function(errorMsg, callback)
    if DEBUG ~= 2 then
        return
    end
    
    local nowScene = cc.Director:getInstance():getRunningScene()
    if nowScene ~= nil and nowScene:getChildByTag(99999) == nil then
        local _errMsg = "errorMessage " .. tostring(errorMsg) .. "\n" .. tostring(debug.traceback())
        -- local view = util_createView("views.logon.Logonfailure", false, true)
        local view = util_createView("views.setting.CheckLogLayer", _errMsg)
        nowScene:addChild(view, 99999, 99999)
        -- view:findChild("Logon_warning_2"):setVisible(false)
        -- view:findChild("lab_describ_1_1"):setString(_errMsg)
        -- view:findChild("lab_describ_2_1"):setString("globalData.userRunData.userUdid " .. globalData.userRunData.userUdid)
        if device.platform ~= "mac" then
            view:setOverFunc(callback)
        end
    end
end

local function resetSearchPaths()
    local _paths = {}
    _paths[#_paths + 1] = device.writablePath
    _paths[#_paths + 1] = device.writablePath .. "src"
    _paths[#_paths + 1] = device.writablePath .. "res"
    _paths[#_paths + 1] = device.writablePath .. "src/protobuf"
    _paths[#_paths + 1] = "src"
    _paths[#_paths + 1] = "res"
    _paths[#_paths + 1] = "src/protobuf"

    cc.FileUtils:getInstance():setSearchPaths(_paths)
end

local function main()
    if CC_SHOW_FPS == true or DEBUG == 2 then
        cc.Director:getInstance():setDisplayStats(true)
    end
    -- cc.Director:getInstance():getScheduler():setTimeScale(5)
    cc.Director:getInstance():setAnimationInterval(1.0 / 60)

    resetSearchPaths()

    --bugly
    local BuglyControl = require "sdk.BuglyControl"
    GD.gLobalBuglyControl = BuglyControl:create()
    gLobalBuglyControl:setId("main none")
    local GameInit = require "GameInit"
    GameInit:getInstance():init()
    local logonLayer = util_createView("views.logon.LogonLoading")
    gLobalViewManager:changeScene(SceneType.Scene_Logon, logonLayer)
    if util_isSupportVersion("1.7.3", "android") then
        GameInit:getInstance():initAndroidCall()
    end
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
