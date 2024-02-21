---
--xcyy
--2018年5月23日
--OZSlotFastNode.lua

local OZSlotFastNode = class("OZSlotFastNode",util_require("Levels.SlotsNode"))
---
-- 还原到初始被创建的状态
function OZSlotFastNode:reset(removeFlag)
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
function OZSlotFastNode:initSlotNodeByCCBName(ccbName,symbolType)
    --    if ccbName == nil then
    --        printInfo("xcyy : --ccbName %s", ccbName)
    --    end
     
        if symbolType ~= -1 and self.m_actionDatas == nil then  -- 表明是滚动的格子
            self.m_actionDatas = {}
        end
        
        self.m_ccbName = ccbName
    
        self.p_symbolType = symbolType
        self.p_layerTag = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE
        self.m_symbolClipCanReset = true
        
        local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
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
            else
                self:spriteChangeImage(self.p_symbolImage,self.m_imageName)
            end
            self.p_symbolImage:setPositionX(offsetX)
            self.p_symbolImage:setPositionY(offsetY)
            self.p_symbolImage:setVisible(true)
            self.p_symbolImage:setScale(scale)
            -- if self.p_symbolType then

            --     if self.p_symbolType == 90 or self.p_symbolType == 93 or self.p_symbolType == 95 or
            --         self.p_symbolType == 0 or self.p_symbolType == 1 or
            --           self.p_symbolType == 2 or self.p_symbolType == 3 then

            --         self.p_symbolImage:setScale(0.5)
            --     else
            --         self.p_symbolImage:setScale(1)
            --     end
                
            -- end
            
            
        end
end

return OZSlotFastNode