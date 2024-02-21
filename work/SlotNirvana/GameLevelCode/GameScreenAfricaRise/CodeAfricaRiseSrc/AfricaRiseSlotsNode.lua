---
--xcyy
--2018年5月23日
--AfricaRiseSlotsNode.lua

local AfricaRiseSlotsNode = class("AfricaRiseSlotsNode", util_require("Levels.SlotsNode"))
AfricaRiseSlotsNode.m_machine = nil

AfricaRiseSlotsNode.m_icon = nil

function AfricaRiseSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
    self.p_isPlayRunLine = false
end

function AfricaRiseSlotsNode:initMachine(machine)
    self.m_machine = machine
end

function AfricaRiseSlotsNode:initSlotNodeByCCBName(ccbName, symbolType)
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
end

function AfricaRiseSlotsNode:changeImage()
    if self.m_ccbName then
        local ccbName = self.m_ccbName .. 1
        local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
        self.m_imageName = imageName
        if imageName == nil then -- 直接添加ccb
            if self.p_symbolImage ~= nil then
                self.p_symbolImage:setVisible(false)
            end

            self:checkLoadCCbNode()
            self:runAnim("idleframe")
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
    end
end

function AfricaRiseSlotsNode:spriteChangeImage(sprite, imageName)
    if sprite == nil then
        return
    end

    local frame = display.newSpriteFrame(imageName)
    if frame then
        sprite:setSpriteFrame(frame)
    end
end

function AfricaRiseSlotsNode:reset(removeFlag)
    if self.m_icon then
        self.m_icon:stopAllActions()
        self.m_icon:removeFromParent()
        self.m_icon = nil
    end
    self.p_isPlayRunLine = false
    self.p_idleIsLoop = true
    self.p_preParent = nil
    self.p_preX = nil
    self.p_preY = nil
    self.p_slotNodeH = 0

    self:setVisible(true)
    self.m_reelTargetX = nil
    self.m_reelTargetY = nil
    self.m_isLastSymbol = nil
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
        if removeFlag then
            ccbNode:release()
        else
            -- 放回到池里面去
            if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
                globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode, self.p_symbolType)
            end
        end
    end

    self.p_symbolType = nil
    self.p_idleIsLoop = true
    self.m_currAnimName = nil
    self.p_reelDownRunAnima = nil
    self.p_reelDownRunAnimaTimes = nil

    -- 清空掉当前的actions
    if self.m_actionDatas ~= nil then
        table_clear(self.m_actionDatas)
    end

    self:hideBigSymbolClip()
end

function AfricaRiseSlotsNode:runAnim(animName, loop, func)
    local ccbNode = self:checkLoadCCbNode()
    if ccbNode ~= nil and self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(false)
    end
    -- if  self.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER or self.p_symbolType == 201 then
    --     local name = animName
    --     print("SYMBOL_SCATTER AfricaRiseSlotsNode animName=== " .. animName)
    -- end
    local isPlay = ccbNode:runAnim(animName, loop, func)
    if self.p_symbolType <= TAG_SYMBOL_TYPE.SYMBOL_SCORE_1 and self.p_symbolType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_4 then
        local node = ccbNode.m_csbNode
        if node then
            local node1 = node:getChildByName("Score_img_0")
            local lan = node1:getChildByName("Score_lan")
            local zi = node1:getChildByName("Score_zi")
            if zi and lan then
                if globalData.slotRunData.currSpinMode == FREE_SPIN_MODE then
                    lan:setVisible(false)
                    zi:setVisible(true)
                else
                    lan:setVisible(true)
                    zi:setVisible(false)
                end
            end
        end
    end
    if isPlay == true then
        self.m_slotAnimaLoop = loop
        self.m_currAnimName = animName

        if self.m_animaCallBackFun ~= nil then
            self.m_animaCallBackFun(self)
        end
    end
end
return AfricaRiseSlotsNode
