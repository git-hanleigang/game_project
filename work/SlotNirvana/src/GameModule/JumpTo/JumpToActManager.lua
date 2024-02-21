--[[
Author: cxc
Date: 2022-03-25 17:08:10
LastEditTime: 2022-03-25 17:08:12
LastEditors: cxc
Description: 跳转功能 活动 mgr
FilePath: /SlotNirvana/src/GameModule/JumpTo/JumpToActManager.lua
--]]
local JumpToActManager = class("JumpToActManager")

function JumpToActManager:jumpToFeature(_info, _params)
    if not _info then
        return
    end

    local actRefName =  _info[3] or ""
    if string.len(actRefName) == 0 then
        return
    end

    local actMgr = G_GetMgr(actRefName)
    if not actMgr then
        return
    end

    return actMgr:showMainLayer()
end

return JumpToActManager
