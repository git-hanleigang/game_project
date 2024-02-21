--[[--
    fb好友邮箱列表
]]
local NetSpriteLua = require("views.NetSprite")
local InboxItem_base = util_require("views.inbox.item.InboxItem_base")
local InboxPage_clan_item = class("InboxPage_clan_item", InboxItem_base)

InboxPage_clan_item.m_nodeSize = nil --
InboxPage_clan_item.m_removeMySelf = nil
InboxPage_clan_item.m_mailData = nil
InboxPage_clan_item.m_addTouchLayer = nil
InboxPage_clan_item.m_removeTouchLayer = nil

InboxPage_clan_item.m_baseLayer = nil

local itemStepDis = 0 --两个item的间距

function InboxPage_clan_item:initUI(data)
    self.m_baseLayer = data
    InboxItem_base.initUI(self, data)

    self.m_nameLb = self:findChild("lb_name")
    self.m_headLayer = self:findChild("layer_head")
    self.m_desLb = self:findChild("lb_chipNum")

    self.m_btnNode = self:findChild("Node_btn")
    self.m_btnBackNode = self:findChild("Node_btn_back")
    self.m_btnCollectYellow = self:findChild("btn_collect_yellow")
    self.m_btnCollectSendBack = self:findChild("btn_collectsendback")

    self.m_nodeSize = self:findChild("item_bg"):getContentSize()
    self.m_nodeSize.height = self.m_nodeSize.height + itemStepDis
    self:setPositionY(itemStepDis / 2)

    self.mainClase = nil

    local label1 = gLobalLanguageChangeManager:getStringByKey("InboxPage_clan_item:btn_label1")
    local label2 = gLobalLanguageChangeManager:getStringByKey("InboxPage_clan_item:btn_label2")
    self:setButtonLabelContent("btn_collectsendback", label1)
    self:setButtonLabelContent("btn_collectsendback", label2, "label_2")
end

function InboxPage_clan_item:getCsbName()
    return "InBox/FBCard/InboxPage_Friend_item.csb"
end

function InboxPage_clan_item:initData(mailData, callFun, addTouchLayer, removeTouchLayer, mainClase)
    self.m_addTouchLayer = addTouchLayer
    self.m_removeTouchLayer = removeTouchLayer
    self.m_removeMySelf = callFun
    --界面显示
    self.m_mailData = mailData or {}
    self.mainClase = mainClase

    self:initView()
end

----------------------------------------------------------------------------------------------------
function InboxPage_clan_item:initView()
    -- self:initFBHeadIcon()
    -- self:initFBName()
    self:initDes()
    self:initButton()
end

-- FB好友头像
-- function InboxPage_clan_item:initFBHeadIcon()
--     self:startLoadFriendHead(self.m_mailData.senderHead, self.m_mailData.senderFacebookId)
-- end

-- FB好友名字
-- function InboxPage_clan_item:initFBName()
--     self.m_nameLb:setString(self.m_mailData.senderNickName)
--     self:updateLabelSize({label = self.m_nameLb, sx = 1, sy = 1}, 368)
-- end

-- FB好友赠送的物品的描述
function InboxPage_clan_item:initDes()
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
function InboxPage_clan_item:initButton()
    if self.m_mailData.type == "CARD" then
        self.m_btnNode:setVisible(true)
        self.m_btnBackNode:setVisible(false)
    elseif self.m_mailData.type == "COIN" then
        self.m_btnNode:setVisible(false)
        self.m_btnBackNode:setVisible(true)

        -- if G_GetMgr(G_REF.Inbox):getFriendRunData():isSended(self.m_mailData.type, self.m_mailData.senderFacebookId) then
        if G_GetMgr(G_REF.Inbox):getFriendRunData():isSended(self.m_mailData.type, self.m_mailData.senderUdid) then
            self.m_btnCollectSendBack:setTouchEnabled(false)
            self.m_btnCollectSendBack:setBright(false)
        else
            self.m_btnCollectSendBack:setTouchEnabled(true)
            self.m_btnCollectSendBack:setBright(true)
        end
    end
end

----------------------------------------------------------------------------------------------------
function InboxPage_clan_item:getCellSize()
    return self.m_nodeSize
end
----------------------------------------------------------------------------------------------------
-- 飞金币
function InboxPage_clan_item:flyBonusGameCoins(collectType, callback)
    local endPos = globalData.flyCoinsEndPos

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
    local baseCoins = globalData.topUICoinCount

    gLobalViewManager:pubPlayFlyCoin(startPos, endPos, baseCoins, self.m_mailData.awards.coins, callback)
end

----------------------------------------------------------------------------------------------------
function InboxPage_clan_item:sendCount()
    if self.m_baseLayer then
        self.m_baseLayer.m_isRefreshCount = self.m_baseLayer.m_isRefreshCount + 1
    end
end

function InboxPage_clan_item:recvCount()
    if self.m_baseLayer then
        self.m_baseLayer.m_isRefreshCount = self.m_baseLayer.m_isRefreshCount - 1
    end
end

-- extra: "{"mailId":2,"type":"COLLECT_BACK"}"
-- 领取奖励
-- 发送读取邮件消息-->返回成功-->发送领取奖励消息-->返回成功-->删除item
function InboxPage_clan_item:sendCollectMail(collectType)
    if self.mainClase.m_isTouchOneItem then
        return
    end
    self.mainClase.m_isTouchOneItem = true
    self.m_addTouchLayer()

    local extraData = {}
    extraData["mailId"] = self.m_mailData.id
    extraData["type"] = collectType

    self.m_isCollectMailData = false
    self:sendCount()
    G_GetMgr(G_REF.Inbox):getFriendNetwork():collectMail(
        extraData,
        function(data)
            if not tolua.isnull(self) then
                self.m_isCollectMailData = true
                -- gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_CHOOSEFRIEND_UI, {FBIdList = {self.m_mailData.senderFacebookId}})
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_CHOOSEFRIEND_UI, {FBIdList = {self.m_mailData.senderUdid}})
                if self.collectMailSuccess then
                    self:collectMailSuccess(collectType)
                end
            end
        end,
        function(data)
            if not tolua.isnull(self) then
                self.m_isCollectMailData = true
                if self.collectMailFailed then
                    self:collectMailFailed()
                end
            end
        end
    )
end

function InboxPage_clan_item:collectMailSuccess(collectType)
    self.mainClase.m_isTouchOneItem = false
    self:recvCount()

    local awards = self.m_mailData.awards
    if awards ~= nil then
        if awards.coins ~= nil and awards.coins > 0 then
            self:flyBonusGameCoins(
                collectType,
                function()
                    if CardSysManager:needDropCards("Friend Gift Mail") == true then
                        CardSysManager:doDropCards("Friend Gift Mail")
                    end
                end
            )
        elseif awards.cards ~= nil and next(awards.cards) ~= nil then
            if CardSysManager:needDropCards("Friend Gift Mail") == true then
                CardSysManager:doDropCards("Friend Gift Mail")
            end
        end
    end
    self.m_removeTouchLayer()

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

function InboxPage_clan_item:collectMailFailed()
    self.mainClase.m_isTouchOneItem = false
    self:recvCount()
    self.m_removeTouchLayer()
    --领取失败
    gLobalViewManager:showReConnect()
end
----------------------------------------------------------------------------------------------------

function InboxPage_clan_item:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

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

return InboxPage_clan_item
