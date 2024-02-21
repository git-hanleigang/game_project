--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2022-07-05 11:39:17
    describe:三周年分挑战管理器
]]
local MemoryLanegNet = require("activities.Activity_MemoryLane.net.MemoryLaneNet")
local MemoryLaneMgr = class(" MemoryLaneMgr", BaseActivityControl)

-- 构造函数
function MemoryLaneMgr:ctor()
    MemoryLaneMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MemoryLane)
    self.m_MemoryLaneNet = MemoryLanegNet:getInstance()
end

function MemoryLaneMgr:showPhotoLayer(params)
    local uiView = util_createView("Activity.Activity_MemoryLanePhotoLayer", params)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

function MemoryLaneMgr:showRewardLayer(params)
    local uiView = util_createView("Activity.Activity_MemoryLaneRewardLayer", params)
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
    return uiView
end

-- 奖励领取
function MemoryLaneMgr:requestRewardCollect(_type, _photoId)
    self.m_MemoryLaneNet:requestRewardCollect(_type, _photoId)
end

return MemoryLaneMgr
