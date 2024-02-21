--[[
Author: cxc
Date: 2022-04-14 18:19:51
LastEditTime: 2022-04-14 18:19:52
LastEditors: cxc
Description:  头像框 关卡任务 数据
FilePath: /SlotNirvana/src/GameModule/Avatar/model/AvatarFrameSlotData.lua
--]]
local AvatarFrameSlotData = class("AvatarFrameSlotData")
local AvatarFrameSlotTaskData = util_require("GameModule.Avatar.model.AvatarFrameSlotTaskData")

-- message AvatarFrameSlot {
--     optional int32 current = 1; //当前序号
--     optional string gameId = 2; //关卡Id
--     optional int32 completeNum = 3; //任务完成个数
--     repeated AvatarFrameSlotTask tasks = 4; //关卡任务列表
    -- optional int64 betNormal = 5; //普通场解锁Bet
    -- optional int64 betHighLimit = 6; //高倍场解锁Bet
--   }

function AvatarFrameSlotData:ctor()
    self.m_curSeq = 0
    self.m_gameId = ""
    self.m_gameName = ""
    self.m_completeNum = 0
    self.m_taskList = {}
    self.m_betNormalIdx = 0
    self.m_betHighLimitIdx = 0

    self.m_bCompleteNewTask = false
end

function AvatarFrameSlotData:parseData(_data)
    if not _data then
        return
    end

    self.m_curSeq = _data.current or 0
    self.m_gameId = _data.gameId or ""
    self:parseSlotGameName()
    self.m_completeNum = _data.completeNum or 0
    self:parseTaskData(_data.tasks or {})
    self.m_betNormalIdx = tonumber(_data.betNormal) or 0
    self.m_betHighLimitIdx = tonumber(_data.betHighLimit) or 0
end

function AvatarFrameSlotData:parseTaskData(_list)
    self.m_taskList = {}
    for i, data in ipairs(_list) do
        local slotData = AvatarFrameSlotTaskData:create()
        slotData:parseData(data, self.m_gameId, self.m_gameName)
        table.insert(self.m_taskList, slotData)
    end
end


-- get 当前序号
function AvatarFrameSlotData:getCurSeq()
    return self.m_curSeq + 1
end
-- get 关卡Id
function AvatarFrameSlotData:getGameId()
    return self.m_gameId
end
function AvatarFrameSlotData:getSlotGameName()
    return self.m_gameName
end
function AvatarFrameSlotData:parseSlotGameName()
    local name = ""
    local levelInfo = globalData.slotRunData:getLevelInfoById(self.m_gameId)
    if levelInfo then
        name = levelInfo:getServerShowName()
    end
    self.m_gameName = name
end
-- get 任务完成个数
function AvatarFrameSlotData:getCompleteNum()
    return self.m_completeNum
end
-- get 任务个数
function AvatarFrameSlotData:getTotalNum()
    return #self.m_taskList
end
-- get 关卡任务列表
function AvatarFrameSlotData:getTaskList()
    return self.m_taskList
end
-- get 关卡任务 _idx
function AvatarFrameSlotData:getTaskDataByIdx(_idx)
    return self.m_taskList[_idx]
end
-- get 关卡任务 _frameId
function AvatarFrameSlotData:getTaskDataByFrameId(_frameId)

    for i, data in ipairs(self.m_taskList) do
        local frameId = data:getFrameId()
        if tostring(frameId) == tostring(_frameId) then
            return data
        end
    end

end
-- get 关卡任务 普通场解锁Bet _idx
function AvatarFrameSlotData:getTaskBetNormalIdx()
    return self.m_betNormalIdx
end
-- get 关卡任务 高倍场解锁Bet _idx
function AvatarFrameSlotData:getTaskBetHighLimitIdx()
    return self.m_betHighLimitIdx
end
----------------------- deal -----------------------
-- 更新数据
function AvatarFrameSlotData:updateCurTaskSeq(_idx)
    self.m_curSeq = math.min(_idx, self:getTotalNum() - 1)
    local bCompleteNew = false
    local curTaskData = self:getTaskDataByIdx(self.m_completeNum + 1)
    if curTaskData then
        bCompleteNew = curTaskData:getStatus() == 2
    end
    if bCompleteNew then
        self.m_completeNum  = math.min(self.m_completeNum + 1, self:getTotalNum())
    end 

    return bCompleteNew
end

function AvatarFrameSlotData:getCurCompleteTaskData()
    local curTaskData = self:getTaskDataByIdx(self.m_completeNum)
    return curTaskData
end

return AvatarFrameSlotData