--[[
    领取类邮件基类
]]

local InboxItem_baseReward = class("InboxItem_baseReward", util_require("views.inbox.item.InboxItem_base"))
local ShopItem = require "data.baseDatas.ShopItem"

function InboxItem_baseReward:getCsbName()
    assert("需设置资源路径")
end

-- 如果有掉卡，在这里设置来源(可设置多个)
function InboxItem_baseReward:getCardSource()
    return {}
end

-- 描述说明
function InboxItem_baseReward:getDescStr()
    return ""
end

-- 金币缩写长度
function InboxItem_baseReward:getCoinLen()
    return 3, 9
end

-- 道具最大显示个数
function InboxItem_baseReward:getItemLen()
    return 4, 7
end

function InboxItem_baseReward:getRewardLen()
    local coinLen1, coinLen2 = self:getCoinLen()
    local itemLen1, itemLen2 = self:getItemLen()

    local coinLen = coinLen2
    if self.m_items and #self.m_items > 0 then
        coinLen = coinLen1
    end
    local itemLen = itemLen2
    if self.m_coins and toLongNumber(self.m_coins) > toLongNumber(0) then
        itemLen = itemLen1
    end
    return coinLen, itemLen
end

function InboxItem_baseReward:initCsbNodes()
    self.m_lb_add = self:findChild("lb_add")
    self.m_sp_coin = self:findChild("sp_coin")
    self.m_lb_coin = self:findChild("lb_coin")
    self.m_lb_time = self:findChild("txt_time")
    self.m_sp_time_bg = self:findChild("sp_time_bg")
    self.m_lb_desc = self:findChild("txt_desc")
    self.m_lb_desc2 = self:findChild("txt_desc1")
    self.m_node_reward = self:findChild("node_reward")
    self.m_btn_inbox = self:findChild("btn_inbox")
    self.m_node_button = self:findChild("node_button")

    if self.m_btn_inbox then
        self.m_btn_inbox:setSwallowTouches(false)
    end
end

function InboxItem_baseReward:initView()
    self:initData()
    -- self:initTime()
    self:initDesc()
    self:initReward()
    self:alignUI()
    self:initIconUI()
end

function InboxItem_baseReward:initData()
    local awards = self.m_mailData.awards or {}
    self.m_items = awards.items or {}
    self.m_coins = toLongNumber(awards.coinsV2 or (awards.coins or 0))
    self.m_uiList = {}
    self.m_gems = 0
    self.m_shopItemList = {} --道具列表
    self.m_deluxePoint = tonumber(awards.points) or 0 --高倍场点数数值
    self.m_propsBagList = {}
    self.m_isMerge = true
    -- 代币
    self.m_rawardBuckNum = tonumber(awards.bucks or 0)
end

function InboxItem_baseReward:mergeItems(_data)
    if not self.m_isMerge then
        return _data
    end
    local items = {}
    local temp = {}
    local buff = {}
    self.m_gems = 0
    for i, v in ipairs(_data) do
        local tempData = ShopItem:create()
        tempData:parseData(v)
        local key = tempData.p_icon
        if tempData.p_type == "Buff" then
            table.insert(buff, tempData)
        else
            -- 处理一些特殊道具的显示方式
            self:mergeSpecialItem(tempData)
            -- 合并道具
            local itemInfo = temp[key]
            if itemInfo then
                itemInfo.p_num = itemInfo.p_num + tempData.p_num
            elseif key == "clanpoint" then
                -- 公会点数
                if self:checkCanTeamPoint() then
                    temp[key] = tempData
                end
            else
                temp[key] = tempData
            end
        end
        -- 钻石
        if key == "Gem" then
            self.m_gems = self.m_gems + tempData.p_num
        end
    end
    for i, v in pairs(temp) do
        table.insert(items, v)
    end
    for i, v in pairs(buff) do
        table.insert(items, v)
    end

    -- 高倍场点数 非道具就是数值
    if self.m_deluxePoint > 0 then
        local itemData = gLobalItemManager:createLocalItemData("DeluxeClub", self.m_deluxePoint)
        table.insert(items, 1, itemData)
    end

    return items
end

-- tempData是传的原始数据表，这个方法是对对原始数据表直接进行更改
function InboxItem_baseReward:mergeSpecialItem(tempData)
end

function InboxItem_baseReward:initReward()
    if not self.m_sp_coin or not self.m_lb_coin or not self.m_lb_add or not self.m_node_reward then
        return
    end

    local coinLen, itemLen = self:getRewardLen()
    -- 金币
    if toLongNumber(self.m_coins) > toLongNumber(0) then
        local strCoins = util_formatCoins(self.m_coins, coinLen)
        self.m_lb_coin:setString(strCoins)
        local size = self.m_sp_coin:getContentSize()
        local scale = self.m_sp_coin:getScale()
        table.insert(self.m_uiList, { node = self.m_sp_coin, alignX = -size.width / 2 * scale })
        table.insert(self.m_uiList, { node = self.m_lb_coin, alignX = 5.5 })
        table.insert(self.m_uiList, { node = self.m_lb_add, alignX = 3.5 })
    else
        self.m_sp_coin:setVisible(false)
        self.m_lb_coin:setVisible(false)
        self.m_lb_add:setVisible(false)
    end

    local hasItem = false
    -- 代币道具
    if self.m_rawardBuckNum and self.m_rawardBuckNum > 0 then
        hasItem = true
        local itemData = gLobalItemManager:createLocalItemData("Buck", self.m_rawardBuckNum)
        if itemData then
            local itemNode = gLobalItemManager:createRewardNode(itemData, ITEM_SIZE_TYPE.TOP)
            if itemNode then
                itemNode:setScale(0.8)
                self.m_node_reward:addChild(itemNode)
                local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP) * 1
                local sizeNode = cc.size(width, width)
                table.insert(self.m_uiList,
                    { node = itemNode, alignX = 0, alignY = 2, size = sizeNode, anchor = { x = 0.5, y = 0.5 } })                
            end
        end
    end
    -- 高倍场点数 非道具就是数值
    if #self.m_items > 0 or self.m_deluxePoint > 0 then
        hasItem = true
        self.m_shopItemList = self:mergeItems(self.m_items)
        for i, v in ipairs(self.m_shopItemList) do
            if i > itemLen then
                return
            end
            local itemNode = gLobalItemManager:createRewardNode(v, ITEM_SIZE_TYPE.TOP)
            if itemNode then
                itemNode:setScale(0.8)
                self.m_node_reward:addChild(itemNode)
                local width = gLobalItemManager:getIconDefaultWidth(ITEM_SIZE_TYPE.TOP) * 1
                local sizeNode = cc.size(width, width)
                table.insert(self.m_uiList,
                    { node = itemNode, alignX = 3, alignY = 2, size = sizeNode, anchor = { x = 0.5, y = 0.5 } })
            end
        end
    end
    if not hasItem then
        self.m_lb_add:setVisible(false)
    end
end

function InboxItem_baseReward:alignUI()
    if #self.m_uiList > 0 then
        if toLongNumber(self.m_coins) <= toLongNumber(0) then
            local temp = self.m_uiList[1]
            local scale = temp.node:getScale()
            temp.alignX = -(temp.size.width / 2 * scale) + 5
        elseif #self.m_shopItemList == 0 then
            table.remove(self.m_uiList, #self.m_uiList)
        end
        self:alignLeft(self.m_uiList)
    end
end

function InboxItem_baseReward:initTime()
    if self.m_lb_time then
        local expireAt = self.m_mailData.expireAt
        local time = 0
        if expireAt and expireAt ~= "" and expireAt ~= 0 then
            time = tonumber(expireAt) / 1000
        elseif self.m_mailData.validEnd then
            time = util_getymd_time(self.m_mailData.validEnd)
        end

        local days = util_leftDays(time, true)
        if days >= 15 then
            self:hideTime()
        else
            local updateTimeLable = function()
                local strTime, isOver = util_daysdemaining(time, true)
                if isOver then
                    self.m_lb_time:stopAllActions()
                    G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
                    local collecData = G_GetMgr(G_REF.Inbox):getSysRunData()
                    if collecData then
                        collecData:removeShowMailDataById({ self.m_mailData.id })
                    end
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_REFRESH_MAIL_COUNT,
                        G_GetMgr(G_REF.Inbox):getMailCount())
                    -- 更新邮件信息
                    self:removeSelfItem()
                else
                    self.m_lb_time:setString(strTime)
                end
            end
            util_schedule(self.m_lb_time, updateTimeLable, 1)
            updateTimeLable()
        end
    end
end

function InboxItem_baseReward:hideTime()
    if self.m_sp_time_bg then
        self.m_sp_time_bg:setVisible(false)
    end
    if self.m_node_button then
        self.m_node_button:setPosition(718, 56)
    end
end

function InboxItem_baseReward:initDesc()
    local desc1, desc2 = self:getDescStr()
    if desc1 and desc1 == "WANTED REWARD" then
        print("--1----")
    end
    if desc2 and desc2 == "WANTED REWARD" then
        print("--2----")
    end
    if self.m_lb_desc then
        if desc1 then
            self.m_lb_desc:setString(desc1)
            self:updateLabelSize({ label = self.m_lb_desc }, 470)
        else
            self.m_lb_desc:setString("")
        end
    end
    if self.m_lb_desc2 then
        if desc2 then
            self.m_lb_desc2:setString(desc2)
            self:updateLabelSize({ label = self.m_lb_desc2 }, 470)
        else
            self.m_lb_desc2:setString("")
        end
    end
end

-- 邮件 icon
function InboxItem_baseReward:initIconUI()
end

function InboxItem_baseReward:clickFunc(sender)
    if G_GetMgr(G_REF.Inbox):getInboxCollectStatus() then
        return
    end
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    local name = sender:getName()
    if name == "btn_inbox" then
        G_GetMgr(G_REF.Inbox):setInboxCollectStatus(true)
        self:collectBonus()
    end
end

function InboxItem_baseReward:collectBonus()
    gLobalViewManager:addLoadingAnima()
    --领取奖励  --发送读取邮件消息-->返回成功-->发送领取奖励消息-->返回成功-->删除item
    self:sendCollectMail()
end

function InboxItem_baseReward:sendCollectMail()
    G_GetMgr(G_REF.Inbox):getSysNetwork():collectMail({ self.m_mailData.id },
        function(data)
            gLobalViewManager:removeLoadingAnima()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_DELUXE_CAT_FOOD_COUNT_REFRESH) --猫粮消息
            if not tolua.isnull(self) then
                self:collectMailSuccess()
            end
        end,
        function(data)
            gLobalViewManager:removeLoadingAnima()
            if not tolua.isnull(self) then
                self:collectMailFailed()
            end
        end
    )
end

-- 尝试 掉落合成福袋
function InboxItem_baseReward:initDropPropsBagLayer()
    if #self.m_items > 0 then
        for i, v in ipairs(self.m_shopItemList ) do
            if string.find(v.p_icon, "Pouch") then
                table.insert(self.m_propsBagList, v)
            end
        end
        -- 合成福包弹板
        local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
        mergeManager:setPopPropsBagTempList(self.m_propsBagList)
    end
end

function InboxItem_baseReward:collectMailSuccess()
    -- 合成福袋
    self:initDropPropsBagLayer()
    local function dropClubMerge()
        local mergeManager = G_GetMgr(ACTIVITY_REF.DeluxeClubMergeActivity)
        local cb = function()
            mergeManager:resetPropsBagTempList()
            globalDeluxeManager:dropExperienceCardItemEvt()
        end
        mergeManager:autoPopPropsBagLayer(cb)
    end

    local sourceList = self:getCardSource()
    local startDropCards = function()
        local dropSource = nil
        if sourceList and #sourceList > 0 then
            for i, v in ipairs(sourceList) do
                if CardSysManager:needDropCards(v) == true then
                    dropSource = v
                    break
                end
            end
        end
        if dropSource ~= nil then
            CardSysManager:doDropCards(dropSource, function()
                dropClubMerge()
            end)
        else
            dropClubMerge()
        end
    end
    -- 飞金币
    self:flyBonusGameCoins(function()
        startDropCards()
        self:removeSelfItem()
    end)
end

function InboxItem_baseReward:flyBonusGameCoins(_callback)
    local flyList = {}
    local btnCollect = self:findChild("btn_inbox")
    local startPos = btnCollect:getParent():convertToWorldSpace(cc.p(btnCollect:getPosition()))
    local isFly = false
    -- 金币
    if toLongNumber(self.m_coins) > toLongNumber(0) then
        isFly = true
        table.insert(flyList, { cuyType = FlyType.Coin, addValue = self.m_coins, startPos = startPos })
    end
    -- 钻石
    if self.m_gems > 0 then
        isFly = true
        table.insert(flyList, { cuyType = FlyType.Gem, addValue = self.m_gems, startPos = startPos })
    end
    -- 代币
    if self.m_rawardBuckNum and self.m_rawardBuckNum > 0 then
        isFly = true
        table.insert(flyList, { cuyType = FlyType.Buck, addValue = self.m_rawardBuckNum, startPos = startPos })
    end
    local mgr = G_GetMgr(G_REF.Currency)
    if isFly and mgr then
        mgr:playFlyCurrency(flyList, function()
            if not tolua.isnull(self) then
                if _callback then
                    _callback()
                end
            end
        end)
    else
        if _callback then
            _callback()
        end        
    end
end

function InboxItem_baseReward:removeSelfItem()
    if self.m_btn_inbox then
        self.m_btn_inbox:setTouchEnabled(false)
    end

    -- 渐隐效果
    util_fadeOutNode(self, 1, function()
        if self.m_removeMySelf ~= nil then
            --刷新界面
            self.m_removeMySelf(self)
        end
    end)
end

function InboxItem_baseReward:collectMailFailed()
    G_GetMgr(G_REF.Inbox):setInboxCollectStatus(false)
    --领取失败
    gLobalViewManager:showReConnect()
end

function InboxItem_baseReward:getLanguageTableKeyPrefix()
    return "InboxItem_reward"
end

function InboxItem_baseReward:onEnter()
    InboxItem_baseReward.super.onEnter(self)
    self:initTime()
end

function InboxItem_baseReward:onExit()
    if self.m_lb_time then
        self.m_lb_time:stopAllActions()
    end
    InboxItem_baseReward.super.onExit(self)
end

function InboxItem_baseReward:alignLeft(uiList)
    local totalWidth = 0
    local posX, posY = 0, 0
    for k, v in ipairs(uiList) do
        local alignX = v.alignX or 0
        local alignY = v.alignY or 0
        local node = v.node
        local nodeSize = v.size or node:getContentSize()
        local nodeAnchor = v.anchor or node:getAnchorPoint()
        local nodeScale = node:getScale()
        posX = posX + nodeAnchor.x * nodeSize.width * nodeScale
        if k > 1 then
            local preInfo = uiList[k - 1]
            local preNode = preInfo.node
            local preAlignX = preInfo.alignX or 0
            local preNodeSize = preInfo.size or preNode:getContentSize()
            local preNodeAnchor = preInfo.anchor or preNode:getAnchorPoint()
            local preNodeScale = preNode:getScale()
            posX = posX + preAlignX + (1 - preNodeAnchor.x) * preNodeSize.width * preNodeScale
        end
        node:setPosition(posX + alignX, posY + alignY)
    end
end

-- 是否可以显示 公会点数道具
function InboxItem_baseReward:checkCanTeamPoint()
    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
    local clanData = ClanManager:getClanData()
    if clanData and clanData:isClanMember() then
        return true
    end

    return false
end

return InboxItem_baseReward
