--[[
Author: cxc
Date: 2022-04-13 16:21:20
LastEditTime: 2022-04-13 16:21:21
LastEditors: cxc
Description: 头像框 数据
FilePath: /SlotNirvana/src/GameModule/Avatar/model/AvatarFrameData.lua
--]]
local AvatarFrameData = class("AvatarFrameData")
local AvatarFrameSlotData = util_require("GameModule.Avatar.model.AvatarFrameSlotData")
local AvatarFrameGameData = util_require("GameModule.AvatarGame.model.AvatarFrameGameData")
local AvatarFrameStatsData = util_require("GameModule.Avatar.model.AvatarFrameStatsData")
local AvatarFrameCollectData = util_require("GameModule.Avatar.model.AvatarFrameCollectData")

function AvatarFrameData:ctor()
    self.m_holdFrameList = {} 
    self.m_slotTaskList = {}
    self.m_miniGameData = nil
    self.m_statsData = nil
    self.m_slotTaskCompleteList = {}
    self.m_holdFrameTimeList = {}  --头像框时间
    self.m_likeFrameList = {}  --喜欢的头像框
end

-- message AvatarFrame {
--     repeated string frames = 1; //已获得的头像框(废弃)
--     repeated AvatarFrameSlot slots = 2; //老虎机任务
--     optional AvatarFrameGame game = 3; //小游戏
--     optional AvatarFrameStats stats = 4; //历史数据
--     repeated AvatarFrameCollection collections = 5; //已收藏的头像
--     repeated string favoriteFrame = 6; //喜欢的头像框
--   }
function AvatarFrameData:parseData(_data)
    if not _data then
        return
    end

    -- self.m_holdFrameList = _data.frames or {}
    self:parseSlotTaskData(_data.slots or {})
    self:parseMiniGameData(_data.game or {})
    self:parseStatsData(_data.stats or {})
    self:parseHoldFrameList(_data.collections or {})
    self:parseFavoriteData(_data.favoriteFrame or {})
    self.favoriteUpdate = _data.favoriteUpdate or 0

    self.m_bOnce = false
end

-- 已收藏的头像框
-- message AvatarFrameCollection {
--     optional string name = 1; //名称
--     optional int64 collectAt = 2; //收藏时间
--     optional int64 expireAt = 3; //过期时间
--   }
function AvatarFrameData:parseHoldFrameList(_list)
    self.m_holdFrameTimeList = {} 
    for i=1, #_list do
        local data = AvatarFrameCollectData:create(_list[i])
        table.insert(self.m_holdFrameTimeList, data)
    end

    self:resetHoldFrameList()
end 

--解析喜欢的头像框
function AvatarFrameData:parseFavoriteData(_data)
    self.m_likeFrameList = _data
end

-- 解析老虎机任务 数据
function AvatarFrameData:parseSlotTaskData(_list)
    self.m_slotTaskList = {}
    for i, data in ipairs(_list) do
        local slotData = AvatarFrameSlotData:create()
        slotData:parseData(data)
        local gameId = slotData:getGameId()
        local completeIdx = slotData:getCompleteNum()
        local preCompleteIdx = self.m_slotTaskCompleteList[gameId] and self.m_slotTaskCompleteList[gameId].completeIdx
        if preCompleteIdx and preCompleteIdx < completeIdx then
            self.m_slotTaskCompleteList[gameId] = {completeIdx = completeIdx, bCompleteNew = true}
        else
            self.m_slotTaskCompleteList[gameId] = {completeIdx = completeIdx, bCompleteNew = false}
        end 
        self.m_slotTaskList[gameId] = slotData
    end
end

-- 解析小游戏 数据
function AvatarFrameData:parseMiniGameData(_data)
    local miniGameData = AvatarFrameGameData:create()
    miniGameData:parseData(_data)
    self.m_miniGameData = miniGameData
end

-- 解析历史统计 数据
function AvatarFrameData:parseStatsData(_data)
    local statsData = AvatarFrameStatsData:create()
    statsData:parseData(_data)
    self.m_statsData = statsData
end

-- reset玩家拥有头像框 list
function AvatarFrameData:resetHoldFrameList()
    self.m_holdFrameList = {}
    local tempHoldTimeList = {}
    for i=1, #self.m_holdFrameTimeList do
        local data = self.m_holdFrameTimeList[i]
        if data:checkIsEnbaled() then
            table.insert(self.m_holdFrameList, data:getFrameId())
            table.insert(tempHoldTimeList, data)
        end
    end
    self.m_holdFrameTimeList = tempHoldTimeList

    -- 个人头像是否到期
    if not tonumber(globalData.userRunData.avatarFrameId) then
        return
    end
    local selfFrameIdBExit = false
    for i=1, #self.m_holdFrameList do
        if tostring(globalData.userRunData.avatarFrameId) == tostring(self.m_holdFrameList[i]) then
            selfFrameIdBExit = true
            break
        end
    end
    if not selfFrameIdBExit then
        globalData.userRunData.avatarFrameId = nil
    end
end

-- 检查自己的头像框是否是  限时头像框
function AvatarFrameData:checkSelfFrameIsLimitType()
    if not tonumber(globalData.userRunData.avatarFrameId) then
        return
    end

    local data = self:getFrameCollectDataById(globalData.userRunData.avatarFrameId) 
    if not data then
        return
    end

    return data:checkIsTimeLimitType() 
end

-- 获取头像框 数据 collect
function AvatarFrameData:getFrameCollectDataById(_frameId)
    if not _frameId then
        return
    end

    for i=1, #self.m_holdFrameTimeList do
        local data = self.m_holdFrameTimeList[i]
        if tostring(_frameId) == tostring(data:getFrameId()) then
            return data
        end
    end
end

function AvatarFrameData:getLikeFrameList()
    local list = {}
    for i=1, #self.m_likeFrameList do
        local frameId = self.m_likeFrameList[i]
        local bExit = self:getFrameCollectDataById(frameId)
        if bExit then
            table.insert(list, frameId)
        end
    end
    self.m_likeFrameList = list
    return self.m_likeFrameList
end

function AvatarFrameData:getHoldFrameTimeList()
    self:resetHoldFrameList()
    return self.m_holdFrameTimeList
end
--获取操作状态
function AvatarFrameData:getLikeStatus()
    return self.favoriteUpdate
end

function AvatarFrameData:setLikeFrameList(_list)
    self.m_likeFrameList = _list
end

function AvatarFrameData:setLikeStatus()
    self.favoriteUpdate = 1
end
-- get 已获得的头像框
function AvatarFrameData:getHoldFrameList()
    self:resetHoldFrameList()
    return self.m_holdFrameList
end
-- get 开启的关卡列表
function AvatarFrameData:getOpenSlotIdList()
    return table.keys(self.m_slotTaskList)
end
-- get 老虎机任务
function AvatarFrameData:getSlotTaskList()
    return self.m_slotTaskList
end
-- get 老虎机任务
function AvatarFrameData:getSlotTaskBySlotId(_id)
    local machineNormalId = "1" .. string.sub(tostring(_id) or "", 2)
    return self.m_slotTaskList[machineNormalId]
end
-- get 小游戏
function AvatarFrameData:getMiniGameData()
    return self.m_miniGameData
end
-- get 历史数据
function AvatarFrameData:getStatsData()
    return self.m_statsData
end
-- get 老虎机任务领取状态
function AvatarFrameData:getSlotTaskCompleteList()
    return self.m_slotTaskCompleteList
end
-- reset 老虎机任务领取状态
function AvatarFrameData:resetSlotTaskCompleteList(_slotId)
    local slotId = tostring(_slotId)
    if self.m_slotTaskCompleteList[slotId] then
        local slotData = self.m_slotTaskList[slotId]
        local completeIdx = slotData:getCompleteNum()
        self.m_slotTaskCompleteList[slotId].completeIdx = completeIdx
        self.m_slotTaskCompleteList[slotId].bCompleteNew = false
    end
end

-------------------------- deal --------------------------
-- 添加新获得的头像框
function AvatarFrameData:addHoldFrame(_frameId)
    if not _frameId then
        return
    end 

    table.insert(self.m_holdFrameList, _frameId) 
end

-- 添加新获得的头像框时间
function AvatarFrameData:addHoldFrameTime(_frameId,_time)
    if not _frameId then
        return
    end 
    local data = {}
    data.name = _frameId
    data.collectAt = _time
    local collectData = AvatarFrameCollectData:create(data)
    table.insert(self.m_holdFrameTimeList, collectData) 
end
-- 更新当前的关卡任务
function AvatarFrameData:updateSlotCurrentTaskData(_currentTask)
    if not _currentTask then
        return
    end 

    local slotId = G_GetMgr(G_REF.AvatarFrame):getCurLevelNormalSlotId()
    local data = self:getSlotTaskBySlotId(slotId)
    if not data then
        return
    end

    local curSeq = data:getCurSeq()
    local taskData = data:getTaskDataByIdx(curSeq)
    if not taskData then
        return
    end

    taskData:parseData(_currentTask) 
end

-- 更新所有关卡任务
function AvatarFrameData:updateSlotData(_current, _tasks)
    if not _current and not _tasks then
        return
    end
    
    local slotId = G_GetMgr(G_REF.AvatarFrame):getCurLevelNormalSlotId()
    local data = self:getSlotTaskBySlotId(slotId)
    if not data then
        return
    end

    data:parseTaskData(_tasks)
    local bCompleteNew = data:updateCurTaskSeq(_current)
    if bCompleteNew then
        self.m_slotTaskCompleteList[tostring(slotId)].bCompleteNew = true
    end
end

function AvatarFrameData:updateMiniGameProp(_count)
    if not _count or not self.m_miniGameData then
        return
    end

    self.m_miniGameData:setPropsNum(_count) 
end 
-------------------------- deal --------------------------


return AvatarFrameData