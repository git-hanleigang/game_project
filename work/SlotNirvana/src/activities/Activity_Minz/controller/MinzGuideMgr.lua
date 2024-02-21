--[[

    time:2022-09-01 11:38:28
]]
local MinzGuideData = require("activities.Activity_Minz.model.MinzGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local MinzGuideMgr = class("MinzGuideMgr", GameGuideCtrl)

function MinzGuideMgr:ctor()
    MinzGuideMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Minz)
end

-- 注册引导模块
function MinzGuideMgr:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(MinzGuideData)
    MinzGuideMgr.super.onRegist(self)
end

function MinzGuideMgr:onRemove()
    self:stopGuide()
end

function MinzGuideMgr:getSaveDataKey()
    return "MinzGuideData"
end

-- 加载引导记录数据
function MinzGuideMgr:reloadGuideRecords()
    local strData = "{}"
    local data = G_GetMgr(ACTIVITY_REF.Minz):getRunningData()
    if data then
        local key = self:getSaveDataKey()
        strData = gLobalDataManager:getStringByField(key, "{}")
    end
    local tbData = cjson.decode(strData)

    MinzGuideMgr.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function MinzGuideMgr:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    local key = self:getSaveDataKey()
    gLobalDataManager:setStringByField(key, strRecords)
end

function MinzGuideMgr:getUDefGuideNode(layer, key)
    if key == "s001"  then
        return layer:getCollectsNode()
    elseif key == "s002"  then
        return layer:getSlotNode()
    elseif key == "s003"  then
        return layer:getSpinNode()
    end
end

function MinzGuideMgr:updateTipView(tipNode, tipInfo)
    if tipInfo:isLua() then
        local id = tipInfo:getTipId()
        if tipNode.updateGuide then
            tipNode:updateGuide(id)
        end
    end
end

return MinzGuideMgr
