--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-03-20 16:24:41
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-03-20 16:24:51
FilePath: /SlotNirvana/src/GameModule/NewUserExpand/controller/ExpandGamePlinkoMgr.lua
Description: 扩圈系统小游戏 弹珠 mgr
--]]
local ExpandGamePlinkoMgr = class("ExpandGamePlinkoMgr", BaseGameControl)
local ExpandGamePlinkoConfig = util_require("GameModule.NewUserExpand.config.ExpandGamePlinkoConfig")
local ExpandPlinkoDropRowColPath = util_require("GameModule.NewUserExpand.config.ExpandPlinkoDropRowColPath")

function ExpandGamePlinkoMgr:ctor()
    ExpandGamePlinkoMgr.super.ctor(self)
    self:setRefName(G_REF.ExpandGamePlinko)
end

function ExpandGamePlinkoMgr:getNetObj()
    if self.m_net then
        return self.m_net
    end
    local ExpandGamePlinkoNet = util_require("GameModule.NewUserExpand.net.ExpandGamePlinkoNet")
    self.m_net = ExpandGamePlinkoNet:create()
    return self.m_net
end

function ExpandGamePlinkoMgr:getData()
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

-- 获取球掉落的 路径
function ExpandGamePlinkoMgr:getBallDropPath(_startIdx)
    local endIdx = self:getCurSpinHitIdx()
    local key = string.format("key_%s_%s", _startIdx, endIdx*2)
    local pathList = ExpandPlinkoDropRowColPath[key]
    assert(pathList, "没有找到 对应路径"..key)
   
    return pathList[util_random(1, #pathList)]
end

-- 设置游戏状态
function ExpandGamePlinkoMgr:setGameState(_state)
    self.m_gameState = _state
end
function ExpandGamePlinkoMgr:getGameState()
    return self.m_gameState
end

-- 设置 当前spin 游戏掉球位置信息
function ExpandGamePlinkoMgr:setCurSpinHitIdx(_idx)
    self.m_curHitIdx = _idx
end
function ExpandGamePlinkoMgr:getCurSpinHitIdx()
    return self.m_curHitIdx or 1
end

-- 显示游戏界面
function ExpandGamePlinkoMgr:showMainLayer()
    if not self:isCanShowLayer() then
        return
    end

    local view = gLobalViewManager:getViewByName("ExpandGamePlinkoMainUI")
    if not view then
       view = util_createView("GameModule.NewUserExpand.gameViews.plinko.ExpandGamePlinkoMainUI")
       self:showLayer(view)
    end
    return view
end
function ExpandGamePlinkoMgr:checkCloseMainUI()
    local view = gLobalViewManager:getViewByName("ExpandGamePlinkoMainUI")
    if not view then
        return
    end

    view:closeUI()
end

-- 显示 奖励弹板
function ExpandGamePlinkoMgr:showRewardLayer(_rewardCoins, _cb)
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
function ExpandGamePlinkoMgr:sendPlayExpandGameReq()
    local gameData = self:getData()
    if not gameData then
        return
    end

    gameData:spinUpdateGameData()
    local hitIdx = gameData:getCurHitIdx()
    self:setCurSpinHitIdx(hitIdx)
    -- 保存 spin 最新游戏数据
    self:saveGameClientData(gameData)
        
    gLobalNoticManager:postNotification(ExpandGamePlinkoConfig.EVENT_NAME.SPIN_SUCCESS_AND_DROP_BALL)
end

-- 保存 spin 最新游戏数据
function ExpandGamePlinkoMgr:saveGameClientData(_gameData)
    local saveInfo = {}
    saveInfo.curPassIdx = _gameData:getCurPassIdx()
    saveInfo.playTimes = _gameData:getPlayTimes()
    saveInfo.coinsSum = _gameData:getTotalCoins()
    gLobalDataManager:setStringByField("PlinkoTaskGameDataSaveInfo", json.encode(saveInfo))
end

-- 玩游戏 3次 结束结算此游戏
function ExpandGamePlinkoMgr:sendOverExpandGameReq()
    local successCB = function(_receiveData)
        local totalCoins = _receiveData.rewardCoins
        self:showRewardLayer(totalCoins, function()
            self:checkCloseMainUI()
        end)
    end
    self:getNetObj():sendOverExpandGameReq(successCB)
end

return ExpandGamePlinkoMgr