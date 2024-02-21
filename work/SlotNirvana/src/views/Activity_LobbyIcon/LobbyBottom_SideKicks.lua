--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-14 10:20:25
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-14 14:07:13
FilePath: /SlotNirvana/src/views/Activity_LobbyIcon/LobbyBottom_SideKicks.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
-- 宠物系统
local BaseLobbyNodeUI = util_require("baseActivity.BaseLobbyNodeUI")
local LobbyBottom_SideKicks = class("LobbyBottom_SideKicks", BaseLobbyNodeUI)

function LobbyBottom_SideKicks:getCsbName()
    return "Activity_LobbyIconRes/LobbyBottom_SidekicksNode.csb"
end

function LobbyBottom_SideKicks:initUI(data)
    LobbyBottom_SideKicks.super.initUI(self)

    if not self.m_LockState then
        local bRunning = G_GetMgr(G_REF.Sidekicks):isRunning()
        if not bRunning then
            self:showCommingSoon()
        end
    end
end

-- 倒计时
function LobbyBottom_SideKicks:updateLeftTime()
    local data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    if not data then
        self.m_timeBg:setVisible(false)
        return
    end

    self:updateRedPointNum(data)
    self.m_lock:setVisible(false)
    self.m_timeBg:setVisible(false) -- 不显示时间
    self.m_commingSoon = false
    if not self._stdCfg then
        self._stdCfg = data:getStdCfg()
        self._newSeasonInfo = self._stdCfg:getSeasonStageInfo(self._stdCfg:getNewSeasonIdx())
    end
    if not self._newSeasonInfo then
        self.m_timeBg:setVisible(false)
        self:stopTimerAction()
        return
    end

    local seasonEndTime = self._newSeasonInfo:getSeasonEndTime()
    local strLeftTime, bOver = util_daysdemaining(seasonEndTime * 0.001, true)
    if bOver then
        self.m_timeBg:setVisible(false)
        self:checkNextSeasonOpen()
    end
    -- self.m_djsLabel:setString(strLeftTime) -- 不显示时间
end
function LobbyBottom_SideKicks:checkNextSeasonOpen()
    local preSeasonIdx = self._newSeasonInfo:getSeasonIdx()
    local curSeasonIdx = self._stdCfg:getNewSeasonIdx(true)
    if curSeasonIdx > preSeasonIdx then
        G_GetMgr(G_REF.Sidekicks):downloadSeasonRes(curSeasonIdx)
        self._newSeasonInfo = self._stdCfg:getSeasonStageInfo(curSeasonIdx)
        return true
    end
    self:stopTimerAction()
    return false
end

function LobbyBottom_SideKicks:updateRedPointNum(_data)
    local num = 0
    local gameData = G_GetMgr(G_REF.Sidekicks):getRunningData()
    if gameData then
        local petsList = gameData:getTotalPetsList()
        local stdCfg = gameData:getStdCfg()
        local seasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
        local curSeasonStageIdx = stdCfg:getCurSeasonStageIdx(seasonIdx)
        for k,v in pairs(petsList) do
            if self:canLevelUp(v, _data, curSeasonStageIdx) or self:canStarUp(v, _data, curSeasonStageIdx) then
                num = num + 1
            end
        end
    end
    self.m_spRedPoint:setVisible(num > 0)
    self.m_labelActivityNums:setString(num)
end

function LobbyBottom_SideKicks:canLevelUp(_petInfo, _data, _stageIdx)
    local bCanLevelUp = _petInfo:checkCanLevelUp()

    local level = _petInfo:getLevel()
    local levelMax = _petInfo:getLevelMax()
    local stage = _petInfo:getCurLevelAndStarStage()
    local levelCount = _data:getLvUpItemCount()

    if level >= levelMax or levelCount <= 0 or stage > _stageIdx then
        bCanLevelUp = false
    end

    return bCanLevelUp
end

function LobbyBottom_SideKicks:canStarUp(_petInfo, _data, _stageIdx)
    local bCanStarUp = _petInfo:checkCanStarUp()

    local Star = _petInfo:getStar()
    local StarMax = _petInfo:getStarMax()
    local stage = _petInfo:getCurLevelAndStarStage()
    local nextStarExp = _petInfo:getStarUpNeedExp()
    local starCount = _data:getStarUpItemCount()

    if Star >= StarMax or starCount < nextStarExp or stage > _stageIdx then
        bCanStarUp = false
    end

    return bCanStarUp
end

function LobbyBottom_SideKicks:clickLobbyNode(sender)
    -- 等级不够
    if self.m_LockState then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_msg)
        return
    end

    -- 未开 没数据
    if not G_GetMgr(G_REF.Sidekicks):isRunning() then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tips_commingsoon_msg)
        return
    end

    -- 没下载完呢
    if not tolua.isnull(self.downLoadProcess) then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:showTips(self.m_tipsNode_downloading)
        return
    end

    local selectSeasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
    G_GetMgr(G_REF.Sidekicks):showMainLayer(selectSeasonIdx)
end

function LobbyBottom_SideKicks:getSysOpenLv()
    return globalData.constantData.SIDE_KICKS_OPEN_LEVEL or 60
end

function LobbyBottom_SideKicks:getDownLoadingNode()
    return self:findChild("downLoadNode")
end

function LobbyBottom_SideKicks:getBottomName()
    return "SIDEKICKS"
end

function LobbyBottom_SideKicks:getDownLoadKey()
    return G_GetMgr(G_REF.Sidekicks):getSeletSeasonIdxDLResName()
end

function LobbyBottom_SideKicks:getProgressPath()
    return "Activity_LobbyIconRes/ui/sidekicks_1.png"
end

function LobbyBottom_SideKicks:getProcessBgOffset()
    return 0, 0
end

return LobbyBottom_SideKicks
