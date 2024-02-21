-- PipeConnect接水管 控制类
local PipeConnectGuideManager = require("activities.Activity_PipeConnect.controller.PipeConnectGuideManager")
local PipeConnectNet = require("activities.Activity_PipeConnect.net.PipeConnectNet")
local PipeConnectManager = class("PipeConnectManager", BaseActivityControl)

function PipeConnectManager:ctor()
    PipeConnectManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PipeConnect)
    self.PipeConnectConfig = util_require("activities.Activity_PipeConnect.config.PipeConnectConfig")

    self.m_PipeConnectNet = PipeConnectNet:getInstance()
    self.m_guide = PipeConnectGuideManager:getInstance()
end

function PipeConnectManager:getGuide()
    return self.m_guide
end

function PipeConnectManager:getConfig()
    local blast_data = self:getRunningData()
    if not blast_data then
        return
    end
    return self.PipeConnectConfig
end

function PipeConnectManager:getMapConfig()
    if not self.mapConfig then
        self.mapConfig = util_require("Activity.PipeConnectConfig.PipeMapConfig")
    end
    return self.mapConfig
end

function PipeConnectManager:getLineData(_index)
    local gameData = self:getRunningData()
    local p_data = nil
    if gameData then
        local pl = gameData:getPipLine()
        local count = #pl[_index]
        p_data = self:getMapConfig().path[_index][count..""]
    end
    return p_data
end

function PipeConnectManager:getLineCollectCount(_index)
    local gameData = self:getRunningData()
    local p_data = nil
    local count = 0
    local maxCount = 0
    if gameData then
        local pl = gameData:getPipLine()[_index]
        if pl then
            for i,v in ipairs(pl) do
                if v.collect then
                    count = count + 1
                end
            end
            maxCount = #pl
        end
    end
    return count,maxCount
end

function PipeConnectManager:getCurrentBetIndex()
    local gameData = self:getRunningData()
    if not gameData then
        return 1,1
    end
    local bet = gameData:getSinglBet()
    local betList = gameData:getBetGear()
    self.m_betIndex = 1
    self.m_betMax = #betList
    for i,v in ipairs(betList) do
        if bet == v then
            self.m_betIndex = i
        end
    end
    return self.m_betIndex,self.m_betMax
end

function PipeConnectManager:getLineMaxCount(_index)
    local gameData = self:getRunningData()
    local p_data = nil
    local count = 0
    local maxCount = 0
    if gameData then
        local pl = gameData:getPipLine()[_index]
        if pl then
            for i,v in ipairs(pl) do
                if v.collect then
                    count = count + 1
                end
            end
            maxCount = #pl
        end
    end
    return maxCount
end


function PipeConnectManager:getLineCount(_index,_data)
    local count = 0
    local maxCount = 0
    if _data then
        local pl = _data[_index]
        if pl then
            for i,v in ipairs(pl) do
                if v.collect then
                    count = count + 1
                end
            end
            maxCount = #pl
        end
    end
    return count,maxCount
end

function PipeConnectManager:setBet(_bet)
    self.m_bet = _bet
end

function PipeConnectManager:getBet()
    return self.m_bet or 1
end

-- 请求小游戏开启宝箱
function PipeConnectManager:sendOpenBoxRequest(_position)
    self.m_PipeConnectNet:sendOpenBoxRequest(_position)
end

-- 请求排行榜数据
function PipeConnectManager:sendActionRank(_flag)
    self.m_PipeConnectNet:sendActionRank(_flag)
end

-- 请求老虎机数据
function PipeConnectManager:sendSlotReq(_bet)
    local successFunc = function(_netData)
        if not self:getRunningData() then
            return
        end
        if _netData.stageReward then
            self:getRunningData():setIsFirst(true)
        else
            self:getRunningData():setIsFirst(false)
        end
        self.m_netData = _netData
        self.m_cbet = _bet
        self:parseSlotReward(_netData)
        self:getRunningData():setSinglBet(_bet)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIPECONNECT_SLOTRESULT,true)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = ACTIVITY_REF.PipeConnect})
    end
    local fileFunc = function()
        print("fileFunc")
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_PIPECONNECT_SLOTRESULT,false)
    end
    self.m_PipeConnectNet:sendSlotReq(_bet,successFunc,fileFunc)
end
--解析老虎机奖励数据,
function PipeConnectManager:parseSlotReward(_netData)
    local gameData = self:getRunningData()
    if not gameData then
        return
    end
    if _netData.jackpots then
        --刷新Jackport信息
        gameData:parsePipeJackData(_netData.jackpots)
    end
    if self.m_netData.fakeScrollReels and #self.m_netData.fakeScrollReels > 0 then
        gameData:parseRells(self.m_netData.fakeScrollReels)
    end
    if self.m_netData.reels and #self.m_netData.reels > 0 then
        gameData:parseEndRells(self.m_netData.reels)
    end
end

--转结束之后解析
function PipeConnectManager:parseSlotReels()
    local gameData = self:getRunningData()
    if self.m_netData and self.m_netData.pipeLineList and gameData then
        --刷新管道信息
        gameData:parsePipeLineData(self.m_netData.pipeLineList)
        if self.m_netData.reward and self.m_netData.reward.scoop ~= 0 then
            gameData:setMayaGameSoop(self.m_netData.reward.scoop)
        end
    end
end

--获取当前奖励
function PipeConnectManager:getSoltReward()
    return self.m_netData or {}
end

--获取奖励倍数
function PipeConnectManager:getRewardBet()
    return self.m_cbet or 1
end

--清理当前轮次数据
function PipeConnectManager:clearSlot()
    self.m_netData = {}
    self.m_cbet = 1
end

function PipeConnectManager:getInCoinBuff()
    local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_PIPECONNECT_DOUBLE_COIN)
    return leftTimes and leftTimes > 0
end

function PipeConnectManager:getWildBuff()
    local leftTimes = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_PIPECONNECT_WILD)
    return leftTimes and leftTimes > 0
end

function PipeConnectManager:getUserDefaultValue()
    return gLobalDataManager:getStringByField(self:getUserDefaultKey(), "")
end

function PipeConnectManager:setUserDefaultValue(value)
    gLobalDataManager:setStringByField(self:getUserDefaultKey(), value)
end

function PipeConnectManager:getUserDefaultKey()
    local gameData = self:getRunningData()
    if gameData then
        return "PipeConnectNet" .. gameData.p_start
    else
        return "PipeConnectNet" .. globalData.userRunData.uid
    end
end

-- 大厅展示资源判断
function PipeConnectManager:isDownloadLobbyRes()
    return self:isDownloadLoadingRes()
end

function PipeConnectManager:getPopPath(popName)
    return "Activity_PipeConnect_loading/" .. popName
end

function PipeConnectManager:showMainLayer(params)
    if not self:isCanShowLayer() then
        return
    end
    local pipeMainUI = nil
    if gLobalViewManager:getViewByExtendData("PipeConnectMainUI") == nil then
        pipeMainUI = util_createView("Activity/PipeConnectGame/PipeConnectGameUI", param)
        if pipeMainUI ~= nil then
            self.m_guide:onRegist(self:getThemeName())
            self:showLayer(pipeMainUI, ViewZorder.ZORDER_UI)
        end
    end
    return pipeMainUI
end

-- 显示选择界面
function PipeConnectManager:showSelectLayer(param)
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("PipeConnectSelectUI") == nil then
        local PipeConnectSelectUI = util_createView("Activity/PipeConnectSelect/PipeConnectSelectUI", param)
        if PipeConnectSelectUI ~= nil then
            self:showLayer(PipeConnectSelectUI, ViewZorder.ZORDER_UI + 1)
        end
    end
end

-- 排行榜主界面
function PipeConnectManager:showRankLayer(param)
    if not self:isCanShowLayer() then
        return
    end

    local PipeConnectRankUI = nil
    if gLobalViewManager:getViewByExtendData("PipeConnectRankUI") == nil then
        local PipeConnectRankUI = util_createView("Activity/PipeConnectRank/PipeConnectRankUI", param)
        if PipeConnectRankUI ~= nil then
            self:showLayer(PipeConnectRankUI, ViewZorder.ZORDER_UI + 1)
        end
    end
    return PipeConnectRankUI
end

-- 显示小游戏界面
function PipeConnectManager:showJigsawGameLayer(param)
    if not self:isCanShowLayer() then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("PCJigsawMainLayer") == nil then
        local view = util_createView("Activity/PipeConnectJigsawGame/PCJigsawMainLayer", param)
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end
    return view
end

-- 显示通用奖励界面({coins = number, items = table})
function PipeConnectManager:showNormalRewardLayer(_rewardInfo)
    if not self:isCanShowLayer() then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("PCNormalRewardLayer") == nil then
        view = util_createView("Activity.PipeConnectReward.PCNormalRewardLayer", _rewardInfo)
        if view then 
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end

    return view
end

-- 显示小游戏奖励界面({coins = number, items = table})
function PipeConnectManager:showJigsawRewardLayer(_rewardInfo)
    if not self:isCanShowLayer() then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("PCJigsawRewardLayer") == nil then
        view = util_createView("Activity.PipeConnectReward.PCJigsawRewardLayer", _rewardInfo)
        if view then 
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end

    return view
end

-- 显示奖励界面(通关/轮次 奖励)({coins = number, items = table}, "PIPE_ROUND"/"PIPE_LEVEL")
function PipeConnectManager:showGameRewardLayer(_rewardInfo, _type,_spine)
    if not self:isCanShowLayer() then
        return
    end
    local coins = toLongNumber(0)
    if _rewardInfo.coinsV2 and _rewardInfo.coinsV2 ~= "" and _rewardInfo.coinsV2 ~= "0" then
        coins:setNum(_rewardInfo.coinsV2)
    else
        coins:setNum(_rewardInfo.coins)
    end
    _rewardInfo.coins = coins
    local view = util_createView("Activity.PipeConnectReward.PCGameRewardLayer", _rewardInfo, _type,_spine)
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end

    return view
end

-- 显示jackpot奖励界面({info = number, index = number, callback = function})
function PipeConnectManager:showJackpotRewardLayer(params)
    if not self:isCanShowLayer() then
        return
    end

    local view = nil
    if gLobalViewManager:getViewByExtendData("PCJackpotRewardLayer") == nil then
        local view = util_createView("Activity/PipeConnectReward/PCJackpotRewardLayer",params)
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI)
        end
    end
    return view
end

-- 显示帮助说明界面
function PipeConnectManager:showGameRuleLayer()
    if gLobalViewManager:getViewByExtendData("PipeConnectRuleView") == nil then
        local view = util_createView("Activity/PipeConnectRule/PipeConnectRuleView")
        if view ~= nil then
            self:showLayer(view, ViewZorder.ZORDER_UI + 1)
        end
    end
end

--
function PipeConnectManager:showGameGuoChangLayer()
    local view = util_createView("Activity.PipeConnectGame.PipeConnectGuoChang")
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI + 2)
    end
end

return PipeConnectManager
