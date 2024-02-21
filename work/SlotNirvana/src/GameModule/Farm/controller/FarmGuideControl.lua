local FarmGuideData = require("GameModule.Farm.model.FarmGuideData")
local GameGuideCtrl = require("GameModule.Guide.GameGuideCtrl")
local FarmGuideControl = class("FarmGuideControl", GameGuideCtrl)

function FarmGuideControl:ctor()
    FarmGuideControl.super.ctor(self)
    self:setRefName(G_REF.Farm)
end

-- 注册引导模块
function FarmGuideControl:onRegist(guideTheme)
    self:setGuideTheme(guideTheme)
    self:initGuideDatas(FarmGuideData)
    FarmGuideControl.super.onRegist(self)
end

function FarmGuideControl:onRemove()
    self:stopGuide()
end

-- 加载引导记录数据
function FarmGuideControl:reloadGuideRecords()
    local strData = "{}"
    local farmData = G_GetMgr(G_REF.Farm):getRunningData()
    if farmData then
        local saveData = farmData:getSaveData()
        if saveData and #saveData > 0 then
            strData = saveData
        end
    end
    local tbData = cjson.decode(strData)

    FarmGuideControl.super.reloadGuideRecords(self, tbData)
end

-- 引导记录数据存盘
function FarmGuideControl:saveGuideRecord(_curStepInfo, _guideName)
    local curStepInfo = _curStepInfo
    local guideTheme = self:getGuideTheme()
    local strRecords = self:getGuideRecord2Str(guideTheme)
    local type = 0
    if curStepInfo then
        local stepId = curStepInfo:getStepId()
        if stepId == "5001" then
            G_GetMgr(G_REF.Farm):sendGuideLog(12, 1)
            type = 1
        end
    end
    G_GetMgr(G_REF.Farm):sendGuide(strRecords, type)
end

function FarmGuideControl:getUDefGuideNode(layer, key)
    if key == "s005" or key == "s007" or key == "t203" or key == "t204" or key == "t208" then
        return layer["m_mainLand"]:findChild("node_land_1")
    elseif key == "s015" then
        return layer["m_mainLand"]["m_tipBubble"]
    end
end

function FarmGuideControl:updateTipView(tipNode, tipInfo)
    if tipInfo:isLua() then
        local id = tipInfo:getTipId()
        local offsetX, offsetY = 0, 0
        if tipNode.updateGuide then
            tipNode:updateGuide(id)
        end

        if tipNode.resetFingerAnimaition then
            tipNode:resetFingerAnimaition()
        end

        if tipNode.setOffsetPos then
            tipNode:setOffsetPos(0, 0)
        end
        if id == "t202" then
            offsetY = -30
        elseif id == "t204" then
            offsetY = 115
        elseif id == "t205" then
            offsetY = 90
        elseif id == "t206" then
            offsetX = -305
            offsetY = 142
        elseif id == "t207" then
            offsetX = -372
            offsetY = -95
        elseif id == "t208" then
            offsetY = 115
        elseif id == "t210" then
            offsetX = -305
            offsetY = -123
        end
        if tipNode.setOffsetPos then
            tipNode:setOffsetPos(offsetX, offsetY)
        end
    end
end

function FarmGuideControl:getFarmGuideCfg()
    return FarmGuideData
end

return FarmGuideControl
