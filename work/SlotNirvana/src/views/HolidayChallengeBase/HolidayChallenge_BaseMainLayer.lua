--[[
    @desc: HolidayChallenge_BaseMainLayer 主界面 是个空的界面
    time:2021-07-22
    优化新版代码结构 继承 BaseRotateLayer  
]]
local BaseRotateLayer = require("base.BaseRotateLayer")
local HolidayChallenge_BaseMainLayer = class("HolidayChallenge_BaseMainLayer", BaseRotateLayer)

function HolidayChallenge_BaseMainLayer:ctor( )
    HolidayChallenge_BaseMainLayer.super.ctor(self)
    self:setKeyBackEnabled(false) -- 吞噬掉返回键
    self:setPauseSlotsEnabled(true) 
end

function HolidayChallenge_BaseMainLayer:initDatas()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    self:setLandscapeCsbName(self.m_activityConfig.RESPATH.MAPMAIN_LAYER)
end

function HolidayChallenge_BaseMainLayer:initUI()
    HolidayChallenge_BaseMainLayer.super.initUI(self)
    --数据层
    self.m_activityRunData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    if self.m_activityConfig.RESPATH.MAIN_BGM_MP3 then
        self:setBgm(self.m_activityConfig.RESPATH.MAIN_BGM_MP3)
    end
    self.m_completedTaskList = {}

    self.m_bActionStarAnima = false -- 星星是否正在播放集满的动画

    --滑动控制类
    self.m_scrollBuilding = nil --滑动背景类
    self.m_scrollRoad = nil --滑动路类

    self.m_nodeScrollBuilding = nil -- 滑动背景对象
    self.m_nodeScrollRoad = nil --滑动路对象

    self.m_isMoving = false
    
    self:initViewUI()
end

function HolidayChallenge_BaseMainLayer:initCsbNodes()
    --UI层
    self.m_nodeUI       = self:findChild("node_ui") 
    --两个滑动层csb
    self.m_nodeMapBuilding = self:findChild("node_building") 
    self.m_nodeMapRoad     = self:findChild("node_road") 

    -- self.m_nodeEffect = self:findChild("node_ef_yanhua")
end

--重写父类方法
function HolidayChallenge_BaseMainLayer:onShowedCallFunc( )
    self:runCsbAction("idle", true, nil,60)
end

-- --重写父类方法
function HolidayChallenge_BaseMainLayer:playShowAction()
    local action = function(_callback)
        gLobalSoundManager:playSound("Sounds/soundOpenView.mp3")
        util_setCascadeOpacityEnabledRescursion(self:findChild("Node_1"), true)
        self:runCsbAction("start", false,function()
            if _callback then
                _callback()
            end
        end,60)
    end
    HolidayChallenge_BaseMainLayer.super.playShowAction(self,action)

end

function HolidayChallenge_BaseMainLayer:playHideAction()
    local action = function(_callback)
        --gLobalSoundManager:playSound("Sounds/soundHideView.mp3")
        util_setCascadeOpacityEnabledRescursion(self:findChild("Node_1"), true)
        self:runCsbAction("over", false,function()
            if _callback then
                _callback()
            end
        end,60)
    end
    HolidayChallenge_BaseMainLayer.super.playHideAction(self,action)
end

function HolidayChallenge_BaseMainLayer:onEnter()

    -- self.m_perBgMusicName = gLobalSoundManager:getCurrBgMusicName()
    -- gLobalSoundManager:playBgMusic(self.m_activityConfig.RESPATH.Base_BGM_MP3)

    HolidayChallenge_BaseMainLayer.super.onEnter(self)

    gLobalNoticManager:addObserver(self,function(target, params)
        --全部加载完毕
        --...空闲预留
        local runData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
        if not G_GetMgr(ACTIVITY_REF.HolidayChallenge):getCompletedGuide() then
            if runData:getCurrentPoints() > 0 then
                -- 引导只展示一次
                gLobalDataManager:setBoolByField(self.m_activityConfig.GUIDE_KEY,true) 
                self:checkTaskStatus()
            else
                self:openGuide()
            end
        else
            self:checkTaskStatus()
        end
    end,ViewEventType.NOTIFY_HOLIDAYCHALLENGE_LOADRES_FINISH)

    -- 引导结束后,需要检测一次是否有未完成的任务
    gLobalNoticManager:addObserver(
        self,
        function(target, params)

            self:checkTaskStatus()
        end,
    ViewEventType.NOTIFY_HOLIDAYCHALLENGE_GUIDE_OVER)

    gLobalNoticManager:addObserver(self,function(target, params)
        local moveX = params.moveX

        self:updateScrollPos(moveX)
    end,ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE_CAR)

    gLobalNoticManager:addObserver(self,function(target, params)
        local flag = params.flag
        self:setScrollMoveFlag(flag)
    end,ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE)
    
    -- 移动结束
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:checkTaskStatus(true) -- 再次检测是否有未完成的任务
        end,
    ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE_OVER)
    
    -- 刷新
    gLobalNoticManager:addObserver(
        self,
        function(sender,param)
            if param.success then
                -- 播放动效
                self:playMoveAction()
            else
                self.m_mainUI:setLayerCanClick(true)
            end
        end,
        ViewEventType.NOTIFY_HOLIDAYCHALLENGE_REFRESH
    )

    -- 判断零点刷新
    gLobalNoticManager:addObserver(
        self,
        function(sender, params)
            self:updateViewZero()
        end,
        ViewEventType.NOTIFY_HOLIDAYCHALLENGE_ZERO_REFRESH_SUCCESS
    )

end

function HolidayChallenge_BaseMainLayer:setViewOverFunc(_func )
    self.m_newOverFunc = _func
end

function HolidayChallenge_BaseMainLayer:initViewUI( )

    -- 因为奖励领取之后不会关闭掉这个界面, 集卡会调用push next ，需要再这里屏蔽掉
    if gLobalPopViewManager:isPopView() then
        gLobalPopViewManager:setPause(true)
    end

    self.m_currLayerScale = self.m_csbNode:getChildByName("root"):getScale()

    self:updateView()
end

-- 更新显示
function HolidayChallenge_BaseMainLayer:updateView()
    if not self.m_activityRunData then
        return
    end

    self:createMainUILayer()
    self:initScrollLayer()
end

function HolidayChallenge_BaseMainLayer:createMainUILayer()
    local mainUiPath = "views.HolidayChallengeBase.HolidayChallenge_BaseMainUI"
    if self.m_activityConfig and self.m_activityConfig.CODE_PATH.MAIN_UI then
        mainUiPath = self.m_activityConfig.CODE_PATH.MAIN_UI
    end
    self.m_mainUI =  util_createView(mainUiPath)
    self.m_nodeUI:addChild(self.m_mainUI)
    self.m_mainUI:setParent(self)
    self.m_mainUI:setScale(self.m_currLayerScale)
    self.m_nodeUI:setPosition(-display.cx*self.m_currLayerScale,-display.cy*self.m_currLayerScale)
end

-- 零点刷新处理
function HolidayChallenge_BaseMainLayer:updateViewZero( )
    if not G_GetMgr(ACTIVITY_REF.HolidayChallenge):isCanShowLayer() then
        -- 恢复背景音
        -- gLobalSoundManager:playBgMusic(self.m_perBgMusicName)
        self:closeUI(function (  )
            if self.m_newOverFunc then
                self.m_newOverFunc()
            end
        end)
    end
end

function HolidayChallenge_BaseMainLayer:checkTaskStatus(_isMoveEnd)
    -- 检测的时候不允许滑动
    self:setScrollMoveFlag(false)

    self.m_completedTaskList = {}
    if G_GetMgr(ACTIVITY_REF.HolidayChallenge):getIsMaxPoints() or not self.m_activityRunData then
        print("------ 当前到头啦！ -- 不需要再进行下一步了")
        self:setScrollMoveFlag(true)
        if not _isMoveEnd then
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_SHOW_WHEEL)
        end
        return
    end

    -- 计算当前已完成的任务
    local tbTaskData = self.m_activityRunData:getTaskData()
    for i = 1 ,#tbTaskData do
        local taskData = tbTaskData[i]
        if taskData and taskData:getStatus() == "completed" then
            table.insert(self.m_completedTaskList,clone(taskData))
        end
    end

    if next(self.m_completedTaskList) then
        local taskData = self.m_completedTaskList[1]
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):sendRefreshReq(taskData:getTaskType(),1)
    else
        self:setScrollMoveFlag(true)
    end
end
-------------------------------- 滑动部分 --------------------------------
function HolidayChallenge_BaseMainLayer:initScrollLayer( )
    -- 初始化滑动界面
    local displayX = display.width

    -- 创建 road 滑动界面
    local roadPath = "views.HolidayChallengeBase.HolidayChallenge_BaseRoadLayer"
    if self.m_activityConfig and self.m_activityConfig.CODE_PATH.ROAD_LAYER then
        roadPath = self.m_activityConfig.CODE_PATH.ROAD_LAYER
    end
    self.m_nodeScrollRoad = util_createView(roadPath)
    self.m_nodeMapRoad:addChild(self.m_nodeScrollRoad )
    self.m_nodeMapRoad:setPosition(-display.cx,-display.cy)
    -- self:addChild(self.m_nodeScrollRoad,1)
    -- self.m_nodeScrollRoad:setPosition(-display.cx,-display.cy)

    --创建 路 滑动类 默认创建出来是在layer 的中心点
    local roadScrollPath = "views.HolidayChallengeBase.HolidayChallenge_BaseRoadScroll"
    if self.m_activityConfig and self.m_activityConfig.CODE_PATH.ROAD_SCORLL then
        roadScrollPath = self.m_activityConfig.CODE_PATH.ROAD_SCORLL
    end
    self.m_scrollRoad = util_createView(roadScrollPath, self.m_nodeScrollRoad, cc.p(0,0))
    local contentLen = self.m_nodeScrollRoad:getContentLen() - self.m_activityConfig.ROAD_CONFIG.ROAD_DIS -- csc 万圣节特意写的-100 长度做效果
    local mapLimitLenRoad = displayX - contentLen 
    self.m_scrollRoad:setMoveLen(mapLimitLenRoad)

    -- 创建背景 滑动界面
    local buildingLayerPath = "views.HolidayChallengeBase.HolidayChallenge_BaseBuildingLayer"
    if self.m_activityConfig and self.m_activityConfig.CODE_PATH.BUILDING_LAYER then
        buildingLayerPath = self.m_activityConfig.CODE_PATH.BUILDING_LAYER
    end
    self.m_nodeScrollBuilding = util_createView(buildingLayerPath)
    self.m_nodeMapBuilding:addChild(self.m_nodeScrollBuilding )
    self.m_nodeMapBuilding:setPosition(-display.cx,-display.cy)
    -- self:addChild(self.m_nodeScrollBuilding,1)
    -- self.m_nodeScrollBuilding:setPosition(-display.cx,-display.cy)

    --创建背景滑动类 默认创建出来是在layer 的中心点
    local buildingScrollPath = "views.HolidayChallengeBase.HolidayChallenge_BaseBuildingScroll"
    if self.m_activityConfig and self.m_activityConfig.CODE_PATH.BUILDING_SCORLL then
        buildingScrollPath = self.m_activityConfig.CODE_PATH.BUILDING_SCORLL
    end
    self.m_scrollBuilding = util_createView(buildingScrollPath, self.m_nodeScrollBuilding, cc.p(0,0))
    local bgContentLen = self.m_nodeScrollBuilding:getContentLen()

    local mapLimitLenBuild = displayX - bgContentLen
    self.m_scrollBuilding:setMoveLen(mapLimitLenBuild)

    local bgFriction = mapLimitLenBuild/mapLimitLenRoad 
    self.m_scrollBuilding:setFriction(bgFriction) -- 设置背景的摩擦系数

    -- 根据当前小车的位置计算出默认的 起始坐标
    local startX = self.m_nodeScrollRoad:getStartX()
    self:updateScrollPos(startX)

    -- 默认不可滑动 需要等到星星都加载完毕
    self:setScrollMoveFlag(false)
end

-- 小车移动的同时滑动背景条
function HolidayChallenge_BaseMainLayer:updateScrollPos(_moveX)
    --更新滑动层坐标
    self.m_scrollBuilding:startMove(_moveX)
    self.m_scrollRoad:startMove(_moveX)
end

function HolidayChallenge_BaseMainLayer:setScrollMoveFlag(_canMove)
    if _canMove == false then
        self.m_scrollBuilding:stopAutoScroll()
        self.m_scrollRoad:stopAutoScroll()
    end
    
    self.m_scrollBuilding:setMoveState(_canMove)
    self.m_scrollRoad:setMoveState(_canMove)

    self.m_isMoving = not _canMove
    self.m_mainUI:setLayerCanClick(_canMove)
end

-------------------------------- 动画部分 --------------------------------
function HolidayChallenge_BaseMainLayer:playMoveAction()
    -- 调用动画
    local newRunData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()
    if newRunData then
        local addNum = newRunData:getCurrentPoints() - self.m_activityRunData:getCurrentPoints()
        self.m_activityRunData = newRunData

        self.m_nodeScrollRoad:setMoveNum(addNum)
        self.m_nodeScrollRoad:playStarMoveAction()
    end
end
-------------------------------- 引导部分 -----------------------------
function HolidayChallenge_BaseMainLayer:openGuide( )
    -- 引导只展示一次
    gLobalDataManager:setBoolByField(self.m_activityConfig.GUIDE_KEY,true) 
    -- 提示场景进行移动
    self.m_nodeScrollRoad:startPlayGuideAction()
end

function HolidayChallenge_BaseMainLayer:closeFunc()

    -- 恢复背景音
    -- gLobalSoundManager:playBgMusic(self.m_perBgMusicName)

    self:closeUI(function (  )
        if gLobalPopViewManager:isPopView() then
            gLobalPopViewManager:setPause(false)
            gLobalNoticManager:postNotification(ViewEventType.PUSH_VIEW_NEXT)
        end

        if self.m_newOverFunc then
            self.m_newOverFunc()
        end
        
    end)
end

return HolidayChallenge_BaseMainLayer