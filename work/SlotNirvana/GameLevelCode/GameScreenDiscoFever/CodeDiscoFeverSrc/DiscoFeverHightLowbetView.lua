---
--xcyy
--2018年5月23日
--DiscoFeverHightLowbetView.lua

local DiscoFeverHightLowbetView = class("DiscoFeverHightLowbetView",util_require("base.BaseView"))
DiscoFeverHightLowbetView.m_machine = nil
DiscoFeverHightLowbetView.m_MachineBetDate = nil
DiscoFeverHightLowbetView.m_canClick = false

function DiscoFeverHightLowbetView:initUI()

    self:createCsbNode("DiscoFever/ChooseBetView.csb")



end


function DiscoFeverHightLowbetView:onEnter()


end

function DiscoFeverHightLowbetView:initMachineBetDate(data)

    self.m_canClick = false
    self:runCsbAction("start",false,function(  )
        self.m_canClick = true
        self:runCsbAction("idle",true)
    end)

    -- data.minBet = self:getMinBet( )
    -- data.betLevel = self:getBetLevel()

    self.m_MachineBetDate = data

end

function DiscoFeverHightLowbetView:initMachine(machine)

    self.m_machine = machine

end



function DiscoFeverHightLowbetView:onExit()
    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)

end

--默认按钮监听回调
function DiscoFeverHightLowbetView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.m_canClick == true then

        self.m_canClick = false

        if name == "high_btn" then
            if self.m_MachineBetDate.betLevel == 1 then
                print("什么也不干")
            else
                if self.m_machine:checkShowChooseBetView( ) then
                    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
                    for i=1,#betList do
                        local betData = betList[i]
                        if betData.p_totalBetValue >= self.m_MachineBetDate.minBet then

                            globalData.slotRunData.iLastBetIdx =   betData.p_betId

                            break
                        end
                    end

                    -- 设置bet index
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
                end


            end
            self:runCsbAction("over",false,function(  )
                self:setVisible(false)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
            end)

        elseif name == "low_btn" then
            if self.m_MachineBetDate.betLevel == 0 then
                print("什么也不干")
            else

                if self.m_machine:checkShowChooseBetView( ) then
                    local betList = globalData.slotRunData.machineData:getMachineCurBetList()
                    for i = #betList ,1 ,-1 do
                        local betData = betList[i]
                        if betData.p_totalBetValue < self.m_MachineBetDate.minBet then

                            globalData.slotRunData.iLastBetIdx =   betData.p_betId

                            break
                        end
                    end

                    -- 设置bet index
                    gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
                end


            end

            self:runCsbAction("over",false,function(  )
                self:setVisible(false)
                gLobalNoticManager:postNotification(ViewEventType.NOTIFY_CLOSE_BETSELECT_VIEW)
            end)
        end
    end


end


return DiscoFeverHightLowbetView