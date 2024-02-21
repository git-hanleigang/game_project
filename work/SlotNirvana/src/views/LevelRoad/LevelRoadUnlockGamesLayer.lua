--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-24 17:17:59
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-25 10:22:20
FilePath: /SlotNirvana/src/views/LevelRoad/LevelRoadUnlockGamesLayer.lua
Description: 解锁关卡弹板
--]]
local LevelRoadUnlockGamesLayer = class("LevelRoadUnlockGamesLayer", BaseLayer)

function LevelRoadUnlockGamesLayer:ctor()
    LevelRoadUnlockGamesLayer.super.ctor(self)

    self:setLandscapeCsbName("LevelRoad/csd/LevelRoad_NewGameUnlock.csb")
    self:setPortraitCsbName("LevelRoad/csd/Main_Portrait/LevelRoad_NewGameUnlock_Potrait.csb")
    self:setPauseSlotsEnabled(true) 
    self:setName("LevelRoadUnlockGamesLayer")
end

function LevelRoadUnlockGamesLayer:initDatas(_gameIdList)
    LevelRoadUnlockGamesLayer.super.initDatas(self)

    self._gameInfoList = {}
    for k, _slotId in ipairs(_gameIdList or {}) do
        local info = globalData.slotRunData:getLevelInfoById(_slotId)
        if info and info.p_levelName then
            table.insert(self._gameInfoList, info)
        end
    end
    table.sort(self._gameInfoList, function(a, b)
        return a.p_openLevel < b.p_openLevel
    end)
end

function LevelRoadUnlockGamesLayer:initView()
    -- 挑战 按钮文本
    self:setButtonLabelContent("btn_ok", "GET IT!")

    -- 关卡图标 多关卡 换行排列
    local parent = self:findChild("node_slotIcon")
    local colShowNum = self:isShownAsPortrait() and 3 or 6
    local count = table.nums(self._gameInfoList)
    local row = math.ceil(count / colShowNum)
    local cellH = 260
    local totalH = (row * cellH)
    local limitH = self:isShownAsPortrait() and 300 or 300
    local scale = math.min(1, limitH / totalH)
    for i=0, row-1 do
        local rowList = {}
        for j=1, colShowNum do
            local slotInfo = self._gameInfoList[i*colShowNum + j]
            local spIcon = self:createSlotIcon(slotInfo)
            if spIcon then
                spIcon:setAnchorPoint(0.5, 0.5)
                parent:addChild(spIcon)
                table.insert(rowList, {node = spIcon, alignY = i * -cellH + (totalH - cellH) * 0.5 })
            end
        end
        util_alignCenter(rowList, 0)
    end
    parent:setScale(scale)
    
    self:runCsbAction("idle", true)
end

function LevelRoadUnlockGamesLayer:createSlotIcon(_slotInfo)
    if _slotInfo and _slotInfo.p_levelName then
        local slotIconPath = globalData.GameConfig:getLevelIconPath(_slotInfo.p_levelName, LEVEL_ICON_TYPE.SMALL)
        local spSlotIcon = util_createSprite("newIcons/Order/cashlink_Small_loading.png")
        util_changeTexture(spSlotIcon, slotIconPath)
        return spSlotIcon
    end
end

function LevelRoadUnlockGamesLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        self:closeUI()
    elseif name == "btn_ok" then
        local cb = function()
            local gameInfo = self._gameInfoList[1]
            if gameInfo and gameInfo.p_id then
                G_GetMgr(G_REF.LevelRoad):jumpLoobyUnlockGames(gameInfo.p_id)
            end 
        end
        self:closeUI(cb)
    end
end

return LevelRoadUnlockGamesLayer