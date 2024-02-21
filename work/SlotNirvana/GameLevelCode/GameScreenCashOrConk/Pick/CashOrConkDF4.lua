local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local CashOrConkDF4 = class("CashOrConkDF4",CashOrConkDFBase)
local CashOrConkUserAction = require("CashOrConkUserAction")

local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

local jackpot2index = {
    ["grand"] = 1,["mega"] = 2,["major"] = 3,["minor"] = 4,["mini"] = 5,
}

local index2jackpot = {
    "grand","mega","major","minor","mini"
}

function CashOrConkDF4:initUI(data)
    self:setDelegate(data.machine)
    self:resetMusicBg(true,CashOrConkPublicConfig["sound_COC_baseLineFrame_stage"..3])
    self:createCsbNode("CashOrConk/GameScreenCashOrConk_sanxuanyi_node.csb")

    -- self:setPosition(cc.p(-1370.00/2,-768/2))

    self.m_jackpotView = util_createView("CashOrConk.CashOrConkDFJackPotBarView",{
        machine = data.machine
    })
    self.m_jackpotView:initMachine(data.machine)
    self:findChild("jackpot_sanxuanyi"):addChild(self.m_jackpotView)


    self._list_spine = {}
    self._list_eff = {}
    for i=1,3 do
        local spine = util_spineCreate("CashOrConk_men",true,true)
        spine:setSkin(tostring(i))
        self._list_spine[i] = spine
        util_spinePlayAction(spine, "idle",true)
        self:findChild("xuanxiang_"..i):addChild(spine)
        self:addClick(self:findChild("touch_"..i))

        local anim1 = util_createAnimation("CashOrConk_sanxuanyi_xuanxiang.csb")
        anim1:hide()
        self:findChild("xuanxiang_"..i):addChild(anim1)
        self._list_eff[i] = anim1

        local spine = util_spineCreate("CashOrConk_shou",true,true)
        anim1:findChild("shou"):addChild(spine)
        anim1.spine = spine
    end

    self:runAction(cc.RepeatForever:create(cc.Sequence:create(
        cc.DelayTime:create(1 * (0.5 + 1)),
        cc.CallFunc:create(function()
            local anim1 = self._list_eff[1]
            anim1.spine:show()
            util_spinePlayAction(anim1.spine, "idle", false,function()
                anim1.spine:hide()
            end)
            self:levelPerformWithDelay(anim1,1/3,function()
                anim1:show()
                anim1:playAction("idle2",false)
            end)
        end),
        cc.DelayTime:create(1 * (0.5 + 1)),
        cc.CallFunc:create(function()
            local anim1 = self._list_eff[2]
            anim1.spine:show()
            util_spinePlayAction(anim1.spine, "idle", false,function()
                anim1.spine:hide()
            end)
            self:levelPerformWithDelay(anim1,1/3,function()
                anim1:show()
                anim1:playAction("idle2",false,function()
                    anim1.spine:hide()
                end)
            end)
        end),
        cc.DelayTime:create(1 * (0.5 + 1)),
        cc.CallFunc:create(function()
            local anim1 = self._list_eff[3]
            anim1.spine:show()
            util_spinePlayAction(anim1.spine, "idle", false,function()
                anim1.spine:hide()
            end)
            self:levelPerformWithDelay(anim1,1/3,function()
                anim1:show()
                anim1:playAction("idle2",false,function()
                    anim1.spine:hide()
                end)
            end)
        end)
    )))
    local spine = util_spineCreate("CashOrConk_sanxuanyibg",true,true)
    util_spinePlayAction(spine, "idleframe7",true)
    self:findChild("bg"):addChild(spine)

    self._node_reward = util_createAnimation("CashOrConk_jianglilan_sanxuanyi.csb")
    self:findChild("jianglilan_sanxuanyi"):addChild(self._node_reward)
    self._spine_eff1 = util_spineCreate("CashOrConk_jianglilan",true,true)
    util_spinePlayAction(self._spine_eff1, "actionframe2",true)
    self._spine_eff1:hide()
    self._node_reward:findChild("Node_tx_1"):addChild(self._spine_eff1)

    local spine_eff = util_spineCreate("CashOrConk_jianglilan",true,true)
    util_spinePlayAction(spine_eff, "idleframe3",true,function()
    end)
    self._node_reward:findChild("Node_tx_1"):addChild(spine_eff)

    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local coins = 0
    if extra.bonus1_win then
        coins = extra.bonus1_win
    elseif extra.bonus2_win then
        coins = extra.bonus2_win
    elseif extra.bonus3_win then
        coins = extra.bonus3_win
    end
    self:setCoinCnt(coins)
    self:setCoinLabel(coins)

    self._machine._node_reward:plalHideIdle()

    self._machine._npc:hide()
    self._machine._npc._animBubble:hide()

    self:levelPerformWithDelay(self,3,function()
        self._blockClick = false
    end)
end

local nodeList = {
    ["jine"] = "reward",["chengbei"] = "mul",["caiji"] = "grand"
}
function CashOrConkDF4:playPick(index,data)
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_df_camera_scale2)
    self:stopAllActions()
    for i,v in ipairs(self._list_eff) do
        v:hide()
    end
    self._blockClick = true

    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra

    local funcRefreshNode = function(node,info)
        for k,v in pairs(nodeList) do
            node:findChild("root"):getChildByName(k):setVisible(v == info[2])
        end
        if info[2] == "reward" then
            node:findChild("m_lb_coins_0"):setString(util_formatCoinsLN(info[3],3))
            -- node:findChild("m_lb_coins_0_0"):setString(util_formatCoinsLN(info[3],3))
        elseif info[2] == "mul" then
            node:findChild("beishu_0"):setString("X"..info[3])
            -- node:findChild("beishu_0_0"):setString("X"..info[3])
        elseif info[2] == "grand" then

        end
    end

    self:levelPerformWithDelay(self,74/60,function()
        self.m_csbAct:pause()
    end)
    self:runCsbAction("move"..index,false)
    

    local anim1 = util_createAnimation("CashOrConk_sanxuanyi_xuanxiang.csb")
    funcRefreshNode(anim1,data)
    anim1:playAction("actionframe_dj")
    self:findChild("xuanxiang_"..index):addChild(anim1)

    local funcRefreshNode2 = function(node,info)
        for k,v in pairs(nodeList) do
            node:findChild("root"):getChildByName(k):setVisible(v == info[2])
        end
        if info[2] == "reward" then
            node:findChild("m_lb_coins_0_0"):setString(util_formatCoinsLN(info[3],3))
        elseif info[2] == "mul" then
            node:findChild("beishu_0_0"):setString("X"..info[3])
        elseif info[2] == "grand" then

        end
    end
    local anim_top = util_createAnimation("CashOrConk_sanxuanyi_xuanxiang_up.csb")
    funcRefreshNode2(anim_top,data)
    anim_top:playAction("actionframe_dj",false,function()
        anim_top:removeFromParent()
    end)
    self:findChild("xuanxiang__"..index):addChild(anim_top)
    self:levelPerformWithDelay(self,110/60,function()
        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_df3_wincoins)
    end)

    anim_top:findChild("beishu_0_0"):show()
    anim_top:findChild("m_lb_coins_0_0"):show()

    local spine = self._list_spine[index]
    util_spinePlayAction(spine, "actionframe_dj",false)

    self:levelPerformWithDelay(self,0.5,function()
        self._node_reward:playAction("start2")
    end)

    local index_pick = 0
    if extra.bonus1_win then
        index_pick = 1
    elseif extra.bonus2_win then
        index_pick = 2
    elseif extra.bonus3_win then
        index_pick = 3
    end

    self:levelPerformWithDelay(self,74/30,function()
        if data[2] == "mul" then
            data[3] = self._curCoinCount*data[3] - self._curCoinCount
        end
        self:playAddCoins(data[3])
    end)

    self:levelPerformWithDelay(self,74/30,function()
        self:levelPerformWithDelay(self,1.5,function ()
            self.m_csbAct:resume()
            self:levelPerformWithDelay(self,126/60,function()
                gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_df_camera_scale1)
                local rewards_other = {}
        
                for i=1,#extra.finalop do
                    if extra.finalop[i][1] ~= data[2] then
                        rewards_other[#rewards_other + 1] = clone(extra.finalop[i])
                    end
                end
                local idx = 0
                for i=1,3 do
                    if i ~= index then
                        idx = idx + 1
                        local anim1 = util_createAnimation("CashOrConk_sanxuanyi_xuanxiang.csb")
                        anim1:playAction("actionframe_djno")
                        self:findChild("xuanxiang_"..i):addChild(anim1)
                        local spine = self._list_spine[i]
                        util_spinePlayAction(spine, "actionframe_djno",false)
                        local data = rewards_other[idx]
                        table.insert(data,1,i)
                        funcRefreshNode(anim1,data)
                    end
                end
            end)
            self:levelPerformWithDelay(self,(280-74)/60,function()
                if data[2] == "grand" then
                    local view = GD.util_createView("Pick.CashOrConkDF11WinView",{
                        index = 1,
                        coins = data[3]
                    })
                    view:findChild("z"):setScale(self._machine.m_machineRootScale)
                    view:popView()
                    view:setOverAniRunFunc(function()
                        self:showDFEndView(extra.bonus4_win,"4_0",tonumber(index_pick))
                        -- self:removeFromParent()
                    end)
                    self._machine:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
                else
                    self:showDFEndView(extra.bonus4_win,"4_0",tonumber(index_pick))
                    -- self:removeFromParent()
                end
            end)
        end)
    end)
end

function CashOrConkDF4:clickFunc(sender)
    if self._blockClick then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    
    local list_str = string.split(name,"_")

    local index = tonumber(list_str[2])
    
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    -- self:playPick(1,extra.finalwin)
    self:sendData(index)
end

function CashOrConkDF4:featureResultCallFun(param)
    CashOrConkDF4.super.featureResultCallFun(self,param)
    local spinData = param[2]
    if spinData.action == "SPIN" then
        self:removeFromParent()
        return
    end
    if param[1] == true then
        local selfData = self._machine.m_runSpinResultData.p_selfMakeData
        local extra = selfData.bonus.extra
        
        self:playPick(self._lastSendData,extra.finalwin)
    else

    end
end

function CashOrConkDF4:playAddCoins(addCoins)
    if self._userAction then
        self._userAction:stop()
        self._userAction = nil
    end

    self._curCoinCount = self._curCoinCount + addCoins

    local cv = self._curCoinCount - addCoins
    local av = addCoins
    local userAction = CashOrConkUserAction.new(self._node_reward,(45/30)*1000,function(per)
        self:setCoinLabel(cv + per * av)
    end)

    self._node_reward:runCsbAction("youwin",false)
    local spine_eff = util_spineCreate("CashOrConk_jianglilan",true,true)
    util_spinePlayAction(spine_eff, "actionframe2_start",false,function()
        spine_eff:hide()
    end)
    self._node_reward:findChild("Node_tx_start"):addChild(spine_eff)

    self:levelPerformWithDelay(self,5/30,function()
        self._node_reward:runCsbAction("actionframe2_idle",true)
        self._spine_eff1:show()
        userAction:run()
        self.m_soundId = gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_df4_b)

        self:levelPerformWithDelay(self,45/30 + 0.01,function()
            if self.m_soundId then
                gLobalSoundManager:stopAudio(self.m_soundId)
                self.m_soundId = nil
            end
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_df4_e)
        end)
    end)
    
    self:levelPerformWithDelay(self,50/30,function()
        self._node_reward:runCsbAction("actionframe2_over",false,function()
            self._spine_eff1:hide()
            self._node_reward:runCsbAction("actionframe2_idle",true)
        end)
    end)

    self._userAction = userAction
end

function CashOrConkDF4:setCoinCnt(coins)
    self._curCoinCount = coins
end

function CashOrConkDF4:setCoinLabel(coins)
    local str = util_formatCoins(coins,20)
    self._node_reward:findChild("m_lb_coins"):setString(str)
    local info = {label = self._node_reward:findChild("m_lb_coins"), sx = 0.7,sy = 0.7}
    self:updateLabelSize(info, 804)
end


return CashOrConkDF4