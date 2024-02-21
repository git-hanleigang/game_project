---
--xcyy
--2018年5月23日
--EgyptMiniSlotsNode.lua
local SlotsNode = require("Levels.SlotsNode")
local EgyptMiniSlotsNode = class("EgyptMiniSlotsNode", SlotsNode)
EgyptMiniSlotsNode.m_mark = nil
EgyptMiniSlotsNode.p_levelPushAnimNodeCallFun = nil
EgyptMiniSlotsNode.p_levelGetAnimNodeCallFun = nil
EgyptMiniSlotsNode.p_levelConfigData = nil

function EgyptMiniSlotsNode:removeAndPushCcbToPool()
    local ccbNode = self:getCCBNode()
     
    if ccbNode ~= nil then
        ccbNode:removeFromParent()
        
        -- 放回到池里面去
        if self.p_levelPushAnimNodeCallFun ~= nil then
            self.p_levelPushAnimNodeCallFun(ccbNode,  self.p_symbolType)
        end
    end
end

---
-- 还原到初始被创建的状态
function EgyptMiniSlotsNode:reset()

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
        if self.p_levelPushAnimNodeCallFun ~= nil then
            self.p_levelPushAnimNodeCallFun(ccbNode,self.p_symbolType)
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

function EgyptMiniSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
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
        
        local imageName = self.p_levelConfigData:getSymbolImageByCCBName(ccbName)
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


function EgyptMiniSlotsNode:clear()
    SlotsNode.clear(self)

    self.p_levelPushAnimNodeCallFun = nil
    self.p_levelGetAnimNodeCallFun = nil
end



function EgyptMiniSlotsNode:checkLoadCCbNode()

    local ccbNode = self:getCCBNode()

    -- 处理从内存池加载动画节点的逻辑。
    if ccbNode == nil then
        if self.p_symbolType == nil then
            release_print(debug.traceback())
        end
        ccbNode = self.p_levelGetAnimNodeCallFun(self.p_symbolType,self.m_ccbName)

        self:addChild(ccbNode, 1, self.m_TAG_CCBNODE)

        -- 检测是否放到big mask 里面去
        self:checkAddToBigSymbolMask()
    end
    return ccbNode
end


return EgyptMiniSlotsNode