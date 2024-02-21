--[[
    创建一个触摸层,来实现节点拖拽功能
]]
local DragFrameLayerV2 = class("DragFrameLayerV2", util_require("views.leftFrame.DragFrameLayer"))

function DragFrameLayerV2:initUI(parent)
    self.m_isTouch = false
    DragFrameLayerV2.super.initUI(self, parent)
    local beganPosition, endPosition, dispos
    self.layer:onTouch(
        function(event)
            if self.m_isTouch then
                return
            end
            if event.name == "began" then
                beganPosition = cc.p(event.x, event.y)
                local parentPos = cc.p(parent:getPosition())
                dispos = cc.pSub(beganPosition, parentPos)

                local oldZorder = GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 5
                if self.parent.getOldZOrder then
                    oldZorder = self.parent:getOldZOrder()
                end
                self.parent:setZOrder(oldZorder + 1)
                if table.nums(self.m_rect) == 0 or (table.nums(self.m_rect) > 0 and cc.rectContainsPoint(self.m_rect, dispos) == false) then
                    -- print("--- DragFrameLayerV2 没在指定区域点击")
                    self.parent:setZOrder(oldZorder)
                    return false
                end

                return true
            elseif event.name == "moved" then
                -- print("======= 输出 newPos x = "..newPos.x.." newPos y = "..newPos.y)
                -- end
                -- print("--- DragFrameLayerV2 moved")
                endPosition = cc.p(event.x, event.y)
                local offx = math.abs(endPosition.x - beganPosition.x)
                local offy = math.abs(endPosition.y - beganPosition.y)
                local newPos = cc.pSub(endPosition, dispos)
                if self.m_bmove then
                    self.parent:setPosition(newPos)
                end
                if offx >= 25 and offy <= 25 then
                    self.m_bmove = true
                    self.parent:changePanleSwallow(true)
                    -- print("--- DragFrameLayerV2 不允许穿透！！！！")
                end
                if not self.m_isOnceMove then
                    self.m_isOnceMove = true
                    self.parent:hideAllPushViews()
                end
            elseif event.name == "ended" then
                endPosition = cc.p(event.x, event.y)
                local newPos = cc.pSub(endPosition, dispos)

                local offx = math.abs(endPosition.x - beganPosition.x)
                local offy = math.abs(endPosition.y - beganPosition.y)
                if offx >= 25 or offy >= 25 then
                    self.parent:changePanleSwallow(true, true)
                    -- print("--- DragFrameLayerV2 不允许穿透！！！！")
                else
                    self.parent:changePanleSwallow(false)
                    -- print("--- DragFrameLayerV2 允许穿透！！！！")
                end
                -- self.parent:changePanleSwallow(false)
                if self.m_bmove then
                    self:caculateLayerPosInfo()
                    self:updatePosition(newPos)
                end
                self.m_bmove = false
                self.m_isOnceMove = false
            end

            return true
        end,
        false,
        false
    )
end

function DragFrameLayerV2:setIsTouch(_isTouch)
    self.m_isTouch = _isTouch
end

return DragFrameLayerV2