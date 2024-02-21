--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2022-07-11 16:11:23
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2022-07-11 16:22:46
FilePath: /SlotNirvana/src/GameModule/PiggyClicker/controller/PiggyClickerGameMgr.lua
Description: 快速点击小游戏
--]]
local PiggyClickerGameConfig = util_require("GameModule.PiggyClicker.config.PiggyClickerGameConfig")
local PiggyClickerGameMgr = class("PiggyClickerGameMgr", BaseGameControl)
local LotteryNetModel = util_require("GameModule.Lottery.net.LotteryNetModel")
local PiggyClickerGameNet = require("GameModule.PiggyClicker.net.PiggyClickerGameNet")

function PiggyClickerGameMgr:ctor()
    PiggyClickerGameMgr.super.ctor(self)
    self:setRefName(ACTIVITY_REF.PiggyClicker)

    self.m_netModel = PiggyClickerGameNet:getInstance()
end

-- 解析小游戏数据
function PiggyClickerGameMgr:parseData(_gameData)
    if not _gameData then
        return
    end

    local _data = self:getData()
    if not _data then
        _data = require("GameModule.PiggyClicker.model.PiggyClickerData"):create()
        _data:parseData(_gameData)
        self:registerData(_data)
    else
        _data:parseData(_gameData)
    end
end

-- 显示游戏主界面
function PiggyClickerGameMgr:getMainLayer()
    return self.m_gameMainLayer
end
function PiggyClickerGameMgr:showMainLayer(_gameIdx, _overFunc)
    local data = self:getData()
    if not data then
        return
    end

    local gameData = data:getGameDataByIdx(_gameIdx)
    if not gameData or not gameData:checkCanPlay() then
        return
    end

    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("PiggyClickerGameMainUI") then
        return
    end

    local view = util_createView("Activity.game.PiggyClickerGameMainUI", gameData, _overFunc)
    self.m_gameMainLayer = view
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示游戏规则界面
function PiggyClickerGameMgr:showGameRuleLayer()
    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("PiggyClickerGameRuleLayer") then
        return
    end

    local view = util_createView("Activity.other.PiggyClickerGameRuleLayer")
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end
function PiggyClickerGameMgr:forceCloseRuleLayer()
    local view = gLobalViewManager:getViewByExtendData("PiggyClickerGameRuleLayer")
    if view then
        view:closeUI()
    end
end

-- 显示游戏支付界面
function PiggyClickerGameMgr:showGamePayLayer(_gameData)
    if not _gameData or not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("PiggyClickerGamePayLayer") then
        return
    end

    local view = util_createView("Activity.other.PiggyClickerGamePayLayer", _gameData)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end
-- 显示游戏支付界面 二次确认
function PiggyClickerGameMgr:showGamePayConfirmLayer(_gameData)
    if not _gameData or not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("PiggyClickerGamePayConfirmLayer") then
        return
    end

    local view = util_createView("Activity.other.PiggyClickerGamePayConfirmLayer", _gameData)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示游戏 掉落界面
function PiggyClickerGameMgr:showGameDropItemLayer(_gameData, _overFunc)
    if not _gameData then
        return
    end

    if not self:isCanShowLayer() then
        return
    end

    if gLobalViewManager:getViewByExtendData("PiggyClickerGameDropItemLayer") then
        return
    end

    local view = util_createView("Activity.other.PiggyClickerGameDropItemLayer", _gameData, _overFunc)
    self:showLayer(view, ViewZorder.ZORDER_UI)
    return view
end

-- 显示付费权益界面
function PiggyClickerGameMgr:showPayBenefitLayer(_gameData)
    if not _gameData then
        return
    end

    local price = _gameData:getPrice()
    local view = util_createView(SHOP_CODE_PATH.ShopBenefitLayer, {p_price = price})
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

-------------------------------- net --------------------------------
-- 开始游戏
function PiggyClickerGameMgr:sendStartGameReq(_gameData)
    if not _gameData or not _gameData:checkCanPlay() then
        return
    end

    local bPlaying = _gameData:checkGamePlaying()
    local gameIdx = _gameData:getGameIdx()
    if bPlaying then
        gLobalNoticManager:postNotification(PiggyClickerGameConfig.EVENT_NAME.PIGGY_CLICKER_START_GAME_SUCCESS, gameIdx)
        return
    end
    self.m_netModel:sendStartGameReq(gameIdx)
end

-- 同步游戏数据 存档
function PiggyClickerGameMgr:sendArchiveGameReq(_gameData)
    local gameIdx = _gameData:getGameIdx()
    local archiveData = _gameData:getArchiveData()
    self.m_netModel:sendArchiveGameReq(gameIdx, archiveData:getCurArchiveData())
end

-- 游戏结束 领奖
function PiggyClickerGameMgr:sendGameCollectReq(_gameData)
    local gameIdx = _gameData:getGameIdx()
    local verifyData = _gameData:getCollectVeriyData() 

    self.m_netModel:sendGameCollectReq(gameIdx, verifyData)
end

--通知服务器游戏结束了
function PiggyClickerGameMgr:sendGameClearReq(_gameData)
    local gameIdx = _gameData:getGameIdx()
    self:getData():removeGameDataByIdx(gameIdx)
    local collectData = G_GetMgr(G_REF.Inbox):getSysRunData()
    if collectData then
        collectData:removePiggyClickerMail(gameIdx)
    end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
    self.m_netModel:sendGameClearReq(gameIdx)
end

-- 付费
function PiggyClickerGameMgr:goPurchase(_gameData)
    self.m_netModel:goPurchase(_gameData)
end
-------------------------------- net --------------------------------

------------------------------ 切前后台暂停游戏 ------------------------------
function PiggyClickerGameMgr:commonBackGround()
    self.m_pauseGame = true
end
function PiggyClickerGameMgr:commonForeGround()
    local cb = function()
        self.m_pauseGame = false
    end
    if not tolua.isnull(self.m_gameMainLayer) then
        self.m_gameMainLayer:commonForeGround(cb)
    else
        cb()
    end 
end
function PiggyClickerGameMgr:isPauseGame()
    return self.m_pauseGam
end
------------------------------ 切前后台暂停游戏 ------------------------------

return PiggyClickerGameMgr