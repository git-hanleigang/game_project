local DartsGameManager = class("DartsGameManager", BaseGameControl)
local DartsGameNet = require("activities.Activity_DartsGameNew.net.DartsGameNet")

function DartsGameManager:ctor()
    DartsGameManager.super.ctor(self)
    self:setRefName(ACTIVITY_REF.DartsGameNew)

    self:getConfig()

    self.m_netModel = DartsGameNet:getInstance()
end

function DartsGameManager:parseData(data, isLogon)
    if not data then
        return
    end

    local _data = self:getData()
    if not _data then
        _data = require("activities.Activity_DartsGameNew.model.DartsGameData"):create()
        _data:parseData(data)
        _data:setRefName(ACTIVITY_REF.DartsGameNew)
        self:registerData(_data)
    else
        _data:parseData(data)
    end
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
    local view = util_createView("Activity.Activity_DartsGameNew", {index = index, callback = callback})
    self:showLayer(view, ViewZorder.ZORDER_UI)
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

--付费确认界面
function DartsGameManager:showPaySureLayer(gameData)
    if gLobalViewManager:getViewByExtendData("DartsPaySureLayer") then
        return
    end
    local view = util_createView("Activity.DartsPopupsNew.DartsPaySureLayer", {gameData = gameData})
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

--二次付费确认界面
function DartsGameManager:showSecondPaySureLayer(gameData)
    if gLobalViewManager:getViewByExtendData("DartsSecondPaySureLayer") then
        return
    end
    local view = util_createView("Activity.DartsPopupsNew.DartsSecondPaySureLayer", {gameData = gameData})
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

--展示奖励
function DartsGameManager:showRewardsLayer(gameData)
    if gLobalViewManager:getViewByExtendData("DartsRewardsLayer") then
        return
    end
    local view = util_createView("Activity.DartsPopupsNew.DartsRewardsLayer", {gameData = gameData})
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
        "Activity.DartsPopupsNew.DartsTriggerLayer",
        {
            gameData = gameData,
            callback = callback
        }
    )
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

--展示规则界面
function DartsGameManager:showRuleLayer()
    local view = util_createView("Activity.DartsPopupsNew.DartsRuleLayer")
    -- gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    self:showLayer(view, ViewZorder.ZORDER_UI)
end

function DartsGameManager:getConfig()
    if not self.m_config then
        self.m_config = util_require("activities.Activity_DartsGameNew.config.DartsGameConfig")
    end

    return self.m_config
end

return DartsGameManager
