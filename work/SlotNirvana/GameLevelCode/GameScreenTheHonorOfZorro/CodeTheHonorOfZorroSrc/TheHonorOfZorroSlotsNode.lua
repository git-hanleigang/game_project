---
--xcyy
--2018年5月23日
--TheHonorOfZorroSlotsNode.lua

local TheHonorOfZorroSlotsNode = class("TheHonorOfZorroSlotsNode",util_require("Levels.SlotsNode"))

---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function TheHonorOfZorroSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
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
        local scale = 0.5
        if tolua.type(imageName) == "table" then
            self.m_imageName = imageName[1]
            offsetX = imageName[2]
            offsetY = imageName[3]
            scale = imageName[4] or 0.5
        end

        --bonus信号
        if symbolType == 94 or symbolType == 95 or symbolType == 96 then
            if self.p_symbolImage and self.p_symbolImage.p_symbolType ~= 94 and self.p_symbolImage.p_symbolType ~= 95 and self.p_symbolImage.p_symbolType ~= 96 then
                self.p_symbolImage:removeFromParent()
                self.p_symbolImage = nil
            end
            if not self.p_symbolImage then
                self.p_symbolImage = util_createAnimation("Socre_TheHonorOfZorro_Bonus1_zi.csb")
                self:addChild(self.p_symbolImage)
            end
            
            self.p_symbolImage:findChild("sp_bonus1"):setVisible(symbolType == 94)
            self.p_symbolImage:findChild("sp_bonus2"):setVisible(symbolType ~= 94)
            if symbolType == 96 then
                self.p_symbolImage:runCsbAction("idleframe2")
            else
                self.p_symbolImage:runCsbAction("idleframe")
            end
        else
            if self.p_symbolImage and (self.p_symbolImage.p_symbolType == 94 or self.p_symbolImage.p_symbolType == 95 or self.p_symbolImage.p_symbolType == 96) then
                self.p_symbolImage:removeFromParent()
                self.p_symbolImage = nil
            end
            if self.p_symbolImage == nil then
                self.p_symbolImage = display.newSprite(self.m_imageName)
                self:addChild(self.p_symbolImage)
            else
                self:spriteChangeImage(self.p_symbolImage,self.m_imageName)
            end
            self.p_symbolImage:setScale(scale)
        end

        self.p_symbolImage.p_symbolType = symbolType
        self.p_symbolImage:setPositionX(offsetX)
        self.p_symbolImage:setPositionY(offsetY)
        self.p_symbolImage:setVisible(true)
    end
end

---
-- 运行节点动画
-- @param animName string 节点里面动画名字

function TheHonorOfZorroSlotsNode:runAnim(animName,loop,func)
    if not self.p_symbolType then
        if type(func) == "function" then
            func()
        end
        return
    end
    local ccbNode = self:checkLoadCCbNode()
    if ccbNode ~= nil and self.p_symbolImage ~= nil then
        self.p_symbolImage:setVisible(false)
        ccbNode:setVisible(true)
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

return TheHonorOfZorroSlotsNode