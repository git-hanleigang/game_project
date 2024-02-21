---
--xcyy
--2018年5月23日
--PussCollectBarView.lua

local PussCollectBarView = class("PussCollectBarView",util_require("base.BaseView"))


function PussCollectBarView:initUI()

    self:createCsbNode("Puss_jindutiao.csb")

    self.PROGRESS_WIDTH = self:findChild()

    self.m_Progress = util_createView("CodePussSrc.Collect.PussCollectLoadingBarView")
    self:findChild("loading"):addChild(self.m_Progress)
    self.m_Progress:setPercent(0)

    self.m_Coins = util_createView("CodePussSrc.Collect.PussCollectCoinsView")
    self:findChild("coins"):addChild(self.m_Coins)

    self:addClick(self:findChild("clickToUnLock"))

    
end

function PussCollectBarView:setMachine( machine )
    self.m_machine = machine
end


function PussCollectBarView:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)  -- 更新赢钱动画
       
        local flag = params
        if globalData.slotRunData.currSpinMode ~= NORMAL_SPIN_MODE then
            flag=false
        end

        
        if self and self.findChild then
            local unlockImg = self:findChild("clickToUnLock")
            if unlockImg then
                self:findChild("clickToUnLock"):setVisible(flag)
            end
            
        end
        

    end,"BET_ENABLE")

end


function PussCollectBarView:onExit()
 
end


--默认按钮监听回调
function PussCollectBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    
        if self.m_machine then
            if self.m_machine:checkShopShouldClick( ) then
                return
            end
            

            if name == "Button_1" then
                if self.m_machine.m_nodePos then
                    gLobalSoundManager:playSound("PussSounds/music_Puss_Click_Show_Map.mp3")
                    self.m_machine.m_MapView:updateLittleUINodeAct( self.m_machine.m_nodePos,self.m_machine.m_bonusPath )
                    self.m_machine.m_MapView:showMap( )
                end

            elseif name == "clickToUnLock" then


                    self.m_machine:changeBetToUnlock()

            end

            
            
        end
    

end


return PussCollectBarView