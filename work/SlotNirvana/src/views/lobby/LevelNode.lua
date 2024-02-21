--
--大厅关卡容器节点 用来放JACKPOT 或者一列多个关卡情况
--
local LevelNode = class("LevelNode", util_require("base.BaseView"))

local JACKPOT_SPAN = 20 --jackpot图标间距
local LINE_STAR_OFFSET_X = 65 -- 星星线和左边的大关卡之间的距离
local LINE_SLOT_OFFSET_X = 41 -- slot线和左边的活动入口之间的距离

function LevelNode:ctor()
    LevelNode.super.ctor(self)
    self.m_info = nil
    -- 是否创建了关卡node(small,big)
    self.m_bCreateLevelNode = false
    self.m_nodes = {}

    self.m_touch = nil
    self.m_distance = nil
    self.m_index = nil
    self.m_spPendant = nil

    self.m_actionDatas = {}
end

function LevelNode:initUI(data, index)
    self:createCsbNode("Lobby/LevelNode.csb")
    self.m_jackpot = self:findChild("txt_jackpot")
    -- self:refreshInfo(data, index)
end

function LevelNode:setIndex(idx)
    self.m_index = idx
end

-- function LevelNode:onEnter()
--     --活动结束
--     gLobalNoticManager:addObserver(
--         self,
--         function(self, params)
--             self:closeActivityNode()
--         end,
--         ViewEventType.NOTIFY_ACTIVITY_FIND_CLOSE
--     )
-- end

function LevelNode:setSiteInfo(siteType, siteName)
    for i = 1, #self.m_nodes do
        local _node = self.m_nodes[i]
        if _node then
            _node:setSiteType(siteType)
            _node:setSiteName(siteName)
        end
    end
end

function LevelNode:removeSelf()
end

function LevelNode:setLvAction(key, action)
    if not key then
        return
    end
    self.m_actionDatas["" .. key] = action
end

function LevelNode:getLvAction(key)
    return self.m_actionDatas["" .. key]
end

function LevelNode:getNodeCell(index)
    if not index then
        return
    end
    return self.m_nodes[index]
end

function LevelNode:refreshInfo(data, index)
    if self.m_index and self.m_index == index then
        return
    end
    self.m_index = index
    self.m_info = data or {}
    if self.m_info.isSmall then
        --并排关卡节点
        self.m_nodes[1] = self:createLevel(self.m_info[1], 0, 128, 1)
        if self.m_info[2] then
            self.m_nodes[2] = self:createLevel(self.m_info[2], 0, -128, 2)
        end
    else
        if self.m_info[1].layoutList then
            -- 广播条
            self.m_nodes[1] = self:createLayout(self.m_info[1].layoutList, 0, 0)
            globalData.saleRunData.m_lobbyLayoutNode = self.m_nodes[1]
        elseif self.m_info[1].activity then
            -- 活动新逻辑
            self.m_nodes[1] = self:createActivity(self.m_info[1], 0, 0)
        elseif self.m_info[1].feature then
            -- 功能展示图逻辑
            self.m_nodes[1] = self:createFeature(self.m_info[1], 0, 0)
        elseif self.m_info.isRecommend then
            -- 推荐关卡
            self.m_nodes[1] = self:createRecommend(self.m_info[1], 0, 0)
        else
            -- 普通关卡节点
            if CC_DYNAMIC_DOWNLOAD then
                self.m_nodes[1] = self:createLevel(self.m_info[1], 0, 0, 1)
            else
                self.m_nodes[1] = self:createLevel(self.m_info[1], 0, 0, 1)
            end

        end
    end
    if self.m_nodes[1] then
        self.m_contentLen = self.m_nodes[1]:getContentLen()
    end

    

end

function LevelNode:createLayout(list, offx, offy)
    local pageNode = util_createView("views.lobby.LevelLayoutNode")
    self.m_levelLayoutNode = pageNode
    self:addChild(pageNode, -1)
    pageNode:setPosition(offx, offy)
    local currLevelNum = globalData.userRunData.levelNum
    local pageCount = 0
    for i = 1, #list do
        -- setDefaultTextureType("RGBA8888", nil)
        if list[i] == LOBBY_LAYOUT_CARD_NOVICE_DOUBLE_REWARD then
            local node = util_createView("views.lobby.LevelCardNoviceDoubleRewardSlideNode")
            pageNode:addPage(node, "CardNoviceDoubleRewardSlide", 1)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_CARD_NOVICE_SALE then
            local node = util_createView("views.lobby.LevelCardNoviceSaleSlideNode")
            pageNode:addPage(node, "CardNoviceSaleSlide", 1)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_FACEBOOK then
            local node = util_createView("views.lobby.LevelFaceBookNode")
            pageNode:addPage(node, "facebook", 1)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_FIRSTBUY and currLevelNum >= (globalData.constantData.FIRSTPAYSLID_TIPS_LEVEL or 0) then
            local node = util_createView("views.lobby.LevelFirstBuyNode")
            pageNode:addPage(node, "firstBuy", 2)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_FIRST_SALE_MULTI then
            local node = util_createView("views.lobby.LevelFirstSaleMultiSlideNode")
            pageNode:addPage(node, "FirstSaleMultiSlide", 3)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_FIRSTCOMMOMSALE and currLevelNum < (globalData.constantData.NOVICE_FIRSTPAY_ENDLEVEL) and G_GetMgr(G_REF.FirstCommonSale):getSaleOpenData() then
            local node = util_createView("views.lobby.LevelFirstCommomSaleSlideNode")
            pageNode:addPage(node, "firstCommomSaleSlide", 3)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_NEW_USER_CARD_OPEN then
            -- 新手期集卡开启 活动
            local node = util_createView("views.lobby.LevelNewUserCardOpenSlideNode")
            pageNode:addPage(node, "LevelNewUserCardOpenSlide", 4)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_ICEBREAKERSLAE then
            -- 新破冰促销
            local node = util_createView("views.lobby.LevelIcebreakerSaleSlideNode")
            pageNode:addPage(node, "LevelIcebreakerSaleSlide", 5)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_NEWUSER_QUEST and globalData.GameConfig:checkUseNewNoviceFeatures() then
            local node = util_createView("views.lobby.LevelQuestNewUserSlideNode")
            pageNode:addPage(node, "newUserQuestSlide", 6)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_BIRTHDAYSLAE then
            -- 生日礼物促销
            local node = util_createView("views.lobby.LevelBirthdaySaleSlideNode")
            pageNode:addPage(node, "LevelBirthdaySaleSlide", 7)
            pageCount = pageCount + 1
        elseif list[i] == LOBBY_LAYOUT_SALE then
            --获取所有活动数据
            local datas = globalData.commonActivityData:getActivitys()
            pageCount = pageCount + self:checkAddSale(pageNode, datas)
        end
        -- setDefaultTextureType("RGBA4444", nil)
    end
    if pageCount == 0 then
        -- setDefaultTextureType("RGBA8888", nil)
        local node = util_createView("views.lobby.LevelRateusNode")
        pageNode:addPage(node, "rateus")
    -- setDefaultTextureType("RGBA4444", nil)
    end

    return pageNode
end

function LevelNode:checkAddSale(pageNode, activityDatas)
    local pageCount = 0
    local activityInfo = {}

    for k, value in pairs(activityDatas) do
        local data = value
        local refName = data:getRefName()
        local refMgr = G_GetMgr(refName)
        if refMgr then
            if refMgr:isCanShowSlide() then
                activityInfo[#activityInfo + 1] = data
            end
        else
            if data and data:isRunning() then
                if data.p_slideImage and data.p_slideImage ~= "" then
                    activityInfo[#activityInfo + 1] = data
                end
            end
        end
    end

    --根据弹板中配置
    for i = 1, #activityInfo do
        local _info = activityInfo[i]
        local controlData = PopUpManager:getPopupControlData(_info)
        if controlData then
            _info.m_slidZoder = controlData.p_slidPriority
            _info.m_slidShow = controlData.p_slidShow
        end
    end

    for i = #activityInfo, 1, -1 do
        if not activityInfo[i].m_slidShow or activityInfo[i].m_slidShow == 0 then
            table.remove(activityInfo, i)
        end
    end

    table.sort(
        activityInfo,
        function(a, b)
            return a.m_slidZoder < b.m_slidZoder
        end
    )

    for i = 1, #activityInfo do
        local data = activityInfo[i]
        --资源不存在，不创建  --主题促销轮播图放到展示图上
        if util_IsFileExist(data.p_slideImage) then
            if data.p_activityType ~= ACTIVITY_TYPE.THEME and not data:isCompleted() then
                local slideName = ""
                local _mgr = G_GetMgr(data:getRefName())
                if _mgr then
                    slideName = _mgr:getSlideModule()
                else
                    slideName = data:getSlideModule()
                end

                if slideName ~= "" then
                    local slideNode = util_createView(slideName, data)

                    if slideNode ~= nil then
                        pageNode:addPage(slideNode, data:getID(), 999 + i, data) -- 999 活动相关轮播需要放到最后 系统轮播后边
                        pageCount = pageCount + 1
                    end
                end
            end
        else
            if isMac() then
                printError("slide path:" .. tostring(data.p_slideImage) .. " is not exist!!!")
            end
        end
    end
    return pageCount
end


function LevelNode:createFeature(info, offx, offy)
    -- setDefaultTextureType("RGBA8888", nil)
    local node = util_createView("views.lobby.Level" .. info.feature.key .. "Node", info, self.m_index)
    self:addChild(node, -1)
    node:setPosition(offx, offy)
    -- setDefaultTextureType("RGBA4444", nil)
    return node
end

function LevelNode:createActivity(info, offx, offy)
    -- setDefaultTextureType("RGBA8888", nil)
    local node = util_createView("views.lobby.LevelActivity", info)
    self:addChild(node, -1)
    node:setPosition(offx, offy)
    self:refreshPendant(node)
    -- setDefaultTextureType("RGBA4444", nil)
    return node
end

function LevelNode:createRateus(info, offx, offy)
    local node = util_createView("views.lobby.LevelRateusNode")
    self:addChild(node, -1)
    node:setPosition(offx, offy)
    return node
end

function LevelNode:createLevel(info, offx, offy, index)
    self.m_bCreateLevelNode = true
    local node = nil
    if self.m_info.isSmall then
        node = self:getChildByName("Small_" .. index)
        if not node then
            node = util_createView("views.lobby.LevelSmallNode")
            node:setName("Small_" .. index)
            self:addChild(node, -1)
        end
        -- local _times = socket.gettime()
        node:updateInfo(info)
        -- printInfo(string.format("--levelnode-- createLevel1 = %3f", socket.gettime() - _times))
        -- _times = socket.gettime()
        node:setPosition(offx, offy)
        self:refreshPendant(node)
        -- printInfo(string.format("--levelnode-- createLevel2 = %3f", socket.gettime() - _times))
    else
        -- 没有关卡大入口了，注释掉
        -- node = util_createView("views.lobby.LevelBigNode", info)
        -- self:addChild(node, -1)
        -- node:setPosition(offx, offy)
        -- self:refreshPendant(node)
        
        node = self:getChildByName("Long_" .. index)
        if not node then
            node = util_createView("views.lobby.LevelLongNode", info)
            node:setName("Long_" .. index)
            self:addChild(node, -1)
        end
        node:updateInfo(info)
        node:setPosition(offx, offy)
        self:refreshPendant(node)
    end
    return node
end

-- 推荐关卡
function LevelNode:createRecommend(info, offx, offy)
    self.m_bCreateLevelNode = true
    -- setDefaultTextureType("RGBA8888", nil)
    local node = nil
    if info:getIsSlotMod() then
        node = util_createView("views.lobby.LevelRecmdNodeMod", info)
        self:addChild(node, -1)
        node:setPosition(offx, offy)
    else
        node = util_createView("views.lobby.LevelRecmdNode", info)
        self:addChild(node, -1)
        node:setPosition(offx, offy)
    end
    -- setDefaultTextureType("RGBA4444", nil)
    return node
end

--下载完成
-- function LevelNode:finishDownload(csbName)
--     local index = 1
--     if self.m_info.isSmall and self.m_info[2] and self.m_info[2].p_csbName == csbName then
--         index = 2
--     end
--     local node = self.m_nodes[index]
--     local path = nil
--     if node then
--         node:removeFromParent()
--         self.m_nodes[index] = nil
--     end
--     local pos = cc.p(0, 0)
--     if self.m_info.isSmall then
--         if index == 1 then
--             pos = cc.p(0, 130)
--         else
--             pos = cc.p(0, -130)
--         end
--     end
--     self.m_nodes[index] = self:createLevel(self.m_info[index], pos.x, pos.y, true)
--     self.m_contentLen = self.m_nodes[index]:getContentLen()
-- end

function LevelNode:getContentLen()
    -- return self.m_contentLen or 0
    local _node = self.m_nodes[1]
    if not _node then
        return 0
    else
        return _node:getContentLen()
    end
end

-- 横向偏移坐标
function LevelNode:getOffsetPosX()
    local _node = self.m_nodes[1]
    if not _node then
        return 0
    else
        return _node:getOffsetPosX()
    end
end

--刷新挂件
function LevelNode:refreshPendant(node)
    if not node then
        node = self.m_nodes[1]
    end
    if tolua.isnull(node) then
        return
    end

    if self.m_spPendant then
        self.m_spPendant:removeFromParent()
        self.m_spPendant = nil
        self.m_spSlot = false
        self.m_slotFileName = ""
    end

    if not self.m_info then
        return
    end

    local isShowSlotLine = function(_info)
        if _info.activity or _info.layoutList or _info.feature then
            return true
        else
            return false
        end
    end

    local count = globalData.activityCount or 0
    if count > 0 and count == self.m_index and isShowSlotLine(self.m_info[1]) then
        -- SLOT线
        self.m_slotFileName = "sp_line_slot.png"
        if globalData.deluexeClubData:getDeluexeClubStatus() == true then
            self.m_slotFileName = "sp_line_deluxeclub.png"
        end
        local sp = display.newSprite(self.m_slotFileName)
        self:addChild(sp, -1)
        sp:setPosition(node:getContentLen() * 2 - node:getOffsetPosX() + LINE_SLOT_OFFSET_X, 0)
        self.m_spPendant = sp
        self.m_spSlot = true
    elseif count == 0 and self.m_info.isStart == true then
        node.m_contentLenX = 150
        self.m_slotFileName = "sp_line_deluxeclub.png"
        local sp = display.newSprite(self.m_slotFileName)
        self:addChild(sp, -1)
        sp:setPosition(-node:getOffsetPosX() + 10, 0)
        self.m_spPendant = sp
        self.m_spSlot = true
        node:setPositionX(25)
    elseif self.m_info.isPendant then
        local sp = display.newSprite("sp_line_star.png")
        self:addChild(sp, -1)
        sp:setPosition(-node:getOffsetPosX() - LINE_STAR_OFFSET_X, 0)
        self.m_spPendant = sp
        self.m_spSlot = false
        self.m_slotFileName = "sp_line_star.png"
    end

    self:initActivityNode()
end

function LevelNode:updateUI()
    for i = 1, #self.m_nodes do
        self.m_nodes[i]:updateUI()
    end
end

-- 更新显示状态
function LevelNode:updateLevelVisible(isVisible)
    self:setVisible(isVisible)

    self:updateLevelLogo(isVisible)
end

-- 更新关卡logo显示
function LevelNode:updateLevelLogo(isVisible)
    for i = 1, #self.m_nodes do
        local _node = self.m_nodes[i]
        if _node then
            _node:setVisible(isVisible or false)
            -- if _node.isNeedUpdateLogo and _node:isNeedUpdateLogo() then
            if _node.updateLevelLogo then
                _node:updateLevelLogo()
            end
            -- end
        end
    end
end

-- 移除关卡logo显示
function LevelNode:removeLevelLogo()
    for i = 1, #self.m_nodes do
        local _node = self.m_nodes[i]
        if _node and _node.isShowedLogo and _node:isShowedLogo() then
            _node:removeSpinAnimNode()
        end
    end
end

--活动开启
function LevelNode:initActivityNode()
    if self.m_spPendant ~= nil then
        local data = {}
        data["spPendant"] = self.m_spPendant
        data["spSlot"] = self.m_spSlot
        gLobalActivityManager:InitLobbyFengeLine(data)
    end
end

--活动结束
function LevelNode:closeActivityNode()
    if self.m_spPendant ~= nil and self.m_slotFileName ~= nil and self.m_slotFileName ~= "" then
        self.m_spPendant:setTexture(self.m_slotFileName)
    end
end

-- 根据高倍场开启状态更新 关卡(small, big) 表现(不需要更新数据)
function LevelNode:updateDeluxeLevels(_bOpenDeluxe)
    if not self.m_bCreateLevelNode or not self.m_info then
        return
    end

    --   node :type ==  LevelBaseNode  大厅关卡节点(updateDeluxeLevels放到 small big)
    for i, node in ipairs(self.m_nodes) do
        node:updateDeluxeLevels(_bOpenDeluxe)
    end
end

-- 初始化Jackpot
function LevelNode:initCommonJackpot()
    if self.m_info.isSmall then
        if self.m_nodes and #self.m_nodes > 0 then
            for i = 1, #self.m_nodes do
                self.m_nodes[i]:initCommonJackpot()
            end
        end
    end
end

function LevelNode:onEnterFinish()
    LevelNode.super.onEnterFinish(self)
    self:updateApdatUI()
end
function LevelNode:updateApdatUI()
    if not tolua.isnull(self.m_levelLayoutNode) then
        self.m_levelLayoutNode:updateLobbyVedioNodePos()
    end
end

return LevelNode
