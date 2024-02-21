--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-14 10:21:54
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-14 16:46:14
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/common/SidekicksSpineUI.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SidekicksSpineUI = class("SidekicksSpineUI", BaseView)

local PET_NAME = {
    "dog",
    "cat"
}

function SidekicksSpineUI:initDatas(_petId, _seasonIdx)
    SidekicksSpineUI.super.initDatas(self)

    self._touchTime = 0
    self._touchCount = 0
    self._petId = _petId
    self._seasonIdx = _seasonIdx
    local data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    if data then
        self._petInfo = data:getPetInfoById(self._petId)
    end
end

function SidekicksSpineUI:initSpineUI()
    if not self._petInfo then
        return
    end
    local path = self._petInfo:getSpineMainPath()
    if not util_IsFileExist(path..".atlas") then
        return
    end
    
    local spine = util_spineCreate(path, true, true)
    self:addChild(spine)
    self._spine = spine
    self:playIdle()

    local layout = util_makeTouch(self, "btn_touch")
	if DEBUG == 2 and device.platform == "mac" then
		layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
		layout:setBackGroundColor( cc.c4b(192, 192, 192 ) );
		layout:setBackGroundColorOpacity( 80 )
	end

    local rect = SidekicksConfig.PET_CLICK_RECT[self._petId]
    layout:setContentSize(cc.size(rect.width, rect.height))
    layout:setPosition(rect.x, rect.y)
	layout:addTo(self)
    self:addClick(layout)
    self._bCanTouch = true
    self:initSpineTouchEfUI()
end

function SidekicksSpineUI:initSpineTouchEfUI()
    if not self._petInfo then
        return
    end
    local path = "Sidekicks_Common/spine/Sidekicks_heart"
    if not util_IsFileExist(path..".atlas") then
        return
    end

    local spine = util_spineCreate(path, true, true)
    self:addChild(spine)
    self._spineTouch = spine
    self._spineTouch:setVisible(false)
    end

function SidekicksSpineUI:playIdle(_idx)
    if not self._spine then
        return
    end
    self._idleIdx = _idx and _idx or util_random(1, 3)
    if G_GetMgr(G_REF.Sidekicks):isExitGudieLayer(self._seasonIdx) then
        -- 引导过程中 只能播idle1
        self._idleIdx = 1
    end
    local actName = "idle" .. self._idleIdx
    util_spinePlay(self._spine, actName)
    util_spineEndCallFunc(self._spine, actName, util_node_handler(self, self.playIdle))
end

function SidekicksSpineUI:playIdle1()
    if not self._spine then
        return
    end

    self:playIdle(1)
end

function SidekicksSpineUI:playTouch(_idx)
    if not self._spine then
        return
    end

    self._touchIdx = _idx and _idx or util_random(1, 4)
    local actName = "dianji" .. self._touchIdx
    util_spinePlay(self._spine, actName)
    util_spineEndCallFunc(self._spine, actName, function()
        self:playIdle()
    end)

    if self._touchIdx == 5 then
        performWithDelay(self, function()
            self._bCanTouch = true
        end, 4)
    else
        self._bCanTouch = true
    end

    if self._touchSound then
        gLobalSoundManager:stopAudio(self._touchSound)
        self._touchSound = nil
    end
    local sound = string.format("Sidekicks_%s/sound/Sidekicks_%sTouch%s.mp3", self._seasonIdx, PET_NAME[self._petId], self._touchIdx)
    self._touchSound = gLobalSoundManager:playSound(sound)
end

function SidekicksSpineUI:playTouchEf(_posW)
    if not self._spineTouch then
        return
    end

    local posL = self:convertToNodeSpace(_posW)
    self._spineTouch:move(posL)
    self._spineTouch:setVisible(true)
    util_spinePlay(self._spineTouch, "start")
    util_spineEndCallFunc(self._spineTouch,  "start", function()
        self._spineTouch:setVisible(false)
    end)
end

function SidekicksSpineUI:clickFunc(_sender)
    if not self._bCanTouch then
        return
    end

    self._bCanTouch = false
    local name = _sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    local curTime = globalData.userRunData.p_serverTime
    if self._touchTime == 0 or (curTime - self._touchTime) < 500 then
        self._touchTime = curTime
        self._touchCount = self._touchCount + 1
    else
        self._touchTime = 0
        self._touchCount = 0
    end

    if self._touchCount >= 10 then
        self._touchCount = 0
        self:playTouch(5)
    else
        self:playTouch()
    end

    local posW = _sender:getTouchEndPosition()
    self:playTouchEf(posW)

    -- 7日任务入口
    if G_GetMgr(ACTIVITY_REF.PetMission) then
        local missionData = G_GetMgr(ACTIVITY_REF.PetMission):getRunningData()
        if missionData then
            G_GetMgr(ACTIVITY_REF.PetMission):sendPetInteraction()
        end
    end 
end

-- 宠物升级播 升级动画
function SidekicksSpineUI:playFeedOkAct()
    if not self._spine then
        return
    end

    local sound = string.format("Sidekicks_%s/sound/Sidekicks_petUp.mp3", self._seasonIdx)
    gLobalSoundManager:playSound(sound)

    self._bCanTouch = false
    util_spinePlay(self._spine, "shengji")
    util_spineEndCallFunc(self._spine, "shengji", function()
        self:playIdle(1)
    end)
    performWithDelay(self, function()
        self._bCanTouch = true
    end, 0.5)
end

return SidekicksSpineUI