---
--xcyy
--2018年5月23日
--PussMapMainView.lua

local PussMapMainView = class("PussMapMainView", util_require("Levels.BaseLevelDialog"))

PussMapMainView.townIndexList = {1, 6, 12, 19}

PussMapMainView.m_maxIndex = 20

PussMapMainView.m_click = false

function PussMapMainView:ctor()
    PussMapMainView.super.ctor(self)
    
end

function PussMapMainView:initUI()
    PussMapMainView.super.initUI(self)
    self:createCsbNode("Puss/Puss_MiniGame.csb")

    self:showMap()

    self.m_maxIndex = 20
    self:initLittleUINode()

    self:addClick(self:findChild("click"))

    self.m_tipaCat = util_createAnimation("Puss_zhizhen.csb")
    self:findChild("Node_1"):addChild(self.m_tipaCat, 1000)
    self.m_tipaCat:setVisible(false)
end

function PussMapMainView:showMap()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PAUSE_SLOTSMACHINE)

    self:setVisible(true)
    self.m_click = true
    self:runCsbAction(
        "start",
        false,
        function()
            self.m_click = false

            self:runCsbAction("idle", true)
        end
    )
end

function PussMapMainView:BonusTriggerShowMap()
    self:setVisible(true)
end

function PussMapMainView:runLittleUINodeAct(nodePos, bonusMap, func)
    for i = 1, #bonusMap do
        local uiIndex = i - 1

        local mapId = bonusMap[nodePos]
        if i == nodePos then
            if mapId == 0 then
                gLobalSoundManager:playSound("PussSounds/music_Puss_Map_dian.mp3")
            else
                gLobalSoundManager:playSound("PussSounds/music_Puss_Map_YanHua.mp3")
            end
            self["m_point_" .. uiIndex]:runCsbAction(
                "actionunlock",
                false,
                function()
                    if func then
                        func()
                    end
                end
            )
        end
    end
end
function PussMapMainView:updateRunLittleUINodeAct(nodePos, bonusMap)
    for i = 1, #bonusMap do
        local uiIndex = i - 1
        local mapId = bonusMap[i]
        self["m_point_" .. uiIndex]:runCsbAction("lock")
        if i < nodePos then
            self["m_point_" .. uiIndex]:runCsbAction("unlock")
        end
    end
end

function PussMapMainView:updateLittleUINodeAct(nodePos, bonusMap, isrunAct)
    for i = 1, #bonusMap do
        local uiIndex = i - 1
        local mapId = bonusMap[i]
        self["m_point_" .. uiIndex]:runCsbAction("lock")
        if i <= nodePos then
            self["m_point_" .. uiIndex]:runCsbAction("unlock")

            if not isrunAct then
                if i == nodePos then
                    if mapId == 0 then
                        self.m_tipaCat:setVisible(true)
                        local pos = cc.p(self["m_point_" .. uiIndex]:getParent():getPosition())
                        self.m_tipaCat:setPosition(pos)
                    end
                end
            end
        end
    end
end

function PussMapMainView:getMiniCsbName(index)
    local name = nil

    if index == self.townIndexList[1] then
        name = "Puss_MiniGame_tower1"
    elseif index == self.townIndexList[2] then
        name = "Puss_MiniGame_tower2"
    elseif index == self.townIndexList[3] then
        name = "Puss_MiniGame_tower3"
    elseif index == self.townIndexList[4] then
        name = "Puss_MiniGame_tower4"
    else
        name = "Puss_MiniGame_dian"
    end

    return name
end

function PussMapMainView:initLittleUINode()
    for i = 1, self.m_maxIndex do
        local uiIndex = i - 1
        local csbName = self:getMiniCsbName(uiIndex)
        local fatherNodeName = "dian" .. uiIndex

        self["m_point_" .. uiIndex] = util_createView("CodePussSrc.Map.PussKMapNodeView", csbName)
        self:findChild(fatherNodeName):addChild(self["m_point_" .. uiIndex])
    end
end
function PussMapMainView:onShowedCallFunc()
    self.m_click = false
    self:runCsbAction("idle", true)
end

function PussMapMainView:BonusTriggercloseUi(func)
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:runCsbAction(
        "over",
        false,
        function()
            self:setVisible(false)
            self.m_tipaCat:setVisible(false)
            if func then
                func()
            end
        end
    )
end

function PussMapMainView:closeUI(func)
    util_setCascadeOpacityEnabledRescursion(self, true)
    self:runCsbAction(
        "over",
        false,
        function()
            self:setVisible(false)
            self.m_tipaCat:setVisible(false)

            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_SLOTSMACHINE)

            if func then
                func()
            end
        end
    )
end

--默认按钮监听回调
function PussMapMainView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_click then
        return
    end

    self.m_click = true

    if name == "click" then
        self:closeUI()
    end
end

function PussMapMainView:catJump(pos, func)
    local time = 0.37
    local actionList = {}
    actionList[#actionList + 1] = cc.JumpTo:create(time, pos, 60, 1)
    actionList[#actionList + 1] =
        cc.CallFunc:create(
        function()
            if func then
                func()
            end
        end
    )
    local sq = cc.Sequence:create(actionList)
    self.m_tipaCat:runAction(sq)
end

function PussMapMainView:beginLittleUiCatAct(nodePos, func)
    self.m_tipaCat:setVisible(true)
    local pos = cc.p(self["m_point_" .. (nodePos - 2)]:getParent():getPosition())
    self.m_tipaCat:setPosition(pos)

    local endPos = cc.p(self["m_point_" .. nodePos - 1]:getParent():getPosition())
    self.m_tipaCat:playAction("animation0")
    self:catJump(
        endPos,
        function()
            if func then
                func()
            end
        end
    )
end

return PussMapMainView
