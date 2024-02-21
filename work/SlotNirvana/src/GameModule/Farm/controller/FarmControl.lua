--[[
    农场
]]
local FarmNet = require("GameModule.Farm.net.FarmNet")
local FarmGuideCtrl = require("GameModule.Farm.controller.FarmGuideControl")
local FarmControl = class("FarmControl", BaseGameControl)

function FarmControl:ctor()
    FarmControl.super.ctor(self)
    self:setRefName(G_REF.Farm)

    self.m_net = FarmNet:getInstance()
    self.m_guide = FarmGuideCtrl:getInstance()
    self.m_isClickLand = false
end

function FarmControl:getGuide()
    return self.m_guide
end

function FarmControl:triggerGuide(view, name)
    if tolua.isnull(view) or not name then
        return false
    end
    return self.m_guide:triggerGuide(view, name, G_REF.Farm)
end

function FarmControl:skipLandGuide()
    local isSave = false
    local curStepInfo = self:getGuide():getCurGuideStepInfo("FarmLandGuide")
    if curStepInfo then
        isSave = true
        curStepInfo.m_nextStep = "1109"
        self:getGuide():updateGuideRecord(curStepInfo, "FarmLandGuide", G_REF.Farm)
    end
    local curBarnStepInfo = self:getGuide():getCurGuideStepInfo("enterFarmBarn")
    if curBarnStepInfo then
        isSave = true
        curBarnStepInfo.m_nextStep = "4003"
        self:getGuide():updateGuideRecord(curBarnStepInfo, "enterFarmBarn", G_REF.Farm)
    end
    if isSave then
        -- 处理当前引导步骤存盘
        self:getGuide():saveGuideRecord()
    end
end


function FarmControl:parseData(_data)
    if not _data then
        return
    end

    local farmData = self:getData()
    if not farmData then
        farmData = require("GameModule.Farm.model.FarmData"):create()
        farmData:parseData(_data)
        farmData:setRefName(G_REF.Farm)
        self:registerData(farmData)
    else
        farmData:parseData(_data)
    end
end

-- 显示主界面
function FarmControl:showMainLayer(_isSelf, _recordsData)
    if not self:isCanShowLayer() then
        return nil
    end

    local data = self:getRunningData()
    local info = data:getInfo()
    self.m_guide:onRegist(G_REF.Farm)
    if info then
        local level = info.p_level
        if level > 2 then
            self:skipLandGuide()
        end
    end
    data:setGuideMaturityTime()

    local mainLayer = nil
    if gLobalViewManager:getViewByExtendData("Farm_MainLayer") == nil then
        mainLayer = util_createView("Views/Farm_MainLayer", _isSelf, _recordsData)
        self:showLayer(mainLayer, ViewZorder.ZORDER_UI)
        self:setClickLand(false)
    end
    return mainLayer
end

-- 显示解锁界面
function FarmControl:showUnlockLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local unlockLayer = nil
    if gLobalViewManager:getViewByExtendData("Farm_MainUnLockLayer") == nil then
        unlockLayer = util_createView("Views/Farm_MainUnLockLayer")
        self:showLayer(unlockLayer, ViewZorder.ZORDER_UI)
    end
    return unlockLayer
end

-- 显示设置名字界面
function FarmControl:showSetNameLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local setNameLayer = nil
    if gLobalViewManager:getViewByExtendData("Farm_InfoSetName") == nil then
        setNameLayer = util_createView("Views/Farm_InfoSetName")
        self:showLayer(setNameLayer, ViewZorder.ZORDER_UI)
    end
    return setNameLayer
end

-- 显示农场信息界面
function FarmControl:showFarmInfoLayer(_isSelf, _othersData)
    if not self:isCanShowLayer() then
        return nil
    end

    local infoLayer = nil
    if gLobalViewManager:getViewByExtendData("Farm_InfoLayer") == nil then
        infoLayer = util_createView("Views/Farm_InfoLayer", _isSelf, _othersData)
        self:showLayer(infoLayer, ViewZorder.ZORDER_UI)
    end
    return infoLayer
end

-- 显示仓库满了
function FarmControl:showBarnFullLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local barnFullLayer = nil
    if gLobalViewManager:getViewByExtendData("Farm_Barn_Full") == nil then
        barnFullLayer = util_createView("Views/Farm_Barn_Full")
        self:showLayer(barnFullLayer, ViewZorder.ZORDER_UI)
    end
    return barnFullLayer
end

-- 显示好友界面
function FarmControl:showFriendLayer(_params, _udid)
    if not self:isCanShowLayer() then
        return nil
    end

    local friendLayer = nil
    if gLobalViewManager:getViewByExtendData("Farm_FriendsLayer") == nil then
        friendLayer = util_createView("Views/Farm_FriendsLayer", _params, _udid)
        self:showLayer(friendLayer, ViewZorder.ZORDER_UI)
    end
    return friendLayer
end

function FarmControl:setFriendLayerVisit(_type, _udid, _steal)
    local view = gLobalViewManager:getViewByExtendData("Farm_FriendsLayer")
    if not tolua.isnull(view) then
        if _type == "hide" then
            view:setVisible(false)
            view:setLocalZOrder(-1)
        elseif _type == "show" then
            view:refreshView(_udid, _steal)
            view:setVisible(true)
            view:setLocalZOrder(ViewZorder.ZORDER_UI)
        elseif _type == "close" then
            view.m_isHideActionEnabled = false
            view:closeUI()
        end
    end
end

-- 显示仓库界面
function FarmControl:showWarehouseLayer(_isSelf)
    if not self:isCanShowLayer() then
        return nil
    end

    local mainLayer = nil
    if gLobalViewManager:getViewByExtendData("Farm_BarnLayer") == nil then
        mainLayer = util_createView("Views/Farm_BarnLayer")
        self:showLayer(mainLayer, ViewZorder.ZORDER_UI)
    end
    return mainLayer
end

-- 显示商店界面
function FarmControl:showStoreLayer(_isSelf)
    if not self:isCanShowLayer() then
        return nil
    end

    local layer = nil
    if gLobalViewManager:getViewByExtendData("Farm_ShopLayer") == nil then
        layer = util_createView("Views/Farm_ShopLayer")
        self:showLayer(layer, ViewZorder.ZORDER_UI)
    end
    return layer
end

-- 显示图鉴界面
function FarmControl:showAlmanacLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local layer = nil
    if gLobalViewManager:getViewByExtendData("Farm_Almanac") == nil then
        layer = util_createView("Views/Farm_Almanac")
        self:showLayer(layer, ViewZorder.ZORDER_UI)
    end
    return layer
end

-- 显示每日奖励领奖界面
function FarmControl:showDailyRewardLayer(_params, _cb)
    if not self:isCanShowLayer() then
        return nil
    end

    local layer = nil
    if gLobalViewManager:getViewByExtendData("Farm_RewardLayer") == nil then
        layer = util_createView("Views/Farm_RewardLayer", _params, _cb)
        self:showLayer(layer, ViewZorder.ZORDER_UI)
    end
    return layer
end

-- 显示获得种子奖励界面
function FarmControl:showSeedRewardLayer(_params, _cb)
    if not self:isCanShowLayer() then
        return nil
    end

    local layer = nil
    if gLobalViewManager:getViewByExtendData("Farm_ShopRewardLayer") == nil then
        layer = util_createView("Views/Farm_ShopRewardLayer", _params, _cb)
        self:showLayer(layer, ViewZorder.ZORDER_UI)
    end
    return layer
end

-- 显示出售作物奖励界面
function FarmControl:showSellRewardLayer(_params, _cb)
    if not self:isCanShowLayer() then
        return nil
    end

    local layer = nil
    if gLobalViewManager:getViewByExtendData("Farm_BarnRewardLayer") == nil then
        layer = util_createView("Views/Farm_BarnRewardLayer", _params, _cb)
        self:showLayer(layer, ViewZorder.ZORDER_UI)
    end
    return layer
end

-- 仓库一键售出二次确认弹板
function FarmControl:showConfirmLayer()
    if not self:isCanShowLayer() then
        return nil
    end

    local layer = nil
    if gLobalViewManager:getViewByExtendData("Farm_BarnConfirmLayer") == nil then
        layer = util_createView("Views/Farm_BarnConfirmLayer")
        self:showLayer(layer, ViewZorder.ZORDER_UI)
    end
    return layer
end

-- 提示弹板
function FarmControl:showErrorLayer(_type)
    if not self:isCanShowLayer() then
        return nil
    end

    local layer = nil
    if gLobalViewManager:getViewByExtendData("Farm_ErrorLayer") == nil then
        layer = util_createView("Views/Farm_ErrorLayer", _type)
        self:showLayer(layer, ViewZorder.ZORDER_UI)
    end
    return layer
end

-- 规则弹板
function FarmControl:showRuleLayer(_type, _index)
    if not self:isCanShowLayer() then
        return nil
    end

    local layer = nil
    if gLobalViewManager:getViewByExtendData("Farm_RuleLayer") == nil then
        layer = util_createView("Views/Farm_RuleLayer", _type, _index)
        self:showLayer(layer, ViewZorder.ZORDER_UI)
    end
    return layer
end

-- 遮罩
function FarmControl:showMaskLayer(_func)
    local mask = nil
    if gLobalViewManager:getViewByExtendData("Farm_Mask") == nil then
        mask = util_newMaskLayer()
        mask:setOpacity(0)
        mask:setName("Farm_Mask")
        mask:onTouch(
            function(event)
                return true
            end,
            false,
            true
        )
        local fadeIn = cc.FadeIn:create(0.5)
        local fadeOut = cc.FadeOut:create(0.5)
        local callfun = cc.CallFunc:create(function ()
            if _func then
                _func()
            end
        end)
        local callfunEnd = cc.CallFunc:create(function ()
            mask:removeFromParent()
        end)
        mask:runAction(cc.Sequence:create(fadeIn, callfun, fadeOut, callfunEnd))
        gLobalViewManager:showUI(mask, ViewZorder.ZORDER_POPUI)
    end
    return mask
end

-- 种植
function FarmControl:sendSowing(_cropId, _lands)
    self.m_net:sendSowing(_cropId, _lands)
end
-- 收获
function FarmControl:sendHarvest(_lands)
    self.m_net:sendHarvest(_lands)
end
-- 加速成熟
function FarmControl:sendExpedite(_landId, _gem)
    self.m_net:sendExpedite(_landId, _gem)
end
-- 出售
function FarmControl:sendSell(_wares)
    self.m_net:sendSell(_wares)
end
-- 购买
function FarmControl:sendBuySeed(_cropID, _num)
    self.m_net:sendBuySeed(_cropID, _num) 
end
-- 改名
function FarmControl:sendFarmInfoUpdate(_name)
    self.m_net:sendFarmInfoUpdate(_name)
end
-- 每日奖励
function FarmControl:sendDailyReward()
    self.m_net:sendDailyReward()
end
-- 他人农场
function FarmControl:sendOthersFarm(_othersData, _type)
    self.m_net:sendOthersFarm(_othersData, _type)
end
-- 好友列表
function FarmControl:sendFriends(_friendType, _openType, _redPoints)
    self.m_net:sendFriends(_friendType, _openType, _redPoints)
end
-- 偷菜
function FarmControl:sendSteal(_udid, _type, _landId, _initTime)
    self.m_net:sendSteal(_udid, _type, _landId, _initTime)
end
-- 偷取记录
function FarmControl:sendStealRecord(_redPoints)
    self.m_net:sendStealRecord(_redPoints)
end
-- 土地解锁
function FarmControl:sendLandUnlock(_landId)
    self.m_net:sendLandUnlock(_landId)
end
-- 新手引导
function FarmControl:sendGuide(_saveData, _type)
    self.m_net:sendGuide(_saveData, _type)
end

function FarmControl:setClickLand(_flag)
    self.m_isClickLand = _flag
end

function FarmControl:isClickLand()
    return self.m_isClickLand
end

----------------------------------------------- 打点 -----------------------------------------------
-- 引导日志
function FarmControl:sendGuideLog(guideType, guideName, guideId)
    local isLog = false
    local guideTrigger = "NewUser"
    local guideStatus = "Comple"
    if guideType <= 9 then
        local isGuiding1 = self:getGuide():isGuideGoing("enterFarmMain", G_REF.Farm)
        local isGuiding2 = self:getGuide():isGuideGoing("FarmLandGuide", G_REF.Farm)
        local isGuiding3 = self:getGuide():isGuideGoing("enterFarmBarn", G_REF.Farm)
        isLog = isGuiding1 or isGuiding2 or isGuiding3
    elseif guideType > 9 and guideType <= 10 then
        guideTrigger = "Action"
        isLog = self:getGuide():isGuideGoing("enterFarmShop", G_REF.Farm)
    elseif guideType > 10 and guideType < 12 then
        guideTrigger = "Action"
        isLog = self:getGuide():isGuideGoing("enterFarmFriend", G_REF.Farm)
    elseif guideType == 12 then
        guideTrigger = "Action"
        isLog = self:getGuide():isGuideGoing("FaemStealGuide", G_REF.Farm)
    end
    
    if isLog then
        gLobalSendDataManager:getFarmActivity():sendGuideLog(guideType, guideName, guideStatus, guideTrigger, guideId)
    end
end

-- 弹框日志
function FarmControl:sendOpenLog()
    -- 发送打点日志
    local entryName = "FarmLobby"
    local entryType = "FarmLobby"
    gLobalSendDataManager:getLogIap():setEntryType(entryType)
    gLobalSendDataManager:getLogIap():setEnterOpen("PushOpen", entryName)

    local type = "Open"
    local pageName = "FarmLobby"
    gLobalSendDataManager:getFarmActivity():sendPageLog(pageName, type)
end

-- 点击日志
function FarmControl:sendClickLog()
    -- 发送打点日志
    local entryName = "FarmLobby"
    local entryType = "FarmLobby"
    gLobalSendDataManager:getLogIap():setEntryType(entryType)
    gLobalSendDataManager:getLogIap():setEnterOpen("TapOpen", entryName)

    local type = "Click"
    local pageName = "FarmLobby"
    gLobalSendDataManager:getFarmActivity():sendPageLog(pageName, type)
end

return FarmControl
