--[[
Author: chenxuechen chenxuechen159@126.com
Date: 2023-10-12 16:19:04
LastEditors: chenxuechen chenxuechen159@126.com
LastEditTime: 2023-10-12 20:02:56
FilePath: /SlotNirvana/src/GameModule/FloatView/views/slotLeft/SlotLeftFloatView.lua
Description: 关卡左边条 view
--]]
local BaseFloatView = util_require("GameModule.FloatView.views.base.BaseFloatView")
local SlotLeftFloatCfg = util_require("GameModule.FloatView.config.SlotLeftFloatCfg")
local SlotLeftFloatView = class("SlotLeftFloatView", BaseFloatView)

local LISTVIEW_BG_SPACE = 15 -- 背景和list间隔

function SlotLeftFloatView:ctor()
	SlotLeftFloatView.super.ctor(self)

	self._waitAddCellInfoList = {} -- 待增加左边条入口 list
	self._marginList = {-2, 0, 100, 100} -- 左右上下
	if util_getBangScreenHeight() > 0 and (not globalData.slotRunData.isPortrait) then
		-- 有刘海再加点space
		self._marginList[1] = util_getBangScreenHeight() * 0.5 - 10
		self._marginList[2] = util_getBangScreenHeight() * 0.5 - 10
	end
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
	return "LeftFrame/SlotLeftFloatNode.csb"
end

function SlotLeftFloatView:initCsbNodes()
	SlotLeftFloatView.super.initCsbNodes(self)

	self._listView = self:findChild("ListView")
	self._listView:setScrollBarEnabled(false)
	self._listParent = self._listView:getParent()
	self._spBg = self:findChild("sp_bg")
	self._showWidth = self._spBg:getContentSize().width
	self._nodeBtn = self:findChild("node_btn")
	self._btnShow = self:findChild("btn_show")
	self._btnHide = self:findChild("btn_hide")
	self._bubbleView = self:findChild("node_bubble")
	self._nodeContent = self:findChild("node_content")

	self._btnTouchMask = self:findChild("btn_touchMask")
	self._btnTouchMaskWidth = self._btnTouchMask:getContentSize().width
	self:setListMaskVisible(false)

	-- 当前关卡 左边条缩放值
	local scale = gLobalActivityManager:getSlotFloatLayerLeft() or 1
	self:setScale(scale)
	self._scale = scale
end

function SlotLeftFloatView:initUI()
	SlotLeftFloatView.super.initUI(self)

	self:checkShowEntryCell()
	self:runCsbAction("idle")

	-- 将touch放到 csbNode上 (有收起展开动作，要更着动)
	util_changeNodeParent(self.m_csbNode, self._touchLayer, 99)
	self._listView:onPosOrSizeChangeCall(util_node_handler(self, self.updateBubbleView))
	self._touchLayer:setVisible(false)
	
	self:registerListener()
end

function SlotLeftFloatView:checkShowEntryCell()
	self:setVisible(false)
	self:onRefreshContentEvt()
end
-- 活动入口
function SlotLeftFloatView:checkActEntry()
	local checkFunc = function(_actData)
		if not _actData or not _actData:isRunning() or (_actData.getPositionBar and _actData:getPositionBar() ~= 1) then
			-- 没有数据 活动没开 不在左边条显示
			return
		end

		local refName = _actData:getRefName()
		local themeName = _actData:getThemeName()
		if string.find(refName, ACTIVITY_REF.League) or self._listView:getChildByName(refName) then
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
			local view = self._listView:getChildByName(info.viewRefKey)
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
		local teamEntry = self._listView:getChildByName("ClanEntryNode")
		if not teamEntry then
			teamEntry = ClanManager:createMachineEntryNode()
			if teamEntry then
				local info = {
					node = teamEntry,
					viewRefKey = "ClanEntryNode",
					zOrder = SlotLeftFloatCfg.SpecialEntryOrders["ClanEntryNode"] or 99
				}
				table.insert(self._waitAddCellInfoList, info)
			end
		end

		
		-- 公会对决
		local teamDuelEntry = self._listView:getChildByName("ClanDuelEntryNode")
		if not teamDuelEntry then
			teamDuelEntry = ClanManager:createClanDuelEntryNode()
			if teamDuelEntry then
				local info = {
					node = teamDuelEntry,
					viewRefKey = "ClanDuelEntryNode",
					zOrder = SlotLeftFloatCfg.SpecialEntryOrders["ClanDuelEntryNode"] or 99
				}
				table.insert(self._waitAddCellInfoList, info)
			end
		end
	end

end

-- 排序 左边条信息 并添加左边条
function SlotLeftFloatView:sortAddEntryCellInfo()
	-- 可显示的所有 左边条 信息
	local exitEntryInfoList = {}
	local totalInfoList = clone(self._waitAddCellInfoList)
	self._waitAddCellInfoList = {}
	local items = self._listView:getItems()
	for _,_cell in pairs(items) do
		if not tolua.isnull(_cell) then
			table.insert(exitEntryInfoList, _cell:getCfgInfo())
		end
	end
	table.insertto(totalInfoList, exitEntryInfoList)

	-- 可显示的所有 左边条 排序
	table.sort(totalInfoList, function(_a, _b)
		local aZorder = _a.zOrder or 99
		local bZorder = _b.zOrder or 99
		return aZorder < bZorder
	end)
	
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

	local cell = self._listView:getChildByName(_info.viewRefKey)
	if cell then
		return
	end

	local count = self._listView:getChildrenCount()
	_idx = _idx or count
	cell = self:createCell(_info)
	self._listView:insertCustomItem(cell, math.max(0, math.min(count, _idx-1) ))
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

	local cell = self._listView:getChildByName(_params.viewRefKey)
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
end

-- 移除 关卡左边条入口
function SlotLeftFloatView:removeEntryCell(_viewRefKey)
	local cell = self._listView:getChildByName(_viewRefKey)
	if not cell then
		return
	end

	self._listView:removeChild(cell)
	self._listView:setContentSize(cc.size(self._listView:getContentSize().width, 0))

	if self._unFoldCellCfgInfo and _viewRefKey == self._unFoldCellCfgInfo.viewRefKey and self._showType == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
		-- 展开状态下 被移除
		-- 直接 变为 收起状态
		self:showEntryNodeFold(_viewRefKey)
	end

	self:refreshContentUI()
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
function SlotLeftFloatView:getEntryNode(_viewRefKey)
	local cell = self._listView:getChildByName(_viewRefKey)
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
	self._listView:doLayout()
	self:updateCellVisible()
	self:updateListViewHeight()
	self:updateBgStatus()

	-- 界面后期 大小变化再 排列
	if self.__bEnterFinish and self._showType == SlotLeftFloatCfg.SHOW_TYPE.FOLD then
		self:correctMarginInfo()
		self:updateLayoutParameter()
		ccui.Helper:doLayout(self:getParent())
	end
end

-- 更新 左边条 大小
function SlotLeftFloatView:updateListViewHeight()
	local cellCount = self._listView:getChildrenCount()
	self:setVisible(cellCount > 0)

	local size = self._listView:getInnerContainerSize()
	if cellCount <= SlotLeftFloatCfg.SHOW_MAX_CHILD_COUNT then
		if size.height > 550 then
			size.height =  550
		end

		self._listView:setBounceEnabled(false)
		self:updateContentSize(size)
		return
	end

	self._listView:setBounceEnabled(true)
	self:updateContentSize(cc.size(size.width, 550))
end

-- 更新 左边条 背景显隐
function SlotLeftFloatView:updateBgStatus()
	-- local cellCount = self._listView:getChildrenCount()
	-- self._spBg:setVisible(cellCount > 1 and self._showType == SlotLeftFloatCfg.SHOW_TYPE.FOLD)
	-- self._nodeBtn:setVisible(cellCount > 1 and self._showType == SlotLeftFloatCfg.SHOW_TYPE.FOLD)
	self._spBg:setVisible(false)
	self._nodeBtn:setVisible(false)
end

-- 更新入口显隐
function SlotLeftFloatView:updateCellVisible()
	for _, v in pairs(self._listView:getItems()) do

		local name = v:getName()
		local bShow = true
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
		local cell = self._listView:getChildByName(self._unFoldCellCfgInfo.viewRefKey)
		if not tolua.isnull(cell) then
			cell:setVisible(true)
		end
	end

	local bubbleList = self._bubbleView:getChildren()
	local aabbW = self._listView:getWordAabb()
	aabbW.width = aabbW.width * self._parentScale
	aabbW.height = aabbW.height * self._parentScale
	local bVisible = self._btnHide:isVisible()
	for _, _node in ipairs(bubbleList) do

		while true do
			local viewRefKey = _node:getName()
			local cell = self._listView:getChildByName(viewRefKey)
			if not cell then
				break
			end
			local size = cell:getContentSize()
			local posW = cell:convertToWorldSpace(cc.p(size.width*0.5, size.height*0.5))
			local posL = self._bubbleView:convertToNodeSpace(posW) 
			_node:setPositionY(posL.y)

			local bCanVisible = bVisible and cc.rectContainsPoint(aabbW, posW)
			if bCanVisible and self._unFoldCellCfgInfo then
				bCanVisible = self._unFoldCellCfgInfo.viewRefKey == viewRefKey
			end
			_node:setVisible(bCanVisible)
			break
		end

	end
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_UPDATE_ENTRY_VISIBLE)
end

function SlotLeftFloatView:clickFunc(sender)
    local name = sender:getName()
	if self._bActing then
		return
	end

    if name == "btn_show" then
        self:playShowViewAct()
    elseif name == "btn_hide" then
        self:playHideViewAct()
    end
	gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
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
		self._btnShow:setVisible(false)
		self._btnHide:setVisible(true)
		self._touchLayer:setVisible(false)
		self._bActing = false
		self:updateBubbleView()

		if _cb then
			_cb()
		end

	end)
	self.m_csbNode:runAction(cc.Sequence:create(moveTo, endCB))
	self._nodeContent:setVisible(true)
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

		-- 显示 show 按钮
		self._btnShow:setVisible(true)
		self._btnHide:setVisible(false)
		self._nodeContent:setVisible(false)
		self._bActing = false
		self:updateBubbleView()

		if _cb then
			_cb()
		end

	end)
	self._touchLayer:setVisible(false)
	self.m_csbNode:runAction(cc.Sequence:create(moveTo, endCB))
end

-- 拖拽滑动结束 矫正左右 margin
function SlotLeftFloatView:correctMarginInfo()
	local horizontalOverType, verticalOverType = SlotLeftFloatView.super.correctMarginInfo(self)
	local pos = cc.p(self:getPosition())
	if not horizontalOverType then
		-- 左边靠左， 右边靠右
		self._edgeTypeList[1] = (pos.x < display.cx) and ccui.LayoutComponent.HorizontalEdge.Left or ccui.LayoutComponent.HorizontalEdge.Right
	end

	--更新按钮位置
	self:updateBtnPos()

	-- 通知改变 方向
	gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_CHANGE_STOP_DIRECTION_LEFTFRAME, self._edgeTypeList[1]== ccui.LayoutComponent.HorizontalEdge.Left and "left" or "right")
end

-- 更新 左边调size
function SlotLeftFloatView:updateContentSize(_size)
	_size.width = self._showWidth
	
	self._size = _size
	self:setContentSize(cc.size(_size.width*self._scale, _size.height*self._scale))
	self.m_csbNode:setPositionY(_size.height)

	-- 背景
	self._spBg:setContentSize(cc.size(_size.width, _size.height + LISTVIEW_BG_SPACE*2))
	self._spBg:setPositionY(LISTVIEW_BG_SPACE)

	-- 按钮位置 调整
	self:updateBtnPos()
	-- listView
	self._listView:setContentSize(_size)
	self._listParent:setContentSize(cc.size(1200, _size.height))
	self:updateListViewPos()
	-- 触摸层
	self:updateTouchSize(_size)

	-- 居中显示
	if self._showType == SlotLeftFloatCfg.SHOW_TYPE.FOLD then
		self:setPositionY(display.height/self._parentScale * 0.5  - self:getContentSize().height * self:getScale() * 0.5 + 30)
	end
end
function SlotLeftFloatView:getContentSize()
	-- 没有缩放的 size
	return self._size or cc.size(0,0)
end
function SlotLeftFloatView:updateTouchSize(_size)
	_size = clone(_size or self:getContentSize())
	local posY = 0
	if self._unFoldCellCfgInfo and self._showType == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
		local unfoldHeight = self._unFoldCellCfgInfo.sizeInfo.unfoldHeight
		local subH = unfoldHeight - _size.height
		posY = self._listParent:getPositionY()
		self._marginList[3] = self._sourceMarginList[3] + posY 
		self._marginList[4] = self._sourceMarginList[4] - posY + subH
		_size.height = unfoldHeight
	else
		self._marginList[3] = self._sourceMarginList[3]
		self._marginList[4] = self._sourceMarginList[4]
	end

	_size.height = _size.height + LISTVIEW_BG_SPACE*2
	self._touchLayer:setPositionY(-_size.height + LISTVIEW_BG_SPACE + posY)
	self._btnTouchMask:setContentSize(cc.size(self._btnTouchMaskWidth, _size.height))
	SlotLeftFloatView.super.updateTouchSize(self, _size)
end
function SlotLeftFloatView:updateListViewPos()
	local unfoldCell 
	if self._unFoldCellCfgInfo and self._showType == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
		unfoldCell = self._unFoldCellCfgInfo.node
	end

	local listVH = self._listView:getContentSize().height
	local posY = 0
	if not tolua.isnull(unfoldCell) then
		local posW_source= unfoldCell:convertToWorldSpace(cc.p(0, self._unFoldCellCfgInfo.sizeInfo.height*0.5))
		-- local posW_target = self._listView:convertToWorldSpace(cc.p(0, listVH))
		-- posY = posW_target.y - posW_source.y
		local posW_targetY = display.cy + self:getScale() * self._parentScale * (self._unFoldCellCfgInfo.sizeInfo.unfoldHeight * 0.5 + 30)-- 居中显示
		posY = self._listView:convertToNodeSpace(cc.p(0, self._listView:getWordAabb().y + posW_targetY - posW_source.y)).y
	end
	self._listView:setPositionY(posY+self._listView:getContentSize().height)
	-- self._listParent:setPositionY(posY)
end
-- 按钮位置 调整
function SlotLeftFloatView:updateBtnPos()
	local size = self:getContentSize()

	local pos = cc.p(size.width, -size.height*0.5)
	local scale = 1
	local edgeTypeH = self._edgeTypeList[1]
	if edgeTypeH == ccui.LayoutComponent.HorizontalEdge.Right then
		pos.x = 0
		scale = -1
	end
	self._nodeBtn:setPosition(pos)
	self._nodeBtn:setScale(scale)
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
		self:sortAddEntryCellInfo()
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

	if self._bActing or not self._btnHide:isVisible() then
		return
	end

	local cb = function()
		-- 向外抛出消息告诉界面当前已经收缩到屏幕外了 (有功能是 根据该事件做展开收起动画)
		performWithDelay(self,function()
			-- 有可能 有的 人 还没注册事件 就处理 显示状态了， 抛事件 很坑（以后改吧）
			gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_MOVEIN)
		end,0)

		-- listView 取消滑动
		self._listView:stopAutoScroll() 
		if _params.type == SlotLeftFloatCfg.SHOW_TYPE.UNFOLD then
			self:showEntryNodeUnfold(_params.viewRefKey, func)
		else
			self:showEntryNodeFold(_params.viewRefKey, func)
		end

		self._nodeBtn:setVisible(false)
		self._bActing = true
		self:setListMaskVisible(true)
		local showCb = function()
			self:correctMarginInfo()
			self:updateLayoutParameter()
			ccui.Helper:doLayout(self:getParent())
		end
		local delayTime = cc.DelayTime:create(0.2)
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
	self:onRefreshContentEvt()
	self:updateCellVisible()
	self:updateListViewPos()
	self:updateTouchSize(nil)
	self:updateBgStatus()
	self:setPositionY(display.height/self._parentScale * 0.5  - self:getContentSize().height * self:getScale() * 0.5 + 30)
	self._listParent:setClippingEnabled(true)
	self._listView:setTouchEnabled(true)
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

	local cell = self._listView:getChildByName(_viewRefKey)
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
	self:updateCellVisible()
	self:updateListViewPos()
	self:updateTouchSize(nil)
	self:updateBgStatus()
	self._listParent:setClippingEnabled(false)
	self._listView:setTouchEnabled(false)
	_func()
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
	-- self:setPositionY(display.height/self._parentScale - (self._marginList[3] + 20) - self:getContentSize().height * self:getScale())
	-- self:setPositionY(display.height/self._parentScale - (self._marginList[3] - 20) - self:getContentSize().height * self:getScale())
	-- 居中显示
	if self._showType == SlotLeftFloatCfg.SHOW_TYPE.FOLD then
		self:setPositionY(display.height/self._parentScale * 0.5  - self:getContentSize().height * self:getScale() * 0.5 + 30)
	end
end
function SlotLeftFloatView:onEnterFinish()
	SlotLeftFloatView.super.onEnterFinish(self)
	
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

function SlotLeftFloatView:checkTouchMove(_subX, _subY)
	local bCanMove = SlotLeftFloatView.super.checkTouchMove(self, _subX, _subY)
	if not bCanMove then
		return false
	end

	local cellCount = self._listView:getChildrenCount()
	if cellCount <= SlotLeftFloatCfg.SHOW_MAX_CHILD_COUNT then
		return bCanMove
	end

	return math.abs(_subX) > 50
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
		local cell = self._listView:getChildByName(_viewRefKey)
		if not cell then
			-- 没有该入口
			return false
		end
		local index = self._listView:getIndex(cell)
		if index and index > 0 then
			if scrollTime > 0 then
				self._listView:scrollToItem(index, cc.p(0.5, 0.5), cc.p(0.5, 0.5), scrollTime)
			else
				self._listView:jumpToItem(index, cc.p(0.5, 0.5), cc.p(0.5, 0.5))
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
	return self._btnHide:convertToWorldSpaceAR(cc.p(0, 0))
end

-- 获取左边条 根节点
function SlotLeftFloatView:getRootNode()
	return self:findChild("node_ref")
end

-- 获取左边条 顶部坐标
function SlotLeftFloatView:getTopFlyPosW()
	local size = self._spBg:getContentSize()
	local pos = self._spBg:convertToWorldSpace(cc.p(size.width * 0.5, (size.height-15) * self:getScale() ))
	return pos
end

-- 关卡左边条 是否显示
function SlotLeftFloatView:checkHideBtnVisible()
	return self._btnHide:isVisible()
end

return SlotLeftFloatView