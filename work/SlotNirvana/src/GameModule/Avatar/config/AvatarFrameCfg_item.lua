--[[
Author: cxc
Date: 2022-04-21 18:07:25
LastEditTime: 2022-04-21 18:07:39
LastEditors: cxc
Description: 头像框 静态表 配置数据
FilePath: /SlotNirvana/src/GameModule/Avatar/config/AvatarFrameCfg_item.lua
--]]
local PropFrame_config = util_require("luaStdTable.PropFrame_config")
local AvatarFrameCfg_item = class("AvatarFrameCfg_item")

function AvatarFrameCfg_item:ctor()
    self.m_cfgFrameIdInfoList = {}
    self.m_totalFrameIdList = {}
    self:init()
end

function AvatarFrameCfg_item:init()
    self.m_titleList = PropFrame_config["id"]
    -- 头像id为主键List
    self.m_cfgFrameIdInfoList = {}
    for key, info in ipairs(PropFrame_config) do
        if type(key) == "string" then
            -- title
        else
            local map = self:parseSingleInfo(key, info)
            local prop_id = map["prop_id"]
            self.m_cfgFrameIdInfoList[prop_id] = map
            table.insert(self.m_totalFrameIdList, prop_id)
        end
    end
end

-- 解析单个信息
function AvatarFrameCfg_item:parseSingleInfo(_key, _info)
    local map = {}
    map["id"] = _key
    map["frameType"] = "item"
    for i=1, #_info do
        local value = _info[i]
        map[self.m_titleList[i]] = value
    end

    return map
end

-- 获取头像框 信息
function AvatarFrameCfg_item:getAvatarFrameCfgInfo(_frameId)
    local info = self.m_cfgFrameIdInfoList[tonumber(_frameId)]
    return info
end

-- 获取 头像框 资源路径
function AvatarFrameCfg_item:getAvatarFrameResInfo(_frameId)
    local info = self:getAvatarFrameCfgInfo(_frameId)
    if not info then
        return
    end
    -- 1：静态图 -- 2：spine骨骼动画 -- 3：csb名字
    local resType = info["propFrame_res_type"]
    local resName = info["propFrame_res_name"] or ""
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

    return {type = resType, path = resPath}
end

-- 获取 所有头像框Id
function AvatarFrameCfg_item:getTotalFrameIdList()
    return self.m_totalFrameIdList
end

-- 获取 头像框来源描述
function AvatarFrameCfg_item:getItemFrameIdGainDesc(_frameId)
    local info = self:getAvatarFrameCfgInfo(_frameId)
    if not info then
        return ""
    end

    return info["propFrame_desc"] or ""
end

return AvatarFrameCfg_item
