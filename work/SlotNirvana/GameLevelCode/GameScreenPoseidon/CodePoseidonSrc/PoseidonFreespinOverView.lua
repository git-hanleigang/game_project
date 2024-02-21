---
--smy
--2018年4月18日
--PoseidonFreespinOverView.lua


local PoseidonFreespinOverView = class("PoseidonFreespinOverView", util_require("base.BaseView"))

PoseidonFreespinOverView.soundIdArrays = nil
PoseidonFreespinOverView.isSoundNotPlayed = true

function PoseidonFreespinOverView:initUI()
    self:createCsbNode("Poseidon/FreeSpinOver.csb")

    self.AdiuId = nil --  -- gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_view_over.mp3")
    self.soundIdArrays = nil

    self.isSoundNotPlayed = true
    local touchLayer = self:findChild("touchPlane")
    self:addClick(touchLayer)
end

function PoseidonFreespinOverView:jumpLab( )
   
    -- self.m_updateCoinHandlerID = scheduler.scheduleUpdateGlobal(function()

    --     self:updateCoins()
    self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_coins))

    -- end)
end

function PoseidonFreespinOverView:updateCoins( )
    self.m_llGrowCoinNum = self.m_llGrowCoinNum + self.m_llPerAddNum

    

    if self.m_llGrowCoinNum >= self.m_coins then
        self.m_llGrowCoinNum = self.m_coins
        if self.AdiuId then
            -- -- gLobalSoundManager:stopAudio(self.AdiuId)
            self.AdiuId = nil
        end

        if self.soundIdArrays == nil and self.isSoundNotPlayed  then
            self.isSoundNotPlayed = false
            local audioID = nil  -- -- gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_fs_view_hide.mp3")
            self.soundIdArrays = audioID

        end
        
    end

    self.m_lb_coins:setString(util_getFromatMoneyStr(self.m_llGrowCoinNum))
    if globalData.slotRunData.isPortrait == true then
        util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 600)
    else
        util_scaleCoinLabGameLayerFromBgWidth(self.m_lb_coins, 1000)
    end


    if self.m_llGrowCoinNum >= self.m_coins then
        
        
        if self.m_updateCoinHandlerID ~= nil then
            scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
        end
        
    end

end

function PoseidonFreespinOverView:initViewData(coins,num,callBackFun)
    self.m_callFunc=callBackFun
    
    self.m_coins = coins

    self.m_lb_coins =self:findChild("m_lb_coins")
    
   
    self.m_lb_coins:setString(0)


    local coinRiseNum =  self.m_coins / (5 * 60)  -- 每秒60帧

    local str = string.gsub(tostring(coinRiseNum),"0",math.random( 1, 5 ))
    coinRiseNum = tonumber(str)
    self.m_llPerAddNum = tonumber(coinRiseNum) 
    self.m_llGrowCoinNum = 0
   
    self:jumpLab()

    -- performWithDelay(self,function() 
    --     if not self.m_clicked then
            
    --         if self.m_llGrowCoinNum == self.m_coins then

    --             if self.soundIdArrays then
    --                 -- -- gLobalSoundManager:stopAudio(self.soundIdArrays)
    --                 self.soundIdArrays = nil
    --             end

    --         else
    --             self.m_llGrowCoinNum = self.m_coins
    --             self.m_lb_coins:setString(self.m_llGrowCoinNum)
    --             if self.soundIdArrays then
    --                 -- -- gLobalSoundManager:stopAudio(self.soundIdArrays)
    --                 self.soundIdArrays = nil
    --             end
    --         end

    --     end  
    --  end, 5)

end

function PoseidonFreespinOverView:onEnter()
    self.m_clicked = false  --点击状态

    self:runCsbAction("start",false,function(  )
        self:runCsbAction("idle",true)
        self.m_clicked = true
    end)
end

function PoseidonFreespinOverView:onExit()
    if self.m_updateCoinHandlerID ~= nil then
        scheduler.unscheduleGlobal(self.m_updateCoinHandlerID)
    end
end
--点击回调
function PoseidonFreespinOverView:clickFunc(sender)
    if self.m_clicked ~= true then
        return 
    end
    -- -- -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

    if self.AdiuId then
        -- -- gLobalSoundManager:stopAudio(self.AdiuId)
        self.AdiuId = nil
    end

    -- -- gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_btn_click.mp3")

    sender:setTouchEnabled(false)
    local name = sender:getName()
    local tag = sender:getTag()


        
        if self.soundIdArrays then
            -- -- gLobalSoundManager:stopAudio(self.soundIdArrays)
            self.soundIdArrays = nil
        end
        if name == "backBtn" then
            gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

            self:removeSelf()
            self.m_clicked = false
        end

end



function PoseidonFreespinOverView:removeSelf( )
    self:runCsbAction("over",false,function(  )
        if self.m_callFunc then
            self.m_callFunc()
        end
        self:removeFromParent()
    end)
end

return PoseidonFreespinOverView