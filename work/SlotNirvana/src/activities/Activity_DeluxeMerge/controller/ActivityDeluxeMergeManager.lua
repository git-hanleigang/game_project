--[[
	高倍场合成 管理类
	张侃侃 20210726
]]
local ActivityDeluxeMergeManager = class("ActivityDeluxeMergeManager", BaseActivityControl)
local NetWorkBase = util_require("network.NetWorkBase")
local MergeMapConfigPath = "mapConfig.lua"
local MergeLocalConfig = {
    mapLocalConfig = "Activity/deluexe_compose_level",
    resourceLocalConfig = "Activity/deluexe_compose_resource",
    commonLocalConfig = "Activity/Activity_DeluxeMergeConfig"
}

ActivityDeluxeMergeManager.MAX_GUIDESTEP = 5
ActivityDeluxeMergeManager.MERGE_GUIDE_KEY = "MergeGameGuideKey"

function ActivityDeluxeMergeManager:ctor()
    ActivityDeluxeMergeManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DeluxeClubMergeActivity)

    self.m_saveFileName = MergeMapConfigPath
    if globalData.userRunData.userUdid then
        local udidDesc = util_string_split(globalData.userRunData.userUdid, ":")
        if udidDesc[1] then
            self.m_saveFileName = udidDesc[1] .. MergeMapConfigPath
        end
    end
    self.m_netModel = gLobalNetManager:getNet("DeluxeMergeGame") -- 网络模块

    self.m_localPointsSaveTime = "0" --本地的数据存储时间戳
    self.m_usedPointsSaveTime = "0" --使用的数据存储时间戳
    self.m_usedPointsChapter = nil --使用 哪个章节的数据
    self.m_serverPointsData = nil --服务器地图的节点数据 数组
    self.m_localPointsData = nil --本地存储的地图的节点数据 数组
    self.m_localPointsChapter = 0 --本地存储的 哪个章节的数据
    self.m_usedPointsData = nil --当前使用的 地图的节点数据 数组
    self.m_canSave = false --是否可以存储数据

    self.m_usedPointsDataKeyMap = nil --当前使用的 地图的节点数据 map 键值对

    self.m_stopOtherLogic = false --耗时操作（检测或动画）中屏蔽其他功能逻辑

    self.m_isShowingReward = {} --耗时操作（检测或动画）中屏蔽其他功能逻辑
    self.m_waitingForReward = {}
    self.m_levelReward = {}

    self.m_isRequestPlayID = 0 --

    self.m_dropPropsBagList1 = {} -- Low
    self.m_dropPropsBagList2 = {} -- Middle
    self.m_dropPropsBagList3 = {} -- High
    self.m_dropPropsBagList4 = {} -- max

    self.m_docheckServerData = false --检测服务器数据正确性

    self:initDatas()
end

function ActivityDeluxeMergeManager:resetUsedChapterID()
    local activityData = self:getRunningData()
    if activityData then
        local currentChapterId = activityData:getCurChapterId()
        self.m_usedChapterID = currentChapterId
    end
end

-- function ActivityDeluxeMergeManager:playBgMusic()
--     if self.m_isPlayingBgMusic then
--         return
--     end
--     self.m_isPlayingBgMusic = true
--     release_print("ActivityDeluxeMergeManager:playBgMusic ----start-- ")
--     gLobalSoundManager:setLockBgMusic(false)
--     gLobalSoundManager:setLockBgVolume(false)
--     gLobalSoundManager:playBgMusic("Sounds/Merge_bgm.mp3")
--     gLobalSoundManager:setLockBgMusic(true)
--     gLobalSoundManager:setLockBgVolume(true)
--     release_print("ActivityDeluxeMergeManager:playBgMusic ----end-- ")
-- end
-- function ActivityDeluxeMergeManager:stopBgMusic()
--     self.m_isPlayingBgMusic = false
--     release_print("ActivityDeluxeMergeManager:stopBgMusic ----start-- ")
--     gLobalSoundManager:setLockBgMusic(false)
--     gLobalSoundManager:setLockBgVolume(false)
--     if self.m_formClub then
--         gLobalSoundManager:playBgMusic("Activity/DeluexeClubSounds/activity_delexe_bgm.mp3")
--         gLobalSoundManager:setLockBgMusic(true)
--         gLobalSoundManager:setLockBgVolume(true)
--     else
--         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESET_BG_MUSIC)
--     end
--     release_print("ActivityDeluxeMergeManager:stopBgMusic ----end-- ")
-- end

function ActivityDeluxeMergeManager:getUsedChapterID()
    if not self.m_usedChapterID then
        self:resetUsedChapterID()
    end
    return self.m_usedChapterID
end

function ActivityDeluxeMergeManager:setUsedChapterMaxLevel(maxLevel)
    self.m_usedChapterMaxLevel = maxLevel
end

function ActivityDeluxeMergeManager:getUsedChapterMaxLevel()
    return self.m_usedChapterMaxLevel
end

function ActivityDeluxeMergeManager:saveGuidStepIDByLayerKey(layerKey, stepId)
    local baseStepId = 0
    if layerKey == "ClubView" then
        baseStepId = 100
    elseif layerKey == "MergeMainView" then
        baseStepId = 200
    elseif layerKey == "MergeGameView" then
        baseStepId = 300
        if stepId > 8 then
            gLobalDataManager:setBoolByField("QuicklyMerge_Guide",true) 
        end
    elseif layerKey == "MergeGameView_Rank" then
        baseStepId = 400
    elseif layerKey == "MergeGameView_Quick" then
        baseStepId = 500
    end
    globalData.mergeGameGuideStepId = baseStepId + stepId
    self:sendExtraRequest(baseStepId + stepId)
end

function ActivityDeluxeMergeManager:getCurStepIdByLayerKey(layerKey)
    local allStepId = globalData.mergeGameGuideStepId ~= nil and tonumber(globalData.mergeGameGuideStepId) or 0
    local baseStepId = 0
    if layerKey == "ClubView" then
        baseStepId = 100
    elseif layerKey == "MergeMainView" then
        baseStepId = 200
    elseif layerKey == "MergeGameView" then
        baseStepId = 300
    elseif layerKey == "MergeGameView_Rank" then
        baseStepId = 400
    elseif layerKey == "MergeGameView_Quick" then
        baseStepId = 500
    end
    local stepId = allStepId - baseStepId
    if stepId < 1 then
        stepId = 1
    end
    if layerKey == "MergeGameView_Quick" and stepId < 7 then
        stepId = 7
    end
    if layerKey == "MergeGameView" and stepId == 3 then
        local uid = globalData.userRunData.uid
        local markPoint = gLobalDataManager:getNumberByField(layerKey .. uid .. "_3", 0)
        if markPoint > 0 then
            stepId = 4
        end
        stepId = 4
    end
    return stepId
end

function ActivityDeluxeMergeManager:sendExtraRequest(stepId)
    local actionData = gLobalSendDataManager:getNetWorkFeature():getSendActionData(ActionType.SyncUserExtra)
    local dataInfo = actionData.data
    local extraData = {}
    extraData[ExtraType.mergeGameGuideStepId] = stepId
    dataInfo.extra = cjson.encode(extraData)
    gLobalSendDataManager:getNetWorkFeature():sendMessageData(actionData)
end

function ActivityDeluxeMergeManager:initDatas()
    if not self:isDownloadRes() then
        self.m_initDatas = false
        return
    end
    local activityData = self:getRunningData()
    if activityData then
        self.m_initDatas = true
        self:initConfig()
        local currentChapterId = activityData:getCurChapterId()
        self.m_usedPointsChapter = currentChapterId
        self.m_localPointsChapter = currentChapterId
        self:checkReadLocalPointsConfig()
    end
end

function ActivityDeluxeMergeManager:initConfig()
    if not self.m_mapLocalConfig then
        local config = util_getRequireFile(MergeLocalConfig.mapLocalConfig)
        if config then
            self.m_mapLocalConfig = {}
            for k, chapter in pairs(config) do
                local oneData = {}
                oneData.chapterId = k
                oneData.rowCount = chapter[2]
                oneData.tandemCount = chapter[3]
                oneData.bgResource = chapter[4]
                oneData.groundResource_1 = chapter[5]
                oneData.groundResource_2 = chapter[6]
                oneData.pointsMap = self:formatPointsData(chapter[1], chapter[5], chapter[6])
                oneData.bgCenterOffset_x = chapter[7]
                oneData.bgCenterOffset_y = chapter[8]
                oneData.chapterName = chapter[9]
                self.m_mapLocalConfig[k] = oneData
            end
        else
            assert(config, "章节配置未能找到 ！！！！")
        end
    end

    if not self.m_resourceLocalConfig then
        self.m_resourceLocalConfig_Index = {}
        self.m_resourceNameLocalConfig = {}
        local config = util_getRequireFile(MergeLocalConfig.resourceLocalConfig)
        if config then
            self.m_resourceLocalConfig = {}
            for k, resource in pairs(config) do
                local resourceType = resource[1]
                local resourceLevel = resource[2]
                local key = self:getTypeAndLevelKey(resourceType, resourceLevel)
                local resourcePath = resource[3] ~= "" and resource[3] or "Activity/image/" .. key .. ".png"
                local spineName = resource[4]
                if resource[5] then
                    self.m_resourceNameLocalConfig[resourceType] = resource[5]
                end
                self.m_resourceLocalConfig[key] = {resourcePath, spineName}
                self.m_resourceLocalConfig_Index[k] = {resourcePath, spineName}
            end
        end
    end

    if not self.m_commonLocalConfig then
        self.m_commonLocalConfig = util_getRequireFile(MergeLocalConfig.commonLocalConfig)
    end
end

function ActivityDeluxeMergeManager:formatPointsData(pointList, groundResource_1, groundResource_2)
    local oneChapterPoints = {}
    if pointList then
        for k, point in pairs(pointList) do
            local oneData = {}
            oneData.pointId = k
            oneData.rowId = point.rowIndex
            local resourceArray = {groundResource_2, groundResource_1}
            if point.rowIndex % 2 == 0 then
                resourceArray = {groundResource_1, groundResource_2}
            end
            oneData.tandemId = point.colIndex
            oneData.allowPlace = point.operateFlag
            oneData.castleBuilding = point.bigBuildingFlag
            oneData.castleBuildingID = point.buildingID
            oneData.initialResources = resourceArray[point.colIndex % 2 + 1]
            oneData.showLand = point.visibleFlag
            oneData.buildingType = 0
            oneData.buildingLevel = 0
            local key = self:getRowAndTandemKey(oneData.rowId, oneData.tandemId)
            oneChapterPoints[#oneChapterPoints + 1] = oneData
        end
        table.sort(
            oneChapterPoints,
            function(a, b)
                if a.rowId == b.rowId then
                    return a.tandemId < b.tandemId
                end
                return a.rowId < b.rowId
            end
        )
    end
    return oneChapterPoints
end

function ActivityDeluxeMergeManager:getChapterConfigByChapterId(chapterId)
    self:initConfig()
    assert(self.m_mapLocalConfig, "getChapterConfigByChapterId ！！！！总章节：" .. chapterId)
    assert(self.m_mapLocalConfig[chapterId], "getChapterConfigByChapterId！！！！单章节：" .. chapterId)
    local data = self.m_mapLocalConfig[chapterId]
    return clone(data)
end

function ActivityDeluxeMergeManager:getTypeAndLevelKey(buildingType, buildingLevel)
    return tonumber(buildingType) * 1000 + tonumber(buildingLevel)
end
function ActivityDeluxeMergeManager:getRowAndTandemKey(rowId, tandemId)
    return rowId * 1000 + tandemId
end

function ActivityDeluxeMergeManager:getResourceNameByType(buildingType)
    local name = self.m_resourceNameLocalConfig[buildingType] or "ERROR"
    return name
end

function ActivityDeluxeMergeManager:getResourcePathByTypeAndLevel(buildingType, buildingLevel)
    local key = self:getTypeAndLevelKey(buildingType, buildingLevel)
    local pathList = self.m_resourceLocalConfig[key] or {"1001.png", ""} --{sp, spinePath}
    return pathList[1] or "1001.png"
end
function ActivityDeluxeMergeManager:getSpinePathByTypeAndLevel(buildingType, buildingLevel)
    local key = self:getTypeAndLevelKey(buildingType, buildingLevel)
    local pathList = self.m_resourceLocalConfig[key] or {"1001.png", ""} --{sp, spinePath}
    return pathList[2] or ""
end

function ActivityDeluxeMergeManager:getResourcePathByIndex(index)
    local pathList = self.m_resourceLocalConfig_Index[index] or {"1001.png", ""} --{sp, spinePath}
    return pathList[1] or "1001.png"
end
function ActivityDeluxeMergeManager:getSpinePathByIndex(index)
    local pathList = self.m_resourceLocalConfig_Index[index] or {"1001.png", ""} --{sp, spinePath}
    return pathList[2] or ""
end

function ActivityDeluxeMergeManager:getCurrentChapterData()
    local currentChapterData = {}
    local activityData = self:getRunningData()
    if activityData then
        local currentChapterId = activityData:getCurChapterId()
        local baseChapterData = activityData:getAllChaptersData()[currentChapterId]
        baseChapterData.config = self:getChapterConfigByChapterId(currentChapterId)
        if not baseChapterData.config then
            return nil
        end
        currentChapterData.baseChapterData = baseChapterData
        currentChapterData.pointsData = self:getPointsData(activityData, currentChapterId, baseChapterData.config)
        currentChapterData.saleData = activityData:getAllSaleData()
        currentChapterData.storeData = activityData:getAllStoreData()
    else
        -- currentChapterData.baseChapterData = self:getChapterConfigByChapterId(1)
        -- currentChapterData.pointsData = self:getPointsData(activityData, 1, self:getChapterConfigByChapterId(1))
    end

    return currentChapterData
end

function ActivityDeluxeMergeManager:checkIsUseLocalPointsData(currentChapterId)
    local result = false
    if tonumber(currentChapterId) > tonumber(self.m_localPointsChapter) then
        result = true
    end
    return result
end

function ActivityDeluxeMergeManager:changeChapter()
    -- 清空本地存储
    self.m_usedPointsData = {}
    self.m_localPointsData = {}
    self.m_usedPointsDataKeyMap = {}
    self.m_usedPointsSaveTime = "0"
    self.m_localPointsSaveTime = "0"
    -- 有可能会带到下一章去 清空一下
    local activityData = self:getRunningData()
    if activityData then
        activityData:clearCell()
    end
    self:savePointsData(true)
end

function ActivityDeluxeMergeManager:setchangeChapter(changeChapter)
    self.m_isChangeChapter = changeChapter
end
function ActivityDeluxeMergeManager:getchangeChapter()
    if not self.m_isChangeChapter then
        self.m_isChangeChapter = false
    end
    return self.m_isChangeChapter
end

-- 是否跳转到选择章节界面
function ActivityDeluxeMergeManager:setGoToLevelView(_bGoLevelView)
    self.m_bGoLevelView = _bGoLevelView
end
function ActivityDeluxeMergeManager:getGoToLevelView()
    return self.m_bGoLevelView
end

--过场动画
function ActivityDeluxeMergeManager:afterChangeChapter()
    self:tryEnterMergeMainView(true)
end

function ActivityDeluxeMergeManager:formatSeverPointsData(chapterConfig, severPointsData)
    local serverDates = clone(chapterConfig.pointsMap)
    for i, point in ipairs(serverDates) do
        if point.showLand and point.allowPlace and not point.castleBuilding then
            local key = tonumber(point.rowId) * 1000 + tonumber(point.tandemId)
            local serverPoint = severPointsData[key]
            if serverPoint then
                point.buildingType = serverPoint.buildingType
                point.buildingLevel = serverPoint.buildingLevel
            end
        end
    end
    return serverDates
end

function ActivityDeluxeMergeManager:getPointsData(activityData, currentChapterId, chapterConfig)
    assert(currentChapterId, "currentChapterId ！！！！nil")
    assert(self.m_localPointsChapter, "self.m_localPointsChapter ！！！！nil")
    local severPointSaveTime = activityData:getPointSaveTime()
    local severPointsData = self:formatSeverPointsData(chapterConfig, activityData:getAllPointsData())
    if tonumber(currentChapterId) > tonumber(self.m_localPointsChapter) then
        if (severPointsData == nil or next(severPointsData) == nil) then
            local curTime = self:getCurrentTime()
            self.m_usedPointsSaveTime = "" .. curTime
            self.m_usedPointsData = clone(chapterConfig.pointsMap)
        else
            self.m_usedPointsSaveTime = "" .. severPointSaveTime
            self.m_usedPointsData = clone(severPointsData)
        end
    else
        --self:checkReadLocalPointsConfig()
        local checkPointsData = nil
        local savaData = false
        if self.m_usedPointsSaveTime == "0" then
            if self.m_localPointsSaveTime and self.m_localPointsSaveTime ~= "0" and tonumber(self.m_localPointsSaveTime) >= severPointSaveTime then
                if tonumber(currentChapterId) > tonumber(self.m_localPointsChapter) then
                    --self.m_usedPointsData = clone(severPointsData)
                    savaData = true
                    self.m_usedPointsSaveTime = "" .. severPointSaveTime
                    checkPointsData = severPointsData
                else
                    --self.m_usedPointsData = clone(self.m_localPointsData)
                    if self:checkLocalPointsData(severPointsData, self.m_localPointsData) then
                        self.m_usedPointsSaveTime = self.m_localPointsSaveTime
                        checkPointsData = self.m_localPointsData
                    else
                        self.m_localPointsSaveTime = "0"
                        self.m_localPointsChapter = 0
                        self.m_localPointsData = {}
                        self:removeMergePointsConfig()
                        self.m_usedPointsSaveTime = "" .. severPointSaveTime
                        checkPointsData = severPointsData
                    end
                end
            else
                --self.m_usedPointsData = clone(severPointsData)
                self.m_usedPointsSaveTime = "" .. severPointSaveTime
                checkPointsData = severPointsData
            end
        end
        local changePointsData = {}
        if checkPointsData then
            for i, data in ipairs(checkPointsData) do
                if data.rowId <= chapterConfig.rowCount and data.tandemId <= chapterConfig.tandemCount then
                    changePointsData[#changePointsData + 1] = data
                else
                    local ddd = 0
                end
            end
            self.m_usedPointsData = clone(changePointsData)
        end
        if savaData then
            self:savePointsData(true)
        end
    end

    self.m_usedPointsDataKeyMap = {}
    if self.m_usedPointsData then
        for i, oneData in ipairs(self.m_usedPointsData) do
            local key = self:getRowAndTandemKey(oneData.rowId, oneData.tandemId)
            self.m_usedPointsDataKeyMap[key] = oneData
        end
    end

    return self.m_usedPointsData
end

function ActivityDeluxeMergeManager:checkLocalPointsData(severPointsData, localPointsData)
    local correct = true
    if severPointsData == nil or next(severPointsData) == nil or severPointsData == nil or next(severPointsData) == nil then
        correct = true
    else
        local serverTypeLevelMap = {}
        for i, data in ipairs(severPointsData) do
            if data.buildingType and data.buildingType > 0 and data.buildingLevel and data.buildingLevel > 0 then
                local key = "" .. (data.buildingType * 1000 + data.buildingLevel)
                if serverTypeLevelMap[key] == nil then
                    serverTypeLevelMap[key] = 1
                else
                    serverTypeLevelMap[key] = serverTypeLevelMap[key] + 1
                end
            end
        end
        local localTypeLevelMap = {}
        for i, data in ipairs(localPointsData) do
            if data.allowPlace and data.buildingType and data.buildingType > 0 and data.buildingLevel and data.buildingLevel > 0 then
                local key = "" .. (data.buildingType * 1000 + data.buildingLevel)
                if localTypeLevelMap[key] == nil then
                    localTypeLevelMap[key] = 1
                else
                    localTypeLevelMap[key] = localTypeLevelMap[key] + 1
                end
            end
        end

        for key, v in pairs(serverTypeLevelMap) do
            if localTypeLevelMap[key] ~= v then
                correct = false
                break
            end
        end
    end
    return correct
end

function ActivityDeluxeMergeManager:getCurrentTime()
    local curTime = os.time()
    if globalData.userRunData ~= nil and globalData.userRunData.p_serverTime ~= nil then
        curTime = globalData.userRunData.p_serverTime / 1000
    end
    return curTime
end

-- 获得和上次服务器同步后的 变化点
function ActivityDeluxeMergeManager:getChangedPointsData(isSendAll)
    local changedPointsData = {}
    local activityData = self:getRunningData()
    if isSendAll or not activityData then
        for i, useData in ipairs(self.m_usedPointsData) do
            if useData.showLand and useData.allowPlace and not useData.castleBuilding then
                changedPointsData[#changedPointsData + 1] = {useData.rowId, useData.tandemId, useData.buildingType, useData.buildingLevel}
            end
        end
        return changedPointsData
    end

    local currentChapterId = activityData:getCurChapterId()
    local chapterConfig = self:getChapterConfigByChapterId(currentChapterId)
    local severPointsData = self:formatSeverPointsData(chapterConfig, activityData:getAllPointsData())
    local severPointsDataMap = {}
    for i, data in ipairs(severPointsData) do
        if data.showLand and data.allowPlace and not data.castleBuilding then
            local key = self:getRowAndTandemKey(data.rowId, data.tandemId)
            severPointsDataMap[key] = data
        end
    end
    for i, useData in ipairs(self.m_usedPointsData) do
        local key = self:getRowAndTandemKey(useData.rowId, useData.tandemId)
        local serverData = severPointsDataMap[key]
        if useData.showLand and useData.allowPlace and not useData.castleBuilding then
            if useData.buildingType >= 0 then
                local addData = nil
                if not serverData then
                    --addData = {useData.rowId,useData.tandemId,useData.buildingType,useData.buildingLevel}
                    local error = 0
                else
                    local isAdd = false
                    if useData.buildingType >= 0 and useData.buildingType ~= serverData.buildingType then
                        isAdd = true
                        addData = {useData.rowId, useData.tandemId, useData.buildingType, useData.buildingLevel}
                    end
                    if not isAdd and useData.buildingLevel >= 0 and useData.buildingLevel ~= serverData.buildingLevel then
                        addData = {useData.rowId, useData.tandemId, useData.buildingType, useData.buildingLevel}
                    end
                end
                if addData then
                    -- if useData.buildingLevel >= self.m_usedChapterMaxLevel then
                    --     addData[3]= 0
                    --     addData[4]= 0
                    -- end
                    changedPointsData[#changedPointsData + 1] = addData
                end
            end
        end
    end
    return changedPointsData
end

-- 和服务器同步 地图节点信息 isSendAll true 全同步 false 同步改变信息
function ActivityDeluxeMergeManager:sendPointsDataToServer(isSendAll, bDrag)
    local params = {}

    params.cellChange = self:getChangedPointsData(isSendAll)
    params.mergeType = bDrag and 0 or 1 -- 0手动合成 1一键合成
    self:doHighLimitMergePlay(params)
end

function ActivityDeluxeMergeManager:setPointsData(pointsData, formMerge, bDrag)
    for i, data in ipairs(pointsData) do
        local key = self:getRowAndTandemKey(data.rowId, data.tandemId)
        self.m_usedPointsDataKeyMap[key] = data
    end
    self.m_usedPointsData = {}
    for k, data in pairs(self.m_usedPointsDataKeyMap) do
        self.m_usedPointsData[#self.m_usedPointsData + 1] = data
    end
    table.sort(
        self.m_usedPointsData,
        function(a, b)
            if a.rowId == b.rowId then
                return a.tandemId < b.tandemId
            end
            return a.rowId < b.rowId
        end
    )
    self:savePointsData()
    if formMerge then
        self:sendPointsDataToServer(false, bDrag)
    end
end

function ActivityDeluxeMergeManager:savePointsData(forceClear)
    local curTime = self:getCurrentTime()
    local data = {}
    data.points = self.m_usedPointsData
    data.time = "" .. curTime
    if forceClear then
        data.points = {}
        data.time = "0"
    end

    local activityData = self:getRunningData()
    if activityData then
        local useChapterId = self:getUsedChapterID()
        data.pointsOfChapter = "" .. useChapterId
        self.m_localPointsChapter = useChapterId
    end
    self.m_localPointsData = nil
    self.m_localPointsData = clone(self.m_usedPointsData)
    self.m_usedPointsSaveTime = "" .. curTime
    if forceClear then
        self.m_usedPointsSaveTime = "0"
    end
    self.m_localPointsSaveTime = self.m_usedPointsSaveTime
    self:writeMergePointsConfig(data)
end

function ActivityDeluxeMergeManager:afterPlayDirty(noPost)
    self.m_usedPointsData = {}
    self.m_localPointsData = {}
    self.m_usedPointsDataKeyMap = {}
    self.m_usedPointsSaveTime = "0"
    self.m_localPointsSaveTime = "0"
    self.m_localPointsChapter = 0
    self.m_waitingForReward = {}
    self.m_isShowingReward = {}
    self:clearALlRewardFlag()
    self:removeMergePointsConfig()
    -- 通知 刷新界面
    if not noPost then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_FORCECLOSEVIEW)
    end
end

--读写 本地配置  ------start----------
function ActivityDeluxeMergeManager:checkReadLocalPointsConfig()
    if self.m_usedPointsSaveTime ~= "0" and self.m_usedPointsSaveTime == self.m_localPointsSaveTime then
        return
    end
    if not cc.FileUtils:getInstance():isFileExist(self.m_saveFileName) then
        self.m_localPointsChapter = 0
        return
    end

    local luaConfig = util_checkJsonDecode(self.m_saveFileName)
    if luaConfig == nil then
        self.m_localPointsChapter = 0
        self:removeMergePointsConfig()
        return
    else
        self.m_localPointsSaveTime = luaConfig.time or "0"
        self.m_localPointsData = luaConfig.points or {}
        self.m_localPointsChapter = luaConfig.pointsOfChapter or 0
    end
end
function ActivityDeluxeMergeManager:removeMergePointsConfig()
    if not self.m_saveFileName or self.m_saveFileName == "" then
        return
    end
    
    local path = device.writablePath .. self.m_saveFileName
    cc.FileUtils:getInstance():removeFile(path)
end

function ActivityDeluxeMergeManager:writeMergePointsConfig(data)
    --写入json文件
    local jsonData = cjson.encode(data)
    local path = cc.FileUtils:getInstance():getWritablePath()
    cc.FileUtils:getInstance():writeStringToFile(jsonData, path .. self.m_saveFileName)
end

--读写 本地配置  ------end----------
--------------------------------------------------华丽的分割线--------界面控制---------- start-----

-- 显示主面板
function ActivityDeluxeMergeManager:tryEnterMergeMainView(useInterlude, useEnterAct, formClub)
    if not self:isCanShowLayer() then
        return nil
    end

    if not gLobalActivityManager:checkActivityOpen(ACTIVITY_REF.DeluxeClubMergeActivity) then
        return
    end
    if self:checkServerData() then
        return
    end
    self.m_formClub = formClub -- 从高倍场主界面进入
    if formClub then
        release_print("tryEnterMergeMainView-----FromClub")
    end
    local view = util_createFindView("Activity/Activity_DeluxeMergeMainView", {useInterlude = useInterlude, useEnterAct = useEnterAct, formClub = formClub})
    if tolua.isnull(view) then
        return
    end
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

-- 进入游戏玩法UI
function ActivityDeluxeMergeManager:tryEnterGameView(chapterId)
    if not self:isCanShowLayer() then
        return nil
    end

    if not chapterId then
        return
    end
    if not self:getCurrentChapterData() then
        return
    end

    local cashBonusView = util_createFindView("Activity/Activity_DeluxeMergeGameView", chapterId)
    gLobalViewManager:showUI(cashBonusView, ViewZorder.ZORDER_UI)
end

function ActivityDeluxeMergeManager:showDailyRewardLayer(resData)
    if not resData or (not resData.dailyCoins and not resData.dailyItems) then
        return
    end

    local coins = tonumber(resData.dailyCoins) or 0
    local itemsCount = #resData.dailyItems

    if coins == 0 and itemsCount == 0 then
        return
    end

    local view = gLobalViewManager:getViewByExtendData("Activity_DeluxeMergeDailyRewardLayer")
    if view then
        return
    end
    view = util_createFindView("Activity/Activity_DeluxeMergeDailyRewardLayer", resData)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self.m_dailyRewardview = view
end

function ActivityDeluxeMergeManager:clearDailyRewardLayer(onlyNil)
    if onlyNil then
        self.m_dailyRewardview = nil
    end
    if not tolua.isnull(self.m_dailyRewardview) then
        self.m_dailyRewardview:closeUI()
        self.m_dailyRewardview = nil
    end
end

-- 游戏关卡内入口
function ActivityDeluxeMergeManager:createMachineEntryNode()
    -- 等级显示 跟高倍场等级一样
    local curLevel = globalData.userRunData.levelNum
    local lockLevel = globalData.constantData.CLUB_OPEN_LEVEL
    if curLevel < lockLevel then
        return
    end

    -- cxc 2021-12-08 11:32:23 高倍场开启再显示入口
    if not globalData.deluexeClubData:getDeluexeClubStatus() then
        return
    end

    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    local view = util_createFindView("Activity/Activity_DeluxeMergeEntryNode")
    return view
end

-- 新赛季开启 提示面板(邮件里点击过来的)
function ActivityDeluxeMergeManager:popMergeNewSeasonTipLayer()
    if not cc.FileUtils:getInstance():isFileExist("InBox/Merge_pouchSource.csb") then
        return
    end

    local view = util_createView("activities.Activity_DeluxeMerge.views.Activity_DeluxeMergeNewSeasonTip")
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

--耗时操作（检测或动画）中屏蔽其他功能逻辑
function ActivityDeluxeMergeManager:setGameViewDoCheckOrActionFlag(stopOtherLogic)
    -- cxc 2021-12-31 14:46:58 界面不知道什么原因卡主了
    if stopOtherLogic then
        self.m_recordActionFlagTime = os.time()
    else
        self.m_recordActionFlagTime = nil
    end

    -- cxc 2021-12-31 14:46:58 界面不知道什么原因卡主了

    self.m_stopOtherLogic = stopOtherLogic
end
function ActivityDeluxeMergeManager:getGameViewDoCheckOrActionFlag()
    -- cxc 2021-12-31 14:46:58 界面不知道什么原因卡主了
    if self.m_stopOtherLogic and self.m_recordActionFlagTime then
        -- 卡了超过10秒就让他 能点
        if (os.time() - self.m_recordActionFlagTime) > 20 then
            self.m_stopOtherLogic = false
        end
    end
    -- cxc 2021-12-31 14:46:58 界面不知道什么原因卡主了

    return self.m_stopOtherLogic
end

-- 手动拖拽合成
function ActivityDeluxeMergeManager:clearGameViewHandComposeFlag()
    self.m_doHandComposeCount = 0
end

function ActivityDeluxeMergeManager:setGameViewHandComposeFlag(doHandCompose)
    if not self.m_doHandComposeCount or self.m_doHandComposeCount < 0 then
        self.m_doHandComposeCount = 0
    end
    if doHandCompose then
        self.m_doHandComposeCount = self.m_doHandComposeCount + 1
    else
        self.m_doHandComposeCount = self.m_doHandComposeCount - 1
    end
end
function ActivityDeluxeMergeManager:getGameViewHandComposeFlag()
    if not self.m_doHandComposeCount or self.m_doHandComposeCount < 0 then
        self.m_doHandComposeCount = 0
    end
    return self.m_doHandComposeCount > 0
end
-- 一键合成
function ActivityDeluxeMergeManager:doMergeAllLogic()
    if self:getGameViewDoCheckOrActionFlag() then
        return
    end
    if self:getGameViewHandComposeFlag() then
        return
    end
    self:setGameViewDoCheckOrActionFlag(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_MERGEALL,{isQuickly = false})
end

-- 一键购买
function ActivityDeluxeMergeManager:doGetMergeItemLogic()
    if self:getGameViewDoCheckOrActionFlag() then
        return
    end
    if self:getGameViewHandComposeFlag() then
        return
    end
    self:setGameViewDoCheckOrActionFlag(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_GETMERGEITEMS)
end

-- 一键购买
function ActivityDeluxeMergeManager:doBuyBalloonLogic()
    if self:getGameViewDoCheckOrActionFlag() then
        return
    end
    if self:getGameViewHandComposeFlag() then
        return
    end
    self:setGameViewDoCheckOrActionFlag(true)
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_BUYBALLOONSALE)
end

-- 商店购买
function ActivityDeluxeMergeManager:buyMergeItem(_data, _index, _discount)
    if not _data then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUXE_MERGE_STORE_BUY)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data.p_keyId
    goodsInfo.goodsPrice = _data.p_price

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo, _index)
    --添加道具log
    local item = clone(_data.p_item)
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {_data.p_item})
    gLobalSendDataManager:getLogIap():setItemList(itemList)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.HIGH_MERGE_PURCHASE_STORE,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function()
            G_GetMgr(ACTIVITY_REF.MergeStoreCoupon):checkActivityClose()
            gLobalSendDataManager:getLogIap():setLastEntryType()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUXE_MERGE_STORE_BUY, {index = _index, item = item, discount = _discount})
        end,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUXE_MERGE_STORE_BUY)
        end
    )
end

function ActivityDeluxeMergeManager:sendIapLog(_goodsInfo, _index)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "MergeStore"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "MergeStore"
    purchaseInfo.purchaseStatus = _index
    gLobalSendDataManager:getLogIap():setEntryType("Merge")
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end

--------------------------------------------------华丽的分割线--------界面控制---------- start-----

--------------------------------------------------华丽的分割线----------------- 和服务器数据交互------------start----------------

function ActivityDeluxeMergeManager:checkAndrememberALlReward(data)
    if data.levelReward then
        local levelReward = data.levelReward
        if levelReward and next(levelReward) ~= nil then
            self.m_levelReward[#self.m_levelReward + 1] = levelReward
        end
    end
    if data.progressReward then
        self.m_progressReward = data.progressReward
    end
    if data.materialProps then
        self.m_materialProps = data.materialProps
    end
    if data.chapterCoins then
        self.m_chapterCoins = data.chapterCoins
    end
    if data.chapterItems then
        self.m_chapterItems = data.chapterItems
    end
    if data.finalCoins then
        self.m_finalCoins = data.finalCoins
    end
    if data.finalItems then
        self.m_finalItems = data.finalItems
    end
end

function ActivityDeluxeMergeManager:clearALlRewardFlag()
    self.m_levelReward = {}
    self.m_progressReward = nil
    self.m_materialProps = nil
    self.m_chapterCoins = nil
    self.m_chapterItems = nil
    self.m_isShowingReward = {}
end

-- 高倍场游戏-合图-上传地图
function ActivityDeluxeMergeManager:doHighLimitMergeUploadMap(params)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local successCallFun = function(resData)
    end
    local failedCallFun = function()
    end

    self.m_netModel:sendActionMessage(ActionType.HighLimitMergeUploadMap, {}, successCallFun, failedCallFun)
end

--高倍场游戏-合图- 吃最高级别建筑
function ActivityDeluxeMergeManager:doHighLimitMergeCollect(rowId, tandemId)
    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end
    self.m_waitingForReward["eat"] = true
    if gLobalSendDataManager:isLogin() == false then
        self.m_waitingForReward["eat"] = false
        return
    end
    self:clearALlRewardFlag()
    local successCallFun = function(resData)
        self:checkAndrememberALlReward(resData)
        self.m_waitingForReward["eat"] = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshLeft = true, refreshBottom = true, refreshBalloon = true})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_RANK)
        if self.m_isShowingReward["eat"] then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_CHECKREWARD)
        end

        -- doHighLimitMergePlay 接口未成功，但可以继续玩，奖励放到建筑升级接口里(板子可能重叠先不用处理)
        if resData.levelReward and self.m_levelReward and #self.m_levelReward > 0 then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_SHOWNEXTUNLOCKREWARD, {rewardIndex = 1})
        end
    end

    local failedCallFun = function()
        self:afterPlayDirty()
        self:setGameViewDoCheckOrActionFlag(false)
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.cellChange = self:getChangedPointsData(false)
    tbData.data.params.cellCollect = {rowId, tandemId}

    self.m_netModel:sendActionMessage(ActionType.HighLimitMergeCollect, tbData, successCallFun, failedCallFun)
end

--高倍场游戏-合图-购买材料 气球（第二货币）
function ActivityDeluxeMergeManager:doHighLimitMergeBuyMaterial(rowId, tandemId)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    local successCallFun = function(resData)
        if resData.buyCell then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_TOP_UPDATE_GEM)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_BUYBALLOONSALE_SUCCESS, resData.buyCell)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshBalloon = true})
        end
    end

    local failedCallFun = function(resData)
        self:afterPlayDirty()
        self:setGameViewDoCheckOrActionFlag(false)
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.cellChange = self:getChangedPointsData(false)
    local buyCell = {}
    buyCell[#buyCell + 1] = rowId
    buyCell[#buyCell + 1] = tandemId
    tbData.data.params.buyCell = buyCell
    self.m_netModel:sendActionMessage(ActionType.HighLimitMergeBuyMaterial, tbData, successCallFun, failedCallFun)
end

--高倍场游戏-合图-购买材料 一键铺满
function ActivityDeluxeMergeManager:doHighLimitMergePutMaterial(allBuyPoints)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    local successCallFun = function(resData)
        if resData.putCells then
            local guideStep = self:getCurStepIdByLayerKey("MergeGameView")
            if guideStep == 2 then
                self:saveGuidStepIDByLayerKey("MergeGameView", 3)
            end
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_GETMERGEITEMS_SUCCESS, resData.putCells)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshCrystal = true, refreshBottom = true})
        end
    end

    local failedCallFun = function(resData)
        local guideStep = self:getCurStepIdByLayerKey("MergeGameView")
        if guideStep == 2 then
            self:saveGuidStepIDByLayerKey("MergeGameView", 3)
        end
        self:afterPlayDirty()
        self:setGameViewDoCheckOrActionFlag(false)
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.cellChange = self:getChangedPointsData(false)
    tbData.data.params.putCells = allBuyPoints
    self.m_netModel:sendActionMessage(ActionType.HighLimitMergePutMaterial, tbData, successCallFun, failedCallFun)
end

function ActivityDeluxeMergeManager:setIsShowingReward(requestId, showing)
    self.m_isShowingReward[("" .. requestId)] = showing
end
function ActivityDeluxeMergeManager:getIsWaitingForReward(requestId)
    if self.m_waitingForReward == nil then
        self.m_waitingForReward = {}
    end
    return not (not self.m_waitingForReward[("" .. requestId)])
end
function ActivityDeluxeMergeManager:getRequestPlayID()
    if self.m_isRequestPlayID == nil then
        self.m_isRequestPlayID = 0
    end
    return self.m_isRequestPlayID
end

function ActivityDeluxeMergeManager:setIsShowingUnlockReward(showing)
    self.m_isShowingUnlockReward = showing
end
function ActivityDeluxeMergeManager:getIsShowingUnlockReward()
    if self.m_isShowingUnlockReward == nil then
        self.m_isShowingUnlockReward = false
    end
    return not (not self.m_isShowingUnlockReward)
end

--//高倍场游戏-合图-上传地图   合成建筑
function ActivityDeluxeMergeManager:doHighLimitMergePlay(params)
    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end
    self.m_isRequestPlayID = self.m_isRequestPlayID + 1
    self.m_waitingForReward[("" .. self.m_isRequestPlayID)] = true

    if gLobalSendDataManager:isLogin() == false then
        self.m_waitingForReward[("" .. self.m_isRequestPlayID)] = false
        return
    end

    --self:clearALlRewardFlag()
    local successCallFun = function(resData)
        self:checkAndrememberALlReward(resData)
        local reqId = resData.reqId
        if not reqId then
            self:setGameViewDoCheckOrActionFlag(false)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshLeft = true, refreshBottom = true, refreshBalloon = true})
            return
        end

        self.m_waitingForReward[("" .. reqId)] = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshLeft = true, refreshBottom = true, refreshBalloon = true})
        if self.m_isShowingReward[("" .. reqId)] then
            --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_CHECKREWARD)
            print("数据没有回来 调用显示奖励")
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_CHECKREWARD_UNLOCK, {requestId = reqId})
        end
    end

    local failedCallFun = function(resData)
        self:afterPlayDirty()
        self:setGameViewDoCheckOrActionFlag(false)
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.reqId = self.m_isRequestPlayID
    if params.cellChange then
        tbData.data.params.cellChange = params.cellChange
    else
        tbData.data.params.cellChange = self:getChangedPointsData(false)
    end
    if params.mergeType then
        tbData.data.params.mergeType = params.mergeType
    end
    self.m_netModel:sendActionMessage(ActionType.HighLimitMergePlay, tbData, successCallFun, failedCallFun)
    return self.m_isRequestPlayID
end

--//高倍场游戏-合图-开礼包
function ActivityDeluxeMergeManager:doHighLimitMergeOpenBag(level)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    local successCallFun = function(resData)
        if resData.bagProps then
            local cashBonusView = util_createView("Activity.Activity_DeluxeMergeRewardView", {bagProps = resData.bagProps})
            gLobalViewManager:showUI(cashBonusView, ViewZorder.ZORDER_UI)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_GUIDEHIDEHAND)
        else
            self:setGameViewDoCheckOrActionFlag(false)
        end
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
        self:setGameViewDoCheckOrActionFlag(false)
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.level = level
    self.m_netModel:sendActionMessage(ActionType.HighLimitMergeOpenBag, tbData, successCallFun, failedCallFun)
end

--//高倍场游戏-合图-领取每日奖励
function ActivityDeluxeMergeManager:doHighLimitMergeDailyReward(_chapterId)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    local successCallFun = function(resData)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_COLLECT_DAILYREWARD, _chapterId)
        self:showDailyRewardLayer(resData)
    end

    local failedCallFun = function()
        gLobalViewManager:showReConnect()
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.chapterId = _chapterId or 0
    self.m_netModel:sendActionMessage(ActionType.HighLimitMergeDailyReward, tbData, successCallFun, failedCallFun)
end

--//高倍场游戏-合图-排行榜
function ActivityDeluxeMergeManager:doHighLimitMergeRank(_callFunc)
    if gLobalSendDataManager:isLogin() == false then
        if _callFunc then
            _callFunc()
        end
        return
    end

    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end

    gLobalViewManager:addLoadingAnima(false, 1)
    local successCallFun = function(resData)
        gLobalViewManager:removeLoadingAnima()
        local activityData = self:getRunningData()
        if activityData and resData then
            activityData:setRankJackpotCoins(0)
            activityData:parseRankData(resData)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_RANK_DATA_REFRESH, {refName = ACTIVITY_REF.DeluxeClubMergeActivity})
            if _callFunc then
                _callFunc()
            end            
        end
    end

    local failedCallFun = function()
        gLobalViewManager:removeLoadingAnima()
        gLobalViewManager:showReConnect()
    end

    self.m_netModel:sendActionMessage(ActionType.HighLimitMergeRank, {}, successCallFun, failedCallFun)
end

--------------------------------------------------华丽的分割线----------------- 和服务器数据交互------------end----------------

-----------------------------------------------------华丽的分割线----------------- 紫晶钻福袋掉落 ------------start----------------

function ActivityDeluxeMergeManager:setPopPropsBagTempList(_list)
    self.m_shopItemList = _list
end
function ActivityDeluxeMergeManager:getPopPropsBagTempList(_list)
    return self.m_shopItemList
end
function ActivityDeluxeMergeManager:resetPropsBagTempList()
    self.m_shopItemList = {}
end

function ActivityDeluxeMergeManager:autoPopPropsBagLayer(_cb)
    _cb = _cb or handler(self, self.resetPropsBagTempList)
    if self.m_shopItemList and next(self.m_shopItemList) then
        self:popMergePropsBagRewardPanel(self.m_shopItemList, _cb)
        return
    end

    _cb()
end

-- 弹出紫晶钻福袋掉落的弹板
function ActivityDeluxeMergeManager:popMergePropsBagRewardPanel(_shopItemDataList, _callback, _bAuto)
    _callback = _callback or function()
        end

    if not _shopItemDataList or not next(_shopItemDataList) then
        _callback()
        return
    end

    self.m_overCb = _callback
    self.m_bPanelAutoClose = _bAuto

    self:parseDropPropsBagListData(_shopItemDataList)
    self:dropPropsBagRewardLayerNext()
end

function ActivityDeluxeMergeManager:parseDropPropsBagListData(_shopItemDataList)
    if not _shopItemDataList or not next(_shopItemDataList) then
        return
    end

    for i, itemInfo in ipairs(_shopItemDataList) do
        local icon = itemInfo.p_icon or ""
        if not string.find(icon, "Pouch") then
            break
        end
        local idxMap = {
            Mini_Pouch = 1,
            Minor_Pouch = 2,
            Major_Pouch = 3,
            Mega_Pouch = 4
        }
        local idx = idxMap[icon]
        local list = self["m_dropPropsBagList" .. idx]
        if not list then
            break
        end

        local propsBagData = list[1]
        if not propsBagData then
            table.insert(list, itemInfo)
        else
            propsBagData.p_num = propsBagData.p_num + itemInfo.p_num
        end
    end
end

function ActivityDeluxeMergeManager:dropPropsBagRewardLayerNext()
    local propsBagList = {}
    for i = 1, 4 do
        local dropPropsBagFoodList = self["m_dropPropsBagList" .. i] or {}
        if next(dropPropsBagFoodList) then
            propsBagList = dropPropsBagFoodList
            break
        end
    end

    if not next(propsBagList) then
        if self.m_overCb then
            self.m_overCb()
            self.m_overCb = nil
        end
        return
    end
    if not self:isDownloadRes() then
        if self.m_overCb then
            self.m_overCb()
            self.m_overCb = nil
        end
        return
    end

    local foodRewardPanel = util_createFindView("Activity/Activity_DeluxeMergeDropPouchView", clone(propsBagList), self.m_bPanelAutoClose)
    if not foodRewardPanel then
        if self.m_overCb then
            self.m_overCb()
            self.m_overCb = nil
        end
        return
    end

    foodRewardPanel.m_callback = nil --(热更了代码但未动态下载更新报错  m_callalbask 会变成bool类型 m_callalbask = self.m_bPanelAutoClose)
    foodRewardPanel:setOverFunc(
        function()
            self:dropPropsBagRewardLayerNext()
        end
    )
    table.remove(propsBagList, 1)
    gLobalViewManager:getViewLayer():addChild(foodRewardPanel, ViewZorder.ZORDER_UI)
end
function ActivityDeluxeMergeManager:refreshBagsData(bags)
    local activityData = self:getRunningData()
    if activityData then
        activityData:refreshBagsData(bags)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.DeluxeClubMergeActivity}) --统一活动数据 更新就刷新小红点
    end
end
function ActivityDeluxeMergeManager:refreshBagsNum(icon, num)
    local idxMap = {
        Mini_Pouch = 1,
        Minor_Pouch = 2,
        Major_Pouch = 3,
        Mega_Pouch = 4
    }
    local activityData = self:getRunningData()
    if activityData then
        local idx = idxMap[icon]
        if idx then
            activityData:refreshBagNum(idx, num)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.DeluxeClubMergeActivity}) --统一活动数据 更新就刷新小红点
        end
    end
end

-----------------------------------------------------华丽的分割线----------------- 紫晶钻福袋掉落 ------------end----------------
-- 获取 显示活动时间的 宏 <= 10天显示时间
function ActivityDeluxeMergeManager:geShowActEndTimeMacro()
    if not self.m_commonLocalConfig then
        return 864000 -- 10 * 24 * 60 * 60
    end

    return self.m_commonLocalConfig.SHOW_ACT_LEFT_TIME_SEC or 864000
end

-- 获取 促销，奖励框里building 材料的sp最大显示大小
function ActivityDeluxeMergeManager:getSaleRewardBuildingMaxHeight()
    if not self.m_commonLocalConfig then
        return 130
    end

    return self.m_commonLocalConfig.MAX_HEIGHT or 130
end

-- 检查是否下载完毕
function ActivityDeluxeMergeManager:checkDownloadResCode()
    if globalDynamicDLControl:checkDownloading("Activity_DeluxeClub_Merge") or globalDynamicDLControl:checkDownloading("Activity_DeluxeClub_Merge_Code") then
        return false
    end

    return true
end

function ActivityDeluxeMergeManager:checkServerData(useDirty)
    if self.m_docheckServerData then
        return false
    end
    self.m_docheckServerData = true
    local doErrorDataLogic = false
    local activityData = self:getRunningData()
    if activityData then
        local currentChapterId = activityData:getCurChapterId()
        local severPointSaveTime = activityData:getPointSaveTime()
        local chapterConfig = self:getChapterConfigByChapterId(currentChapterId)
        local severPointDatas = activityData:getAllPointsData()

        local configPointDates = clone(chapterConfig.pointsMap)
        for i, point in ipairs(configPointDates) do
            local key = tonumber(point.rowId) * 1000 + tonumber(point.tandemId)
            local serverPoint = severPointDatas[key]
            if serverPoint then
                point.buildingType = serverPoint.buildingType
                point.buildingLevel = serverPoint.buildingLevel
            end
        end
        local doError, serverPoints, changeArray = self:checkErrorData(configPointDates)
        if doError then
            doErrorDataLogic = true
            self.m_usedPointsSaveTime = "" .. severPointSaveTime
            self.m_usedPointsData = clone(serverPoints)
            self:savePointsData(true)

            local params = {}
            params.cellChange = changeArray
            self:doHighLimitMergePlay(params)
        end
    end
    if useDirty and doErrorDataLogic then
        self:afterPlayDirty(false)
    end
    return doErrorDataLogic
end

function ActivityDeluxeMergeManager:checkErrorData(severPointsData)
    local serverPoints = clone(severPointsData)
    local activityData = self:getRunningData()
    local chapterConfig = nil
    if activityData then
        local currentChapterId = activityData:getCurChapterId()
        chapterConfig = self:getChapterConfigByChapterId(currentChapterId)
    end
    local doError = false
    local errorArray = {}
    local serverEmptyArray = {}
    local changeArray = {}
    if activityData and chapterConfig then
        local ChapterConfigMap = {}
        for i, data in ipairs(chapterConfig.pointsMap) do
            local key = "" .. (data.rowId * 1000 + data.tandemId)
            ChapterConfigMap[key] = data
        end
        for i, data in ipairs(serverPoints) do
            local key = "" .. (data.rowId * 1000 + data.tandemId)
            local checkData = ChapterConfigMap[key]
            if data.buildingType > 0 and data.buildingLevel > 0 and (not checkData or checkData.castleBuilding or not checkData.showLand) then
                errorArray[#errorArray + 1] = data
                doError = true
            else
                if data.buildingType == 0 and data.buildingLevel == 0 and data.allowPlace and not data.castleBuilding then
                    serverEmptyArray[#serverEmptyArray + 1] = data
                end
            end
        end
        if doError then
            for i, errorData in ipairs(errorArray) do
                local checkServerEmptyData = serverEmptyArray[i]
                if checkServerEmptyData then
                    checkServerEmptyData.buildingType = errorData.buildingType
                    checkServerEmptyData.buildingLevel = errorData.buildingLevel
                    errorData.buildingType = 0
                    errorData.buildingLevel = 0
                    changeArray[#changeArray + 1] = {errorData.rowId, errorData.tandemId, errorData.buildingType, errorData.buildingLevel}
                    changeArray[#changeArray + 1] = {checkServerEmptyData.rowId, checkServerEmptyData.tandemId, checkServerEmptyData.buildingType, checkServerEmptyData.buildingLevel}
                end
            end
        end
    end

    return doError, serverPoints, changeArray
end

function ActivityDeluxeMergeManager:showCloudLoading(showType)
    local mergeLoading = util_createView("Activity.Activity_DeluxeMergeGameLoading", showType)
    mergeLoading:setName("DeluxeMergeGameLoading")
    gLobalViewManager:showUI(mergeLoading, ViewZorder.ZORDER_POPUI)
end

function ActivityDeluxeMergeManager:closeCloudLoading(callback)
    local mergeLoading = gLobalViewManager:getViewByName("DeluxeMergeGameLoading")
    if mergeLoading then
        mergeLoading:closeUI(callback)
    else
        if callback then
            callback()
        end
    end
end

function ActivityDeluxeMergeManager:showStoreLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    if self:getGameViewDoCheckOrActionFlag() then
        return
    end

    if gLobalViewManager:getViewByExtendData("Activity_DeluxeMergeStoreView") == nil then
        local storeView = util_createView("Activity.Activity_DeluxeMergeStoreView")
        self:showLayer(storeView, ViewZorder.ZORDER_UI)
    end
end

-- 一键合成  快速一键合成
function ActivityDeluxeMergeManager:doQuicklyMergeAllLogic(useProps)
    if self:getGameViewDoCheckOrActionFlag() then
        return
    end
    if self:getGameViewHandComposeFlag() then
        return
    end
    self:showQuicklyMergeSecondComfirmLayer(useProps)
    
end

function ActivityDeluxeMergeManager:showQuicklyMergeSecondComfirmLayer(useProps)
    local view = util_createFindView("Activity/Activity_DeluxeMergerQuicklySecondComfirmLayer", {useProps = useProps,callBack = function ()
        self:afterComfirmQuicklyMergeAll()
    end})
    if tolua.isnull(view) then
        return
    end
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function ActivityDeluxeMergeManager:afterComfirmQuicklyMergeAll()
    self:setGameViewDoCheckOrActionFlag(true)
    --self:doHighLimitMergeQuicklyPlay()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_MERGEALL,{isQuickly = true})
end

--//高倍场游戏-合图-上传地图   合成建筑 快速一键合成
function ActivityDeluxeMergeManager:doHighLimitMergeQuicklyPlay(allBuyPoints)
    --联网检查
    if xcyy.GameBridgeLua:checkNetworkIsConnected() == false then
        gLobalViewManager:showReConnect(true)
        return
    end
    self.m_isRequestPlayID = self.m_isRequestPlayID + 1
    self.m_waitingForReward[("" .. self.m_isRequestPlayID)] = true

    if gLobalSendDataManager:isLogin() == false then
        self.m_waitingForReward[("" .. self.m_isRequestPlayID)] = false
        return
    end

    --self:clearALlRewardFlag()
    local successCallFun = function(resData)
        self:checkAndrememberALlReward(resData)
        local reqId = resData.reqId
        if not reqId then
            self:setGameViewDoCheckOrActionFlag(false)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshLeft = true, refreshBottom = true, refreshBalloon = true})
            return
        end

        if resData.cells then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_QUICKLYALLMERGE_SUCCESS, resData.cells)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshCrystal = true, refreshBottom = true})
        end
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_RANK)

        self.m_waitingForReward[("" .. reqId)] = false
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_REFRESH, {refreshLeft = true, refreshBottom = true, refreshBalloon = true})
        if self.m_isShowingReward[("" .. reqId)] then
            --gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_CHECKREWARD)
            print("数据没有回来 调用显示奖励")
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DELUXEMERGE_CHECKREWARD_UNLOCK, {requestId = reqId})
        end
    end

    local failedCallFun = function(resData)
        self:afterPlayDirty()
        self:setGameViewDoCheckOrActionFlag(false)
    end

    local tbData = {
        data = {
            params = {}
        }
    }
    tbData.data.params.reqId = self.m_isRequestPlayID
    tbData.data.params.mergeType = 1
    tbData.data.params.putCells = allBuyPoints
    self.m_netModel:sendActionMessage(ActionType.HighLimitMergeOneClick, tbData, successCallFun, failedCallFun)
    return self.m_isRequestPlayID
end


function ActivityDeluxeMergeManager:isInAllQuickMergeGuide()
    return not not self.m_inQuickMergeGuide
end

function ActivityDeluxeMergeManager:setInAllQuickMergeGuide(inGuide)
    self.m_inQuickMergeGuide = inGuide
end

function ActivityDeluxeMergeManager:setIsEatingHighBuilding(isEat)
    self.m_isEating = isEat
end

function ActivityDeluxeMergeManager:isEatingHighBuilding()
    return not not self.m_isEating
end

-- 本次登录 完成了那个章节
function ActivityDeluxeMergeManager:setCurLogonOverMergeChapterId(_chapterId)
    self._curLogonOverChapterId = _chapterId
end
-- 关闭高倍场监测下 运营引导弹板
-- cxc 2023年12月25日14:36:06 每一个赛季，合成完成第1章和第2章，领取奖励，回到关卡或大厅的时候弹出  点位CD48小时	引导评论>弹窗>FB
function ActivityDeluxeMergeManager:closeDeluxeCheckOGPopLayer()
    if not self._curLogonOverChapterId then
        return
    end

    local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("MergeActOverChapter", "MergeActOverChapter_" .. self._curLogonOverChapterId)
    self:setCurLogonOverMergeChapterId(nil)
    return view
end

return ActivityDeluxeMergeManager
