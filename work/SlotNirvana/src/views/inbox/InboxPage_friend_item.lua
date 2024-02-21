--[[--
    fb好友邮箱列表
]]
local NetSpriteLua = require("views.NetSprite")
local InboxItem_base = util_require("views.inbox.item.InboxItem_base")
local InboxPageFriendItem = class("InboxPageFriendItem", BaseView)

InboxPageFriendItem.m_nodeSize = nil --
InboxPageFriendItem.m_removeMySelf = nil
InboxPageFriendItem.m_mailData = nil

InboxPageFriendItem.m_baseLayer = nil

local itemStepDis = 0 --两个item的间距

function InboxPageFriendItem:initUI(data)
    self.m_baseLayer = data
    InboxPageFriendItem.super.initUI(self, data)

    self.m_nameLayer = self:findChild("panel_name")
    self.m_nameLb = self:findChild("lb_name")
    self.m_headLayer = self:findChild("layer_head")
    self.m_desLb = self:findChild("lb_chipNum")

    self.m_btnNode = self:findChild("Node_btn")
    self.m_btnBackNode = self:findChild("Node_btn_back")
    self.m_btnCollectYellow = self:findChild("btn_collect_yellow")
    self.m_btnCollectSendBack = self:findChild("btn_collectsendback")

    self.m_sp_timebg = self:findChild("sp_timebg")
    self.m_lb_time = self:findChild("lb_daojishi")

    self.m_nodeSize = self:findChild("item_bg"):getContentSize()
    self.m_nodeSize.height = self.m_nodeSize.height + itemStepDis
    self:setPositionY(itemStepDis / 2)

    self.mainClase = nil

    local label1 = gLobalLanguageChangeManager:getStringByKey("InboxPageFriendItem:btn_label1")
    local label2 = gLobalLanguageChangeManager:getStringByKey("InboxPageFriendItem:btn_label2")
    self:setButtonLabelContent("btn_collectsendback", label1)
    self:setButtonLabelContent("btn_collectsendback", label2, "label_2")
end

function InboxPageFriendItem:getCsbName()
    return "InBox/FBCard/InboxPage_Friend_item.csb"
end

function InboxPageFriendItem:initData(mailData, callFun, mainClase)
    self.m_removeMySelf = callFun
    --界面显示
    self.m_mailData = mailData or {}
    self.mainClase = mainClase

    self:initView()
end

----------------------------------------------------------------------------------------------------
function InboxPageFriendItem:initView()
    self:initFBHeadIcon()
    self:initFBName()
    self:initDes()
    self:initButton()
    self:initTime()
end

-- FB好友头像
function InboxPageFriendItem:initFBHeadIcon()
    -- if self.m_mailData.senderFacebookId and self.m_mailData.senderFacebookId ~= "" then
    --     self:startLoadFriendHead(self.m_mailData.senderHead, self.m_mailData.senderFacebookId, self.m_mailData.senderFrameId)
    -- end
    self:startLoadFriendHead(self.m_mailData.senderHead, self.m_mailData.senderFacebookId, self.m_mailData.senderFrameId)
end

-- FB好友名字
function InboxPageFriendItem:initFBName()
    self.m_nameLb:setString(self.m_mailData.senderNickName)
    util_wordSwing(self.m_nameLb, 1, self.m_nameLayer, 2, 30, 2)
end

-- FB好友赠送的物品的描述
function InboxPageFriendItem:initDes()
    local des = ""
    if self.m_mailData.type == "CARD" then
        local num = 0
        local cards = self.m_mailData.awards.cards
        for k, v in pairs(cards) do
            num = num + tonumber(v)
        end
        des = "Sent you " .. num .. " Fortune Chips!"
    elseif self.m_mailData.type == "COIN" then
        des = "Sent you " .. util_formatCoins(tonumber(self.m_mailData.awards.coins), 5) .. " coins!"
    end
    self.m_desLb:setString(des)
end

-- 按钮显示
function InboxPageFriendItem:initButton()
    if self.m_mailData.type == "CARD" then
        self.m_btnNode:setVisible(true)
        self.m_btnBackNode:setVisible(false)
    elseif self.m_mailData.type == "COIN" then
        self.m_btnNode:setVisible(false)
        self.m_btnBackNode:setVisible(true)

        -- if G_GetMgr(G_REF.Inbox):getFriendRunData():isSended(self.m_mailData.type, self.m_mailData.senderFacebookId) then
        if G_GetMgr(G_REF.Inbox):getFriendRunData():isSended(self.m_mailData.type, self.m_mailData.senderUdid) then
            -- self.m_btnCollectSendBack:setTouchEnabled(false)
            -- self.m_btnCollectSendBack:setBright(false)
            self:setButtonLabelDisEnabled("btn_collectsendback", false)
        else
            -- self.m_btnCollectSendBack:setTouchEnabled(true)
            -- self.m_btnCollectSendBack:setBright(true)
            self:setButtonLabelDisEnabled("btn_collectsendback", true)
        end
    end
end

function InboxPageFriendItem:initTime()
    if self.m_lb_time then
        local expireAt = self.m_mailData.expireAt
        local time = nil
        if expireAt and expireAt ~= "" and expireAt ~= 0 then
            time = tonumber(expireAt) / 1000
        elseif self.m_mailData.validEnd then
            time = util_getymd_time(self.m_mailData.validEnd)
        end

        if time and util_leftDays(time, true) < 15 then
            local updateTimeLable = function()
                local strTime, isOver = util_daysdemaining(time, true)
                if isOver then
                    -- 渐隐效果
                    local item_bg = self:findChild("item_bg")
                    util_fadeOutNode(
                        item_bg,
                        1,
                        function()
                            --刷新界面
                            self.m_removeMySelf()
                        end
                    )
                else
                    self.m_lb_time:setString(strTime)
                end
            end
            util_schedule(self.m_lb_time, updateTimeLable, 1)
            updateTimeLable()
        else
            self:hideTime()
        end
    end
end

function InboxPageFriendItem:hideTime()
    if self.m_sp_timebg then
        self.m_sp_timebg:setVisible(false)
    end
end

----------------------------------------------------------------------------------------------------
function InboxPageFriendItem:getCellSize()
    return self.m_nodeSize
end
----------------------------------------------------------------------------------------------------
-- -- 飞金币
-- function InboxPageFriendItem:flyBonusGameCoins(collectType, callback)
--     local endPos = globalData.flyCoinsEndPos

--     local btnCollect = nil
--     if self.m_mailData.type == "CARD" then
--         btnCollect = self:findChild("btn_collect")
--     elseif self.m_mailData.type == "COIN" then
--         if collectType == "COLLECT" then
--             btnCollect = self:findChild("btn_collect_yellow")
--         elseif collectType == "COLLECT_BACK" then
--             btnCollect = self:findChild("btn_collectsendback")
--         end
--     end

--     local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
--     local baseCoins = globalData.topUICoinCount

--     gLobalViewManager:pubPlayFlyCoin(startPos, endPos, baseCoins, self.m_mailData.awards.coins, callback)
-- end

function InboxPageFriendItem:flyBonusGameCoins(collectType, _callback)
    local flyList = {}
    local btnCollect = nil
    if self.m_mailData.type == "CARD" then
        btnCollect = self:findChild("btn_collect")
    elseif self.m_mailData.type == "COIN" then
        if collectType == "COLLECT" then
            btnCollect = self:findChild("btn_collect_yellow")
        elseif collectType == "COLLECT_BACK" then
            btnCollect = self:findChild("btn_collectsendback")
        end
    end
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local coins = self.m_mailData.awards.coins
    if coins > 0 then
        table.insert(flyList, { cuyType = FlyType.Coin, addValue = coins, startPos = startPos })
    end

    if G_GetMgr("Currency") then
        G_GetMgr("Currency"):playFlyCurrency(flyList, function()
            _callback()
        end)
    end
end

----------------------------------------------------------------------------------------------------
function InboxPageFriendItem:sendCount()
    if self.m_baseLayer then
        self.m_baseLayer.m_isRefreshCount = self.m_baseLayer.m_isRefreshCount + 1
    end
end

function InboxPageFriendItem:recvCount()
    if self.m_baseLayer then
        self.m_baseLayer.m_isRefreshCount = self.m_baseLayer.m_isRefreshCount - 1
    end
end

-- extra: "{"mailId":2,"type":"COLLECT_BACK"}"
-- 领取奖励
-- 发送读取邮件消息-->返回成功-->发送领取奖励消息-->返回成功-->删除item
function InboxPageFriendItem:sendCollectMail(collectType)
    if self.mainClase.m_isTouchOneItem then
        return
    end
    self.mainClase.m_isTouchOneItem = true
    gLobalViewManager:addLoadingAnima()

    local extraData = {}
    extraData["mailId"] = self.m_mailData.id
    extraData["type"] = collectType

    self.m_isCollectMailData = false

    local senderUdid = self.m_mailData.senderUdid

    self:sendCount()
    G_GetMgr(G_REF.Inbox):getFriendNetwork():collectMail(
        extraData,
        function(data)
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_CHOOSEFRIEND_UI, {FBIdList = {senderUdid}})
            if not tolua.isnull(self) then
                self.m_isCollectMailData = true
                self:collectMailSuccess(collectType)
            end
        end,
        function(data)
            gLobalViewManager:removeLoadingAnima()
            gLobalViewManager:showReConnect()            
            if not tolua.isnull(self) then
                self.m_isCollectMailData = true
                self:collectMailFailed()
            end
        end
    )
end

function InboxPageFriendItem:collectMailSuccess(collectType)
    -- self.mainClase.m_isTouchOneItem = false
    self:recvCount()

    local awards = self.m_mailData.awards
    if awards ~= nil then
        if awards.coins ~= nil and awards.coins > 0 then
            self:flyBonusGameCoins(
                collectType,
                function()
                    if CardSysManager:needDropCards("Friend Gift Mail") == true then
                        gLobalNoticManager:addObserver(
                            self,
                            function(sender, func)
                                gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                                -- cxc 2023年12月04日10:51:50 领取好友邮件奖励后 检测运营引导弹板
                                if gLobalViewManager:getViewByName("Inbox") ~= nil then
                                    G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Friendreward", "FriendrewardGainSingle")
                                end
                            end,
                            ViewEventType.NOTIFY_CARD_SYS_OVER
                        )
                        CardSysManager:doDropCards("Friend Gift Mail")
                    else
                        -- cxc 2023年12月04日10:51:50 领取好友邮件奖励后 检测运营引导弹板
                        if gLobalViewManager:getViewByName("Inbox") ~= nil then
                            G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Friendreward", "FriendrewardGainSingle")
                        end
                    end
                end
            )
        elseif awards.cards ~= nil and next(awards.cards) ~= nil then
            if CardSysManager:needDropCards("Friend Gift Mail") == true then
                gLobalNoticManager:addObserver(
                    self,
                    function(sender, func)
                        gLobalNoticManager:removeObserver(self, ViewEventType.NOTIFY_CARD_SYS_OVER)
                        -- cxc 2023年12月04日10:51:50 领取好友邮件奖励后 检测运营引导弹板
                        if gLobalViewManager:getViewByName("Inbox") ~= nil then
                            G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Friendreward", "FriendrewardGainSingle")
                        end
                    end,
                    ViewEventType.NOTIFY_CARD_SYS_OVER
                )
                CardSysManager:doDropCards("Friend Gift Mail")
            end
        else
            -- cxc 2023年12月04日10:51:50 领取好友邮件奖励后 检测运营引导弹板
            if gLobalViewManager:getViewByName("Inbox") ~= nil then
                G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Friendreward", "FriendrewardGainSingle")
            end
        end
    end

    local btn_collect = self:findChild("btn_collect")
    btn_collect:setTouchEnabled(false)
    local btn_collect_yellow = self:findChild("btn_collect_yellow")
    btn_collect_yellow:setTouchEnabled(false)
    local btn_collectsendback = self:findChild("btn_collectsendback")
    btn_collectsendback:setTouchEnabled(false)

    -- 渐隐效果
    local item_bg = self:findChild("item_bg")
    util_fadeOutNode(
        item_bg,
        1,
        function()
            --刷新界面
            self.m_removeMySelf()
        end
    )
    -- local actionList={}
    -- actionList[#actionList+1]=cc.FadeOut:create(1)
    -- actionList[#actionList+1]=cc.CallFunc:create(function(  )
    -- end)
    -- local seq=cc.Sequence:create(actionList)
    -- item_bg:runAction(seq)  --???  3 好像是设置动画 但是设置了怎样的动画不太理解
end

--领取失败
function InboxPageFriendItem:collectMailFailed()
    self.mainClase.m_isTouchOneItem = false
    self:recvCount()
end
----------------------------------------------------------------------------------------------------

function InboxPageFriendItem:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end
    G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
    if name == "btn_collect" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendCollectMail("COLLECT")
    elseif name == "btn_collect_yellow" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendCollectMail("COLLECT")
    elseif name == "btn_collectsendback" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        self:sendCollectMail("COLLECT_BACK")
    end
end

----------------------------------------------------------------------------------------------------
function InboxPageFriendItem:startLoadFriendHead(head, fbId, frameId)
    if self.m_isInitHead then
        return
    end
    self.m_isInitHead = true

    local nodeHead = self.m_headLayer
    local fbSize = nodeHead:getContentSize()
    -- 头像切图
    nodeHead:removeAllChildren()
    local nodeAvatar = G_GetMgr(G_REF.AvatarFrame):createCommonAvatarNode(fbId, head, frameId, nil, fbSize)
    nodeHead:addChild(nodeAvatar)
    nodeAvatar:setPosition(fbSize.width * 0.5, fbSize.height * 0.5)
end

function InboxPageFriendItem:onEnter()
    InboxPageFriendItem.super.onEnter(self)

    gLobalNoticManager:addObserver(ViewEventType.NOTIFY_INBOX_SEND_SUCCESS)

    -- 实时更新按钮状态
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self) then
                self:initButton()
            end
        end,
        ViewEventType.NOTIFY_INBOX_SEND_SUCCESS
    )
end

return InboxPageFriendItem
