local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local CashOrConkDF22 = class("CashOrConkDF22",CashOrConkDFBase)
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

local MAX_SELECT = 16

function CashOrConkDF22:initUI(data)
    self:setDelegate(data.machine)
    self:resetMusicBg(true,CashOrConkPublicConfig["sound_COC_baseLineFrame_stage"..2])
    self:createCsbNode("CashOrConk/GameCashOrConk_DF22.csb")

    self._list_select = {}
    for i=1,MAX_SELECT do
        local spine = util_createAnimation("CashOrConk_DF22_fenqu.csb")
        self:findChild("fenqu_"..i):addChild(spine)
        self._list_select[i] = spine
        local act = cc.Sequence:create(
            cc.DelayTime:create(math.random(1,14)),
            cc.CallFunc:create(function()
                -- util_spinePlayAction(spine, "xiangzi_idle2",true)
            end)
        )
        spine:runAction(act)
        -- util_spinePlayAction(spine, "xiangzi_idle",true)

        self:addClick(self:findChild("touch_"..i))
    end


    local spine_eff1 = util_spineCreate("Socre_CashOrConk_DF22",true,true)
    self:findChild("Node_spine"):addChild(spine_eff1)
    util_spinePlayAction(spine_eff1, "idle",true)

    local spine_eff1 = util_spineCreate("Socre_CashOrConk_DF22",true,true)
    self:findChild("Node_spine2"):addChild(spine_eff1)
    util_spinePlayAction(spine_eff1, "idle2",true)

    self._machine._npc:playDFNromal("2_2")

    self:addClick(self:findChild("touch"))

    self._machine._node_reward:plalIdle()
end

function CashOrConkDF22:startWheel(index_get)
    self._blockClick = true

    local totalBet = globalData.slotRunData:getCurTotalBet()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local bonus2seq = extra.bonus2seq       

    local status1,status2 = self:getSubStatus()

    local roll2sec = self:getCurStageData()

    local data_res = roll2sec[index_get]
 
    local index = index_get
    local roolCnt = 16 * 1
    local total = roolCnt + index
    local i1 = total - math.floor(total / 6)
    local maxSpeed = 0.2
    local actions = {}
    local i = 1
    local ip = 0
    local iLow = 1
    local totalDelay = 0

    local nodeLast = nil

    while i <= total do
        local node = self._list_select[i%16 == 0 and 16 or i%16]
        if not node then
            return
        end

        if i <= i1 then
            totalDelay = 0.020 + math.min(maxSpeed,maxSpeed/i1 * i)
        else
            iLow = iLow + 1
            totalDelay = maxSpeed + iLow * 0.065
        end
        print(totalDelay)
        actions[#actions + 1] = cc.DelayTime:create(totalDelay)
        actions[#actions + 1] = cc.CallFunc:create(function()
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_10)
            node:playAction("actionframe",false)
            ip = ip + 1
            if ip >= i1 and nodeLast then
                nodeLast:playAction("idle",false)
            end
            nodeLast = node
            self:levelPerformWithDelay(node,12/60,function()
                if ip ~= total then
                    if ip >= i1 then
                        self:levelPerformWithDelay(node,(0.020 + math.min(maxSpeed,maxSpeed/i1 * ip)),function()
                            -- node:playAction("idle",false)
                        end)
                    else
                        node:playAction("idle",false)
                        self:levelPerformWithDelay(node,(0.020 + math.min(maxSpeed,maxSpeed/i1 * ip)) * 1,function()
                            
                        end)
                    end
                end
            end)
        end)

        if i == total then
            actions[#actions + 1] = cc.DelayTime:create(0.5 + 12/60)
            actions[#actions + 1] = cc.CallFunc:create(function()
                if node:getChildByName("waitNode") then
                    node:getChildByName("waitNode"):stopAllActions()
                end
                gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_3)
                node:playAction("actionframe_cf",false,function()
                    node:playAction("actionframe_cf2",true)
                end)
                node:getParent():setLocalZOrder(0xff)
                self:levelPerformWithDelay(self,30/60,function()
                    if data_res == "conk" then
                        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_42)
                        self:levelPerformWithDelay(node,1.5,function()
                            node:playAction("actionframe_cf2",true)
                        end)
                        local spine_dog = util_spineCreate("Socre_CashOrConk_dog",true,true)
                        util_spinePlayAction(spine_dog, "actionframe_conk",false,function()
                            spine_dog:hide()
                            self._machine._node_reward:playAddCoins(-math.floor(self._machine._node_reward._curCoinCount/2))
                            self:levelPerformWithDelay(self,2.5,function()
                                self:showDFEndView(extra.bonus2_win,"2_2")
                            end)
                        end)
                        self._machine:findChild("DF22_conk"):addChild(spine_dog)
                        self._machine._npc:playDFSpecial("2_2","22conk")
                    elseif data_res == "final" then
                        self._machine:clearCurMusicBg()
                        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_51)
                        self:checkEndAndGotoNext()
                    else
                        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_6)
                        local addCoins = 0
                        if type(data_res) == "string" then
                            addCoins = self._machine._node_reward._curCoinCount * tonumber(data_res) - self._machine._node_reward._curCoinCount
                        else
                            addCoins = data_res * self._machine._node_reward._curCoinCount
                        end
                        local particle = util_createAnimation("CashOrConk_DF21_lizi.csb")
                        particle:findChild("Particle_1"):resetSystem()
                        particle:findChild("Particle_1"):setPositionType(0)
                        particle:findChild("Particle_1"):setDuration(-1)
                        particle:findChild("Particle_2"):resetSystem()
                        particle:findChild("Particle_2"):setPositionType(0)
                        particle:findChild("Particle_2"):setDuration(-1)
            
                        local targetNode = self._machine:findChild("Node_top")
                        targetNode:addChild(particle)
            
                        local wp1 = node:convertToWorldSpace(cc.p(0,0))
                        local np1 = targetNode:convertToNodeSpace(cc.p(wp1))
            
                        local wp2 = self._machine._node_reward:convertToWorldSpace(cc.p(0,0))
                        local np2 = targetNode:convertToNodeSpace(cc.p(wp2))
            
                        particle:setPosition(cc.p(np1))
                        particle:runAction(cc.Sequence:create(
                            cc.MoveTo:create(27/60,np2),
                            cc.CallFunc:create(function()
                                particle:findChild("Particle_1"):stopSystem()
                                particle:findChild("Particle_2"):stopSystem()
                                local time = self._machine._node_reward:playAddCoins(addCoins)
                                self:levelPerformWithDelay(self,time/1000,function()
                                    self:showCelebrate()
                                end)
                                time = time/1000 + 0.5 + 0.5
                                self:levelPerformWithDelay(self,time,function()
                                    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_52)
                                    local co
                                    if status1 == 1 then
                                        node:playAction("idle",true)
                                        co = coroutine.create(function()
                                            local data_cur = self:getCurStageData(status1)
                                            local data_next = self:getCurStageData(status1 + 1)
                
                                            for i=1,16 do
                                                local data_c = data_cur[i]
                                                local data_n = data_next[i]
                                                if data_n == "conk" and data_c ~= "conk" then
                                                    local anim = util_spineCreate("Socre_CashOrConk_DF22",true,true)
                                                    util_spinePlayAction(anim, "switch",false,function()end)
                                                    self:findChild("fenqu_"..i):addChild(anim)
                                                    self:levelPerformWithDelay(self,8/30,function()
                                                        self._list_select[i]:playAction("switch",false)
                                                    end)
                                                    self:levelPerformWithDelay(self,6/30,function()
                                                        self:refreshSingleRewardNode(self._list_select[i],data_n)
                                                    end)
                                                end
                                            end
                                            self:levelPerformWithDelay(self,1.5,function()
                                                util_resumeCoroutine(co)        
                                            end)
                                            coroutine.yield()
                
                                            for i=1,16 do
                                                local data_c = data_cur[i]
                                                local data_n = data_next[i]
                                                if data_c ~= data_n and data_n ~= "conk" then
                                                    local anim = util_spineCreate("Socre_CashOrConk_DF22",true,true)
                                                    util_spinePlayAction(anim, "switch",false,function()end)
                                                    self:findChild("fenqu_"..i):addChild(anim)
                                                    self:levelPerformWithDelay(self,8/30,function()
                                                        self._list_select[i]:playAction("switch",false)
                                                    end)
                                                    self:levelPerformWithDelay(self,6/30,function()
                                                        self:refreshSingleRewardNode(self._list_select[i],data_n)
                                                    end)
                                                end
                                            end
                                            self:levelPerformWithDelay(self,2.5,function()
                                                util_resumeCoroutine(co)        
                                            end)
                                            coroutine.yield()
            
                                            self:checkEndAndGotoNext()
                                            self._blockClick = false
                                        end)
                                    else
                                        co = coroutine.create(function()
                                            local data_cur = self:getCurStageData(status1)
                                            local data_next = self:getCurStageData(status1 + 1)
                
                                            for i=1,16 do
                                                local data_c = data_cur[i]
                                                local data_n = data_next[i]
                                                if data_c ~= "conk" then
                                                    local anim = util_spineCreate("Socre_CashOrConk_DF22",true,true)
                                                    util_spinePlayAction(anim, "switch2",false,function()end)
                                                    self:findChild("fenqu_"..i):addChild(anim)
                                                    self:levelPerformWithDelay(self,8/30,function()
                                                        self._list_select[i]:playAction("switch",false)
                                                    end)
                                                    self:levelPerformWithDelay(self,6/30,function()
                                                        self:refreshSingleRewardNode(self._list_select[i],data_n)
                                                    end)
                                                end
                                            end
                                            self:levelPerformWithDelay(self,2.5,function()
                                                util_resumeCoroutine(co)        
                                            end)
                                            coroutine.yield()                                
            
                                            node:playAction("idle",true)
                                            self:checkEndAndGotoNext()
                                            self._blockClick = false
                                        end)
                                    end
                                    
                                    util_resumeCoroutine(co)
                                end)
                            end),
                            cc.DelayTime:create(0.1),
                            cc.CallFunc:create(function()
                                particle:removeFromParent()
                            end)
                        ))
                    end                    
                end)
            end)
        end
        
        i = i + 1
    end

    self:runAction(cc.Sequence:create(actions))
end

function CashOrConkDF22:showCelebrate()
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

function CashOrConkDF22:checkEndAndGotoNext(is_connect)
    -- do return end
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
            --     coins = extra.bonus2_win,
            --     is3in1 = true
            -- },function(isContinue)
            --     if isContinue then
            --         self._machine:changePickToState("4_0",function()
            --             self:removeFromParent()
            --         end)
            --     else
            --         self:showDFEndView(extra.bonus2_win,"2_2")
            --     end
            -- end) 
        else
            self:levelPerformWithDelay(self,status_main == 1 and (is_connect and 1 or 4.5) or 0,function()
                self:showSurePop({
                    coins = extra.bonus2_win,
                    is2_3 = status1 == 2
                },function(isContinue)
                    if isContinue then
                        self:addObservers()
                        self:refreshStatus()
                        self:setLockClick(false)
                        self:levelPerformWithDelay(self,1,function()
                            self:sendData(1)
                        end)
                    else
                        self:showDFEndView(extra.bonus2_win,"2_2")
                    end
                end) 
            end)
            self:setLockClick(true)
        end
    elseif is_connect then
        self:levelPerformWithDelay(self,1,function()
            self:sendData(1)
        end)
    end
end

function CashOrConkDF22:refreshStatus(is_connect)
    local status_main = self:getMainStatus()
    local status1,status2 = self:getSubStatus()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local bonus2reward = extra.bonus2reward
    local roll2sec = self:getCurStageData((status1 ~= 3 and status2 == 1) and status1 + 1 or status1)
    if status_main == 1 then
        roll2sec = self:getCurStageData(1)
    end
    

    for i=1,MAX_SELECT do
        local node = self._list_select[i]
        self:refreshSingleRewardNode(node,roll2sec[i])
    end

    self._machine._node_reward:setCoinLabelAndCount(extra.bonus2_win)

    self:checkEndAndGotoNext(is_connect)
end

local nodeList = {
    "conk","jine","chengbei","jiangli"
}
function CashOrConkDF22:refreshSingleRewardNode(node,data)
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
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
            node:findChild("beishu_da"):setString("X"..data):setVisible(tonumber(data) >= 2)
            local info = {label = node:findChild("beishu_da"), sx = 0.49,sy = 0.49}
            self:updateLabelSize(info, 239)

            node:findChild("beishu_zhong"):setString("X"..data):setVisible(tonumber(data) >= 1.5 and tonumber(data) < 2)
            local info = {label = node:findChild("beishu_zhong"), sx = 0.48,sy = 0.48}
            self:updateLabelSize(info, 239)

            node:findChild("beishu_xiao"):setString("X"..data):setVisible(tonumber(data) < 1.5)
            local info = {label = node:findChild("beishu_xiao"), sx = 0.54,sy = 0.54}
            self:updateLabelSize(info, 207)
        end
    else
        node:findChild("jine"):show()
        node:findChild("m_lb_coins_da"):setString(util_formatCoinsLN(data*extra.bonus2_win,3)):setVisible((data*extra.bonus2_win/totalBet) >= 15)
        local info = {label = node:findChild("m_lb_coins_da"), sx = 0.50,sy = 0.50}
        self:updateLabelSize(info, 247)

        node:findChild("m_lb_coins_zhong"):setString(util_formatCoinsLN(data*extra.bonus2_win,3)):setVisible((data*extra.bonus2_win/totalBet) >= 5 and (data*extra.bonus2_win/totalBet) < 15)
        local info = {label = node:findChild("m_lb_coins_zhong"), sx = 0.49,sy = 0.49}
        self:updateLabelSize(info, 247)

        node:findChild("m_lb_coins_xiao"):setString(util_formatCoinsLN(data*extra.bonus2_win,3)):setVisible((data*extra.bonus2_win/totalBet) < 5)
        local info = {label = node:findChild("m_lb_coins_xiao"), sx = 0.53,sy = 0.53}
        self:updateLabelSize(info, 223)
    end
end

function CashOrConkDF22:clickFunc(sender)
    if self._blockClick then
        return
    end

    local name = sender:getName()
    local tag = sender:getTag()

    -- self:sendData(1)
    -- self:startWheel(math.random(1,16))
end

function CashOrConkDF22:featureResultCallFun(param)
    CashOrConkDF22.super.featureResultCallFun(self,param)
    local spinData = param[2]
    if spinData.action == "SPIN" then
        self:removeFromParent()
        return
    end
    if param[1] == true then
        local selfData = self._machine.m_runSpinResultData.p_selfMakeData
        local extra = selfData.bonus.extra
        local bonus2seq = extra.bonus2seq        

        local index
        if extra.roll23_index then
            index = extra.roll23_index
        elseif extra.roll22_index then
            index = extra.roll22_index
        elseif extra.roll21_index then
            index = extra.roll21_index
        end
        self:startWheel(index)
    else

    end
end

function CashOrConkDF22:getCurStageData(status)
    local status1,status2 = self:getSubStatus()
    status1 = status or status1
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local roll2sec
    if status1 == 1 then
        roll2sec = extra.roll2sec
    elseif status1 == 2 then
        roll2sec = extra.roll2sec2copy
    elseif status1 == 3 then
        roll2sec = extra.roll2sec3
    end
    return roll2sec
end

return CashOrConkDF22