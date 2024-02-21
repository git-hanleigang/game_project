--第一次进入游戏新手引导
local FirstWheelLayer = class("FirstWheelLayer", BaseLayer)
FirstWheelLayer.m_baseNode = nil
FirstWheelLayer.m_npc = nil
local FIRST_GAME_ID = 10031


function FirstWheelLayer:initDatas()
    self:setLandscapeCsbName("GuideNewUser/NewUserFirstLayer.csb")
    self:setShowActionEnabled(false)
    self:setHideActionEnabled(false)
    self:setShowBgOpacity(0)
    self:setMaskEnabled(false)
end

function FirstWheelLayer:initGuide(index)
    for i = 1, 3 do
        local baseNode = self:findChild("Node_" .. i)
        if baseNode then
            if i == index then
                baseNode:setVisible(true)
                self.m_baseNode = baseNode
                -- local _node_0 = self.m_baseNode:getChildByName("Node_" .. i .. "_0")
                local _node_0 = self:findChild("Node_" .. i .. "_0")
                if _node_0 then
                    _node_0:setVisible(true)
                    local node_npc = _node_0:getChildByName("zhichaoren")
                    if node_npc then
                        self.m_npc = util_createView("views.newbieTask.GuideNpcNode")
                        node_npc:addChild(self.m_npc)
                        -- util_setCascadeOpacityEnabledRescursion(node_npc, true)
                        self.m_npc:showIdle(1)
                    end
                end
            else
                baseNode:setVisible(false)
                local _node_0 = self:findChild("Node_" .. i .. "_0")
                if _node_0 then
                    _node_0:setVisible(false)
                end
            end
        end
    end
end

function FirstWheelLayer:initView()
    self:initGuide(2)
    -- local scale = self:getUIScalePro()
    -- self:setPosition(display.cx+(0-876*0.5)*scale,(170)/scale)
    gLobalSoundManager:playSound("Sounds/guide_move_pop.mp3")
    self:runCsbAction(
        "start",
        false,
        function()
            if self.showNpc then
                self:showNpc()
            end
        end,
        30
    )
end

function FirstWheelLayer:showNpc()
    self:runCsbAction(
        "start2",
        false,
        function()
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CHANGE_CASHWHEEL_ZORDER, true)
        end,
        30
    )
end

-- function FirstWheelLayer:onKeyBack()
-- end

function FirstWheelLayer:onEnter()
    FirstWheelLayer.super.onEnter(self)
    gLobalNoticManager:addObserver(
        self,
        function(self, params)
            if not params then
                self:closeUI()
            end
        end,
        ViewEventType.NOTIFY_CHANGE_CASHWHEEL_ZORDER
    )
end

return FirstWheelLayer
