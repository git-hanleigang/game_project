local BaseFloatView = util_require("GameModule.FloatView.views.base.BaseFloatView")
local SlotLeftFloatCfg = util_require("GameModule.FloatView.config.SlotLeftFloatCfg")
local SlotLeftFloatView = class("SlotLeftFloatView", BaseFloatView)

local LISTVIEW_BG_SPACE = 15 -- 背景和list间隔

function SlotLeftFloatView:ctor()
	SlotLeftFloatView.super.ctor(self)

	self._waitAddCellInfoList = {} -- 待增加左边条入口 list
	self._bMoveEnabled = false -- 是否可以移动
	self._marginList = {6, 0, 100, 100} -- 左右上下
	if globalData.gameRealViewsSize then
		self._marginList[3] = globalData.gameRealViewsSize.topUIHeight or 100
		self._marginList[4] = globalData.gameRealViewsSize.bottomUIHeight or 100
	end
	self._sourceMarginList = clone(self._marginList)

	self._edgeTypeList = {ccui.LayoutComponent.HorizontalEdge.Left, ccui.LayoutComponent.VerticalEdge.None}
	self._showType = SlotLeftFloatCfg.SHOW_TYPE.FOLD
	self._bNeedCheckNotchBar = true --是否需要检查 刘海
	self:setName("SlotLeftFloatView")
end

function SlotLeftFloatView:getCsbName()
	return "LeftFrame/SlotLeftFloatNodeV2.csb"
end

function SlotLeftFloatView:initCsbNodes()
	SlotLeftFloatView.super.initCsbNodes(self)

	self._scrlView = self:findChild("ScrollView_1")
	self._scrlVParent = self:findChild("Panel_3")
	self._scrlView:setScrollBarEnabled(false)
	self._scrlView:setClippingEnabled(false)
	self._scrlVDfSize = self._scrlView:getContentSize()
	self._scrlView:setContentSize(cc.size(self._scrlVDfSize.width, 0))
	self._spBgZhankai = self:findChild("img_bg_zhankai")
	self._spBgZhankDfSize = self._spBgZhankai:getContentSize()
	self._spBgZhezhao = self:findChild("img_bg_zhezhao")
	self._spBgZhezhaoSubPosY = self._spBgZhankDfSize.height - self._spBgZhezhao:getPositionY()
	self._spBgShouqi = self:findChild("img_bg_shouqi")
	self._nodeBtn = self:findChild("node_btn")
	self._bubbleView = self:findChild("node_bubble")
	self._btnTouchMask = self:findChild("btn_touchMask")
	self._btnTouchMaskWidth = self._btnTouchMask:getContentSize().width
	self:setListMaskVisible(false)

	self._smallEntryParent = self:findChild("node_small_entry")

	-------------------
	local nodeClipRef = self:findChild("node_clip")
	local clipPos = cc.p(nodeClipRef:getPosition())
	-- 创建裁剪层
	local nodeClipping = cc.ClippingNode:create()
	nodeClipping:setInverted(false)
	nodeClipping:setAlphaThreshold(0)
	self._scrlVParent:addChild(nodeClipping)
	nodeClipping:move(clipPos)
	-- 设置 stencil node对象
	self._nodeStencil = ccui.Scale9Sprite:create(self._spBgZhankai:getCapInsets(), "LeftFrame/ui/ui_new2023/leftframe_bg_1_clip.png")
	self._nodeStencil:setAnchorPoint(cc.p(0.5, 0))
	self._nodeStencil:setPositionY(-60)
	self._nodeStencil:setContentSize(cc.size(1000, self._spBgZhankDfSize.height-6))
	nodeClipping:setStencil(self._nodeStencil)
	-- 裁剪scrlView
	util_changeNodeParent(nodeClipping, nodeClipRef)
	nodeClipRef:move(cc.p(0, 0))
	-------------------

	-- 当前关卡 左边条缩放值
	local scale = gLobalActivityManager:getSlotFloatLayerLeft() or 1
	self:setScale(scale)
	self._scale = scale
end

function SlotLeftFloatView:initUI()
	SlotLeftFloatView.super.initUI(self)

	self:checkShowEntryCell()

	-- 气泡刷新
    self._scrlView:onScroll(function()
		self:updateCellVisible()
		self:updateBubbleView()
	end)
	self:registerListener()
	self:runCsbAction("idle_zhankai")
end

function SlotLeftFloatView:checkShowEntryCell()
	self:setVisible(false)
	self:onRefreshContentEvt()
end

-- 更新 左边条 大小
function SlotLeftFloatView:updateScrolHeight()
	local cellCount = self._scrlView:getChildrenCount()
	self:setVisible(cellCount > 0)

	local size = self._scrlView:getInnerContainerSize()
	if cellCount <= SlotLeftFloatCfg.SHOW_MAX_CHILD_COUNT then
		if size.height > self._scrlVDfSize.height then
			size.height =  self._scrlVDfSize.height
		end

		self._scrlView:setBounceEnabled(false)
		self:updateContentSize(size)
		return
	end

	self._scrlView:setBounceEnabled(true)
	self:updateContentSize(cc.size(size.width, self._scrlVDfSize.height))
end

function SlotLeftFloatView:updateContentSize(_size)
	self._size = cc.size(self._spBgZhankDfSize.width, _size.height + (self._spBgZhankDfSize.height - self._scrlVDfSize.height))
	self:setContentSize(cc.size(self._size.width*self._scale, self._size.height*self._scale))

	-- 背景
	self._spBgZhankai:setContentSize(cc.size(self._size.width, self._size.height))
	self._nodeStencil:setContentSize(cc.size(1000, self._size.height-6))
	self._nodeStencil:setPositionY(-62)
	self._spBgZhezhao:setPositionY(self._size.height - self._spBgZhezhaoSubPosY)

	-- listView
	self._scrlView:setContentSize(cc.size(_size.width, _size.height))
	self._scrlVParent:setContentSize(cc.size(1200, _size.height))
	self._btnTouchMask:setContentSize(cc.size(self._size.width, self._size.height))
end
function SlotLeftFloatView:getContentSize()
	-- 没有缩放的 size
	return self._size or cc.size(0,0)
end

-- 更新 左边条 背景显隐
function SlotLeftFloatView:updateBgStatus()
	local cellCount = self._scrlView:getChildrenCount()
	self._spBgZhankai:setVisible(cellCount > 1 and self._showType == SlotLeftFloatCfg.SHOW_TYPE.FOLD)
	self._spBgZhezhao:setVisible(cellCount > 1 and self._showType == SlotLeftFloatCfg.SHOW_TYPE.FOLD)
	self._nodeBtn:setVisible(cellCount > 1 and self._showType == SlotLeftFloatCfg.SHOW_TYPE.FOLD)
	if self._idleActName == "idle_shouqi" then
		-- 缩小状态 要显示btn
		self._nodeBtn:setVisible(true)
	end
end

-- 对 入口cell 进行坐标排序
function SlotLeftFloatView:updateCellPos()
	local items = self._scrlView:getChildren()
	-- 可显示的所有 左边条 排序 (UI 从下到上)
	table.sort(items, function(_a, _b)
		local aZorder = _a:getCfgInfo().zOrder or 99
		local bZorder = _b:getCfgInfo().zOrder or 99
		return aZorder > bZorder
	end)
	local posY = 0
	for i, cell in ipairs(items) do
		local info = cell:getCfgInfo()
		local sizeInfo = info.sizeInfo
		cell:move((self._scrlVDfSize.width - sizeInfo.width)*0.5, posY)
		posY = posY + sizeInfo.height + 10
		cell:setTag(i)
	end
	self._scrlView:setInnerContainerSize(cc.size(self._scrlVDfSize.width, math.max(posY, 0)))
end 

-- 更新入口显隐
function SlotLeftFloatView:updateCellVisible()
	local items = self._scrlView:getChildren()
	local aabbW = self._scrlView:getWordAabb()
	for _, v in pairs(items) do

		local name = v:getName()
        local posItem = v:convertToWorldSpace(cc.p(0, 0))
        local sizeItem = v:getContentSize()
		local bShow = cc.rectIntersectsRect(aabbW, cc.rect(posItem.x, posItem.y, sizeItem.width, sizeItem.height))
		if self._unFoldCellCfgInfo then
			bShow = self._unFoldCellCfgInfo.viewRefKey == name
		end
		for _, _subNode in pairs(v:getChildren()) do
			_subNode:setOpacity(bShow and 255 or 0)
			_subNode:setVisible(bShow)
		end

	end
end

-- 更新气泡显隐
function SlotLeftFloatView:updateBubbleView()
	if self._unFoldCellCfgInfo and self._showType == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
		-- 展开的cell在设置下显示， 可能listView超框 隐藏了(减少drawcall)
		local cell = self._scrlView:getChildByName(self._unFoldCellCfgInfo.viewRefKey)
		if not tolua.isnull(cell) then
			cell:setVisible(true)
		end
	end

	local bubbleList = self._bubbleView:getChildren()
	local aabbW = self._scrlView:getWordAabb()
	aabbW.width = aabbW.width * self._parentScale
	aabbW.height = aabbW.height * self._parentScale
	for _, _node in ipairs(bubbleList) do

		while true do
			local viewRefKey = _node:getName()
			local cell = self._scrlView:getChildByName(viewRefKey)
			if not cell then
				break
			end
			local size = cell:getContentSize()
			local posW = cell:convertToWorldSpace(cc.p(size.width*0.5, size.height*0.5))
			local posL = self._bubbleView:convertToNodeSpace(posW) 
			_node:setPositionY(posL.y)

			local bCanVisible = cc.rectContainsPoint(aabbW, posW)
			if bCanVisible and self._unFoldCellCfgInfo then
				bCanVisible = self._unFoldCellCfgInfo.viewRefKey == viewRefKey
			end
			_node:setVisible(bCanVisible)
			break
		end

	end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_UPDATE_ENTRY_VISIBLE)
end

function SlotLeftFloatView:playIdleAct(_idleActName)
	self:runCsbAction(_idleActName)
	self._idleActName = _idleActName
end

-- 变大 展开
function SlotLeftFloatView:playToBigViewAct()
	self._idleActName = nil
	self:updateBgStatus()
	self:runCsbAction("to_big", false, function()
		self:playIdleAct("idle_zhankai")
		self:updateBgStatus()
		self:updateScrlVParentContSize()
		self._scrlVParent:stopAllActions()
	end, 60)
	schedule(self._scrlVParent, util_node_handler(self, self.updateScrlVParentContSize), 1/30)
end
function SlotLeftFloatView:playToSmallViewAct()
	self:updateSmallEntryUI()
	self:runCsbAction("to_small", false, function()
		self:playIdleAct("idle_shouqi")
		self._nodeBtn:setVisible(true)
		self:updateScrlVParentContSize()
		self._scrlVParent:stopAllActions()
	end, 60)
	schedule(self._scrlVParent, util_node_handler(self, self.updateScrlVParentContSize), 1/30)
end
-- 更新scl裁剪层
function SlotLeftFloatView:updateScrlVParentContSize()
	local size = self:getContentSize()
	local scale = self._spBgZhankai:getScaleY()
	self._scrlVParent:setContentSize(1200, (size.height - (self._spBgZhankDfSize.height - self._scrlVDfSize.height)) * scale)
end

function SlotLeftFloatView:updateSmallEntryUI()
	local items = self._scrlView:getChildren()
	if #items == 0 then
		return
	end

	local tempList = {}
	local defaultInfo = nil
	for i=#items, 1, -1 do

		while true do
			
			local cell = self._scrlView:getChildByTag(i)
			if not cell then
				break
			end
			local info = cell:getCfgInfo()
			if not defaultInfo then
				defaultInfo = info
			end
			local entryNode = info.node
			if tolua.isnull(entryNode) or entryNode.checkHadRedOrProgMax == nil then
				break
			end

			local redProgInfo = entryNode:checkHadRedOrProgMax() -- {hadRedDot, ProgPercentMax}
			if redProgInfo[1] then
				-- 有小红点
				table.insert(tempList, info)
			end
			break
		end

	end
	table.sort(tempList, function(_a, _b)
		local aZorder = SlotLeftFloatCfg.SmallEntryShowOrderMap[_a.viewRefKey] or 99
		local bZorder = SlotLeftFloatCfg.SmallEntryShowOrderMap[_b.viewRefKey] or 99
		return aZorder < bZorder
	end)

	local info = tempList[1] or defaultInfo
	if not info or tolua.isnull(info.node) then
		return
	end

	local view
	if info.actRefName then
		view = self:createSmallEntry_Act(info)
	elseif info.sysRefName then
		view = self:createSmallEntry_Sys(info) 
	end
	if not view then
		return
	end

	if self._preSmallEntryInfo and self._preSmallEntryInfo.viewRefKey == info.viewRefKey then
		return
	end

	if view.forbidEntryUnflodState then
		view:forbidEntryUnflodState(true)
	end
	self._smallEntryParent:removeAllChildren()
	view:addTo(self._smallEntryParent) 
	self._preSmallEntryInfo = clone(info)
	self._preSmallEntryInfo.node = view
end
-- 检查 缩小状态小图标入口
function SlotLeftFloatView:removeSmallEntry(_viewRefKey)
	if self._preSmallEntryInfo and self._preSmallEntryInfo.viewRefKey == _viewRefKey then
		self._smallEntryParent:removeAllChildren()
		self._preSmallEntryInfo = nil
		self:updateSmallEntryUI()
	end
end

-- 活动入口
function SlotLeftFloatView:createSmallEntry_Act(_info)
	local _actData = _info and _info.actData or nil
	if not _actData or not _actData:isRunning() or (_actData.getPositionBar and _actData:getPositionBar() ~= 1) then
		-- 没有数据 活动没开 不在左边条显示
		return
	end

	local refName = _actData:getRefName()
	local themeName = _actData:getThemeName()

	local entryModule = ""
	local activityId = nil
	local _mgr = G_GetMgr(refName)
	if _mgr then
		if _mgr:isCanShowEntry() then
			entryModule = _mgr:getEntryModule()
		end
	elseif BaseGameControl:getInstance():checkRes(themeName) then
		if  BaseGameControl:getInstance():checkDownloaded(themeName) then
			entryModule = _actData:getEntryModule()
		end
	else
		entryModule = _actData:getEntryModule()
	end
	if entryModule == "" then
		return
	end

	if _actData.getActivityID then
		activityId = _actData:getActivityID()
	end

	--将活动ID传入
	local view = util_createView(entryModule, {activityId = activityId})
	return view
end

function SlotLeftFloatView:createSmallEntry_Sys(_info)
	local sysRefName = _info and _info.sysRefName or nil

	local mgr = G_GetMgr(sysRefName)
	local view
	if mgr and mgr.createEntryNode then
		view = mgr:createEntryNode()
	else
		local ClanManager = util_require("manager.System.ClanManager"):getInstance()
		if sysRefName == "ClanEntryNode" then
			view = ClanManager:createMachineEntryNode()
		elseif sysRefName == "ClanDuelEntryNode" then
			view = ClanManager:createClanDuelEntryNode()
		end
	end

	return view
end

function SlotLeftFloatView:clickFunc(sender)
    local name = sender:getName()
	if self._bActing or self._bStopTouch then
		return
	end

    if name == "Button_up" then
        self:playToBigViewAct()
    elseif name == "Button_down" then
        self:playToSmallViewAct()
    end
	self._bStopTouch = true
	performWithDelay(sender, function()
		self._bStopTouch = false
	end, 0.5)
	gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
end

function SlotLeftFloatView:checkActEntry()
	local checkFunc = function(_actData)
		if not _actData or not _actData:isRunning() or (_actData.getPositionBar and _actData:getPositionBar() ~= 1) then
			-- 没有数据 活动没开 不在左边条显示
			return
		end

		local refName = _actData:getRefName()
		local themeName = _actData:getThemeName()
		if string.find(refName, ACTIVITY_REF.League) or self._scrlView:getChildByName(refName) then
			-- 比赛 单独处理， 已经添加不在加了
			return
		end

		local entryModule = ""
        local activityId = nil
        local _mgr = G_GetMgr(refName)
        if _mgr then
            if _mgr:isCanShowEntry() then
                entryModule = _mgr:getEntryModule()
            end
        elseif BaseGameControl:getInstance():checkRes(themeName) then
			if  BaseGameControl:getInstance():checkDownloaded(themeName) then
				entryModule = _actData:getEntryModule()
			end
		else
			entryModule = _actData:getEntryModule()
        end
        if entryModule == "" then
            return
        end

        if _actData.getActivityID then
            activityId = _actData:getActivityID()
        end

        --将活动ID传入
        local view = util_createView(entryModule, {activityId = activityId})
		return view
	end

    local datas = globalData.commonActivityData:getActivitys()
	for _, actData in pairs(datas) do
		local view = checkFunc(actData)
		if view then
			local refName = actData:getRefName()
			local info = {
				node = view,
				actData = actData,
				actRefName = refName,
				viewRefKey = refName,
				zOrder = SlotLeftFloatCfg.SpecialEntryOrders[refName] or 99
			}
			table.insert(self._waitAddCellInfoList, info)
		end
	end

end
-- 系统功能入口
function SlotLeftFloatView:checkSysEntry()
	-- 新版 有mgr的
	local list = SlotLeftFloatCfg.SYS_ENTRY_LIST
	for _, info in pairs(list) do
		local mgr = G_GetMgr(info.refName)

		while (mgr and mgr.createEntryNode) do
			local view = self._scrlView:getChildByName(info.viewRefKey)
			if view then
				-- 已存在 不用加了
				break
			end

			if mgr.checkEntryNode and not mgr:checkEntryNode() then
				-- CardSeekerGame 不可创建
				break
			end

			view = mgr:createEntryNode()
			if not view then
				-- 此功能 不用加
				break
			end

			local info = {
				node = view,
				sysRefName = info.refName,
				viewRefKey = info.viewRefKey,
				zOrder = SlotLeftFloatCfg.SpecialEntryOrders[info.viewRefKey] or 99
			}
			table.insert(self._waitAddCellInfoList, info)
			break
		end
	end

	-- 老版
    local ClanManager = util_require("manager.System.ClanManager"):getInstance()
	if ClanManager and ClanManager:isDownLoadRes() and ClanManager:checkSupportAppVersion() then 
		-- 公会入口
		local teamEntry = self._scrlView:getChildByName("ClanEntryNode")
		if not teamEntry then
			teamEntry = ClanManager:createMachineEntryNode()
			if teamEntry then
				local info = {
					node = teamEntry,
					sysRefName = "ClanEntryNode",
					viewRefKey = "ClanEntryNode",
					zOrder = SlotLeftFloatCfg.SpecialEntryOrders["ClanEntryNode"] or 99
				}
				table.insert(self._waitAddCellInfoList, info)
			end
		end

		
		-- 公会对决
		local teamDuelEntry = self._scrlView:getChildByName("ClanDuelEntryNode")
		if not teamDuelEntry then
			teamDuelEntry = ClanManager:createClanDuelEntryNode()
			if teamDuelEntry then
				local info = {
					node = teamDuelEntry,
					sysRefName = "ClanDuelEntryNode",
					viewRefKey = "ClanDuelEntryNode",
					zOrder = SlotLeftFloatCfg.SpecialEntryOrders["ClanDuelEntryNode"] or 99
				}
				table.insert(self._waitAddCellInfoList, info)
			end
		end

	end

end

-- 排序 左边条信息 并添加左边条
function SlotLeftFloatView:checkAddEntryCellInfo()
	-- 可显示的所有 左边条 信息
	local exitEntryInfoList = {}
	local totalInfoList = clone(self._waitAddCellInfoList)
	self._waitAddCellInfoList = {}
	local items = self._scrlView:getChildren()
	for _,_cell in pairs(items) do
		if not tolua.isnull(_cell) then
			table.insert(exitEntryInfoList, _cell:getCfgInfo())
		end
	end
	table.insertto(totalInfoList, exitEntryInfoList)
	
	for _idx=1, #totalInfoList do
		self:addEntryCell(totalInfoList[_idx], _idx, true)
	end

	self:refreshContentUI()
end

-- 添加 关卡左边条入口
function SlotLeftFloatView:addEntryCell(_info, _idx, _bRefreshAll)
	if self._showType == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
		-- 展开状态先不加 收起后会自动加
		return
	end

	if not _info or tolua.isnull(_info.node) then
		return
	end

	local cell = self._scrlView:getChildByName(_info.viewRefKey)
	if cell then
		return
	end

	local count = self._scrlView:getChildrenCount()
	_idx = _idx or count
	cell = self:createCell(_info)
	self._scrlView:addChild(cell)
	if not _bRefreshAll then
		-- 外部单独调用 刷下UI
		self:refreshContentUI()
	end
end
function SlotLeftFloatView:createCell(_info)
	if not _info or tolua.isnull(_info.node) then
		return
	end

	local layout = ccui.Layout:create()
	layout._slotLeftEntryInfo = _info
	-- if DEBUG == 2 then
	-- 	layout:setBackGroundColorType(ccui.LayoutBackGroundColorType.solid);
	-- 	layout:setBackGroundColor( cc.c4b(192, 192, 192 ) );
	-- 	layout:setBackGroundColorOpacity( 80 )
	-- end
	layout:addChild(_info.node)
	self:buttonSwallowTouches(layout)
	local size = cc.size(100,100)
	if _info.node.getPanelSize then
		size = _info.node:getPanelSize()
		if size.widht then
			size.width = size.widht
		end
		if size.launchHeight then
			size.unfoldHeight = size.launchHeight
		end
	end
	_info.sizeInfo = size
	layout:setContentSize(size)
	_info.node:setPosition(size.width / 2, size.height / 2)

	layout:setName(_info.viewRefKey)
	layout["getCfgInfo"] = function()
		return layout._slotLeftEntryInfo
	end
	return layout
end
--[[
	入口添加的 气泡
	_params = {
		viewRefKey: 入口引用名
		viewPath: 气泡资源或nodeLua路径
		bubblePosW: 气泡世界坐标,
		bubbleName: 气泡名
	}
]]
function SlotLeftFloatView:addEntryBubble(_params)
	if type(_params) ~= "table" then
		return
	end

	local cell = self._scrlView:getChildByName(_params.viewRefKey)
	if not cell then
		return
	end

	if not _params.viewPath then
		return
	end
	local bubble = self._bubbleView:getChildByName(_params.viewRefKey)
	if not bubble then
		bubble = display.newNode()
		bubble:setName(_params.viewRefKey)
		self._bubbleView:addChild(bubble)
	end

	local subBubble = bubble:getChildByName(_params.bubbleName)
	if subBubble then
		return
	end

	local pushView = nil
	if string.find(_params.viewPath, ".csb") then
		pushView = util_createAnimation(_params.viewPath)
	else
		pushView = util_createView(_params.viewPath)
	end
	if not pushView then
		return
	end
	pushView:setName(_params.bubbleName)
	bubble:addChild(pushView)
	local posL = cc.p(0, 0)
	if _params.bubblePosW then
		posL = self._bubbleView:convertToNodeSpace(_params.bubblePosW)
	end
	bubble:setPosition(posL)
	if self.__bEnterFinish then
		self:updateBubbleView()
	end
end

-- 移除 关卡左边条入口
function SlotLeftFloatView:removeEntryCell(_viewRefKey)
	local cell = self._scrlView:getChildByName(_viewRefKey)
	if not cell then
		return
	end

	self._scrlView:removeChild(cell)
	
	if self._unFoldCellCfgInfo and self._showType == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
		self._bFoldRContent = true

		-- 展开状态下 被移除
		if _viewRefKey == self._unFoldCellCfgInfo.viewRefKey then
			self:showEntryNodeFold(_viewRefKey)
		else
			-- 不是自己 被移了 啥也不干，别更新入口了， 等缩小的时候会自己更新位置的
		end
	else
		-- 非展开状态 被移除更新下 入口位置大小啥的
		self:refreshContentUI()
	end

	-- 检查 缩小状态小图标入口
	self:removeSmallEntry(_viewRefKey)
end
--[[
	移除 入口添加的 气泡
	_params = {
		viewRefKey: 入口引用名
		bubbleName: 气泡名
	}
]]
function SlotLeftFloatView:removeEntryBubble(_params)
	if type(_params) ~= "table" then
		return
	end

	local bubble = self._bubbleView:getChildByName(_params.viewRefKey)
	if not bubble then
		return
	end

	local subBubble = bubble:getChildByName(_params.bubbleName)
	if not subBubble then
		return	
	end
	subBubble:removeSelf()
end

--[[
    获取 关卡左边条入口 node
    viewRefKey: 入口引用名
]]
function SlotLeftFloatView:getEntryNode(_viewRefKey, _bCheckSmallEntryNode)
	if self._idleActName == "idle_shouqi" and self._preSmallEntryInfo then
		-- 缩小状态优先 选择缩小状态的
		if self._preSmallEntryInfo.viewRefKey == _viewRefKey then
			return self._preSmallEntryInfo.node
		elseif _bCheckSmallEntryNode then
			return nil
		end
	end

	local cell = self._scrlView:getChildByName(_viewRefKey)
	if tolua.isnull(cell) then
		return
	end

	local info = cell:getCfgInfo()
    if not info or tolua.isnull(info.node) then
        -- 节点不存在
        return nil
    else
	    return info.node
    end
end

--[[
	获得 入口添加的 气泡
	_params = {
		viewRefKey: 入口引用名
		bubbleName: 气泡名
	}
]]
function SlotLeftFloatView:getEntryBubble(_params)
	if type(_params) ~= "table" then
		return
	end

	local bubble = self._bubbleView:getChildByName(_params.viewRefKey)
	if not bubble then
		return
	end

	local subBubble = bubble:getChildByName(_params.bubbleName)
	return subBubble
end

-- 刷新 背景显隐和ContentSize
function SlotLeftFloatView:refreshContentUI()
	self:updateCellPos()
	self:updateCellVisible()
	self:updateScrolHeight()
	self:updateBgStatus()
	self:updateBubbleView()
end

-- 刷新
function SlotLeftFloatView:onRefreshContentEvt()
	if self._showType == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
		-- 展开状态先不加
		return
	end

	self._waitAddCellInfoList = {}
	
	self:checkActEntry()
	self:checkSysEntry()
	-- 排序 添加
	if #self._waitAddCellInfoList > 0 then
		self:checkAddEntryCellInfo()
	end
end


--[[
	切换 显示状态
	_params = {
		type = 显示类型
		viewRefKey = 入口refkey
		func = 回调
	}
--]]
function SlotLeftFloatView:onSwitchEntryNodeShowTypeEvt(_params)
	local func = _params.func or function() end

	if self._bActing then
		return
	end

	local cb = function()
		-- 向外抛出消息告诉界面当前已经收缩到屏幕外了 (有功能是 根据该事件做展开收起动画)
		performWithDelay(self,function()
			-- 有可能 有的 人 还没注册事件 就处理 显示状态了， 抛事件 很坑（以后改吧）
			gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_MOVEIN)
		end,0)

		-- listView 取消滑动
		self._scrlView:stopAutoScroll() 
		if _params.type == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
			self:showEntryNodeUnfold(_params.viewRefKey, func)
			self:playIdleAct("idle_zhankai")
			self:updateScrlVParentContSize()
		else
			self:showEntryNodeFold(_params.viewRefKey, func)
			self:playIdleAct("idle_zhankai")
			self:updateScrlVParentContSize()
		end

		self._nodeBtn:setVisible(false)
		self._bActing = true
		self:setListMaskVisible(true)
		local showCb = function()
		end
		local delayTime = cc.DelayTime:create(0.3)
		local playAct = cc.CallFunc:create(function()
			self:updateBgStatus()
			self:playShowViewAct(showCb)
		end)
		self.m_csbNode:runAction(cc.Sequence:create(delayTime, playAct))
	end
	self:playHideViewAct(cb)
end
function SlotLeftFloatView:showEntryNodeFold(_viewRefKey, _func)
	_func = _func or function() end
	if not self._unFoldCellCfgInfo or self._unFoldCellCfgInfo.viewRefKey ~= _viewRefKey then
		return
	end

	self._unFoldCellCfgInfo = nil
	self._showType = SlotLeftFloatCfg.SHOW_TYPE.FOLD
	local innerPos = self._scrlView:getInnerContainerPosition()
	self._scrlView:setInnerContainerPosition(cc.p(innerPos.x, innerPos.y - (self._unFoldMovePosY or 0)))
	self:onRefreshContentEvt()
	if self._bFoldRContent then
		self:refreshContentUI()
		self._bFoldRContent = false
	else
		self:updateBgStatus()
		self:updateCellVisible()
		self:updateBubbleView()
		self._nodeStencil:setContentSize(cc.size(1000, self._size.height-6))
		self._nodeStencil:setPositionY(-62)
	end
	self._scrlVParent:setClippingEnabled(true)
	self._scrlView:setTouchEnabled(true)
	local curPercent = self._scrlView:getScrolledPercentVertical()
	if curPercent > 100 then
		self._scrlView:jumpToPercentVertical(100)
	end
	_func()
end
function SlotLeftFloatView:showEntryNodeUnfold(_viewRefKey, _func)
	_func = _func or function() end
	if self._unFoldCellCfgInfo then
		-- 展开中
		performWithDelay(self,function()
			-- 有可能 有的 人 还没注册事件 就处理 显示状态了， 抛事件 很坑（以后改吧）
			performWithDelay(self,function()
				gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_FORCE_HIDE, {name = _viewRefKey})
			end, 0)
		end,0)
		_func()
		return
	end

	local cell = self._scrlView:getChildByName(_viewRefKey)
	if not cell then
		-- 没有该入口
		return
	end
	local cellCfg = cell:getCfgInfo()
	local sizeInfo = cellCfg.sizeInfo
	if not sizeInfo.unfoldHeight then
		-- 没有展开大小
		return
	end
	cell:setVisible(true)
	self._unFoldCellCfgInfo = cellCfg
	self._showType = SlotLeftFloatCfg.SHOW_TYPE.UNFOLD
	self:updateBgStatus()
	self:updateCellVisible()
	self:updateBubbleView()
	local height = cellCfg.sizeInfo.height or 0
	local unfoldHeight = cellCfg.sizeInfo.unfoldHeight or 0
	local posWT = self._scrlView:convertToWorldSpace(cc.p(0, unfoldHeight))
	local posWS = cell:convertToWorldSpace(cc.p(0, height))
	local innerPos = self._scrlView:getInnerContainerPosition()
	self._unFoldMovePosY = posWT.y - posWS.y
	self._scrlView:setInnerContainerPosition(cc.p(innerPos.x, innerPos.y + self._unFoldMovePosY))
	self._scrlVParent:setClippingEnabled(false)
	self._scrlView:setTouchEnabled(false)
	self._nodeStencil:setContentSize(cc.size(1000, 2000))
	self._nodeStencil:setPositionY(-1000)
	_func()
end
-- 显示 左边条 detail
function SlotLeftFloatView:playShowViewAct(_cb)
	self:setListMaskVisible(true)
	self._bActing = true
	local edgeTypeH = self._edgeTypeList[1]
	local startPos = cc.p(self.m_csbNode:getPosition())
	local size = self:getContentSize()
	local moveTo = cc.MoveTo:create(0.2, cc.p(0, startPos.y))
	local endCB = cc.CallFunc:create(function()
		self:setListMaskVisible(false)

		-- 显示 hide 按钮
		self._bActing = false
		self:updateBubbleView()

		if _cb then
			_cb()
		end

	end)
	self.m_csbNode:runAction(cc.Sequence:create(moveTo, endCB))
	self:setVisible(true)
end
-- 隐藏 左边条 detail
function SlotLeftFloatView:playHideViewAct(_cb)
	self:setListMaskVisible(true)
	self._bActing = true
	local edgeTypeH = self._edgeTypeList[1]
	local startPos = cc.p(self.m_csbNode:getPosition())
	local size = self:getContentSize()
	local endPosX = -size.width
	if edgeTypeH == ccui.LayoutComponent.HorizontalEdge.Right then
		endPosX = size.width
	end
	local moveTo = cc.MoveTo:create(0.2, cc.p(endPosX, startPos.y))
	local endCB = cc.CallFunc:create(function()
		self:setListMaskVisible(false)

		self:setVisible(false)
		self._bActing = false
		self:updateBubbleView()

		if _cb then
			_cb()
		end

	end)
	self.m_csbNode:runAction(cc.Sequence:create(moveTo, endCB))
end

function SlotLeftFloatView:registerListener()
	-- 注册事件
    gLobalNoticManager:addObserver(self, "onRefreshContentEvt", ViewEventType.SHOW_LEVEL_UP)
    gLobalNoticManager:addObserver(self, "onRefreshContentEvt", ViewEventType.NOTIFY_AVATAR_FRME_RES_DOWNLOAD_COMPLETE)
    gLobalNoticManager:addObserver(self, "onRefreshContentEvt", ViewEventType.NOTIFY_SERVER_TIME_ZERO)
    gLobalNoticManager:addObserver(self, "onRefreshContentEvt", "DL_Complete" .. CardSysManager:getDyNotifyName())
	gLobalNoticManager:addObserver(self, "onRefreshContentEvt", ViewEventType.NOTIFY_ACTIVITY_HOUR_DEAL_DATA_UPDATE)
	gLobalNoticManager:addObserver(self, "onRefreshContentEvt", SlotLeftFloatCfg.EVENT_NAME.UPDATE_SLOT_LEFT_ENTRY_VIEW)
	-- 切换显示状态
    gLobalNoticManager:addObserver(self, "onSwitchEntryNodeShowTypeEvt", SlotLeftFloatCfg.EVENT_NAME.NOTIFY_SWITCH_LEFT_FLOAT_SHOW_TYPE)
end
function SlotLeftFloatView:onEnter()
	SlotLeftFloatView.super.onEnter(self)

	if globalData.slotRunData.isPortrait then
		self._marginList[3] = self._marginList[3] / self._parentScale
		self._marginList[4] = self._marginList[4] / self._parentScale
		self._sourceMarginList = clone(self._marginList)
	end
	self:setPositionY(display.height/self._parentScale - (self._marginList[3] + 10) - self._spBgZhankDfSize.height * self:getScale())
	self:updateCellVisible()
end
function SlotLeftFloatView:onEnterFinish()
	SlotLeftFloatView.super.onEnterFinish(self)
	
	self:updateBubbleView()
	self.__bEnterFinish = true
end

function SlotLeftFloatView:buttonSwallowTouches(_node)
    if not _node then
        return
    end

    --绑定按钮监听
    if tolua.type(_node) == "ccui.Button" or tolua.type(_node) == "ccui.Layout" then
        _node:setSwallowTouches(false)
    end
    for _, node in pairs(_node:getChildren()) do
        self:buttonSwallowTouches(node)
    end
end

-- 节点动画过程中 不可点击
function SlotLeftFloatView:setListMaskVisible(_bVisible)
	self._btnTouchMask:setVisible(_bVisible and true or false)
end

--[[
    关卡左边条 是否展开状态
    _viewRefKey: 
]]
function SlotLeftFloatView:checkIsUnfload(_viewRefKey)
	if self._showType == SlotLeftFloatCfg.SHOW_TYPE.FOLD then
		return false
	end

	if type(_viewRefKey) == "string" then
		return self._unFoldCellCfgInfo.viewRefKey == _viewRefKey
	end

	return true
end

--[[
    关卡左边条 跳转到节点位置
    _viewRefKey: 
]]
function SlotLeftFloatView:jumpEntryNode(_viewRefKey, _scrollTime)
	if self._showType == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
		return false
	end

	if type(_viewRefKey) == "string" then
		local scrollTime = _scrollTime or 0
		local cell = self._scrlView:getChildByName(_viewRefKey)
		if not cell then
			-- 没有该入口
			return false
		end
		local cellCfg = cell:getCfgInfo()
		local scrlViewSize = self._scrlView:getContentSize()
		local innerSize = self._scrlView:getInnerContainerSize()
		if innerSize.height <= scrlViewSize.height then
			return false
		end
		local curPercent = self._scrlView:getScrolledPercentVertical()
		local posWT = self._scrlView:convertToWorldSpace(cc.p(0, scrlViewSize.height))
		local posWS = cell:convertToWorldSpace(cc.p(0, cellCfg.sizeInfo.height))
		local percent = curPercent + math.floor((posWT.y - posWS.y) / (innerSize.height-scrlViewSize.height) * 100)
		if percent and percent > 0 then
			if scrollTime > 0 then
				self._scrlView:scrollToPercentVertical(percent, scrollTime, false)
			else
				self._scrlView:jumpToPercentVertical(percent)
			end
		end
		return true
	end
	return false
end

-- 获取 方向
function SlotLeftFloatView:getDirectionH()
	return self._edgeTypeList[1]== ccui.LayoutComponent.HorizontalEdge.Left and "left" or "right"
end

-- 获取按钮 世界坐标
function SlotLeftFloatView:getBtnPosW()
	return self._nodeBtn:convertToWorldSpace(cc.p(0, 30)) 
end

-- 获取左边条 根节点
function SlotLeftFloatView:getRootNode()
	return self:findChild("node_ref")
end

-- 获取左边条 顶部坐标
function SlotLeftFloatView:getTopFlyPosW()
	return self._nodeBtn:convertToWorldSpace(cc.p(0, 30)) 
end

-- 关卡左边条 是否显示
function SlotLeftFloatView:checkHideBtnVisible()
	return self:isVisible()
end

return SlotLeftFloatView
