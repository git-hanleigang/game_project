--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2024-01-10 14:44:31
]]
local SidekicksGuideData = class("SidekicksGuideData")

local mainLayerGuideInfo = {
    [0] = {stepId = 0, nextStepId = 1, desc = ""},
    [1] = {stepId = 1, nextStepId = 2, desc = "宠物打招呼"},
    [2] = {stepId = 2, nextStepId = 3, desc = "宠物狗命名"},
    [3] = {stepId = 3, nextStepId = 4, desc = "宠物狗感谢表示喜欢新名字"},
    [4] = {stepId = 4, nextStepId = 5, desc = "为宠物猫命名"},
    [5] = {stepId = 5, nextStepId = 6, desc = "宠物猫感谢表示喜欢新名字"},
    [6] = {stepId = 6, nextStepId = nil, hightNodeInfo = {"getFeedBtnNode", "resetFeedBtnNode"}, desc = "引导喂养狗"},
}

local detailLayerGuideInfo = {
    [0] = {stepId = 0, nextStepId = 1, desc = ""},
    [1] = {stepId = 1, nextStepId = 2, desc = "介绍宠物技能"},
    [2] = {stepId = 2, nextStepId = 3, bCoerce = true, hightNodeInfo = {"getStarUpBtnNode", "resetStarUpBtnNode"}, desc = "引导宠物升星"},
    [3] = {stepId = 3, nextStepId = 4, desc = "介绍升星的权益"},
    [4] = {stepId = 4, nextStepId = 5, bCoerce = true, hightNodeInfo = {"getLevelUpBtnNode", "resetLevelUpBtnNode"}, desc = "引导升级"},
    [5] = {stepId = 5, nextStepId = 6, desc = "介绍升级权益"},
    [6] = {stepId = 6, nextStepId = nil, desc = "介绍关卡权益"},
}

function SidekicksGuideData:ctor()
    self._mainLayerGuideStep = 0 -- 主界面引导步骤
    self._detailLayerGuideStep = 0 -- 宠物详情界面引导步骤
    self._bEnterDetailLayer = false -- 是否进入过宠物详情界面
end
function SidekicksGuideData:parseData(_data)
    if not _data then
        return
    end

    self._mainLayerGuideStep = _data.mainLayerGuideStep or 99
    self._detailLayerGuideStep = _data.detailLayerGuideStep or 99
    self._bEnterDetailLayer = _data.bEnterDetailLayer or false
end

function SidekicksGuideData:setMainLayerGuideStep(_stepId)
    self._mainLayerGuideStep = _stepId
end
function SidekicksGuideData:getMainLayerGuideStep()
    return self._mainLayerGuideStep or 99
end
function SidekicksGuideData:setDetailLayerGuideStep(_stepId)
    self._detailLayerGuideStep = _stepId
end
function SidekicksGuideData:getDetailLayerGuideStep()
    return self._detailLayerGuideStep or 99
end
function SidekicksGuideData:setEnterDetailLayer()
    self._bEnterDetailLayer = true
end
function SidekicksGuideData:checkEnterDetailLayer()
    return self._bEnterDetailLayer
end

function SidekicksGuideData:getStepInfo(_guideType, _stepId)
    if _guideType == "MainLayer" then
        return mainLayerGuideInfo[_stepId]
    elseif _guideType == "DetailLayer" then
        return detailLayerGuideInfo[_stepId]
    end
end

function SidekicksGuideData:getSaveGuideData()
    return {
        mainLayerGuideStep = self:getMainLayerGuideStep(),
        detailLayerGuideStep = self:getDetailLayerGuideStep(),
        bEnterDetailLayer = self:checkEnterDetailLayer()
    }
end

return SidekicksGuideData