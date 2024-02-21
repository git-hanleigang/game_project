--[[

]]

local MissionsToDIYGuideData = require("activities.Activity_MissionsToDIY.model.MissionsToDIYGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local MissionsToDIYMgr = class("MissionsToDIYMgr", GameGuideCtrl)

function MissionsToDIYMgr:ctor()
    MissionsToDIYMgr.super.ctor(self)

    self:setRefName(ACTIVITY_REF.MissionsToDIY)
end

-- 注册引导模块
function MissionsToDIYMgr:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(MissionsToDIYGuideData)
    MissionsToDIYMgr.super.onRegist(self)
end

function MissionsToDIYMgr:onRemove()
    self:stopGuide()
end

-- 加载引导记录数据
function MissionsToDIYMgr:reloadGuideRecords()
    local strData = "{}"
    local data = G_GetMgr(ACTIVITY_REF.MissionsToDIY):getRunningData()
    if data then
        strData = data:getGuideData()
    end
    local tbData = cjson.decode(strData)
    MissionsToDIYMgr.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function MissionsToDIYMgr:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    G_GetMgr(ACTIVITY_REF.MissionsToDIY):setSaveData(strRecords)
end

function MissionsToDIYMgr:updateTipView(tipNode, tipInfo)
    if not tipNode or not tipInfo then
        return
    end
    if tipInfo:isLua() then
        local id = tipInfo:getTipId()
        if tipNode.updateUI then
            tipNode:updateUI(id)
        end
    end
end

return MissionsToDIYMgr
