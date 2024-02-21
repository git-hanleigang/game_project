--[[
    Quest Pass
]]

local QuestPassLayer = class("QuestPassLayer", BaseLayer)

function QuestPassLayer:ctor()
    QuestPassLayer.super.ctor(self)

    self:setLandscapeCsbName(QUEST_RES_PATH.QuestPassLayer)
    self:setExtendData("QuestPassLayer")
end

function QuestPassLayer:initDatas()
    self.m_gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    self.m_passData = self.m_gameData:getPassData()
    self.m_allRewards = self.m_passData:getAllCanCollectReward()
end

function QuestPassLayer:initCsbNodes()
    self.m_passPanel = self:findChild("passPanelLayout")
    self.m_node_rewardTopUI = self:findChild("node_rewardTopUI")
    self.m_node_fixedReward = self:findChild("node_fixedReward")
    self.m_node_Pre = self:findChild("node_Pre")
    self.m_passPanel:setSwallowTouches(false)

    self.m_node_prograss = self:findChild("node_prograss")
end

function QuestPassLayer:initView()
    self:initRewardTable()
    self:initRewardTopUI()
    self:initPreviewNode()
    self:initSeasonProgressNode()
end

function QuestPassLayer:initRewardTable()
    local tmpSize = self.m_passPanel:getContentSize()
    local tableViewInfo = {
        tableSize = tmpSize,
        parentPanel = self.m_passPanel,
        directionType = 1 --1 水平方向 ; 2 垂直方向
    }
    local tableView = util_require(QUEST_CODE_PATH.QuestPassTableView)
    self.m_passTable = tableView:create(tableViewInfo)
    self.m_passTable:reload(self)
    self.m_passPanel:addChild(self.m_passTable)
end

function QuestPassLayer:initRewardTopUI()
    local topUI = util_createView(QUEST_CODE_PATH.QuestPassTopUI, self)
    self.m_node_rewardTopUI:addChild(topUI)
end

function QuestPassLayer:initSeasonProgressNode()
    local topProgressUI = util_createView(QUEST_CODE_PATH.QuestPassSeasonProgressNode)
    self.m_node_prograss:addChild(topProgressUI)
end

function QuestPassLayer:setTouch(_flag)
    self.m_isTouch = _flag
end

function QuestPassLayer:getTouch()
    return self.m_isTouch
end

function QuestPassLayer:onShowedCallFunc()
    if self.m_passData then
        local boxData = self.m_passData:getBoxReward()
        local payUnlocked = self.m_passData:getPayUnlocked()
        if payUnlocked and boxData.p_curExp >= boxData.p_totalExp then
            boxData.p_level = -1000
            G_GetMgr(ACTIVITY_REF.Quest):sendPassBoxCollect(boxData, "box")
        end
    end
end

function QuestPassLayer:clickFunc(_sender)
    local name = _sender:getName()
    if name == "btn_close" then
        self:closeUI()
        G_GetMgr(ACTIVITY_REF.Quest):showPassBuyTicketRewardPreviewLayer()
    elseif name == "btn_info" then
        G_GetMgr(ACTIVITY_REF.Quest):showPassRuleLayer()
    end
end

-- 创建奖励界面
function QuestPassLayer:createRewardUI(_data)
    if not _data or not _data.p_level then
        self:setTouch(false)
        return
    end

    local rewardData = _data
    if _data.p_level == -1 then
        rewardData = self.m_allRewards
    end
    local view =  util_createView(QUEST_CODE_PATH.QuestPassRewardLayer) 
    if view then
        view:updateView(rewardData)
        if self.m_gameData then
            self.m_passData = self.m_gameData:getPassData()
            self.m_allRewards = self.m_passData:getAllCanCollectReward()
        end
        gLobalViewManager:showUI(view, ViewZorder.ZORDER_UI)
    end

    self:setTouch(false)
end

function QuestPassLayer:registerListener()
    QuestPassLayer.super.registerListener(self)

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.success then
                self:createRewardUI(params.data)
            else
                self:setTouch(false)
            end
        end,
        ViewEventType.NOTIFY_QUEST_PASS_COLLECT
    )

    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if params and params.success then
                if self.m_gameData then
                    local passData = self.m_gameData:getPassData()
                    self.m_allRewards = passData:getAllCanCollectReward()
                end
            else
                self:setTouch(false)
            end
        end,
        ViewEventType.NOTIFY_QUEST_PASS_PAY_UNLOCK
    )

    -- 活动到期
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.name == ACTIVITY_REF.Quest then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_ACTIVITY_TIMEOUT
    )

     -- 显示宝箱奖励信息
     gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            if params and params.level ~= nil and params.boxType ~= nil then -- 补丁：发消息时可能极限点击切页
                local level = params.level
                local boxType = params.boxType
                local isPreview = params.isPreview
                self:showBoxQipao(boxType, level, isPreview)
            end
        end,
        ViewEventType.NOTIFY_QUESTPASS_SHOW_REWARD_INFO
     )
     gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:removeBoxRewardInfo(params)
        end,
        ViewEventType.NOTIFY_QUESTPASS_REMOVE_REWARD_INFO
    )
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:scrollToCurrentPos()
        end,
        ViewEventType.NOTIFY_QUESTPASS_SCROLLTOCURRENT_POS
    )
end


function QuestPassLayer:initPreviewNode()
    if not self.m_node_Pre then
        return
    end
    local code_Path = QUEST_CODE_PATH.QuestPassPreviewCellNode
    self.m_previewCell = util_createView(code_Path)
    self.m_node_Pre:addChild(self.m_previewCell)
    local previewIndex = 6 -- 默认
    if self.m_passTable then
        previewIndex = self.m_passTable:getPreviewIndex() or previewIndex
    end

    self.m_gameData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if self.m_gameData then
        self.m_passData = self.m_gameData:getPassData()
        local passInfo = self.m_passData:getPassInfoByIndex(previewIndex)
        self.m_previewCell:loadDataUi(passInfo,previewIndex)
    end
end

function QuestPassLayer:showBoxQipao(_boxType, _level, _isPreview)
    local actData = G_GetMgr(ACTIVITY_REF.Quest):getRunningData()
    if not actData then
        return
    end
    local passData = actData:getPassData()
    if not passData then
        return
    end
    local pointData = passData:getPassInfoByIndex(_level)
    local pos = {x = 0, y = 0}
    local boxInfo = nil
    if _boxType == "free" then
        if _isPreview == true then
            pos = self.m_previewCell:getCellPos(_boxType)
        else
            pos = self:getCellPos(_boxType, _level,cc.p(25,100))
        end
        if pos then
            boxInfo = pointData.free
        end
    elseif _boxType == "pay" then
        if _isPreview == true then
            pos = self.m_previewCell:getCellPos(_boxType)
        else
            pos = self:getCellPos(_boxType, _level,cc.p(25,100))
        end
        if pos then
            boxInfo = pointData.pay
        end
    end
    if boxInfo then
        self:removeBoxRewardInfo(true)
        self.uiQipao = util_createView(QUEST_CODE_PATH.QuestPassCellBubble)
        self:addChild(self.uiQipao,100)
        self.uiQipao:setPosition(pos)
        self.uiQipao:showView(boxInfo)
    end
    return self.uiQipao
end

function QuestPassLayer:getCellPos(_boxType, _level, _offset)
    -- 从tableView 中获取
    local node = nil
    node = self.m_passTable:getCellPos(_boxType, _level, _offset)
    return node
end

function QuestPassLayer:removeBoxRewardInfo(remove)
    if not tolua.isnull(self.uiQipao) then
        if remove == true then
            self.uiQipao:removeFromParent()
        end
        self.uiQipao = nil
    end
end

function QuestPassLayer:scrollToCurrentPos()
    self.m_passTable:setTablePos()
end

function QuestPassLayer:buyPassTicketSuccessGuide()
    if self.m_buyGuideIndex == nil then
        self.m_buyGuideIndex = 1
    end
    local buyGuideTotalNum = 4
    
    if self.m_buyGuideIndex == 1 then
        -- 让table view 移动到头
        self.m_passView:scrollTableViewByRowIndex(1, 0.5, 1, true)
    elseif self.m_buyGuideIndex == 2 then
        -- 播放 pay cell 块解锁动画
        
        performWithDelay(
            self,
            function()
                local pointConfig = actData:getPassPointsInfo()
                self.m_passView:scrollTableViewByRowIndex(#pointConfig, 1, 1, true)
            end,
            2.5
        )
    elseif self.m_buyGuideIndex == 3 then
        -- 播放保险箱解锁动画
        self.m_passView:buyPassUpdate("safeBox")
        performWithDelay(
            self,
            function()
                -- 回到当前进度
                local currLevel = actData:getLevel()
                self.m_passView:scrollTableViewByRowIndex(currLevel + 1, 0.5, 1, true)
            end,
            2
        )
    elseif self.m_buyGuideIndex == 4 then
        -- 判断当前保险箱是否可以领取
        if self:checkSafeBoxCompleted() then
            -- 移动界面到保险箱
            local pointConfig = actData:getPassPointsInfo()
            self.m_passView:scrollTableViewByRowIndex(#pointConfig, 1, 1, true)
            performWithDelay(
                self,
                function()
                    self.m_bInBuyTicketGuide = true
                    self:collectSafeBox()
                end,
                1.1
            )
        else
            performWithDelay(
                self,
                function()
                    self:buyPassTicketSuccessGuide()
                end,
                0.1
            )
        end
    end
    self.m_buyGuideIndex = self.m_buyGuideIndex + 1
end

return QuestPassLayer