local DartsGameManager = class("DartsGameManager", BaseGameControl)
local DartsGameNet = require("activities.Activity_DartsGame.net.DartsGameNet")

function DartsGameManager:ctor()
    DartsGameManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DartsGame)

    self:getConfig()

    self.m_netModel = DartsGameNet:getInstance()
end

function DartsGameManager:parseData(data, isLogon)
    if not data then
        return
    end

    local _data = self:getData()
    if not _data then
        _data = require("activities.Activity_DartsGame.model.DartsGameData"):create()
        _data:parseData(data)
        _data:setRefName(ACTIVITY_REF.DartsGame)
        self:registerData(_data)
    else
        _data:parseData(data)
    end
end

-- 资源是否下载完成
function DartsGameManager:isDownloadRes(refName)
    if not DartsGameManager.super.isDownloadRes(self, refName) then
        return false
    end
    local themeName = self:getThemeName(refName)
    if self:checkRes(themeName .. "Res") then
        -- 存在代码资源包才判断
        if not self:checkDownloaded(themeName .. "Res") then
            return false
        end
    end
    return true
end

function DartsGameManager:sendStartGameReq(gameData)
    local gameIdx = gameData:getIndex()
    self.m_netModel:sendStartGameReq(gameIdx)
end

function DartsGameManager:sendGameEnd(gameData)
    local gameIdx = gameData:getIndex()
    self.m_netModel:sendGameEnd(gameIdx)
end

function DartsGameManager:sendBuy(gameData)
    self.m_netModel:goPurchase(gameData)
end

function DartsGameManager:sendGetReeward(gameData)
    self.m_netModel:sendGetReeward(gameData)
end

function DartsGameManager:onClickMail(index)
    --find game which is playing status
    local gameData = self:getData():getCurGameOrCanPlayGame(index)
    if gameData then
        self:openGameLayer(gameData:getIndex())
    end
end

function DartsGameManager:openGameLayer(index, callback)
    if not self:isCanShowLayer() then
        if callback then
            callback()
        end
        return
    end
    local view = util_createView("Activity.Activity_DartsGame", {index = index, callback = callback})
    self:showLayer(view, ViewZorder.ZORDER_UI)
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

--付费确认界面
function DartsGameManager:showPaySureLayer(gameData)
    local view = util_createView("Activity.popups.DartsPaySureLayer", {gameData = gameData})
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

--二次付费确认界面
function DartsGameManager:showSecondPaySureLayer(gameData)
    local view = util_createView("Activity.popups.DartsSecondPaySureLayer", {gameData = gameData})
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

--展示奖励
function DartsGameManager:showRewardsLayer(gameData)
    local view = util_createView("Activity.popups.DartsRewardsLayer", {gameData = gameData})
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function DartsGameManager:showTriggerLayer(gameData, callback)
    if not self:isCanShowLayer() then
        if callback then
            callback()
        end
        return
    end
    local view =
        util_createView(
        "Activity.popups.DartsTriggerLayer",
        {
            gameData = gameData,
            callback = callback
        }
    )
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function DartsGameManager:getConfig()
    if not self.m_config then
        self.m_config = util_require("activities.Activity_DartsGame.config.DartsGameConfig")
    end

    return self.m_config
end

return DartsGameManager
