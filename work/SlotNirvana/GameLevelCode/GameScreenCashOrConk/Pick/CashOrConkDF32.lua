local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local CashOrConkDF32 = class("CashOrConkDF32",CashOrConkDFBase)
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

local MAX_SELECT = 5

function CashOrConkDF32:initUI(data)
    self:setDelegate(data.machine)
    self:resetMusicBg(true,CashOrConkPublicConfig["sound_COC_baseLineFrame_stage"..2])
    self:createCsbNode("CashOrConk/GameCashOrConk_DF32.csb")

    self._list_select = {}
    for i=1,MAX_SELECT do
        local spine = self:createSpine()
        
        self:findChild("xuanxiang_"..i):addChild(spine)
        util_spinePlayAction(spine, "idle",false)
        self._list_select[i] = spine

        self:addClick(self:findChild("touch"..i))

        self:runSinleSpineRandIdle(i)
    end

    

    self._machine._npc:playDFNromal("3_2")

    self._machine._node_reward:plalIdle()
end


function CashOrConkDF32:refreshStatus()
    

    local status1,status2 = self:getSubStatus()

    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    
    local extra = selfData.bonus.extra

    local bonus3roll = extra.bonus3roll

    self._machine._node_reward:setCoinLabelAndCount(extra.bonus3_win)
end

function CashOrConkDF32:runSinleSpineRandIdle(index)
    local spine = self._list_select[index]
    spine:stopActionByTag(6)
    spine.node:hide()

    local act = cc.Sequence:create(
        cc.DelayTime:create(math.random(2,6)),
        cc.CallFunc:create(function()
            util_spinePlayAction(spine, "idle",false)
        end)
    )
    act = cc.RepeatForever:create(act)
    spine:runAction(act)
    act:setTag(6)
end

function CashOrConkDF32:refreshNodeUI(node,spine,data)
    node:show()
    if type(data) == "string" then
        if data == "conk" then
            spine:setSkin("CONK")
            node:hide()
        elseif data == "final" then
            spine:setSkin("men")
            node:hide()
        else
            spine:setSkin("chengbei")
        end
    else
        spine:setSkin("qian")
    end

    node:findChild("chengbei"):hide()
    node:findChild("qian"):hide()
    if type(data) == "string" then
        if data ~= "conk" then
            node:findChild("chengbei"):show()
            node:findChild("beishu"):setString("X"..data)
        end
    else
        node:findChild("qian"):show()
        node:findChild("m_lb_coins"):setString(util_formatCoinsLN(data*self._machine._node_reward._curCoinCount, 3))
    end
end

function CashOrConkDF32:createSpine()
    local spine = util_spineCreate("CashOrConk_DF32_xuanxiang",true,true)
    local node = util_createAnimation("CashOrConk_DF32_xuanxiang.csb")
    node:hide()
    node:playAction("idle",true)
    util_bindNode(spine, "wb", node)
    spine.node = node
    return spine
end

function CashOrConkDF32:playOpenSingle(index,data,func,is_dj)
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local spine = self._list_select[index]
    spine:stopActionByTag(6)

    local node = spine.node
    node:hide()

    self:levelPerformWithDelay(self,0.1,function()
        self:refreshNodeUI(node,spine,data)
    end)
    
    util_spinePlayAction(spine, is_dj and "actionframe_dj" or "actionframe_fk",false,func)
end

local move2pos = {cc.p(-149.00,8),cc.p(-141.00,-4),cc.p(-131.00,-15),cc.p(-121.00,-30),cc.p(-111.00,-48)}
local hash_randc2c = {
    "hong","lan","lv"
}
function CashOrConkDF32:playClick(index,info)
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_46)
    local data = info
    self._blockClick = true
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local dataList = self:getCurStageData()
    local totalBet = globalData.slotRunData:getCurTotalBet()
    local status1,status2 = self:getSubStatus()

    self:playOpenSingle(index,data,function()
        local funcOpen2 = function()
            local list = {"final","conk","conk"}
            if info == "conk" then
                table.insert(list,math.random(1,4),"final")
            else
                table.insert(list,math.random(1,4),"conk")
            end
            local idx = 1
            for i=1,MAX_SELECT do
                if i ~= index and list[idx] then
                    self:playOpenSingle(i,list[idx])
                    idx = idx + 1
                end
            end
        end

        local funcOpen = function()
            local list_last = {}--ui对应数据
            local is_filtered = false
            for k,v in pairs(dataList) do
                if (v ~= info or is_filtered) then
                    list_last[#list_last + 1] = v
                    is_filtered = true
                end
            end
            table.insert(list_last,index,info)
            for i=1,MAX_SELECT do
                if i ~= index and list_last[i] then
                    self:playOpenSingle(i,list_last[i])
                end
            end
        end
        
        if data == "conk" then
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_17)
            funcOpen()
            self:levelPerformWithDelay(self,1,function()
                gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_58)
                local spine_dog = util_spineCreate("CashOrConk_cow",true,true)
                util_spinePlayAction(spine_dog, "actionframe_conk",false,function()
                    spine_dog:hide()
                    self._machine._node_reward:playAddCoins(-math.floor(self._machine._node_reward._curCoinCount/2))
                    self:levelPerformWithDelay(self,2,function()
                        self:levelPerformWithDelay(self,1,function()
                            self:showDFEndView(extra.bonus3_win,"3_2")
                        end)
                    end)
                end)
                self._machine:findChild("DF32_conk"):addChild(spine_dog)
                self._machine._npc:playDFSpecial("3_2","CashOrConk_QP_20_23")
            end)
        elseif data == "final" then
            self._machine:clearCurMusicBg()
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_51)
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_17)
            funcOpen2()
            self:levelPerformWithDelay(self,1.5,function()
                self:checkEndAndGotoNext()
            end)
        end
    end,true)

    self:levelPerformWithDelay(self,19/30,function()
        if data ~= "conk" and data ~= "final" then
            local rand_color = type(data) == "string" and 3 or 1
            local node_particle = util_createAnimation("CashOrConk_tuoweilizi.csb")
            local particle = node_particle:findChild("Node_"..hash_randc2c[rand_color])
            for i,v in ipairs(hash_randc2c) do
                node_particle:findChild("Node_"..v):setVisible(rand_color == i)
            end
            for i=1,2 do
                particle:getChildByName("Particle_"..i):resetSystem()
                particle:getChildByName("Particle_"..i):setPositionType(0)
                particle:getChildByName("Particle_"..i):setDuration(-1)
            end
            local targetNode = self._machine:findChild("Node_top")
            targetNode:addChild(node_particle)
        
            local wp1 = self:findChild("xuanxiang_"..index):convertToWorldSpace(cc.p(0,0))
            local np1 = targetNode:convertToNodeSpace(cc.p(wp1))
        
            local node_reward = self._machine._node_reward
            local wp2 = node_reward:convertToWorldSpace(cc.p(0,0))
            local np2 = targetNode:convertToNodeSpace(cc.p(wp2))
        
            np1.x = np1.x 
            np1.y = np1.y
            node_particle:setPosition(cc.p(np1))
            node_particle:runAction(cc.Sequence:create(
                cc.MoveTo:create(27/60,np2),
                cc.CallFunc:create(function()
                    for i=1,2 do
                        particle:getChildByName("Particle_"..i):stopSystem()
                    end
                    local addCoins = 0
                    if type(data) == "string" and tonumber(data) ~= nil then
                        addCoins = node_reward._curCoinCount * tonumber(data) - node_reward._curCoinCount
                    else
                        addCoins = data * node_reward._curCoinCount
                    end

                    local co
                    co = coroutine.create(function()
                        --加钱
                        local t = self._machine._node_reward:playAddCoins(addCoins)
                        self:levelPerformWithDelay(self,t/1000,function()
                            self._machine._npc:playAnim("actionframe5",false)
                            self:showCelebrate()
                            self:levelPerformWithDelay(self,2,function()
                                util_resumeCoroutine(co)
                            end)
                        end)
                        coroutine.yield()

                        --翻开
                        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_17)
                        local list_last = {}--ui对应数据
                        for k,v in pairs(dataList) do
                            if v ~= info then
                                list_last[#list_last + 1] = v
                            end
                        end
                        table.insert(list_last,index,info)
                        for i=1,MAX_SELECT do
                            if i ~= index and list_last[i] then
                                self:playOpenSingle(i,list_last[i])
                            end
                        end
                        self:levelPerformWithDelay(self,1.5,function()
                            util_resumeCoroutine(co)
                        end)
                        coroutine.yield()

                        --切换4or5
                        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_df32_add_refresh)
                        local total_next = status1 == 1 and 4 or 5
                        local spine = self._list_select[total_next]
                        spine:hide()
                        self:runCsbAction(status1 == 1 and "switch1" or "switch2",false,function()
                            util_resumeCoroutine(co)
                        end)
                        coroutine.yield()

                        --新的出现
                        spine:stopActionByTag(6)
                        self:levelPerformWithDelay(spine,0.03,function()
                            spine:show()
                        end)
                        spine:setSkin("CONK")
                        util_spinePlayAction(spine, "actionframe_cx",false,function()
                            util_resumeCoroutine(co)
                        end)
                        coroutine.yield()

                        --刷新
                        local data_next = self:getCurStageData(status1 + 1)
                        local list_last_next = {}
                        for k,v in pairs(data_next) do
                            if v ~= "conk" then
                                list_last_next[#list_last_next + 1] = v
                            end
                        end
                        local index_next = 1
                        if status1 == 2 then
                            for i,v in ipairs(list_last) do
                                if v ~= "conk" then
                                    local up_infp = list_last_next[index_next]
                                    local spine = util_spineCreate("CashOrConk_DF32_xuanxiang",true,true)
                                    self._list_select[i].node:playAction("suofang")
                                    util_spinePlayAction(spine, status1 == 1 and "actionframe_sx" or "actionframe_sx2",false)
                                    self:findChild("xuanxiang_"..i):addChild(spine)
                                    self:levelPerformWithDelay(self,10/30,function()
                                        local spine = self._list_select[i]
                                        self:refreshNodeUI(spine.node,spine,up_infp)
                                    end)
                                    index_next = index_next + 1
                                end
                            end
                        else
                            local funcFindData = function(is_string)
                                for k,v in pairs(list_last_next) do
                                    if type(v) == "string" and is_string then
                                        return v
                                    elseif not is_string then
                                        return v
                                    end
                                end
                            end
                            for i,v in ipairs(list_last) do
                                if v ~= "conk" then
                                    local func_refresh = function(v)
                                        local spine = util_spineCreate("CashOrConk_DF32_xuanxiang",true,true)
                                        self._list_select[i].node:playAction("suofang")
                                        util_spinePlayAction(spine, status1 == 1 and "actionframe_sx" or "actionframe_sx2",false)
                                        self:findChild("xuanxiang_"..i):addChild(spine)
                                        self:levelPerformWithDelay(self,10/30,function()
                                            local up_infp = funcFindData(type(v) == "string")
                                            local spine = self._list_select[i]
                                            self:refreshNodeUI(spine.node,spine,up_infp)
                                        end)
                                    end
                                    func_refresh(v)
                                end
                            end
                        end
                        

                        self:levelPerformWithDelay(self,1.5,function()
                            util_resumeCoroutine(co)
                        end)
                        coroutine.yield()

                        --翻回去
                        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_df32_xp)
                        for i=1,MAX_SELECT do
                            local spine = self._list_select[i]
                            util_spinePlayAction(spine, "actionframe_fh",false)
                        end
                        self:levelPerformWithDelay(self,13/30,function()
                            util_resumeCoroutine(co)
                        end)
                        coroutine.yield()

                        --到中心
                        local list_pos_ori = {}
                        for i=1,total_next do
                            list_pos_ori[i] = cc.p(self:findChild("xuanxiang_"..i):getPosition())
                            self:findChild("xuanxiang_"..i):runAction(cc.MoveTo:create(0.2,move2pos[i]))
                        end
                        self:levelPerformWithDelay(self,0.3,function()
                            util_resumeCoroutine(co)
                        end)
                        coroutine.yield()

                        --洗牌
                        -- for i=1,total_next do
                        --     self:findChild("xuanxiang_"..i):hide()
                        -- end
                        -- local spine = self:createSpine()
                        -- util_spinePlayAction(spine, status1 == 1 and "actionframe_xp2" or "actionframe_xp",false,function()
                        --     util_resumeCoroutine(co)
                        -- end)
                        -- self:getParent():addChild(spine)
                        -- coroutine.yield()

                        --
                        -- spine:hide()
                        for i=1,total_next do
                            self:findChild("xuanxiang_"..i):show()
                            self:runSinleSpineRandIdle(i)
                        end
                        self:levelPerformWithDelay(self,0.01,function()
                            for i=1,total_next do
                                self:findChild("xuanxiang_"..i):runAction(cc.MoveTo:create(0.5/3.0,list_pos_ori[i]))
                            end
                            self:levelPerformWithDelay(self,0.5/3.0,function()
                                self:runCsbAction(status1 == 1 and "idle4" or "idle5")
                                util_resumeCoroutine(co)
                            end)
                        end)
                        coroutine.yield()

                        self:levelPerformWithDelay(self,0.5,function()
                            self:checkEndAndGotoNext()
                        end)
                    end)
                    util_resumeCoroutine(co)
                end),
                cc.DelayTime:create(1.7),
                cc.CallFunc:create(function()
                    node_particle:removeFromParent()
                end)
            ))
        end
    end)
end

function CashOrConkDF32:refreshStatus()
    local status1,status2 = self:getSubStatus()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra

    local roll3sec = self:getCurStageData()

    if status1 == 1 then
        self:runCsbAction("idle3",true)
    elseif status1 == 2 then
        self:runCsbAction("idle4",true)
    elseif status1 == 3 then
        self:runCsbAction("idle5",true)
    end

    self._machine._node_reward:setCoinLabelAndCount(extra.bonus3_win)
    
    self:checkEndAndGotoNext()
end

function CashOrConkDF32:getCurStageData(status)
    local status1,status2 = self:getSubStatus()
    status1 = status or status1
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local roll2sec
    if status1 == 1 then
        roll2sec = extra.roll3sec3_1
    elseif status1 == 2 then
        roll2sec = extra.roll3sec3_2
    elseif status1 == 3 then
        roll2sec = extra.roll3sec3_3
    end
    return roll2sec
end

function CashOrConkDF32:checkEndAndGotoNext()
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
            --     coins = extra.bonus3_win,
            --     is3in1 = true
            -- },function(isContinue)
            --     if isContinue then
            --         self._machine:changePickToState("4_0",function()
            --             self:removeFromParent()
            --         end)
            --     else
            --         self:showDFEndView(extra.bonus3_win,"3_2")
            --     end
            -- end) 
        else
            local co
            co = coroutine.create(function()
                if status_main == 1 then
                    self._blockClick = true
                    self:runCsbAction("idle3")

                    local total_next = 3
                    for i=1,total_next do
                        local spine = self._list_select[i]
                        spine:stopActionByTag(6)
                        self:refreshNodeUI(spine.node,spine,extra.roll3sec3_1[i])
                        util_spinePlayAction(spine, "idleframe",false)
                    end

                    self:levelPerformWithDelay(self,4,function()
                        util_resumeCoroutine(co)
                    end)
                    coroutine.yield()

                    --翻回去
                    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_df32_xp)
                    for i=1,MAX_SELECT do
                        local spine = self._list_select[i]
                        util_spinePlayAction(spine, "actionframe_fh",false)
                    end
                    self:levelPerformWithDelay(self,13/30,function()
                        util_resumeCoroutine(co)
                    end)
                    coroutine.yield()

                    --到中心
                    local list_pos_ori = {}
                    for i=1,total_next do
                        list_pos_ori[i] = cc.p(self:findChild("xuanxiang_"..i):getPosition())
                        self:findChild("xuanxiang_"..i):runAction(cc.MoveTo:create(0.2,move2pos[i + 1]))
                    end
                    self:levelPerformWithDelay(self,0.3,function()
                        util_resumeCoroutine(co)
                    end)
                    coroutine.yield()
    
                    --洗牌
                    -- for i=1,total_next do
                    --     self:findChild("xuanxiang_"..i):hide()
                    -- end
                    -- local spine = self:createSpine()
                    -- util_spinePlayAction(spine, "actionframe_xp3",false,function()
                    --     util_resumeCoroutine(co)
                    -- end)
                    -- self:getParent():addChild(spine)
                    -- coroutine.yield()
    
                    --
                    -- spine:hide()
                    for i=1,total_next do
                        self:findChild("xuanxiang_"..i):show()
                        self:runSinleSpineRandIdle(i)
                    end
                    self:levelPerformWithDelay(self,0.01,function()
                        for i=1,total_next do
                            self:findChild("xuanxiang_"..i):runAction(cc.MoveTo:create(0.5/3.0,list_pos_ori[i]))
                        end
                        self:levelPerformWithDelay(self,0.5/3.0,function()
                            self:runCsbAction("idle3")
                            util_resumeCoroutine(co)
                        end)
                    end)
                    coroutine.yield()
    
                    self:levelPerformWithDelay(self,0.5,function()
                        self:showSurePop({
                            coins = extra.bonus3_win,
                            is2_3 = status1 == 2
                        },function(isContinue)
                            if isContinue then
                                self:addObservers()
                                self:refreshStatus()
                                self._blockClick = false
                            else
                                self:showDFEndView(extra.bonus3_win,"3_2")
                            end
                        end) 
                    end)
                else
                    self:showSurePop({
                        coins = extra.bonus3_win,
                        is2_3 = status1 == 2
                    },function(isContinue)
                        if isContinue then
                            self:addObservers()
                            self:refreshStatus()
                            self._blockClick = false
                        else
                            self:showDFEndView(extra.bonus3_win,"3_2")
                        end
                    end) 
                end
            end)
            util_resumeCoroutine(co)
        end
    end
end

function CashOrConkDF32:clickFunc(sender)
    if self._blockClick then
        return
    end
    local name = sender:getName()
    local index = tonumber(string.sub(name,6,6))

    self:sendData(index)
    -- self:playClick(index,0.7)
end

function CashOrConkDF32:featureResultCallFun(param)
    CashOrConkDF32.super.featureResultCallFun(self,param)
    local spinData = param[2]
    if spinData.action == "SPIN" then
        self:removeFromParent()
        return
    end
    if param[1] == true then
        local selfData = clone(self._machine.m_runSpinResultData.p_selfMakeData)
        local extra = selfData.bonus.extra
        local bonus3roll = extra.bonus3roll
        local data = bonus3roll[#bonus3roll]
        self:playClick(data[1],data[2])
    else

    end
end

function CashOrConkDF32:getCurStageData(status)
    local status1,status2 = self:getSubStatus()
    status1 = status or status1
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local roll2sec
    if status1 == 1 then
        roll2sec = extra.roll3sec3_1
    elseif status1 == 2 then
        roll2sec = extra.roll3sec3_2
    elseif status1 == 3 then
        roll2sec = extra.roll3sec3_3
    end
    return roll2sec
end

function CashOrConkDF32:showCelebrate()
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


return CashOrConkDF32