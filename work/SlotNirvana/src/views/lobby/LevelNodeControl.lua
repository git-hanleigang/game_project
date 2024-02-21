--
--大厅关卡循环显示与控制
--

local LevelRecmdData = require("views.lobby.LevelRecmd.LevelRecmdData")
local LevelNodeControl = class("LevelNodeControl", BaseSingleton)

-- LevelNodeControl.m_nodePool = nil

-- LevelNodeControl.m_nodeList = nil
-- LevelNodeControl.m_levelInfoList = nil
-- LevelNodeControl.m_contentX = nil

--新增的广播节点
-- LevelNodeControl.m_broadcast = nil
--广播信息
-- LevelNodeControl.m_broadcastInfo = nil

local STARTX = 50 --轮播图距离左边距离
local FIRSTHALL = 30 --第一个展示图和缝的距离
local OFFSETX = 330 --第一个图标位置
local FIRST_BIG_LEVEL = 41 -- 第一个大关卡和左边的分割线的距离
local OFFSETX_BIG_LEVEL = 48 --图标间距
local OFFSETX_MUL_SPAN = 48 --多个轮播图间隔

local LINE_STAR_OFFSET_X = 65 -- 星星线和左边的大关卡之间的距离
local OFFSET_SMALL_LEVEL_GROUP = 68 -- 第一个小关卡和左边的线的距离，也是小关卡组之间的间距
local OFFSETX_SMALL_LEVEL = 50 -- 每一个小关卡左右间距
-- local OFFSETY_SMALL_LEVEL = 34 -- 每一个小关卡上下间距

local WIDTH = 1370 --屏幕宽度
local OFFY = 6 --图标y轴偏移
-- LevelNodeControl.m_spanPos = nil
-- LevelNodeControl.m_scroll = nil
-- LevelNodeControl.m_iLevelsStartID = nil -- 关卡开始 ID
-- LevelNodeControl.m_vecBigLevels = nil
-- LevelNodeControl.m_bigLevelsInfo = nil

-- LevelNodeControl.m_isFreshLevel = nil --是否正在刷新节点

-- 宽度列表
local levelWidth = {
    small = {
        level = 120
    },
    big = {
        layoutList = 110.5,
        activity = 115.5,
        feature = 110,
        level = 110,
        recommend = {
            fold = 200,
            unfold = 570
        }
    }
}

-- 坐标偏移列表
local posXOffset = {
    small = {
        level = 120
    },
    big = {
        layoutList = 110.5,
        activity = 115.5,
        feature = 110,
        level = 110,
        recommend = 200
    }
}

-- function LevelNodeControl:ctor()
-- end

--释放资源
function LevelNodeControl:purge()
    self:stopLoadLevels()
    self.m_content = nil
    self.m_nodeList = nil
    self.m_levelInfoList = nil
    self.m_levelPos = {}
    self.m_broadcast = nil
    self.m_broadcastInfo = {}
    self.m_nodePool = nil
    self.m_isFreshLevel = false
    self.m_iLevelsStartID = nil
    self.m_scroll:removeScrollEvent()
    self.m_scroll = nil
end

function LevelNodeControl:initData(node, boradcast, layerMaskl, backFront)
    self.m_nodePool = {}
    self.m_content = node
    self.m_broadcast = boradcast
    self.m_layerMaskl = layerMaskl
    self.m_backFront = backFront

    self.m_nodeList = {}
    self.m_levelInfoList = {}
    self.m_levelPos = {}
    self.m_vecBigLevels = {}
    self.m_broadcastInfo = {}
    -- 关卡池
    self.m_nodeLevelPools = {}

    self.m_isFreshLevel = false
    self.m_iLevelsStartID = nil
    self.m_scroll = nil

    self:initUI()
end

-- function LevelNodeControl:setScrollControl(scroll)
--     self.m_scroll = scroll
-- end

function LevelNodeControl:initLevelScroll()
    --初始坐标 或上次进入游戏坐标
    local startX = self:getLobbyScorllX()
    local function moveFunc(contentX)
        local dt = contentX - self:getLobbyScorllX()
        if dt ~= 0 then
            self:updateNodeVisibleByMove(contentX, dt)
            globalData.lobbyScorllx = contentX
        end

        if self.m_backFrontNode then
            local firstIndex = self:getLobbyFirstLevelNodeIndex()
            local levelNodeX = self:_initLevelNodePos(firstIndex) - LINE_STAR_OFFSET_X * 2
            if contentX < -levelNodeX then
                self.m_backFrontNode:playOpen()
            else
                self.m_backFrontNode:playClose()
            end
        end
    end
    self.m_scroll = util_createView("views.lobby.LevelScrollControl", self.m_content, cc.p(startX, display.cy), moveFunc)
    -- self:setScrollControl(self.m_scroll)
end

function LevelNodeControl:moveToLevelNode(posX, secs)
    secs = secs or 0
    if self.m_scroll then
        local curPos = self:getLobbyScorllX()
        local difX = math.abs(posX - curPos)
        if difX <= display.width then
            self.m_scroll:move(posX, secs)
        else
            self:jumpToRecmdNode(posX)
        end
    end

    -- 刷新显示
    -- self:updateNodeVisibleByJump(posX)
end

function LevelNodeControl:jumpToLevelNode(x)
    local scrollX = self:getLeveToCenterOffset(x)
    -- 当前大厅滑动偏移
    local curLobbyOffset = self:getLobbyScorllX()
    if math.abs(scrollX - curLobbyOffset) < OFFSETX_SMALL_LEVEL then
        -- 偏移小于小关卡间距就不跳转了
        return
    end
    if self.m_scroll then
        self.m_scroll:move(scrollX)
    end
    -- 刷新显示
    self:updateNodeVisibleByJump(scrollX)
end

function LevelNodeControl:jumpToRecmdNode(scrollX)
    if self.m_scroll then
        self.m_scroll:move(scrollX)
    end
    -- 刷新显示
    self:updateNodeVisibleByJump(scrollX)
end

-- 跳转到最前端
function LevelNodeControl:jumpToFront()
    if self.m_scroll then
        self.m_scroll:stopAutoScroll()
        self.m_scroll:move(0)
    end
    -- 刷新显示
    self:updateNodeVisibleByJump(0)
end

-- 设置返回最前端按钮显隐
function LevelNodeControl:setBackFrontBtnVisible(_isVisible)
    if _isVisible then
        self.m_backFrontNode:setIsCollectLevel(false)
        local pos = cc.p(self.m_content:getPosition())
        local firstIndex = self:getLobbyFirstLevelNodeIndex()
        local levelNodeX = self:_initLevelNodePos(firstIndex) - LINE_STAR_OFFSET_X * 2
        if pos.x < -levelNodeX then
            self.m_backFrontNode:playOpen()
        else
            self.m_backFrontNode:playClose()
        end
    else
        self.m_backFrontNode:setIsCollectLevel(true)
        self.m_backFrontNode:playClose()
    end
end

function LevelNodeControl:updateScroll()
    --校正位置
    if self.m_scroll and self.m_scroll.isMoveBoundary and self.m_scroll:isMoveBoundary() then
        self.m_scroll:initAutoScroll()
        self.m_scroll:startBoundary()
    end
    local startX = self:getLobbyScorllX()
    local firstIndex = self:getLobbyFirstLevelNodeIndex()
    local levelNodeX = self:_initLevelNodePos(firstIndex) - LINE_STAR_OFFSET_X * 2
    if startX < -levelNodeX then
        if self.m_backFrontNode then
            self.m_backFrontNode:playOpen()
        end
    end
end

function LevelNodeControl:getNodeInPool(index)
    local _node = self.m_nodePool[index]
    if not _node or _node == "nil" then
        return nil
    else
        return _node
    end
end

function LevelNodeControl:getNodeCell(idxCol, idxRow)
    local _node = self:getNodeInPool(idxCol)
    if _node then
        return _node:getNodeCell(idxRow)
    else
        return nil
    end
end

-- 获得一列空闲的levelNode
function LevelNodeControl:getLevelNode(index, info)
    local _node = self:getNodeInPool(index)
    if not _node then
        if info.isSmall then
            _node = table.remove(self.m_nodeLevelPools, 1)
            if not _node then
                _node = util_createView("views.lobby.LevelNode")
                _node:setName("LevelSmallNode")
                self.m_content:addChild(_node)
            end
        else
            _node = util_createView("views.lobby.LevelNode")
            self.m_content:addChild(_node)
        end
        _node:setTag(index)
    end
    return _node
end

-- 使用一列levelNode
function LevelNodeControl:applyLevelNode(index)
    -- local _times = socket.gettime()
    -- printInfo(string.format("--levelnode-- refreshInfo begin"))
    -- _times = socket.gettime()
    local _info = self.m_levelInfoList[index]
    local _node = self:getLevelNode(index, _info)
    if _node then
        local _action = _node:getLvAction("move")
        if _action then
            -- 停止移动动作
            _node:stopAction(_action)
            _node:setLvAction("move", nil)
        end

        local posX = self:getLevelNodePos(index)
        _node:setPositionX(posX)
        self.m_nodePool[index] = _node
        _node:refreshInfo(_info, index)
        -- printInfo(string.format("--levelnode-- refreshInfo1 = %3f", socket.gettime() - _times))
        -- _times = socket.gettime()
        _node:initCommonJackpot()
        -- printInfo(string.format("--levelnode-- refreshInfo2 = %3f", socket.gettime() - _times))
        -- _times = socket.gettime()
        _node:updateLevelVisible(true)
        -- printInfo(string.format("--levelnode-- refreshInfo3 = %3f", socket.gettime() - _times))
    end
    -- printInfo(string.format("--levelnode-- ==========="))
    -- _times = socket.gettime()
    return _node
end

-- 回收一列levelNode
function LevelNodeControl:recycleLevelNode(index)
    local _node = self:getNodeInPool(index)
    if _node then
        _node:updateLevelVisible(false)
        if _node:getName() == "LevelSmallNode" then
            _node:removeLevelLogo()
            _node:setTag(0)
            _node:setIndex(0)
            self.m_nodePool[index] = "nil"
            table.insert(self.m_nodeLevelPools, _node)
        end
    end

end

function LevelNodeControl:initUI()
    self:initLevelInfoList()
    -- local curTime = socket.gettime()
    self:initLevelNode()
    -- addCostRecord("Slide", socket.gettime() - curTime)
    -- 更新关卡节点X坐标
    self:updateLevelNodePosX()
end

--大厅节点顺序
-- cxc 2020年12月04日17:36:04
-- 显示规则： 1. 不显示大图标， 2. 开启高倍场都显示金边， 不开启高倍场都显示普通边
function LevelNodeControl:initLevelInfoList()
    -- 初始化轮播图
    if self:canShowFirstCommonSale(true) then
        -- 未购买首充
        self:initLayoutNodeList_fistSale()
    else
        self:initLayoutNodeList_normal()
    end

    globalData.activityCount = 0
    local nextIndex = 0
    -- 非活动展示图
    nextIndex = self:initFeatureInfo(nextIndex)
    if globalData.userRunData.levelNum > 1 then
        -- 活动展示图
        nextIndex = self:initActivityInfo(nextIndex)
    end

    self.m_iLevelsStartID = nextIndex
    -- 大关卡
    -- self.m_bigLevelsInfo = self:getBigLevelInfoList()
    -- nextIndex = self:initBigLevelInfo(nextIndex, self.m_bigLevelsInfo)

    local _recmdLevelNodeCount = 0
    local _recmdObj = LevelRecmdData:getInstance()
    if _recmdObj then
        _recmdObj:freshUnlockLevels()
        local recmdGrops = _recmdObj:getShowingRecmdGrops()
        if #recmdGrops > 0 then
            local _recmdInfos = self:initRecmdLevelInfo(recmdGrops)
            _recmdLevelNodeCount = #_recmdInfos
            if _recmdLevelNodeCount > 0 then
                nextIndex = nextIndex + _recmdLevelNodeCount

                table.insertto(self.m_levelInfoList, _recmdInfos)

            -- self.m_levelInfoList[nextIndex].isPendant = true
            end
        end
    end

    --小关卡索引(只显示普通场就行，高倍场开启就显示个金边)
    local oriLevels = globalData.slotRunData:getMachineEntryDatas()
    local _smallLeves = self:initSmallLevelInfo(nextIndex, oriLevels)
    if #_smallLeves > 0 then
        local tempIdx = nextIndex
        nextIndex = nextIndex + #_smallLeves
        table.insertto(self.m_levelInfoList, _smallLeves)
        if _recmdLevelNodeCount == 0 then
            self.m_levelInfoList[tempIdx + 1].isPendant = false
        end
    end

    return nextIndex
end

function LevelNodeControl:getBigLevelInfoList()
    local newLevels = {}
    local curLevel = globalData.userRunData.levelNum
    if curLevel < globalData.constantData.OPENLEVEL_NORMALQUEST then
        return newLevels
    end
    local levels = globalData.slotRunData.p_machineDatas
    for k, v in ipairs(levels) do
        -- 补上p_openLevel 必须为1级才能展示
        if v.p_firstOrder and v.p_highBetFlag ~= true and v.p_maintain ~= true and v.p_openLevel == 1 then
            table.insert(newLevels, v)
        end
    end
    table.sort(
        newLevels,
        function(a, b)
            return a.p_firstOrder < b.p_firstOrder
        end
    )
    return newLevels
end

--[[
    初始化大厅里面的广播条
    未购买首充促销
    facebook, 首冲促销, 新手集卡
]]
function LevelNodeControl:initLayoutNodeList_fistSale()
    local layoutNodeList = {}

    -- 新手期集卡双倍奖励
    local bShowCardNoviceDoubleReward = G_GetMgr(G_REF.CardNoviceSale):canShowDoubleRewardHallSlide()
    if bShowCardNoviceDoubleReward then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_CARD_NOVICE_DOUBLE_REWARD
    end

    -- 新手期集卡 促销
    local bShowCardNoviceSale = G_GetMgr(G_REF.CardNoviceSale):canShowSaleHallSlide()
    if bShowCardNoviceSale then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_CARD_NOVICE_SALE
    end

    --facebook
    local isFacebook = gLobalSendDataManager:getIsFbLogin()
    if isFacebook == false then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_FACEBOOK
    end

    -- 三档首冲
    local bShowFirstSaleMulti = G_GetMgr(G_REF.FirstSaleMulti):isCanShowLayer()
    if bShowFirstSaleMulti then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_FIRST_SALE_MULTI
    end

    -- 首购促销
    local isFirstCommomSale = self:canShowFirstCommonSale()
    if isFirstCommomSale then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_FIRSTCOMMOMSALE
    end

    -- 新手期集卡开启 活动(排序规则不一样，当功能来做)
    if G_GetMgr(ACTIVITY_REF.CardOpenNewUser):canShowCustomSlide() then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_NEW_USER_CARD_OPEN
    end

    self.m_broadcastInfo = {}
    if #layoutNodeList > 0 then
        self.m_broadcastInfo[1] = {layoutList = layoutNodeList}
    end
end

--[[
    @desc: 初始化大厅里面的广播条
    time:2019-04-11 14:49:33
    facebook, 首冲, 首冲促销, 新版破冰促销, 新手期集卡（新增）, 新手quest, 生日礼物促销, 活动配置
]]
function LevelNodeControl:initLayoutNodeList_normal()
    --广播条
    local layoutNodeList = {}
    --  系统轮播顺序 {facebook, 首冲, 首冲促销, 新版破冰促销, 新手quest}

    -- 新手期集卡双倍奖励
    local bShowCardNoviceDoubleReward = G_GetMgr(G_REF.CardNoviceSale):canShowDoubleRewardHallSlide()
    if bShowCardNoviceDoubleReward then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_CARD_NOVICE_DOUBLE_REWARD
    end

    -- 新手期集卡 促销
    local bShowCardNoviceSale = G_GetMgr(G_REF.CardNoviceSale):canShowSaleHallSlide()
    if bShowCardNoviceSale then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_CARD_NOVICE_SALE
    end
    
    --facebook
    local isFacebook = gLobalSendDataManager:getIsFbLogin()
    if isFacebook == false then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_FACEBOOK
    end

    -- 三档首冲
    local bShowFirstSaleMulti = G_GetMgr(G_REF.FirstSaleMulti):isCanShowLayer()
    if bShowFirstSaleMulti then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_FIRST_SALE_MULTI
    end

    --首冲
    local isFirstBuy = self:canShowFirstBuy()
    if isFirstBuy then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_FIRSTBUY
    end

    -- 首购促销
    local isFirstCommomSale = self:canShowFirstCommonSale()
    if isFirstCommomSale then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_FIRSTCOMMOMSALE
    end

    -- 新版破冰促销
    local icebreakerSaleData = G_GetMgr(G_REF.IcebreakerSale):checkCanShowHallSlide()
    if icebreakerSaleData then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_ICEBREAKERSLAE
    end

    -- 新手期集卡开启 活动(排序规则不一样，当功能来做)
    if G_GetMgr(ACTIVITY_REF.CardOpenNewUser):canShowCustomSlide() then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_NEW_USER_CARD_OPEN
    end

    -- 新手Quest 轮播图
    if globalData.GameConfig:checkUseNewNoviceFeatures() then
        local questMgr = G_GetMgr(ACTIVITY_REF.Quest)
        if questMgr:isRunning() and questMgr:isNewUserQuest() then
            layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_NEWUSER_QUEST
        end
    end

    --促销默认加里面 活动放到最后
    layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_SALE

    -- 生日礼物促销
    local birthdayMgr = G_GetMgr(ACTIVITY_REF.Birthday)
    if birthdayMgr and birthdayMgr:isCanShowSlide() then
        layoutNodeList[#layoutNodeList + 1] = LOBBY_LAYOUT_BIRTHDAYSLAE
    end

    self.m_broadcastInfo = {}
    if #layoutNodeList > 0 then
        self.m_broadcastInfo[1] = {layoutList = layoutNodeList}
    end
end

-- 是否在小猪商店新手折扣活动期间
function LevelNodeControl:hasPiggyNoviceDiscount()
    local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    return piggyBankData and piggyBankData:checkInNoviceDiscount()
end

function LevelNodeControl:canShowFirstBuy()
    local isBuyed = globalData.shopRunData:isShopFirstBuyed()
    return not isBuyed
    -- TODO:
    -- return false
end

-- _bCheckFirstBuy 检查是否第一次购买首冲礼包
function LevelNodeControl:canShowFirstCommonSale(_bCheckFirstBuy)
    -- csc 2021-08-31 新手ABTEST 第三期 补充首充开启判断
    if globalData.userRunData.levelNum < globalData.constantData.NOVICE_FIRSTPAY_OPENLEVEL then
        return false
    end
    if
        globalData.GameConfig:checkUseNewNoviceFeatures() and globalData.userRunData.levelNum < (globalData.constantData.NOVICE_FIRSTPAY_ENDLEVEL or 100) and
            G_GetMgr(G_REF.FirstCommonSale):getRunningData()
     then
        if _bCheckFirstBuy then
            return G_GetMgr(G_REF.FirstCommonSale):checkIsFirstSaleType()
        end
        return true
    end
    return false
end

-- 功能展示图(非活动)
function LevelNodeControl:initFeatureInfo(infoIndex)
    local featureInfo = {}

    -- 限时集卡多倍奖励
    local isAlbumMoreAwardShow = G_GetMgr(ACTIVITY_REF.AlbumMoreAward):checkActivityOpen()
    if isAlbumMoreAwardShow then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "AlbumMoreAwardHall", p_csbname = ""}}

        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "AlbumMoreAwardSaleHall", p_csbname = ""}}
    end

    -- 新手期集卡双倍奖励
    local bShowCardNoviceDoubleReward = G_GetMgr(G_REF.CardNoviceSale):canShowDoubleRewardHallSlide()
    if bShowCardNoviceDoubleReward then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "CardNoviceDoubleRewardHall", p_csbname = ""}}
    end

    -- 新手期集卡 促销
    local bShowCardNoviceSale = G_GetMgr(G_REF.CardNoviceSale):canShowSaleHallSlide()
    if bShowCardNoviceSale then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "CardNoviceSaleHall", p_csbname = ""}}
    end
    
    -- 三档首冲
    local bShowFirstSaleMulti = G_GetMgr(G_REF.FirstSaleMulti):isCanShowLayer()
    if bShowFirstSaleMulti then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "FirstSaleMultiHall", p_csbname = ""}}
    end

    -- 首购促销
    local isFirstCommomSale = self:canShowFirstCommonSale()
    if isFirstCommomSale then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "FirstCommomSaleHall", p_csbname = ""}} -- 这里可以不用配置 csbname 到对应的lua文件中配置
    end

    -- 新版破冰促销
    local icebreakerSaleData = G_GetMgr(G_REF.IcebreakerSale):checkCanShowHallSlide()
    if icebreakerSaleData then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "IcebreakerSaleHall", p_csbname = "Icons/IcebreakerSaleHall"}}
    end

    -- 新手期集卡开启 活动(排序规则不一样，当功能来做)
    if G_GetMgr(ACTIVITY_REF.CardOpenNewUser):canShowCustomHall() and CardSysManager:isDownLoadCardRes() then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "NewUserCardOpenHall", p_csbname = "Icons/CardOpenhall_NewUser"}}
    end
    
    -- -- 小猪新手折扣促销 2023年07月26日17:20:10 展示过多隐藏该功能
    -- local piggyBankData = G_GetMgr(G_REF.PiggyBank):getData()
    -- local isIn = piggyBankData and piggyBankData:checkInNoviceDiscount()
    -- if isIn then
    --     infoIndex = infoIndex + 1
    --     globalData.activityCount = globalData.activityCount + 1
    --     self.m_levelInfoList[infoIndex] = {}
    --     self.m_levelInfoList[infoIndex][1] = {feature = {key = "PiggyNoviceDiscount", p_csbname = "Icons/Level_PiggyNoviceDiscount"}}
    -- end

    -- 新手Quest
    local questMgr = G_GetMgr(ACTIVITY_REF.Quest)
    if questMgr:isRunning() and questMgr:isNewUserQuest() then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "QuestNewUserHall", p_csbname = "QuestNewUser/Icons/QuestNewUserHall"}}
    end

    -- 聚合挑战结束促销
    local holidayEndSaleData = G_GetMgr(G_REF.HolidayEnd):getRunningData()
    if holidayEndSaleData and not holidayEndSaleData:isPay() then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "holidayEndSaleHall", p_csbname = "Icons/HolidayBox_Hall"}}
    end

    -- 限时促销
    if G_GetMgr(G_REF.HourDeal):canShowHallNode() then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "HourDealHall", p_csbname = ""}}
    end

    -- 生日礼物促销
    local birthdayMgr = G_GetMgr(ACTIVITY_REF.Birthday)
    if birthdayMgr and birthdayMgr:isCanShowHall() then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "BirthdaySaleHall", p_csbname = ""}}
    end
    
    return infoIndex
end

-- 活动展示图
function LevelNodeControl:initActivityInfo(infoIndex)
    local activityInfo = {}
    -- 获取所有活动数据
    local datas = globalData.commonActivityData:getActivitys()
    self:checkAddActivity(activityInfo, datas)
    if #activityInfo > 0 then
        self:sortActivityInfo(activityInfo)
        for i = 1, #activityInfo do
            self.m_levelInfoList[infoIndex + i] = {}
            self.m_levelInfoList[infoIndex + i][1] = {activity = activityInfo[i]}
        end
        infoIndex = infoIndex + #activityInfo
        globalData.activityCount = globalData.activityCount + #activityInfo
    end

    -- 亿万赢钱挑战 展示图 放到 活动后边
    local tcMgr = G_GetMgr(G_REF.TrillionChallenge)
    if tcMgr and tcMgr:isCanShowHall() then
        infoIndex = infoIndex + 1
        globalData.activityCount = globalData.activityCount + 1
        self.m_levelInfoList[infoIndex] = {}
        self.m_levelInfoList[infoIndex][1] = {feature = {key = "TrillionChallengeHall", p_csbname = ""}}
    end

    return infoIndex
end

--展示图优先级
function LevelNodeControl:sortActivityInfo(activityInfo)
    for i = 1, #activityInfo do
        local _info = activityInfo[i]
        local controlData = PopUpManager:getPopupControlData(_info)
        if controlData then
            _info.m_hallZoder = controlData.p_hallPriority
            _info.m_hallShow = controlData.p_hallShow
        end
    end

    for i = #activityInfo, 1, -1 do
        if not activityInfo[i].m_hallShow or activityInfo[i].m_hallShow == 0 then
            table.remove(activityInfo, i)
        end
    end

    table.sort(
        activityInfo,
        function(a, b)
            return a.m_hallZoder < b.m_hallZoder
        end
    )
end
--检测活动是否存在展示图
function LevelNodeControl:checkAddActivity(activityInfo, activityDatas)
    for k, value in pairs(activityDatas) do
        local data = value
        local refName = data:getRefName()
        local refMgr = G_GetMgr(refName)
        if refMgr then
            if refMgr:isCanShowHall() then
                -- if refMgr.randomShowHall then
                --     data = refMgr:randomShowHall(data)
                -- end
                activityInfo[#activityInfo + 1] = data
            end
        else
            if data:isRunning() then
                if data.p_hallImages and #data.p_hallImages > 0 and data.p_hallImages[1] ~= "" then
                    if util_IsFileExist(data.p_hallImages[1]) then
                        activityInfo[#activityInfo + 1] = data
                    else
                        printInfo("------>    活动展示图资源不存在 具体哪个不存在 到这里断点看 数据太复杂 打印不出来")
                    end
                end
            end
        end
    end
end

--初始化大入口关卡
-- function LevelNodeControl:initBigLevelInfo(infoIndex, levels)
function LevelNodeControl:initBigLevelInfo(levels)
    local levelInfoList = {}
    local infoIndex = 0
    local newHotsVersion = tonumber(util_getUpdateVersionCode(false))
    for i = 1, #levels do
        local levelData = levels[i]
        local levelVersion = levelData.p_hideVersion
        if levelVersion == nil then
            levelVersion = -1
        end
        if newHotsVersion >= levelVersion then
            infoIndex = infoIndex + 1
            local info = {isBig = true}
            info[1] = levelData
            table.insert(levelInfoList, infoIndex, info)
        -- self.m_vecBigLevels[#self.m_vecBigLevels + 1] = infoIndex
        end
    end

    return infoIndex, levelInfoList
end

-- 初始化推荐关卡
function LevelNodeControl:initRecmdLevelInfo(recmdGrops)
    local levelInfoList = {}

    for i = 1, #(recmdGrops or {}) do
        local _, _data = LevelRecmdData:getInstance():getRecmdInfoByGroup(recmdGrops[i])

        local isCanShow = _data:isCanShow()
        if isCanShow then
            local info = {
                [1] = {},
                isRecommend = true
            }

            info.isShow = _data:isShowed()

            local slotModInfos = _data:getSlotModInfo() or {}
            local levels = {}
            for j = 1, #slotModInfos do
                local levelName = slotModInfos[j].game
                local mod = slotModInfos[j].mod
                local levelInfo = globalData.slotRunData:getLevelInfoByName(levelName)
                if levelInfo and mod then
                    levelInfo = clone(levelInfo)
                    levelInfo:setSlotMod(true)
                    levelInfo:setLongIcon(mod == 1)
                end
                table.insert(levels, levelInfo)
            end

            info[1] = _data
            info[1].levelInfos = self:initSmallLevelInPage(levels)

            table.insert(levelInfoList, info)
        end
    end

    return levelInfoList
end

--初始化小关卡
function LevelNodeControl:initSmallLevelInfo(infoIndex, levels)
    -- 关卡分页
    local levelInfoList = self:initSmallLevelInPage(levels)

    -- 排序关卡
    levelInfoList = self:sortSmallLevel(levelInfoList)

    return levelInfoList
end

-- 小关卡分页
function LevelNodeControl:initSmallLevelInPage(levels)
    local levelInfoList = {}
    local infoIndex = 0
    local newHotsVersion = tonumber(util_getUpdateVersionCode(false))
    local col = 0
    local isNewRaw = nil
    local lastSmall = nil
    local page = 1

    --开一个新列
    local function newCol(levelData)
        infoIndex = infoIndex + 1
        if levelData.p_longIcon then
            levelInfoList[infoIndex] = {isSmall = false, page = page}
            levelInfoList[infoIndex][1] = levelData
        else
            levelInfoList[infoIndex] = {isSmall = true, page = page}
            levelInfoList[infoIndex][1] = levelData
            lastSmall = infoIndex
        end
    end

    --填充第二个小格子
    local function newRow(levelData)
        levelInfoList[lastSmall][2] = levelData
    end

    --遍历分组
    for i = 1, #levels do
        local levelData = levels[i]
        if levelData ~= nil then
            local levelVersion = levelData.p_hideVersion
            if levelVersion == nil then
                levelVersion = -1
            end
            if newHotsVersion >= levelVersion then
                --可以填充
                if lastSmall and not levelData.p_longIcon then
                    newRow(levelData)
                    lastSmall = nil
                else
                    --开新列
                    if col >= 3 then
                        col = 0
                        page = page + 1
                    end
                    newCol(levelData)
                    col = col + 1
                end
            end
        end
    end

    return levelInfoList
end

-- 小关卡排序
function LevelNodeControl:sortSmallLevel(levelInfoList)
    levelInfoList = levelInfoList or {}
    local curPage = nil
    local pageStartIndex = nil
    local pageOverIndex = nil
    local isEnd = nil
    for i = 1, #levelInfoList do
        if levelInfoList[i].page then
            if i == #levelInfoList then
                isEnd = true
            end
            if not curPage or curPage ~= levelInfoList[i].page or isEnd then
                --这里只适合1屏3列图标 如果后面有改动这里重写吧、、、
                if isEnd then
                    pageOverIndex = #levelInfoList
                end
                if pageStartIndex and pageOverIndex and pageStartIndex < pageOverIndex then
                    --先排序大图放前面
                    for index = pageStartIndex, pageOverIndex - 1 do
                        if levelInfoList[index].isSmall and not levelInfoList[index + 1].isSmall then
                            local tempData = levelInfoList[index]
                            levelInfoList[index] = levelInfoList[index + 1]
                            levelInfoList[index + 1] = tempData
                        end
                    end
                    --在排序大图放前面3换2换1最多换两次所以遍历两边、
                    for index = pageStartIndex, pageOverIndex - 1 do
                        if levelInfoList[index].isSmall and not levelInfoList[index + 1].isSmall then
                            local tempData = levelInfoList[index]
                            levelInfoList[index] = levelInfoList[index + 1]
                            levelInfoList[index + 1] = tempData
                        end
                    end
                    --没办法先这么强制匹配吧
                    if levelInfoList[pageOverIndex].isSmall and levelInfoList[pageOverIndex - 1].isSmall then
                        --需要换3次位置
                        if levelInfoList[pageStartIndex].isSmall then
                            --下面俩个图标换位
                            local tempData = levelInfoList[pageStartIndex][2]
                            levelInfoList[pageStartIndex][2] = levelInfoList[pageStartIndex + 1][2]
                            levelInfoList[pageStartIndex + 1][2] = tempData
                            --上面两个在换位
                            local tempData = levelInfoList[pageOverIndex][1]
                            levelInfoList[pageOverIndex][1] = levelInfoList[pageOverIndex - 1][1]
                            levelInfoList[pageOverIndex - 1][1] = tempData
                            --中间上下换位 2换1要检测是否为空防止配置混乱引起报错
                            local tempData = levelInfoList[pageStartIndex + 1][2]
                            if tempData then
                                levelInfoList[pageStartIndex + 1][2] = levelInfoList[pageStartIndex + 1][1]
                                levelInfoList[pageStartIndex + 1][1] = tempData
                            end
                        else
                            --对角换位 2换1要检测是否为空防止配置混乱引起报错
                            local tempData = levelInfoList[pageOverIndex - 1][2]
                            if tempData then
                                levelInfoList[pageOverIndex - 1][2] = levelInfoList[pageOverIndex][1]
                                levelInfoList[pageOverIndex][1] = tempData
                            end
                        end
                    end

                    levelInfoList[pageStartIndex].isPendant = true
                end

                pageStartIndex = i
                curPage = levelInfoList[i].page
            else
                pageOverIndex = i
            end
        end
    end

    -- 多余的commonsoon删除
    local isDeleteCommonSoon = true
    local deleteCount = 0
    for i = #levelInfoList, 1, -1 do
        if levelInfoList[i].page and levelInfoList[i].page == curPage then
            if levelInfoList[i][1] and not levelInfoList[i][1].p_commingSoonIndex then
                isDeleteCommonSoon = false
            end
            if levelInfoList[i][2] and not levelInfoList[i][2].p_commingSoonIndex then
                isDeleteCommonSoon = false
            end
            deleteCount = deleteCount + 1
        end
    end

    if isDeleteCommonSoon and deleteCount > 0 then
        for i = 1, deleteCount do
            table.remove(levelInfoList, #levelInfoList)
            -- infoIndex = infoIndex - 1
        end
    end

    return levelInfoList
end

--初始化 目前就设置了轮播图节点
function LevelNodeControl:initLevelNode()
    local LevelNode = util_createView("views.lobby.LevelNode", self.m_broadcastInfo)
    LevelNode:refreshInfo(self.m_broadcastInfo)
    self.m_broadcast:addChild(LevelNode)

    local BackFrontNode = util_createView("views.lobby.BackFrontNode", self.m_backFront)
    self.m_backFront:addChild(BackFrontNode)
    self.m_backFrontNode = BackFrontNode

    local size = self.m_broadcast:getContentSize()
    LevelNode:setPosition(size.width * 0.5 - 0.5, size.height * 0.5 + 1.5)
    local x, y = self.m_broadcast:getPosition()
    x = x + STARTX
    self.m_broadcast:setPosition(x, y)
    x = x + size.width + 30
    self.m_layerMaskl:setPositionX(x)
    self.m_backFront:setPositionX(x)
    x = x + 2
    self.m_content:getParent():setPosition(x, y)
end

-- 移除功能展示图
function LevelNodeControl:checkRemoveFeature(featureKey)
    if globalData.activityCount == 0 then
        return
    end
    for i = 1, globalData.activityCount do
        local info = self.m_levelInfoList[i]
        if info and info[1] and info[1].feature then
            if info[1].feature.key == featureKey then
                globalData.activityCount = globalData.activityCount - 1
                table.remove(self.m_levelInfoList, i)
                local node = table.remove(self.m_nodePool, i)
                self:removeNode(node)
                self:updateAfterRemoveActivity()
                return
            end
        end
    end
end

-- 移除活动
function LevelNodeControl:checkRemoveActivity(activityId)
    if globalData.activityCount == 0 then
        return
    end
    for i = 1, globalData.activityCount do
        if not self.m_levelInfoList then
            release_print("Error:levelInofList is nil!!!")
        end
        local info = self.m_levelInfoList[i]
        if info and info[1] and info[1].activity then
            local actId = info[1].activity.p_activityId
            if info[1].activity.p_id == activityId or (actId and actId ~= "" and actId == activityId) then
                globalData.activityCount = globalData.activityCount - 1
                table.remove(self.m_levelInfoList, i)
                local node = table.remove(self.m_nodePool, i)
                self:removeNode(node)
                self:updateAfterRemoveActivity()
                return
            end
        end
    end
end

function LevelNodeControl:updateAfterRemoveActivity()
    self.m_iLevelsStartID = self.m_iLevelsStartID - 1
    -- for i = #self.m_vecBigLevels, 1, -1 do
    --     self.m_vecBigLevels[i] = self.m_vecBigLevels[i] - 1
    -- end
end

-- cxc 2021年01月13日15:34:46 根据高倍场开启状态更新 关卡(small, big) 表现(不需要更新数据)
function LevelNodeControl:updateDeluxeLevels(open)
    -- local bOpenDeluxe = globalData.deluexeClubData:getDeluexeClubStatus()
    if not self.m_leftShowIdx or not self.m_rightShowIdx then
        for i, node in ipairs(self.m_nodePool) do
            node:updateDeluxeLevels(open)
        end
    else
        -- 刷新显示的节点
        for i = self.m_leftShowIdx, self.m_rightShowIdx do
            if not self.m_nodePool then
                release_print("Error:nodePool is nil!!!!")
            end
            local node = self:getNodeInPool(i)
            if node then
                node:updateDeluxeLevels(open)
            end
        end
    end
end

-- 插入一个广告位
function LevelNodeControl:insertHallNode(_params)
    local hallData = _params.hall
    if not hallData then
        return
    end
    
    local _info = hallData.info
    local _index = hallData.index or 1
    for i, v in ipairs(self.m_levelInfoList) do
        for k, m in ipairs(v) do
            if m.activity and m.activity.p_id and _info.activity and _info.activity.p_id then
                if v.activity.p_id == _info.activity.p_id then
                    return
                end
            elseif m.feature and m.feature.key and _info.feature and _info.feature.key then
                if m.feature.key == _info.feature.key then
                    return
                end
            end
        end
    end

    globalData.activityCount = globalData.activityCount + 1
    local hallInfo = {[1] = _info}
    table.insert(self.m_levelInfoList, _index, hallInfo)
    local LevelNode = util_createView("views.lobby.LevelNode", hallInfo, _index)
    LevelNode:setTag(_index)
    LevelNode:refreshInfo(hallInfo, _index)
    self.m_content:addChild(LevelNode)
    table.insert(self.m_nodePool, _index, LevelNode)
    
    self:updateLevelNodePosX()
    self:freshLevelNode("UpdateLobby")
end

--移除节点并且刷新坐标
function LevelNodeControl:removeNode(node)
    if not tolua.isnull(node) then
        node:removeFromParent()
    end
    self:updateLevelNodePosX()
    self:freshLevelNode("UpdateLobby")
end

--刷新关卡节点
function LevelNodeControl:freshLevelNode(freshType)
    if self.m_isFreshLevel then
        return
    end

    -- 更新滑动范围
    local levelMoveLen = self:getLevelMoveLen()
    self.m_scroll:setMoveLen(levelMoveLen, true)

    -- 获得显示的索引信息
    local startIdx, leftShowIdx, rightShowIdx = self:getLevelShowIndex(self:getLobbyScorllX())
    self.m_leftShowIdx = leftShowIdx
    self.m_rightShowIdx = rightShowIdx
    -- 索引关卡是否显示
    local isInShowIdx = function(lvIdx)
        if lvIdx > rightShowIdx or lvIdx < leftShowIdx then
            return false
        end
        return true
    end

    local count = #self.m_levelInfoList

    -- 加载剩余的关卡
    local loadLevelNodeFunc = nil
    loadLevelNodeFunc = function(nIndex)
        if nIndex > count or nIndex < 1 then
            return false
        end

        local levelInfo = self.m_levelInfoList[nIndex]
        self:loadLevelNode(nIndex, levelInfo, true)

        return true
    end

    local _interval = 0.05

    local _smallLvCount = math.ceil((3 * display.width / 2) / (levelWidth.small.level * 2 + OFFSETX_BIG_LEVEL))
    if freshType == "LoginLobby" then
        -- 登陆第一次进入大厅
        -- 先同步加载到第一个小关卡
        startIdx = 1
        for i = 1, count do
            local levelInfo = self.m_levelInfoList[i]
            self:loadLevelNode(i, levelInfo)

            if levelInfo.isSmall then
                startIdx = i
                break
            end
        end

        local levelIdxR = startIdx

        globalData.commonActivityData:pauseUpdate()
        -- 定时加载剩余的关卡
        self.m_levelSchedule =
            schedule(
            self.m_content,
            function()
                local newlvIdxR = levelIdxR + 1

                local resultR = false
                if isInShowIdx(levelIdxR) or (newlvIdxR - startIdx) < _smallLvCount then
                    -- 关卡显示或者少于最小数量就创建
                    resultR = loadLevelNodeFunc(newlvIdxR)
                    if resultR then
                        levelIdxR = newlvIdxR
                    end
                end

                if not resultR then
                    self:stopLoadLevels()
                    return
                end
            end,
            _interval
        )
    elseif freshType == "ReturnLobby" then
        -- 返回进入大厅
        -- 加载开始位置的关卡
        startIdx = startIdx or 1
        loadLevelNodeFunc(startIdx)

        local levelIdxL = startIdx
        local levelIdxR = startIdx

        globalData.commonActivityData:pauseUpdate()
        -- 定时加载剩余的关卡
        self.m_levelSchedule =
            schedule(
            self.m_content,
            function()
                local newLvIdxL = levelIdxL - 1
                local newLvIdxR = levelIdxR + 1

                local _cp = ((newLvIdxR - newLvIdxL) < _smallLvCount)
                local resultL = false
                if isInShowIdx(levelIdxL) or _cp then
                    resultL = loadLevelNodeFunc(newLvIdxL)
                    if resultL then
                        levelIdxL = newLvIdxL
                    end
                end

                local resultR = false
                if isInShowIdx(levelIdxR) or _cp then
                    resultR = loadLevelNodeFunc(newLvIdxR)
                    if resultR then
                        levelIdxR = newLvIdxR
                    end
                end

                if not (resultL or resultR) then
                    self:stopLoadLevels()
                    return
                end
            end,
            _interval
        )
    elseif freshType == "UpdateLobby" then
        -- 更新大厅
        -- 加载开始位置的关卡
        startIdx = startIdx or 1
        loadLevelNodeFunc(startIdx)

        local levelIdxL = startIdx
        local levelIdxR = startIdx

        while true do
            local newLvIdxL = levelIdxL - 1
            local newLvIdxR = levelIdxR + 1

            local _cp = ((newLvIdxR - newLvIdxL) < _smallLvCount)
            local resultL = false
            if isInShowIdx(levelIdxL) or _cp then
                resultL = loadLevelNodeFunc(newLvIdxL)
                if resultL then
                    levelIdxL = newLvIdxL
                end
            end

            local resultR = false
            if isInShowIdx(levelIdxR) or _cp then
                resultR = loadLevelNodeFunc(newLvIdxR)
                if resultR then
                    levelIdxR = newLvIdxR
                end
            end

            if not (resultL or resultR) then
                break
            end
        end
    end

    -- addCostRecord("Levels", socket.gettime() - curTime)
end

-- 更新关卡分类动画
function LevelNodeControl:updateRecmdLevelAction(secs, isShow)
    secs = secs or 0

    local oldLevelPos = clone(self.m_levelPos)

    self:updateLevelNodePosX()
    -- 更新滑动范围
    local levelMoveLen = self:getLevelMoveLen()
    self.m_scroll:setMoveLen(levelMoveLen, true)

    -- 获得显示的索引信息
    local startIdx, leftShowIdx, rightShowIdx = self:getLevelShowIndex(self:getLobbyScorllX())
    -- 移动的Index
    local oldLeftShowIdx = math.min(self.m_leftShowIdx, leftShowIdx)
    local oldRightShowIdx = math.max(self.m_rightShowIdx, rightShowIdx)

    local rightPoolIdx = 1
    -- for index = 1, #self.m_nodePool do
    for index = oldLeftShowIdx, (oldRightShowIdx + 1) do
        local distance = self:getLevelNodePos(index)
        local LevelNode = self:getNodeInPool(index)
        if not LevelNode then
            LevelNode = self:applyLevelNode(index)
            LevelNode:setPositionX(oldLevelPos[index])
        end
        if LevelNode then
            rightPoolIdx = index
            -- self.m_nodePool[index] = LevelNode
            -- 更新节点显示状态
            local isVisible = self:getNodeVisibleByIndex(index)

            local posX, posY = LevelNode:getPosition()
            if index >= oldLeftShowIdx and index <= oldRightShowIdx and secs > 0 then
                local actList = {}
                if isShow == nil then
                    actList[#actList + 1] = cc.MoveTo:create(secs, cc.p(distance, posY))
                else
                    if isShow then
                        actList[#actList + 1] = cc.EaseSineOut:create(cc.MoveTo:create(secs, cc.p(distance, posY)))
                    else
                        actList[#actList + 1] = cc.EaseSineIn:create(cc.MoveTo:create(secs, cc.p(distance, posY)))
                    end
                end
                if isVisible then
                    -- 立即更新状态
                    LevelNode:updateLevelVisible(isVisible)
                else
                    -- 执行动画后根据当前状态刷新
                    -- actList[#actList + 1] =
                    --     cc.CallFunc:create(
                    --     function()
                    --         -- self:getNodeVisibleByIndex(index)
                    --         -- LevelNode:updateLevelVisible(isVisible)
                    --     end
                    -- )
                end
                -- 执行动画后根据当前状态刷新
                actList[#actList + 1] =
                    cc.CallFunc:create(
                    function()
                        LevelNode:setLvAction("move", nil)
                    end
                )
                local _actionId = LevelNode:runAction(cc.Sequence:create(actList))
                LevelNode:setLvAction("move", _actionId)
            else
                LevelNode:updateLevelVisible(isVisible)
                LevelNode:setPositionX(distance)
            end
        end
    end
    self.m_leftShowIdx = leftShowIdx
    self.m_rightShowIdx = math.min(rightShowIdx, rightPoolIdx)
end

function LevelNodeControl:stopLoadLevels()
    if self.m_levelSchedule then
        self.m_content:stopAction(self.m_levelSchedule)
        self.m_levelSchedule = nil
    end
    globalData.commonActivityData:resumeUpdate()
end

--顺序列表
function LevelNodeControl:getLoadNodeList()
    return self.m_levelInfoList
end

--刷新坐标
function LevelNodeControl:loadLevelNode(index, info, ignoreCount)
    if not info then
        if DEBUG == 2 then
            print("loadLevelNode info = nil index = " .. index)
            release_print("loadLevelNode info = nil index = " .. index)
        end
        return
    end
    local LevelNode = self:getNodeInPool(index)
    if not LevelNode then
        LevelNode = self:applyLevelNode(index)
    end
    if index == 1 then
        globalNoviceGuideManager:addNode(NOVICEGUIDE_ORDER.comeCust, LevelNode)
    end

    local distance = self:getLevelNodePos(index)
    LevelNode:setPosition(distance, OFFY)
    -- if index == #self.m_levelInfoList or ignoreCount then
    --     local minLen = display.width - distance - LevelNode:getOffsetPosX() - STARTX - OFFSETX
    --     self.m_scroll:setMoveLen(minLen)
    -- end

    -- 更新节点显示状态
    -- local isVisible = self:getNodeVisibleByIndex(index)
    local isVisible = (index >= self.m_leftShowIdx) and (index <= self.m_rightShowIdx)
    LevelNode:updateLevelVisible(isVisible)

    LevelNode.m_index = index
    if LevelNode.refreshPendant then
        LevelNode:refreshPendant()
    end

    if info.isPendant then
        if globalData.lobbyFirstLevelNodeIndex == nil then
            globalData.lobbyFirstLevelNodeIndex = index
        else
            globalData.lobbyFirstLevelNodeIndex = math.min(globalData.lobbyFirstLevelNodeIndex, index)
        end
    end
end

-- 获得关卡宽度
function LevelNodeControl:getLevelContentLen(nodeInfo, index)
    local _node = nil
    if index then
        _node = self:getNodeInPool(index)
    end

    if _node then
        return _node:getContentLen() * 2
    else
        local _content = 0

        if nodeInfo then
            if nodeInfo.isSmall then
                _content = levelWidth.small.level
            elseif nodeInfo.isRecommend then
                local info = nodeInfo[1]
                if info:getIsSlotMod() then
                    _content = info:getContentLen()
                else
                    if nodeInfo.isShow then
                        local lvCount = #(info.levelInfos or {})
                        _content = levelWidth.big.recommend.unfold - (3 - lvCount) * 110
                    else
                        _content = levelWidth.big.recommend.fold
                    end
                end
            else
                local info = nodeInfo[1]
                if info then
                    if info.layoutList then
                        _content = levelWidth.big.layoutList
                    elseif info.feature then
                        _content = levelWidth.big.feature
                    elseif info.activity then
                        -- 展示页Hall数量
                        local nCount = #(info.activity.p_hallImages or {})
                        _content = levelWidth.big.activity * nCount + math.max(nCount - 1, 0) * OFFSETX_MUL_SPAN / 2
                    else
                        _content = levelWidth.big.level
                    end
                end
            end
        end

        return _content * 2
    end
end

-- 获得横向坐标偏移
function LevelNodeControl:getLevelOffsetPosX(nodeInfo, index)
    local _node
    if index then
        _node = self:getNodeInPool(index)
    end

    if _node then
        return _node:getOffsetPosX()
    end

    if not nodeInfo then
        return 0
    end
    if nodeInfo.isSmall then
        return posXOffset.small.level
    elseif nodeInfo.isRecommend then
        local info = nodeInfo[1]
        if info:getIsSlotMod() then
            return info:getOffsetPosX()
        else
            return posXOffset.big.recommend
        end
    else
        local info = nodeInfo[1]
        if not info then
            return 0
        end
        if info.layoutList then
            return posXOffset.big.layoutList
        elseif info.feature then
            return posXOffset.big.feature
        elseif info.activity then
            return posXOffset.big.activity
        else
            return posXOffset.big.level
        end
    end
end

-- 大厅滑动偏移
function LevelNodeControl:getLobbyScorllX()
    --解锁关卡
    if globalData.unlockMachineName then
        local moveX = self:getLevelPosXByName(globalData.unlockMachineName)
        globalData.unlockMachineName = nil

        globalData.lobbyScorllx = self:getLeveToCenterOffset(-moveX)
    end

    return globalData.lobbyScorllx or 0
end

-- 大厅关卡节点所在索引
function LevelNodeControl:getLobbyFirstLevelNodeIndex()
    return globalData.lobbyFirstLevelNodeIndex or 1
end

-- 关卡居中的偏移位置
function LevelNodeControl:getLeveToCenterOffset(scorllX)
    local posx = self.m_content:getParent():getPositionX()
    return math.max(math.min(scorllX + (display.width - posx) / 2, 0), self:getLevelMoveLen())
end

-- 更新关卡X坐标
function LevelNodeControl:updateLevelNodePosX()
    self.m_levelPos = {}

    for index = 1, #self.m_levelInfoList do
        local posX = self:_initLevelNodePos(index)
        self.m_levelPos[index] = posX
        self.m_nodePool[index] = self.m_nodePool[index] or "nil"
    end
end

-- 更新关卡显示索引范围
function LevelNodeControl:getLevelShowIndex(startX, levelPos)
    local leftShowIdx = nil
    local rightShowIdx = nil
    local startIdx = nil
    local startX = startX or 0

    levelPos = levelPos or self.m_levelPos
    local _count = #levelPos
    for index = 1, _count do
        local posX = self:getLevelNodePos(index)

        if not startIdx and (startX + posX) > 0 then
            -- 第一个加载的位置
            startIdx = index
        end

        local isVisible = self:getNodeVisibleByIndex(index)
        if not leftShowIdx and isVisible then
            -- 第一个显示的关卡栏
            leftShowIdx = index
        end

        if leftShowIdx and not rightShowIdx then
            if index == _count then
                rightShowIdx = index
            elseif not isVisible then
                -- 最后一个显示的关卡栏
                rightShowIdx = index - 1
            end
        end
    end
    return (startIdx or 1), (leftShowIdx or 1), (rightShowIdx or 1)
end

-- 获得最大滑动距离
function LevelNodeControl:getLevelMoveLen()
    local index = #self.m_levelInfoList
    local distance = self:getLevelNodePos(index)
    -- LevelNode:setPosition(distance, OFFY)
    -- if index == #self.m_levelInfoList or ignoreCount then
    local moveLen = display.width - distance - self:getLevelOffsetPosX(self.m_levelInfoList[index], index) - STARTX - OFFSETX
    local offset = util_getBangScreenHeight()
    if offset and offset > 0 then
        moveLen = moveLen - offset - 20
    end
    return moveLen
    -- end
end

-- 初始化所有关卡节点位置
function LevelNodeControl:_initLevelNodePos(index)
    local lvInfo = self.m_levelInfoList[index]
    if not lvInfo then
        return 0
    end

    local curPosX = self:getLevelOffsetPosX(lvInfo, index)
    if index == 1 then
        local distance = curPosX + FIRSTHALL
        return distance
    else
        local lastLvInfo = self.m_levelInfoList[index - 1]
        if not lastLvInfo then
            return 0
        end

        local lastPosX = self:getLevelOffsetPosX(lastLvInfo, index - 1)
        local lastLen = self:getLevelContentLen(lastLvInfo, index - 1)
        -- local pos = cc.p(lastNode:getPosition())
        local posX = self:getLevelNodePos(index - 1)
        local offX = 0
        -- 目前没有共存的以下两种情况
        if globalData.activityCount > 0 and globalData.activityCount + 1 == index then
            offX = FIRST_BIG_LEVEL
        end

        if lvInfo.isPendant then
            offX = offX + OFFSET_SMALL_LEVEL_GROUP + LINE_STAR_OFFSET_X
            local distance = posX + curPosX + (lastLen - lastPosX) + offX
            return distance
        else
            local LEVEL_OFFSETX = 0
            if index > globalData.activityCount + #self.m_vecBigLevels then
                LEVEL_OFFSETX = OFFSETX_SMALL_LEVEL
            else
                LEVEL_OFFSETX = OFFSETX_BIG_LEVEL
            end
            local distance = posX + curPosX + (lastLen - lastPosX) + LEVEL_OFFSETX + offX
            return distance
        end
    end
end

--根据索引获得坐标
function LevelNodeControl:getLevelNodePos(index)
    local lvPosX = self.m_levelPos[index]
    if lvPosX == nil then
        util_sendToSplunkMsg("LevelNodeControl", "posX of level index " .. tostring(index) .. " is nil!!")
    end
    return lvPosX or 0
end

-- 获得显示状态
function LevelNodeControl:getNodeVisibleByIndex(index, scorllX)
    scorllX = scorllX or (self:getLobbyScorllX())
    index = math.min(math.max(index or 1, 1), #self.m_levelPos)

    if not self.m_levelPos then
        release_print("Error:levelPos is nil !!!")
    end

    if index > #(self.m_levelPos or {}) then
        release_print("Error:index > #levelPos")
    end

    local lvPosX = self:getLevelNodePos(index)
    
    if scorllX == nil then
        scorllX = 0
        util_sendToSplunkMsg("LevelNodeControl", "scorllX of level index " .. tostring(index) .. " is nil!!")
    end
    local posX = lvPosX + scorllX

    local _len = levelWidth.small.level
    local _offsetX = levelWidth.small.level
    local levelNode = self:getNodeInPool(index)
    if levelNode then
        -- 如果节点存在
        _len = levelNode:getContentLen()
        _offsetX = levelNode:getOffsetPosX()
    end
    -- 左边缘坐标
    local posXL = posX - _offsetX
    -- 右边缘坐标
    local posXR = posXL + 2 * _len
    if posXR < -(display.width / 2) or posXL > display.width then
        return false
    else
        return true
    end
    -- else
    --     if posX < -(display.width / 3) or posX > display.width then
    --         return false
    --     else
    --         return true
    --     end
    -- end
end

-- 移动后更新节点显示隐藏状态
function LevelNodeControl:updateNodeVisibleByMove(scorllX, dt)
    if scorllX > 0 then
        return
    end

    local posCount = #self.m_levelPos
    local indexL = self.m_leftShowIdx or 1
    local indexR = math.min((self.m_rightShowIdx or 1), posCount)

    if dt < 0 then
        -- 左滑
        -- local offsetL = self.m_levelPos[indexL] + scorllX
        local isVisibleL = self:getNodeVisibleByIndex(indexL, scorllX)
        local nextR = math.min(indexR + 1, posCount)
        -- local offsetR = self.m_levelPos[nextR] + scorllX
        local isVisibleR = self:getNodeVisibleByIndex(nextR, scorllX)
        -- if offsetL < -(display.width / 3) then
        if not isVisibleL then
            local leftShowIdx = math.min(indexL + 1, posCount)
            if leftShowIdx ~= self.m_leftShowIdx then
                -- local _node = self.m_nodePool[indexL]
                -- if _node then
                --     _node:updateLevelVisible(false)
                --     _node:removeLevelLogo()
                -- end
                self:recycleLevelNode(indexL)
                self.m_leftShowIdx = leftShowIdx
                -- printInfo("-+-xy-+- 1 -- recycle = " .. indexL .. "|leftidx = " .. leftShowIdx)
            end
        end

        -- if offsetR < display.width then
        if isVisibleR then
            if self.m_rightShowIdx ~= nextR then
                -- local _node = self.m_nodePool[nextR]
                -- if _node then
                --     _node:updateLevelVisible(true)
                -- end
                self.m_rightShowIdx = nextR
                self:applyLevelNode(nextR)
                -- printInfo("-+-xy-+- 1 -- apply right idx = " .. nextR)
            end
        end
    elseif dt > 0 then
        -- 右滑
        local preL = math.max(indexL - 1, 1)
        -- local offsetL = self.m_levelPos[preL] + scorllX
        -- local offsetR = self.m_levelPos[indexR] + scorllX
        local isVisibleL = self:getNodeVisibleByIndex(preL, scorllX)
        local isVisibleR = self:getNodeVisibleByIndex(indexR, scorllX)

        -- if offsetR > display.width then
        if not isVisibleR then
            local rightShowIdx = math.max(self.m_rightShowIdx - 1, 1)
            if rightShowIdx ~= indexR and indexR ~= indexL then
                -- local _node = self.m_nodePool[indexR]
                -- if _node then
                --     _node:updateLevelVisible(false)
                --     _node:removeLevelLogo()
                -- end
                self:recycleLevelNode(indexR)
                self.m_rightShowIdx = rightShowIdx
                -- printInfo("-+-xy-+- 2 -- recycle = ".. indexR .. " rightidx = " .. rightShowIdx)
            end
        end

        -- if offsetL > -200 then
        if isVisibleL then
            if self.m_leftShowIdx ~= preL then
                -- local _node = self.m_nodePool[self.m_leftShowIdx]
                -- if _node then
                --     _node:updateLevelVisible(true)
                -- end
                self.m_leftShowIdx = preL
                self:applyLevelNode(preL)
                -- printInfo("-+-xy-+- 2 -- apply left idx = " .. preL)
            end
        end
    end
end

-- 跳转后更新关卡显示
function LevelNodeControl:updateNodeVisibleByJump(scorllX)
    local _, leftShowIdx, rightShowIdx = self:getLevelShowIndex(scorllX)

    if self.m_leftShowIdx == leftShowIdx and self.m_rightShowIdx == rightShowIdx then
        return
    end

    for key, value in ipairs(self.m_nodePool) do
        if  key < leftShowIdx or key > rightShowIdx then
            self:recycleLevelNode(key)
        else
            self:applyLevelNode(key)
        end
        -- local _node = self:getNodeInPool(key)
        -- local idx = key
        -- if _node then
        --     if idx < leftShowIdx or idx > rightShowIdx then
        --         _node:updateLevelVisible(false)
        --     else
        --         _node:updateLevelVisible(true)
        --     end
        -- end
    end

    self.m_leftShowIdx = leftShowIdx
    self.m_rightShowIdx = rightShowIdx
end

--根据索引获得坐标
-- function LevelNodeControl:getLevelNodePos(index)
--     local LevelNode = self.m_nodePool[index]
--     if not LevelNode then
--         return 0
--     end
--     if index == 1 then
--         local distance = LevelNode:getOffsetPosX() + FIRSTHALL
--         return distance
--     else
--         local lastNode = self.m_nodePool[index - 1]
--         if not lastNode then
--             return 0
--         end
--         local lastNodeInfo = lastNode.m_info
--         if not lastNodeInfo then
--             return 0
--         end
--         local pos = cc.p(lastNode:getPosition())
--         local offX = 0
--         -- 目前没有共存的以下两种情况
--         if globalData.activityCount > 0 and globalData.activityCount + 1 == index then
--             offX = FIRST_BIG_LEVEL
--         end
--         if lastNodeInfo.isPendant then
--             offX = offX + OFFSET_SMALL_LEVEL_GROUP + LINE_STAR_OFFSET_X
--             local distance = pos.x + LevelNode:getOffsetPosX() + lastNode:getOffsetPosX() + offX
--             return distance
--         else
--             local LEVEL_OFFSETX = 0
--             if index > globalData.activityCount + #self.m_vecBigLevels then
--                 LEVEL_OFFSETX = OFFSETX_SMALL_LEVEL
--             else
--                 LEVEL_OFFSETX = OFFSETX_BIG_LEVEL
--             end
--             local distance = pos.x + LevelNode:getOffsetPosX() + lastNode:getOffsetPosX() + LEVEL_OFFSETX + offX
--             return distance
--         end
--     end
-- end

--根据关卡名称获得关卡解锁位置
function LevelNodeControl:getUnlockPos(name)
    if self.m_isFreshLevel then
        return 0
    end
    for i = 1, #self.m_levelInfoList do
        local info = self.m_levelInfoList[i][1]
        local info2 = self.m_levelInfoList[i][2]
        if info and info.p_levelName and info.p_levelName == name then
            local LevelNode = self:getNodeInPool(i)
            if LevelNode then
                local pos = LevelNode:getOffsetPosX() - self:getLevelNodePos(i) + 20
                return pos, LevelNode.m_nodes[1]
            end
        end
        if info2 and info2.p_levelName and info2.p_levelName == name then
            local LevelNode = self:getNodeInPool(i)
            if LevelNode then
                local pos = LevelNode:getOffsetPosX() - self:getLevelNodePos(i) + 20
                return pos, LevelNode.m_nodes[2]
            end
        end
    end
    return 0
end

--根据关卡名称获得关卡解锁位置
function LevelNodeControl:getUnlockPosById(levelId)
    if self.m_isFreshLevel then
        return 0
    end
    for i = 1, #self.m_levelInfoList do
        local info = self.m_levelInfoList[i][1]
        local info2 = self.m_levelInfoList[i][2]
        if info and info.p_id and info.p_id == levelId then
            local LevelNode = self:getNodeInPool(i)
            if LevelNode then
                local pos = LevelNode:getOffsetPosX() - self:getLevelNodePos(i) + 20
                return pos, LevelNode.m_nodes[1]
            end
        end
        if info2 and info2.p_id and info2.p_id == levelId then
            local LevelNode = self:getNodeInPool(i)
            if LevelNode then
                local pos = LevelNode:getOffsetPosX() - self:getLevelNodePos(i) + 20
                return pos, LevelNode.m_nodes[2]
            end
        end
    end
    return 0
end

-- 新关卡跳转位置
-- function LevelNodeControl:getNewLevelPosById(levelId, ignorePage)
--     if self.m_isFreshLevel then
--         ignorePage = true
--     end
--     local curPage = nil
--     local colIndex = 1
--     local lastNode = nil
--     local offX = 0
--     if self.m_scroll and self.m_scroll.getCurrentOffset then
--         offX = self.m_scroll:getCurrentOffset()
--     end
--     for i = 1, #self.m_levelInfoList do
--         local info = self.m_levelInfoList[i][1]
--         local info2 = self.m_levelInfoList[i][2]
--         if self.m_levelInfoList[i].page or ignorePage then
--             --记录当前页签和对应的列数
--             if not curPage or curPage ~= self.m_levelInfoList[i].page then
--                 curPage = self.m_levelInfoList[i].page
--                 colIndex = 1
--             else
--                 colIndex = colIndex + 1
--             end
--             --如果在第二排标记节点
--             local LevelNode = self:getNodeInPool(i)
--             if LevelNode then
--                 if info2 and info2.p_id and info2.p_id == levelId then
--                     lastNode = LevelNode.m_nodes[2]
--                 end
--                 --如果在第一排正常跳转
--                 if info and info.p_id and info.p_id == levelId then
--                     local pos = LevelNode.m_nodes[1]:convertToNodeSpace(cc.p(offX, 0))
--                     local newPosX = pos.x + display.width - LevelNode.m_nodes[1]:getOffsetPosX()
--                     return newPosX, LevelNode.m_nodes[1]
--                 end
--                 --如果已经标记了 在第一列的最后一个跳转
--                 if lastNode and colIndex == 3 then
--                     local pos = LevelNode.m_nodes[1]:convertToNodeSpace(cc.p(offX, 0))
--                     local newPosX = pos.x + display.width - LevelNode.m_nodes[1]:getOffsetPosX()
--                     return newPosX, lastNode
--                 end
--             end
--         end
--     end

--     return 0
-- end

-- 获得关卡X坐标
function LevelNodeControl:getLevelPosXByName(name)
    if self.m_isFreshLevel or #self.m_levelPos <= 0 then
        return 0
    end
    for i = 1, #self.m_levelInfoList do
        local info = self.m_levelInfoList[i][1]
        local info2 = self.m_levelInfoList[i][2]
        if info and info.p_levelName and info.p_levelName == name then
            return self:getLevelNodePos(i)
        end
        if info2 and info2.p_levelName and info2.p_levelName == name then
            return self:getLevelNodePos(i)
        end
    end
    return 0
end

-- 获得关卡X坐标
function LevelNodeControl:getLevelPosXById(levelId)
    if self.m_isFreshLevel or not levelId then
        return 0, nil, nil
    end


    local lvId_n = globalData.slotRunData:translateLvId(levelId, false)
    local lvId_h = globalData.slotRunData:translateLvId(levelId, true)

    local pos = 0
    local idxCol = nil
    local idxRow = nil
    for i = 1, #self.m_levelInfoList do
        local info = self.m_levelInfoList[i][1]
        if info and info.p_id and (info.p_id == lvId_n or info.p_id == lvId_h) then
            -- local LevelNode = self:getNodeInPool(i)
            -- if LevelNode then
            --     local pos = self:getLevelNodePos(i)
            --     return pos, LevelNode.m_nodes[1]
            -- end
            pos = self:getLevelNodePos(i)
            idxCol = i
            idxRow = 1
            break
        end

        local info2 = self.m_levelInfoList[i][2]
        if info2 and info2.p_id and (info2.p_id == lvId_n or info2.p_id == lvId_h) then
            -- local LevelNode = self:getNodeInPool(i)
            -- if LevelNode then
            --     local pos = self:getLevelNodePos(i)
            --     return pos, LevelNode.m_nodes[2]
            -- end
            pos = self:getLevelNodePos(i)
            idxCol = i
            idxRow = 2
            break
        end
    end
    return pos, idxCol, idxRow
end

-- 推荐关卡置左位置
function LevelNodeControl:getRecmdLevelToLeftPos(recmdName)
    local index = 0
    for i = 1, #self.m_levelInfoList do
        local _levelInfo = self.m_levelInfoList[i]
        if _levelInfo and _levelInfo.isRecommend then
            local _info = _levelInfo[1]
            if _info and _info:getRecmdName() == recmdName then
                index = i
                break
            end
        end
    end

    if index > 0 then
        local LevelNode = self:getNodeInPool(index)
        if LevelNode then
            local posX = LevelNode:getOffsetPosX() - self:getLevelNodePos(index) + FIRSTHALL
            return posX
        end
    end

    return nil
end

return LevelNodeControl

