--[[
    分类信息
    author:{author}
    time:2022-01-30 15:59:56
]]
GD.RecmdGroup = {
    NewGame = "NewGame",
    Hottest = "Hottest",
    -- Favourite = "Favourite",
    Lately = "Lately",
    -- Guess = "Guess",
    Theme = "Theme",
    SlotFrame = "Frame",
    Jackpot = "Jackpot",
    Link = "Link",
    Retro = "Retro",
    Collect = "Collect",
    Magic = "Magic",
    NewSlots = "NewSlots"
}

local tbCsb = {
    NewGame = "newIcons/LevelRecmd2023/2023LevelFolder_TheNewGame.csb",
    Hottest = "newIcons/LevelRecmd2023/2023LevelFolder_TheHottest.csb",
    -- Favourite = "newIcons/LevelRecmd2023/2023LevelFolder_TheHottest.csb",
    Lately = "newIcons/LevelRecmd2023/2023LevelFolder_LatelyPlay.csb",
    -- Guess = "newIcons/LevelRecmd2023/2023LevelFolder_LatelyPlay.csb",
    Theme = "newIcons/LevelRecmd2023/Themes/2023LevelFolder_SpinItem.csb"
}

-- 按照组的解锁等级解锁
local UnlockGroup = {
    RecmdGroup.Hottest,
    RecmdGroup.NewGame,
    RecmdGroup.Theme,
    RecmdGroup.Jackpot,
    RecmdGroup.Link,
    RecmdGroup.Retro,
    RecmdGroup.Collect,
    RecmdGroup.Magic
}

local LevelRecmdInfo = class("LevelRecmdInfo")

function LevelRecmdInfo:ctor()
    self.m_group = ""
    self.m_recmdName = ""
    self.m_levelNames = {}
    self.m_slotModInfo = {}
    self.m_resource = ""
    self.m_order = 0
    self.m_type = 1
    self.m_startStamp = 0
    self.m_endStamp = 0

    self.m_isShowed = false
    self.m_titleType = nil
    self.m_titleRes = ""
    self.m_bindRef = nil
    self.m_isSlotMod = false
end

function LevelRecmdInfo:parseData(_info, _levelIgnoreList)
    local levelIgnoreList = _levelIgnoreList or {}
    self.m_group = _info.group
    self.m_recmdName = _info.groupName
    self.m_bindRef = _info.activityName
    self.m_levelNames = {}
    self.m_slotModInfo = {}
    for j = 1, #_info.games do
        local gameArr = string.split(_info.games[j], "|")
        if #gameArr <= 1 then
            self.m_isSlotMod = false
            if not levelIgnoreList[_info.games[j]] then
                table.insert(self.m_levelNames, _info.games[j])
                table.insert(self.m_slotModInfo, {game = _info.games[j]})
            end
        else
            self.m_isSlotMod = true
            if not levelIgnoreList[_info.games[j]] then
                table.insert(self.m_levelNames, gameArr[1])
                table.insert(self.m_slotModInfo, {game = gameArr[1], mod = tonumber(gameArr[2])})
            end
        end
    end
    self.m_resource = _info.resource
    self.m_order = tonumber(_info.order)
    self.m_type = _info.type
    self.m_startStamp = tonumber(_info.startTime) or 0
    self.m_endStamp = tonumber(_info.endTime) or 0

    self:setTitleType()
    self:setTitleRes()
end

function LevelRecmdInfo:getOrder()
    return self.m_order
end

function LevelRecmdInfo:getRecmdName()
    return self.m_recmdName
end

function LevelRecmdInfo:getGroup()
    return self.m_group
end

function LevelRecmdInfo:getLevelNames()
    return self.m_levelNames or {}
end

-- {game = "xx", mod = 0/1}
function LevelRecmdInfo:getSlotModInfo()
    return self.m_slotModInfo or {}
end

function LevelRecmdInfo:setShowState(isShow)
    self.m_isShowed = isShow
end

function LevelRecmdInfo:isShowed()
    return self.m_isShowed
end

function LevelRecmdInfo:getTitleType()
    return self.m_titleType
end

function LevelRecmdInfo:getBindRef()
    return self.m_bindRef or ""
end

-- 关卡模组
function LevelRecmdInfo:getIsSlotMod()
    return self.m_isSlotMod
end

function LevelRecmdInfo:getContentLen()
    if self.m_group == RecmdGroup.Jackpot then
        return 800 / 2
    elseif self.m_group == RecmdGroup.Link then
        return 690 / 2
    elseif self.m_group == RecmdGroup.Retro then
        return 1021 / 2
    elseif self.m_group == RecmdGroup.Collect then
        return 696 / 2
    elseif self.m_group == RecmdGroup.Magic then
        return 1026 / 2
    elseif self.m_group == RecmdGroup.NewSlots then
        return 663 / 2
    end
    return 200
end

function LevelRecmdInfo:getOffsetPosX()
    return self:getContentLen()
end

function LevelRecmdInfo:setTitleType()
    if self.m_group == RecmdGroup.Jackpot then
        self.m_titleType = "Jackpot"
        -- 兼容老配置
        if self.m_bindRef == nil then
            if self.m_recmdName == "Jillion" then
                self.m_bindRef = ACTIVITY_REF.CommonJackpot
            elseif self.m_recmdName == "Flamingo" then
                self.m_bindRef = ACTIVITY_REF.FlamingoJackpot
            end
        end
    elseif self.m_group == RecmdGroup.Theme then
        if self.m_recmdName == "SpinItem" then
            self.m_bindRef = ACTIVITY_REF.SpinItem
        end
    end
end

function LevelRecmdInfo:getJackpotTitleLuaName()
    local name =  "LevelRecmd" .. self.m_recmdName .. "JackpotNode"
    return name
end

function LevelRecmdInfo:getTitleRes()
    return self.m_titleRes
end

function LevelRecmdInfo:setTitleRes(_res)
    if self:getTitleType() == nil then
        return
    end
    if _res and _res ~= "" then
        self.m_titleRes = _res
    else
        local csb = self:getCsb()
        if csb and csb ~= "" then
            self.m_titleRes = string.sub(csb, 1, -5) .. "Title.csb"
        end
    end
end

function LevelRecmdInfo:getCsb()
    if not self.m_resource or self.m_resource == "" then
        local _group = self.m_group or ""
        return tbCsb[_group]
    else
        return self.m_resource
    end
end

function LevelRecmdInfo:isUnlockGroup()
    for i = 1, #UnlockGroup do
        if self.m_group == UnlockGroup[i] then
            return true
        end
    end
    return false
end

-- 是否可显示
function LevelRecmdInfo:isCanShow()
    local _csb = self:getCsb()
    if not _csb then
        return false
    end

    if not util_IsFileExist(_csb) then
        return false
    end

    if globalData.userRunData.levelNum < globalData.constantData.NoviceGameGroupOpenLevel then
        return false
    end

    if #(self.m_levelNames or {}) == 0 and self.m_group ~= RecmdGroup.NewGame then
        -- 不存在关卡数据不显示
        return false
    end

    if not self:isExpire() then
        return false
    end

    if self.m_group ~= RecmdGroup.Hottest and self.m_group ~= RecmdGroup.NewGame and globalData.constantData.NoviceGameGroupOtherOpenLevel > globalData.userRunData.levelNum then
        return false
    else
        return true
    end
end

function LevelRecmdInfo:isExpire()
    -- 判断时间
    local serverTimeStamp = globalData.userRunData.p_serverTime
    if self.m_type == 2 then
        if serverTimeStamp < self.m_startStamp or serverTimeStamp > self.m_endStamp then
            return false
        end
    end
    return true
end

return LevelRecmdInfo
