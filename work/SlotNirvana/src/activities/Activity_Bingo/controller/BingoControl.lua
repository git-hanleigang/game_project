--[[
    
    author: 徐袁
    time: 2021-08-13 10:23:32
]]
local BingoNet = require("activities.Activity_Bingo.net.BingoNet")
local BingoGuide = require("activities.Activity_Bingo.controller.BingoGuideCtrl")
local BingoControl = class("BingoControl", BaseActivityControl)

function BingoControl:ctor()
    BingoControl.super.ctor(self)
    self:setRefName(ACTIVITY_REF.Bingo)

    self.m_net = BingoNet:getInstance()
    self.m_guide = BingoGuide:getInstance()
end

function BingoControl:getNet()
    return self.m_net
end

function BingoControl:getGuide()
    return self.m_guide
end

function BingoControl:getUserDefaultValue()
    return gLobalDataManager:getStringByField(self:getUserDefaultKey(), "")
end

function BingoControl:setUserDefaultValue(value)
    gLobalDataManager:setStringByField(self:getUserDefaultKey(), value)
end

function BingoControl:getExtraDataKey()
    return "BingoExtra"
end

function BingoControl:getUserDefaultKey()
    local gameData = self:getRunningData()
    if gameData then
        return "BingoNet" .. gameData.p_start
    else
        return "BingoNet" .. globalData.userRunData.uid
    end
end

-- 大厅展示资源判断
function BingoControl:isDownloadLobbyRes()
    -- 弹板、hall、slide、资源在loading内
    return self:isDownloadLoadingRes()
end

-- 显示主界面
function BingoControl:showMainLayer(param, func)
    if not self:isCanShowLayer() then
        return nil
    end

    self.m_guide:onRegist("Bingo")

    local bingoGameUI = nil
    if gLobalViewManager:getViewByExtendData("BingoGameUI") == nil then
        bingoGameUI = util_createView("Activity/BingoGame/BingoGameUI", param)
        if bingoGameUI ~= nil then
            self:showLayer(bingoGameUI, ViewZorder.ZORDER_UI - 1)
        end
    end
    if func then
        func()
    end
    return bingoGameUI
end

-- 显示选择界面
function BingoControl:showSelectLayer(param)
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("BingoSelectUI") == nil then
        local bingoSelectUI = util_createView("Activity/BingoSelect/BingoSelectUI", param)
        if bingoSelectUI ~= nil then
            self:showLayer(bingoSelectUI, ViewZorder.ZORDER_UI - 1)
        end
    end
end

function BingoControl:showZeusGameLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("BingoZeusMainLayer") == nil then
        local bingoZeus = util_createView("Activity/BingoZeusGame/BingoZeusMainLayer")
        if bingoZeus ~= nil then
            self:showLayer(bingoZeus, ViewZorder.ZORDER_UI - 1)
        end
    end
end

function BingoControl:showBoxRewardLayer(_rewardInfo, _isProgress)
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity.BingoReward.BingoBoxRewardUI", _rewardInfo, _isProgress)
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI - 1)
    end

    return view
end

function BingoControl:showWheelRewardLayer(_rewardInfo, _isProgress)
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity.BingoReward.BingoWheelReward", _rewardInfo, _isProgress)
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI - 1)
    end

    return view
end

function BingoControl:showGameRewardLayer(_rewardInfo, _type)
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity.BingoReward.BingoGameGetRewardUI", _rewardInfo, _type)
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI - 1)
    end

    return view
end

function BingoControl:showLineLayer(_rewardInfo, _type)
    if not self:isCanShowLayer() then
        return
    end

    local view = util_createView("Activity.BingoGame.BingoShowLineDetailUI")
    if view then 
        self:showLayer(view, ViewZorder.ZORDER_UI - 1)
    end

    return view
end

--打开排行榜页
function BingoControl:showRankLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("BingoRankUI") == nil then
        local rankUI = util_createView("Activity.BingoRank.BingoRankUI")
        if rankUI then 
            if gLobalSendDataManager.getLogPopub then
                gLobalSendDataManager:getLogPopub():addNodeDot(rankUI, "btnRank", DotUrlType.UrlName, false)
            end
            self:showLayer(rankUI, ViewZorder.ZORDER_UI - 1)
        end
    end
end

-- 解析额外数据
function BingoControl:initBingoExtraData(BingoExtraData)
    local bingoData = self:getRunningData()
    if BingoExtraData and bingoData then
        bingoData:initBingoExtraData(BingoExtraData)
    end
end

function BingoControl:sendBingoPlayBall()
    self.m_net:sendBingoPlayBall()
end

function BingoControl:sendActionBingoRank()
    self.m_net:sendActionBingoRank()
end

function BingoControl:sendZeusPlay(_index)
    self.m_net:sendZeusPlay(_index)
end

function BingoControl:setSaveData(_data)
    self.m_saveData = _data
end

function BingoControl:getSaveData()
    return self.m_saveData
end

return BingoControl
