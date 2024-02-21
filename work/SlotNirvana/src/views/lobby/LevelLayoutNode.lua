--
--大厅关卡容器节点 用来放JACKPOT 或者一列多个关卡情况
--
local LevelLayoutNode = class("LevelLayoutNode", util_require("base.BaseView"))
LevelLayoutNode.m_pageIndex = nil
LevelLayoutNode.m_currentInfo = nil
LevelLayoutNode.m_page = nil
LevelLayoutNode.m_contentLenX = nil
LevelLayoutNode.m_contentLenY = nil
LevelLayoutNode.m_contentLen = nil
LevelLayoutNode.m_views = nil
LevelLayoutNode.m_infoList = nil --界面属性
LevelLayoutNode.m_waitRemoveKeys = nil --等待移除
local MoveTime = 7 --切换下一个时间
function LevelLayoutNode:initUI()
    self:createCsbNode("newIcons/Level_Layout.csb")
    self.m_pageIndex = 1
    self.m_currentInfo = nil
    self.m_isMove = false
    self.m_views = {}
    self.m_points = {}
    self.m_infoList = {}
    self.m_waitRemoveKeys = {}
    self.m_page = self:findChild("page")
    self.m_nodeDian = self:findChild("dian")

    self.m_page_Layout = self:findChild("page_Layout")
    self:addClick(self.m_page_Layout)
    self.m_page_Layout:setSwallowTouches(true)
    local size = self.m_page_Layout:getContentSize()

    self.m_width = size.width
    self.m_contentLenX = size.width * 0.5
    self.m_contentLenY = size.height * 0.5
    self.m_contentLen = 0

    self:runCsbAction("animation0", true)
end

function LevelLayoutNode:onEnter()
    schedule(
        self,
        function()
            if #self.m_views <= 1 then
                return
            end
            if self.m_isMove == false then
                self:showNextView()
            end
        end,
        MoveTime
    )
    self:showFristPage()

    gLobalNoticManager:addObserver(
        self,
        function(target, activityId)
            if self.checkRemovePage then
                self:checkRemovePage(activityId)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_CLOSE
    )

    -- 以后替代 NOTIFY_ACTIVITY_CLOSE 事件
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.checkRemovePage then
                self:checkRemovePage(params.id)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

    -- 活动完成条件达成
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.checkRemovePage then
                self:checkRemovePage(params.id)
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_COMPLETED
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if globalData.shopRunData:isShopFirstBuyed() then
                -- 移除首冲的宣传轮播图
                if self.checkRemovePage then
                    self:checkRemovePage("firstBuy")
                end
            end
        end,
        ViewEventType.NOTIFY_BUYCOINS_SUCCESS
    )

    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if not G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData() then
                -- 移除首充促销轮播图
                if self.checkRemovePage then
                    self:checkRemovePage("firstCommomSaleSlide")
                end
            end
        end,
        ViewEventType.NOTIFY_FIRST_SALE_BUYSUCCESS
    )

    -- 新手quest到期，刷新大厅 新手Quest轮播图
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if self.checkRemovePage then
                self:checkRemovePage("newUserQuestSlide")
            end
        end,
        ViewEventType.NOTIFY_UPDATE_QUEST_NEWUSER
    )

    -- 破冰促销结束购买完
    local IcebreakerSaleConfig = util_require("GameModule.IcebreakerSale.config.IcebreakerSaleConfig")
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 破冰促销结束购买完 移除轮播图
            if self.checkRemovePage then
                self:checkRemovePage("LevelIcebreakerSaleSlide")
            end
        end,
        IcebreakerSaleConfig.EVENT_NAME.ICE_BREAKER_OVER
    )

    -- 插入一个轮播
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            if self.insertSlideNode then
                self:insertSlideNode(data)
            end
        end,
        ViewEventType.NOTIFY_LOBBY_INSERT_HALL_AND_SLIDE
    )

    -- 生日促销结束
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 生日促销结束 移除轮播图
            if self.checkRemovePage then
                self:checkRemovePage("LevelBirthdaySaleSlide")
            end
        end,
        ViewEventType.NOTIFY_BIRTHDAY_PROMOTION_TIMEOUT
    )

    -- 新手期集卡开启活动 到期移除轮播展示
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 新手期集卡开启活动 到期移除 轮播图
            if self.checkRemovePage then
                self:checkRemovePage("LevelNewUserCardOpenSlide")
            end
        end,
        ViewEventType.CLOSE_REMOVE_NEW_USER_CARD_OPEN_HALL_SLIDE
    )

    -- 新手期集卡 促销 结束 移除轮播展示
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 新手期集卡 促销 结束 移除 轮播图
            if self.checkRemovePage then
                self:checkRemovePage("CardNoviceSaleSlide")
            end
        end,
        CardNoviceCfg.EVENT_NAME.REMOVE_CARD_NOVICE_SALE_HALL_SLIDE
    )

    -- 新手期集卡 双倍奖励 结束 移除轮播展示
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 新手期集卡 双倍奖励 结束 移除 轮播图
            if self.checkRemovePage then
                self:checkRemovePage("CardNoviceDoubleRewardSlide")
            end
        end,
        CardNoviceCfg.EVENT_NAME.REMOVE_CARD_NOVICE_DOUBLE_REWARD_HALL_SLIDE
    )
    
    -- 三档首冲
    gLobalNoticManager:addObserver(
        self,
        function(target, data)
            -- 三档首冲 移除轮播图
            if self.checkRemovePage then
                self:checkRemovePage("FirstSaleMultiSlide")
            end
        end,
        ViewEventType.NOTIFY_REMOVE_FIRST_SALE_MULTI_HALL_SLIDE
    )
end

-- function LevelLayoutNode:onEnterFinish()
--     LevelLayoutNode.super.onEnterFinish(self)
-- 更新坐标 放到 LevelLayoutNode 的 parent 适配完再 更新
function LevelLayoutNode:updateLobbyVedioNodePos()
    if globalData.lobbyVedioNode then
        local wordPos = self:convertToWorldSpace(cc.p(0, 270))
        local localPos = globalData.lobbyVedioNode:getParent():convertToNodeSpace(wordPos)
        globalData.lobbyVedioNode:setPosition(localPos)
    end
    
    if globalData.lobbyVedioChallgeNode then
        local wordPos = self:convertToWorldSpace(cc.p(-85, 275))
        if globalData.lobbyVedioNode then
            wordPos = self:convertToWorldSpace(cc.p(0, 275))
            local x = 150
            if globalData.lobbyScale then
                x = 150* globalData.lobbyScale
            end
            wordPos = self:convertToWorldSpace(cc.p(x, 275))
        end
        local localPos = globalData.lobbyVedioChallgeNode:getParent():convertToNodeSpace(wordPos)
        globalData.lobbyVedioChallgeNode:setPosition(localPos)
    end
end

function LevelLayoutNode:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
--显示第一个
function LevelLayoutNode:showFristPage()
    self.m_pageIndex = 1
    self.m_currentInfo = self.m_views[self.m_pageIndex]
    self.m_views[self.m_pageIndex].view:setVisible(true)
end
--显示下一个
function LevelLayoutNode:showNextView()
    self.m_pageIndex = self.m_pageIndex + 1
    if self.m_pageIndex > #self.m_views then
        self.m_pageIndex = 1
    end
    --检测下一个需要展示的是否和当前记录的一样
    if self.m_currentInfo.key ~= self.m_views[self.m_pageIndex].key then
        self:movePage(-1)
    else
        self:showNextView()
    end
end
--显示上一个
function LevelLayoutNode:showLastView()
    self.m_pageIndex = self.m_pageIndex - 1
    if self.m_pageIndex < 1 then
        self.m_pageIndex = #self.m_views
    end
    
    if not self.m_pageIndex or self.m_pageIndex < 1 or self.m_pageIndex > #self.m_views then
        return
    end
    --检测下一个需要展示的是否和当前记录的一样
    if self.m_currentInfo.key ~= self.m_views[self.m_pageIndex].key then
        self:movePage(1)
    else
        self:showLastView()
    end
end
--移动
function LevelLayoutNode:movePage(dir)
    local x, y = self.m_currentInfo.view:getPosition()
    local lastIndex = self:getIndex(self.m_currentInfo)
    self.m_isMove = true
    self.m_currentInfo = self.m_views[self.m_pageIndex]
    self.m_views[self.m_pageIndex].view:setVisible(true)
    self.m_views[self.m_pageIndex].view:setPosition(x - self.m_width * dir, y)
    local endPos = cc.p(self.m_page:getPosition())
    endPos.x = endPos.x + self.m_width * dir
    local moveAction = cc.MoveTo:create(0.5, endPos)
    local callfunc =
        cc.CallFunc:create(
        function()
            self:moveOverFunc(lastIndex)
        end
    )
    local seq = cc.Sequence:create(moveAction, callfunc)
    self.m_page:runAction(seq)
end
--移动结束回调
function LevelLayoutNode:moveOverFunc(lastIndex)
    self.m_views[lastIndex].view:setVisible(false)
    for i = 1, #self.m_points do
        if self.m_points[i] and self.m_points[i].setState then
            if i == self.m_pageIndex then
                self.m_points[i]:setState(true)
            else
                self.m_points[i]:setState(false)
            end
        end
    end
    self.m_isMove = false
    --动画完成尝试移除
    if #self.m_waitRemoveKeys > 0 then
        local isRemoveCur = nil
        for i = 1, #self.m_waitRemoveKeys do
            if self.m_waitRemoveKeys[i] == self.m_currentInfo.key then
                isRemoveCur = true
            else
                self:removePage(self.m_waitRemoveKeys[i])
            end
        end
        self.m_waitRemoveKeys = {}
        if isRemoveCur then
            self.m_waitRemoveKeys[1] = self.m_currentInfo.key
        end
    end
    self:checkParamData(self.m_views[lastIndex])
end
--根据附加参数特殊处理
function LevelLayoutNode:checkParamData(info)
    if not info or not info.param then
        return
    end
end

--根据信息获取索引
function LevelLayoutNode:getIndex(info)
    for i = 1, #self.m_views do
        if self.m_views[i].key == info.key then
            return i
        end
    end
end

--增加页面view node  key 字符串 order 顺序
function LevelLayoutNode:addPage(view, key, order, param)
    if not order then
        order = 100
    end
    for i = 1, #self.m_views do
        if self.m_views[i].key == key then
            return
        end
    end
    if self.m_page then
        self.m_page:addChild(view)
        view:setVisible(false)
        self.m_views[#self.m_views + 1] = {key = key, view = view, order = order, param = param}
        self:sortPage()
    end
end

--尝试移除
function LevelLayoutNode:checkRemovePage(key)
    if self.m_views and #self.m_views <= 1 and key == self.m_currentInfo.key then
        local node = util_createView("views.lobby.LevelRateusNode")
        self:addPage(node, "rateus")
    end

    if self.m_isMove or key == self.m_currentInfo.key then
        self.m_waitRemoveKeys[#self.m_waitRemoveKeys + 1] = key
        --如果当前正在展示强制移动到下一个
        if not self.m_isMove and key == self.m_currentInfo.key then
            self:showNextView()
        end
    else
        self:removePage(key)
    end
end

--移除(不要手动调用)
function LevelLayoutNode:removePage(key)
    for i = 1, #self.m_views do
        if self.m_views[i].key == key then
            self.m_views[i].view:removeFromParent()
            table.remove(self.m_views, i)
            self:sortPage()
            break
        end
    end
end

--根据order重新排序
function LevelLayoutNode:sortPage()
    table.sort(
        self.m_views,
        function(page1, page2)
            return page1.order < page2.order
        end
    )
    self:updatePoint()
end
--刷新点
function LevelLayoutNode:updatePoint()
    if #self.m_views <= 1 then
        self.m_nodeDian:removeAllChildren()
        return
    end
    local count = #self.m_views
    local scale = 1
    if count > 5 then
        scale = 0.7
    elseif count > 9 then
        scale = 0.3
    end
    local x = (count - 1) * -15 * scale
    self.m_nodeDian:removeAllChildren()
    for i = 1, count do
        self.m_points[i] = util_createView("views.lobby.LevelDian")
        self.m_nodeDian:addChild(self.m_points[i])
        self.m_points[i]:setPosition(x, 0)
        if i == self.m_pageIndex then
            self.m_points[i]:setState(true)
        else
            self.m_points[i]:setState(false)
        end
        x = x + 30 * scale
    end
end

--点击回调
function LevelLayoutNode:clickFunc(sender)
    if self.m_isMove == true then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "page_Layout" then
        --兼容老版本
        if self.m_currentInfo.view.MyclickFunc then
            self.m_currentInfo.view:MyclickFunc()
        end
        --发送点击通知
        if self.m_currentInfo and self.m_currentInfo.param and self.m_currentInfo.param.getRefName then
            if globalFireBaseManager.sendFireBaseLogDirect then
                globalFireBaseManager:sendFireBaseLogDirect(self.m_currentInfo.param:getRefName() .. "_CarouselClick", false)
            end
        end
        --大厅轮播图
        gLobalSendDataManager:getLogIap():setEntryOrder(self.m_pageIndex)
        gLobalSendDataManager:getLogIap():setEnterOpen("tapOpen", "lobbyCarousel")

        if gLobalSendDataManager.getLogPopub then
            gLobalSendDataManager:getLogPopub():setClickUrl(DotEntrySite.LobbyCarousel, DotEntryType.Lobby, "page_Layout")
        end

        -- 该轮播图点击是否播点击音效
        if self.m_currentInfo.view["isClickPlaySound"] and self.m_currentInfo.view:isClickPlaySound() then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        end

        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLICK_BROADCAST, {id = self.m_currentInfo.key, d = self.m_currentInfo.param, clickFlag = true})
    end
end
--抬起执行
function LevelLayoutNode:clickEndFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    local beganPos = sender:getTouchBeganPosition()
    local endPos = sender:getTouchEndPosition()
    if name == "page_Layout" and #self.m_views > 1 and self.m_isMove == false then
        if endPos.x - beganPos.x > 10 then
            self:showLastView()
        elseif endPos.x - beganPos.x < -10 then
            self:showNextView()
        end
    end
end

function LevelLayoutNode:getContentLen()
    return self.m_contentLenX, self.m_contentLenY
end

function LevelLayoutNode:getOffsetPosX()
    return self.m_contentLenX
end

function LevelLayoutNode:updateUI()
end

function LevelLayoutNode:insertSlideNode(_params)
    local slideData = _params.slide
    if not slideData then
        return
    end

    local data = slideData.data
    local luaName = slideData.luaName
    local order = slideData.order
    local key = slideData.key
    for i,v in ipairs(self.m_views) do
        if v.key == key then
            return
        end
    end

    local slideNode = util_createView(luaName, data)
    self:addPage(slideNode, key, order, data)
end

return LevelLayoutNode
