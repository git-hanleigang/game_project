--[[
    @desc: HolidayChallenge_BaseMainUI 主界面上下UI
    time:2021-05-31
    优化新版代码结构 继承 BaseRotateLayer 
]]
local HolidayChallenge_BaseMainUI = class("HolidayChallenge_BaseMainUI",BaseView)

function HolidayChallenge_BaseMainUI:ctor()
    HolidayChallenge_BaseMainUI.super.ctor(self)
    --不需要做动画
    self.m_isShowActionEnabled = false 
    self.m_isHideActionEnabled = false
    self.m_isMaskEnabled = false
end

function HolidayChallenge_BaseMainUI:getCsbName()
    self.m_activityConfig = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getConfig()
    return self.m_activityConfig.RESPATH.MAPMAINUI_NODE
end

function HolidayChallenge_BaseMainUI:initUI()
    HolidayChallenge_BaseMainUI.super.initUI(self)
    --数据层
    self.m_activityRunData = G_GetMgr(ACTIVITY_REF.HolidayChallenge):getActivityData()

    -- 默认界面是不能点击的
    self.m_bCanClick = false

    self:initViewUI()
    self:checkTimer()
end

function HolidayChallenge_BaseMainUI:initCsbNodes()
    --UI层
    self.m_btnClose = self:findChild("btn_close") 

    self.m_nodeTopPos = self:findChild("node_up") -- 用作适配的顶部节点
    self.m_nodeBottomPos = self:findChild("node_down") -- 用作适配的底部节点
    self.m_nodeTopPos:setPositionY(display.cy)
    self.m_nodeBottomPos:setPositionY(-display.cy)

    self.m_node_box = self:findChild("node_box")
    self.clickArea = self:findChild("Panel_box")
    self.m_node_BoxBubble = self:findChild("node_BoxBubble")
    self:addClick(self.clickArea)

    if  self.m_nodeTopPos then
        util_getAdaptNode(self.m_nodeTopPos)
    end
    if self.m_nodeBottomPos then
        util_getAdaptNode(self.m_nodeBottomPos)
    end
    
    self.m_lbDayTime = self:findChild("lb_time")
    self.m_labProgress = self:findChild("lb_number") 
    self.Base = self:findChild("lb_des")

    self:startButtonAnimation("btn_pay", "sweep", true) 

    local key = "" .. G_GetMgr(ACTIVITY_REF.HolidayChallenge):getCurrThemeName() .."MainUI:btn_pay"
    local lbString = gLobalLanguageChangeManager:getStringByKey(key) ~= "" and gLobalLanguageChangeManager:getStringByKey(key) or "GOLDEN HUNT"
    self:setButtonLabelContent("btn_pay", lbString)

    local key_1 = "" .. G_GetMgr(ACTIVITY_REF.HolidayChallenge):getCurrThemeName() .."MainUI:btn_rule"
    local lbString_1 = gLobalLanguageChangeManager:getStringByKey(key_1) ~= "" and gLobalLanguageChangeManager:getStringByKey(key_1) or "SEE RULES"
    self:setButtonLabelContent("btn_rule", lbString_1)
end

function HolidayChallenge_BaseMainUI:onEnter()
    HolidayChallenge_BaseMainUI.super.onEnter(self)

    -- 移动结束
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            self:updateProgressStatus() -- 刷新进度
        end,
    ViewEventType.NOTIFY_HOLIDAYCHALLENGE_MOVE_OVER)

    -- 高亮按钮
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.reset then
                self:resetGuideNodeZOrder()
            else
                self:changeGuideNodeZorder()
            end
        end,
    ViewEventType.NOTIFY_HOLIDAYCHALLENGE_GUIDE_CHANGENODEZORDER)
end

function HolidayChallenge_BaseMainUI:onExit()
    HolidayChallenge_BaseMainUI.super.onExit(self)

    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
    end
end

function HolidayChallenge_BaseMainUI:clickFunc(sender)
    if not self.m_bCanClick then
        return
    end
    local name = sender:getName()

    if self.m_btnClick then
        return 
    end
    self.m_btnClick = true

    if not G_GetMgr(ACTIVITY_REF.HolidayChallenge):isCanShowLayer() then
        return
    end
    if name == "btn_pay" then
        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_HOLIDAYCHALLENGE_GUIDE_NEXT_STEP)
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):createPayLayer()
    elseif name == "btn_rule" then
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):showRuleLayer()
    elseif name == "btn_close" then
        --通知给父类
        if self.m_parent and self.m_parent.closeFunc then
            self.m_parent:closeFunc()
        end
    elseif name == "Panel_box" then
        G_GetMgr(ACTIVITY_REF.HolidayChallenge):showBoxBubbleLayer()
    end

    if not tolua.isnull(self) then
        performWithDelay(self,function()
            self.m_btnClick = false
        end,0.3)
    end
end

function HolidayChallenge_BaseMainUI:initViewUI( )
    -- 更新进度
    self:updateProgressStatus()
end

function HolidayChallenge_BaseMainUI:updateProgressStatus( )
    self.m_labProgress:setString(G_GetMgr(ACTIVITY_REF.HolidayChallenge):getProgressString())
end

function HolidayChallenge_BaseMainUI:checkTimer()
    if self.activityAction ~= nil then
        self:stopAction(self.activityAction)
    end
    self.activityAction = util_schedule(self,function()
        self:updateLeftTime()
    end,1)
    self:updateLeftTime()
end

-- 更新剩余时间
function HolidayChallenge_BaseMainUI:updateLeftTime()

    if G_GetMgr(ACTIVITY_REF.HolidayChallenge):isCanShowLayer() == false then
        if self.activityAction ~= nil then
            self:stopAction(self.activityAction)
            self.activityAction = nil
        end
        -- 活动的关闭是通过零点刷新来控制的 -- 
        -- self:closeUI()
        return
    end
    local expireAt = self.m_activityRunData:getExpireAt()-- 秒
    local leftTime = math.max(expireAt, 0) -- 显示使用 减去一天
    local dayStr = util_daysdemaining(leftTime,true)
    self.m_lbDayTime:setString(dayStr)
end

function HolidayChallenge_BaseMainUI:setLayerCanClick(_touch)
    self.m_bCanClick = _touch
end

function HolidayChallenge_BaseMainUI:setParent(_parent)
    self.m_parent = _parent
end

function HolidayChallenge_BaseMainUI:changeGuideNodeZorder()
    self.data = {}

    local node = self:findChild("node_pay") 
    self.data.node = node
    self.data.zorder = node:getZOrder()
    self.data.parent = node:getParent()
    self.data.pos = cc.p(node:getPosition())

    local nodeWorldPos = node:getParent():convertToWorldSpace(cc.p(node:getPositionX(), node:getPositionY()))
    node:setPosition(nodeWorldPos)

    -- 横竖版都需要适配
    local currLayerScale = self:getUIScalePro() --self.m_csbNode:getChildByName("root"):getScale()
    node:setScale(currLayerScale)

    util_changeNodeParent(gLobalViewManager:getViewLayer(),node,ViewZorder.ZORDER_GUIDE+2)
end

-- 太高层级之后需要设置回来
function HolidayChallenge_BaseMainUI:resetGuideNodeZOrder()
    if self.data and self.data.node ~= nil then
        util_changeNodeParent(self.data.parent,self.data.node ,self.data.zorder)
        self.data.node:setScale(1)
        self.data.node:setPosition(self.data.pos)
        self.data.parent = nil
        self.data.node = nil
        self.data.zorder = 1
        self.data.pos = nil
    end
end

return HolidayChallenge_BaseMainUI