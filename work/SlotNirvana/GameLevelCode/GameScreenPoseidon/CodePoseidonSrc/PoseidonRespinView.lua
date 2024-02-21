--[[
    luaide  模板位置位于 Template/FunTemplate/NewFileTemplate.lua 其中 Template 为配置路径 与luaide.luaTemplatesDir
    luaide.luaTemplatesDir 配置 https://www.showdoc.cc/web/#/luaide?page_id=713062580213505
    author:{author}
    time:2019-02-21 15:17:59
]]
local RespinView = util_require("Levels.RespinView")
local PoseidonRespinView = class("PoseidonRespinView", RespinView)

GD.POSEIDON_EFFECT_TYPE = 
{
    SEPICAL_CHANGE_JP = 1,      --圆球变up
    SEPICAL_CHANGE_UP = 2,      --圆球变up
    UP_REEL = 3,                -- ↑轮盘上升
    SEPICAL_CHANGE_ROUND = 4,   --圆球变up
    ROUND_CHANGE = 5,           -- X四周变为symbol9
    SEPICAL_CHANGE_SCORE = 6,   --圆球变up
    SCORE_CHANGE = 7,           -- +分值变高
    JACKPOT = 8,                -- ⚡️触发jp
}

local SPECIAL_NODE_TYPES = {1001, 1002, 1003, 1004}
local SPECIAL_SYMBOL_9_TYPE = {0, 93, 94}           --不同档位信号

local MOVE_TIME = 0.7
local UP_TIME = 0.6

PoseidonRespinView.m_effectTypes = nil  -- {type = EFFECT_TYPE , node =  respinNode, bePlay = false}
PoseidonRespinView.m_allFirstNodePos = nil

PoseidonRespinView.m_upTimes = nil
PoseidonRespinView.m_mulitipTimes = nil

PoseidonRespinView.m_respinStoreIcons = nil
PoseidonRespinView.m_jpInfo = nil
PoseidonRespinView.m_nowSpinUpTimes = nil
PoseidonRespinView.m_nowSpinRow = nil
PoseidonRespinView.m_machineNode  = nil
PoseidonRespinView.m_playRoundTimes = nil
PoseidonRespinView.m_bUpdateLeftCount = nil
PoseidonRespinView.m_bUpdataTotleCount = nil
PoseidonRespinView.m_bBreakLine = nil
PoseidonRespinView.m_allJpInfo = nil
PoseidonRespinView.m_jpNode = nil
PoseidonRespinView.m_bigSymbolNode = nil

function PoseidonRespinView:initUI(respinNodeName)
    RespinView.initUI(self, respinNodeName)
    self.m_effectTypes = {}
    self.m_allFirstNodePos = {}
    self.m_upTimes = 0
    self.m_mulitipTimes = 1 
    self.m_respinStoreIcons = {}
    self.m_jpInfo = {}
    
    self.m_nowSpinUpTimes = 0
    self.m_nowSpinRow = 0
    self.m_playRoundTimes = 0
    self.m_bUpdateLeftCount = false
    self.m_bUpdataTotleCount = false
end

function PoseidonRespinView:setMulitpTimes(time)
    self.m_mulitipTimes = time
end

function PoseidonRespinView:setMachineNode(node)
    self.m_machineNode = node
end

function PoseidonRespinView:setRespinStoreIcons(storeIcons, nowSpinRow)
    self.m_nowSpinRow = nowSpinRow
    self.m_respinStoreIcons = storeIcons
end

function PoseidonRespinView:setJpInfo(jpInfo)
    self.m_jpInfo = jpInfo
end

function PoseidonRespinView:setIsBreakLine(bBreak)
    self.m_bBreakLine = bBreak
end

function PoseidonRespinView:setAllJpData(allJpInfo)
    self.m_allJpInfo = allJpInfo
end

function PoseidonRespinView:getEffectType(symbolType)
    local effectType = nil
    local specailSymbolEffectType = nil
    
    if symbolType == 1003 then
        effectType = POSEIDON_EFFECT_TYPE.UP_REEL
        specailSymbolEffectType = POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_UP
    elseif symbolType == 1002 then
        effectType = POSEIDON_EFFECT_TYPE.ROUND_CHANGE
        specailSymbolEffectType = POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_ROUND
    elseif symbolType == 1004 then
        effectType = POSEIDON_EFFECT_TYPE.SCORE_CHANGE
        specailSymbolEffectType = POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_SCORE
    elseif symbolType == 1001 then
        effectType = POSEIDON_EFFECT_TYPE.JACKPOT
        specailSymbolEffectType = POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_JP
    end
    return effectType, specailSymbolEffectType
end

function PoseidonRespinView:createRespinNode(symbolNode, status)
    RespinView.createRespinNode(self, symbolNode, status)

    if self:isSpeicalSymbol(symbolNode.p_symbolType) then

        if self.m_bBreakLine and symbolNode.p_symbolType == 1001 then

            self.m_machineNode:changeNodeParentLayer(symbolNode, self.m_machineNode:getEffectLayer())
            symbolNode:runAnim("idleframe1004_1", false, function(  )
                self.m_machineNode:changeNodeParentLayer(symbolNode, self)
            end)

            local wins = 0
            for i=1,#self.m_allJpInfo do
                local jp = self.m_allJpInfo[i]
                if jp.pos.iX == symbolNode.p_rowIndex
                and jp.pos.iY == symbolNode.p_cloumnIndex
                then
                    wins = wins + jp.wins
                end
            end

            symbolNode:getCcbProperty("BitmapFontLabel_1"):setString(util_formatCoins(wins, 4))
           
            self:updateLabelSize({label= symbolNode:getCcbProperty("BitmapFontLabel_1"),sx=0.4,sy=0.4},210)
        else
            symbolNode:runAnim("idleframe"..tostring( symbolNode.p_symbolType))
        end

    end
    self:playBigAnima(symbolNode)

    self:updateRandomSymbol9Type()
end

function PoseidonRespinView:updateLabelSize(info,length,otherInfo)
    local width=info.label:getContentSize().width
    local scale=length/width
    if width<=length then
        scale=1
    end
    info.label:setScaleX(scale*(info.sx or 1))
    info.label:setScaleY(scale*(info.sy or 1))
    if otherInfo and #otherInfo>0 then
        for k,orInfo in ipairs(otherInfo) do
            orInfo.label:setScaleX(scale*(orInfo.sx or 1))
            orInfo.label:setScaleY(scale*(orInfo.sy or 1))
        end
    end
end

function PoseidonRespinView:playBigAnima(symbolNode)
    local martixPos = self:getRowAndColByPos(35)
    if symbolNode.p_cloumnIndex == martixPos.iY
    and symbolNode.p_rowIndex == martixPos.iX
    then
        -- symbolNode:runAnim("idleframe7")
        if  self.m_bigSymbolNode == nil then
            local nodePos = {}
            nodePos.x, nodePos.y = symbolNode:getPosition()
            self.m_bigSymbolNode = util_spineCreate("Poseidon_H1_HT", true, true)
            self.m_bigSymbolNode:setPosition(cc.p(nodePos.x, nodePos.y + self.m_slotNodeHeight * 3.5 + 1))
            symbolNode:getParent():addChild(self.m_bigSymbolNode, symbolNode:getLocalZOrder() + 1)
        end
        util_spinePlay(self.m_bigSymbolNode, "idleframe"..tostring(self.m_mulitipTimes), true)

    end
end

function PoseidonRespinView:initRespinElement(machineElement, machineRow, machineColmn, startCallFun)

    self.m_machineRow = machineRow 
    self.m_machineColmn = machineColmn
    self.m_startCallFunc = startCallFun
    self.m_respinNodes = {}
    self:setMachineType(machineColmn, machineRow)
    self:initClipNodes(machineElement,RESPIN_CLIPTYPE.COMBINE)
    self.m_machineElementData = machineElement
    for i=1,#machineElement do
          local nodeInfo = machineElement[i]
          local machineNode = self.getSlotNodeBySymbolType(nodeInfo.Type, nodeInfo.ArrayPos.iX, nodeInfo.ArrayPos.iY, true)
          local pos = self:convertToNodeSpace(nodeInfo.Pos)
          machineNode:setPosition(pos)

          if self:isSpeicalSymbol(machineNode.p_symbolType) then
            self:addChild(machineNode , REEL_SYMBOL_ORDER.REEL_ORDER_3 - machineNode.p_rowIndex, self.REPIN_NODE_TAG)
          else
            self:addChild(machineNode, nodeInfo.Zorder, self.REPIN_NODE_TAG)
          end
          if nodeInfo.ArrayPos.iY == 1 and nodeInfo.ArrayPos.iX > 3 then  -- 第一列是大图隐藏图标
            nodeInfo.isVisible = false
          end
          machineNode:setVisible(nodeInfo.isVisible)

          local status = nodeInfo.status
          self:createRespinNode(machineNode, status)

          if machineNode.p_rowIndex == 1 then
             self.m_allFirstNodePos[ machineNode.p_cloumnIndex ] = pos
          end
    end
    for i=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[i]
        repsinNode:setRespinView(self)
    end
    self:readyMove()
end

function PoseidonRespinView:startMove()
    self.m_jpNode = {}
    RespinView.startMove(self)
    self:playOutFrameAnima( self.m_machineRow + self.m_upTimes - 8)
end

function PoseidonRespinView:getUpTimes()
    return  self.m_machineRow + self.m_upTimes - 8
end

function PoseidonRespinView:getSpecialSymbolType()
    return SPECIAL_SYMBOL_9_TYPE[self.m_mulitipTimes]
end

function PoseidonRespinView:playOutFrameAnima(upTimes)
    self.m_machineNode:playOutFrameAnima(upTimes)
end

function PoseidonRespinView:isSpeicalSymbol(type)
    for i=1,#SPECIAL_NODE_TYPES do
        local sepcicalType = SPECIAL_NODE_TYPES[i]
        if type == sepcicalType then
           return true
        end
    end
    return false
end


--重写
function PoseidonRespinView:runNodeEnd(endNode)
    local info = self:getEndTypeInfo(endNode.p_symbolType)
    if info ~= nil and info.runEndAnimaName ~= "" and info.runEndAnimaName ~= nil then

        self.m_machineNode:changeNodeParentLayer(endNode, self.m_machineNode:getEffectLayer())
        endNode:runAnim(info.runEndAnimaName, false, function(  )
            self.m_machineNode:changeNodeParentLayer(endNode, self)
        end)
    
    end

    local nodeType = endNode.p_symbolType
    if self:isSpeicalSymbol(nodeType) then
        
        self.m_machineNode:changeNodeParentLayer(endNode, self.m_machineNode:getEffectLayer())
        endNode:runAnim("buling", false, function(  )
            self.m_machineNode:changeNodeParentLayer(endNode, self)
        end)

        local effectType, specailSymbolEffectType = self:getEffectType(nodeType)
        if specailSymbolEffectType ~= nil then
            self:addEffectType(specailSymbolEffectType, endNode)
        end

        if effectType ~= nil then
            self:addEffectType(effectType, endNode)
        end

    end
end

function PoseidonRespinView:getJpEffect()
    for i=1, #self.m_effectTypes do
        local effect = self.m_effectTypes[i]
        if effect.type == POSEIDON_EFFECT_TYPE.JACKPOT then
            return effect
        end
    end
    return nil
end

function PoseidonRespinView:addEffectType(effectType, repsinNode)

    if effectType == POSEIDON_EFFECT_TYPE.UP_REEL and self.m_upTimes == 2 then
        return 
    end

    local typeT = {type = effectType , node = repsinNode, bPlay = false}

    if effectType == POSEIDON_EFFECT_TYPE.JACKPOT then
        self.m_jpNode[#self.m_jpNode + 1] = repsinNode
        typeT.jpTimes = 1

        local jpEffect =  self:getJpEffect()
        if jpEffect ~= nil then
            jpEffect.jpTimes = jpEffect.jpTimes + 1
            return 
        end

    end
    self.m_effectTypes[#self.m_effectTypes + 1] = typeT
end


---
--typeT {type = EFFECT_TYPE , node =  respinNode, bPlay = false}
function PoseidonRespinView:addEffectTypeBySort(effectType, repsinNode)

    if effectType == POSEIDON_EFFECT_TYPE.UP_REEL and self.m_upTimes == 2 then
        return 
    end

    if effectType == POSEIDON_EFFECT_TYPE.UP_REEL and  self.m_upTimes == 1 then
        print("1")
    end

    local typeT = {type = effectType , node = repsinNode, bPlay = false}

    if #self.m_effectTypes == 0 then
        self.m_effectTypes[#self.m_effectTypes + 1] = typeT
    else
        local bEffectAdd = false
        for i = #self.m_effectTypes, 1, -1 do
            local effect = self.m_effectTypes[i]
            if effect.type < effectType then
                table.insert( self.m_effectTypes, i + 1, typeT)

                if bEffectAdd == false then
                    bEffectAdd = true
                end
                break
            end
        end
        
        if bEffectAdd == false then
            table.insert( self.m_effectTypes, 1, typeT)
        end
    end
end

function PoseidonRespinView:updataTotleCount()

    if self.m_bUpdataTotleCount then
        self.m_machineNode:upDataJpTotleCount()
        self.m_bUpdataTotleCount = false
    end
end

function  PoseidonRespinView:respinNodeEndBeforeResCallBack(endNode)
    RespinView.respinNodeEndBeforeResCallBack(self, endNode)
    if self:isSymbol9(endNode.p_symbolType) then
        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_move_chang.mp3")
    end
end


function PoseidonRespinView:respinNodeEndCallBack(endNode, status)
    --层级调换
    self.m_respinNodeStopCount = self.m_respinNodeStopCount + 1

    if status == RESPIN_NODE_STATUS.LOCK then
          local worldPos = endNode:getParent():convertToWorldSpace(cc.p(endNode:getPositionX(), endNode:getPositionY()))
          local pos = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
          

         if self:isSpeicalSymbol(endNode.p_symbolType) then
            gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_reels_down_power_up.mp3")
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_3 - endNode.p_rowIndex)
            
         else
            util_changeNodeParent(self,endNode,REEL_SYMBOL_ORDER.REEL_ORDER_2 - endNode.p_rowIndex)
        
            if self:isSymbol9(endNode.p_symbolType) then
                
                gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_down_H1.mp3")

                local lightNode = self.getSlotNodeBySymbolType(10004)

                local posNode = self:convertToNodeSpace(cc.p(worldPos.x,worldPos.y))
                self:addChild(lightNode, REEL_SYMBOL_ORDER.REEL_ORDER_3)
                lightNode:setPosition(posNode)

                self.m_machineNode:changeNodeParentLayer(lightNode, self.m_machineNode:getEffectLayer())
                lightNode:runAnim("actionframe", false, function()
                    self:updataTotleCount()
                    lightNode:removeFromParent()
                    self.pushSlotNodeToPoolBySymobolType(lightNode)
                end)
            end
        end
        endNode:setTag(self.REPIN_NODE_TAG)
        endNode:setPosition(pos)
    end
    self:runNodeEnd(endNode)

    if self.m_respinNodeStopCount == self.m_respinNodeRunCount  then
        self.m_nowSpinUpTimes = 0
        --排序
       self:setRespinEffectBySpecialSort()

       self:playRespinEffect()
    end
end

function PoseidonRespinView:setRespinEffectBySpecialSort()
    local jpEffects = {}

    local i = 1
    while i <= #self.m_effectTypes do
        
        local effectType = self.m_effectTypes[i]
        if effectType.type == POSEIDON_EFFECT_TYPE.JACKPOT then
            jpEffects[#jpEffects + 1] = effectType
            table.remove( self.m_effectTypes, i)
        else
            i = i + 1
        end
    end

    for j=1, #jpEffects do
        self.m_effectTypes[#self.m_effectTypes + 1] = jpEffects[j]
    end

    release_print("setRespinEffectBySpecaialSort.....")
end
--
--播放effect 
function PoseidonRespinView:playRespinEffect()
    local effectPlayEnd = true

    for i=1, #self.m_effectTypes do
        local effectType = self.m_effectTypes[i]

        if effectType.bPlay == false then
            effectPlayEnd = false

            if effectType.type == POSEIDON_EFFECT_TYPE.UP_REEL then
                self:playUpEffect(effectType)    
            elseif effectType.type == POSEIDON_EFFECT_TYPE.ROUND_CHANGE then
                self:playRoundChangeEffect(effectType)
            elseif effectType.type == POSEIDON_EFFECT_TYPE.SCORE_CHANGE then
                self:playScoreMulitipEffect(effectType)
            elseif effectType.type == POSEIDON_EFFECT_TYPE.JACKPOT then
                self:playJPEffect(effectType)
            elseif effectType.type == POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_ROUND
            or POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_UP
            or POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_SCORE
            or POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_JP
            then
                self:playSpecialChangeEffect(effectType)

            end
            break
        end
    end

    if effectPlayEnd then
        self.m_effectTypes = {}
        self.m_playRoundTimes = 0

        performWithDelay(self, function(  )
            release_print("PoseidonRespinView 424 ")
            gLobalNoticManager:postNotification(ViewEventType.NOTIFY_RESPIN_RUN_STOP)
            release_print("PoseidonRespinView 424 END ")
        end , 1)

    end
end 

function PoseidonRespinView:playNextEffect(effectType)
    effectType.bPlay = true
    effectType.node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_3 - effectType.node.p_rowIndex)
    self:playRespinEffect()
end

function PoseidonRespinView:playSpecialChangeEffect( effectType )


    local symbolNode = effectType.node

    -- local nodeSp = symbolNode:getCcbProperty("spEndChange")

    -- -- symbolNode:spriteChangeImage(nodeSp, frame)
    -- nodeSp:setTexture(getNodeSpName(effectType.type))

    -- symbolNode:runAnim("actionframe",false , function()
    --     self:playNextEffect(effectType)
    -- end)
    self:playSpecialSymbolChangeAnima(symbolNode, effectType)


    -- performWithDelay(self, function()
    --     self:m_machineNode:playPoseidonShakre()   
    -- end, 2.5)

    -- performWithDelay(self, function() 
    --     self:m_machineNode:playPoseidonShakre()   
    -- end, 2.5)

    performWithDelay(self, function(  )
        release_print("PoseidonRespinView 462")
        self.m_machineNode:playPoseidonShakre()
        release_print("PoseidonRespinView 462 END")
    end, 3)

    performWithDelay(self, function (  )
        release_print("PoseidonRespinView 468")
        local posX = symbolNode:getPositionX()
        local posY = symbolNode:getPositionY()
        
        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_reels_Thunder_power_up.mp3")
        local lightNode = self.getSlotNodeBySymbolType(20001)
        self.m_machineNode:getEffectLayer():addChild(lightNode, REEL_SYMBOL_ORDER.REEL_ORDER_3)
        lightNode:setPosition(cc.p(posX, posY))

        -- self.m_machineNode:changeNodeParentLayer(lightNode, self.m_machineNode:getEffectLayer())

        lightNode:runAnim("actionframe", false, function()
            lightNode:removeFromParent()
            self.pushSlotNodeToPoolBySymobolType(lightNode)
        end)
    end, 3.8)
end

function PoseidonRespinView:playAnima(specialNode, index , animaType, effectType)
    
    if  index < #animaType - 3 then
        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_reels_chnage_power_up.mp3")
    end

    specialNode:runAnim("animation"..animaType[index] , false, function()
        if index <  #animaType then
            self:playAnima(specialNode, index + 1, animaType, effectType)
        else
            self.m_machineNode:changeNodeParentLayer(specialNode, self)
            return
        end
    end)
end

function PoseidonRespinView:playSpecialSymbolChangeAnima(specialNode, effectType)
    local getNodeSpName = function(type)
        local spName = nil
        if type == POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_ROUND then
            spName = "Symbol/Poseidon_bonus_sizhou.png"
        elseif type == POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_UP then
            spName = "Symbol/Poseidon_bonus_up.png"
        elseif type == POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_SCORE then 
            spName = "Symbol/Poseidon_bonus_jia.png"
        elseif type == POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_JP  then
            spName = "Symbol/Poseidon_bonus_chazi.png"
        end
        return spName
    end

    local getEffectName = function(type)
        local spName = nil
        if type == POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_ROUND then
            spName = "Symbol/Poseidon_SBC36.png"
        elseif type == POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_UP then
            spName = "Symbol/Poseidon_SBC31.png"
        elseif type == POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_SCORE then 
            spName = "Symbol/Poseidon_SBC41.png"
        elseif type == POSEIDON_EFFECT_TYPE.SEPICAL_CHANGE_JP  then
            spName = "Symbol/Poseidon_SBC26.png"
        end
        return spName
    end


    local animaType = {0, 1, 2, 3}
    local animaTypes2 = {0, 1, 2, 3}
    randomShuffle(animaType)
    randomShuffle(animaTypes2)

    if animaType[#animaType] == animaTypes2[1] then
        for i=#animaTypes2, 1, -1 do
            animaType[#animaType + 1] = animaTypes2[i]
        end
    else
        for i= 1, #animaTypes2 do
            animaType[#animaType + 1] = animaTypes2[i]
        end
    end
    
    animaType[#animaType + 1] = 4

    local nodeSp = specialNode:getCcbProperty("spEndChange")

    -- symbolNode:spriteChangeImage(nodeSp, frame)
    util_changeTexture(nodeSp,getNodeSpName(effectType.type))

    
    local nodeSpTexiao = specialNode:getCcbProperty("spEndChange_0")
    util_changeTexture(nodeSpTexiao,getEffectName(effectType.type))
  
    self.m_machineNode:changeNodeParentLayer(specialNode, self.m_machineNode:getEffectLayer())
    specialNode:runAnim("actionframe", false, function()
        self:playAnima(specialNode, 1, animaType, effectType)
    end)

    performWithDelay(self, function (  )

        self.m_machineNode:playRsSpecialNodeTip(specialNode.p_symbolType)

    end, 5.8)

    performWithDelay(self, function (  )
        self:playNextEffect(effectType)
    end, 7.8)

end

--
--轮盘上升effect
function PoseidonRespinView:playUpEffect( effectType )
    
    self.m_upTimes = self.m_upTimes + 1
    local childs = self:getChildren()
    for i=1, #childs do
        local node = childs[i]
        local posY = node:getPositionY()
        local posX = node:getPositionX()
        node:runAction(cc.MoveTo:create(MOVE_TIME, cc.p(posX, posY + self.m_slotNodeHeight)))

        if node:getTag() == self.REPIN_NODE_TAG then
            node.p_rowIndex = node.p_rowIndex + 1
        end
    end

    for i=1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[i]
        respinNode.p_rowIndex = respinNode.p_rowIndex + 1
    end    

    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_reels_up.mp3")

    self.m_machineNode:runCsbAction("actionframe_up"..(self.m_upTimes + self.m_machineRow))
    self.m_machineNode:setBigPoseidonScaleAnima(UP_TIME)

    for i=1, #self.m_allFirstNodePos do
        local pos = self.m_allFirstNodePos[i]
        local node = self.getSlotNodeBySymbolType( SPECIAL_SYMBOL_9_TYPE[self.m_mulitipTimes], 1, i)

        node:setPosition(pos)
        self:addChild(node, REEL_SYMBOL_ORDER.REEL_ORDER_2 + self.m_upTimes, self.REPIN_NODE_TAG)
        node:setVisible(false)
        performWithDelay(self,function(  )
            release_print("PoseidonRespinView 580 ")
            node:setVisible(true)
            self:addLightNode(pos, true)
            release_print("PoseidonRespinView 580 END ")
        end, (i- 1) * UP_TIME + MOVE_TIME)
    end

    performWithDelay(self, function() 
        release_print("PoseidonRespinView 586 ")
        self.m_nowSpinUpTimes = self.m_nowSpinUpTimes + 1   --本次轮盘增长数

        self:playNextEffect(effectType)
        release_print("PoseidonRespinView 586 END")

    end, 4 * UP_TIME + MOVE_TIME + 0.5)
end

function PoseidonRespinView:addLightNode(pos, isPlaySound)
    if isPlaySound then
        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_boom.mp3")
    end
    local lightNode = self.getSlotNodeBySymbolType(10005)
    self:addChild(lightNode, REEL_SYMBOL_ORDER.REEL_ORDER_3)
    lightNode:setPosition(pos)

    self.m_machineNode:changeNodeParentLayer(lightNode, self.m_machineNode:getEffectLayer())
    
    lightNode:runAnim("actionframe", false, function()
        lightNode:removeFromParent()
        self.pushSlotNodeToPoolBySymobolType(lightNode)
    end)
end

---
--jpEffect
function PoseidonRespinView:playJPEffect( effectType )
    
    -- self:playJPShowAnima( effectType , function(  )
     
    -- end)


    -- performWithDelay(self, function(  )
        self:showJpView( effectType )
    -- end, 1)
end

function PoseidonRespinView:showJpView( effectType )

    self.m_machineNode:clearCurMusicBg()

    

    local jpView = util_createView("CodePoseidonSrc.JackPotView")
    --传入信号池
    jpView:setNodePoolFunc(self.getSlotNodeBySymbolType, self.pushSlotNodeToPoolBySymobolType)
    jpView:jpRunTimes(effectType.jpTimes)
    jpView:initFeatureUI(self.m_jpInfo)
    jpView:initJpUI(self.m_machineNode)
    jpView:setJpSymbolNode(self.m_jpNode)
    
    jpView:setOverCallBackFun(function()
        -- self.m_machineNode:rePutJpBar()
        -- self:playJPShowAnima(effectType)
        self:setVisible(true) 
        self.m_machineNode.m_csbOwner["Node_man"]:setVisible(true)
        self.m_machineNode.m_csbOwner["Node_1"]:setVisible(true)
        self.m_machineNode.m_machineNode:setVisible(true)
        -- self.m_machineNode:
        jpView:runCsbAction("actionframe2",false)
        performWithDelay(self,function (  )
          
            release_print("PoseidonRespinView 639  ")
            self.m_machineNode:resetMusicBg()
            --播放下一个动画
            jpView:removeFromParent()
            effectType.node:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_3 - effectType.node.p_rowIndex)
            effectType.bPlay = true
            self:playRespinEffect()

            for i=1,#self.m_jpNode do
                local node = self.m_jpNode[i]

                self.m_machineNode:changeNodeParentLayer(node, self.m_machineNode:getEffectLayer())

                node:runAnim("idleframe1004_1", false, function(  )
                    self.m_machineNode:changeNodeParentLayer(node, self)
                end)

                self:addLightNode({x = node:getPositionX(),y = node:getPositionY() }, true)
            end
            release_print("PoseidonRespinView 639 END ")
        end, 2)
    end)
    if globalData.slotRunData.machineData.p_portraitFlag then
        jpView.getRotateBackScaleFlag = function(  ) return false end
    end
    gLobalViewManager:showUI(jpView)

    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_guochang_flash.mp3")

    jpView:runCsbAction("actionframe", false,function(  )
        self:setVisible(false)
        self.m_machineNode.m_csbOwner["Node_man"]:setVisible(false)
        self.m_machineNode.m_csbOwner["Node_1"]:setVisible(false)
        self.m_machineNode.m_machineNode:setVisible(false)
        jpView:runCsbAction("idle",true)
    end)
    -- local jpNode = self.m_machineNode:getJpBar()
    jpView:addJpNode( self.m_machineNode)

    -- self.m_machineNode:updateJackpot()
                    --     performWithDelay(self, function (  )        
                    --     gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)
                    --     -- gLobalViewManager:gotoSceneByType(SceneType.Scene_Lobby)

                    -- end, 0.01)
end

-- function PoseidonRespinView:playJPShowAnima( effectType, func)
--     local node = self.getSlotNodeBySymbolType(10007)

--     gLobalViewManager.p_ViewLayer:addChild(node)
--     local pos =gLobalViewManager.p_ViewLayer:convertToNodeSpace(cc.p(display.width/2,display.height/2))
--     node:setPosition(pos)
--     node:runAnimFrame("actionframe",false,"show_view",function()
--         if func ~= nil then
--             func()
--         end
--     end)

--     performWithDelay(self, function(  )
--         node:removeFromParent()
--         -- self.pushSlotNodeToPoolBySymobolType(node, node.p_symbolType)
--     end, 2)
-- end


function PoseidonRespinView:getRowAndColByPos(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = self.m_machineColmn

    local rowIndex = (self.m_machineRow + self.m_upTimes) - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex,iY = colIndex}
end

function PoseidonRespinView:getFixSymbolNodeByMatrixPos(iX, iY)
    local childs = self:getChildren()
    for i=1, #childs do
        local child = childs[i]
        if child:getTag() == self.REPIN_NODE_TAG 
        and child.p_rowIndex == iX
        and child.p_cloumnIndex == iY
        and child.p_symbolType == 100
        then 
            return child
        end
    end
    return nil
end

function PoseidonRespinView:getRespinNode(row, col)
    
    for i=1,#self.m_respinNodes do
        local respinNode = self.m_respinNodes[i]
        if respinNode.p_rowIndex == row 
        and  respinNode.p_colIndex == col then
            return respinNode
        end
    end    

    return nil
end

-- --
-- --四周变换动画111
function PoseidonRespinView:playRoundChangeEffect(effectType)

    local diff = self.m_nowSpinRow - self.m_machineRow 
    self.m_playRoundTimes = self.m_playRoundTimes + 1
    local isChange = false

    if #self.m_respinStoreIcons == 0 then
        self:playNextEffect(effectType)
        return
    end 

    local respinStoreIcons = nil
    for i=1, #self.m_respinStoreIcons do
        local storeIcons = self.m_respinStoreIcons[i]
        local speicalSymbolPos = self:getRowAndColByPos(storeIcons[1])
        if speicalSymbolPos.iX == effectType.node.p_rowIndex
        and speicalSymbolPos.iY == effectType.node.p_cloumnIndex
        then
            respinStoreIcons = storeIcons
            break
        end
    end

    if respinStoreIcons == nil then
        assert(false, "respinStoreIcons  nil !!!!!!")
    end

    if #respinStoreIcons <= 1  then
        self:playNextEffect(effectType)
        return
    end

    if #respinStoreIcons > 1 then
        gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_ROUND_CHANGE_H1.mp3")
    end

    for i = 2, #respinStoreIcons do
        isChange = true
        local pos = respinStoreIcons[i]
        local matrixPos = self:getRowAndColByPos(pos)
        local matrixPosX =  matrixPos.iX
        -- if diff > 0 then
        --     matrixPosX = matrixPosX - diff
        -- end

        local repinNode = self:getRespinNode(matrixPosX, matrixPos.iY)

        if repinNode ~= nil and repinNode:getRespinNodeStatus() ~= RESPIN_NODE_STATUS.LOCK then
            repinNode:setRespinNodeStatus(RESPIN_NODE_STATUS.LOCK)

            local row = repinNode.p_rowIndex
            local col = repinNode.p_colIndex
            local posX = repinNode:getPositionX()
            local posY = repinNode:getPositionY()
            local type =  SPECIAL_SYMBOL_9_TYPE[self.m_mulitipTimes]
        
            local newSymbol = self.getSlotNodeBySymbolType(type, row, col)

            self:addChild(newSymbol, REEL_SYMBOL_ORDER.REEL_ORDER_4, self.REPIN_NODE_TAG)
            -- self:playBigAnima(newSymbol)
            local jpNodePosX = effectType.node:getPositionX()
            local jpNodePosY = effectType.node:getPositionY()

            local callFun = cc.CallFunc:create(function ()
                
                
                newSymbol:setLocalZOrder(REEL_SYMBOL_ORDER.REEL_ORDER_2 - newSymbol.p_rowIndex)
                if i ==  #respinStoreIcons  then
                    self:addLightNode({x = posX,y = posY }, true)
                else
                    self:addLightNode({x = posX,y = posY })
                end
     
            end)

            newSymbol:setPosition(cc.p(jpNodePosX, jpNodePosY))
            newSymbol:runAction(cc.Sequence:create(cc.MoveTo:create(0.5, cc.p(posX, posY)) , callFun, nil))
        end

    end
    performWithDelay(self, function()
        release_print("PoseidonRespinView 795  ")
        self:playNextEffect(effectType)
        release_print("PoseidonRespinView 795 END ")
    end, 2.5)
end

function PoseidonRespinView:removeBigSymolNode()
    if self.m_bigSymbolNode ~= nil then
        self.m_bigSymbolNode:removeFromParent()
        self.m_bigSymbolNode = nil
    end
end

function PoseidonRespinView:isSymbol9(symbolType)
    for i=1,#SPECIAL_SYMBOL_9_TYPE do
        local type = SPECIAL_SYMBOL_9_TYPE[i]
        if type == symbolType then
           return true
        end
    end
    return false
end

function PoseidonRespinView:replaceFixSymbolNode(node, replaceType)
    --   self.getSlotNodeBySymbolType
    local row = node.p_rowIndex
    local col = node.p_cloumnIndex
    local posX = node:getPositionX()
    local posY = node:getPositionY()

    local newSymbol = self.getSlotNodeBySymbolType(replaceType, row, col)
    newSymbol:setPosition(cc.p(posX, posY))  
    newSymbol:setVisible(node:isVisible())
    self:addChild(newSymbol, REEL_SYMBOL_ORDER.REEL_ORDER_2 - node.p_rowIndex, self.REPIN_NODE_TAG)

    node:removeFromParent()

    self.pushSlotNodeToPoolBySymobolType(node)
    return newSymbol
end
-- --
-- --分数翻倍Effect
function PoseidonRespinView:playScoreMulitipEffect(effectType)
    
    self.m_mulitipTimes = self.m_mulitipTimes + 1
    self:updateRandomSymbol9Type()
    
    local childs = self:getChildren()
    for i=1, #childs do
        local child = childs[i]

        if child:getTag() == self.REPIN_NODE_TAG and self:isSymbol9(child.p_symbolType) then

            local newSymbol = self:replaceFixSymbolNode(child, SPECIAL_SYMBOL_9_TYPE[self.m_mulitipTimes])
            self:playBigAnima(newSymbol)
        end
    end

    gLobalSoundManager:playSound("PoseidonSounds/music_Poseidon_H1_LevelUp.mp3")

    performWithDelay(self, function()
        release_print("PoseidonRespinView 853 ")
        self:playNextEffect(effectType)
        release_print("PoseidonRespinView 853 END ")
    end, 0.8)
end

function PoseidonRespinView:setRunEndInfo(storedNodeInfo, unStoredReels, updataTotleCount, specailRun)
    self.m_bUpdateLeftCount = not updataTotleCount
    self.m_bUpdataTotleCount = updataTotleCount
    
    local ustroedReelsSpecialRunIndex = nil

    
    for j=1,#self.m_respinNodes do
          local repsinNode = self.m_respinNodes[j]
          local bFix = false 
          local coldiff = 3
        --   if specailRun == true then
        --     coldiff = 10
        --   end
          local runLong = self:getBaseRunNum() + (repsinNode.p_colIndex- 1) * coldiff
          for i=1, #storedNodeInfo do
                local stored = storedNodeInfo[i]
                if self:isSymbol9(stored.type) then
                    stored.type = SPECIAL_SYMBOL_9_TYPE[self.m_mulitipTimes]
                end
                if repsinNode.p_rowIndex == stored.iX and repsinNode.p_colIndex == stored.iY then
                      repsinNode:setRunInfo(runLong, stored.type, specailRun , true)
                      bFix = true
                end
          end
          
          for i=1,#unStoredReels do
                local data = unStoredReels[i]
                if self:isSymbol9(data.type) then
                    data.type = SPECIAL_SYMBOL_9_TYPE[self.m_mulitipTimes]
                end
                if repsinNode.p_rowIndex == data.iX and repsinNode.p_colIndex == data.iY then

                    local bSpecialRun = false

                    if specailRun 
                    and xcyy.SlotsUtil:getArc4Random() % 3 == 1 then
                        bSpecialRun = true
                    end

                    repsinNode:setRunInfo(runLong, data.type, bSpecialRun, false)
                end
          end
    end
end

function PoseidonRespinView:updateRandomSymbol9Type()
    for j=1,#self.m_respinNodes do
        local repsinNode = self.m_respinNodes[j]
        local symbolRandomType = repsinNode.m_symbolRandomType
        for i=1, #symbolRandomType do

            if self:isSymbol9(symbolRandomType[i]) then
                symbolRandomType[i] = SPECIAL_SYMBOL_9_TYPE[self.m_mulitipTimes]
            end
    
        end
    end
    for i=1, #self.m_symbolRandomType do

        if self:isSymbol9(self.m_symbolRandomType[i]) then
            self.m_symbolRandomType[i] = SPECIAL_SYMBOL_9_TYPE[self.m_mulitipTimes]
        end

    end

end

return PoseidonRespinView