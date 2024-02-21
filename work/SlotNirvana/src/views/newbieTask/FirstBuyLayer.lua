--首购弹版
local FirstBuyLayer = class("FirstBuyLayer", BaseLayer)

function FirstBuyLayer:initDatas()
    self:setLandscapeCsbName("GuideNewUser/FirstBuyLayer.csb")
    self:setPauseSlotsEnabled(true)
    self:setKeyBackEnabled(true)
end

function FirstBuyLayer:initUI()
    FirstBuyLayer.super.initUI(self)

    local Image_6 = self:findChild("Image_6")
    if Image_6 then
        Image_6:setVisible(false)
    end

    local lbTip = self:findChild("lb_tip")
    if lbTip then
        if globalData.GameConfig:checkABtestGroup("Novice", "C") then
            lbTip:setVisible(false)
        else
            lbTip:setVisible(true)
        end
    end

    self:runCsbAction("idle")
end

function FirstBuyLayer:toShop()
    --新手firebase打点
    globalAdjustManager:checkTriggerNPAdjustLog(AdjustNPEventType.click_shop)
    if globalFireBaseManager.sendFireBaseLogDirect then
        globalFireBaseManager:sendFireBaseLogDirect(FireBaseLogType.click_shop)
    end
    gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "FirstBuyLayerClick")

    local params = {
        shopPageIndex = 1,
        dotKeyType = "btn_collect",
        dotUrlType = DotUrlType.UrlName,
        dotIsPrep = true,
        dotEntrySite = DotEntrySite.UpView,
        dotEntryType = DotEntryType.Game
    }
    G_GetMgr(G_REF.Shop):showMainLayer(params)
    self:closeUI(false)
end

function FirstBuyLayer:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- 尝试重新连接 network
    if name == "btn_close" then
        self:closeUI(true)
    elseif name == "btn_collect" then
        self:toShop()
    end
end

function FirstBuyLayer:closeUI(isNext)
    FirstBuyLayer.super.closeUI(
        self,
        function()
            if isNext then
                gLobalNoticManager:postNotification(ViewEventType.POP_DONEXT_EVENT)
                --弹窗逻辑执行下一个事件
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_BUYTIP_CLOSE)
            end
        end
    )
end

return FirstBuyLayer
