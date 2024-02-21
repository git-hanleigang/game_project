local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")

local CashOrConkDF12 = class("CashOrConkDF12",CashOrConkDFBase)

local CashOrConkDF12WheelAction = require("Pick.CashOrConkDF12WheelAction")


local BaseWheelNew = require "Levels.BaseReel.BaseWheelNew.lua"
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

function CashOrConkDF12:initUI(data)
    self:setDelegate(data.machine)
    self:resetMusicBg(true,CashOrConkPublicConfig["sound_COC_baseLineFrame_stage"..2])

    self:createCsbNode("CashOrConk/GameCashOrConk_DF12.csb")
    self:runCsbAction("idleframe3",true)

    
    self:addClick(self:findChild("Panel_1"))

    self.m_wheel = BaseWheelNew:create(
        {
            sectorCount = 12,
            rotateNode = self:findChild("zhuan"),
            accSpeed = 600,
            turnNum = 1,
            backDistance = 2,
            backTime = 0.3,
            doneFunc = function()
                self:onStopWheel()
            end,

        }
    )
    self:addChild(self.m_wheel)

    self._spine_btn = util_spineCreate("CashOrConk_DF12_zpanniu",true,true)
    self:findChild("Node_anniu"):addChild(self._spine_btn)
    util_spinePlayAction(self._spine_btn, "idleframe3",true)

    self._spine_btn2 = util_spineCreate("CashOrConk_DF12_zpanniu",true,true)
    self:findChild("Node_anniu_1"):addChild(self._spine_btn2)
    self._spine_btn2:hide()
    
    self._node_rewards = {}
    for i=1,12 do
        local node = self:createSingleRewardNode()
        self:findChild("fenqu_"..i):addChild(node)
        self._node_rewards[i] = node
    end

    local spine_eff1 = util_spineCreate("CashOrConk_DF12_zpbg",true,true)
    self:findChild("Node_bg"):addChild(spine_eff1)
    util_spinePlayAction(spine_eff1, "idleframe",true)

    local anim = util_createAnimation("CashOrConk_DF12_zpzj_tx.csb")
    anim:playAction("actionframe_cf",true)
    self:findChild("Node_zpzj"):addChild(anim)
    self._eff_reward = anim
    self:stopRewardEff()

    self._machine._npc:playDFNromal("1_2")

    self._machine._node_reward:plalIdle()
end

function CashOrConkDF12:createSingleRewardNode()
    local node = util_createAnimation("CashOrConk_DF12_fenqu.csb")

    return node
end

local nodeList = {
    "conk","jine","chengbei","jiangli"
}
function CashOrConkDF12:refreshSingleRewardNode(node,data)
    data = data or 1
    local totalBet = globalData.slotRunData:getCurTotalBet()
    for k,v in pairs(nodeList) do
        node:findChild(v):hide()
    end
    if type(data) == "string" then
        if data == "conk" then
            node:findChild("conk"):show()
        elseif data == "final" then
            node:findChild("jiangli"):show()
        else
            node:findChild("chengbei"):show()
            node:findChild("beishu_da"):setVisible(tonumber(data) >= 2)
            node:findChild("beishu_zhong"):setVisible(tonumber(data) >= 1.5 and tonumber(data) < 2)
            node:findChild("beishu_xiao"):setVisible(tonumber(data) < 1.5)
            if tonumber(data) > math.floor(tonumber(data)) then
                node:findChild("beishu_da"):getChildByName("Node_9"):show()
                node:findChild("beishu_da"):getChildByName("Node_8"):hide()
                node:findChild("beishu_da"):getChildByName("Node_9"):getChildByName("shuzi"):setString(string.sub(data,1,1))
                node:findChild("beishu_da"):getChildByName("Node_9"):getChildByName("shuzi_1"):setString(string.sub(data,3,3))
            else
                node:findChild("beishu_da"):getChildByName("Node_9"):hide()
                node:findChild("beishu_da"):getChildByName("Node_8"):show()
                node:findChild("beishu_da"):getChildByName("Node_8"):getChildByName("shuzi"):setString(data)
            end

            if tonumber(data) > math.floor(tonumber(data)) then
                node:findChild("beishu_zhong"):getChildByName("Node_9"):show()
                node:findChild("beishu_zhong"):getChildByName("Node_8"):hide()
                node:findChild("beishu_zhong"):getChildByName("Node_9"):getChildByName("shuzi"):setString(string.sub(data,1,1))
                node:findChild("beishu_zhong"):getChildByName("Node_9"):getChildByName("shuzi_1"):setString(string.sub(data,3,3))
            else
                node:findChild("beishu_zhong"):getChildByName("Node_9"):hide()
                node:findChild("beishu_zhong"):getChildByName("Node_8"):show()
                node:findChild("beishu_zhong"):getChildByName("Node_8"):getChildByName("shuzi"):setString(data)
            end

            if tonumber(data) > math.floor(tonumber(data)) then
                node:findChild("beishu_xiao"):getChildByName("Node_9"):show()
                node:findChild("beishu_xiao"):getChildByName("Node_8"):hide()
                node:findChild("beishu_xiao"):getChildByName("Node_9"):getChildByName("shuzi"):setString(string.sub(data,1,1))
                node:findChild("beishu_xiao"):getChildByName("Node_9"):getChildByName("shuzi_1"):setString(string.sub(data,3,3))
            else
                node:findChild("beishu_xiao"):getChildByName("Node_9"):hide()
                node:findChild("beishu_xiao"):getChildByName("Node_8"):show()
                node:findChild("beishu_xiao"):getChildByName("Node_8"):getChildByName("shuzi"):setString(data)
            end
        end
    else
        node:findChild("jine"):show()
        node:findChild("shuzi"):setString(data)
        node:findChild("jine_da"):setVisible((data*self._machine._node_reward._curCoinCount/totalBet) >= 15)
        node:findChild("jine_zhong"):setVisible((data*self._machine._node_reward._curCoinCount/totalBet) >= 5 and ((data*self._machine._node_reward._curCoinCount/totalBet) < 15))
        node:findChild("jine_xiao"):setVisible((data*self._machine._node_reward._curCoinCount/totalBet) < 5)
        local strCoin = util_formatCoinsLN(data*self._machine._node_reward._curCoinCount,3)
        for i=1,4 do
            local lb = node:findChild("jine_da"):getChildByName("m_lb_coins_"..i)
            if string.len(strCoin) >= i then
                local s1,s2,s3 = string.sub(strCoin,i,i)
                lb:setString(s1)
            end
            lb:setVisible(string.len(strCoin) >= i)

            local lb = node:findChild("jine_zhong"):getChildByName("m_lb_coins_"..i)
            if string.len(strCoin) >= i then
                local s1,s2,s3 = string.sub(strCoin,i,i)
                lb:setString(s1)
            end
            lb:setVisible(string.len(strCoin) >= i)

            local lb = node:findChild("jine_xiao"):getChildByName("m_lb_coins_"..i)
            if string.len(strCoin) >= i then
                local s1,s2,s3 = string.sub(strCoin,i,i)
                lb:setString(s1)
            end
            lb:setVisible(string.len(strCoin) >= i)
        end
    end
end

function CashOrConkDF12:beginWheel(index)
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_47)

    self._curIndex = index
    -- self._machine._npc:playAnim("actionframe4",false)
    self._spine_btn:hide()
    self._spine_btn2:show()
    util_spinePlayAction(self._spine_btn2, "actionframe_dj",false,function()
        self._spine_btn2:hide()
    end)
    self:levelPerformWithDelay(self,18/30,function()
        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_22)
        self:runCsbAction("move",false)
    end)
    self._idMusicRool = gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_55)
    self.m_wheel:startMove()
    self.m_wheel:setEndIndex(self._curIndex - 1)

    self:levelPerformWithDelay(self,7.6,function()
        -- self._machine._npc:playAnim("actionframe4",false)
    end)
end

function CashOrConkDF12:refreshStatus(is_connect)

    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    
    local roll1sec = {}

    if extra.roll1sec3 then
        roll1sec = extra.roll1sec3
    elseif extra.roll1sec2 then
        roll1sec = extra.roll1sec2
    elseif extra.roll1sec then
        roll1sec = extra.roll1sec
    end

    self._machine._node_reward:setCoinLabelAndCount(extra.bonus1_win)

    for i=1,12 do
        local node = self._node_rewards[i]
        self:refreshSingleRewardNode(node,roll1sec[i])
    end

    self:checkEndAndGotoNext(is_connect)
end

function CashOrConkDF12:checkEndAndGotoNext(is_connect)
    self._spine_btn:show(0)
    local status1,status2 = self:getSubStatus()
    local status_main = self:getMainStatus()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    if status2 == 1 then
        if status1 == 3 then
            self:createDirectView():goDirectNext(function()
                self._machine:changePickToState("4_0",function()
                    self:removeFromParent()
                end)
            end)
            -- self:showSurePop({
            --     coins = extra.bonus1_win,
            --     is3in1 = true
            -- },function(isContinue)
            --     if isContinue then
            --         self._machine:changePickToState("4_0",function()
            --             self:removeFromParent()
            --         end)
            --     else
            --         self:showDFEndView(extra.bonus1_win,"1_2")
            --     end
            -- end) 
        else
            self:levelPerformWithDelay(self,status_main == 1 and 4.5 or 0,function()
                self:showSurePop({
                    coins = extra.bonus1_win,
                    is2_3 = status1 == 2
                },function(isContinue)
                    if isContinue then
                        self._blockClick = false
                        self:addObservers()
                        self:levelPerformWithDelay(self,1,function()
                            self:sendData(1)
                        end)
                    else
                        self:showDFEndView(extra.bonus1_win,"1_2")
                    end
                end) 
            end)
        end
        self._blockClick = true
    elseif is_connect then
        self:levelPerformWithDelay(self,1,function()
            self:sendData(1)
        end)
    end
end

function CashOrConkDF12:getCurStageData(status)
    local status1,status2 = self:getSubStatus()
    status1 = status or status1
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local roll1sec = {}

    if status1 == 1 then
        roll1sec = extra.roll1sec
    elseif status1 == 2 then
        roll1sec = extra.roll1sec2
    elseif status1 == 3 then
        roll1sec = extra.roll1sec3
    end
    return roll1sec
end

function CashOrConkDF12:showRewardEff()
    self._eff_reward:show()
end

function CashOrConkDF12:stopRewardEff()
    self._eff_reward:hide()
end

function CashOrConkDF12:playConk()    
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_conk1)
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local spine = util_spineCreate("CashOrConk_DF12_conk",true,true)
    util_spinePlayAction(spine, "actionframe_conk",false,function()
        spine:hide()
        local time = self._machine._node_reward:playAddCoins(-math.floor(self._machine._node_reward._curCoinCount/2))
        self:levelPerformWithDelay(self,time/1000 + 1.5,function()
            self:showDFEndView(extra.bonus1_win,"1_2")
        end)
    end)
    self._machine:findChild("DF12_conk"):addChild(spine)
    self._machine._npc:playDFSpecial("1_2","12conk")
end

function CashOrConkDF12:showCelebrate()
    self._machine._npc:playAnim("actionframe5",false)
    -- local spine = util_spineCreate("CashOrConk_qingzhu",true,true)
    -- util_spinePlayAction(spine, "actionframe", false,function()
    --     self:levelPerformWithDelay(self,0.0001,function()
    --         spine:removeFromParent()
    --     end)
    -- end)
    -- local py = -380
    -- spine:setPositionY(py)
    -- self._machine:findChild("Node_bigwin"):addChild(spine)
end

function CashOrConkDF12:onStopWheel()
    if self._idMusicRool then
        gLobalSoundManager:stopAudio(self._idMusicRool)
        self._idMusicRool = nil
    end
    local status1,status2 = self:getSubStatus()

    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra

    local index = self._curIndex

    local data = self:getCurStageData()[index]
    
    if type(data) ~= "string" then
        self:showCelebrate()
    end

    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_27)
    self:showRewardEff()

    if data ~= "conk" and data ~= "final" then
        self:levelPerformWithDelay(self,15/30,function()
            local particle = util_createAnimation("CashOrConk_DF21_lizi.csb")
            particle:findChild("Particle_1"):resetSystem()
            particle:findChild("Particle_1"):setPositionType(0)
            particle:findChild("Particle_1"):setDuration(-1)
            particle:findChild("Particle_2"):resetSystem()
            particle:findChild("Particle_2"):setPositionType(0)
            particle:findChild("Particle_2"):setDuration(-1)
    
            local targetNode = self._machine:findChild("Node_top")
            targetNode:addChild(particle)
    
            local wp1 = self._node_rewards[index]:convertToWorldSpace(cc.p(0,0))
            wp1.y = wp1.y + 200
            local np1 = targetNode:convertToNodeSpace(cc.p(wp1))
    
            local wp2 = self._machine._node_reward:convertToWorldSpace(cc.p(0,0))
            local np2 = targetNode:convertToNodeSpace(cc.p(wp2))
    
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_39)
            particle:setPosition(cc.p(np1))
            particle:runAction(cc.Sequence:create(
                cc.MoveTo:create(27/60,np2),
                cc.CallFunc:create(function()
                    particle:findChild("Particle_1"):stopSystem()
                    particle:findChild("Particle_2"):stopSystem()
                end),
                cc.DelayTime:create(0.1),
                cc.CallFunc:create(function()
                    particle:removeFromParent()
                end)
            ))
        end)
    end
    

    self:runCsbAction("start2",false,function()
        self:runCsbAction("idle3",true)
        if data == "conk" then
            self:playConk()
        elseif data == "final" then
            self._machine:clearCurMusicBg()
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_51)
            self:checkEndAndGotoNext()
        else
            self:levelPerformWithDelay(self,0.6,function()
                local addCoins = 0
                if type(data) == "string" then
                    addCoins = self._machine._node_reward._curCoinCount * tonumber(data) - self._machine._node_reward._curCoinCount
                else
                    addCoins = data * self._machine._node_reward._curCoinCount
                end
                local time = self._machine._node_reward:playAddCoins(addCoins)
                self:levelPerformWithDelay(self,time/1000 + 0.5,function()
                    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_49)
                    self:runCsbAction("over",false,function()
                        self:stopRewardEff()
                        self:levelPerformWithDelay(self,0.5,function()
                            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_20)
                            local co
                            if status1 == 1 then
                                co = coroutine.create(function()
                                    local data_cur = self:getCurStageData(status1)
                                    local data_next = self:getCurStageData(status1 + 1)
        
                                    for i=1,12 do
                                        local data_c = data_cur[i]
                                        local data_n = data_next[i]
                                        if data_n == "conk" and data_c ~= "conk" then
                                            local anim = util_createAnimation("CashOrConk_DF12_fenqu_zpsx_tx.csb")
                                            self:findChild("fenqu_"..i):addChild(anim)
                                            anim:playAction("switch1",false,function()
                                                anim:removeFromParent()
                                            end)
                                            self:levelPerformWithDelay(self,0.3,function()
                                                self:refreshSingleRewardNode(self._node_rewards[i],data_n)
                                            end)
                                            self:levelPerformWithDelay(self,15/60,function()
                                                self._node_rewards[i]:playAction("actionframe")
                                            end)
                                        end
                                    end
                                    self:levelPerformWithDelay(self,1,function()
                                        util_resumeCoroutine(co)        
                                    end)
                                    coroutine.yield()
        
                                    for i=1,12 do
                                        local data_c = data_cur[i]
                                        local data_n = data_next[i]
                                        if data_c ~= data_n and data_n ~= "conk" then
                                            local anim = util_createAnimation("CashOrConk_DF12_fenqu_zpsx_tx.csb")
                                            self:findChild("fenqu_"..i):addChild(anim)
                                            anim:playAction("switch1",false,function()
                                                anim:removeFromParent()
                                            end)
                                            self:levelPerformWithDelay(self,0.3,function()
                                                self:refreshSingleRewardNode(self._node_rewards[i],data_n)
                                            end)
                                            self:levelPerformWithDelay(self,15/60,function()
                                                self._node_rewards[i]:playAction("actionframe")
                                            end)
                                        end
                                    end
                                    self:levelPerformWithDelay(self,3,function()
                                        util_resumeCoroutine(co)        
                                    end)
                                    coroutine.yield()
    
                                    self:checkEndAndGotoNext()
                                end)
                            else
                                co = coroutine.create(function()
                                    local data_cur = self:getCurStageData(status1)
                                    local data_next = self:getCurStageData(status1 + 1)
        
                                    for i=1,12 do
                                        local data_c = data_cur[i]
                                        local data_n = data_next[i]
                                        if data_c ~= data_n then
                                            local anim = util_createAnimation("CashOrConk_DF12_fenqu_zpsx_tx.csb")
                                            self:findChild("fenqu_"..i):addChild(anim)
                                            anim:playAction("switch2",false,function()
                                                anim:removeFromParent()
                                            end)
                                            self:levelPerformWithDelay(self,0.3,function()
                                                self:refreshSingleRewardNode(self._node_rewards[i],data_n)
                                            end)
                                            self:levelPerformWithDelay(self,15/60,function()
                                                self._node_rewards[i]:playAction("actionframe")
                                            end)
                                        end
                                    end
                                    self:levelPerformWithDelay(self,3,function()
                                        util_resumeCoroutine(co)        
                                    end)
                                    coroutine.yield()                                
    
                                    self:checkEndAndGotoNext()
                                end)
                            end
                            
                            util_resumeCoroutine(co)
                        end)
                    end)
                end)
            end)
        end
    end)

    if data == "conk" then
        self:levelPerformWithDelay(self,2,function()
            self:runCsbAction("over2",false)
            self:stopRewardEff()
        end)
    end
end

--默认按钮监听回调
function CashOrConkDF12:clickFunc(sender)
    if self._blockClick then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()

    
end

function CashOrConkDF12:featureResultCallFun(param)
    CashOrConkDF12.super.featureResultCallFun(self,param)
    local spinData = param[2]
    if spinData.action == "SPIN" then
        self:removeFromParent()
        return
    end
    if param[1] == true then
        local selfData = self._machine.m_runSpinResultData.p_selfMakeData
        local extra = selfData.bonus.extra
        local index
        if extra.roll3_index then
            index = extra.roll3_index
        elseif extra.roll2_index then
            index = extra.roll2_index
        elseif extra.roll1_index then
            index = extra.roll1_index
        end
        self:beginWheel(index)
        self._blockClick = true
    else

    end
end

return CashOrConkDF12