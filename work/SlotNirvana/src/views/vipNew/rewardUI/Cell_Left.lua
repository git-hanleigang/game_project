--[[--
    左边第一列
    冻结列，不能滑动
]]
local BUBBLE_STATUS = {
    OPENED = 1,
    CLOSED = 2
}
local Cell_Left = class("Cell_Left", BaseView)
function Cell_Left:getCsbName()
    return "VipNew/csd/rewardUI/Cell_Left.csb"
end

function Cell_Left:initDatas(_index, _pageIndex, _cellData)
    self.m_index = _index
    self.m_pageIndex = _pageIndex
    self.m_cellData = _cellData
    self.m_bubbleStatus = BUBBLE_STATUS.CLOSED
end

function Cell_Left:initCsbNodes()
    self.m_nodeFlag = self:findChild("node_flag")
    self.m_lbName = self:findChild("lb_name")
    self.m_btnInfo = self:findChild("btn_info")
    self.m_nodeBubble = self:findChild("node_bubble")
    self.m_nodeg1 = self:findChild("img_gezi")
    self.m_nodeg2 = self:findChild("img_gezi2")
end

function Cell_Left:initUI()
    Cell_Left.super.initUI(self)
    self:updateFlag()
    self:updateName()
    self:updateColor()
end

function Cell_Left:updateUI(_pageIndex, _cellData)
    self.m_pageIndex = _pageIndex
    self.m_cellData = _cellData
    self:updateFlag()
    self:updateName()
    self:hideBubble() -- 切页更新cell时，关闭气泡
    self:updateColor()
end

function Cell_Left:updateColor()
    if self.m_nodeg2 then
        if self.m_index%2 == 0 then
            self.m_nodeg2:setVisible(true)
            self.m_nodeg1:setVisible(false)
        else
            self.m_nodeg2:setVisible(false)
            self.m_nodeg1:setVisible(true)
        end
    end
end

function Cell_Left:updateFlag()
    local flag = self.m_cellData.pageFlag
    if flag ~= nil then
        if not self.m_flagNode then
            self.m_flagNode = util_createView("views.vipNew.rewardUI.CellFlag")
            self.m_nodeFlag:addChild(self.m_flagNode)
        end
        self.m_flagNode:setVisible(true)
        self.m_flagNode:updateFlag(flag)
    else
        if self.m_flagNode then
            self.m_flagNode:setVisible(false)
        end
    end
end

function Cell_Left:updateName()
    self.m_lbName:setString(self.m_cellData.pageName)
end

function Cell_Left:showBubble()
    if self.m_bubbleStatus == BUBBLE_STATUS.OPENED then
        return
    end
    self.m_bubbleStatus = BUBBLE_STATUS.OPENED
    if not self.m_bubble then
        self.m_bubble = util_createView("views.vipNew.rewardUI.CellBubble", self.m_pageIndex, self.m_index)
        gLobalViewManager:getViewLayer():addChild(self.m_bubble, ViewZorder.ZORDER_POPUI)
        self.m_bubble:setName("cell_bubble_" .. self.m_pageIndex .. "_" .. self.m_index)
        local worldBubblePos = self.m_nodeBubble:getParent():convertToWorldSpace(cc.p(self.m_nodeBubble:getPosition()))
        self.m_bubble:setPosition(cc.p(worldBubblePos))
    end
    self.m_bubble:updateUI(self.m_pageIndex)
    self.m_bubble:playShow()
    self:initBubbleAutoClose()
end

function Cell_Left:hideBubble()
    if not self.m_bubble then
        return
    end
    if self.m_bubbleStatus == BUBBLE_STATUS.CLOSED then
        return
    end
    self.m_bubbleStatus = BUBBLE_STATUS.CLOSED

    if self.m_bubbleTimer then
        self:stopAction(self.m_bubbleTimer)
        self.m_bubbleTimer = nil
    end
    self.m_bubble:playOver()
end

function Cell_Left:initBubbleAutoClose()
    if self.m_bubbleTimer then
        self:stopAction(self.m_bubbleTimer)
        self.m_bubbleTimer = nil
    end
    self.m_bubbleTimer =
        util_performWithDelay(
        self.m_bubble,
        function()
            if not tolua.isnull(self) then
                self:hideBubble()
            end
        end,
        4
    )
end

function Cell_Left:clickFunc(sender)
    local name = sender:getName()
    if name == "btn_info" then
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
        gLobalNoticManager:postNotification(ViewEventType.VIP_CELL_BUBBLE, {index = self.m_index})
    end
end

function Cell_Left:onEnter()
    Cell_Left.super.onEnter(self)

    -- 点击其他按钮
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params.index == self.m_index then
                self:showBubble()
            else
                self:hideBubble()
            end
        end,
        ViewEventType.VIP_CELL_BUBBLE
    )
    -- 界面关闭气泡消失
    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if not tolua.isnull(self.m_bubble) then
                self.m_bubble:removeFromParent()
                self.m_bubble = nil
            end
        end,
        ViewEventType.VIP_REWARDUI_CLOSE
    )
end

function Cell_Left:onExit()
    Cell_Left.super.onExit(self)

    if self.m_bubbleTimer then
        self:stopAction(self.m_bubbleTimer)
        self.m_bubbleTimer = nil
    end
end

return Cell_Left
