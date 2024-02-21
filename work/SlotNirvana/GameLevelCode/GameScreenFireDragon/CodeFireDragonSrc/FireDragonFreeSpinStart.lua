---
--island
--2018年4月12日
--FireDragonFreeSpinStart.lua
--
-- 自定义的freeSpin开始弹框

local FireDragonFreeSpinStart = class("FireDragonFreeSpinStart", util_require("base.BaseView"))


FireDragonFreeSpinStart.m_symbolSprite_1 = nil
FireDragonFreeSpinStart.m_symbolSprite_2 = nil
FireDragonFreeSpinStart.m_symbolSprite_3 = nil
FireDragonFreeSpinStart.m_symbolSprite_4 = nil
FireDragonFreeSpinStart.m_machineSprArray = nil

-- 构造函数
function FireDragonFreeSpinStart:initUI(machine)
    self.m_machine=machine
    local resourceFilename="FireDragon/FreeSpinStart.csb"
    self:createCsbNode(resourceFilename)
    self:showFsStart()
    self.m_closeBtn = self:findChild("Button_1")

    
end

function FireDragonFreeSpinStart:setMachineFlaySymbol( SprArray )
    self.m_machineSprArray = SprArray
end

function FireDragonFreeSpinStart:getFlaySymbol(i)
    local spr = self:findChild("FireDragon_spr_"..i)
    
    return spr
end

function FireDragonFreeSpinStart:getMachineFlaySymbolForType( symbolType )
    for k,v in pairs(self.m_machineSprArray) do
        if v.symbolType ==  symbolType then
           return v.symbolSpr
        end
    end
end



function FireDragonFreeSpinStart:showFsStart()
    self:runCsbAction("start")
end
function FireDragonFreeSpinStart:showFsClose()
    self:runCsbAction("over")

    self:beginFlaySymblo()
end

function FireDragonFreeSpinStart:beginFlaySymblo( )
    
    performWithDelay(self,
        function()
            for i=1,5 do        
                self:FlaySymbloIndex( i )
            end     
        end,
    0.5)
end

function FireDragonFreeSpinStart:FlaySymbloIndex( i )
    performWithDelay(self,
        function()   
            if self.m_machineSprArray  then
                if i == 5 then
                    i = 0
                end
                local startWorldPos = self:getFlaySymbol(i):getParent():convertToWorldSpace(cc.p(self:getFlaySymbol(i):getPosition()))
                local startPos=  cc.p(self:convertToNodeSpace(startWorldPos))
                local worldPos = self:getMachineFlaySymbolForType(i):getParent():convertToWorldSpace(cc.p(self:getMachineFlaySymbolForType(i):getPosition()))
                local endPos = self:convertToNodeSpace(worldPos) 
                local spr =  self:getFlaySymbol(i)
                local func = nil
                local typeSmbol = i
                if typeSmbol == 0 then
                    endPos = cc.p(endPos.x - 35, endPos.y + 10)
                    func = function(  )
                        self.m_machine:showOneSymbolFromSymbolType(typeSmbol )
                        self:runCsbAction("over1", false, function()
                            -- 根据type显示某类小信号
                            if self.m_upEndCallBack then
                                self.m_upEndCallBack()
                            end 
                            self:closeView()
                        end)
                    end
                    gLobalSoundManager:playSound(self.m_machine.m_topSymbolMoveSounds[1])
                    spr:setVisible(false)
                else 
                    func = function(  )
                        -- 根据type显示某类小信号
                        self.m_machine:showOneSymbolFromSymbolType(typeSmbol )
                        -- 显示某个小信号分数图片
                        self.m_machine:showOneSymbolScoreImg( typeSmbol )
                        self.m_machine:palyOneSymbolScoreImgAction( typeSmbol,"show")
                       
                    end
                    spr:setVisible(false)
                    gLobalSoundManager:playSound(self.m_machine.m_topSymbolMoveSounds[i])
                end
                

                self:flySymblos(startPos,endPos,func,i)
            end
           
        end,
    i * 0.3)
end

function FireDragonFreeSpinStart:flySymblos(startPos,endPos,func,symbolType)
    local flyNode = cc.Node:create()
    -- flyNode:setOpacity()
    self:addChild(flyNode,30000) -- 是否添加在最上层
    local time = 0.05
    local count = 5
    local flyTime = 0.5
    for i=1,count do
        self:runFlySymblosAction(flyNode,time*i,flyTime,startPos,endPos,i,symbolType)
    end
    performWithDelay(flyNode,function()
        if func then
            func()
        end
    end,flyTime - 0.05)
    performWithDelay(flyNode,function()
        flyNode:removeFromParent()
    end,flyTime + time * count)
end


function FireDragonFreeSpinStart:runFlySymblosAction(flyNode,time,flyTime,startPos,endPos,index,symbolType)
    local actionList = {}
    local opacityList = {185,145,105,65,25,1,1,1,1,1}
    actionList[#actionList + 1] = cc.DelayTime:create(time)

    local node = self.m_machine:getSlotNodeBySymbolType(symbolType)
    node:runAnim("idleframe1")
    -- node:setVisible(false)
    util_setCascadeOpacityEnabledRescursion(node,true)
    node:setOpacity(opacityList[index])
    actionList[#actionList + 1] = cc.CallFunc:create(function()
    --     node:setVisible(true)
        node:runAction(cc.ScaleTo:create(flyTime,self.m_machine.m_littleSymbolScaleSize))
    end)
    flyNode:addChild(node,6-index)
    node:setPosition(startPos)

    actionList[#actionList + 1] = cc.MoveTo:create(flyTime, cc.p(endPos))
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        node:setOpacity(0)
        node:setLocalZOrder(index)
    end)

    node:runAction(cc.Sequence:create(actionList))
end

function FireDragonFreeSpinStart:setCallBackFun(callBackFun)
    self.m_upEndCallBack = callBackFun
end

function FireDragonFreeSpinStart:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    self.m_closeBtn:setTouchEnabled(false)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:showFsClose()
end

function FireDragonFreeSpinStart:closeView( )
    self:removeFromParent()
end


return FireDragonFreeSpinStart