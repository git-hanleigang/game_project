--[[

    time:2022-09-01 11:38:28
]]
local EgyptCoinPusherGuideData = require("activities.Activity_EgyptCoinPusher.model.EgyptCoinPusherGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local EgyptCoinPusherGuideMgr = class("EgyptCoinPusherGuideMgr", GameGuideCtrl)

function EgyptCoinPusherGuideMgr:ctor()
    EgyptCoinPusherGuideMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.EgyptCoinPusher)
end

-- 注册引导模块
function EgyptCoinPusherGuideMgr:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(EgyptCoinPusherGuideData)
    EgyptCoinPusherGuideMgr.super.onRegist(self)
end

function EgyptCoinPusherGuideMgr:onRemove()
    self:stopGuide()
end

function EgyptCoinPusherGuideMgr:getSaveDataKey()
    return "EgyptCoinPusherGuideData"
end

-- 加载引导记录数据
function EgyptCoinPusherGuideMgr:reloadGuideRecords()
    local strData = "{}"
    local data = G_GetMgr(ACTIVITY_REF.EgyptCoinPusher):getRunningData()
    if data then
        local key = self:getSaveDataKey()
        strData = gLobalDataManager:getStringByField(key, "{}")
    end
    local tbData = cjson.decode(strData)

    EgyptCoinPusherGuideMgr.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function EgyptCoinPusherGuideMgr:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    local key = self:getSaveDataKey()
    gLobalDataManager:setStringByField(key, strRecords)
end

-- DeBug 清除引导缓存
function EgyptCoinPusherGuideMgr:clearGuideRecord()
    local strData = "{}"
    local tbData = cjson.decode(strData)
    local key = self:getSaveDataKey()
    gLobalDataManager:setStringByField(key, tbData)
end

function EgyptCoinPusherGuideMgr:getUDefGuideNode(layer, key)
    if key == "s001"  then
        return layer:getUpGuideNode()
    end
end

function EgyptCoinPusherGuideMgr:updateTipView(tipNode, tipInfo)
    if tipInfo:isLua() then
        local id = tipInfo:getTipId()
        if tipNode.updateGuide then
            tipNode:updateGuide(id)
        end
    end
end

return EgyptCoinPusherGuideMgr
