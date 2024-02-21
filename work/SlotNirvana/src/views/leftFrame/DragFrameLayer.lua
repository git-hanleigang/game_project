--[[
    创建一个触摸层,来实现节点拖拽功能
]]
local DragFrameLayer = class("DragFrameLayer", util_require("base.BaseView"))

--[[
    传入模块的ui方向信息
    left_top  ui是从左上角向下排列
    right_top ui是从右上角向下排列
    center ui是从中间向上下排表
    left_down ui是从左下角向上排列
    right_down ui是从右下角向上排列
]]
DragFrameLayer.DIRECTION = {
    LEFT_TOP = "left_top",
    RIGHT_TOP = "right_top",
    CENTER = "center",
    LEFT_DOWN = "left_down",
    RIGHT_DOWN = "right_down"
}

DragFrameLayer.STOPDIRECTION = {
    LEFT = 0,
    RIGHT = 1,
    TOP = 2,
    DOWN = 3
}

function DragFrameLayer:initUI(parent)
    if self.m_rect == nil then
        self.m_rect = {}
    end

    self.layer = cc.LayerColor:create(cc.c3b(250, 0, 0))
    self.layer:setOpacity(0)
    local beganPosition, endPosition, dispos
    self.layer:onTouch(
        function(event)
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
                    print("--- DragFrameLayer 没在指定区域点击")
                    self.parent:setZOrder(oldZorder)
                    return false
                end

                return true
            elseif event.name == "moved" then
                -- print("======= 输出 newPos x = "..newPos.x.." newPos y = "..newPos.y)
                -- end
                -- print("--- DragFrameLayer moved")
                endPosition = cc.p(event.x, event.y)
                local newPos = cc.pSub(endPosition, dispos)
                self.parent:setPosition(newPos)

                local offx = math.abs(endPosition.x - beganPosition.x)
                local offy = math.abs(endPosition.y - beganPosition.y)
                if offx >= 25 or offy >= 25 then
                    self.m_bmove = true
                end
            elseif event.name == "ended" then
                endPosition = cc.p(event.x, event.y)
                local newPos = cc.pSub(endPosition, dispos)

                local offx = math.abs(endPosition.x - beganPosition.x)
                local offy = math.abs(endPosition.y - beganPosition.y)
                if offx >= 25 or offy >= 25 then
                    self.parent:changePanleSwallow(true)
                    print("--- DragFrameLayer 不允许穿透！！！！")
                else
                    self.parent:changePanleSwallow(false)
                    print("--- DragFrameLayer 允许穿透！！！！")
                end
                -- self.parent:changePanleSwallow(false)

                if self.m_bmove then
                    if gLobalDataManager:getBoolByField("leftFrameGuide", false) == false then
                        gLobalDataManager:setBoolByField("leftFrameGuide", true) --
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_FRAME_LAYER_GUIDE_REMOVE)
                    end
                    self.m_bmove = nil
                end
                self:caculateLayerPosInfo()
                self:updatePosition(newPos)
            end

            return true
        end,
        false,
        false
    )
    self:addChild(self.layer)

    self.parent = parent
    self.m_lastDirection = "left"
end

function DragFrameLayer:setLayerRect(pos, layersize)
    self.m_rect.x = pos.x
    self.m_rect.y = pos.y
    self.m_rect.width = layersize.width
    self.m_rect.height = layersize.height
end

function DragFrameLayer:updateSize(layersize, direction)
    self.layer:setContentSize({width = layersize.width, height = layersize.height})
    self.m_direction = direction
end

function DragFrameLayer:updatePosition(pos)
    --[[
        ①
        当松手时候自动吸附的离的近的一侧（以图标的中心点处于中线左侧还是右侧来判断）
        ②
        globalData.gameRealViewsSize 决定了当前的可拖动区域
        一旦当前拖拽条的上部超过了高度，默认停留在最上方
        同理下部超过了底边距离 需要停靠在距离底部 + 节点长度 的位置上
    ]]
    -- 1.
    local endPos = cc.p(0, pos.y)
    local offset = 15
    if self.parent.getLayerDis then
        offset = self.parent:getLayerDis()
    end
    local topOffset = 0
    local downOffset = 20
    local direct = "left"
    -- 这里要判断下刘海屏的情况
    if globalData.slotRunData.isPortrait == false then
        offset = offset + util_getBangScreenHeight()
    end

    if RotateScreen:getInstance():isRotated() then
        return
    end

    if self.m_CenterPos.x < display.width / 2 then
        endPos.x = 0 + self:getXOffset(self.STOPDIRECTION.LEFT) + offset
        direct = "left"
    elseif self.m_CenterPos.x >= display.width / 2 then
        endPos.x = display.width - self:getXOffset(self.STOPDIRECTION.RIGHT) - offset
        direct = "right"
    end

    -- 2.判断上下 是否超过规定界限
    local topLimit = display.height - globalData.gameRealViewsSize.topUIHeight
    local downLimit = globalData.gameRealViewsSize.bottomUIHeight
    self.m_bOverStep = true
    if self.m_TopPos.y >= topLimit then
        endPos.y = self:getYOffset(self.STOPDIRECTION.TOP, topOffset)
    elseif self.m_DownPos.y <= downLimit then
        endPos.y = self:getYOffset(self.STOPDIRECTION.DOWN, downOffset)
    else
        self.m_bOverStep = false
    end

    -- print("000000 ---- endPos - " ..endPos.x.."   ----- y - "..endPos.y)
    local moveTo = cc.MoveTo:create(0.2, endPos)
    self.parent:runAction(moveTo)
    self.dragFrameFlag = false
    self.parent:updateMoveEndPos(endPos)

    -- 一旦发现变化 就发送一次通知
    if self.m_lastDirection ~= direct then
        self.m_lastDirection = direct
        self.parent:changeStopDirection(direct)
    end
end

--[[
    实时更新
    根据当前的ui方向信息，计算出 top down 的坐标值
]]
function DragFrameLayer:caculateLayerPosInfo(pLayerSize)
    local top = cc.p(0, 0)
    local down = cc.p(0, 0)
    local center = cc.p(0, 0)
    local parentPos = cc.p(self.parent:getPosition())
    local layerSize = self.layer:getContentSize()
    if pLayerSize then
        layerSize = pLayerSize
    end

    if self.m_direction == self.DIRECTION.LEFT_TOP then
        top = cc.p(parentPos.x, parentPos.y)
        down = cc.p(parentPos.x, parentPos.y - layerSize.height)
        center = cc.p(parentPos.x + layerSize.width / 2, parentPos.y - layerSize.height / 2)
    elseif self.m_direction == self.DIRECTION.RIGHT_TOP then
        top = cc.p(parentPos.x, parentPos.y)
        down = cc.p(parentPos.x, parentPos.y - layerSize.height)
        center = cc.p(parentPos.x - layerSize.width / 2, parentPos.y - layerSize.height / 2)
    elseif self.m_direction == self.DIRECTION.CENTER then
        top = cc.p(parentPos.x, parentPos.y + layerSize.height / 2)
        down = cc.p(parentPos.x, parentPos.y - layerSize.height / 2)
        center = parentPos
    elseif self.m_direction == self.DIRECTION.LEFT_DOWN then
        top = cc.p(parentPos.x, parentPos.y + layerSize.height)
        down = cc.p(parentPos.x, parentPos.y)
        center = cc.p(parentPos.x + layerSize.width / 2, parentPos.y + layerSize.height / 2)
    elseif self.m_direction == self.DIRECTION.RIGHT_DOWN then
        top = cc.p(parentPos.x, parentPos.y + layerSize.height)
        down = cc.p(parentPos.x, parentPos.y)
        center = cc.p(parentPos.x - layerSize.width / 2, parentPos.y + layerSize.height / 2)
    end

    self.m_TopPos = top
    self.m_DownPos = down
    self.m_CenterPos = center

    --     print("======= 输出 top x = "..top.x.." top y = "..top.y)
    --     print("======= 输出 down x = "..down.x.." down y = "..down.y)
    --     print("======= 输出 center x = "..center.x.." center y = "..center.y)
end

function DragFrameLayer:checkOpenProgress(param)
    if param == nil then
        return
    end

    local checkPos = cc.p(param.node:getPosition())
    -- local newPos = cc.pSub(endPosition , dispos)

    -- print("======= 输出 checkPos x = "..checkPos.x.." checkPos y = "..checkPos.y)
    self:caculateLayerPosInfo(param.layerSize)
    self:updatePosition(checkPos)

    if param.newEntryNode then
        checkPos = nil
    end

    if self.m_bOverStep then
        -- 将原坐标传回去
        self.parent:checkOpenProgressResult(checkPos)
    end
end
-- 获取不同ui起始点下的横坐标补充量
function DragFrameLayer:getXOffset(direct)
    local layerSize = self.layer:getContentSize()
    local xOffset = 0
    if direct == self.STOPDIRECTION.LEFT then
        if self.m_direction == self.DIRECTION.LEFT_TOP or self.m_direction == self.DIRECTION.LEFT_DOWN then
            xOffset = 0
        elseif self.m_direction == self.DIRECTION.RIGHT_TOP or self.m_direction == self.DIRECTION.RIGHT_DOWN then
            xOffset = xOffset + layerSize.width
        end
    else
        if self.m_direction == self.DIRECTION.LEFT_TOP or self.m_direction == self.DIRECTION.LEFT_DOWN then
            xOffset = xOffset + layerSize.width
        elseif self.m_direction == self.DIRECTION.RIGHT_TOP or self.m_direction == self.DIRECTION.RIGHT_DOWN then
            xOffset = xOffset + 0
        end
    end

    if self.m_direction == self.DIRECTION.CENTER then
        xOffset = xOffset + layerSize.width / 2
    end

    return xOffset
end

function DragFrameLayer:getYOffset(direct, offset)
    local layerSize = self.layer:getContentSize()
    local yOffset = 0

    if direct == self.STOPDIRECTION.TOP then
        if self.m_direction == self.DIRECTION.LEFT_TOP or self.m_direction == self.DIRECTION.RIGHT_TOP then
            yOffset = display.height - globalData.gameRealViewsSize.topUIHeight - offset
        elseif self.m_direction == self.DIRECTION.LEFT_DOWN or self.m_direction == self.DIRECTION.RIGHT_DOWN then
            yOffset = display.height - layerSize.height - globalData.gameRealViewsSize.topUIHeight - offset
        elseif self.m_direction == self.DIRECTION.CENTER then
            yOffset = display.height - globalData.gameRealViewsSize.topUIHeight - layerSize.height / 2 - offset
        end
    else
        if self.m_direction == self.DIRECTION.LEFT_TOP or self.m_direction == self.DIRECTION.RIGHT_TOP then
            yOffset = layerSize.height + globalData.gameRealViewsSize.bottomUIHeight + offset
        elseif self.m_direction == self.DIRECTION.LEFT_DOWN or self.m_direction == self.DIRECTION.RIGHT_DOWN then
            yOffset = globalData.gameRealViewsSize.bottomUIHeight + offset
        elseif self.m_direction == self.DIRECTION.CENTER then
            yOffset = globalData.gameRealViewsSize.bottomUIHeight + layerSize.height / 2 + offset
        end
    end
    return yOffset
end

function DragFrameLayer:onEnter()
end

function DragFrameLayer:onExit()
end

return DragFrameLayer
