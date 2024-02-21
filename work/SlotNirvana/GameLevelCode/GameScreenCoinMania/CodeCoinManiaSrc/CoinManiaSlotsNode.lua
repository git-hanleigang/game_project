---
--xcyy
--2018年5月23日
--CoinManiaSlotsNode.lua
local SlotsNode = require "Levels.SlotsNode"
local CoinManiaSlotsNode = class("CoinManiaSlotsNode",util_require("Levels.SlotsNode"))

CoinManiaSlotsNode.m_machine = nil

CoinManiaSlotsNode.m_BgNode = nil

function CoinManiaSlotsNode:initMachine( machine)
    self.m_machine = machine
end

---
-- 传递进来的ccbName 不带有.ccbi 后缀， 主要是为了方便注册
-- symbol 对应的节点JS Controller 名字与ccbi一致
-- 
function CoinManiaSlotsNode:initSlotNodeByCCBName(ccbName,symbolType)
    SlotsNode.initSlotNodeByCCBName(self,ccbName,symbolType)

    
   
end

function CoinManiaSlotsNode:createTrailingNode( symbolType,iCol,iRow,isLast )
    if symbolType == self.m_machine.SYMBOL_PIG_Bonus and not self.m_machine.m_isOutLine  then
        

        local soundId =  gLobalSoundManager:playSound("CoinManiaSounds/music_CoinMania_PigSymbol_LuoDITuoWei.mp3")

        local BgNode = util_createAnimation("CoinMania_tuoying.csb") 
        BgNode.m_iCol = iCol
        BgNode.m_iRow = iRow
        BgNode.m_isLast = isLast
        BgNode.m_isMoveDown = false
        BgNode.soundId = soundId
        local node = cc.Node:create()
        node:addChild(BgNode)
        local order = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE+1000000
        if isLast then
            order = -1
        end
        
        self.m_machine.m_onceClipNode:addChild(node,order)
        BgNode:setVisible(false)
        BgNode.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()
            if not BgNode:isVisible() then
                BgNode:setVisible(true)
            end
           
            self:updateBgNodePos(BgNode)
    
        end)

        self.m_machine.nodeBgList[#self.m_machine.nodeBgList + 1] = BgNode


    end
end

function CoinManiaSlotsNode:updateBgNodePos( targNode )
    local pos = cc.p(self:getPosition())
    -- self.m_num = self.m_num +1
   
    local wordPos = cc.p(self:getParent():convertToWorldSpace(pos))
    local localpos = self.m_machine.m_onceClipNode:convertToNodeSpace(cc.p(wordPos.x, wordPos.y))
    
    if targNode then
        targNode:setPosition(localpos)
    end
end

function CoinManiaSlotsNode:removeBonusBg( targNode )
    

        if self.m_machine then


            targNode.m_isMoveDown = true
            scheduler.unscheduleGlobal(targNode.m_updateCoinHandlerID)
            
            local pos = cc.p(targNode:getPosition()) 
            
            local sizeY = 800
            local time = sizeY / self.m_machine.m_configData.p_reelMoveSpeed 

            local actList = {}
            actList[#actList + 1] = cc.EaseInOut:create(cc.MoveTo:create(time,cc.p(pos.x,pos.y - sizeY)),1)
            actList[#actList + 1] = cc.CallFunc:create(function(  )
                targNode:stopAllActions()
                targNode:getParent():stopAllActions()
                targNode:getParent():removeFromParent()
            end)
            local sq = cc.Sequence:create(actList)
            targNode:runAction(sq)

        else
            targNode:stopAllActions()
            targNode:getParent():stopAllActions()
            targNode:getParent():removeFromParent()
        end
     
end

function CoinManiaSlotsNode:reset( removeFlag)

    if self.p_symbolType == self.m_machine.SYMBOL_PIG_Bonus then
        if self.m_machine.nodeBgList[1] then
        
            self:removeBonusBg( self.m_machine.nodeBgList[1] )
            table.remove(self.m_machine.nodeBgList,1)
        end
    end

    SlotsNode.reset(self,removeFlag)

    
   
    
     
        
end

return CoinManiaSlotsNode