--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-12-15 20:38:01
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-12-18 16:12:39
FilePath: /SlotNirvana/src/GameModule/Sidekicks/controller/SidekicksManager.lua
Description: 这是默认设置,请设置`customMade`, 打开koroFileHeader查看配置 进行设置: https://github.com/OBKoro1/koro1FileHeader/wiki/%E9%85%8D%E7%BD%AE
--]]
local SidekicksManager = class("SidekicksManager", BaseGameControl)
local SidekicksConfig = util_require("GameModule.Sidekicks.config.SidekicksConfig")
local SidekicksNet = util_require("GameModule.Sidekicks.net.SidekicksNet")
local SidekicksGuideData = util_require("src.GameModule.Sidekicks.model.SidekicksGuideData")

function SidekicksManager:ctor()
    SidekicksManager.super.ctor(self)
    self:setRefName(G_REF.Sidekicks)

    self.m_net = SidekicksNet:getInstance()
    self.m_guideData = SidekicksGuideData:create()

    -- 玩家所选赛季
    self._selectSeasonIdx = gLobalDataManager:getNumberByField("SidekicksSelSeasonIdx", SidekicksConfig.NewSeasonIdx)
    self:setDataModule("GameModule.Sidekicks.model.SidekicksData")
    self:addExtendResList("Sidekicks_Season_Common")
end

-- 玩家所选赛季
function SidekicksManager:setSelectSeasonIdx(_selSeasonIdx)
    self._selectSeasonIdx = _selSeasonIdx or SidekicksConfig.NewSeasonIdx
    gLobalDataManager:setNumberByField("SidekicksSelSeasonIdx", self._selectSeasonIdx)
end
function SidekicksManager:getSelectSeasonIdx()
    if self._selectSeasonIdx <= 0 then
        -- 未主动选择赛季 使用最新赛季
        self._selectSeasonIdx = SidekicksConfig.NewSeasonIdx
    end
    return self._selectSeasonIdx
end

-- 引导数据
function SidekicksManager:parseGuideData(_data)
    self.m_guideData:parseData(_data)
end
function SidekicksManager:getGuideData()
    return self.m_guideData
end

-- 宠物系统 左边条节点
function SidekicksManager:createEntryNode()
    if not self:isCanShowLayer() then
        return
    end

    local node = util_createView("GameModule.Sidekicks.views.base.SidekicksEntryNode")
    return node
end

-- 显示 宠物系统引导界面
function SidekicksManager:showGuideLayer(_seasonIdx, _guideType, _stepInfo, _params)
    _seasonIdx = _seasonIdx or self:getSelectSeasonIdx()
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    local layerName = string.format("SidekickGuideLayer_%s_%d",_guideType, _seasonIdx)
    local view = gLobalViewManager:getViewByName(layerName)
    if view then
        view:updateStepInfo(_stepInfo)
        return
    end

    local path = string.format("Sidekicks_Season_%s.GameMain.%s", _seasonIdx, layerName)
    view = util_createView(path, _seasonIdx, _params)
    if view then
        view:setName(layerName)
        self:showLayer(view, ViewZorder.ZORDER_UI)
        view:updateStepInfo(_stepInfo)
    end
    return view
end
function SidekicksManager:checkCloseGuideLayer(_seasonIdx, _guideType)
    _seasonIdx = _seasonIdx or self:getSelectSeasonIdx()
    local layerName = string.format("SidekickGuideLayer_%s_%d",_guideType, _seasonIdx)
    local view = gLobalViewManager:getViewByName(layerName)
    if not view then
        return
    end
    
    view:closeUI()
end
function SidekicksManager:isExitGudieLayer(_seasonIdx)
    _seasonIdx = _seasonIdx or self:getSelectSeasonIdx()
    local layerName_m = string.format("SidekickGuideLayer_%s_%d","MainLayer", _seasonIdx)
    local view_m = gLobalViewManager:getViewByName(layerName_m)
    local layerName_d = string.format("SidekickGuideLayer_%s_%d","DetailLayer", _seasonIdx)
    local view_d = gLobalViewManager:getViewByName(layerName_d)
    return view_m or view_d
end

-- 显示 宠物系统主界面
function SidekicksManager:showMainLayer(_seasonIdx)
    _seasonIdx = _seasonIdx or self:getSelectSeasonIdx()
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    local layerName = string.format("SidekicksMainLayer_%d", _seasonIdx)
    if gLobalViewManager:getViewByName(layerName) then
        return
    end
    local path = string.format("Sidekicks_Season_%s.GameMain.%s", _seasonIdx, layerName)
    local view = util_createView(path, _seasonIdx)
    if view then
        view:setName(layerName)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 显示 过场 界面
function SidekicksManager:showInterludeLayer(_seasonIdx, _func, _id)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    if gLobalViewManager:getViewByExtendData("BaseSidekicksInterludeLayer") then
        return
    end

    local path = string.format("Sidekicks_Season_%s.GameMain.SidekicksInterludeLayer_%s", _seasonIdx, _seasonIdx)
    local view = util_createView(path, _seasonIdx, _func, _id)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_POPUI)
    end
    return view
end

-- 显示 改名 界面
function SidekicksManager:showSetNameLayer(_seasonIdx, _petInfo)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    if gLobalViewManager:getViewByExtendData("BaseSidekicksSetNameLayer") then
        return
    end

    local view = util_createView("GameModule.Sidekicks.views.base.BaseSidekicksSetNameLayer", _seasonIdx, _petInfo)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_POPUI)
    end
    return view
end

-- 显示 宠物系统 宠物 详情界面
function SidekicksManager:showPetDeailLayer(_seasonIdx, _petId)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    local layerName = string.format("SidekicksDetailLayer_%d", _seasonIdx)
    if gLobalViewManager:getViewByName(layerName) then
        return
    end
    local path = string.format("Sidekicks_Season_%s.GameMain.%s", _seasonIdx, layerName)
    local view = util_createView(path, _seasonIdx, _petId)
    if view then
        view:setName(layerName)
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function SidekicksManager:showRuleLayer(_seasonIdx, _pageIdx)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    if gLobalViewManager:getViewByName("SidekicksRuleLayer") then
        return
    end

    local luaPath = string.format("Sidekicks_Season_%s.GameMain.SidekicksRuleLayer_%d", _seasonIdx, _seasonIdx)
    local view = util_createView(luaPath, _seasonIdx, _pageIdx)
    if view then
        view:setName("SidekicksRuleLayer")
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 是否可显示主资源Layer界面
function SidekicksManager:isCanShowLayer(_seasonIdx)
    local data = self:getRunningData()
    if not data then
        return false
    end

    _seasonIdx = _seasonIdx or self:getSelectSeasonIdx()
    return self:isDownloadTheme("Sidekicks_Season_" .. _seasonIdx)
end

-- 显示 每日轮盘 主界面
function SidekicksManager:showWheelLayer(_seasonIdx)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    local data = self:getRunningData()
    local wheelData = data:getMiniGameData()
    if not wheelData or not wheelData:isCanPlay() then
        return
    end

    if gLobalViewManager:getViewByExtendData("MiniGameMainLayer") then
        return
    end
    
    local path = string.format("Sidekicks_Season_%s.MiniGame.MiniGameMainLayer", _seasonIdx)
    local view = util_createView(path, _seasonIdx)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 显示 每日轮盘奖励 界面
function SidekicksManager:showWheelReward(_seasonIdx, _data)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    if gLobalViewManager:getViewByExtendData("MiniGameRewardLayer") then
        return
    end
    
    local path = string.format("Sidekicks_Season_%s.MiniGame.MiniGameRewardLayer", _seasonIdx, _data)
    local view = util_createView(path, _seasonIdx, _data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 显示 荣誉 主界面
function SidekicksManager:showRankLayer(_seasonIdx)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    if gLobalViewManager:getViewByExtendData("SidekicksRankLayer") then
        return
    end
    
    local view = util_createView("GameModule.Sidekicks.views.rank.SidekicksRankLayer", _seasonIdx)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 显示 荣誉升级 界面
function SidekicksManager:showRankLevelUp(_seasonIdx)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    local data = self:getRunningData()
    local curLv = data:getHonorLv()
    if curLv <= self:getLastHonorLv() then
        return
    end

    if gLobalViewManager:getViewByExtendData("SidekicksRankLevelUp") then
        return
    end
    
    local view = util_createView("GameModule.Sidekicks.views.rank.SidekicksRankLevelUp", _seasonIdx)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 显示 荣誉购买奖励 界面
function SidekicksManager:showSaleReward(_seasonIdx, _data)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    if gLobalViewManager:getViewByExtendData("SidekicksRankReward") then
        return
    end
    
    local view = util_createView("GameModule.Sidekicks.views.rank.SidekicksRankReward", _seasonIdx, _data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 显示 升星奖励 界面
function SidekicksManager:showStarUpReward(_seasonIdx, _data)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end

    if gLobalViewManager:getViewByExtendData("SidekicksStarUpReward") then
        return
    end
    
    local view = util_createView("GameModule.Sidekicks.views.base.message.SidekicksStarUpReward", _seasonIdx, _data)
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 获取 下载列表
function SidekicksManager:getUserNeedDLZips(_dlPos, _resType)
    if _dlPos == 0 then
        --loading 期间不下载了
        return {}
    end

    local newSeasonIdx = SidekicksConfig.NewSeasonIdx
    local data = self:getRunningData()
    if data then
        newSeasonIdx = data:getNewSeasonIdx()
    end
    local dlZipList = {"Sidekicks_Season_Common"}
    if self._selectSeasonIdx > 0 then
        local resZipName = "Sidekicks_Season_" .. self._selectSeasonIdx
        local codeZipName = resZipName .. "_Code" 
        table.insert(dlZipList, resZipName)
        table.insert(dlZipList, codeZipName)
        if newSeasonIdx ~= self._selectSeasonIdx then
            resZipName = "Sidekicks_Season_" .. newSeasonIdx
            codeZipName = resZipName .. "_Code" 
            table.insert(dlZipList, resZipName)
            table.insert(dlZipList, codeZipName)
        end
    end

    return dlZipList
end
function SidekicksManager:getDlZips(_dlZips)
    _dlZips = _dlZips or {}

    local dlZipInfoList = {}
    for _, dlKey in pairs(_dlZips) do
        local bDownload = self:checkDownloaded(dlKey)
        if not bDownload then

            local dyInfo = globalData.GameConfig.dynamicData[dlKey]
            if dyInfo then
                local dlInfo = {
                    key = dyInfo.zipName,
                    md5 = dyInfo.md5,
                    type = dyInfo.type,
                    zOrder = "3", -- 不用那么靠前
                    size = (dyInfo.size or 123)
                }
                table.insert(dlZipInfoList, dlInfo)
            end

        end
    end

    return dlZipInfoList
end

function SidekicksManager:getSeletSeasonIdxDLResName()
    return "Sidekicks_Season_" .. self._selectSeasonIdx
end
-- 下载 指定赛季资源
function SidekicksManager:downloadSeasonRes(_seasonIdx)
    local dlZipList = {}
    local resZipName = "Sidekicks_Season_" .. self._selectSeasonIdx
    local codeZipName = resZipName .. "_Code" 
    table.insert(dlZipList, resZipName)
    table.insert(dlZipList, codeZipName)
    local dlZipInfoList = self:getDlZips(dlZipList)
    local SideKicksDLControl = util_require("common.SideKicksDLControl")
    SideKicksDLControl:getInstance():downloadSeasonRes(dlZipInfoList)
end

-- 每日轮盘
function SidekicksManager:sendWheelSpin()
    self.m_net:sendWheelSpin()
end
-- 宠物重命名
function SidekicksManager:sendSyncPetName(_petId, _newName)
    self.m_net:sendSyncPetName(_petId, _newName)
end
-- 喂宠物 升级
function SidekicksManager:sendFeedPetReq(_petId, _count)
    self.m_net:sendFeedPetReq(_petId, _count)
end
-- 喂宠物 星级突破
function SidekicksManager:sendStarUpPetReq(_petId, _count)
    self.m_net:sendStarUpPetReq(_petId, _count)
end
-- 保存引导 信息
function SidekicksManager:syncGuideDataReq()
    self.m_net:syncGuideDataReq(self:getGuideData())
end
-- 荣誉促销购买
function SidekicksManager:buyHonorSale(_data)
    self.m_net:buyHonorSale(_data)
end

function SidekicksManager:saveWheelLevelEf()
    local curHonorLv = 1
    local newSeasonIdx = 1
    local data = self:getRunningData()
    if data then
        curHonorLv = data:getHonorLv()
        newSeasonIdx = data:getNewSeasonIdx()
    end
    
    gLobalDataManager:setNumberByField("Sidekicks_" .. newSeasonIdx, curHonorLv)
end

function SidekicksManager:getWheelLevelEf()
    local newSeasonIdx = 1
    local data = self:getRunningData()
    if data then
        newSeasonIdx = data:getNewSeasonIdx()
    end
    
    local saveLv = gLobalDataManager:getNumberByField("Sidekicks_" .. newSeasonIdx, 1)
    return saveLv
end

function SidekicksManager:getLastHonorLv()
    return self.m_lastHonorLv or 1
end
function SidekicksManager:setLastHonorLv(_lv)
    self.m_lastHonorLv = _lv
end

function SidekicksManager:spinWinCoinsInfo(_info)
    if not _info then
        return
    end

    self._sidekicksSpinWinCoins = _info.BIG_WIN_MORE or 0
    self._sidekicksBetWinCoins = _info.BET_COINS_MORE
    if self._sidekicksBetWinCoins then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_SIDEKICKS_EXTRA_BET)
    end
end
function SidekicksManager:getSpinWinCoins()
    local coins = toLongNumber(self._sidekicksSpinWinCoins)
    self:resetSpinWinCoins()
    return coins
end
function SidekicksManager:resetSpinWinCoins()
    self._sidekicksSpinWinCoins = 0
end
function SidekicksManager:getBigWinSpinName()
    return "Sidekicks_dog"
end

function SidekicksManager:getBetWinCoins()
    local coins = self._sidekicksBetWinCoins
    self:resetBetWinCoins()
    return coins
end

function SidekicksManager:resetBetWinCoins()
    self._sidekicksBetWinCoins = nil
end

function SidekicksManager:getSidekicksBetNode(_seasonIdx)
    if not self:isCanShowLayer(_seasonIdx) then
        return
    end
    
    local node = util_createView("GameModule.Sidekicks.views.base.SidekicksBetWinNode", _seasonIdx)
    return node
end

function SidekicksManager:getPetSpecialBonus(_petId)
    local bonus = 0
    local data = G_GetMgr(G_REF.Sidekicks):getRunningData()
    if not data then
        return bonus
    end

    local petList = data:getTotalPetsList()
    local petInfo = petList[_petId]
    if not petInfo then
        return bonus
    end

    local skill = petInfo:getSkillInfoById(3)
    bonus = skill:getCurrentSpecialParam()
    return bonus
end

return SidekicksManager