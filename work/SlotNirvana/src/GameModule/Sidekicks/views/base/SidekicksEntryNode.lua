--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2024-01-19 11:40:28
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2024-01-19 11:41:15
FilePath: /SlotNirvana/src/GameModule/Sidekicks/views/base/SidekicksEntryNode.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksEntryNode = class("SidekicksEntryNode", BaseView)
local TrillionChallengeConfig = util_require("GameModule.TrillionChallenge.config.TrillionChallengeConfig")

function SidekicksEntryNode:getCsbName()
    local seasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
    return string.format("Sidekicks_%s/csd/EntryNode.csb", seasonIdx)
end

function SidekicksEntryNode:initCsbNodes()
    self._size = self:findChild("Node_PanelSize"):getContentSize()
    self._spRedPoint = self:findChild("sp_num_close_bg")
    self._labelActivityNums = self:findChild("lb_num_close")
end

function SidekicksEntryNode:initUI()
    SidekicksEntryNode.super.initUI(self)
    self._data = G_GetMgr(G_REF.Sidekicks):getRunningData()

    -- 倒计时
    schedule(self, util_node_handler(self, self.updateRedDotUI), 1)
    self:updateRedDotUI()

    self:runCsbAction("idle")
end

-- 小红点
function SidekicksEntryNode:updateRedDotUI()
    local num = 0
    local gameData = G_GetMgr(G_REF.Sidekicks):getRunningData()
    if gameData then
        local petsList = gameData:getTotalPetsList()
        local stdCfg = gameData:getStdCfg()
        local seasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
        local curSeasonStageIdx = stdCfg:getCurSeasonStageIdx(seasonIdx)
        for k,v in pairs(petsList) do
            if self:canLevelUp(v, gameData, curSeasonStageIdx) or self:canStarUp(v, gameData, curSeasonStageIdx) then
                num = num + 1
            end
        end
    end
    self._spRedPoint:setVisible(num > 0)
    self._labelActivityNums:setString(num)
    util_scaleCoinLabGameLayerFromBgWidth(self._labelActivityNums, 30, 1)
end
function SidekicksEntryNode:canLevelUp(_petInfo, _data, _stageIdx)
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
function SidekicksEntryNode:canStarUp(_petInfo, _data, _stageIdx)
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

function SidekicksEntryNode:getPanelSize()
    return {widht = self._size.width, height = self._size.height}
end

function SidekicksEntryNode:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_open" then
        local selectSeasonIdx = G_GetMgr(G_REF.Sidekicks):getSelectSeasonIdx()
        G_GetMgr(G_REF.Sidekicks):showMainLayer(selectSeasonIdx)
    end
end

-- 监测 有小红点或者活动进度满了
function SidekicksEntryNode:checkHadRedOrProgMax()
    local bHadRed = false -- 有没有小红点
    if self._spRedPoint then
        bHadRed = self._spRedPoint:isVisible()
    end
    local bProgMax = false -- 进度条是否满了 （预留一下万一后边加个需求没小红点的进度满了）
    return {bHadRed, bProgMax}
end

return SidekicksEntryNode