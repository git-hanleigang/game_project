--线上报错检测修复通用工具类

--目前报错率高需要清除md5的资源列表
GD.util_csbErrorInfo = {
    ["CardRes/common201904/CardComplete201903_challenge_layer.csb"] = "CardsRes201904",
    ["CardRes/common201904/cash_nado_wheel_layer.csb"] = "CardsRes201904",
    ["CardRes/season201904/cash_album_layer.csb"] = "CardsRes201904",
    ["CardRes/common201904/cash_wild_exchange_layer.csb"] = "CardsRes201904",
    ["CardRes/season201904/cash_season_time.csb"] = "CardsRes201904",
    ["CardRes/season201903/cash_drop_layer.csb"] = "CardsBase201903",
    ["QuestBaseRes/QuestMainLayer.csb"] = "Activity_QuestBase",
    ["QuestBaseRes/QuestLobbyRank.csb"] = "Activity_QuestBase",
    ["QuestChristmasRes/QuestMainLayer.csb"] = "Activity_QuestChristmas",
    ["Activity/DinnerLand/csb/GameSceneUiNode.csb"] = "Activity_DinnerLand",
    ["Activity/MainUI/LC_MainUI.csb"] = "Activity_LuckyChallenge",
    ["Activity/Blast/GameSceneUiNode.csb"] = "Activity_Blast",
    ["Activity/Blast/BlastMainmap.csb"] = "Activity_Blast",
    ["Activity/ScreenDeluexeClub.csb"] = "Activity_DeluexeClub",
    ["Activity/Activity_DeluexeClub_tip.csb"] = "Activity_DeluexeClub"
    -- [""] = "",
}
--打印搜索路径列表
GD.util_filePathErrorInfo = {
    {"createRewardListView", "src/manager/ItemManager"},
    {"setOverAniRunFunc", "src/Levels/BaseDialog"},
    {"CardCode", "Dynamic/CardCode"},
    {"CardRes", "Dynamic/CardRes"}
}

--获取文件大小
function GD.util_getluaFileLength(filePath)
    if not filePath then
        return -2
    end
    release_print("-------------------------util_getluaFileLength = " .. filePath)
    local len = cc.FileUtils:getInstance():getFileSize(filePath) or 0
    return len
end

--获取文件目录
function GD.util_getFileDirectory(filePath)
    if not filePath then
        return
    end
    if cc.FileUtils:getInstance():isDirectoryExist(filePath) then
        return filePath
    end
    local rPath = string.reverse(filePath)
    local pos = string.find(rPath, "/")
    if not pos then
        return
    end
    local newFilePath = string.sub(filePath, 1, -pos)
    return newFilePath
end

--输出错误文件log
function GD.util_printCsbErrorLog(resourceFilename)
    --没有文件时候添加打印
    if util_IsFileExist(resourceFilename) then
        --如果文件存在解析不了打印文件大小
        local _fullPath = cc.FileUtils:getInstance():fullPathForFilename(resourceFilename)
        local strMsg = string.format("ExistFile!!! path = %s  strLen = %d", _fullPath, util_getluaFileLength(resourceFilename))
        print(strMsg)
        release_print(strMsg)
    else
        --如果文件不存在
        local isDirectory = false
        local newPath = util_getFileDirectory(resourceFilename)
        if cc.FileUtils:getInstance():isDirectoryExist(newPath) then
            --如果文件所在目录存在打印目录
            local strMsg = string.format("DirectoryExist and not ExistFile!!! path = %s  directory = %s", resourceFilename, newPath)
            print(strMsg)
            release_print(strMsg)
        else
            --如果文件所在目录不存在也打印目录
            local strMsg = string.format("not DirectoryExist and not ExistFile!!! path = %s  directory = %s", resourceFilename, newPath)
            print(strMsg)
            release_print(strMsg)
        end
    end
end

--清除本地MD5
function GD.util_checkClearCsbMd5(resourceFilename)
    local zipName = util_csbErrorInfo[resourceFilename]
    local skipSupportVersion = false
    --集卡资源老包也支持清理功能
    if zipName and zipName == "CardsRes201904" then
        skipSupportVersion = true
    end
    --支持版本
    if not util_isSupportVersion("1.3.7") and skipSupportVersion == false then
        return
    end
    local isPopView = false
    if zipName then
        globalDynamicDLControl:setVersion(zipName, "")
        isPopView = true
    end

    --检测关卡
    local levelIndex = string.find(resourceFilename, "GameScreen")
    if levelIndex then
        local levelIndexEnd = string.find(resourceFilename, "Bg.csb")
        if not levelIndexEnd then
            levelIndexEnd = string.find(resourceFilename, ".csb")
        end
        if levelIndexEnd and levelIndexEnd > levelIndex then
            local levelName = string.sub(resourceFilename, levelIndex, levelIndexEnd - 1)
            if levelName then
                gLobaLevelDLControl:setVersion(levelName, "")
            end
            isPopView = true
        end
    end

    if isPopView then
        gLobalViewManager:showReConnectNew(nil, nil, nil, nil, true)
        --     function()
        --         if gLobalGameHeartBeatManager then
        --             gLobalGameHeartBeatManager:stopHeartBeat()
        --         end
        --         util_restartGame()
        --     end
        -- )
    end
end

--根据开始和结束符截取字符串
function GD.util_string_clip(orgStr, startKey, endKey, maxLen)
    if not orgStr or not startKey or not endKey or not maxLen then
        return
    end
    local startIndex = string.find(orgStr, startKey)
    if startIndex then
        startIndex = startIndex + string.len(startKey)
        local endIndex = string.find(orgStr, endKey, startIndex)
        if endIndex then
            if endIndex - startIndex <= maxLen then
                return string.sub(orgStr, startIndex, endIndex - 1)
            else
                orgStr = string.sub(orgStr, endIndex)
                return util_string_clip(orgStr, startKey, endKey, maxLen)
            end
        end
    end
end

--发送日志给splunk
function GD.util_sendToSplunkMsg(msgType, msg)
    if msg and gLobalSendDataManager and gLobalSendDataManager.getLogGameLoad and gLobalSendDataManager:getLogGameLoad().sendErrorDirectoryLog then
        msg = "CTLua-Error = \n" .. msg
        gLobalSendDataManager:getLogGameLoad():sendErrorDirectoryLog(msgType, msg)
    end
end

--发送错误路径到splunk
function GD.util_printErrorDirectory(errorInfo, errorMessage)
    if errorInfo and #errorInfo > 0 then
        local strLog = tostring(errorMessage) .. "\nfilePath = \n"
        for k, v in ipairs(errorInfo) do
            local size = cc.FileUtils:getInstance():getFileSize(v) or 0
            strLog = strLog .. tostring(v) .. "-" .. tostring(size) .. "| \n"
        end
        util_sendToSplunkMsg("errorDirectory", strLog)
    end
end

--打印搜索路径
function GD.util_checkPrintSearchPaths()
    local isPrint = nil
    if device.platform == "ios" then
        if util_isSupportVersion("1.4.5") then
            isPrint = true
        end
    elseif device.platform == "android" then
        if util_isSupportVersion("1.4.1") then
            isPrint = true
        end
    end
    if isPrint then
        local searchPaths = cc.FileUtils:getInstance():getSearchPaths()
        for i = 1, #searchPaths do
            local value = searchPaths[i]
            release_print(value)
            print(value)
        end
    end
end

--关闭ios buglylog
function GD.util_closeBuglyLog()
    if util_isSupportVersion("1.3.8") then
        if device.platform == "ios" then
            buglySetSendLogFlag(false)
        end
    end
end
