--
--
-- 游戏中 spin 按钮
local AutoSpinChooseNode = class("AutoSpinChooseNode", util_require("base.BaseView"))
function AutoSpinChooseNode:initUI(list, func)
    local csbName = "Game/autoChooseNode.csb"
    self:createCsbNode(csbName)
    self:setPositionY(0)
    if globalData.slotRunData.isPortrait == true then
        self:setPositionY(20)
    end
    self.m_func = func
    self.m_sp_list = {}
    if not list or #list ~= 5 then
        list = {10, 25, 50, 100, 500}
    end
    self.m_num_list = list
    for i = 1, 5 do
        local node = self:findChild("node" .. i)
        local touch = self:findChild("touch" .. i)
        self:addClick(touch)
        local sp_click1 = node:getChildByName("sp_click1")
        local sp_click2 = node:getChildByName("sp_click2")
        local m_lb_num = node:getChildByName("m_lb_num")
        m_lb_num:setString(list[i])
        sp_click1:setVisible(true)
        sp_click2:setVisible(false)
        self.m_sp_list[i] = {sp_click1, sp_click2}
    end
end

function AutoSpinChooseNode:onEnter()
    if not self.m_touchLayer then
        self.m_touchLayer = util_newMaskLayer()
        self.m_touchLayer:setOpacity(0)
        self:addChild(self.m_touchLayer, -1)
        self.m_touchLayer:setVisible(false)
        self.m_touchLayer:onTouch(
            function(event)
                --如果正在显示隐藏
                if self.m_status == self.SHOW_IDLE then
                    if event.name == "ended" then
                        if self.m_func then
                            self.m_func(0)
                        end
                    end
                end
                return true
            end,
            false,
            true
        )
        self.m_touchLayer:setTouchEnabled(false)
    end

    gLobalNoticManager:addObserver(
        self,
        function(target, params)
            if params ~= nil and params.isShow ~= nil then
                if params.isShow == true then
                    self:show()
                elseif params.isShow == false then
                    self:hide()
                end
            end
        end,
        ViewEventType.AUTO_SPIN_CHOOSE_SET_VISIBLE
    )
end

function AutoSpinChooseNode:onExit()
    if self.m_touchLayer then
        self.m_touchLayer:setVisible(false)
        self.m_touchLayer:setTouchEnabled(false)
        self.m_touchLayer:removeFromParent()
        self.m_touchLayer = nil
    end
end

function AutoSpinChooseNode:show()
    if not self:isVisible() then
        self:setVisible(true)
        gLobalActivityManager:changeBubbleGZorder(self:getParent(), 1, true)
        self:runCsbAction(
            "show",
            false,
            function()
                if self.m_touchLayer and self:isVisible() then
                    self.m_touchLayer:setVisible(true)
                    self.m_touchLayer:setTouchEnabled(true)
                end
            end
        )
    end
end

function AutoSpinChooseNode:hide()
    self:setVisible(false)
    gLobalActivityManager:changeBubbleGZorder(self:getParent(), 0, true)
    if self.m_touchLayer then
        self.m_touchLayer:setVisible(false)
        self.m_touchLayer:setTouchEnabled(false)
    end
end

--点击监听
function AutoSpinChooseNode:clickStartFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    for i = 1, 5 do
        if name == "touch" .. i then
            self.m_sp_list[i][1]:setVisible(false)
            self.m_sp_list[i][2]:setVisible(true)
            break
        end
    end
end
--结束监听
function AutoSpinChooseNode:clickEndFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    for i = 1, 5 do
        if name == "touch" .. i then
            self.m_sp_list[i][1]:setVisible(true)
            self.m_sp_list[i][2]:setVisible(false)
        end
    end
end
function AutoSpinChooseNode:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    for i = 1, 5 do
        if name == "touch" .. i then
            if self.m_func then
                self.m_func(self.m_num_list[i])
            end
            break
        end
    end
end
return AutoSpinChooseNode
