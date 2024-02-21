---
--xcyy
--2018年5月23日
--FourInOneSlotFastNode.lua

local FourInOneSlotFastNode = class("FourInOneSlotFastNode",util_require("Levels.SlotsNode"))



FourInOneSlotFastNode.SYMBOL_ChilliFiesta_SC =	190
FourInOneSlotFastNode.SYMBOL_Charms_Scatter = 290
FourInOneSlotFastNode.SYMBOL_HowlingMoon_SC = 390
FourInOneSlotFastNode.SYMBOL_Pomi_Scatter = 490

function FourInOneSlotFastNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = false
end

---
-- 还原到初始被创建的状态
function FourInOneSlotFastNode:reset(removeFlag)
    self.p_idleIsLoop = false
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
                globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,self.p_symbolType)
            end
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

---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function FourInOneSlotFastNode:initSlotNodeByCCBName(ccbName,symbolType)
    --    if ccbName == nil then
    --        printInfo("xcyy : --ccbName %s", ccbName)
    --    end
    self.m_lastImageName = self.m_imageName
    if symbolType ~= -1 and self.m_actionDatas == nil then  -- 表明是滚动的格子
        self.m_actionDatas = {}
    end
    
    self.m_ccbName = ccbName

    self.p_symbolType = symbolType
    self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
    self.m_symbolClipCanReset = true

    if self.p_symbolType then

        if self.p_symbolType == self.SYMBOL_ChilliFiesta_SC or
            self.p_symbolType == self.SYMBOL_Charms_Scatter or
            self.p_symbolType == self.SYMBOL_HowlingMoon_SC or
            self.p_symbolType == self.SYMBOL_Pomi_Scatter then

                self.p_idleIsLoop = false
        else
                self.p_idleIsLoop = false
        end

        
    end
    
    local imageName = self.m_machine.m_configData:getSymbolImageByCCBName(ccbName)
    if imageName  == nil then
        ccbName = "Socre_" .. ccbName 
        imageName = self.m_machine.m_configData:getSymbolImageByCCBName(ccbName)
    end

    self.m_imageName = imageName
    if imageName == nil then  -- 直接添加ccb
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
            -- self.p_symbolImage:setScale(0.5)
        else
            self:spriteChangeImage(self.p_symbolImage,self.m_imageName)
        end
        self.p_symbolImage:setPositionX(offsetX)
        self.p_symbolImage:setPositionY(offsetY)
        self.p_symbolImage:setScale(0.5 * scale)
        self.p_symbolImage:setVisible(true)
    end
end

function FourInOneSlotFastNode:setMachine(machine )
    self.m_machine = machine
end

return FourInOneSlotFastNode