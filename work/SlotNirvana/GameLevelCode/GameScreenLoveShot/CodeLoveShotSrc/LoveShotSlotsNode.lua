---
--xcyy
--2018年5月23日
--LoveShotSlotsNode.lua
--fixios0223
local SlotsNode = require "Levels.SlotsNode"
local LoveShotSlotsNode = class("LoveShotSlotsNode",util_require("Levels.SlotsNode"))

function LoveShotSlotsNode:initMachine( machine)
    self.m_machine = machine
end


function LoveShotSlotsNode:createTrailingNode( symbolType,iCol,iRow,isLast )
    
    local nodeBg = self:getNodeBg(self.p_cloumnIndex,self.p_rowIndex )
    if nodeBg then
        self:removeBonusBg( nodeBg,true ) 
    end

    if symbolType == self.m_machine.SYMBOL_SHOT_BONUS  then
        
        local soundId =  gLobalSoundManager:playSound("LoveShotSounds/music_LoveShot_PigSymbol_LuoDITuoWei.mp3")

        local BgNode = util_createAnimation("LoveShot_Bonus_reeltuowei.csb") 
        BgNode.m_iCol = iCol
        BgNode.m_iRow = iRow
        BgNode.m_isLast = isLast
        BgNode.m_isMoveDown = false
        BgNode.soundId = soundId
        local order = SLOT_LAYER_ZOEDER_FLAG.SLOT_CLIP_NODE+1000000
        if isLast then
            order = -1
        end
        
        self.m_machine.m_onceClipNode:addChild(BgNode,order)
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

function LoveShotSlotsNode:updateBgNodePos( targNode )
    local pos = cc.p(self:getPosition())

   
    local wordPos = cc.p(self:getParent():convertToWorldSpace(pos))
    local localpos = self.m_machine.m_onceClipNode:convertToNodeSpace(cc.p(wordPos.x, wordPos.y))
    
    if targNode then
        targNode:setPosition(localpos)
    end
end

function LoveShotSlotsNode:removeBonusBg( _targNode , _quickRemove )
    
    _targNode.m_isMoveDown = true
    scheduler.unscheduleGlobal(_targNode.m_updateCoinHandlerID)

    if _quickRemove then
        _targNode:stopAllActions()
        _targNode:removeFromParent()
    else
        
        local pos = cc.p(_targNode:getPosition()) 
        
        local sizeY = 700
        local time = sizeY / self.m_machine.m_configData.p_reelMoveSpeed 

        local actList = {}
        actList[#actList + 1] = cc.EaseInOut:create(cc.MoveTo:create(time,cc.p(pos.x,pos.y - sizeY)),1)
        actList[#actList + 1] = cc.CallFunc:create(function(  )
            _targNode:stopAllActions()
            _targNode:removeFromParent()
        end)
        local sq = cc.Sequence:create(actList)
        _targNode:runAction(sq)
    end
        

end

function LoveShotSlotsNode:getNodeBg(_iCol,_iRow )
    
    if self.m_machine then


        for i=#self.m_machine.nodeBgList,1,-1 do
            local bgNode = self.m_machine.nodeBgList[i]
            if bgNode.m_iCol == _iCol and bgNode.m_iRow == _iRow then

                table.remove(self.m_machine.nodeBgList,i)

                return bgNode
                
            end
        end


    end



end

-- 切换ccb的动画名字在其它特定关卡使用
function LoveShotSlotsNode:changeCCBByName(ccbName,symbolType)

    local nodeBg = self:getNodeBg(self.p_cloumnIndex,self.p_rowIndex )


    if nodeBg then
        self:removeBonusBg( nodeBg,true ) 
    end

    SlotsNode.changeCCBByName(self,ccbName,symbolType)
end

function LoveShotSlotsNode:reset( removeFlag)

    local nodeBg = self:getNodeBg(self.p_cloumnIndex,self.p_rowIndex )


    if nodeBg then
        self:removeBonusBg( nodeBg ) 
    end
    
    


    SlotsNode.reset(self,removeFlag)

        
end

return LoveShotSlotsNode