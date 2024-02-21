--[[
Author: cxc
Date: 2022-04-12 16:47:44
LastEditTime: 2022-04-12 16:47:45
LastEditors: cxc
Description: 头像 头像框信息管理类
FilePath: /SlotNirvana/src/GameModule/Avatar/controller/AvatarFrameManager.lua
--]]
local AvatarFrameConfig = util_require("GameModule.Avatar.config.AvatarFrameConfig")
local AvatarNet = util_require("GameModule.Avatar.net.AvatarNet")
local SlotHotPlayerData = util_require("GameModule.Avatar.model.SlotHotPlayerData")
local AvatarFrameStaticData = util_require("GameModule.Avatar.model.AvatarFrameStaticData")
local AvatarFrameManager = class("AvatarFrameManager", BaseGameControl)

function AvatarFrameManager:ctor()
    AvatarFrameManager.super.ctor(self)
    self:setRefName(G_REF.AvatarFrame)

    self.m_frameStaticData = AvatarFrameStaticData:create()
    self.m_netModel = AvatarNet:getInstance()
    self.m_slotHotPlayerList = {} -- 关卡热玩玩家数据

    self:registerListener()
end

--添加头像框缓存
function AvatarFrameManager:loadSpriteFrameCache()
    -- display.loadSpriteFrames("CommonAvatar/ui/frame/idle/ui_frame_idle_season12.plist", "CommonAvatar/ui/frame/idle/ui_frame_idle_season12.png")
end

-- 获取数据
function AvatarFrameManager:getData()
    return globalData.avatarFrameData
end

------------------------ 静态表 数据 ------------------------
-- 获取头像框 静态 数据
function AvatarFrameManager:getFrameStaticData()
    return self.m_frameStaticData
end

-- 获取头像框 信息
function AvatarFrameManager:getAvatarFrameCfgInfo(_frameId)
    local info = self.m_frameStaticData:getAvatarFrameCfgInfo(_frameId)
    return info
end

-- 获取 头像框 资源路径
function AvatarFrameManager:getAvatarFrameResPath(_frameId)
    local resInfo = self.m_frameStaticData:getAvatarFrameResInfo(_frameId)
    return resInfo
end
------------------------ 静态表 数据 ------------------------
-- 获取玩家喜欢的头像框
function AvatarFrameManager:getUserLikeFrameList()
    local data = self:getData()
    return data:getLikeFrameList() 
end

-- 获取玩家已获得的头像框时间
function AvatarFrameManager:getUserHoldFrameTimeList()
    local data = self:getData()
    return data:getHoldFrameTimeList() 
end
function AvatarFrameManager:getLikeStatus()
    local data = self:getData()
    return data:getLikeStatus() 
end

-- 获取玩家已获得的头像框
function AvatarFrameManager:getUserHoldFrameIdList()
    local data = self:getData()
    return data:getHoldFrameList() 
end

-- 获取 关卡普通场 id
function AvatarFrameManager:getCurLevelNormalSlotId(_slotId)
    local slotId = _slotId
    if not slotId then
        local curMachineData = globalData.slotRunData.machineData or {}
        slotId = curMachineData.p_id
    end
    local machineNormalId = "1" .. string.sub(tostring(slotId) or "", 2)

    return machineNormalId
end

--[[
    @desc: 创建头像框 node
    --@_frameId: 头像框id
    --@_bAct: 是否显示 动画
    @return: AvatarFrameNode
]]
function AvatarFrameManager:createAvatarFrameNode(_frameId, _bAct, _size)
    if not self:checkCommonAvatarDownload() then
        local node = display.newNode()
        node["updateUI"] = function() end
        return node
    end

    local resInfo = self:getAvatarFrameResPath(_frameId)
    local view = util_createView("GameModule.Avatar.views.base.AvatarFrameNode", resInfo, _bAct, _size)
    return view
end

--[[
    @desc: 创建通用头像+头像框
    --@_fId: facebook id 
	--@_headId: 游戏game 存储的头像id
	--@_headFrameId: 游戏game 存储的头像框 id
	--@_robotHeadName: 机器人头像名字
	--@_size:  头像限制大小
	--@_bFBFromCache: facebook头像是否从（缓存）中获取 默认true
    @return: node
]]
function AvatarFrameManager:createCommonAvatarNode(_fId, _headId, _headFrameId, _robotHeadName, _size, _bFBFromCache)
    if not self:checkCommonAvatarDownload() then
        local clipNode = G_GetMgr(G_REF.Avatar):createAvatarClipNode(_fId, _headId, _robotHeadName, false, _size, _bFBFromCache)
        clipNode["checkFrameNodeVisible"] = function()
            return false
        end
        clipNode["updateUI"] = function() end
        clipNode["registerTakeOffEvt"] = function() end
        return clipNode
    end
    local view = util_createView("GameModule.Avatar.views.base.CommonAvatarNode")
    view:updateUI(_fId, _headId, _headFrameId, _robotHeadName, _size, _bFBFromCache)
    view:setName("CommonAvatarNode")
    return view
end

----------------------------------------------  slotTask ---------------------------------------------- 
-- 获取头像框 任务状态 0未激活， 1正在进行， 2已完成
function AvatarFrameManager:getFrameIdTaskState(_frameId)
    local info = self:getAvatarFrameCfgInfo(_frameId)
    if not info then
        return
    end

    local slotId = info["slot_id"]
    local data = self:getData()
    local slotData = data:getSlotTaskBySlotId(slotId)
    if not slotData then
        return
    end

    local taskData = slotData:getTaskDataByFrameId(_frameId)
    return taskData:getStatus()
end

-- spin 更新 头像框 slot任务数据
function AvatarFrameManager:updateSlotTaskData(_data)
    local reward = _data.reward --任务奖励
    local frame = _data.frame -- 任务完成新家的头像框
    local current = _data.current -- 当前关卡任务idx
    local currentTask = _data.currentTask -- 当前关卡当前任务
    local tasks = _data.tasks -- 当前关卡所有任务
    local miniGameProps = _data.props -- 小游戏道具

    local data = self:getData()
    data:addHoldFrame(frame)
    data:updateSlotCurrentTaskData(currentTask)
    data:updateSlotData(current, tasks)
    data:updateMiniGameProp(miniGameProps)
    data:addHoldFrameTime(frame,currentTask.completeTime)

    gLobalNoticManager:postNotification(AvatarFrameConfig.EVENT_NAME.UPDATE_ENTRY_PROGRESS)
end

function AvatarFrameManager:updateLikeFrame(_list)
    self:getData():setLikeFrameList(_list)
end

function AvatarFrameManager:updateLikeStatus()
    self:getData():setLikeStatus()
end

-- 检查
function AvatarFrameManager:checkCurTaskComplete()
    local data = self:getData()
    local machineNormalId = self:getCurLevelNormalSlotId()
    local taskCompleteList = data:getSlotTaskCompleteList()
    local bCompleteNew = false
    if taskCompleteList[tostring(machineNormalId)] then
        bCompleteNew = taskCompleteList[tostring(machineNormalId)].bCompleteNew
    end
    return bCompleteNew
end

-- 检查 关卡slotId 是否开启
function AvatarFrameManager:checkCurSlotOpen(_slotId)
    local serverData = self:getData()
    if not serverData then
        return
    end 

    -- 开启的关卡id
    local openLevelIdList = serverData:getOpenSlotIdList()
    local machineNormalId = self:getCurLevelNormalSlotId(_slotId)
    local bExit = false
    for _, id in ipairs(openLevelIdList) do
        if machineNormalId == tostring(id) then
            bExit = true
            break
        end
    end

    return bExit
end

-- 创建 关卡任务 icon
function AvatarFrameManager:createSlotTaskIconUI(_slotId)
    if not self:checkCommonAvatarDownload() then
        return display.newNode()
    end

    local machineNormalId = self:getCurLevelNormalSlotId(_slotId)

    local view = util_createView("GameModule.Avatar.views.base.AvatarFrameSlotIcon", machineNormalId)
    return view
end

-- 头像框任务是否开启
function AvatarFrameManager:checkUnlock()
    local curLevel = globalData.userRunData.levelNum
    local lockLevel = globalData.constantData.AVATAR_TASK_OPEN_LV or 10
    return curLevel >= lockLevel
end

-- 创建 关卡入口
function AvatarFrameManager:createMachineEntryNode()
    if not self:checkUnlock() then
        return
    end
    
    if not self:checkCommonAvatarDownload() then
        return
    end

    if not self:isCanShowLayer() then
        return
    end

    if not self:checkCurSlotOpen() then
        return
    end

    local view = util_createView("views.AvatarFrame.entry.AvatarFrameMachineEntryNode")
    return view
end
function AvatarFrameManager:createEntryNode()
    return self:createMachineEntryNode()
end

-- 显示主界面
function AvatarFrameManager:showMainLayer(_slotId)
    if not self:checkCommonAvatarDownload() then
        return
    end

    if not self:isCanShowLayer() then
        return
    end

    if not self:checkCurSlotOpen(_slotId) then
        return
    end

    if gLobalViewManager:getViewByExtendData("AvatarFrameMainUI") then
        return
    end

    local view = util_createView("views.AvatarFrame.main.AvatarFrameMainUI", _slotId)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    return view
end

-- 显示任务完成奖励界面
function AvatarFrameManager:showRewardLayer(_slotId)
    if not self:checkCommonAvatarDownload() then
        return
    end

    if not self:isCanShowLayer() then
        return
    end

    if not self:checkCurSlotOpen(_slotId) then
        return
    end

    if gLobalViewManager:getViewByExtendData("AvatarFrameSlotTaskRewardLayer") then
        return
    end

    local normalId = self:getCurLevelNormalSlotId(_slotId)
    local view = util_createView("views.AvatarFrame.reward.AvatarFrameSlotTaskRewardLayer", normalId)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)

    return view
end
----------------------------------------------  slotTask ---------------------------------------------- 

----------------------------------------------  hotPlayers ---------------------------------------------- 
-- 解析关卡 热玩玩家数据
function AvatarFrameManager:parseHotPlayersData(_levelName, _players)
    if not _players or not _levelName then
        return
    end

    local hotPlayerList = {}
    for _, _data in ipairs(_players) do
        if _data and _data.udid ~= globalData.userRunData.userUdid then 
            local playerData = SlotHotPlayerData:create()
            playerData:parseData(_data)
            table.insert(hotPlayerList, playerData)
        end
    end
    if #hotPlayerList > 0 then
        table.sort(hotPlayerList, function(_a, _b)
            return _a:getPriority() > _b:getPriority()
        end)
        self.m_slotHotPlayerList[_levelName] = hotPlayerList
    end
end
-- 获取关卡 热玩玩家数据
function AvatarFrameManager:getHotPlayersData(_levelName, _bForce)
    if not next(self.m_slotHotPlayerList) then
        return {}
    end

    local hotPlayerList = {}
    if self.m_slotHotPlayerList[_levelName] then
        hotPlayerList = self.m_slotHotPlayerList[_levelName]
    elseif _bForce then
        -- 找不到随机给一个, 不然界面太空了
        for i,v in ipairs(self.m_slotHotPlayerList) do
            hotPlayerList = v
            break
        end
    end
    return hotPlayerList
end
-- 清除 记录的关卡热玩 玩家数据
function AvatarFrameManager:clearMachineHotPlayerList()
    self.m_slotHotPlayerList = {}
end
-- 请求关卡 热玩玩家数据
function AvatarFrameManager:sendHotPlayerReq(_levelName)
    if self.m_slotHotPlayerList and self.m_slotHotPlayerList[_levelName] then
        gLobalNoticManager:postNotification(AvatarFrameConfig.EVENT_NAME.RECIEVE_HOT_PLAYER_LIST_SUCCESS)
        return
    end
    local successFunc = function(_levelN, _players)
        self:parseHotPlayersData(_levelN, _players)
        gLobalNoticManager:postNotification(AvatarFrameConfig.EVENT_NAME.RECIEVE_HOT_PLAYER_LIST_SUCCESS)
    end
    self.m_netModel:sendHotPlayerReq(_levelName, successFunc)
end
----------------------------------------------  hotPlayers ---------------------------------------------- 

function AvatarFrameManager:checkCommonAvatarDownload()
    ------------------- 游戏内下载修改测试 -------------------
    -- if self.m_bSign then
    --     return true
    -- end
    -- self.m_bSign = false
    -- performWithDelay(display.getRunningScene(), function()
    --     self.m_bSign = true 
    --     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE)
    -- end, 5)
    -- return self.m_bSign
    ------------------- 游戏内下载修改测试 -------------------
    return self:checkRes("CommonAvatar") and self:checkDownloaded("CommonAvatar") and util_IsFileExist("CommonAvatar/csb/CommonAvatar.csb")
end
function AvatarFrameManager:checkTotalAvatarFrameDownload()
    local bDownload = false

    for i=1, #AvatarFrameConfig.DownloadList do
        local downloadKey = AvatarFrameConfig.DownloadList[i]
        bDownload = self:checkRes(downloadKey) and self:checkDownloaded(downloadKey)
        if not bDownload then
            return false
        end
    end

    return true
end
function AvatarFrameManager:registerListener()

    for i=1, #AvatarFrameConfig.DownloadList do
        local downloadKey = AvatarFrameConfig.DownloadList[i]

        gLobalNoticManager:addObserver(
            self,
            function(target, params)
                local bDownLoad = self:checkTotalAvatarFrameDownload()
                if bDownLoad then
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE)
                end
            end,
            "DL_Complete" .. downloadKey 
        )
    end
end

-- 判断头像框是否是限时头像框
function AvatarFrameManager:checkSelfFrameIdIsLimitType()
    if self.m_bLimit ~= nil then
        return self.m_bLimit
    end

    local data = self:getData()
    if not data then
        return false
    end

    self.m_bLimit = data:checkSelfFrameIsLimitType() or false
end

-- 更新玩家自己头像框 id
function AvatarFrameManager:updateSelfAvatarFrameID()
    local data = self:getData()
    if not data or not tonumber(globalData.userRunData.avatarFrameId) then
        return
    end

    local frameCollectData = data:getFrameCollectDataById(globalData.userRunData.avatarFrameId)
    if not frameCollectData then
        globalData.userRunData.avatarFrameId = nil
        gLobalSendDataManager:getNetWorkFeature():sendNameEmailHead("", "", {avatarFrameId = ""})
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AVATAR_TAKEOFF_SELF_FRAME_UI) --头像卡到期卸下自己的头像框
        return
    end

    if frameCollectData:checkIsEnbaled() then
        return
    end
    globalData.userRunData.avatarFrameId = nil
    gLobalSendDataManager:getNetWorkFeature():sendNameEmailHead("", "", {avatarFrameId = ""})
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_AVATAR_TAKEOFF_SELF_FRAME_UI) --头像卡到期卸下自己的头像框
end

-- 玩家更换头像框
function AvatarFrameManager:changeSelfAvatarFrameID()
    self.m_bLimit = nil
    self:updateSelfAvatarFrameID()
end

return AvatarFrameManager