---
--island
--2018年4月12日
--TarzanFightFreeSpinStart.lua
--
-- 自定义的freeSpin开始弹框

local TarzanFightFreeSpinStart = class("TarzanFightFreeSpinStart", util_require("base.BaseView"))


TarzanFightFreeSpinStart.m_symbolSprite_1 = nil
TarzanFightFreeSpinStart.m_symbolSprite_2 = nil
TarzanFightFreeSpinStart.m_symbolSprite_3 = nil
TarzanFightFreeSpinStart.m_symbolSprite_4 = nil
TarzanFightFreeSpinStart.m_machineSprArray = nil

-- 构造函数
function TarzanFightFreeSpinStart:initUI(machine)
    self.m_machine=machine
    local resourceFilename="TarzanFight/FreeSpinStart.csb"
    self:createCsbNode(resourceFilename)
    self:showFsStart()
    self.m_closeBtn = self:findChild("Button_1")

    
end

function TarzanFightFreeSpinStart:setMachineFlaySymbol( SprArray )
    self.m_machineSprArray = SprArray
end

function TarzanFightFreeSpinStart:getFlaySymbol(i)
    local txt = self:findChild("TarzanFight_txt_"..i)
    local spr = self:findChild("TarzanFight_spr_"..i)
    
    return spr,txt
end

function TarzanFightFreeSpinStart:getMachineFlaySymbolForType( symbolType )
    for k,v in pairs(self.m_machineSprArray) do
        if v.symbolType ==  symbolType then
           return v.symbolSpr
        end
    end
end



function TarzanFightFreeSpinStart:showFsStart()
    self:runCsbAction("start")
end
function TarzanFightFreeSpinStart:showFsClose()
    self:runCsbAction("over")

    self:beginFlaySymblo()
end

function TarzanFightFreeSpinStart:beginFlaySymblo( )
    
    performWithDelay(self,
        function()
            for i=1,5 do        
                self:FlaySymbloIndex( i )
            end     
        end,
    0.5)
end

function TarzanFightFreeSpinStart:FlaySymbloIndex( i )
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
                local csbPath = self.m_machine:getFlaySymbolCsbPath(i)
                local spr,txt =  self:getFlaySymbol(i)
                local func = nil
                local typeSmbol = i
                if typeSmbol == 0 then
                    func = function(  )
                        
                        -- 根据type显示某类小信号
                        self.m_machine:showOneSymbolFromSymbolType(typeSmbol )
                        
                        if self.m_upEndCallBack then
                            self.m_upEndCallBack()
                        end 
                        self:closeView()
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
                    txt:setVisible(false)
                    gLobalSoundManager:playSound(self.m_machine.m_topSymbolMoveSounds[i])
                end
                

                self:flySymblos(startPos,endPos,func,csbPath)
            end
           
        end,
    i * 0.3)
end

function TarzanFightFreeSpinStart:flySymblos(startPos,endPos,func,csbPath)
    local flyNode = cc.Node:create()
    -- flyNode:setOpacity()
    self:addChild(flyNode,30000) -- 是否添加在最上层
    local time = 0.05
    local count = 5
    local flyTime = 0.5
    for i=1,count do
        self:runFlySymblosAction(flyNode,time*i,flyTime,startPos,endPos,i,csbPath)
    end
    performWithDelay(flyNode,function()
        if func then
            func()
        end
        flyNode:removeFromParent()
    end,flyTime+time*count)
end


function TarzanFightFreeSpinStart:runFlySymblosAction(flyNode,time,flyTime,startPos,endPos,index,csbPath)
    local actionList = {}
    local opacityList = {185,145,105,65,25,1,1,1,1,1}
    actionList[#actionList + 1] = cc.DelayTime:create(time)
    local node 
    if csbPath == "Socre_TarzanFight_9" then
        node =util_spineCreate("Socre_TarzanFight_9", true,true)
        -- self:addChild( self.m_spineAction)
        if node then
            util_spinePlay(node, "idle", false)
        end
    else
        node,csbAct=util_csbCreate(csbPath)
        util_csbPlayForKey(csbAct,"idle")
    end

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
          node:setLocalZOrder(index)
    end)
    
    node:runAction(cc.Sequence:create(actionList))
end

function TarzanFightFreeSpinStart:setCallBackFun(callBackFun)
    self.m_upEndCallBack = callBackFun
end

function TarzanFightFreeSpinStart:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    self.m_closeBtn:setTouchEnabled(false)
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:showFsClose()
end

function TarzanFightFreeSpinStart:closeView( )
    self:removeFromParent()
end


return TarzanFightFreeSpinStart