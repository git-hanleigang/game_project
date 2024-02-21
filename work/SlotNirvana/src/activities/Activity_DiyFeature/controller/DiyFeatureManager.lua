--[[--
    DIY 管理器
]]
require("activities.Activity_DiyFeature.config.DiyFeatureConfig")
local DiyFeatureGuideManager = require("activities.Activity_DiyFeature.controller.DiyFeatureGuideManager")
local DiyFeatureNet = require("activities.Activity_DiyFeature.net.DiyFeatureNet")
local DiyFeatureManager = class("DiyFeatureManager", BaseActivityControl)

-- DiyFeature关卡ID
local DIY_LEVEL_ID = {
    ["10230"] = true,
    ["10231"] = true
}
-- DiyFeature主题对应关卡ID
local SLOT_LEVELID_LIST = {
    [1] = "10230",
    [2] = "10231"
}

function DiyFeatureManager:ctor()
    DiyFeatureManager.super.ctor(self)
    
    self:setRefName(ACTIVITY_REF.DiyFeature)

    self.m_netModel = DiyFeatureNet:getInstance()
    self.m_guide = DiyFeatureGuideManager:getInstance()
    -- gLobalDataManager:setStringByField("Activity_DiyFeature", "{}")
    -- gLobalDataManager:setStringByField("Activity_DiyFeature_AllOver", "false")

    self:registerListener()
    --self:addExtendResList("Activity_DiySale")
end

function DiyFeatureManager:getGuide()
    return self.m_guide
end

function DiyFeatureManager:registerListener()
    -- 进入关卡消息回调
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(target, params)
    --         local isSuc = params[1]
    --         local resultData = params[2]
    --         if isSuc == true and resultData then
    --             local resultList = cjson.decode(resultData.result)
    --             self.m_isDiyFeatureGame = resultList.diyFeatureGame or false
    --             if self.m_isDiyFeatureGame then
    --                 self:checkShowTakePartInLayer()
    --             end
    --         end
    --     end,
    --     ViewEventType.NOTIFY_GETGAMESTATUS
    -- )
end

function DiyFeatureManager:showMainLayer()
    if not self:isCanShowLayer() then
        return nil
    end
    
    if gLobalViewManager:getViewByName("DiyFeatureMainLayer") then
        return
    end

    local view = util_createView("Activity_DiyFeatureCode.DiyFeatureMainLayer")  
    if view then
        if self:willShowMainLayer() then
            self:setWillShowMainLayer(false)
        else
            G_GetMgr(ACTIVITY_REF.DiyFeature):setGameLevel()
        end
        self.m_guide:onRegist(self:getThemeName())
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function DiyFeatureManager:showRecycleLayer(_isMax, _over)
    if not self:isCanShowLayer() then
        return nil
    end
    
    if gLobalViewManager:getViewByName("DiyFeatureRecycleLayer") then
        return
    end

    local view = util_createView("Activity_DiyFeatureCode.DiyFeatureRecycleLayer", _isMax, _over)  
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

function DiyFeatureManager:showRecycleRewardLayer(_over)
    if not self:isCanShowLayer() then
        return nil
    end
    
    if gLobalViewManager:getViewByName("DiyFeatureRecycleRewardLayer") then
        return
    end

    local view = util_createView("Activity_DiyFeatureCode.DiyFeatureRecycleRewardLayer")  
    if view then
        self:showLayer(view, ViewZorder.ZORDER_UI)
    end
    return view
end

-- 关卡内首次参与 或者 二次确认 弹板
function DiyFeatureManager:checkShowTakePartInLayer()
    if not self:getIsDiyFeatureGame() then
        return nil
    end
    if self:isCanShowLayer() then
        if self:checkWillShowSecondConfirm() then
            if gLobalViewManager:getViewByExtendData("DiyFeatureFirstTakePartInLayer") then
                return nil
            end
            local view = util_createView("Activity_DiyFeatureCode.DiyFeatureFirstTakePartInLayer")
            self:showLayer(view, ViewZorder.ZORDER_UI)
            return view
        end
    end
    return nil
end

function DiyFeatureManager:doShowSeconfComfirmLayer()
    if self:isCanShowLayer() then
        if gLobalViewManager:getViewByExtendData("DiyFeatureSecondComfirmLayer") then
            return nil
        end
        local view = util_createView("Activity_DiyFeatureCode.DiyFeatureSecondComfirmLayer")
        if view then
            self:showLayer(view, ViewZorder.ZORDER_UI)
            view:setOverFunc(
                function()
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESUME_MACHINE_POPUPVIEW)
                end
            )
        end
        return view
    end
    return nil
end


function DiyFeatureManager:doShowRuleInfoLayer()
    if self:isCanShowLayer() then
        if gLobalViewManager:getViewByExtendData("DiyFeatureRuleInfoLayer") then
            return nil
        end
        local view = util_createView("Activity_DiyFeatureCode.DiyFeatureRuleInfoLayer")
        self:showLayer(view, ViewZorder.ZORDER_UI)
        return view
    end
    return nil
end

-- 活动主界面SPIN次数消耗完毕后，第一次返回关卡时弹出促销主界面
function DiyFeatureManager:setNeedcheckMLayerClosePopSaleLayer(_bCheck)
    self._bNeedcheckMLayerClosePopSaleLayer = _bCheck
end
function DiyFeatureManager:getNeedcheckMLayerClosePopSaleLayer()
    return self._bNeedcheckMLayerClosePopSaleLayer
end
function DiyFeatureManager:checkMLayerClosePopSaleLayer()
    local data = self:getRunningData()
    if not data or data:getSpinTimes() > 0 then
        return
    end

    -- cd时间内不弹
    if not data:checkMLayerClosePopSaleLayerTimeEnabled() then
        return
    end

    local bHadPop = gLobalDataManager:getBoolByField("DiyMainLayerFirstBackHadPopSale", false)
    if bHadPop then
        return
    end
    gLobalDataManager:setBoolByField("DiyMainLayerFirstBackHadPopSale", true)
    return true
end

function DiyFeatureManager:buySale(_data)
    if not _data then
        gLobalNoticManager:postNotification(DIYWheelConfig.notify_buy_sale)
        return
    end

    local goodsInfo = {}
    goodsInfo.discount = -1
    goodsInfo.goodsId = _data.p_keyId
    goodsInfo.goodsPrice = _data.p_price

    gLobalSendDataManager:getLogIap():setPayGoodsInfo(goodsInfo)
    self:sendIapLog(goodsInfo)
    --添加道具log
    local itemList = gLobalItemManager:checkAddLocalItemList(_data, {})
    gLobalSendDataManager:getLogIap():setItemList(itemList)

    gLobalSaleManager:purchaseGoods(
        DIYWheelConfig.buy_type,
        _data.p_keyId,
        _data.p_price,
        0,
        0,
        function(_result)
            local result = nil
            if _result then
                result = util_cjsonDecode(_result)
            end

            gLobalViewManager:checkBuyTipList(function ()
                gLobalNoticManager:postNotification(DIYWheelConfig.notify_buy_sale, {result = result})
            end)
        end,
        function(_errorInfo)
            gLobalNoticManager:postNotification(DIYWheelConfig.notify_buy_sale)
        end
    )
end

function DiyFeatureManager:sendIapLog(_goodsInfo)
    if not _goodsInfo then
        return
    end

    -- 商品信息
    local goodsInfo = {}
    
    goodsInfo.goodsTheme = "DIYWheelSale"
    goodsInfo.goodsId = _goodsInfo.goodsId
    goodsInfo.goodsPrice = _goodsInfo.goodsPrice 
    goodsInfo.discount = 0
    goodsInfo.totalCoins = 0
    
    -- 购买信息
    local purchaseInfo = {}
    purchaseInfo.purchaseType = "LimitBuy"
    purchaseInfo.purchaseName = "DIYWheelSale"
    purchaseInfo.purchaseStatus = "DIYWheelSale"
    gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo,purchaseInfo)
end


function DiyFeatureManager:getEntryPath(entryName)
    return "Activity_DiyFeatureCode/DiyFeatureEntryNode" 
end

function DiyFeatureManager:isCanShowEntry()
    if not DiyFeatureManager.super.isCanShowEntry(self) then
        return false
    end
    
    local isDiyFeatureGame = self:getIsDiyFeatureGame()
    if not isDiyFeatureGame then
        return false
    end

    return true
end

function DiyFeatureManager:checkWillShowSecondConfirm()
    if not self.m_showTimeStr then
        self.m_showTimeStr = gLobalDataManager:getStringByField("DiyFeature_SecondConfirm", "")
    end
    local todayTimeStr = util_formatServerTime() 
    if self.m_showTimeStr ~= todayTimeStr then
        self.m_showTimeStr = todayTimeStr
        gLobalDataManager:setStringByField("DiyFeature_SecondConfirm", todayTimeStr)
        return true
    end
    return false
end

--------------------------------------------------------- 开关消耗 金币 bet 相关-----------------------------------------------------------
-- 消耗额外金币需要实现的方法
function DiyFeatureManager:getBetExtraPercent()
    local betPercent = 0
    local data = self:getRunningData()
    if data then
        local isDiyFeatureGame = self:getIsDiyFeatureGame()
        local diyfeatureSwithcOn = self:getDiyFeatureSwitch()
        if isDiyFeatureGame and diyfeatureSwithcOn == "true" then
            betPercent = data:getExtraBetPercent()
        end
    end
    return betPercent
end

-- 是否是掉落diyfeature点数的关卡
function DiyFeatureManager:getIsDiyFeatureGame()
    local machineData = globalData.slotRunData.machineData
    if machineData and machineData.getDiyFeatureGame then
        local isDiyFeatureGame = machineData:getDiyFeatureGame()
        return isDiyFeatureGame
    end
    -- return self.m_isDiyFeatureGame
end

-- 是否是DiyFeature玩法触发的关卡 
function DiyFeatureManager:isDiyFeatureLevel(_curMachineData)
    local curMachineData = _curMachineData or globalData.slotRunData.machineData
    if curMachineData and curMachineData.p_id then
        local level_id = tostring(curMachineData.p_id)
        if DIY_LEVEL_ID[level_id] then
            return true
        end
    end
    return false
end

-- 进入DiyFeature的主题关卡ID列表
function DiyFeatureManager:getSlotLevelIdList()
    return SLOT_LEVELID_LIST
end

-- diyfeature开关 (传的必须是字符类型"true" or "false")
function DiyFeatureManager:setDiyFeatureSwitch(_val)
    local data = self:getRunningData()
    if data then
        local switchBefore = self:getDiyFeatureSwitch()
        local endTime = data:getExpireAt()
        gLobalDataManager:setStringByField("DiyfeatureSwitch" .. endTime, _val)
        if switchBefore == "false" and _val == "true" then
            self.m_mainLayerBigEnterAct = true
        end
    end
    -- bet气泡
    G_GetMgr(G_REF.BetBubbles):refreshBetBubble(ACTIVITY_REF.DiyFeature, _val == "true")    
    -- 发消息通知GameBottomNode改变bet显示
    gLobalNoticManager:postNotification(ViewEventType.NOTIFI_BET_EXTRA_COST_SWITCH, {name = ACTIVITY_REF.DiyFeature})
end

-- diyfeature开关"true" or "false"（在关卡中spin是否掉落点数） 服务器那边规定必须是字符类型不能是布尔类型
function DiyFeatureManager:getDiyFeatureSwitch()
    local data = self:getRunningData()
    if data then
        local endTime = data:getExpireAt()
        return gLobalDataManager:getStringByField("DiyfeatureSwitch" .. endTime, "false")
    end
    return "false"
end

-- diyfeature开关 是否是开着的
function DiyFeatureManager:getIsDiyFeatureSwitchOn()
    local diyfeatureSwitch = self:getDiyFeatureSwitch()
    if diyfeatureSwitch and diyfeatureSwitch == "true" then
        return true
    end
    return false
end



---------------------------------------------------------------- 关卡spin获得积分道具------------------------------------------------------------------------
-- Spin获得积分
function DiyFeatureManager:updateSlotData(pointInfo)
    pointInfo = pointInfo or {}
    if not next(pointInfo) then
        return
    end

    local activityData = self:getRunningData()
    if not activityData then
        return
    end

    activityData:updateSlotData(pointInfo)
    -- if activityData.p_criticalMult and activityData.p_criticalMult > 1 then
    --     self:onShowFlyPointLayer()
    -- end
end


-- 显示飞奖杯效果
function DiyFeatureManager:onShowFlyPointLayer()
    local activityData = self:getRunningData()
    if activityData then
        -- 获取要飞到的坐标
        local _node = gLobalActivityManager:getEntryNode(ACTIVITY_REF.DiyFeature)
        if not _node then
            return false
        end

        local flyDesPos = _node:getFlyDesPos()

        local _isVisible = gLobalActivityManager:getEntryNodeVisible(ACTIVITY_REF.DiyFeature)
        if not _isVisible then
            -- 隐藏图标的时候使用箭头坐标
            flyDesPos = gLobalActivityManager:getEntryArrowWorldPos()
        end

        if not flyDesPos then
            return false
        end

        local layer = util_createView("Activity_DiyFeatureCode.PointFly.DiyFeature_PointFlyLayer")
        self:showLayer(layer, ViewZorder.ZORDER_GUIDE, false)
        layer:playGainCupAction(flyDesPos)

        return true
    else
        return false
    end
end

--------------------------------------------------------- 请求服务器数据-----------------------------------------------------------
function DiyFeatureManager:getGuideBufLevel()
    local  actData = self:getRunningData()
    if actData then
        local bufMap = actData:getBuffsByType(1)
        return bufMap["SLOT1_WHEEL"].p_level
    end
    return 1
end

function DiyFeatureManager:requestSpinReward(callBack)
    if self._bRequestSpinning then
        return
    end
    self._bRequestSpinning = true
    self.m_spinResultBuffs = {}
    local  actData = self:getRunningData()
    if not actData then
        return
    end
    local levelMap = self:getRunningData():getRememberLevelMap()
    local buffLevel_WHEEL = self:getGuideBufLevel()
    local success_call_fun = function(resData)
        local  actData = self:getRunningData()
        if not actData then
            return
        end
        self.m_spinResultBuffs.rewardBuffs = {}
        self.m_spinResultBuffs.useBuffLvUp = false
        if resData and resData.rewardBuffs and #resData.rewardBuffs > 0 then
            for index, value in ipairs(resData.rewardBuffs) do
                local buff = {}
                buff.p_level = value.level
                buff.p_buffType = value.buffType
                buff.p_value = tonumber(value.value)
                buff.p_useBuffLvUp = not not value.useBuffLvUp
                if buff.p_level == 1 or string.find(buff.p_buffType, "ENERGY") then
                    buff.p_useBuffLvUp = false
                end
                if buff.p_useBuffLvUp then
                    self.m_spinResultBuffs.useBuffLvUp = true
                end
                if value.buffType == "SLOT1_WHEEL" then
                    buff.p_level_front = buffLevel_WHEEL
                end
                if buff.p_level~= 1 and buff.p_level == (levelMap[buff.p_buffType] or 0) then
                    buff.p_changeToFree = true
                end
                table.insert(self.m_spinResultBuffs.rewardBuffs, buff)

                if value.buffType == "SLOT1_WHEEL" and value.level == 2 and buffLevel_WHEEL == 1 then
                    local isOver_2, curStepId = G_GetMgr(ACTIVITY_REF.DiyFeature):getGuide():getGuideRecordStepId("enterDiyFeatureGame_2")
                    if not isOver_2 and value.level then
                        self:setIsInGuide(true)
                    end
                elseif value.buffType == "SLOT1_WHEEL" and value.level == 2 and buffLevel_WHEEL == 2 then
                    local isOver_3, curStepId = G_GetMgr(ACTIVITY_REF.DiyFeature):getGuide():getGuideRecordStepId("enterDiyFeatureGame_3")
                    if not isOver_3 and value.level  < 2 then
                        self:setIsInGuide(true)
                    end
                elseif value.buffType == "NORMAL_ENERGY" then 
                    local isOver_4, curStepId = G_GetMgr(ACTIVITY_REF.DiyFeature):getGuide():getGuideRecordStepId("enterDiyFeatureGame_4")
                    if not isOver_4 and value.level  < 2 then
                        self:setIsInGuide(true)
                    end
                end
            end
        end

        self.m_spinResultBuffs.nearMissBuffs = {}
        if resData and resData.nearMissBuffs and #resData.nearMissBuffs > 0 then
            for index, value in ipairs(resData.nearMissBuffs) do
                local buff = {}
                buff.p_level = value.level
                buff.p_buffType = value.buffType
                buff.p_value = tonumber(value.value)
                if value.buffType == "SLOT1_WHEEL" then
                    buff.p_level_front = buffLevel_WHEEL
                end
                table.insert(self.m_spinResultBuffs.nearMissBuffs, buff)
            end
        end
        
        self.m_spinResultBuffs.nearMissFlag = not not (resData and resData.nearMiss)

        if callBack then
            callBack()
        end
        self._bRequestSpinning = false
    end

    local faild_call_fun = function(errorCode, errorData)
        self._bRequestSpinning = false
        -- gLobalViewManager:showReConnect()
    end
    self.m_netModel:requestSpinReward(success_call_fun, faild_call_fun)
end

function DiyFeatureManager:getSpinRewardResult(isCheckNear,isForNear)
    if isCheckNear then
        local nearMissType = 0
        if #self.m_spinResultBuffs.nearMissBuffs >= 2 then
            if self.m_spinResultBuffs.nearMissBuffs[2].p_level > self.m_spinResultBuffs.nearMissBuffs[1].p_level then
                nearMissType = 2
            else
                nearMissType = 1
            end
        end
        return self.m_spinResultBuffs.nearMissFlag and nearMissType or 0
    elseif isForNear then
        return self.m_spinResultBuffs.nearMissBuffs
    else
        return self.m_spinResultBuffs.rewardBuffs
    end
end

function  DiyFeatureManager:isUseBuffLvUpThisTime()
    return not not self.m_spinResultBuffs.useBuffLvUp
end


function DiyFeatureManager:isCanShowBetBubble()
    if not DiyFeatureManager.super.isCanShowBetBubble(self) then
        return false
    end
    -- 判断是否有数据
    local act_data = self:getRunningData()
    if not act_data then
        return false
    end
    -- 判断是否有资源
    if not self:isCanShowLayer() then
        return false
    end
    -- 判断是否会掉落DiyFeature点数关卡
    local isDiyFeatureGame = self:getIsDiyFeatureGame()
    if not isDiyFeatureGame then
        return false
    end
    -- 判断当前是否是DiyFeature触发关卡
    local isDiyFeatureLevel = self:isDiyFeatureLevel() 
    if isDiyFeatureLevel then
        return false
    end
    -- 开关
    local isSwitchOn = self:getIsDiyFeatureSwitchOn()
    if not isSwitchOn then
        return false
    end    
    return true
end

function DiyFeatureManager:getBetBubblePath(_refName)
    return "BetExtraBubbleCode/" .. _refName .. "BetExtraNode"
end


-- 关卡角标点数
function DiyFeatureManager:getLevelLogoRes()
    -- 判断资源是否下载
    if not self:isDownloadRes() then
        return nil
    end
    local sign, act = util_csbCreate("Activity_DiyFeature/csd/DiyFeature_SlotsIcon.csb") 
    return sign, act
end

-- 关卡角标大小
function DiyFeatureManager:getLogoSize()
    return cc.size(55, 55)
end


-- 获取本次spin产出logo个数
function DiyFeatureManager:getSlotData()
    local act_data = self:getRunningData()
    if not act_data then
        return 0, 0
    end
    -- return #self.m_position,self.slot_point
    return 0, 0
end

-- 获取本次spin位置和点数
function DiyFeatureManager:getPointData()
    local act_data = self:getRunningData()
    if not act_data then
        return nil
    end
    return act_data:getPointData()
end

-- 清空本次spin数据
function DiyFeatureManager:clearSlotData()
    local act_data = self:getRunningData()
    if not act_data then
        return 
    end
    act_data:clearSlotData()
end

-- 特殊关卡返回 大厅标志
function DiyFeatureManager:setFreeSpinBackLobbyMark(isMark)
    self.m_isFreeSpinBackLobby = isMark
end

function DiyFeatureManager:isFreeSpinBackLobby()
    return not not self.m_isFreeSpinBackLobby
end

function DiyFeatureManager:clearFreeSpinBackLobbyMark()
    self.m_isFreeSpinBackLobby = false
end

function DiyFeatureManager:isFirstEnterGame()
    local isFrist = gLobalDataManager:getBoolByField("DiyFeatureManager_isFirstEnterGame", true)
    if isFrist then
        gLobalDataManager:setBoolByField("DiyFeatureManager_isFirstEnterGame", false)
    end
    return isFrist
end

function DiyFeatureManager:getIsMainLayerBigEnterAct(doClear)
    local result = self.m_mainLayerBigEnterAct and self:getIsDiyFeatureSwitchOn()
    if self.m_mainLayerBigEnterAct == nil then
        result = self:getIsDiyFeatureSwitchOn()
    end
    if doClear then
        self.m_mainLayerBigEnterAct = false
    end
    return result
end

function DiyFeatureManager:setIsInGuide(inGuide)
    self.m_inGuide = inGuide
    if self:isAllGuideOver() then
        self.m_inGuide = false
    end
end

function DiyFeatureManager:isInGuide()
   return not not self.m_inGuide 
end

function DiyFeatureManager:setAllGuideOver()
    self.m_guide:setAllGuideOver()
end
function DiyFeatureManager:isAllGuideOver()
    return self.m_guide:isAllGuideOver()
end

function DiyFeatureManager:setGameLevel(_info)
    self.m_gameInfo = _info
end

function DiyFeatureManager:getGameLevel()
    return self.m_gameInfo
end

--关闭玩法后进入主界面
function DiyFeatureManager:setWillShowMainLayer(isWillShow)
    self.m_isWillShow = isWillShow
end

function DiyFeatureManager:willShowMainLayer()
    return not not self.m_isWillShow
end

function DiyFeatureManager:isInDoublePointer()
    local leftTimes = 0
    local data = self:getRunningData()
    if  data then
        leftTimes = data:getDoubleSpin()
    end
    return leftTimes > 0 ,leftTimes
end


function DiyFeatureManager:isInLevelUp()
    local leftTimes = 0
    local data = self:getRunningData()
    if  data then
        leftTimes = data:getBuffLvUp()
    end
    return leftTimes > 0
end

return DiyFeatureManager
