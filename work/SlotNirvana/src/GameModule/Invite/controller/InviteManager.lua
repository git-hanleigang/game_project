
local InviteNet = require("GameModule.Invite.net.InviteNet")
local InviteManager = class("InviteManager", BaseGameControl)
function InviteManager:ctor()
    InviteManager.super.ctor(self)
    self:setRefName(G_REF.Invite)
    self.reward_all = 0
end

function InviteManager:getConfig()
    if not self.InviteConfig then
        self.InviteConfig = util_require("GameModule.Invite.config.InviteConfig")
    end
    return self.InviteConfig
end

function InviteManager:getData()
    return globalData.inviteData
end

function InviteManager:showInviteeLayer(params)
    if not self:isCanShowLayer() then 
        return
    end
    local InviteeMainUI = nil
    if gLobalViewManager:getViewByExtendData("Activity_Invitee") == nil then
        InviteeMainUI = util_createFindView("views/Invite/Activity/Activity_Invitee", params)
        if InviteeMainUI ~= nil then
           if gLobalSendDataManager.getLogFeature ~= nil then
                gLobalSendDataManager:getLogFeature():sendInviteLog("Open","Invitee","btn_invitee")
            end
            gLobalViewManager:showUI(InviteeMainUI,ViewZorder.ZORDER_UI)
        end
    end
    return InviteeMainUI
end

function InviteManager:showInviterLayer(actType)
    if not self:isCanShowLayer() then 
        return
    end
    if globalData.userRunData.levelNum < globalData.constantData.INVITE_LEVEL then
        self:showLeveUp()
        return
    end
    local InviterMainUI = nil
    if gLobalViewManager:getViewByExtendData("Activity_Inviter") == nil then
        InviterMainUI = util_createFindView("views/Invite/Activity/Activity_Inviter")
        if InviterMainUI ~= nil then
            if gLobalSendDataManager.getLogFeature ~= nil then
                local name = "btn_inviter"
                if actType ~= nil then
                    name = actType
                end
                gLobalSendDataManager:getLogFeature():sendInviteLog("Open","Inviter",actType)
            end
            gLobalViewManager:showUI(InviterMainUI,ViewZorder.ZORDER_UI)
        end
    end
    return InviterMainUI
end

function InviteManager:shareRewardLayer(coins)
    if not self:isCanShowLayer() then 
        return
    end
    local InviterReward = nil
    if gLobalViewManager:getViewByExtendData("InviteRewardLayer") == nil then
        InviterReward = util_createFindView("views/Invite/Activity/InviteRewardLayer")
        if InviterReward ~= nil then
            gLobalViewManager:showUI(InviterReward,ViewZorder.ZORDER_UI)
        end
    end
    return InviterReward
end

function InviteManager:showGuideLayer(_type,node_list)
    if not self:isCanShowLayer() then 
        return
    end
    local InvitaGuide = nil
    if gLobalViewManager:getViewByExtendData("InvitaGuide") == nil then
        InvitaGuide = util_createFindView("views/Invite/Activity/InvitaGuide")
        if InvitaGuide ~= nil then
            InvitaGuide:setPosData(_type)
            if _type == 2 then
                InvitaGuide:setGuideRNodes(node_list)
            else
                InvitaGuide:setGuideRefNodes(node_list)
            end
            
            --gLobalViewManager:showUI(InvitaGuide,ViewZorder.ZORDER_UI)
        end
    end
    return InvitaGuide
end

function InviteManager:showUrgeLayer()
    if not self:isCanShowLayer() then 
        return
    end
    local InviterUrge = nil
    if gLobalViewManager:getViewByExtendData("InviterUrge") == nil then
        InviterUrge = util_createFindView("views/Invite/Activity/InviterUrge")
        if InviterUrge ~= nil then
            gLobalViewManager:showUI(InviterUrge,ViewZorder.ZORDER_UI)
        end
    end
    return InviterUrge
end

function InviteManager:showPromoLayer()
    if not self:isCanShowLayer() then 
        return
    end
    local Activity_Invite = nil
    if gLobalViewManager:getViewByExtendData("Activity_Invite") == nil then
        Activity_Invite = util_createFindView("views/Invite/Activity/Activity_Invite")
        if Activity_Invite ~= nil then
            gLobalViewManager:showUI(Activity_Invite,ViewZorder.ZORDER_UI)
        end
    end
    return Activity_Invite
end

function InviteManager:showInviteeTips()
    if not self:isCanShowLayer() then 
        return
    end
    local Activity_Invite = nil
    if gLobalViewManager:getViewByExtendData("InviteeTips") == nil then
        Activity_Invite = util_createFindView("views/Invite/Activity/InviteeTips")
        if Activity_Invite ~= nil then
            gLobalViewManager:showUI(Activity_Invite,ViewZorder.ZORDER_UI)
        end
    end
    return Activity_Invite
end

function InviteManager:showTips()
    if not self:isCanShowLayer() then 
        return
    end
    local Activity_Invite = nil
    if gLobalViewManager:getViewByExtendData("InviteTip") == nil then
        Activity_Invite = util_createFindView("views/Invite/Activity/InviteTip")
        if Activity_Invite ~= nil then
            gLobalViewManager:showUI(Activity_Invite,ViewZorder.ZORDER_UI)
        end
    end
    return Activity_Invite
end

function InviteManager:showLeveUp()
    if not self:isCanShowLayer() then 
        return
    end
    local Activity_Invite = nil
    if gLobalViewManager:getViewByExtendData("InviteLevel") == nil then
        Activity_Invite = util_createFindView("views/Invite/Activity/InviteLevel")
        if Activity_Invite ~= nil then
            gLobalViewManager:showUI(Activity_Invite,ViewZorder.ZORDER_UI)
        end
    end
    return Activity_Invite
end

function InviteManager:shareInvite(_type,pos)
    local platform = device.platform
    if platform == "ios" then
        if not util_isSupportVersion("1.7.3") then
            xcyy.GameBridgeLua:rateUsForSetting()
            return
            --cc.Application:getInstance():openURL("itms-apps://itunes.apple.com/app/id1480805172?action=write-review")
        end
    elseif platform == "android" then
        if not util_isSupportVersion("1.6.5") then
            xcyy.GameBridgeLua:rateUsForSetting()
            return
        end
    end
    local title = "拉新邀请"
    local content = "Come Play With Me! Cash Tornado Slots: https://link.topultragame.com/cashlink_common?param="
    local Callback = function(_data)
        release_print("=======>>> share Callback: ")
        gLobalViewManager:removeLoadingAnima()
        local result = util_cjsonDecode(_data)
        if result.flag == 1 then
            if gLobalSendDataManager.getLogFeature ~= nil then
                local name = "btn_share"
                local s = "share"
                gLobalSendDataManager:getLogFeature():sendInviteLog("Invite",nil,name,s)
            end
            --成功 暂时去掉
            -- if self:getRunningData():getShare() == false and self:getRunningData():getIsReward() == false then
            --      self:sendReciveReq()
            -- end
        else
        end
    end
    local info = {}
    local str = "id="..globalData.userRunData.loginUserData.displayUid..",type="..globalPlatformManager.SHARE_TYPE.INVITE
    content = content..str
    info = {content = content,start_x = pos.x,start_y = pos.y}
    gLobalViewManager:addLoadingAnima(false,0,5)
    globalPlatformManager:sendFuncMsg(_type,info,Callback)
end
--分享领取
function InviteManager:sendReciveReq()
    local successCallback = function (_data)
        self:getData():setShareCoin(_data.coins)
        self:getData():setShare(true)
        self:shareRewardLayer()
    end

    local failedCallback = function (errorCode, errorData)
    end
    InviteNet:getInstance():sendReciveReq(successCallback,failedCallback)
end
--获取整体数据
function InviteManager:sendDataReq(tag)
    local successCallback = function (_data)
        self:getData():parseData(_data)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_INVITE_MAIN)
        gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.INVITEE_UPDATA_PAY)
        if tag then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_INBOX_UPDATE_LOCAL_MAIL)
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT, G_GetMgr(G_REF.Inbox):getMailCount())
        end
    end
    local failedCallback = function (errorCode, errorData)
    end
    InviteNet:getInstance():sendInviteDataReq(successCallback,failedCallback)
end
--邀请者领奖 _type:0,人数领奖，1付费领奖，value,领取的级别
function InviteManager:sendInviterRew(_type,_value,_item,_coins)   
    local successCallback = function (_data)
        --dump(_data)
        self:getData():parseData(_data)
        local params = {}
        params.type = _type
        params.item = _item
        params.coins = _coins
        gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.INVITER_REWARD_COLLECT,params)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = G_REF.Invite})
    end
    local failedCallback = function (errorCode, errorData)
        
    end
    InviteNet:getInstance():sendInviterRew(successCallback,failedCallback,_type,_value)
end

--被邀请者领奖 _type:0,免费，1付费，level,领取的级别
function InviteManager:sendInviteeRew(_type,_level,item)   
    local successCallback = function (_data)
        self.m_propsBagist = {}
        self:getData():parseData(_data)
        local item_list = {}
        local coin_num = nil
        if _type == "2" then
            if #item.prop > 0 then
                item_list = item.prop
                coin_num = item.coin_num
            end
        else
            item_list[1] = item
            coin_num = item.coins
        end
        local call = function()
            if CardSysManager:needDropCards("Invite") == true then
                CardSysManager:doDropCards(
                    "Invite",
                    function()
                        self:triggerPropsBagView()
                    end
                )
            else
                self:triggerPropsBagView()
            end
        end
        for i,v in ipairs(item_list) do
            if v and v.p_icon then
                if string.find(v.p_icon, "Pouch") then
                    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
                    mergeManager:refreshBagsNum(v.p_icon, v.p_num)
                    table.insert(self.m_propsBagist, v)
                end
            end
        end
        local rewardLayer = gLobalItemManager:createRewardLayer(item_list, call, coin_num, true)
        gLobalViewManager:showUI(rewardLayer, ViewZorder.ZORDER_UI)
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_DATA_REFRESH, {name = G_REF.Invite})
        gLobalNoticManager:postNotification(self:getConfig().EVENT_NAME.INVITEE_UPDATA_PAY)
    end
    local failedCallback = function (errorCode, errorData)
    end
    InviteNet:getInstance():sendInviteeRew(successCallback,failedCallback,_level,_type)
end

function InviteManager:triggerPropsBagView()
    local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
    mergeManager:popMergePropsBagRewardPanel(self.m_propsBagist, function()
    end)
end

--同意邀请 uid
function InviteManager:sendLinkReq(_uid,_type) 
    local successCallback = function (_data)
        if _data then
            local first_invite = gLobalDataManager:getNumberByField("first_invite", 1)
            if first_invite == 1 then
                --玩家首次进入
                self:getData():setIsFirst(true)
                gLobalDataManager:setNumberByField("first_invite", 2)
                if gLobalPopViewManager:isPopView() then
                else
                    if globalNoviceGuideManager:getIsFinish(NOVICEGUIDE_ORDER.initIcons.id) then --新用户
                        self:showInviteeTips()
                    end
                end
            end
        else
            if globalData.userRunData.levelNum > globalData.constantData.INVITE_LEVEL then
                self:getData():setIsOut(true)
                if gLobalPopViewManager:isPopView() then
                else
                    self:showTips()
                end
            end
        end
        self:sendDataReq()
    end
    local failedCallback = function (errorCode, errorData)
    end

    InviteNet:getInstance():sendInviteLinkReq(successCallback,failedCallback,_uid)
end

--购买
function InviteManager:buyGoods()
    local data = self:getData():getInviteeReward()
    local saleData = {key = data.key,keyId = data.keyId, price = data.price}
    self:sendIapLog(saleData)
    gLobalSaleManager:purchaseGoods(
        BUY_TYPE.INVITEE_BUY_TYPE,
        data.key,
        data.price,
        0,
        0,
        function()
            self:buySuccess()
        end,
        function()
        end
    )
end
function InviteManager:buySuccess()
    gLobalViewManager:checkBuyTipList(function()
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_ACTIVITY_INVITE_BUY_SUCCESS)
    end)
end
-- 客户端打点
function InviteManager:sendIapLog(_goodsInfo)
    if _goodsInfo ~= nil then
        -- 商品信息
        local goodsInfo = {}

        goodsInfo.goodsTheme = "Invite"
        goodsInfo.goodsId = _goodsInfo.key
        goodsInfo.goodsPrice = _goodsInfo.price
        goodsInfo.discount = 0
        goodsInfo.totalCoins = 0

        -- 购买信息
        local purchaseInfo = {}
        purchaseInfo.purchaseType = "LimitBuy"
        purchaseInfo.purchaseName = "InvitePass"
        local actData = G_GetMgr(G_REF.Invite):getData()
        if not actData then
            return
        end
        purchaseInfo.purchaseStatus = "InvitePass"

        gLobalSendDataManager:getLogIap():openIapLogInfo(goodsInfo, purchaseInfo, nil, nil, self)
    end
end

function InviteManager:getInviteeItems()
    local f_data = self:getData():getInviteeFree()
    local p_data = self:getData():getInviteePay()
    local item_data = {}
    local all = 1
    for i,v in ipairs(f_data) do
        local item = {}
        item.free = v
        local last_level = 0
        if f_data[i-1] ~= nil then
            last_level = f_data[i-1].value
        end
        local force_level = 0
        if f_data[i+1] ~= nil then
            force_level = f_data[i+1].value
        end
        item.parent = self:getPercent(last_level,v.value,force_level)
        if p_data[i] ~= nil then
            item.pay = p_data[i]
        end
        if v.collect ==false or item.pay.collect == false then
            all = 0
        end
        table.insert(item_data,item)
    end
    self.reward_all = all
    return item_data
end
function InviteManager:getPercent(last_level,level,force_level)
    local my_level = globalData.userRunData.levelNum - self:getData():getLevel()
    local q_per = 0
    if my_level >= level then
        q_per = 0.5
        if force_level ~= 0 then
            q_per = q_per + (my_level-level)/(force_level-level)
        else
            q_per = q_per + (my_level-level)/(level-last_level)
        end
    else
        if last_level ~= 0 then
            local miss_level = (level - last_level)/2 + last_level
            if my_level <= miss_level then
                q_per = 0
            else
                local di = (level - last_level)
                q_per = (my_level-miss_level)/di
            end
        else
            q_per = (my_level/level)/2
        end
    end
    return q_per
end

function InviteManager:getRewardAll()
    return self.reward_all
end


function InviteManager:getMail()
    local data = self:getData():getMailCount()
    if data == nil and #data == 0 then
        return
    end
    local mail_str = gLobalDataManager:getStringByField("invite_Mail")
    local mail_data = {}
    if mail_str ~= nil and mail_str ~= "" then
        local loacl_Data = cjson.decode(mail_str)
        for i=1,#data do
            local item = data[i]
            local tag = 1
            for j=1,#loacl_Data do
                local item1 = loacl_Data[j]
                if item1.id == item.id then
                    if item1.collect ~= nil then
                        tag = 0
                    end
                end
            end
            if tag == 1 then
                table.insert(mail_data,item)
            end
        end
    else
        mail_data = data
    end
    return mail_data
end

function InviteManager:getAllCollect()
    local f_data1 = self:getData():getInviteeFree()
    local p_data1 = self:getData():getInviteePay()
    local f_data = clone(f_data1)
    local p_data = clone(p_data1)
    local intee_data = self:getData():getInviteeReward()
    local my_level = globalData.userRunData.levelNum - self:getData():getLevel()
    local collect_item = {}
    local coin_data = {}
    local prop_data = {}
    local coin_num = 0
    for i,v in ipairs(f_data) do
        if my_level >= v.value then
            local x = 1
            if not v.collect then
                if v.coins > 0 then
                    table.insert(coin_data,v)
                    coin_num = coin_num + v.coins
                else
                    local index = self:composeItem(prop_data,v)
                    if index then
                        prop_data[index].p_num = prop_data[index].p_num + v.p_num
                    else
                        table.insert(prop_data,v)
                    end
                end
            end
            if intee_data and intee_data.pay then
                if not p_data[i].collect then
                    if p_data[i].coins > 0 then
                        table.insert(coin_data,p_data[i])
                        coin_num = coin_num + p_data[i].coins
                    else
                        local index = self:composeItem(prop_data,p_data[i])
                        if index then
                            prop_data[index].p_num = prop_data[index].p_num + p_data[i].p_num
                        else
                            table.insert(prop_data,p_data[i])
                        end
                    end
                end
            end  
         end
    end
    if #coin_data > 0 then
        local itme_1 = coin_data[1]
        itme_1.coins = coin_num
        itme_1.p_num = coin_num
        table.insert(prop_data,itme_1)
    end
    collect_item.prop = prop_data
    collect_item.coin_num = coin_num
    return collect_item
end

function InviteManager:composeItem(_data,item)
    local index = nil
    for i,v in ipairs(_data) do
        if item.p_id == v.p_id then
            index = i
            break
        end
    end
    return index
end

function InviteManager:getHistoryItem()
    local item = 1
    local f_data = self:getData():getInviteeFree()
    local my_level = globalData.userRunData.levelNum - self:getData():getLevel()
    for i,v in ipairs(f_data) do
        if my_level <= v.value then
            item = i
            break
        end
    end
    return item
end

function InviteManager:getInviteeVs()
    local tm = 0
    local invite_Data = self:getData():getInviteeReward()
    if invite_Data ~= nil and invite_Data.pay == true then
        tm = 1
    end
    local item = self:getData():getInviteeFree()
    if not item or #item == 0 then
        return true
    end
    local value = item[#item].value
    local my_level = globalData.userRunData.levelNum - self:getData():getLevel()
    local tm1 = 0
    if my_level >= value then
        tm1 = 1
    end
    local all_rew = self:getAllCollect()
    local tm2 = 0
    if all_rew.coin_num == 0 and #all_rew.prop == 0 then
        tm2 = 1
    end
    if tm == 1 and tm1 == 1 and tm2 == 1 then
        return false
    else
        return true
    end
end

return InviteManager
