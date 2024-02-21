--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-10 11:15:32
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-10 11:15:47
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/controller/ExpandGameMarqueeMgr.lua
Description: 扩圈系统小游戏 跑马灯mgr
--]]
local ExpandGameMarqueeConfig = util_require("GameModule.NewUserExpand.config.ExpandGameMarqueeConfig")
local ExpandGameMarqueeMgr = class("ExpandGameMarqueeMgr", BaseGameControl)

function ExpandGameMarqueeMgr:ctor()
    ExpandGameMarqueeMgr.super.ctor(self)
    self:setRefName(G_REF.ExpandGameMarquee)
end

function ExpandGameMarqueeMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local ExpandGameMarqueeNet = util_require("GameModule.NewUserExpand.net.ExpandGameMarqueeNet")
    self.m_net = ExpandGameMarqueeNet:getInstance()
    return self.m_net
end

function ExpandGameMarqueeMgr:getData()
    local expandData = G_GetMgr(G_REF.NewUserExpand):getData()
    if not expandData then
        return
    end

    local gameData = expandData:getGameData()
    if not gameData then
        return
    end
    local curTaskGameData = gameData:getCurTaskGameData()
    return curTaskGameData
end

-- 设置游戏状态
function ExpandGameMarqueeMgr:setGameMachineState(_state)
    self.m_gameState = _state
end
function ExpandGameMarqueeMgr:getGameMachineState()
    return self.m_gameState
end

-- 本次spin 选中的 cellIdx
function ExpandGameMarqueeMgr:setCurSpinHitIdx(_idx)
    self.m_serverHitIdx = _idx
end
function ExpandGameMarqueeMgr:getCurSpinHitIdx()
    return self.m_serverHitIdx
end

-- 显示游戏界面
function ExpandGameMarqueeMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local view = gLobalViewManager:getViewByName("ExpandGameMarqueeMainUI")
    if not view then
       view = util_createView("GameModule.NewUserExpand.gameViews.marquee.ExpandGameMarqueeMainUI")
       self:showLayer(view)
    end
    return view
end
function ExpandGameMarqueeMgr:checkCloseMainUI()
    local view = gLobalViewManager:getViewByName("ExpandGameMarqueeMainUI")
    if not view then
        return
    end

    view:closeUI()
end

-- 显示 奖励弹板
function ExpandGameMarqueeMgr:showRewardLayer(_rewardCoins, _cb)
    _cb = _cb or function() end
    local totalCoins = tonumber(_rewardCoins) or 0
    if totalCoins <= 0 then
        _cb()
        return
    end

    local view = G_GetMgr(G_REF.NewUserExpand):showRewardLayer(totalCoins, _cb)
    if not view then
        _cb()
        return
    end
    return view
end

-- 玩游戏 play
function ExpandGameMarqueeMgr:sendPlayExpandGameReq()
    -- local successCB = function(_receiveData)
    --     if _receiveData and _receiveData.hitIndex then
    --         self:setCurSpinHitIdx((tonumber(_receiveData.hitIndex) or 0) + 1)
    --     end
    -- end
    -- self:getNetObj():sendPlayExpandGameReq(successCB)
    local gameData = self:getData()
    if not gameData then
        return
    end

    gameData:spinUpdateGameData()
    local hitIdx = gameData:getCurHitIdx()
    self:setCurSpinHitIdx(hitIdx)

    -- 保存 spin 最新游戏数据
    self:saveGameClientData(gameData)
        
    gLobalNoticManager:postNotification(ExpandGameMarqueeConfig.EVENT_NAME.PLAY_EXPAND_MINI_GMAE_SUCCESS)
end

-- 保存 spin 最新游戏数据
function ExpandGameMarqueeMgr:saveGameClientData(_gameData)
    local saveInfo = {}
    saveInfo.curPassIdx = _gameData:getCurPassIdx()
    saveInfo.playTimes = _gameData:getPlayTimes()
    saveInfo.coinsSum = _gameData:getTotalCoins()
    saveInfo.multipleSum = _gameData:getTotalMulSum()
    gLobalDataManager:setStringByField("MarqueeTaskGameDataSaveInfo", json.encode(saveInfo))
end

-- 玩游戏 3次 结束结算此游戏
function ExpandGameMarqueeMgr:sendOverExpandGameReq()
    local successCB = function(_receiveData)
        local totalCoins = _receiveData.rewardCoins
        local gameData = self:getData()
        if not gameData then
            self:showRewardLayer(totalCoins, function()
                self:checkCloseMainUI()
            end)
            return
        end

        gLobalNoticManager:postNotification(ExpandGameMarqueeConfig.EVENT_NAME.COLLECT_EXPAND_MINI_GMAE_SUCCESS, totalCoins)
    end
    self:getNetObj():sendOverExpandGameReq(successCB)
end

return ExpandGameMarqueeMgr