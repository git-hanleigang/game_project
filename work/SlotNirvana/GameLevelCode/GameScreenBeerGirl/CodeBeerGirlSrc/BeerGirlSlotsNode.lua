---
--xcyy
--2018年5月23日
--BeerGirlSlotsNode.lua

local BeerGirlSlotsNode = class("BeerGirlSlotsNode",util_require("Levels.SlotsNode"))

function BeerGirlSlotsNode:init()
    self.m_TAG_CCBNODE = 10
    self.m_lineAnimName = nil
    self.p_idleIsLoop = true
end

---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function BeerGirlSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
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
        
        if ccbName then
            if ccbName == "BeerGirl_grand"  then
                ccbName = "Socre_".. ccbName
            elseif ccbName == "BeerGirl_major"  then
                ccbName = "Socre_".. ccbName
            elseif ccbName == "BeerGirl_minor" then
                ccbName = "Socre_".. ccbName 
            elseif ccbName == "BeerGirl_mini" then   
                ccbName = "Socre_".. ccbName
            end
        end
        
        if ccbName == "Socre_BeerGirl_9" then
            print("")
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

function BeerGirlSlotsNode:runIdleAnim()
    if self.p_idleIsLoop == nil then
        self.p_idleIsLoop = false
    end

    self.p_idleIsLoop = true

    local csbNode = self:getCCBNode()
    if csbNode ~= nil then  -- 不用图片代替时才会直接播放默认动画
        self:runAnim(self:getIdleAnimName(),self.p_idleIsLoop)
    end
    
end

---
-- 还原到初始被创建的状态
function BeerGirlSlotsNode:reset(removeFlag)

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


return BeerGirlSlotsNode