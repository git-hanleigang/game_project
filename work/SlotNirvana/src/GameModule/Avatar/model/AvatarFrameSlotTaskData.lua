--[[
Author: cxc
Date: 2022-04-15 15:10:39
LastEditTime: 2022-04-15 15:10:40
LastEditors: cxc
Description: 头像框 关卡任务详情 数据
FilePath: /SlotNirvana/src/GameModule/Avatar/model/AvatarFrameSlotTaskData.lua
--]]
local AvatarFrameSlotTaskData = class("AvatarFrameSlotTaskData")
local ShopItem = util_require("data.baseDatas.ShopItem")

local LEVEL_DESC = {"BRONZE", "SILVER", "GOLD", "PLATINUM", "DIAMOND"}
-- message AvatarFrameSlotTask {
--     optional int32 seq = 1; //序号
--     optional int64 param = 2; //参数
--     optional int64 progress = 3; //进度
--     repeated ShopItem reward = 4; //奖励物品
--     optional string frame = 5; //头像框
--     optional int32 status = 6; //0未激活， 1正在进行， 2已完成
--     optional string text = 7; //描述Key
--     optional int64 completeTime = 8; //任务完成时间
--   }

function AvatarFrameSlotTaskData:ctor()
    self.m_slotGameId = ""
    self.m_slotGameName = ""
    self.m_seq = 0
    self.m_limitNum = 0
    self.m_progress = 0
    self.m_rewardList = {}
    self.m_frameId = ""
    self.m_status = 0
    self.m_desc = ""
    self.m_completeTime = 0
    self.m_miniGameCount = 0
end

function AvatarFrameSlotTaskData:parseData(_data, _slotGameId, _slotGameName)
    if not _data then
        return
    end

    if _slotGameId then
        self.m_slotGameId = _slotGameId
    end
    if _slotGameName then
        self.m_slotGameName = _slotGameName
    end
    self.m_seq = _data.seq or 0
    self.m_limitNum = tonumber(_data.param) or 0
    self.m_progress = _data.progress or 0
    self:parseRewardData(_data.reward or {})
    self.m_frameId = _data.frame or ""
    self.m_status = math.min(_data.status or 0, 2)
    self.m_desc = self:parseDesc(_data.text)
    self.m_completeTime = _data.completeTime or 0 
end

function AvatarFrameSlotTaskData:parseRewardData(_items)
    self.m_rewardList = {}
    self.m_miniGameCount = 0
    if not _items then
        return
    end

    for i = 1, #_items do
		local itemData = _items[i]
		local rewardItem = ShopItem:create()
        rewardItem:parseData(itemData)
        if rewardItem.p_icon == "AvatarFrameMiniGame" then
            self.m_miniGameCount = self.m_miniGameCount + rewardItem.p_num
        end
		table.insert(self.m_rewardList, rewardItem)
	end
end

-- get 关卡Id name
function AvatarFrameSlotTaskData:getSlotGameId()
    return self.m_slotGameId
end
function AvatarFrameSlotTaskData:getSlotGameName()
    return self.m_slotGameName
end
-- get 序号
function AvatarFrameSlotTaskData:getSeq()
    return self.m_seq
end
-- 任务默认 等级描述
function AvatarFrameSlotTaskData:getFrameDefaultDesc()
    return LEVEL_DESC[self.m_seq] or ""
end
-- 任务默认 等级描述
function AvatarFrameSlotTaskData:getFrameLevelDesc()
    local staticInfo = G_GetMgr(G_REF.AvatarFrame):getAvatarFrameCfgInfo(self.m_frameId)
    local desc = self:getFrameDefaultDesc()
    if staticInfo then
        desc = staticInfo["frame_desc"] or ""
    end
    return desc
end
-- get 任务要求个数
function AvatarFrameSlotTaskData:getLimitNum()
    return self.m_limitNum
end
-- get 任务当前完成个数
function AvatarFrameSlotTaskData:getProgress()
    return self.m_progress
end
-- get 奖励物品
function AvatarFrameSlotTaskData:getRewardList()
    return self.m_rewardList
end
function AvatarFrameSlotTaskData:getRewardFrameMiniGameCount()
    return self.m_miniGameCount
end
-- get 头像框
function AvatarFrameSlotTaskData:getFrameId()
    return self.m_frameId
end
-- get 0未激活， 1正在进行， 2已完成
function AvatarFrameSlotTaskData:getStatus()
    return self.m_status
end
-- get 描述
function AvatarFrameSlotTaskData:parseDesc(_desc)
    local desc = _desc or ""
    -- 文本类型
    desc = string.gsub(desc, "%%S", "%%s")
    local strList = string.split(desc, "%s") or {}
    if #strList < 2 then
        -- 无数字 简单的描述
        return desc
    end

    return string.format(desc, tostring(self.m_limitNum))
end
function AvatarFrameSlotTaskData:getDesc()
    return self.m_desc
end
-- get 任务完成时间
function AvatarFrameSlotTaskData:getCompleteTime()
    return self.m_completeTime * 0.001
end

return AvatarFrameSlotTaskData