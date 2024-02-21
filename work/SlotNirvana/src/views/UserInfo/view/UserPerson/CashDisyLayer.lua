--成就页面
local CashDisyLayer = class("CashDisyLayer", BaseLayer)
function CashDisyLayer:ctor(_type)
    CashDisyLayer.super.ctor(self)
    self:setExtendData("CashDisyLayer")
    local path = "Activity/csd/Information_FramePartII/FramePartII_MainUI/FramePartII_MainUI.csb"
    self:setLandscapeCsbName(path)
    self.ManGer = G_GetMgr(G_REF.UserInfo)
    self.config = G_GetMgr(G_REF.UserInfo):getConfig()
    self:setShowActionEnabled(false)
    self:setBgm(self.config.SoundPath.BGM)
end

function CashDisyLayer:initCsbNodes()
    self.node_level_title = self:findChild("node_level_title")
    self.node_frame_tltle = self:findChild("node_frame_tltle")
    self.lb_title = self:findChild("lb_title_progress_2")
    self.pageView = self:findChild("pageview")
    self.btn_left = self:findChild("btn_left")
    self.btn_right = self:findChild("btn_right")
    self.layer_frame = self:findChild("node_level")
    self.layer_gird = self:findChild("node_frame")
    self.page_frame = self:findChild("page_frame")
end

function CashDisyLayer:initView()
    self.click_one = true
    local winSize = cc.Director:getInstance():getWinSize()
    local designScale = CC_DESIGN_RESOLUTION.width / CC_DESIGN_RESOLUTION.height
    local deviceScale = display.width / display.height
    local ratio = math.min(deviceScale / designScale, 2)
    local node = self:findChild("node_middle")
    local an = self:findChild("root")
    if ratio > 1 then
         an:setPositionX((winSize.width/2)*ratio)
    else
         node:setPosition((winSize.width/2)/ratio,(winSize.height/2)/ratio)
         an:setPositionY((winSize.height/2)/ratio)
    end
    gLobalSoundManager:playSound(self.config.SoundPath.OPEN)
    self:runCsbAction(
        "open",
        false,
        function()
            self:runCsbAction("idle",true)
            self.click_one = false
        end
    )

    util_performWithDelay(
            self,
            function()
               self:updataPageview()
               self:createGirdView()
            end,
            20/60
    )
    self.item_type = 1
    self.node_level_title:setVisible(false)
    local hold_data = G_GetMgr(G_REF.AvatarFrame):getUserHoldFrameTimeList()
    local all_cf = self.ManGer:getCfAllList()
    self.til_str = #hold_data .."/"..#all_cf
    self.lb_title:setString(self.til_str)
    
    self.btn_left:setVisible(false)
    self.btn_right:setVisible(true)
    self.pageView:addEventListener(handler(self, self.pageViewCallback))
    self.pageView:setTouchEnabled(false)
    self.page_frame:setTouchEnabled(false)
    self.page_frame:setVisible(false)
end

function CashDisyLayer:createGirdView()
    self.grid_index = 1
    self.girdView_one = cc.NodeGrid:create()
    self.layer_gird:addChild(self.girdView_one)
    local node,aniact = util_csbCreate("Activity/csd/Information_FramePartII/FramePartII_MainUI/Gird_node.csb")
    self.grd_bg = node:getChildByName("sp_title_bg")
    self.node_di = node:getChildByName("gri_node")
    self.grid_node = node:getChildByName("node_fgrid")
    self.grid_pro = self.node_di:getChildByName("grd_pro")
    self.grid_icon = self.node_di:getChildByName("grid_icon")
    node:setPositionY(15)
    self.girdView_one:addChild(node)
    self.girdView_one:setVisible(false)
    self:updataGirdView(self.page_data[self.grid_index])
end

function CashDisyLayer:updataGirdView(data)
    self.grd_bg:setVisible(true)
    self.node_di:setVisible(true)
    self.grid_node:setVisible(true)
    for i=1,6 do
        local nodeg = self.grid_node:getChildByName("grdi_icon"..i)
        nodeg:setVisible(true)
        nodeg:removeAllChildren()
    end
    local icon_pic = "Activity/img/Information_FramePartII/FramePartII_MainUI/FramePartII_Main_icon8.png"
    if self.item_type == 1 then
        self.grid_pro:setString(self.til_str)
        if data and #data > 0 then
            for k=1,#data do
                local nodeg = self.grid_node:getChildByName("grdi_icon"..k)
                local node = util_createView("views.UserInfo.view.UserPerson.CashDisyCell")
                node:updataCell(data[k].id,1,1)
                node:setScale(0.9)
                nodeg:addChild(node)
            end
        end
    else
        if data.id == "99999" then
            local item_head = self.ManGer:getCfHoldList()
            local totalNum = self.ManGer:getCfItemList()
            self.grid_pro:setString(#item_head.."/"..#totalNum)
            local index = 1
            if #item_head > 0 then
                for i,v in ipairs(item_head) do
                    local ic_node = self.grid_node:getChildByName("grdi_icon"..index)
                    local node = util_createView("views.UserInfo.view.UserPerson.CashDisyFrameCell")
                    node:updataCell(v.id,true)
                    ic_node:addChild(node)
                    index = index + 1
                end
            end
            if #totalNum > 0 then
                for i=index,#totalNum do
                    local ic_node = self.grid_node:getChildByName("grdi_icon"..i)
                    local node = util_createView("views.UserInfo.view.UserPerson.CashDisyFrameCell")
                    node:updataCell(totalNum[i].id,false)
                    ic_node:addChild(node)
                end
            end
        else
            local frameStaticData = G_GetMgr(G_REF.AvatarFrame):getFrameStaticData() 
            local iconPath = frameStaticData:getSlotIconPath(data.id)
            icon_pic = string.format("Activity/img/Information_FramePartII/FramePartII_MainUI/FramePartII%s.png", iconPath)
            local data1 = G_GetMgr(G_REF.AvatarFrame):getData()
            local m_slotTaskData = data1:getSlotTaskBySlotId(data.id)
            local completeNum = m_slotTaskData:getCompleteNum()
            local totalNum = m_slotTaskData:getTotalNum()
            self.grid_pro:setString(completeNum .. "/" .. totalNum)
            local taskDataList = m_slotTaskData:getTaskList()
            for i,v in ipairs(taskDataList) do
                local ic_node = self.grid_node:getChildByName("grdi_icon"..i)
                local node = util_createView("views.UserInfo.view.UserPerson.CashDisyFrameCell")
                node:updataCell(v)
                ic_node:addChild(node)
            end
        end
    end
    util_changeTexture(self.grid_icon,icon_pic)
end

function CashDisyLayer:pageViewCallback(sender, event)
    if event == ccui.PageViewEventType.turning then
        -- getCurrentPageIndex() 获取当前翻到的页码 打印
        local curPageIndex = self.pageView:getCurrentPageIndex()
        if self.item_type == 2 then
            return
        end
        if curPageIndex == 0 then
            self.btn_left:setVisible(false)
            self.btn_right:setVisible(true)
        elseif curPageIndex == 1 then
            self.btn_left:setVisible(true)
            self.btn_right:setVisible(false)
        end
    end
end

function CashDisyLayer:updataPageview()
    self.m_data = self.ManGer:getCashData()
    local item_data = G_GetMgr(G_REF.UserInfo):getCfItemList()
    if item_data and #item_data > 0 then
        local item = {}
        item.id = "99999"
        item.num = 0
        table.insert(self.m_data,1,item)
    end
    self.page_data = {}
    for idx, itemInfo in ipairs(self.m_data) do
        local newIdx = math.floor((idx-1) / 6) + 1
        if not self.page_data[newIdx] then
            self.page_data[newIdx] = {}
        end
        table.insert(self.page_data[newIdx], itemInfo)
    end
    local size = self.pageView:getContentSize()
    local index = 0
    for i=1,#self.page_data do
        local layout = ccui.Layout:create()
        local pos_x = 320
        local pos_y = 380
        for k=1,#self.page_data[i] do
            index = index + 1
            local inde = k - 1
            if k > 3 then
                inde = k - 4
                pos_y = 130
            end
            pos_x = 160 + inde*290
            local node = util_createView("views.UserInfo.view.UserPerson.CashDisyCell")
            node:updataCell(self.page_data[i][k].id,1,index)
            node:setScale(0.9)
            node:setPosition(pos_x,pos_y)
            layout:addChild(node)
        end
        
        self.pageView:addPage(layout)
    end

    util_setCascadeOpacityEnabledRescursion(self.pageView, true)
end

function CashDisyLayer:updataFrame(_slotId)
    self.pageView:setVisible(false)
    self.page_frame:setVisible(true)
    self:updataFramePage()
    self.page_frame:removeAllPages()
    local title_icon = self:findChild("title_ficon")
    local process_title = self:findChild("lb_title_progress")
    local icon_str = "Activity/img/Information_FramePartII/FramePartII_MainUI/FramePartII_Main_icon1.png"
    local pageList = {}
    if _slotId == "99999" then
        local item_head = self.ManGer:getCfHoldList()
        local totalNum = self.ManGer:getCfItemList()
        process_title:setString(#item_head .. "/" .. #totalNum)
        local index = 1
        if item_head and #item_head > 0 then
            for i,v in ipairs(item_head) do
                v.teshu = true
                table.insert(pageList,v)
                index = index + 1
            end
        end
        if totalNum and #totalNum > 0 then
            for i=index,#totalNum do
                totalNum[i].teshu = false
                table.insert(pageList,totalNum[i])
            end
        end
        if #totalNum <= 6 then
            self.btn_right:setVisible(false)
            self.btn_left:setVisible(false)
        end
    else
        local frameStaticData = G_GetMgr(G_REF.AvatarFrame):getFrameStaticData()
        icon_str = frameStaticData:getSlotImgPath(_slotId)
        local data = G_GetMgr(G_REF.AvatarFrame):getData()
        self.m_slotTaskData = data:getSlotTaskBySlotId(_slotId)
        local completeNum = self.m_slotTaskData:getCompleteNum()
        local totalNum = self.m_slotTaskData:getTotalNum()
        process_title:setString(completeNum .. "/" .. totalNum)
        local taskDataList = self.m_slotTaskData:getTaskList()
        if #taskDataList <= 6 then
            self.btn_right:setVisible(false)
            self.btn_left:setVisible(false)
        end
        if taskDataList and #taskDataList > 0 then
            for i,v in ipairs(taskDataList) do
                table.insert(pageList,v)
            end
        end
    end
    util_changeTexture(title_icon,icon_str)
    local size = self.page_frame:getContentSize()
    if #pageList > 0 then
        self.m_pageDate = self:getPageItemData(pageList)
        self.m_pageDateNum = #self.m_pageDate
        for i,v in ipairs(self.m_pageDate) do
            local layout = ccui.Layout:create()
            local pageItem = util_createView("views.UserInfo.view.UserPerson.FrameDisyPageNode",i,v)
            layout:addChild(pageItem)
            pageItem:setPosition(size.width / 2, size.height / 2 +25)
            self.page_frame:addPage(layout)
        end
    end

    util_setCascadeOpacityEnabledRescursion(self.page_frame, true)
end

function CashDisyLayer:getPageItemData(_list)
    local splitItemsList = {}
    for idx, itemInfo in ipairs(_list) do
        local newIdx = math.floor((idx-1) / 6) + 1
        if not splitItemsList[newIdx] then
            splitItemsList[newIdx] = {}
        end
        table.insert(splitItemsList[newIdx], itemInfo)
    end
    return splitItemsList
end

function CashDisyLayer:registerListener()
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            --具体展示页
            if self.click_one or self.right_type then
                return
            end
            self.click_one = true
            self.btn_right:setVisible(false)
            self.btn_left:setVisible(false)
            gLobalSoundManager:playSound(self.config.SoundPath.ENTER)
            self:runCsbAction("change1",false,function()
                --self:runCsbAction("idle",true)
                 self.node_level_title:setVisible(true)
                 self.node_frame_tltle:setVisible(false)
                 
                 self:playChangePage()
                 self.pageView:setVisible(false)
                 self:updataFrame(params.data)
                 self.layer_frame:setVisible(true)
                 gLobalNoticManager:postNotification(self.config.ViewEventType.CASH_AVMENT_ANIFRAME)
            end)
            self.item_type = 2
            self.m_nIndex = params.index
        end,
        self.config.ViewEventType.FRAME_AVMENT_LEVEL
    )
    -- gLobalNoticManager:addObserver(
    --     self,
    --     function(self, _bGoGameScene)
    --         self:closeUI()
    --     end,
    --     self.config.ViewEventType.MAIN_CLOSE
    -- )
end
function CashDisyLayer:playChangePage()
    self.grd_bg:setVisible(false)
    self.node_di:setVisible(false)
    self.grid_node:setVisible(true)
    self.girdView_one:setVisible(true)
    local act = cc.PageTurn3D:create(0.8, cc.size(15,10))
    local callFunc = cc.CallFunc:create(function()
        if tolua.isnull(self) then
            return
        end
        self.girdView_one:setVisible(false)
    end)
    local seq = cc.Sequence:create(act,callFunc)
    self.girdView_one:runAction(seq)
    util_performWithDelay(
            self,
            function()
                if tolua.isnull(self) then
                    return
                end
                self.grid_node:setVisible(false)
                self:runCsbAction("change2",false,function()
                    self.click_one = false
                    self:runCsbAction("idle",true)
                end)
            end,
            8/60
    )
end
function CashDisyLayer:changFrameUI()
    -- self:runCsbAction("start",false,function()
    --     self:runCsbAction("idle",true)
    -- end)
    self.item_type = 1
    self:updataGirdView(self.page_data[self.grid_index])
    self.pageView:setVisible(true)
    self.node_level_title:setVisible(false)
    self.node_frame_tltle:setVisible(true)
    self.layer_frame:setVisible(false)
    self.page_frame:setVisible(false)
    self:updatePageViewPoint()
    gLobalNoticManager:postNotification(self.config.ViewEventType.CASH_AVMENT_ANIFRAME)
end

function CashDisyLayer:updatePageViewPoint()
    local curPageIndex = self.pageView:getCurrentPageIndex()
    self.btn_left:setVisible(true)
    self.btn_right:setVisible(true)
    if curPageIndex == 0 or curPageIndex == -1 then
        self.btn_left:setVisible(false)
        self.btn_right:setVisible(true)
    elseif curPageIndex == (#self.page_data - 1) then
        self.btn_left:setVisible(true)
        self.btn_right:setVisible(false)
    end
end

function CashDisyLayer:updataButton(_nIndex,_data)
    self.layer_frame:setVisible(true)
    self:updataFrame(_data.id)
    gLobalNoticManager:postNotification(self.config.ViewEventType.CASH_AVMENT_ANIFRAME)
end

function CashDisyLayer:clickStartFunc(sender)
end

function CashDisyLayer:playHideAction()
    CashDisyLayer.super.playHideAction(self, "close", false)
end

function CashDisyLayer:closeUI()
    self.click_one = true
    -- self:runCsbAction("close",false,function()
        CashDisyLayer.super.closeUI(self)
    -- end)
    -- util_performWithDelay(
    --     self,
    --     function()
    --         if tolua.isnull(self) then
    --             return
    --         end
    --         self.pageView:setVisible(false)
    --     end,
    --     30/60
    -- )
end

function CashDisyLayer:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_close" then
        if self.click_one then
            return
        end
        if self.item_type == 2 then
            self:changFrameUI()
            return
        end
        gLobalSoundManager:playSound(self.config.SoundPath.CLOSE)
        self:closeUI()
    elseif name == "btn_left" then
        if self.item_type == 2 then
            self:goToLeft()
            return
        end
        if self.left_type == true or self.right_type == true or self.click_one then
            return
        end
        self.left_type = true
        self.btn_left:setTouchEnabled(false)
        if self.item_type == 2 then
            local _data = self.m_data[self.m_nIndex - 1]
            if _data then
                self:updataGirdView(_data)
                self:playLeftAction(2)
            end
            return
        end
        self:playLeftAction()
    elseif name == "btn_right" then
        if self.item_type == 2 then
            self:goToRight()
            return
        end
        if self.click_one then
            return
        end
        self.right_type = true
        if self.item_type == 2 then
            self:updataGirdView(self.m_data[self.m_nIndex])
            local _data = self.m_data[self.m_nIndex + 1]
            if _data then
                self.m_nIndex = self.m_nIndex + 1
                self:updataButton(self.m_nIndex,_data)
            end
            self:playRightAction(2)
            return
        end
        local idx = self.pageView:getCurrentPageIndex()
        if idx == -1 then
            self.pageView:setCurrentPageIndex(1)
        else
            self.pageView:setCurrentPageIndex(idx+1)
        end
        self:playRightAction()
    end
end

function CashDisyLayer:goToLeft()
    local idx = self.page_frame:getCurrentPageIndex()
    self.page_frame:setCurrentPageIndex(idx-1)
    self:updataFramePage()
end
function CashDisyLayer:goToRight()
    local idx = self.page_frame:getCurrentPageIndex()
    if idx == -1 then
        idx = 0
    end
    self.page_frame:setCurrentPageIndex(idx+1)
    self:updataFramePage()
end

function CashDisyLayer:updataFramePage()
    local curPageIndex = self.page_frame:getCurrentPageIndex()
    self.btn_left:setVisible(true)
    self.btn_right:setVisible(true)
    if curPageIndex == 0 or curPageIndex == -1 then
        self.btn_left:setVisible(false)
        self.btn_right:setVisible(true)
    elseif curPageIndex == (self.m_pageDateNum - 1) then
        self.btn_left:setVisible(true)
        self.btn_right:setVisible(false)
    end
end

function CashDisyLayer:playLeftAction(_type)
    gLobalSoundManager:playSound(self.config.SoundPath.BACKSLIDE)
    self.grd_bg:setVisible(false)
    self.node_di:setVisible(false)
    self.grid_node:setVisible(true)
    self.girdView_one:setVisible(true)
    for i=1,6 do
        self.grid_node:getChildByName("grdi_icon"..i):setVisible(false)
    end
    local act = cc.PageTurn3D:create(0.5, cc.size(15,10))
    local act1 = act:reverse()
    local callFunc = cc.CallFunc:create(function()
        if tolua.isnull(self) then
            return
        end

        self.btn_left:setTouchEnabled(true)
        self.girdView_one:setVisible(false)
        if _type then
            self.m_nIndex = self.m_nIndex - 1
            local _data = self.m_data[self.m_nIndex]
            if _data then
                self:updataButton(self.m_nIndex,_data)
            end
        else
            local idx = self.pageView:getCurrentPageIndex()
            self.pageView:setCurrentPageIndex(idx-1)
            self:updatePageViewPoint()
           
        end
       
    end)
    local seq = cc.Sequence:create(act1,callFunc)
    self.girdView_one:runAction(seq)
    util_performWithDelay(
            self,
            function()
                if tolua.isnull(self) then
                    return
                end
                self.left_type = false
                self.grd_bg:setVisible(true)
                self.node_di:setVisible(true)
                for i=1,6 do
                    self.grid_node:getChildByName("grdi_icon"..i):setVisible(true)
                end
            end,
            50/60
    )
end

function CashDisyLayer:playRightAction(_type)
    gLobalSoundManager:playSound(self.config.SoundPath.SLIDE)
    self.grd_bg:setVisible(true)
    self.node_di:setVisible(true)
    self.grid_node:setVisible(true)
    self.girdView_one:setVisible(true)
    local act = cc.PageTurn3D:create(0.8, cc.size(15,10))
    local callFunc = cc.CallFunc:create(function()
        if tolua.isnull(self) then
            return
        end
        self.right_type = false
        self.girdView_one:setVisible(false)
    end)
    local seq = cc.Sequence:create(act,callFunc)
    self.girdView_one:runAction(seq)
    util_performWithDelay(
            self,
            function()
                if tolua.isnull(self) then
                    return
                end
                self.grd_bg:setVisible(false)
                self.node_di:setVisible(false)
                self.grid_node:setVisible(false)
                if not _type then
                    local idx = self.pageView:getCurrentPageIndex()
                    self:updatePageViewPoint()
                end
            end,
            8/60
    )
end

return CashDisyLayer