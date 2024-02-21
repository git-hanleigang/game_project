---
--xcyy
--2018年5月23日
--DiscoFeverBetLogoView.lua

local DiscoFeverBetLogoView = class("DiscoFeverBetLogoView",util_require("base.BaseView"))


function DiscoFeverBetLogoView:initUI(machine)

    self.m_machine = machine

    self:createCsbNode("DiscoFever_Bet_logo.csb")

    -- self:runCsbAction("actionframe") -- 播放时间线
    self:findChild("btn_click") -- 获得子节点
    self:addClick(self:findChild("btn_click")) -- 非按钮节点得手动绑定监听




end


function DiscoFeverBetLogoView:onEnter()
 

end

function DiscoFeverBetLogoView:showAdd()
    
end
function DiscoFeverBetLogoView:onExit()
 
end

--默认按钮监听回调
function DiscoFeverBetLogoView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "btn_click" then

       if self.m_machine then
            if self.m_machine:checkShowChooseBetView( ) then
                --self.m_machine:showHightLowBetView( )

                if self.m_machine:getBetLevel() == 1 then
                    print("什么也不干")
                else    
                    if self.m_machine:checkShowChooseBetView( ) then
                        local betList = globalData.slotRunData.machineData:getMachineCurBetList()
                        for i=1,#betList do
                            local betData = betList[i]
                            if betData.p_totalBetValue >= self.m_machine:getMinBet( ) then
            
                                globalData.slotRunData.iLastBetIdx =   betData.p_betId
            
                                break
                            end
                        end
                        
                        -- 设置bet index
                        gLobalNoticManager:postNotification(ViewEventType.NOTIFY_UPDATE_BETIDX)
                    end
                    
        
                end

            end
       end 
        
    end

end


return DiscoFeverBetLogoView