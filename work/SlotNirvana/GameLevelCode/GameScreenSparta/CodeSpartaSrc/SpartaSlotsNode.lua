---
--xcyy
--2018年5月23日
--SpartaSlotsNode.lua

local SpartaSlotsNode = class("SpartaSlotsNode",util_require("Levels.SlotsNode"))
SpartaSlotsNode.m_machine = nil
-- SpartaSlotsNode.m_num = 0
SpartaSlotsNode.m_Corn = nil


function SpartaSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

function SpartaSlotsNode:initMachine( machine )
    self.m_machine =  machine
end
---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function SpartaSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
 
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
        self.p_symbolImage.imageName = imageName
        self.p_symbolImage:setPositionX(offsetX)
        self.p_symbolImage:setPositionY(offsetY)
        self.p_symbolImage:setVisible(true)
        self.p_symbolImage:setScale(0.5)
     
    end

    --增加bonus 效果. 不是lastSymobol, 初始化时直接 return
    if self.m_machine.m_playAddBonus or self.m_isLastSymbol == false or self.m_machine.m_bFirstSpin ==false then
        return
    end

    if self.p_symbolType and  self.p_symbolType ==  self.m_machine.SYMBOL_SCORE_BONUS then

        if self.m_ScatterBgNode == nil and self.m_machine then

            local csbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_machine.SYMBOL_SCORE_BONUS_BG)  

            self.m_ScatterBgNode = util_createAnimation(csbName..".csb") 
            self.m_machine.m_onceClipNode:addChild(self.m_ScatterBgNode, SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE - 10,10)
            self.m_ScatterBgNode:setVisible(false)

            schedule(self.m_ScatterBgNode,function()
                self.m_ScatterBgNode:setVisible(true)
                    self:updateScatterBgNodePos()
            end,0.00001)
        end 
    end
end

-- 切换ccb的动画名字在其它特定关卡使用
function SpartaSlotsNode:changeCCBByName(ccbName,symbolType)
    if ccbName == self.m_ccbName then 
        return 
    end
    
    self:removeAndPushCcbToPool()
    
    self.p_symbolType = symbolType
    self.m_ccbName = ccbName

    self:checkLoadCCbNode()
    if  self.p_symbolType == TAG_SYMBOL_TYPE.SYMBOL_WILD then
        self:resetImage()
        if self.p_symbolImage ~= nil then
            self.p_symbolImage:setVisible(false)
        end
    end
end
--[[
    @desc: 处理其它信号变化wild的逻辑， 更新数据信息、更新symbolImage信息
    time:2019-12-05 21:20:37
    @return:
]]
function SpartaSlotsNode:changeSymbolToWild(ccbName,symbolType )
    if  symbolType ~= TAG_SYMBOL_TYPE.SYMBOL_WILD then
        return
    end

    -- print("信号变化信息" .. symbolType .. "  col=" .. self.p_cloumnIndex .. " row=".. self.p_rowIndex  )
    if self.p_symbolType >= TAG_SYMBOL_TYPE.SYMBOL_SCORE_9 and
            self.p_symbolType <= TAG_SYMBOL_TYPE.SYMBOL_SCORE_4  and self:getCCBNode() ~= nil  then
        self:runAnim("idleframe")
    end
    self:removeAndPushCcbToPool()
    self.p_symbolType = symbolType
    self.m_ccbName = ccbName
    -- 重置显示图片
    self:resetImage()
end


function SpartaSlotsNode:resetImage()

    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(self.m_ccbName)
    self.m_imageName = imageName
    local offsetX = 0
    local offsetY = 0
    if self.p_symbolImage == nil then
        self.p_symbolImage = display.newSprite(self.m_imageName)
        self:addChild(self.p_symbolImage)
    else
        self:spriteChangeImage(self.p_symbolImage,self.m_imageName)
    end
    self.p_symbolImage.imageName = imageName
    self.p_symbolImage:setPositionX(offsetX)
    self.p_symbolImage:setPositionY(offsetY)
    self.p_symbolImage:setVisible(true)
    self.p_symbolImage:setScale(0.5)
end

function SpartaSlotsNode:updateScatterBgNodePos( )
    local pos = cc.p(self:getPosition())
    -- self.m_num = self.m_num +1
   
    local wordPos = cc.p(self:getParent():convertToWorldSpace(pos))
    local localpos = self.m_machine.m_onceClipNode:convertToNodeSpace(cc.p(wordPos.x, wordPos.y))
    
    if self.m_ScatterBgNode then
        self.m_ScatterBgNode:setPosition(localpos)
    end
end

function SpartaSlotsNode:removeBonusBg( )
    if self.m_ScatterBgNode then
        self.m_ScatterBgNode:playAction("over",false,function(  )
            self.m_ScatterBgNode:removeFromParent()
            self.m_ScatterBgNode = nil
        end)
    end
end

function SpartaSlotsNode:reset( removeFlag)
    
    if self.m_scatterBgHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_scatterBgHandlerId)
        self.m_scatterBgHandlerId = nil
    end

    if self.m_ScatterBgNode then
        self.m_ScatterBgNode:removeFromParent()
        self.m_ScatterBgNode = nil
    end

    if self.m_Corn then
        self.m_Corn:stopAllActions()
        self.m_Corn:removeFromParent()
        self.m_Corn = nil
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

    -- if self.p_symbolImage ~= nil then
    --     self.p_symbolImage:removeFromParent()
    --     self.p_symbolImage = nil
    -- end
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

function SpartaSlotsNode:removeAndPushCcbToPool()
    local ccbNode = self:getCCBNode()
    
    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        if ccbNode.__cname ~= nil and ccbNode.__cname == "SlotsSpineAnimNode" then
            ccbNode.m_spineNode:resetAnimation()
        end
        -- 放回到池里面去
        if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
            globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,  self.p_symbolType)
        end
    end
end

-- function SpartaSlotsNode:removeAndPushCcbToPool()
--     local ccbNode = self:getCCBNode()
    
--     if ccbNode ~= nil then
--         ccbNode:removeFromParent()
--         if ccbNode.__cname ~= nil and ccbNode.__cname == "SlotsSpineAnimNode" then
--             -- do nothing
--             -- ccbNode:resetSpine()

--             -- 放回到池里面去
--             if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
--                 -- 这里放回到完全不用的分类里面， 保证可以卸载diao
--                 globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,  20191206)
--             end
--         else
--             -- 放回到池里面去
--             if globalData.slotRunData.levelPushAnimNodeCallFun ~= nil then
--                 globalData.slotRunData.levelPushAnimNodeCallFun(ccbNode,  self.p_symbolType)
--             end
--         end
--     end
-- end

return SpartaSlotsNode