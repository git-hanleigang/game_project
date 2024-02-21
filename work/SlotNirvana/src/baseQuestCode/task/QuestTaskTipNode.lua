-- Created by jfwang on 2019-05-21.
-- QuestTaskTipNode
--
local QuestTaskTipNode = class("QuestTaskTipNode", BaseView)
function QuestTaskTipNode:getCsbNodePath()
    return QUEST_RES_PATH.QuestTaskTipNode
end

function QuestTaskTipNode:initUI(data)
    self:createCsbNode(self:getCsbNodePath())

    -- self.m_descValue = self:findChild("BitmapFontLabel_1")
    local desc = data.p_description
    local len = #data.p_params
    if len == 1 then
        local t = util_formatCoins(data.p_params[1], 3, nil, nil, nil, true)
        desc = string.format(desc, tostring(t))
    elseif len == 2 then
        local t = util_formatCoins(data.p_params[1], 3, nil, nil, nil, true)
        local t1 = util_formatCoins(data.p_params[2], 3, nil, nil, nil, true)
        desc = string.format(desc, tostring(t), tostring(t1))
    elseif len == 3 then
        local t = util_formatCoins(data.p_params[1], 3, nil, nil, nil, true)
        local t1 = util_formatCoins(data.p_params[2], 3, nil, nil, nil, true)
        local t2 = util_formatCoins(data.p_params[3], 3, nil, nil, nil, true)
        desc = string.format(desc, tostring(t), tostring(t1), tostring(t2))
    end
    local m_lb_center = self:findChild("m_lb_center")
    local m_lb_top = self:findChild("m_lb_top")
    local m_lb_bottom = self:findChild("m_lb_bottom")

    local m_lb_center_1 = self:findChild("m_lb_center_1")
    local m_lb_top_1 = self:findChild("m_lb_top_1")
    local m_lb_bottom_1 = self:findChild("m_lb_bottom_1")

    m_lb_center:setVisible(false)
    m_lb_top:setVisible(false)
    m_lb_bottom:setVisible(false)
    m_lb_center_1:setVisible(false)
    m_lb_top_1:setVisible(false)
    m_lb_bottom_1:setVisible(false)
    local strList = util_string_split(desc, ";")
    if strList and #strList == 1 then
        m_lb_center:setVisible(true)
        m_lb_center:setString(strList[1])
        m_lb_center_1:setVisible(true)
        m_lb_center_1:setString(strList[1])
    elseif strList and #strList == 2 then
        m_lb_top:setVisible(true)
        m_lb_bottom:setVisible(true)
        m_lb_top:setString(strList[1])
        m_lb_bottom:setString(strList[2])

        m_lb_top_1:setVisible(true)
        m_lb_bottom_1:setVisible(true)
        m_lb_top_1:setString(strList[1])
        m_lb_bottom_1:setString(strList[2])
    end
    -- self.m_descValue:setString(desc)
    -- util_AutoLine(self.m_descValue,desc,165,true)
    self.m_layerDirction = "left"
    self.m_panelLeft = self:findChild("Panel_1")
    self.m_panelRight = self:findChild("Panel_2")
    self:updatePanelVisible()
end

function QuestTaskTipNode:showTipView(callback)
    self.m_isFore = nil
    self:runCsbAction(
        "show",
        false,
        function()
            if self.m_isFore then
                self:pauseForIndex(70)
                return
            end
            self:runCsbAction("idle", false)
            if callback ~= nil then
                callback()
            end
        end,
        60
    )
end
--修改
function QuestTaskTipNode:hideFore()
    self:stopAllActions()
    self:pauseForIndex(70)
    self.m_isFore = true
end

function QuestTaskTipNode:hideTipView(callback)
    self.m_isFore = nil
    self:runCsbAction(
        "over",
        false,
        function()
            if self.m_isFore then
                self:pauseForIndex(70)
                return
            end
            if callback ~= nil then
                callback()
            end
        end,
        60
    )
end

-- csc 添加
function QuestTaskTipNode:updatePanelVisible()
    if self.m_panelLeft and self.m_panelRight then
        if self.m_layerDirction == "left" then
            self.m_panelLeft:setVisible(true)
            self.m_panelRight:setVisible(false)
        elseif self.m_layerDirction == "right" then
            self.m_panelLeft:setVisible(false)
            self.m_panelRight:setVisible(true)
        end
    end
end

function QuestTaskTipNode:onEnter()
    gLobalNoticManager:addObserver(
        self,
        function(node, direction)
            if direction then
                self.m_layerDirction = direction
                self:updatePanelVisible()
            end
        end,
        ViewEventType.NOTIFY_FRAME_LAYER_CHANGE_STOP_DIRECTION_LEFTFRAME
    )
end

return QuestTaskTipNode
