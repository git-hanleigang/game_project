--
-- 点击小节点
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptShaqiuClickView = class("MiracleEgyptShaqiuClickView", util_require("base.BaseView"))

function MiracleEgyptShaqiuClickView:initUI( collectView )

    self:createCsbNode("Socre_Shaqiu_clickView.csb")

    self.m_btn =  self:findChild("clickBtn")
    self:addClick(self.m_btn )

    self.BubbleNode = util_createView("CodeMiracleEgyptSrc.MiracleEgyptShaqiu")
    self:addChild(self.BubbleNode)

    self.BubbleNodeBoom = util_createView("CodeMiracleEgyptSrc.MiracleEgyptShaqiuBao")
    self:addChild(self.BubbleNodeBoom)
    self.BubbleNodeBoom:setVisible(false)

    self.m_CollectLab1 = util_createView("CodeMiracleEgyptSrc.MiracleEgypCollectLab",1)
    self:addChild(self.m_CollectLab1)
    self.m_CollectLab1:setVisible(false)

    self.m_CollectLab2 = util_createView("CodeMiracleEgyptSrc.MiracleEgypCollectLab",2)
    self:addChild(self.m_CollectLab2)
    self.m_CollectLab2:setVisible(false)

    self.m_collectView = collectView

end

function MiracleEgyptShaqiuClickView:setCallFunc( func )
   self.m_func = func
end

--结束监听
function MiracleEgyptShaqiuClickView:clickStartFunc(sender)

    if sender then
        local name = sender:getName()
        if name == "clickBtn" then

            
            
            if self.m_collectView.m_clickIndex > #self.m_collectView.m_freespinInfo then
                print("~~~~~~~~~~~~   结束Bonus点击")
                return
            end

            if self.m_collectView.m_clickTimes <= 0 and self.m_collectView.m_clickIndex > 0 then
                print("~~~~~~~~~~~~   需要等待加的次数更新之后才能点")
                return
            end

            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            self.m_btn:setVisible(false)
            self.BubbleNode:setVisible(false)
            self.BubbleNodeBoom:setVisible(true)

            self.m_collectView:updateClickTimes(-1 )

            gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BubblesBoom.mp3")
            local clickIndex = self.m_collectView.m_clickIndex
            self.BubbleNodeBoom:showAction(function(  )
                self.BubbleNodeBoom:setVisible(false)
            end )

            performWithDelay(self,function() 
               
                if self.m_collectView.m_freespinInfo[clickIndex] > 99 then
                    self.m_CollectLab2:setVisible(true)
                    self.m_CollectLab2:setLabStr(self.m_collectView.m_freespinInfo[clickIndex] / 100)
                else
                    self.m_CollectLab1:setVisible(true)
                    self.m_CollectLab1:setLabStr(self.m_collectView.m_freespinInfo[clickIndex])
                end 
            end, 0.3)

            local clickOverNum = self.m_collectView.m_clickIndex
            performWithDelay(self,function() 
                if self.m_collectView.m_freespinInfo[clickIndex] > 99 then

                    self:stopAllActions()
                    local fontNode = self.m_collectView.m_CollectLabViewPick:findChild("BitmapFontLabel_1")
                    local endPos = fontNode:getParent():convertToWorldSpace(cc.p(fontNode:getPosition()))
                    endPos = self.m_collectView:findChild("root"):convertToNodeSpace(endPos)
                    gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BubblesFlay.mp3")

                    self:runMoveAct(endPos,function(  )

                        if clickOverNum >= #self.m_collectView.m_freespinInfo  then
                                if self.m_func then
                                    self.m_func()
                                end 
                        end 

                        self.m_collectView:updateClickTimes(self.m_collectView.m_freespinInfo[clickIndex] / 100 )
                    end )
    
                else
    
                    self:stopAllActions()
                    
                    local fontNode = self.m_collectView.m_CollectLabViewFs:findChild("BitmapFontLabel_1")
                    local endPos = fontNode:getParent():convertToWorldSpace(cc.p(fontNode:getPosition()))
                    endPos = self.m_collectView:findChild("root"):convertToNodeSpace(endPos)
                    
                    gLobalSoundManager:playSound("MiracleEgyptSounds/MiracleEgypt_BubblesFlay.mp3")

                    self:runMoveAct(endPos,function(  )

                        if clickOverNum >= #self.m_collectView.m_freespinInfo  then
                                if self.m_func then
                                    self.m_func()
                                end 
                        end 

                        self.m_collectView:updateFreeSpinTimes(self.m_collectView.m_freespinInfo[clickIndex])
                    end )
                end 
                
            end, 1)
                 

            self.m_collectView.m_clickIndex = self.m_collectView.m_clickIndex + 1
        end
    end
end

function MiracleEgyptShaqiuClickView:removeSelf(  )
    self:removeFromParent()
end

function MiracleEgyptShaqiuClickView:runMoveAct(endPos,func )
    local time = 1
    local actionList = {}
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        local actionList1 = {}

        actionList1[#actionList1 + 1] = cc.ScaleTo:create(time,0.1)
       
        self:runAction(cc.Sequence:create(actionList1))
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(time,endPos)
    actionList[#actionList + 1] = cc.CallFunc:create(function()
        if func then
            func()
        end
        self:removeSelf( )
    end)
    self:runAction(cc.Sequence:create(actionList))
end

return  MiracleEgyptShaqiuClickView