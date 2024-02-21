

local PepperBlastNode = class("PepperBlastNode", 
                                    util_require("Levels.RespinNode"))

local SYMBOL_WILD = 92
local SYMBOL_SPECIAL_WILD = 93

local MOVE_SPEED = 1500     --滚动速度 像素/每秒
local RES_DIS = 20
local RES_DIS_QUICKSTOP = 30

function PepperBlastNode:changeNodeDisplay( node )
    local imageName = globalData.slotRunData.levelConfigData:getSymbolImageByCCBName(node.m_ccbName)
    local showType = self.m_machine.m_reSpinSymbolType
    if(node.p_symbolType == showType)then
        if(nil~=node.p_symbolImage)then
            util_setCsbVisible(node.p_symbolImage, true)
        end
        return
    end
    if imageName ~= nil then
        --截取第一个参数作为资源路径
        imageName = imageName[1]
        --暂时没有灰色资源 
        -- imageName = string.gsub(imageName, ".png", "_gray.png")
        node:removeAndPushCcbToPool()
        if node.p_symbolImage == nil then
            -- node.p_symbolImage = display.newSprite(imageName)
            -- node:addChild(node.p_symbolImage)
        else
            util_setCsbVisible(node.p_symbolImage, false)
            -- node:spriteChangeImage(node.p_symbolImage,imageName)
        end
        
        -- node.p_symbolImage:setVisible(true)
    end
end



--====================重写父类
--裁切遮罩透明度
function PepperBlastNode:initClipOpacity(opacity)
    if opacity and opacity>0 then
        local pos = cc.p(0 , 0)
        local clipSize = cc.size(self.m_clipNode.clipSize.width+4,self.m_clipNode.clipSize.height+10)
        local spPath = "common/PepperBlast_RESPIN_DI.png"
        opacity = 255
        local colorNode = util_createColorMask(RESPIN_COLOR_TYPE.SPRITE,pos,clipSize,opacity,spPath)
        self.m_clipNode:addChild(colorNode, SHOW_ZORDER.SHADE_LAYER_ORDER)
    end
end

--执行回弹动作
function PepperBlastNode:runBaseResAction()
    self:baseResetNodePos()
    local baseResTime = 0
    --最终停止小块回弹
    if self.m_baseFirstNode then
          local offPos = self.m_baseFirstNode:getPositionY()-self.m_baseStartPosY
          local actionTable ,downTime = self:getBaseResAction(0, self.m_baseFirstNode)
          if actionTable and #actionTable>0 then
              self.m_baseFirstNode:runAction(cc.Sequence:create(actionTable))
          end
          if baseResTime<downTime then
              baseResTime = downTime
          end
    end
    --上边缘小块回弹
    if self.m_baseNextNode then
          if self.m_baseNextNode.p_symbolImage then
                self.m_baseNextNode.p_symbolImage:removeFromParent()
                self.m_baseNextNode.p_symbolImage = nil
          end
          self.m_baseNextNode:changeCCBByName(self.m_machine:getSymbolCCBNameByType(self.m_machine, self.m_machine.m_reSpinSymbolType), self.m_machine.m_reSpinSymbolType)
          self.m_baseNextNode:setLocalZOrder(SHOW_ZORDER.SHADE_LAYER_ORDER + 1)
          local offPos = self.m_baseFirstNode:getPositionY() - self.m_baseStartPosY - self.m_slotNodeHeight
          local actionTable ,downTime = self:getBaseResAction(0)
          if actionTable and #actionTable>0 then
                self.m_baseNextNode:runAction(cc.Sequence:create(actionTable))
          end
          --回弹结束后移除上边缘小块
          if downTime>0 then
                --检测时长
                if baseResTime<downTime then
                    baseResTime = downTime
                end
                performWithDelay(self,function()
                    self:baseRemoveNode(self.m_baseNextNode)
                    self.m_baseNextNode = nil
                end,downTime)
          else
                self:baseRemoveNode(self.m_baseNextNode)
                self.m_baseNextNode = nil
          end
    end
    return baseResTime
end

--获取回弹action @symbol 小块
--墨西哥分支
function PepperBlastNode:getBaseResAction(startPos, symbol)
    local time1 = 5/30
    local time2 = 5/30
    local moveResDis = RES_DIS
    if self.m_isQuickStop then
        time1 = 5/30
        time2 = 5/30
        moveResDis = RES_DIS_QUICKSTOP
    end
    local dis =  startPos + moveResDis
    local timeDown = 0
    local speedActionTable = {}

    if(symbol and symbol.p_symbolType == self.m_machine.m_reSpinSymbolType)then
        speedActionTable[#speedActionTable + 1] = cc.CallFunc:create(function()
            --scatter落地音效,wild
            local soundName = string.format("PepperBlastSounds/music_PepperBlast_Wild_reelDown_%d.mp3", symbol.p_cloumnIndex)  
            gLobalSoundManager:playSound(soundName)
            symbol:runAnim("buling",false,function()
                symbol:runAnim("idleframe1", true)
            end)
        end)
    end
    speedActionTable[#speedActionTable + 1] = cc.MoveBy:create(time1,cc.p(0, - moveResDis))
    speedActionTable[#speedActionTable + 1] = cc.MoveBy:create(time2,cc.p(0,moveResDis))
    timeDown = time1 + time2 + 0.1

    return speedActionTable, timeDown
end

return PepperBlastNode