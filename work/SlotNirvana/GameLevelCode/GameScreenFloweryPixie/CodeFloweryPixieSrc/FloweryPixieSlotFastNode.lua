---
--xcyy
--2018年5月23日
--FloweryPixieSlotFastNode.lua

local FloweryPixieSlotFastNode = class("FloweryPixieSlotFastNode",util_require("Levels.SlotsNode"))


---
--
function FloweryPixieSlotFastNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = false
end

function FloweryPixieSlotFastNode:setMachine(machine )
    self.m_machine = machine
end


---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function FloweryPixieSlotFastNode:initSlotNodeByCCBName(ccbName,symbolType)
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
    
    if self.p_symbolType and self.m_machine then
        if self.p_symbolType == self.m_machine.SYMBOL_SCATTER_GLOD  then
  
            ccbName = "Socre_FloweryPixie_scatter2"

        elseif self.p_symbolType == self.m_machine.SYMBOL_SCATTER_WILD  then

            ccbName = "Socre_FloweryPixie_wild2"
            
        end
    end
    

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
        self.p_symbolImage:setScale(scale)
        self.p_symbolImage:setVisible(true)
    end
end

---
-- 运行节点动画
-- @param animName string 节点里面动画名字

function FloweryPixieSlotFastNode:runAnim(animName,loop,func)

    local ccbNode = self:checkLoadCCbNode()
    if ccbNode ~= nil and self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(false)
    end

    
    

    if self.p_symbolType and self.m_machine then

        if self.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER   then

            if animName == "idleframe" then
                loop = true
            end

        elseif self.p_symbolType == self.m_machine.SYMBOL_SCATTER_GLOD  then

            if animName == "idleframe" then
                loop = true
            end

            if animName == "actionframe" or animName == "idleframe" or animName == "buling" then
                animName = animName .. "2"
            end
                
            
     
        elseif self.p_symbolType == self.m_machine.SYMBOL_SCATTER_WILD  then

            if animName == "actionframe" or animName == "idleframe" then
                animName = animName .. "2"
            end
        end
    end
  
      

    local isPlay = ccbNode:runAnim(animName,loop,func)

    if isPlay == true then
        self.m_slotAnimaLoop = loop
        self.m_currAnimName = animName

        if self.m_animaCallBackFun ~= nil then
            self.m_animaCallBackFun(self)
        end

    end
    
end

---
-- 还原到初始被创建的状态
function FloweryPixieSlotFastNode:reset()

    if self.bonusLab then
        self.bonusLab:stopAllActions()
        self.bonusLab:removeFromParent()
        self.bonusLab = nil
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
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,self.p_symbolType)
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

-- 切换ccb的动画名字在其它特定关卡使用
function FloweryPixieSlotFastNode:changeCCBByName(ccbName,symbolType)
    -- if ccbName == self.m_ccbName then 
    --     return 
    -- end
    
    self:removeAndPushCcbToPool()
    
    self.p_symbolType = symbolType
    self.m_ccbName = ccbName


    self:checkLoadCCbNode()
end

function FloweryPixieSlotFastNode:changeSymbolImage(ccbName )
    
    if self.p_symbolType and self.m_machine then
        if self.p_symbolType == self.m_machine.SYMBOL_SCATTER_GLOD  then
  
            ccbName = "Socre_FloweryPixie_scatter2"

        elseif self.p_symbolType == self.m_machine.SYMBOL_SCATTER_WILD  then

            ccbName = "Socre_FloweryPixie_wild2"
            
        end
    end

    local imageName = self.m_machine.m_configData:getSymbolImageByCCBName(ccbName)
    self.m_imageName = imageName
    if imageName == nil then  -- 直接添加ccb

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
        self.p_symbolImage:setScale(scale)
        self.p_symbolImage:setVisible(true)
    end
    self.p_symbolImage:setVisible(false)
end

---
--node所在列滚动停止之后播放的动画
function FloweryPixieSlotFastNode:playReelDownAnima()
    if self.p_reelDownRunAnima == nil then
        return
    end
    local ccbNode = self:checkLoadCCbNode()
    ccbNode:runAnim(self.p_reelDownRunAnima,false,function(  )
        if self then
            self:runAnim("idleframe")
        end
        
    end)
end

return FloweryPixieSlotFastNode