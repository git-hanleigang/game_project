---
--xcyy
--2018年5月23日
--PalaceWishMapMainView.lua

local PalaceWishMapMainView = class("PalaceWishMapMainView", util_require("Levels.BaseLevelDialog"))

PalaceWishMapMainView.townIndexList = {1, 6, 12, 19}

PalaceWishMapMainView.m_maxIndex = 20

PalaceWishMapMainView.m_click = false

local BTN_TAG_CLOSE = 1001

function PalaceWishMapMainView:ctor()
    PalaceWishMapMainView.super.ctor(self)
    
end

function PalaceWishMapMainView:initUI()
    PalaceWishMapMainView.super.initUI(self)
    self:createCsbNode("PalaceWish/PalaceWish_MiniGame.csb")

    self:showMap(true)

    self.m_maxIndex = 20
    self:initLittleUINode()

    -- self:findChild("Panel_1"):setTag(BTN_TAG_CLOSE)
    -- self:addClick(self:findChild("Panel_1"))

    self.m_tipaCat = cc.Node:create()
    self:findChild("map_dian"):addChild(self.m_tipaCat, 1000)
    self.m_tipaCatSpine = util_spineCreate("Socre_PalaceWish_Wild", true, true)
    self.m_tipaCat:addChild(self.m_tipaCatSpine)
    self:playIdle(  )
    self.m_tipaCat:setVisible(false)


    
    local buttonBack = util_createAnimation("PalaceWish_mapanniu.csb")
    self:findChild("Node_anniu"):addChild(buttonBack)
    self:addClick(buttonBack:findChild("Button_1"))
end

function PalaceWishMapMainView:showMap(isInit)
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
    if not isInit then
        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_map_start.mp3")
    end
    
end

function PalaceWishMapMainView:BonusTriggerShowMap()
    self:setVisible(true)
end

function PalaceWishMapMainView:runLittleUINodeAct(nodePos, bonusMap, func)
    for i = 1, #bonusMap do
        local uiIndex = i - 1

        local mapId = bonusMap[nodePos]
        if i == nodePos then
            if mapId == 0 then
                gLobalSoundManager:playSound("PalaceWishSounds/music_PalaceWish_Map_dian.mp3")
            else
                gLobalSoundManager:playSound("PalaceWishSounds/music_PalaceWish_Map_YanHua.mp3")
            end
            --触发
            self["m_point_" .. uiIndex]:runTrigger(
                function()
                    if func then
                        func()
                    end
                end
            )
        end
    end
end
function PalaceWishMapMainView:updateRunLittleUINodeAct(nodePos, bonusMap)
    for i = 1, #bonusMap do
        local uiIndex = i - 1
        local mapId = bonusMap[i]
        self["m_point_" .. uiIndex]:runIdle("lock")
        if i < nodePos then
            self["m_point_" .. uiIndex]:runIdle("unlock")
        end
    end
end

function PalaceWishMapMainView:updateLittleUINodeAct(nodePos, bonusMap, isrunAct)
    for i = 1, #bonusMap do
        local uiIndex = i - 1
        local mapId = bonusMap[i]
        self["m_point_" .. uiIndex]:runIdle("lock")
        if i <= nodePos then
            self["m_point_" .. uiIndex]:runIdle("unlock")

            if not isrunAct then
                if i == nodePos then
                    -- if mapId == 0 then
                        self.m_tipaCat:setVisible(true)
                        local pos = cc.p(self["m_point_" .. uiIndex]:getParent():getPosition())
                        self.m_tipaCat:setPosition(pos)
                    -- end
                end
            end
        end
    end
end

function PalaceWishMapMainView:getMiniCsbName(index)
    local name = nil

    if index == self.townIndexList[1] then
        name = "PalaceWish_MiniGame_tower1"
    elseif index == self.townIndexList[2] then
        name = "PalaceWish_MiniGame_tower2"
    elseif index == self.townIndexList[3] then
        name = "PalaceWish_MiniGame_tower3"
    elseif index == self.townIndexList[4] then
        name = "PalaceWish_MiniGame_tower4"
    else
        name = "PalaceWish_MiniGame_dian"
    end

    return name
end

function PalaceWishMapMainView:initLittleUINode()
    for i = 1, self.m_maxIndex do
        local uiIndex = i - 1
        local csbName = self:getMiniCsbName(uiIndex)
        local fatherNodeName = "dian" .. uiIndex

        self["m_point_" .. uiIndex] = util_createView("PalaceWishSrc.PalaceWishMap.PalaceWishMapNodeView", csbName, uiIndex)
        self:findChild(fatherNodeName):addChild(self["m_point_" .. uiIndex])
    end
end
function PalaceWishMapMainView:onShowedCallFunc()
    self.m_click = false
    self:runCsbAction("idle", true)
end

function PalaceWishMapMainView:BonusTriggercloseUi(func)
    util_setCascadeOpacityEnabledRescursion(self, true)
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_map_over.mp3")
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

function PalaceWishMapMainView:closeUI(func)
    util_setCascadeOpacityEnabledRescursion(self, true)
    gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_map_over.mp3")
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
function PalaceWishMapMainView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_click then
        return
    end

    self.m_click = true

    -- if tag == BTN_TAG_CLOSE then
    --     self:closeUI()
    -- end

    if name == "Button_1" then
        self:closeUI()
    end
end

function PalaceWishMapMainView:catJump(pos, func)
    
    util_spinePlay(self.m_tipaCatSpine, "actionframe_ditu", false)
    local spineEndCallFunc = function()
        self:playIdle(  )
        if func then
            func()
        end
    end
    util_spineEndCallFunc(self.m_tipaCatSpine, "actionframe_ditu", spineEndCallFunc)


    performWithDelay(self, function (  )
        local time = 10/30
        local actionList = {}
        actionList[#actionList + 1] = cc.MoveTo:create(time, pos)
        actionList[#actionList + 1] =
            cc.CallFunc:create(
            function()
                
            end
        )
        local sq = cc.Sequence:create(actionList)
        self.m_tipaCat:runAction(sq)

        gLobalSoundManager:playSound("PalaceWishSounds/sound_PalaceWish_map_role_jump.mp3")
    end, 5/30) --5帧开始移动 15帧移动完

end

function PalaceWishMapMainView:beginLittleUiCatAct(nodePos, func)
    self.m_tipaCat:setVisible(true)
    local pos = cc.p(self["m_point_" .. (nodePos - 2)]:getParent():getPosition())
    self.m_tipaCat:setPosition(pos)

    local endPos = cc.p(self["m_point_" .. nodePos - 1]:getParent():getPosition())
    -- self.m_tipaCat:playAction("animation0")
    self:catJump(
        endPos,
        function()
            if func then
                func()
            end
        end
    )
end

--箭头idle
function PalaceWishMapMainView:playIdle(  )
    util_spinePlay(self.m_tipaCatSpine, "idleframe_ditu", true)
end

function PalaceWishMapMainView:playStart(  )
    util_spinePlay(self.m_tipaCatSpine, "start_ditu", false)
    local spineEndCallFunc = function()
        self:playIdle(  )
    end
    util_spineEndCallFunc(self.m_tipaCatSpine, "start_ditu", spineEndCallFunc)
end

--设置是否可点击
function PalaceWishMapMainView:setCanClick(isCanClick)
    self.m_click = not isCanClick
end

return PalaceWishMapMainView
