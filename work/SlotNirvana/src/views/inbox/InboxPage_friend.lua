--[[--
    邮件页签-friend
    好友发送的邮件列表
]]
local InboxPage_collectBase = util_require("views.inbox.InboxPage_collectBase")
local InboxPage_friend = class("InboxPage_friend", InboxPage_collectBase)

function InboxPage_friend:initUI(mainClass)
    InboxPage_collectBase.initUI(self, mainClass)
    self.m_list:setScrollBarEnabled(false)
    self.m_btnCollectAll = self:findChild("btn_collectAll")
    -- self.img_bg = self:findChild("img_bg")
end

function InboxPage_friend:getCsbName()
    return "InBox/FBCard/InboxPage_Friend.csb"
end

function InboxPage_friend:getFBMailData()
    return G_GetMgr(G_REF.Inbox):getFriendRunData():getMailData()
end

function InboxPage_friend:getClanMailData()
    return G_GetMgr(G_REF.Inbox):getFriendRunData():getClanCardData()
end

function InboxPage_friend:getAllMailData()
    local allMail = {}
    local fbMail = self:getFBMailData()
    local clanMail = self:getClanMailData()
    allMail = clone(fbMail)
    table.insertto(allMail, clanMail, #allMail)
    return allMail
end

function InboxPage_friend:getList()
    return self:findChild("ListView")
end

function InboxPage_friend:updataInboxItem()
    InboxPage_collectBase.updataInboxItem(self)

    -- 隐藏collectall按钮，并且将背景图拉到底部
    local count = self:getCount()
    if count == 0 then
        -- self.img_bg:setContentSize(cc.size(933, 539))
        self.m_btnCollectAll:setVisible(false)
    else
        -- self.img_bg:setContentSize(cc.size(933, 456))
        self.m_btnCollectAll:setVisible(true)
    end
end

-- 创建item
function InboxPage_friend:createItemCell()
    local fbMailData = self:getFBMailData()
    for i = 1, #fbMailData do
        self:initCellItem("views.inbox.InboxPage_friend_item", true, fbMailData[i])
    end

    local clanMailData = self:getClanMailData()
    for i = 1, #clanMailData do
        self:initCellItem("views.inbox.InboxPage_friend_item", true, clanMailData[i])
    end
end

function InboxPage_friend:initCellItem(name, initFlag, mailData)
    local cell = util_createView(name, self)
    if cell:isCsbExist() then
        if initFlag then
            cell:initData(
                mailData,
                function()
                    if not tolua.isnull(self) then
                        self.m_isTouchOneItem = false
                        self:updataInboxItem()
                    end
                end,
                self
            )
        end
        local layout = ccui.Layout:create()
        local cellSize = cell:getCellSize()
        layout:setContentSize({width = cellSize.width, height = cellSize.height})
        layout:addChild(cell)
        cell:setPosition(0, 0)
        self.m_list:pushBackCustomItem(layout)
    end
end

function InboxPage_friend:canCollectAll()
    -- local fbMailData = self:getFBMailData()
    -- if #fbMailData == 0 then
    --     return false
    -- end

    -- local clanMailData = self:getClanMailData()
    -- if #clanMailData == 0 then
    --     return false
    -- end

    local mailData = self:getAllMailData()
    if #mailData == 0 then
        return false
    end

    return true
end

-- 领取所有邮件
function InboxPage_friend:requestCollectAllMail(success, fail)
    local FBIdList = {}
    local allCoins = 0
    local isDrop = false
    local mailsData = G_GetMgr(G_REF.Inbox):getFriendRunData():getMailData()
    if mailsData and #mailsData > 0 then
        for i = 1, #mailsData do
            if mailsData[i].awards then
                if mailsData[i].awards.coins and mailsData[i].awards.coins ~= "" and mailsData[i].awards.coins ~= 0 then
                    allCoins = allCoins + tonumber(mailsData[i].awards.coins)
                end
                if mailsData[i].awards.cards and next(mailsData[i].awards.cards) ~= nil then
                    isDrop = true
                end
            end
            -- 如果是送金币，并且没有被玩家送过的，需要加入列表
            -- 因为一键领取默认使用sendback，需要从选择列表中删除
            -- if mailsData[i].type == "COIN" and not G_GetMgr(G_REF.Inbox):getFriendRunData():isSended(mailsData[i].type, mailsData[i].senderFacebookId) then
            --     FBIdList[#FBIdList + 1] = mailsData[i].senderFacebookId
            -- end
            if mailsData[i].type == "COIN" and not G_GetMgr(G_REF.Inbox):getFriendRunData():isSended(mailsData[i].type, mailsData[i].senderUdid) then
                FBIdList[#FBIdList + 1] = mailsData[i].senderUdid
            end
        end
    end

    local clanMail = self:getClanMailData()
    if clanMail and #clanMail > 0 then
        isDrop = true
    end

    if self.m_isTouchOneItem then
        return
    end
    self.m_isTouchOneItem = true

    local function successFunc()
        if gLobalViewManager:getViewByName("Inbox") ~= nil then
            -- 邮箱关闭  可能弹出了其他界面 弹出其他系统 不要监测 引导弹板了
            -- cxc 2023年12月04日10:51:50 领取好友邮件奖励后 检测运营引导弹板
            local view = G_GetMgr(G_REF.OperateGuidePopup):checkPopGuideLayer("Friendreward", "FriendrewardGainAll")
            if view then
                view:setOverFunc(function()
                    if success then
                        success()
                    end
                end)
            else
                if success then
                    success()
                end
            end
        elseif success then
            success()
        end

        self.m_isTouchOneItem = false
    end

    local function failFunc()
        if fail then
            fail()
        end
        self.m_isTouchOneItem = false
    end

    local extraData = {}
    extraData["type"] = "COLLECT_ALL"
    gLobalViewManager:addLoadingAnimaDelay()
    G_GetMgr(G_REF.Inbox):getFriendNetwork():collectMail(
        extraData,
        function(result)
            gLobalViewManager:removeLoadingAnima()
            if not tolua.isnull(self) then
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_CHOOSEFRIEND_UI, {FBIdList = FBIdList})
                if allCoins > 0 then
                    local endPos = globalData.flyCoinsEndPos
                    local btnCollect = self.m_btnCollectAll
                    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
                    local baseCoins = globalData.topUICoinCount
                    gLobalViewManager:pubPlayFlyCoin(
                        startPos,
                        endPos,
                        baseCoins,
                        allCoins,
                        function()
                            if isDrop then
                                if CardSysManager:needDropCards("Friend Gift Mail") == true then
                                    CardSysManager:doDropCards("Friend Gift Mail")
                                end
                            end
                            successFunc()
                        end
                    )
                elseif isDrop == true then
                    if CardSysManager:needDropCards("Friend Gift Mail") == true then
                        CardSysManager:doDropCards("Friend Gift Mail")
                    end
                    successFunc()
                else
                    successFunc()
                end
            end
        end,
        function()
            gLobalViewManager:removeLoadingAnima()
            if not tolua.isnull(self) then
                failFunc()
            end
        end
    )
end

return InboxPage_friend
