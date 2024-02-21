--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-05-30 17:30:09
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-05-30 17:30:58
FilePath: /SlotNirvana/src/GameModule/Avatar/model/AvatarFrameStaticData.lua
Description: 头像框 静态数据
--]]
local AvatarFrameStaticData =  class("AvatarFrameStaticData")
local AvatarFrameCfg_slot = util_require("GameModule.Avatar.config.AvatarFrameCfg_slot")
local AvatarFrameCfg_item = util_require("GameModule.Avatar.config.AvatarFrameCfg_item")

local ITEM_FRAME_ID_START =  900

function AvatarFrameStaticData:ctor()
    self.m_frameCfg_slot = AvatarFrameCfg_slot:create()
    self.m_frameCfg_item = AvatarFrameCfg_item:create()
    self.m_totalFrameIdList = {}
    self:init()
end

function AvatarFrameStaticData:init()
    --头像框idList
    self.m_slotIdList = self.m_frameCfg_slot:getTotalFrameIdList()
    self.m_itemIdList = self.m_frameCfg_item:getTotalFrameIdList()
    table.insertto(self.m_totalFrameIdList, self.m_slotIdList)
    table.insertto(self.m_totalFrameIdList, self.m_itemIdList)
end

-- 获取头像框 信息
function AvatarFrameStaticData:getAvatarFrameCfgInfo(_frameId)
    if not _frameId then
        return
    end
    _frameId = tonumber(_frameId) or 0
    local target = self.m_frameCfg_slot
    if _frameId >= ITEM_FRAME_ID_START then
        target = self.m_frameCfg_item
    end
    
    local info = target:getAvatarFrameCfgInfo(_frameId)
    return info
end

-- 获取 头像框 资源路径
function AvatarFrameStaticData:getAvatarFrameResInfo(_frameId)
    if not _frameId then
        return
    end
    _frameId = tonumber(_frameId) or 0
    local target = self.m_frameCfg_slot
    if _frameId >= ITEM_FRAME_ID_START then
        target = self.m_frameCfg_item
    end
    
    local info = target:getAvatarFrameResInfo(_frameId)
    return info
end

-- 获取 所有头像框Id
function AvatarFrameStaticData:getTotalFrameIdList(_type)
    if _type == "slot" then
        return self.m_slotIdList
    elseif _type == "item" then
        return self.m_itemIdList
    end
    
    return self.m_totalFrameIdList
end

-- 获取静态表
function AvatarFrameStaticData:getFrameCfg(_type)
    if _type == "slot" then
        return self.m_frameCfg_slot
    elseif _type == "item" then
        return self.m_frameCfg_item
    end
end

-- 获取 关卡图片 资源路径
function AvatarFrameStaticData:getSlotImgPath(_slotId)
    return self.m_frameCfg_slot:getSlotImgPath(_slotId)
end

-- 获取 关卡名称
function AvatarFrameStaticData:getSlotIconPath(_slotId)
    return self.m_frameCfg_slot:getSlotIconPath(_slotId)
end

return AvatarFrameStaticData