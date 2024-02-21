--[[
    des: 新手5级时解锁新关卡提示 在樱桃关卡内提示
    如果玩家在樱桃关卡内升级升到了5级，弹出提示
    如果升到5级不是在樱桃关卡内，不弹出
    如果升到5级是在樱桃关卡内，但是中间进入过其他关卡，不弹出
    进入过其他的关卡，消失
    author:{author}
    time:2019-12-10 16:26:55
]]
local UnlockLevelTip = class("UnlockLevelTip", util_require("base.BaseView"))

function UnlockLevelTip:initUI()

    gLobalSendDataManager:getLogFeature():createUIActionSid("GameGuide")
    gLobalSendDataManager:getLogFeature():createUIActionNameDetailed("UnlockLevelTip")
    gLobalSendDataManager:getLogFeature():sendUIActionLog("GameGuide", "Popup")
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.NewGuide_NewGame)
    end

    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect("guideMoreGamesWindowSmall",false)
    end

    self.m_closed = false
    self:createCsbNode("UnlockLevelTip/UnlockLevelTip.csb")
    local touch = self:findChild("touch_layer")
    self:addClick(touch)

    self.m_showAction = true
    self:runCsbAction("show", false, function()
        self.m_showAction = false
        self:runCsbAction("idle", true)
    end)

    self:initIcon()
end

function UnlockLevelTip:initIcon()
    local levels = self:getLevelInfoList()
    for i=1,6 do
        local level = levels[i]
        if not level then
            return
        end
        local png = globalData.GameConfig:getLevelIconPath(level.p_levelName,LEVEL_ICON_TYPE.UNLOCK)
        if png then
            local icon = util_createSprite(png)
            local nodesp = self:findChild("Node_sp"..i)
            if nodesp and icon then
                icon:setAnchorPoint(0.5, 0.5)
                icon:setScale(0.25)
                nodesp:addChild(icon)
            end
        end
    end
end

function UnlockLevelTip:gotoLobby()
    if self.m_closed == true then
        return
    end
    self.m_closed = true
    globalData.isMoreGames2Lobby = true
    -- 进入大厅
    gLobalSendDataManager:getLogFeature():sendUIActionLog("GameGuide", "Click")
    release_print("UnlockLevelTip back to lobby!!!")
    gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)

    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect("guideMoreGamesWindowSmallClick",false)
    end
end

function UnlockLevelTip:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if name == "touch_layer" then
        if self.m_showAction == false then
            self:gotoLobby()
        end
    end
end

function UnlockLevelTip:getLevelInfoList()
    local allLevels = globalData.slotRunData.p_machineDatas
    local firstOrderLevels = {}
    for k,v in ipairs(allLevels) do
        if v.p_firstOrder and v.p_highBetFlag ~= true and v.p_maintain ~= true then
            table.insert(firstOrderLevels, allLevels[k])
        end
    end

    return firstOrderLevels
end

return UnlockLevelTip