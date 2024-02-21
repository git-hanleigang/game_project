---
--xcyy
--2018年5月23日
--ThorSlotsNode.lua

local ThorSlotsNode = class("ThorSlotsNode", util_require("Levels.SlotsNode"))
ThorSlotsNode.m_machine = nil

ThorSlotsNode.m_Corn = nil

function ThorSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
    self.m_BonusBgNode = nil
end

function ThorSlotsNode:initMachine(machine)
    self.m_machine = machine
end
---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
--
function ThorSlotsNode:initSlotNodeByCCBName(ccbName, symbolType)
    if symbolType ~= -1 and self.m_actionDatas == nil then -- 表明是滚动的格子
        self.m_actionDatas = {}
    end

    self.m_ccbName = ccbName

    self.p_symbolType = symbolType
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    self.m_symbolClipCanReset = true

    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
    self.m_imageName = imageName
    if imageName == nil then -- 直接添加ccb
        if self.p_symbolImage ~= nil then
            self.p_symbolImage:setVisible(false)
        end
        print("self.p_symbolType ===" .. self.p_symbolType)
        self:checkLoadCCbNode()
    else
        local offsetX = 0
        local offsetY = 0
        local scale = 1
        if tolua.type(imageName) == "table" then
            self.m_imageName = imageName[1]
            if #imageName == 3 then
                offsetX = imageName[2]
                offsetY = imageName[3]
            elseif #imageName == 4 then
                offsetX = imageName[2]
                offsetY = imageName[3]
                scale = imageName[4]
            end
        end
        if self.p_symbolImage == nil then
            self.p_symbolImage = display.newSprite(self.m_imageName)
            self:addChild(self.p_symbolImage)
        else
            self:spriteChangeImage(self.p_symbolImage, self.m_imageName)
        end
        self.p_symbolImage:setPositionX(offsetX)
        self.p_symbolImage:setPositionY(offsetY)
        self.p_symbolImage:setScale(scale)
        self.p_symbolImage:setVisible(true)
    end
    if self.m_machine.m_isOutLine then
        return
    end
    if self.p_symbolType and (self.p_symbolType == self.m_machine.SYMBOL_BONUS_X or self.p_symbolType == self.m_machine.SYMBOL_BONUS_Y or self.p_symbolType == self.m_machine.SYMBOL_BONUS_Z) then
        if self.m_BonusBgNode == nil and self.m_machine then
            if self.p_symbolType == self.m_machine.SYMBOL_BONUS_X then
                self.m_BonusBgNode = self.m_machine:createBonusBg(self.m_machine.SYMBOL_BONUS_X_BG)
            elseif self.p_symbolType == self.m_machine.SYMBOL_BONUS_Y then
                self.m_BonusBgNode = self.m_machine:createBonusBg(self.m_machine.SYMBOL_BONUS_Y_BG)
            elseif self.p_symbolType == self.m_machine.SYMBOL_BONUS_Z then
                self.m_BonusBgNode = self.m_machine:createBonusBg(self.m_machine.SYMBOL_BONUS_Z_BG)
            end
            self.m_machine.m_onceClipNode:addChild(self.m_BonusBgNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE - 10, 10)

            schedule(
                self,
                function()
                    if self.m_BonusBgNode then
                        self.m_BonusBgNode:setVisible(true)
                        self:updateBonusBgNodePos()
                    end
                end,
                0.01
            )
        end
    end
end

function ThorSlotsNode:updateBonusBgNodePos()
    local pos = cc.p(self:getPosition())

    local wordPos = cc.p(self:getParent():convertToWorldSpace(pos))
    local localpos = self.m_machine.m_onceClipNode:convertToNodeSpace(cc.p(wordPos.x, wordPos.y))

    if self.m_BonusBgNode then
        self.m_BonusBgNode:setPosition(localpos)
    end
end

function ThorSlotsNode:playBonusBgBuling()
    if self.m_BonusBgNode then
        self.m_BonusBgNode:playAction(
            "buling",
            false,
            function()
                self:removeBonusBg()
            end
        )
    end
end
function ThorSlotsNode:removeBonusBg()
    if self.m_BonusBgNode then
        self.m_BonusBgNode:removeFromParent()
        self.m_BonusBgNode = nil
    end
end
function ThorSlotsNode:removeSpin()
    if self.m_spin then
        self.m_spin:stopAllActions()
        self.m_spin:removeFromParent()
        self.m_spin = nil
    end  
end

function ThorSlotsNode:reset(removeFlag)
    if self.m_BonusBgNode then
        self.m_BonusBgNode:removeFromParent()
        self.m_BonusBgNode = nil
    end

    if self.m_spin then
        self.m_spin:stopAllActions()
        self.m_spin:removeFromParent()
        self.m_spin = nil
    end  
    self.p_idleIsLoop = false
    self.p_preParent = nil
    self.p_preX = nil
    self.p_preY = nil
    self.p_slotNodeH = 0

    self:setVisible(true)
    self.m_reelTargetX = nil
    self.m_reelTargetY = nil
    self.m_isLastSymbol = nil
    --    self.p_maxRowIndex = nil
    self.m_lineMatrixPos = nil
    self.m_imageName = nil
    self.m_lineAnimName = nil
    self.m_idleAnimName = nil
    self.m_bInLine = true
    self.m_callBackFun = nil
    self.m_bRunEndTarge = false
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE

    self:setScale(1)
    self:setOpacity(255)
    self:setRotation(0)

    if self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(true)
    end
    self:setScale(1)
    local ccbNode = self:getCCBNode()
    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode, self.p_symbolType)
        end
    end

    self.p_symbolType = nil
    self.p_idleIsLoop = false

    self.m_currAnimName = nil
    self.p_reelDownRunAnima = nil
    self.p_reelDownRunAnimaTimes = nil
    -- 清空掉当前的actions
    if self.m_actionDatas ~= nil then
        table_clear(self.m_actionDatas)
    end

    self:hideBigSymbolClip()
end

function ThorSlotsNode:clear()
    self.m_currAnimName = nil
    self.m_actionDatas = nil
    self.p_preParent = nil
    self.m_callBackFun = nil
    if self.m_BonusBgNode then
        self.m_BonusBgNode:removeFromParent()
        self.m_BonusBgNode = nil
    end

    if self.m_spin then
        self.m_spin:stopAllActions()
        self.m_spin:removeFromParent()
        self.m_spin = nil
    end  
    self:unregisterScriptHandler()  -- 卸载掉注册事件
    
    -- 检测释放掉添加进来的动画节点
    local ccbNode = self:getCCBNode()
    if ccbNode ~= nil then
        ccbNode:clear()

        ccbNode:removeAllChildren()

        if ccbNode:getReferenceCount() > 1 then
            ccbNode:release()
        end

        ccbNode:removeFromParent()

    end

    if self.p_symbolImage ~= nil and self.p_symbolImage:getParent() ~= nil then
        self.p_symbolImage:removeFromParent()
    end

    self.p_symbolImage = nil
end
return ThorSlotsNode
