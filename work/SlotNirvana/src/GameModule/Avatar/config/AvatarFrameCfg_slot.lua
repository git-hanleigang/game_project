--[[
Author: cxc
Date: 2022-04-21 18:07:25
LastEditTime: 2022-04-21 18:07:39
LastEditors: cxc
Description: 头像框 静态表 配置数据
FilePath: /SlotNirvana/src/GameModule/Avatar/config/AvatarFrameCfg_slot.lua
--]]
local SlotFrame_config = util_require("luaStdTable.SlotFrame_config")
local AvatarFrameCfg_slot = class("AvatarFrameCfg_slot")

function AvatarFrameCfg_slot:ctor()
    self.m_totalFrameIdList = {}
    self.m_cfgFrameIdInfoList = {}
    self.m_cfgSlotIdInfoList = {}
    self.m_slotTotalFrameIdList = {}
    self:init()
end

function AvatarFrameCfg_slot:init()
    self.m_titleList = SlotFrame_config["id"]
    -- 头像id为主键List
    self.m_cfgFrameIdInfoList = {}
    -- slot关卡ID 为主键list
    self.m_cfgSlotIdInfoList = {}
    for key, info in ipairs(SlotFrame_config) do
        if type(key) == "string" then
            -- title
        else
            local map = self:parseSingleInfo(key, info)
            self.m_cfgFrameIdInfoList[key] = map
            table.insert(self.m_totalFrameIdList, map["id"])

            self:addSlotInfo(map)
        end
    end
end

-- 解析单个信息
function AvatarFrameCfg_slot:parseSingleInfo(_key, _info)
    local map = {}
    map["id"] = _key
    map["frameType"] = "slot"
    for i=1, #_info do
        local value = _info[i]
        map[self.m_titleList[i]] = value
    end

    return map
end

-- 添加关卡信息
function AvatarFrameCfg_slot:addSlotInfo(_info)
    local slotId = tostring(_info["slot_id"])
    if not self.m_cfgSlotIdInfoList[slotId] then
        self.m_cfgSlotIdInfoList[slotId] = {}
    end
    table.insert(self.m_cfgSlotIdInfoList[slotId], _info)
end

-- 获取头像框 信息
function AvatarFrameCfg_slot:getAvatarFrameCfgInfo(_frameId)
    local info = self.m_cfgFrameIdInfoList[tonumber(_frameId)]
    return info
end

-- 获取 头像框 资源路径
function AvatarFrameCfg_slot:getAvatarFrameResInfo(_frameId)
    local info = self:getAvatarFrameCfgInfo(_frameId)
    if not info then
        return
    end
    -- 1：静态图 -- 2：spine骨骼动画 -- 3：csb名字
    local resType = info["frame_res_type"]
    local resName = info["frame_res_name"] or ""
    if string.len(resName) == 0 then
        return
    end

    local resPath = ""
    if resType == 1 then
        resPath = string.format("CommonAvatar/ui/frame/idle/%s.png", resName)
    elseif resType == 2 then
        resPath = string.format("CommonAvatar/ui/frame/spine/%s", resName)
    elseif resType == 3 then
        resPath = string.format("CommonAvatar/csb/frame/%s.csb", resName)
    end

    local season = math.ceil(tonumber(_frameId) / 30)-- 一个赛季6关30个头像框
    return {type = resType, path = resPath, season = season}
end

-- 获取 关卡图片 资源路径
function AvatarFrameCfg_slot:getSlotImgPath(_slotId)
    local infoList = self.m_cfgSlotIdInfoList[tostring(_slotId)] 
    if not infoList or #infoList == 0 then
        return
    end

    local info = infoList[#infoList]
    local slotPic = info["slot_pic"] or ""
    return string.format("CommonAvatar/ui/slot/%s.png", slotPic)
end

-- 获取 关卡名字
function AvatarFrameCfg_slot:getSlotIconPath(_slotId)
    local infoList = self.m_cfgSlotIdInfoList[tostring(_slotId)] 
    if not infoList or #infoList == 0 then
        return
    end

    local info = infoList[#infoList]
    local slotPic = info["slot_pic"] or ""
    return slotPic
end

-- 获取 所有头像框Id
function AvatarFrameCfg_slot:getTotalFrameIdList()
    return self.m_totalFrameIdList
end

-- 获取 某关卡 所有的头像框Id
function AvatarFrameCfg_slot:getSlotTotalFrameIdList(_slotId)
    local slotId = tostring(_slotId)
    if self.m_slotTotalFrameIdList[slotId] then
        return self.m_slotTotalFrameIdList[slotId]
    end

    local infoList = self.m_cfgSlotIdInfoList[slotId] 
    if not infoList or #infoList == 0 then
        return {}
    end

    self.m_slotTotalFrameIdList[slotId] = {}
    for i, info in ipairs(infoList) do
        table.insert(self.m_slotTotalFrameIdList, slotId)
    end
    return self.m_slotTotalFrameIdList[slotId]
end

return AvatarFrameCfg_slot
