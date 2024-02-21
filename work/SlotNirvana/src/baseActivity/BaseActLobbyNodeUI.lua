--[[
Author: cxc
Date: 2021-06-04 12:10:42
LastEditTime: 2021-07-07 21:08:16
LastEditors: Please set LastEditors
Description: 大活动的基类
FilePath: /SlotNirvana/src/baseActivity/BaseActLobbyNodeUI.lua
--]]
local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local BaseActLobbyNodeUI = class("BaseActLobbyNodeUI", BaseLobbyNodeUI)

function BaseActLobbyNodeUI:initUI(data)
    BaseActLobbyNodeUI.super.initUI(self, data)

    if G_GetMgr(ACTIVITY_REF.Quest):checkQuestUlkLobbyBtmGuide() then
        G_GetMgr(ACTIVITY_REF.Quest):setLobbyBtmBigActUI(self)
    end
end

function BaseActLobbyNodeUI:initUnlockUI()
    if self.m_unlockValue then
        self.m_unlockValue:setVisible(false)
    end

    local lbUnlock = self:findChild("lb_unlock")
    if not lbUnlock then
        return
    end

    local defaultDesc = self:getDefaultUnlockDesc()
    local desc = self:getSysUnlockDesc(defaultDesc)
    lbUnlock:setString(desc)
    lbUnlock:setPositionX(0)
    util_scaleCoinLabGameLayerFromBgWidth(lbUnlock, 500)

    local lbSize = lbUnlock:getContentSize()
    local imgUnlockTipBg = self:findChild("imgView_tipBg")
    if imgUnlockTipBg then
        local height = imgUnlockTipBg:getContentSize().height
        imgUnlockTipBg:setContentSize(lbSize.width * lbUnlock:getScale() + 30, height)
    end
end

------------------------- 子类重写 -------------------------
-- 获取默认的解锁文本
function BaseActLobbyNodeUI:getDefaultUnlockDesc()
    return ""
end
------------------------- 子类重写 -------------------------

-- 获取 开启等级
function BaseActLobbyNodeUI:getSysOpenLv()
    local lv = globalData.constantData.ACTIVITY_OPEN_LEVEL
    local refName = self:getActRefName()
    if not refName then
        return lv
    end

    local actConfig = globalData.GameConfig:getActivityConfigByRef(refName)
    if actConfig and actConfig.p_openLevel then
        lv = actConfig.p_openLevel
    end

    -- 该玩家 本活动是否忽略等级
    local bIgnoreActLv = globalData.constantData:checkIsIgnoreActLevel()
    if bIgnoreActLv and self:getGameData() then
        return 1
    end

    return lv
end

-- 获取 未解锁 文本
function BaseActLobbyNodeUI:getSysUnlockDesc(_defaultDesc)
    local lv = self:getNewUserLv()
    if lv then
        return lv
    end
    _defaultDesc = _defaultDesc or ""
    local refName = self:getActRefName()
    if not refName or not globalData.GameConfig:checkUseNewNoviceFeatures() then
        return _defaultDesc
    end

    local questData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not questData or not questData:isNewUserQuest() then
        -- 玩家 新手quest 完成过期了 也会有数据)
        return _defaultDesc
    end

    local openLv = self:getSysOpenLv()
    if globalData.constantData.NOVICE_NEW_QUEST_OPEN then
        return "COMPLETE VEGAS QUEST OR REACH LV." .. openLv .. " TO UNLOCK"
    end
    
    return _defaultDesc
end

function BaseActLobbyNodeUI:stopTimerAction()
    BaseActLobbyNodeUI.super.stopTimerAction(self)
    if not tolua.isnull(self.m_timeBg) then
        self.m_timeBg:setVisible(false)
    end
    if not tolua.isnull(self.m_lock) then
        self.m_lock:setVisible(true) -- 锁定icon
    end
end

function BaseActLobbyNodeUI:getNewUserLv()
    if globalData.constantData.NoviceNewUserBlastSwitch and globalData.constantData.NoviceNewUserBlastSwitch == "1" and G_GetMgr(ACTIVITY_REF.Blast):getNewUserOver() and CardSysManager and CardSysManager:isNovice() then
        return "COMPLETE TORNADO ALBUM TO UNLOCK"
    end
    local lv = self:getSysOpenLv()
    if lv and tonumber(lv) > 10000 then
        return "FUN FEATURES ARE COMING SOON"
    end
end

-- 获取默认的宽高
function BaseActLobbyNodeUI:getContentSize()
    return cc.size(120, 120)
end

return BaseActLobbyNodeUI
