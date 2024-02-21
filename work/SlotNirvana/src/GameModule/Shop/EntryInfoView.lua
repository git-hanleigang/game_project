-- Created by jfwang on 2019-05-21.
-- boostme关卡内 右下角入口
--
local EntryInfoView = class("EntryInfoView", util_require("base.BaseView"))

function EntryInfoView:initUI(data)
    self:createCsbNode("BoostMe/Node_3_1.csb")
    
    self.m_tomorrowLabelValue = self:findChild("lb_number1")
    self.m_currentLabelValue = self:findChild("lb_percent1")

    self.m_tomorrowLabelValue2 = self:findChild("lb_number2")
    self.m_currentLabelValue2 = self:findChild("lb_percent2")

    self.m_layerDirction = "right"
    self.m_panelLeft = self:findChild("Image_1_0")
    self.m_panelRight = self:findChild("Image_1")
    -- self:updatePanelVisible()
    self.m_canShowTips = true
    self:runCsbAction("idle",false,function(  )
        self.m_canShowTips = false
        if self.m_panelLeft and self.m_panelRight then
            self.m_panelLeft:setVisible(false)
            self.m_panelRight:setVisible(false)
        end
    end,60)
end

function EntryInfoView:setEntryInfoView(tomorrow,current)
    if self.m_tomorrowLabelValue ~= nil then
        self.m_tomorrowLabelValue:setString(tomorrow)
    end

    if self.m_currentLabelValue ~= nil then
        self.m_currentLabelValue:setString(current)
    end

    if self.m_tomorrowLabelValue2  then
        if self.m_tomorrowLabelValue2 ~= nil then
            self.m_tomorrowLabelValue2:setString(tomorrow)
        end
    end

    if self.m_currentLabelValue2  then
        if self.m_currentLabelValue2 ~= nil then
            self.m_currentLabelValue2:setString(tomorrow)
        end
    end
end

function EntryInfoView:showView(callback)
    self.m_canShowTips = true
    self:updatePanelVisible()

    gLobalActivityManager:changeBubbleGZorder(self.m_csbNode, 1, true)
    self:runCsbAction("show",false,function(  )
        if callback ~= nil then
            callback()
        end
    end,60)
end

function EntryInfoView:hideView(callback)
    gLobalActivityManager:changeBubbleGZorder(self.m_csbNode, 1, true)
    self:runCsbAction("over",false,function(  )
        if callback ~= nil then
            callback()
        end
        gLobalActivityManager:changeBubbleGZorder(self.m_csbNode, 0, true)
    end,60)
end

function EntryInfoView:updatePanelVisible( )
    if self.m_panelLeft and self.m_panelRight and self.m_canShowTips then
        if self.m_layerDirction == "left" then
            self.m_panelLeft:setVisible(true)
            self.m_panelRight:setVisible(false)
        elseif self.m_layerDirction == "right" then
            self.m_panelLeft:setVisible(false)
            self.m_panelRight:setVisible(true)
        end
    end
end

function EntryInfoView:onEnter( )
    gLobalNoticManager:addObserver(self,function(node,direction)
        if direction then
            self.m_layerDirction = direction
            self:updatePanelVisible()
        end
    end,ViewEventType.NOTIFY_FRAME_LAYER_CHANGE_STOP_DIRECTION_RIGHTFRAME)
end


function EntryInfoView:onExit(  )
    gLobalNoticManager:removeAllObservers(self)
end

return EntryInfoView