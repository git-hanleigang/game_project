local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"
local CashOrConkDF21 = class("CashOrConkDF21",CashOrConkDFBase)

local MAX_SELECT = 7

function CashOrConkDF21:initUI(data)
    self:setDelegate(data.machine)
    self:resetMusicBg(true,CashOrConkPublicConfig["sound_COC_baseLineFrame_stage"..1])
    self:createCsbNode("CashOrConk/GameCashOrConk_DF21.csb")
    self:runCsbAction("idle2",true)
    self._machine._npc:playDFNromal("2_1")
    self._list_select = {}
    for i=1,MAX_SELECT do
        local spine = util_spineCreate("Socre_CashOrConk_DF21",true,true)
        self:findChild("xuanxiang_"..i):addChild(spine)
        self._list_select[i] = spine
        local act = cc.Sequence:create(
            cc.DelayTime:create(math.random(1,14)),
            cc.CallFunc:create(function()
                util_spinePlayAction(spine, "xiangzi_idle2",false)
            end)
        )
        act = cc.RepeatForever:create(act)
        spine:runAction(act)
        util_spinePlayAction(spine, "xiangzi_idle",true)

        self:addClick(self:findChild("touch_"..i))
    end

    self._list_coin = {}
    for i=1,5 do
        local node_coin = util_createAnimation("CashOrConk_DF21_jinelan.csb")
        self:findChild("jinelan_"..i):addChild(node_coin)
        self._list_coin[i] = node_coin

        local node_no = util_createAnimation("CashOrConk_DF21_jinelan_kuangche.csb")
        node_coin:findChild("kuangche"):addChild(node_no)
        for k,v in pairs(node_no:findChild("shuzi"):getChildren()) do
            v:setVisible(v:getName() == tostring(i))
        end
        node_coin.node_no = node_no
    end
end

function CashOrConkDF21:refreshStatus()
    local selfData = clone(self._machine.m_runSpinResultData.p_selfMakeData)
    local extra = selfData.bonus.extra
    local bonus2reward = extra.bonus2reward
    local bonus2seq = extra.bonus2seq or {}
    
    for i,v in ipairs(bonus2seq or {}) do
        local index = v[1]
        local spine = self._list_select[index]
        spine:stopAllActions()
        util_spinePlayAction(spine, "che_idle",true)
    end
    
    for i=1,5 do
        local coins = extra.bonus2reward[i]
        local node_coin = self._list_coin[i]
        node_coin:findChild("m_lb_coins_5"):setString(util_formatCoins(coins,20))
        if #bonus2seq == 5 then
            node_coin:playAction(i == #bonus2seq and "hong_idle" or "yaan_idle",i == #bonus2seq)
        else
            if i == #bonus2seq then
                node_coin:playAction("hong_idle")
                node_coin:getParent():setLocalZOrder(0xffff)
                node_coin:playAction("actionframe_dc",true)
            elseif i < #bonus2seq then
                node_coin:playAction("yaan_idle")
            else
                node_coin:playAction("lan_idle")
            end
        end
        local info1 = {label = node_coin:findChild("m_lb_coins_5"), sx = 0.94,sy = 0.94}
        self:updateLabelSize(info1, 367)
    end

    self:checkEndAndGotoNext()
end

function CashOrConkDF21:checkEndAndGotoNext()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local bonus2reward = extra.bonus2reward
    local bonus2seq = extra.bonus2seq or {}
    if (#bonus2seq > 0 and bonus2seq[#bonus2seq][2] == "game_over") or (#bonus2seq == 5 and bonus2seq[#bonus2seq][2] == "continue") then
        self._blockClick = true
        self:levelPerformWithDelay(self,1,function()
            self._machine:changePickToState("2_2",function()
                self:removeFromParent()
            end)
        end)
        -- self:showSurePop({
        --     coins = extra.bonus2_win
        -- },function(isContinue)
        --     if isContinue then
        --         self._machine:changePickToState("2_2",function()
        --             self:removeFromParent()
        --         end)
        --     else
        --         self:showDFEndView(extra.bonus2_win,"2_1")
        --     end
        -- end) 
    else
        self:levelPerformWithDelay(self,1,function()
            self:setLockClick(false)
        end)
    end
end

function CashOrConkDF21:playPick(click_index,is_boom,get_index)
    self._blockClick = true
    local selfData = clone(self._machine.m_runSpinResultData.p_selfMakeData)
    local extra = selfData.bonus.extra
    local bonus2seq = extra.bonus2seq or {}

    local spine = self._list_select[click_index]
    spine:stopAllActions()

    local is_end = is_boom or (not is_boom and get_index == 5)

    self:levelPerformWithDelay(spine,10/30,function()
        if not is_boom then
            local particle = util_createAnimation("CashOrConk_DF21_lizi.csb")
            particle:findChild("Particle_1"):resetSystem()
            particle:findChild("Particle_1"):setPositionType(0)
            particle:findChild("Particle_1"):setDuration(-1)
            particle:findChild("Particle_2"):resetSystem()
            particle:findChild("Particle_2"):setPositionType(0)
            particle:findChild("Particle_2"):setDuration(-1)

            local targetNode = self._machine:findChild("Node_top")
            targetNode:addChild(particle)

            local wp1 = self:findChild("xuanxiang_"..click_index):convertToWorldSpace(cc.p(0,0))
            local np1 = targetNode:convertToNodeSpace(cc.p(wp1))

            local node = self:findChild(string.format("jinelan_%d",get_index))
            local wp2 = node:convertToWorldSpace(cc.p(0,0))
            local np2 = targetNode:convertToNodeSpace(cc.p(wp2))

            local index = #bonus2seq
            local node_coin = self._list_coin[index]
            node_coin:playAction("dc_1",false)
            if index > 1 then
                self._list_coin[index - 1]:playAction("yaan",false)
                if self._list_coin[index - 1]:getChildByName("waitNode") then
                    self._list_coin[index - 1]:getChildByName("waitNode"):stopAllActions()
                end
            end

            particle:setPosition(cc.p(np1))
            particle:runAction(cc.Sequence:create(
                cc.MoveTo:create(27/60,np2),
                cc.CallFunc:create(function()
                    node_coin:getParent():setLocalZOrder(0xffff)
                    node_coin:playAction("actionframe_dc",true)
                    node_coin.node_no:playAction("sf",false)
                    
                    particle:findChild("Particle_1"):stopSystem()
                    particle:findChild("Particle_2"):stopSystem()
                    self._blockClick = false
                    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_40)
                end),
                cc.DelayTime:create(0.1),
                cc.CallFunc:create(function()
                    particle:removeFromParent()
                end)
            ))
        end
    end)

    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_64)
    if is_boom then
        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_37)
    end
    
    util_spinePlayAction(spine, is_boom and "actionframe_dj_zhadan" or "actionframe_dj_che",false,function()
        if is_end then
            local other2 = extra.other2
            local index_other2 = 1
            local index_reward = bonus2seq[#bonus2seq][2] == "continue" and #bonus2seq or #bonus2seq - 1
            for i=1,MAX_SELECT do
                local isHave = false
                for k,v in pairs(bonus2seq) do
                    if v[1] == i then
                        isHave = true
                    end
                end
                if not isHave then
                    self._list_select[i]:stopAllActions()
                    util_spinePlayAction(self._list_select[i], other2[index_other2] ~= "game_over" and "actionframe_che_an" or "actionframe_zhadan_an",false)
                    index_other2 = index_other2 + 1
                end
            end

            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_43)

            for i=1,5 do
                local node_coin = self._list_coin[i]
                if i > index_reward then
                    node_coin:playAction("yaan")
                end
            end
            self:levelPerformWithDelay(self,1,function()
                gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_5)
                local node_coin = self._list_coin[index_reward]
                node_coin:getParent():setLocalZOrder(0xffff)
                node_coin:playAction("actionframe_cf",true)
                local anim = util_createAnimation("CashOrConk_DF21_jinelan_tx.csb")
                anim:playAction("idle",true,function()

                end)
                node_coin:findChild("Node_tx"):addChild(anim)
                self._machine._npc:playAnim("actionframe4",false)
                self._machine._node_reward:setCoinLabelAndCount(0)
                self:levelPerformWithDelay(self,15/30,function()
                    self._machine._node_reward:playStart(function()
                        anim:removeFromParent()
                        node_coin:playAction("fly",false)
                        self:levelPerformWithDelay(self,10/60,function()
                            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_19)
                            local particle = util_createAnimation("CashOrConk_DF21_lizi.csb")
                            particle:findChild("Particle_1"):resetSystem()
                            particle:findChild("Particle_1"):setPositionType(0)
                            particle:findChild("Particle_1"):setDuration(-1)
                            particle:findChild("Particle_2"):resetSystem()
                            particle:findChild("Particle_2"):setPositionType(0)
                            particle:findChild("Particle_2"):setDuration(-1)
                    
                            local targetNode = self._machine:findChild("Node_top")
                            targetNode:addChild(particle)
                    
                            local wp1 = self:findChild(string.format("jinelan_%d",index_reward)):convertToWorldSpace(cc.p(0,0))
                            local np1 = targetNode:convertToNodeSpace(cc.p(wp1))
                    
                            local node = self._machine._node_reward
                            local wp2 = node:convertToWorldSpace(cc.p(0,0))
                            local np2 = targetNode:convertToNodeSpace(cc.p(wp2))
                            np2.y = np2.y - 10
                    
                            particle:setPosition(cc.p(np1))
                            particle:runAction(cc.Sequence:create(
                                cc.MoveTo:create(27/60,np2),
                                cc.CallFunc:create(function()
                                    particle:findChild("Particle_1"):stopSystem()
                                    particle:findChild("Particle_2"):stopSystem()
                                    self._machine._node_reward:playAddCoins(extra.bonus2reward[index_reward])
                                    self:levelPerformWithDelay(self,2,function()
                                        self:checkEndAndGotoNext()
                                    end)
                                end),
                                cc.DelayTime:create(0.1),
                                cc.CallFunc:create(function()
                                    particle:removeFromParent()
                                end)
                            ))
                        end)
                    end)
                end)
            end)
        end
    end)
end

function CashOrConkDF21:clickFunc(sender)
    if self._blockClick or self._is_end then
        return
    end

    local selfData = clone(self._machine.m_runSpinResultData.p_selfMakeData)
    local extra = selfData.bonus.extra
    local bonus2seq = extra.bonus2seq

    local name = sender:getName()
    local tag = sender:getTag()
    
    local name_parent = sender:getParent():getName()

    local list_str = string.split(name_parent,"_")

    local index = tonumber(list_str[2])

    for k,v in pairs(bonus2seq or {}) do
        if v[1] == index then
            return
        end
    end

    -- self:playPick(1,true,2)
    self:sendData(index)
end

function CashOrConkDF21:featureResultCallFun(param)
    CashOrConkDF21.super.featureResultCallFun(self,param)
    local spinData = param[2]
    if spinData.action == "SPIN" then
        self:removeFromParent()
        return
    end
    if param[1] == true then
        local selfData = clone(self._machine.m_runSpinResultData.p_selfMakeData)
        local extra = selfData.bonus.extra
        local bonus2seq = extra.bonus2seq
        
        self:playPick(self._lastSendData,bonus2seq[#bonus2seq][2] == "game_over",#bonus2seq)
        local is_boom = bonus2seq[#bonus2seq][2] == "game_over"
        local get_index = #bonus2seq
        local is_end = is_boom or (not is_boom and get_index == 5)
        if is_end then
            self._blockClick = true
            self._is_end = true
        end
    else

    end
end


return CashOrConkDF21