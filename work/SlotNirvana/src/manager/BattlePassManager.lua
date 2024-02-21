local BattlePassManager = class("BattlePassManager")
local NetWorkBase = util_require("network.NetWorkBase")
local ShopItem = util_require("data.baseDatas.ShopItem")
BattlePassManager._instance = nil
-- FIX IOS 139

function BattlePassManager:getInstance()
    if BattlePassManager.m_instance == nil then
        BattlePassManager.m_instance = BattlePassManager.new()
    end
    return BattlePassManager.m_instance
end

function BattlePassManager:ctor()
end

--
function BattlePassManager:getIsMaxLevel()
    local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    if not bpData then
        return false
    end
    -- 计算当前是否满级 做处理
    if bpData:getLevel() >= bpData:getMaxLevel() then
        return true
    end

    return false
end

function BattlePassManager:getItemsType(ID)
    -- 这里需要做的是 对发放下的道具ID进行本地判断,返回Type
    if ID then
        if tonumber(ID) == 300 or tonumber(ID) == 301 or tonumber(ID) == 302 or tonumber(ID) == 302 then
            return "coupon"
        elseif tonumber(ID) == 108 then
            return "hightClub"
        end
    end
    return nil
end

function BattlePassManager:getIsOpen()
    local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    local openLevel = globalData.constantData.BATTLEPASS_OPEN_LEVEL or 25 --解锁等级
    if bpData and bpData:isRunning() and globalData.userRunData.levelNum >= openLevel and not globalDynamicDLControl:checkDownloading(ACTIVITY_REF.BattlePass) then
        return true
    end

    return false
end

function BattlePassManager:getInBuffTime()
    local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    if not bpData then
        return false
    end
    local buffTimeLeft = globalData.buffConfigData:getBuffLeftTimeByType(BUFFTYPY.BUFFTYPE_BATTLEPASS_BOOSTER)
    if buffTimeLeft <= 0 or bpData:getLevel() >= bpData:getMaxLevel() then
        return false
    else
        return true
    end
    return false
end

function BattlePassManager:getInGuide()
    local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    if not bpData then
        return false
    end

    if bpData:getGuideIndex() == -1 then
        -- 当前引导已经结束了
        return false
    end

    return true
end

function BattlePassManager:initBPNode(bpNode, pInfoPBNode, pPrice, pVipPoints)
    self:initLuckyStampNode(
        bpNode,
        function()
            self:initBPInfoNode(bpNode, pInfoPBNode, pPrice, pVipPoints)
        end
    )
end

function BattlePassManager:removeInfoPbNode(pInfoPBNode)
    if pInfoPBNode then
        pInfoPBNode:removeFromParent()
        pInfoPBNode = nil
    end
end

function BattlePassManager:initLuckyStampNode(bpNode, callback)
    local data = G_GetMgr(G_REF.LuckyStamp):getData()
    if not data then
        if callback then
            callback()
        end
        return
    end
    local tipNode = G_GetMgr(G_REF.LuckyStamp):createLuckyStampTip(callback)
    if tipNode then
        bpNode:addChild(tipNode, 1)
    end
end

------------新增提示功能
function BattlePassManager:initBPInfoNode(bpNode, pInfoPBNode, pPrice, pVipPoints)
    if pInfoPBNode then
        return
    end
    --创建提示节点
    local saleData = {p_price = pPrice, p_vipPoint = pVipPoints}
    local infoPBnode = gLobalItemManager:createInfoPBNode(saleData, nil, nil, "BattlePass")
    if infoPBnode then
        bpNode:addChild(infoPBnode, 1)
        pInfoPBNode = infoPBnode
    end
end

function BattlePassManager:checkClickFuncPos(sender)
    local beginPos = sender:getTouchBeganPosition()
    local endPos = sender:getTouchEndPosition()
    local offx = math.abs(endPos.x - beginPos.x)
    if offx < 10 and globalData.slotRunData.changeFlag == nil then
        return true
    end
    return false
end

function BattlePassManager:checkPopViewCD(_popViewKey, _popViewCD)
    local lastPopTime = gLobalDataManager:getNumberByField(_popViewKey, 0)
    local currTime = math.floor(globalData.userRunData.p_serverTime / 1000)
    local dis = currTime - lastPopTime
    if dis >= _popViewCD then
        gLobalDataManager:setNumberByField(_popViewKey, currTime)

        return true
    end
    return false
end

-- 领取成功
function BattlePassManager:collectCallBack(_success, _resultData, _level, _type, _collectAll)
    if _success then
        printInfo("--领取宝箱成功！！")
        local boxSucInfo = {
            level = _level,
            boxType = _type == 0 and "FreeBox" or "PayBox"
        }
        if _type == 0 then
            -- 发送给 guide 移除
            gLobalNoticManager:postNotification(ViewEventType.EVENT_BATTLE_PASS_REMOVE_GUIDE, {maskZorder = true, nextStep = true})
        end
        if _collectAll then
            gLobalNoticManager:postNotification(ViewEventType.EVENT_BATTLE_PASS_COLLECTALL)
        end
        self:gainRewardSuccess(_resultData, not _collectAll and boxSucInfo or nil)
    else
        printInfo("--领取宝箱失败！！")
    end
end

-- 处理领取成功
function BattlePassManager:gainRewardSuccess(resultData, boxSucInfo)
    local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    if not bpData then
        return
    end
    local _reward = nil
    if resultData:HasField("result") == true then
        _reward = util_cjsonDecode(resultData.result)
    end

    if not _reward or _reward.collectResult then
        return
    end

    if _reward.items ~= nil then
        local itemData = {}
        for i = 1, #_reward.items do
            local shopItem = ShopItem:create()
            shopItem:parseData(_reward.items[i], true)
            itemData[i] = shopItem
        end
        _reward.items = itemData
    end

    self:openRewardLayer(_reward, boxSucInfo)
end

function BattlePassManager:openRewardLayer(_reward, _boxSucInfo)
    local view = util_createView("Activity.BattlePassCode.BattlePassRewardLayer", _reward, _boxSucInfo)
    gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
end

function BattlePassManager:getIsDailyMissionLayerPopView()
    -- 每次打开界面, 引导玩家购买解锁
    if not self:getIsOpen() then
        return false
    end

    -- 玩家没有解锁/不在引导内/已经满级
    if self:getIsUnlocked() == false and self:getInGuide() == false and self:getIsMaxLevel() then
        if self:checkPopViewCD("openDailyMissionLayerPopUnlock", 1800) then
            return true
        end
    end

    return false
end

function BattlePassManager:openUnlockRewardLayer()
    local uiView = util_createView("Activity.BattlePassCode.BattlePassUnlockRewardLayer")
    gLobalViewManager:showUI(uiView, ViewZorder.ZORDER_UI)
end

function BattlePassManager:getIsUnlocked()
    local bpData = G_GetActivityDataByRef(ACTIVITY_REF.BattlePass)
    if not bpData then
        return false
    end

    return bpData:isUnlocked()
end
---------------------------------- 网络协议迁移 ------------------------------------
-- 领取BattlePass奖励
function BattlePassManager:sendActionBattlePassCollect(_level, _type, _collectAll)
    if gLobalSendDataManager:isLogin() == false then
        return
    end
    local params = {
        success = false,
        resultData = nil
    }
    gLobalViewManager:addLoadingAnima()
    -- 处理回调
    local success = function(target, resultData)
        gLobalViewManager:removeLoadingAnima()
        params.success = true
        params.resultData = resultData
        self:collectCallBack(true, resultData, _level, _type, _collectAll)

        -- gLobalNoticManager:postNotification(ViewEventType.EVENT_BATTLE_PASS_COLLECT_BOX_CALLBACK,params)
    end
    local fail = function(errorCode, errorData)
        gLobalViewManager:removeLoadingAnima()
        -- gLobalNoticManager:postNotification(ViewEventType.EVENT_BATTLE_PASS_COLLECT_BOX_CALLBACK,params)
        self:collectCallBack(false, nil, _level, _type, _collectAll)
    end

    -- 组装数据发送
    local actionData = NetWorkBase:getSendActionData(ActionType.BattlePassCollect)
    local params = {}
    params["level"] = _level
    params["type"] = _type
    actionData.data.params = json.encode(params)

    NetWorkBase:sendMessageData(actionData, success, fail)
end

-- BattlePass 引导进度打点
function BattlePassManager:sendActionBattlePassGuideStep(index)
    if gLobalSendDataManager:isLogin() == false then
        return
    end

    local actionData = NetWorkBase:getSendActionData(ActionType.BattlePassGuide)
    local params = {}

    params["BattlePassGuide"] = index
    actionData.data.params = json.encode(params)

    NetWorkBase:sendMessageData(actionData, nil, nil)
end

return BattlePassManager
