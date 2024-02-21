---
--island
--2017年8月28日
--SlotsNode.lua
--

local SlotsNode = class("SlotsNode",util_require("reels.ReelGridNode"))
SlotsNode.p_preSymbolType = nil -- 原来的类型， 主要是slotomania 或者 house fun的原始类型
SlotsNode.p_symbolImage = nil -- 滚动时的图片
SlotsNode.p_symbolType = nil  -- 信号类型
SlotsNode.p_layerTag = nil -- node 所属的图形层级
 
SlotsNode.p_cloumnIndex = nil -- node 所在行 列 
SlotsNode.p_rowIndex = nil --  
--SlotsNode.p_maxRowIndex = nil -- 大信号影响到的最大行号，在创建下一个格子时用此来处理 
SlotsNode.m_imageName = nil 
SlotsNode.m_currAnimName = nil
SlotsNode.m_lineAnimName = nil -- 连线时播放的动画名字
SlotsNode.m_idleAnimName = nil -- 默认时间线名字

SlotsNode.m_isLastSymbol = nil -- 
SlotsNode.m_reelTargetX = nil -- 滚动到的目标点
SlotsNode.m_reelTargetY = nil --   
SlotsNode.m_ccbName = nil     --
SlotsNode.m_bInLine = nil     -- 是否参与连线计算
SlotsNode.m_lineMatrixPos = nil --参与计算的坐标
SlotsNode.m_actionDatas = nil -- action 数据
SlotsNode.m_bRunEndTarge = nil --是否移动到目标位置 不算回弹 回弹之前

SlotsNode.p_reelDownRunAnima = nil --node所在列滚动停止播放的动画
SlotsNode.p_reelDownRunAnimaTimes = nil --node所在列滚动停止播放的动画
SlotsNode.p_showOrder = nil -- 显示在列表中的 位置 REEL_SYMBOL_ORDER.REEL_ORDER_2_1
SlotsNode.p_preParent = nil -- 切换图层之前的 parent 容器， 主要是在遮罩播放时显示 2017-12-05 17:34:48 修改
SlotsNode.p_preX = nil  -- 同上
SlotsNode.p_preY = nil
SlotsNode.p_preLayerTag = nil -- 同上
SlotsNode.p_slotNodeH = nil -- 创建格子时的高度，

SlotsNode.p_bigSymbolMaskNode = nil -- 大信号遮罩节点
SlotsNode.m_TAG_CCBNODE = nil -- ccbnode tag 值
SlotsNode.p_selfData = nil -- 大信号遮罩节点

SlotsNode.m_animaCallBackFun = nil --注册一个回调函数 
SlotsNode.m_symbolClipCanReset = nil -- 

SlotsNode.p_idleIsLoop = nil -- idle动画是否需要循环

SlotsNode.m_slotAnimaLoop = nil -- 动画是否需要循环
-- 构造函数
function SlotsNode:ctor()
    self:init()
end

---
--
function SlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = false
end

---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function SlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
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
        self.p_symbolImage:setScale(scale)
        self.p_symbolImage:setVisible(true)
    end
end

function SlotsNode:spriteChangeImage(sprite,imageName)
    if sprite == nil then
    	return
    end

    local frame = display.newSpriteFrame(imageName)
    if frame then
        sprite:setSpriteFrame(frame)
    end

    -- local frame  = cc.SpriteFrameCache:getInstance():getSpriteFrame(imageName)
    -- if frame then
    	
    --     sprite:setSpriteFrame(frame)
    -- else
    --     local texture = display.loadImage(imageName)
    --     if texture then
    --         local size = texture:getContentSize()
    --         local rect = cc.rect(0,0,0,0)
    --         rect.width = size.width
    --         rect.height = size.height
    --         local frame = display.newSpriteFrame(texture,rect)
    --         if frame then
    --             sprite:setSpriteFrame(frame)
    --         end
    --     end
    -- end
end


---
-- 设置连线时播放的动画名称
--
function SlotsNode:setLineAnimName(animName)
    self.m_lineAnimName = animName
end

function SlotsNode:setIdleAnimName( animName )
    self.m_idleAnimName = animName
end

function SlotsNode:changeSymbolImageByName( ccbName )

    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(ccbName)
    self.m_imageName = imageName
    if imageName == nil then  -- 直接添加ccb
        print("changeSymbolImageByName imageName是 nil ")
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

-- 切换ccb的动画名字在其它特定关卡使用
function SlotsNode:changeCCBByName(ccbName,symbolType)
    if ccbName == self.m_ccbName then 
        return 
    end
    
    self:removeAndPushCcbToPool()
    
    self.p_symbolType = symbolType
    self.m_ccbName = ccbName


    self:checkLoadCCbNode()
end

function SlotsNode:removeAndPushCcbToPool()

    local ccbNode = self:getCCBNode()
    
    if ccbNode ~= nil then
        ccbNode:resetTimeLine()
        ccbNode:removeFromParent(false)
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,  self.p_symbolType)
        end
    end
end

---
-- 设置移动目标位置
--
function SlotsNode:setTargetPos(posX,posY)
    self.m_reelTargetX = posX
    self.m_reelTargetY = posY
end

---
--
function SlotsNode:isLastSymbol()
    if self.m_isLastSymbol then
    	return true
    end
    return false
end
function SlotsNode:markLastSymbol(isLast)
    if isLast == nil then
        isLast = true
    end
    
    self.m_isLastSymbol = isLast
end

function SlotsNode:isRunEndTarget()
	return self.m_bRunEndTarge
end

function SlotsNode:markRunEndTarget(status)
    self.m_bRunEndTarge = status
end
----
-- 设置ccb 属性
--
function SlotsNode:getCcbProperty(propName)

    local ccbNode = self:getCCBNode()

    if ccbNode == nil then
        return nil
    end

    if not ccbNode.getCcbProperty then
        return nil
    end
    return ccbNode:getCcbProperty(propName)

end

---
-- 还原到初始被创建的状态
function SlotsNode:reset()

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
        ccbNode:resetTimeLine()
        ccbNode:removeFromParent(false)
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
---
-- clipy 起始的位置
-- clipW
-- clipH 
--
function SlotsNode:showBigSymbolClip(clipy,clipW,clipH)
 
    if self.p_bigSymbolMaskNode == nil then
        self.p_bigSymbolMaskNode = cc.ClippingRectangleNode:create({x=-clipW*0.5,y=clipy,width = clipW,height = clipH})
        self:addChild(self.p_bigSymbolMaskNode)
        
        
        self:checkAddToBigSymbolMask()

    end
end

function SlotsNode:resetReelStatus()

    if self.p_symbolImage ~= nil and self.m_imageName ~= nil then
        self.p_symbolImage:setVisible(true)
        self:hideBigSymbolClip()
        
        self:removeAndPushCcbToPool()
    end
end

----
-- 检测是否放到mask 长提哦遮罩里面去
--
function SlotsNode:checkAddToBigSymbolMask()

    if self.p_bigSymbolMaskNode ~= nil and 
        self.p_bigSymbolMaskNode:getParent() ~= nil then
        
        local ccbNode = self:getChildByTag(self.m_TAG_CCBNODE)  -- 这里直接从当前读取
        if ccbNode ~= nil then
            ccbNode:retain()
            ccbNode:removeFromParent(false)
            self.p_bigSymbolMaskNode:addChild(ccbNode)
            ccbNode:release()
        end

    end

end

---
-- 设置symbol clip 是否跟随reset
function SlotsNode:setSymbolClipCanReset(isReset)
    self.m_symbolClipCanReset = isReset
end

function SlotsNode:hideBigSymbolClip()
    if self.p_bigSymbolMaskNode ~= nil and self.m_symbolClipCanReset == true then
        local ccbNode = self.p_bigSymbolMaskNode:getChildByTag(self.m_TAG_CCBNODE)
        if ccbNode ~= nil then
            ccbNode:retain()
            ccbNode:removeFromParent(false)
            self:addChild(ccbNode)
            ccbNode:release()
            ccbNode:setPositionX(0)
            ccbNode:setPositionY(0)
        end
        
        self.p_bigSymbolMaskNode:removeFromParent()
        self.p_bigSymbolMaskNode = nil
    end
end
---
-- 播放连线时的动画
--
function SlotsNode:runLineAnim()

    local animName = self:getLineAnimName()

    self:runAnim(animName,true)
end

function SlotsNode:runIdleAnim()
    if self.p_idleIsLoop == nil then
        self.p_idleIsLoop = false
    end

    local csbNode = self:getCCBNode()
    if csbNode ~= nil then  -- 不用图片代替时才会直接播放默认动画
        self:runAnim(self:getIdleAnimName(),self.p_idleIsLoop)
    end
    
end

function SlotsNode:getLineAnimName()

    if self.m_lineAnimName ~= nil then
        return self.m_lineAnimName
    else
        return "actionframe"
    end

end

function SlotsNode:getIdleAnimName(  )
    if self.m_idleAnimName ~= nil then
        return self.m_idleAnimName
    else
        return "idleframe"
    end
end


---
-- 运行节点动画
-- @param animName string 节点里面动画名字

function SlotsNode:runAnim(animName,loop,func)
    if not self.p_symbolType then
        if type(func) == "function" then
            func()
        end
        return
    end
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

    end
    
end

--[[
    执行混合动作
]]
function SlotsNode:runMixAni(aniName,loop,func,curAniName,time)
    if not self.p_symbolType or not self.m_isLastSymbol then
        if type(func) == "function" then
            func()
        end
        return
    end
    local ccbNode = self:checkLoadCCbNode()
    if not tolua.isnull(ccbNode) and not tolua.isnull(ccbNode.m_spineNode) then
        local spine = ccbNode.m_spineNode
        if not curAniName then
            curAniName = self.m_currAnimName
        end
        --混合时间
        if not time then
            time = 0.2
        end
        util_spineMix(spine,curAniName,aniName,time)

    end
    
    self:runAnim(aniName,loop,func)
end

---
-- 运行节点动画
-- @param animName string 节点里面动画名字
function SlotsNode:runAnimFrame(animName,loop,frameName,func, funcEnd)
    
    local ccbNode = self:checkLoadCCbNode()
    if ccbNode ~= nil and self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(false)
    end
    local isPlay = ccbNode:runAnimFrame(animName,loop,frameName,func, funcEnd)
    
    if isPlay == true then
        self.m_slotAnimaLoop = loop
        self.m_currAnimName = animName

        if self.m_animaCallBackFun ~= nil then
            self.m_animaCallBackFun(self)
        end

    end
    
end


---
-- 运行帧动画
-- @param animIndex number 动画帧
function SlotsNode:runAnimByIndex(animIndex)
    local ccbNode = self:checkLoadCCbNode()
    if ccbNode ~= nil and self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(false)
    end
    local isPlay = ccbNode:runFrameForIndex(animIndex)
end

--获取当前播放动画
function SlotsNode:getSlotsNodeAnima()
    local animaName = self.m_currAnimName
    local bLoop = self.m_slotAnimaLoop
    if bLoop == nil then
        bLoop = false
    end

    if animaName then
        animaName = ""
    end
    return animaName, bLoop
end

function SlotsNode:getCCBNode()

    local ccbNode = self:getChildByTag(self.m_TAG_CCBNODE)

    if ccbNode == nil then
        if self.p_bigSymbolMaskNode ~= nil then
            ccbNode = self.p_bigSymbolMaskNode:getChildByTag(self.m_TAG_CCBNODE)
        end
    end


    return ccbNode
end

function SlotsNode:checkLoadCCbNode()

    local ccbNode = self:getCCBNode()

    -- 处理从内存池加载动画节点的逻辑。
    if ccbNode == nil then
        ccbNode = globalData.slotRunData.levelGetAnimNodeCallFun(self.p_symbolType,self.m_ccbName)

        self:addChild(ccbNode, 1, self.m_TAG_CCBNODE)

        -- 检测是否放到big mask 里面去
        self:checkAddToBigSymbolMask()
    end
    return ccbNode
end

---
--node所在列滚动停止之后播放的动画
function SlotsNode:playReelDownAnima()
    if self.p_reelDownRunAnima == nil then
        return
    end
    local ccbNode = self:checkLoadCCbNode()
    ccbNode:runAnim(self.p_reelDownRunAnima)
end

---
--获取动画持续时间
function SlotsNode:getAniamDurationByName(animaName)
    local ccbNode = self:getCCBNode()
    if ccbNode == nil then
        return 0
    end

    return ccbNode:getAnimDurationTime(animaName)
end

---
--
function SlotsNode:create()
    local slotsNode = SlotsNode.new()
    return slotsNode
end

---
-- 清理node节点, 释放不必要的对象， 尤其是 ccb[ccbName]里面的因为这是个全局的
-- 
function SlotsNode:clear()

    self.m_currAnimName = nil
    self.m_actionDatas = nil
    self.p_preParent = nil
    self.m_callBackFun = nil
    self:unregisterScriptHandler()  -- 卸载掉注册事件
    
    -- 检测释放掉添加进来的动画节点
    local ccbNode = self:getCCBNode()
    if ccbNode ~= nil then
        ccbNode:resetTimeLine()
        ccbNode:clear()

        ccbNode:removeAllChildren()

        if ccbNode:getReferenceCountEx() > 1 then
            ccbNode:release()
        end

        ccbNode:removeFromParent()

    end

    if self.p_symbolImage ~= nil and self.p_symbolImage:getParent() ~= nil then
        self.p_symbolImage:removeFromParent()
    end

    self.p_symbolImage = nil

end 
---
-- 修改layertag 同时修改p_preLayerTag
--
function SlotsNode:updateLayerTag(layerTag)
    self.p_preLayerTag = layerTag
    self.p_layerTag = layerTag
end
---
-- 添加自定义类型aciton，
-- 
function SlotsNode:addActions(...)
    local arg = {...}
    for i=#arg,1, -1 do
        
        self.m_actionDatas[#self.m_actionDatas + 1] = arg[i]
    end
end
---
--
function SlotsNode:clearAllActions()
    if self.m_actionDatas ~= nil then
        table_clear(self.m_actionDatas)
    end
end
function SlotsNode:getCurrentAction()
    return self.m_actionDatas[#self.m_actionDatas]
end

function SlotsNode:removeCurrentAction()
    self.m_actionDatas[#self.m_actionDatas] = nil
end
function SlotsNode:actionIsDone()
    if #self.m_actionDatas == 0 then
        return true
    end
    return false
end

---
--参与连线的martix坐标
function SlotsNode:setLinePos(linePos)
    self.m_lineMatrixPos = nil
    self.m_lineMatrixPos = linePos
end

---
--传入坐标是否是参与连线坐标
function SlotsNode:isInLinePos(matrixPos)
    if self.m_lineMatrixPos == nil then
	   return false
    end
    local posLen = #self.m_lineMatrixPos
    for i=1, posLen, 1 do
        
        
        if (self.m_lineMatrixPos[i].iX ~= matrixPos.iX or self.m_lineMatrixPos[i].iY ~= matrixPos.iY) == false then
            return true
        end
        
    end
    
    return false
end

--自定义数据
function SlotsNode:setSelfData(data)
    self.p_selfData = data
end

---获取当前播放动画的名字
function SlotsNode:getCurAnimName()
   return  self.m_currAnimName
end

function SlotsNode:getSelfData()
    return self.p_selfData
end

--注册一个动画播放回调函数
function SlotsNode:registerAniamCallBackFun(callBackFun)
    self.m_animaCallBackFun = callBackFun
end

function SlotsNode:isSlotsNode( )
    return true
end

--[[
    变更皮肤
]]
function SlotsNode:changeSkin(skinName)
    local ccbNode = self:checkLoadCCbNode()
    if not tolua.isnull(ccbNode) and ccbNode.m_spineNode then
        ccbNode.m_spineNode:setSkin(skinName)
    end
end

return SlotsNode