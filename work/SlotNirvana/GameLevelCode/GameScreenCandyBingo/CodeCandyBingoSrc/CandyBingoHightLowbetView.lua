---
--xcyy
--2018年5月23日
--CandyBingoHightLowbetView.lua

local CandyBingoHightLowbetView = class("CandyBingoHightLowbetView",util_require("base.BaseView"))
CandyBingoHightLowbetView.m_machine = nil
CandyBingoHightLowbetView.m_canClick = false

function CandyBingoHightLowbetView:initUI()

    self:createCsbNode("CandyBingo_BetView1.csb")

    self:addClick( self:findChild("btn_hight") )
    self:addClick( self:findChild("btn_mid") )
    self:addClick( self:findChild("btn_low") )

end


function CandyBingoHightLowbetView:onEnter()


end

function CandyBingoHightLowbetView:initMachineBetDate(data)

    self.m_canClick = false
    self:runCsbAction("start",false,function(  )
        self.m_canClick = true
        self:runCsbAction("idle",true)
    end)

    -- data.minBet = self:getMinBet( )
    -- data.betLevel = self:getBetLevel()

    -- self.m_canClick = true


end

function CandyBingoHightLowbetView:initMachine(machine)

    self.m_machine = machine

    self:updatelab()

end



function CandyBingoHightLowbetView:onExit()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
end

function CandyBingoHightLowbetView:updatelab( )

    local coins1 = self:findChild("m_lb_coins_1")
    local coins2 = self:findChild("m_lb_coins_2")
    local coins3 = self:findChild("m_lb_coins_3")

    if self:getMinCoins(2,true) == self:getMaxCoins(3 ) then
        coins1:setString(util_formatCoins(self:getMinCoins(2,true), 3))
    else
        coins1:setString(util_formatCoins(self:getMinCoins(2,true), 3)  .."-".. util_formatCoins( self:getMaxCoins(3 ), 3))
    end

    if self:getMinCoins(1,true) == self:getMaxCoins(2 ) then
        coins2:setString(util_formatCoins(self:getMinCoins(1,true), 3))
    else
        coins2:setString(util_formatCoins(self:getMinCoins(1,true), 3) .."-".. util_formatCoins( self:getMaxCoins(2 ), 3))
    end


    if self:getMinCoins(1,false) == self:getMaxCoins(1 ) then
        coins3:setString(util_formatCoins(self:getMinCoins(1,false), 3))
    else
        coins3:setString(util_formatCoins(self:getMinCoins(1,false), 3) .."-".. util_formatCoins( self:getMaxCoins(1 ), 3))
    end




end

function CandyBingoHightLowbetView:getMaxCoins(index )
    local maxcoins = 0

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    local maxBet = 0

    if index == 1 then
        maxBet = self.m_machine.m_specialBets[index].p_totalBetValue
        for i = #betList,1,-1 do
            local betData = betList[i]
            if betData.p_totalBetValue < maxBet then

                maxcoins = betData.p_totalBetValue

                break
            end
        end
    elseif index == 2 then
        maxBet = self.m_machine.m_specialBets[index].p_totalBetValue
        for i = #betList,1,-1 do
            local betData = betList[i]
            if betData.p_totalBetValue < maxBet then

                maxcoins = betData.p_totalBetValue

                break
            end
        end

    else
        maxcoins =  betList[#betList].p_totalBetValue
    end

    return maxcoins
end

function CandyBingoHightLowbetView:getMinCoins(index,isMAX  )
    local mincoins = 0
    local minBet = self.m_machine.m_specialBets[index].p_totalBetValue

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if isMAX then -- 大于等于
            if betData.p_totalBetValue >= minBet then

                mincoins = betData.p_totalBetValue

                break
            end
        else
            if betData.p_totalBetValue < minBet then

                mincoins = betData.p_totalBetValue

                break
            end

        end

    end

    return mincoins
end

function CandyBingoHightLowbetView:setBetId(index,isMAX )

    local minBet = self.m_machine.m_specialBets[index].p_totalBetValue

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
    for i=1,#betList do
        local betData = betList[i]
        if isMAX then -- 大于等于
            if betData.p_totalBetValue >= minBet then

                globalData.slotRunData.iLastBetIdx =   betData.p_betId

                break
            end
        else
            if betData.p_totalBetValue < minBet then

                globalData.slotRunData.iLastBetIdx =   betData.p_betId

                break
            end

        end

    end




    -- 设置bet index
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

end

function CandyBingoHightLowbetView:setMaxBetId(index )

    local maxBet = self.m_machine.m_specialBets[index].p_totalBetValue

    local betList = globalData.slotRunData.machineData:getMachineCurBetList()


    for i=#betList,1,-1 do
        local betData = betList[i]
        if betData.p_totalBetValue < maxBet   then
            globalData.slotRunData.iLastBetIdx =   betData.p_betId

            break
        end
    end


    -- 设置bet index
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)

end

--默认按钮监听回调
function CandyBingoHightLowbetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_canClick == true then

        self.m_canClick = false
        gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)

        if name == "btn_hight" then
            if self.m_machine:getBetLevel() == 2 then
                print("什么也不干")
            else
                if self.m_machine:checkShowChooseBetView( ) then

                        self:setBetId(2,true )

                end


            end
            self:runCsbAction("little_1",false,function(  )
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
                self:setVisible(false)
            end)

        elseif name == "btn_mid" then
            if self.m_machine:getBetLevel() == 1 then
                print("什么也不干")
            else

                if self.m_machine:checkShowChooseBetView( ) then
                    if self.m_machine:getBetLevel() > 1 then
                        self:setMaxBetId(2)
                    else


                        self:setBetId(1,true )


                    end

                end


            end

            self:runCsbAction("little_2",false,function(  )
                self:setVisible(false)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
            end)
        elseif name == "btn_low" then
            if self.m_machine:getBetLevel() == 0 then
                print("什么也不干")
            else

                if self.m_machine:checkShowChooseBetView( ) then
                    self:setMaxBetId(1)
                end


            end

            self:runCsbAction("little_3",false,function(  )
                self:setVisible(false)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
            end)
        elseif name == "Button_Close" then

            self:runCsbAction("over",false,function(  )
                self:setVisible(false)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
            end)
        end
    end


end


return CandyBingoHightLowbetView