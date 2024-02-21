---
--xcyy
--2018年5月23日
--DiscoFeverSlotsNode.lua

local DiscoFeverSlotsNode = class("DiscoFeverSlotsNode",util_require("Levels.SlotsNode"))
DiscoFeverSlotsNode.m_machine = nil
DiscoFeverSlotsNode.m_ScatterBgNode = nil
DiscoFeverSlotsNode.m_num = 0

function DiscoFeverSlotsNode:initMachine(machine )
    self.m_machine = machine
end

function DiscoFeverSlotsNode:updateScatterBgNodePos( )
    local pos = cc.p(self:getPosition())
    self.m_num = self.m_num +1
   

    local wordPos = cc.p(self:getParent():convertToWorldSpace(pos))
    local localpos = self.m_machine.m_onceClipNode:convertToNodeSpace(cc.p(wordPos.x, wordPos.y))
    
    if self.m_ScatterBgNode then
        self.m_ScatterBgNode:setPosition(localpos)
    end
end

function DiscoFeverSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end


---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function DiscoFeverSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
 
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
        if tolua.type(imageName) == "table" then
            self.m_imageName = imageName[1]
            if #imageName == 3 then
                offsetX = imageName[2]
                offsetY = imageName[3]
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
    end

    if self.p_symbolType and 
            (self.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER 
                or self.p_symbolType == 96 
                    or self.p_symbolType == 97) then

        if self.m_ScatterBgNode == nil and self.m_machine then
            local csbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_machine.SYMBOL_JpUp_BG)
            if self.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_SCATTER then
                csbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_machine.SYMBOL_SCATTER_BG)  
            end

            self.m_ScatterBgNode = util_createAnimation(csbName..".csb") 
            self.m_machine.m_onceClipNode:addChild(self.m_ScatterBgNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE - 10,10)
            -- self.m_ScatterBgNode:setScale(3)

            self.m_ScatterBgNode:playAction("animation0",true,nil,20)
            self.m_ScatterBgNode:setVisible(false)

            schedule(self.m_ScatterBgNode,function()
                self.m_ScatterBgNode:setVisible(true)
                    self:updateScatterBgNodePos()
            end,0.00001)

            -- self.m_scatterBgHandlerId =  scheduler.scheduleGlobal(
            --     function(dt)
                    
            --     end,
            --     0
            -- )
        end
        
    end

    
end

---
-- 还原到初始被创建的状态
function DiscoFeverSlotsNode:reset()


    if self.m_scatterBgHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_scatterBgHandlerId)
        self.m_scatterBgHandlerId = nil
    end

    if self.m_ScatterBgNode then
        self.m_ScatterBgNode:removeFromParent()
        
        self.m_ScatterBgNode = nil
    end
    

    self.p_idleIsLoop = true
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

function DiscoFeverSlotsNode:runIdleAnim()
    if self.p_idleIsLoop == nil then
        self.p_idleIsLoop = false
    end

    local csbNode = self:getCCBNode()
    -- if csbNode ~= nil then  -- 不用图片代替时才会直接播放默认动画
        self:runAnim(self:getIdleAnimName(),self.p_idleIsLoop)
    -- end

    self:changeScatterBgNodeImgColler(self:getIdleAnimName() )
    
    
end

---
-- 运行节点动画
-- @param animName string 节点里面动画名字

function DiscoFeverSlotsNode:runAnim(animName,loop,func)

    local ccbNode = self:checkLoadCCbNode()
    if ccbNode ~= nil and self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(false)
    end

    local isPlay = ccbNode:runAnim(animName,loop,func)

    if isPlay == true then
        self.m_slotAnimaLoop = loop
        self.m_currAnimName = animName

        if self.m_animaCallBackFun ~= nil then
            self.m_animaCallBackFun(self)
        end

        self:changeScatterBgNodeImgColler(animName )

    end
    
end

function DiscoFeverSlotsNode:changeScatterBgNodeImgColler(name )
    if name then

        if self.m_ScatterBgNode then

            for i=1,4 do
                local image =  self.m_ScatterBgNode:findChild("scatte_guangquan_"..i)
                if image then
                    if name == "DarkAct" then
                        image:setColor(cc.c3b(70,70,70))
                    else
                        image:setColor(cc.c3b(255,255,255))
                    end
                end
            end
            
         end
    end
    
end



return DiscoFeverSlotsNode