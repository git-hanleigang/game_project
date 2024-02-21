--[[
Author: cxc
Date: 2022-03-25 15:37:41
LastEditTime: 2022-03-25 15:37:43
LastEditors: cxc
Description: 跳转功能 mgr
FilePath: /SlotNirvana/src/GameModule/JumpTo/JumpToManager.lua
--]]
local JumpToManager = class("JumpToManager", BaseGameControl)
local JumpToSceneManager = util_require("GameModule.JumpTo.JumpToSceneManager")
local JumpToSystemManager = util_require("GameModule.JumpTo.JumpToSystemManager")
local JumpToActManager = util_require("GameModule.JumpTo.JumpToActManager")
local JumpToConfig = util_require("luaStdTable.JumpTo")

local JUMP_TYPE = {
    SCENE = 1,  -- 场景
    SYSTEM = 2, -- 系统
    ACTIVITY = 3 -- 活动
}

function JumpToManager:ctor()
    JumpToManager.super.ctor(self)
    self:setRefName(G_REF.JumpTo)

    self.m_sceneJumpToMgr = JumpToSceneManager:create()
    self.m_sysJumpToMgr = JumpToSystemManager:create()
    self.m_actJumpToMgr = JumpToActManager:create()
end

function JumpToManager:jumpToFeature(_key, _params)
    _key = tonumber(_key) or 0
    if not JumpToConfig[_key] then
        return
    end
    _params = _params or {}

    local info = JumpToConfig[_key]
    local view = nil
    if info[1] == JUMP_TYPE.SCENE then
        self.m_sceneJumpToMgr:jumpToFeature(info, _params)
    elseif  info[1] == JUMP_TYPE.SYSTEM then
        view = self.m_sysJumpToMgr:jumpToFeature(info, _params)
    elseif  info[1] == JUMP_TYPE.ACTIVITY then
        view = self.m_actJumpToMgr:jumpToFeature(info, _params)
    end

    return view, info[1]
end

return JumpToManager