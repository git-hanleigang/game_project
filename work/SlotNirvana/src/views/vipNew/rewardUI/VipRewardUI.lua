--[[--
    显示vip rewards 信息
]]
local VipRewardUI = class("VipRewardUI", BaseLayer)

function VipRewardUI:initDatas(_defaultPageIndex,_flag)
    self:setLandscapeCsbName("VipNew/csd/rewardUI/VipRewardUI.csb")

    self.m_pageIndex = _defaultPageIndex or 1
    self.m_flag = _flag
    self:addClickSound("btn_return", SOUND_ENUM.SOUND_HIDE_VIEW)
end

function VipRewardUI:initCsbNodes()
    self.m_nodeTime = self:findChild("node_time")
    self.m_return = self:findChild("btn_return")
    self.m_nodePageList = self:findChild("node_pageList")
    self.m_nodePageBtns = {}
    for i = 1, VipConfig.PageNum do
        local nodeBtn = self:findChild("node_btn" .. i)
        table.insert(self.m_nodePageBtns, nodeBtn)
    end

    self.m_listview = self:findChild("ListView")

    self.m_panelSwitchPage = self:findChild("Panel_switchPage")
    self:addClick(self.m_panelSwitchPage)
    self.m_panelSwitchPage:setSwallowTouches(false)
end

function VipRewardUI:initView()
    self:initCountDown()
    self:initPageBtns()
    self:initPageCells()
    self:initListView()
    self:setHideActionEnabled(false)
end

function VipRewardUI:initCountDown()
    local VipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
    if VipBoostData and VipBoostData:isOpenBoost() then
        self.m_cdTime = util_createView("views.vipNew.rewardUI.VipRewardTime")
        self.m_nodeTime:addChild(self.m_cdTime)
    end
end

function VipRewardUI:removeCountdownTime()
    if not tolua.isnull(self.m_cdTime) then
        self.m_cdTime:removeFromParent()
        self.m_cdTime = nil
    end
end

function VipRewardUI:initPageBtns()
    self.m_pageBtns = {}
    for i = 1, VipConfig.PageNum do
        local btnNode = util_createView("views.vipNew.rewardUI.VipRewardPageBtn", i, handler(self, self.clickPageBtn))
        self.m_nodePageBtns[i]:addChild(btnNode)
        table.insert(self.m_pageBtns, btnNode)
    end
    self:updatePageBtns()
end

function VipRewardUI:updatePageBtns()
    for i = 1, #self.m_pageBtns do
        self.m_pageBtns[i]:updateBtn(i == self.m_pageIndex)
    end
end

function VipRewardUI:clickPageBtn(_selectedIndex)
    self.m_pageIndex = _selectedIndex
    self:updatePageBtns()
    self:updatePageCells()
    self:updateListView()
    gLobalNoticManager:postNotification(ViewEventType.VIP_SWITCH_PAGE, {pageIndex = self.m_pageIndex})
end

function VipRewardUI:addPage()
    if self.m_pageIndex == VipConfig.PageNum then
        return
    end
    self:clickPageBtn(self.m_pageIndex + 1)
end

function VipRewardUI:delPage()
    if self.m_pageIndex == 1 then
        return
    end
    self:clickPageBtn(self.m_pageIndex - 1)
end

function VipRewardUI:initPageCells()
    self.m_pageCell = util_createView("views.vipNew.rewardUI.Cell_Vertical", self.m_pageIndex, "page")
    self.m_nodePageList:addChild(self.m_pageCell)
end

function VipRewardUI:updatePageCells()
    self.m_pageCell:updateCells(self.m_pageIndex)
end

function VipRewardUI:initListView()
    local listViewSize = self.m_listview:getContentSize()
    self.m_listCells = {}
    for i = 1, #VipConfig.LISTVIEW_CONFIG do
        local cell = util_createView("views.vipNew.rewardUI.Cell_Vertical", self.m_pageIndex, "listView", i)
        local cellSize = cell:getCellSize()
        local layout = ccui.Layout:create()
        layout:setContentSize({width = cellSize.width, height = listViewSize.height})
        layout:addChild(cell)
        cell:setPosition(cc.p(cellSize.width / 2, listViewSize.height / 2))
        self.m_listCells[i] = cell
        self.m_listview:pushBackCustomItem(layout)
    end
    local jumpIndex = self:getCurVipLevel()
    self.m_listview:jumpToItem(jumpIndex - 1, cc.p(0, 0), cc.p(0, 0))
end

function VipRewardUI:updateListView()
    for i = 1, #VipConfig.LISTVIEW_CONFIG do
        self.m_listCells[i]:updateCells(self.m_pageIndex)
    end
end

function VipRewardUI:closeUI(_over)
    -- 界面关闭发送消息关闭气泡
    gLobalNoticManager:postNotification(ViewEventType.VIP_REWARDUI_CLOSE)
    VipRewardUI.super.closeUI(self, _over)
end

function VipRewardUI:canClick()
    return true
end

function VipRewardUI:clickFunc(sender)
    if not self:canClick() then
        return
    end
    local name = sender:getName()
    if name == "btn_return" then
        self.m_return:setTouchEnabled(false)
        if self.m_flag and self.m_flag == 1 then
            self:closeUI()
            G_GetMgr(G_REF.Vip):showMainLayer()
        else
            self:runCsbAction("over",false,function()
                self:closeUI()
            end)
        end
       
        -- self:closeUI(
        --     function()
        --         gLobalNoticManager:postNotification(ViewEventType.NOTIFY_VIPMAIN_CLOSE)
        --     end
        -- )
    end
end

function VipRewardUI:baseTouchEvent(sender, eventType)
    if eventType == ccui.TouchEventType.began then
        if not self.clickStartFunc then
            return
        end
        self:setButtonStatusByBegan(sender)
        self:clickStartFunc(sender)
    elseif eventType == ccui.TouchEventType.moved then
        if not self.clickMoveFunc then
            return
        end
        self:setButtonStatusByMoved(sender)
        self:clickMoveFunc(sender)
    elseif eventType == ccui.TouchEventType.ended then
        if not self.clickEndFunc then
            return
        end
        self:setButtonStatusByEnd(sender)
        self:clickEndFunc(sender)
        local beginPos = sender:getTouchBeganPosition()
        local endPos = sender:getTouchEndPosition()

        local name = sender:getName()
        if name == "Panel_switchPage" then
            local offy = endPos.y - beginPos.y
            if offy > 50 then
                self:addPage()
            elseif offy < -50 then
                self:delPage()
            end
        else
            local offx = math.abs(endPos.x - beginPos.x)
            local offy = math.abs(endPos.y - beginPos.y)
            if offx < 50 and offy < 50 and globalData.slotRunData.changeFlag == nil then
                self:clickSound(sender)
                self:clickFunc(sender)
            end
        end
    elseif eventType == ccui.TouchEventType.canceled then
        -- print("Touch Cancelled")
        if not self.clickEndFunc then
            return
        end
        self:clickEndFunc(sender, eventType)
    end
end

function VipRewardUI:playShowAction()
    --gLobalSoundManager:playSound("Activity/Activity_CardEnd_Special_Disco/sound/openSound.mp3")
    local userDefAction = function(callFunc)
        self:runCsbAction(
            "start",
            false,
            function()
                if callFunc then
                    callFunc()
                end
            end,
            60
        )
    end
    VipRewardUI.super.playShowAction(self, userDefAction)
end

function VipRewardUI:onShowedCallFunc()
    self:runCsbAction("idle", true, nil, 60)
end

function VipRewardUI:onEnter()
    VipRewardUI.super.onEnter(self)

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.VipBoost then
                self:removeCountdownTime()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )
end

function VipRewardUI:getCurVipLevel()
    local curVipLevel = globalData.userRunData.vipLevel
    local data = G_GetMgr(G_REF.Vip):getData()
    if data then
        local VipBoostData = G_GetMgr(ACTIVITY_REF.VipBoost):getRunningData()
        if VipBoostData and VipBoostData:isOpenBoost() then
            local nextData = data:getVipLevelInfo(curVipLevel + VipBoostData.p_extraVipLevel) --获取下一个等级的VIP数据
            if nextData then
                curVipLevel = nextData.levelIndex
            end
        end
    end
    return curVipLevel
end

return VipRewardUI
