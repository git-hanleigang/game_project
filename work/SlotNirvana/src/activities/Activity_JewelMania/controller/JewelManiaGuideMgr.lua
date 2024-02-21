--[[
    如果是强制引导，一定不能因为数据或者配置问题，导致被卡死在引导上
        解锁了付费奖励，不能卡死在引导界面
        当前的章节不是第一个章节，不能卡死在引导界面
]]

local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local JewelManiaGuideMgr = class("JewelManiaGuideMgr", GameGuideCtrl)

function JewelManiaGuideMgr:ctor()
    JewelManiaGuideMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.JewelMania)

    self:setMaskLua("activities.Activity_JewelMania.view.JewelManiaGuideMaskLayer")
end

-- 注册引导模块
function JewelManiaGuideMgr:onRegist()
    local themeName = G_GetMgr(ACTIVITY_REF.JewelMania):getThemeName()
    self:setGuideTheme(themeName)
    local JewelManiaGuideData = require("activities.Activity_JewelMania.model.JewelManiaGuideData")
    self:initGuideDatas(JewelManiaGuideData)
    JewelManiaGuideMgr.super.onRegist(self)
end

function JewelManiaGuideMgr:getSaveDataKey()
    return "JewelManiaGuideData"
end

-- 加载引导记录数据
function JewelManiaGuideMgr:reloadGuideRecords()
    local strData = "{}"
    local data = G_GetMgr(ACTIVITY_REF.JewelMania):getRunningData()
    if data then
        local key = self:getSaveDataKey()
        strData = gLobalDataManager:getStringByField(key, "{}")
    end
    local tbData = cjson.decode(strData)
    JewelManiaGuideMgr.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function JewelManiaGuideMgr:saveGuideRecord()
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    local key = self:getSaveDataKey()
    gLobalDataManager:setStringByField(key, strRecords)
end

function JewelManiaGuideMgr:getUDefGuideNode(layer, key)
    if key == "s002"  then
        return layer:getChapterByIndex(1)
    elseif key == "s0031"  then
        local guideNodes = layer:getGuideNodes()
        if guideNodes then
            return guideNodes["jewel"]
        end
    elseif key == "s0032"  then
        local guideNodes = layer:getGuideNodes()
        if guideNodes then
            local slateNodes = guideNodes["slate"]
            if slateNodes and #slateNodes > 0 then
                return slateNodes[1]
            end
        end
    elseif key == "s0033"  then
        local guideNodes = layer:getGuideNodes()
        if guideNodes then
            local slateNodes = guideNodes["slate"]
            if slateNodes and #slateNodes > 0 then
                return slateNodes[2]
            end
        end
    elseif key == "s0034"  then
        local guideNodes = layer:getGuideNodes()
        if guideNodes then
            local slateNodes = guideNodes["slate"]
            if slateNodes and #slateNodes > 0 then
                return slateNodes[3]
            end
        end
    elseif key == "s0035"  then
        local guideNodes = layer:getGuideNodes()
        if guideNodes then
            return guideNodes["hammer"]
        end
    elseif key == "s005" then
        return layer:getSlateGuideNumNode()
    end
end

function JewelManiaGuideMgr:triggerGuideAction(callFunc, view, curStepInfo, guideName)
    if callFunc then
        callFunc()
    end
end

-- function JewelManiaGuideMgr:onTouchMaskBegan(pos)
--     gLobalNoticManager:postNotification(ViewEventType.NOTIFY_JEWELMANIA_GUIDE_OVER)
-- end

return JewelManiaGuideMgr
