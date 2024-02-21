local BaseGame = util_require("base.BaseGame")
local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")
local BaseView = require "base.BaseView"
local SendDataManager = require "network.SendDataManager"
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local CashOrConkDF11 = class("CashOrConkDF11",CashOrConkDFBase)
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

local jackpot2index = {
    ["mega"] = 1,["major"] = 2,["minor"] = 3,["mini"] = 4,
}
local index2jackpot = {
    "mega","major","minor","mini"
}
function CashOrConkDF11:initUI(data)
    self:setDelegate(data.machine)
    self:resetMusicBg(true,CashOrConkPublicConfig["sound_COC_baseLineFrame_stage"..1])

    self:createCsbNode("CashOrConk/GameCashOrConk_DF11.csb")

    self._panel_jackpot = util_createAnimation("CashOrConk_jackpot_DF11.csb")
    self:findChild("jackpot_DF11"):addChild(self._panel_jackpot)

    self._panel_jackpot_uis = {{},{},{},{}}
    for i,v in ipairs({"mega","major","minor","mini"}) do
        local anim = util_createAnimation("CashOrConk_jackpot_tx.csb")
        self._panel_jackpot:findChild("Node_idle_"..v):addChild(anim)
        self:runAction(cc.Sequence:create(
            cc.DelayTime:create(0.5*(i - 1)),
            cc.CallFunc:create(function()
                anim:playAction("idle",true)
            end)
        ))
        for j=1,3 do
            self._panel_jackpot_uis[i][j] = {}
            local node = util_createAnimation("CashOrConk_jackpot_DF11_jindu.csb")
            node:hide()
            self._panel_jackpot_uis[i][j]["node"] = node
            self._panel_jackpot:findChild(string.format("jindu_%s_%d",v,j)):addChild(node)

            for _,node_jackpot in pairs(node:findChild("Node_1"):getChildren()) do
                node_jackpot:setVisible(node_jackpot:getName() == v)
            end

            local sp = util_spineCreate("CashOrConk_jackpot_DF11_jindu",true,true)
            self._panel_jackpot:findChild(string.format("jindu_%s_%d",v,j)):addChild(sp)
            sp:hide()
            self._panel_jackpot_uis[i][j]["spine"] = sp
            util_spinePlayAction(sp, "idleframe3",true)
        end
    end

    self._list_select = {}
    self._list_shuzi = {}
    for i=1,12 do
        local spine = util_spineCreate("CashOrConk_DF11_xuanxiang",true,true)
        local act = cc.Sequence:create(
            cc.DelayTime:create(math.random(1,12)),
            cc.CallFunc:create(function()
                util_spinePlayAction(spine, "idleframe3",true)
            end)
        )
        spine:runAction(act)
        act:setTag(6)
        self:findChild("xuanxiang_"..i):addChild(spine)
        self._list_select[i] = spine

        local node_shuzi = util_createAnimation("CashOrConk_DF11_xuanxiang_shuzi.csb")
        util_bindNode(spine, "shuzi", node_shuzi,nil,nil,true)
        node_shuzi:findChild("hou_shuzi"):hide()
        node_shuzi:findChild("qian_shuzi"):show()
        for j=1,12 do
            node_shuzi:findChild("hou_"..j):setVisible(j == i)
            node_shuzi:findChild("qian_"..j):setVisible(j == i)
        end
        self._list_shuzi[i] = node_shuzi

        self:addClick(self:findChild("xuanxiang_"..i):getChildByName("touch"))
    end 

    self._machine._npc:hide()
    self._machine._npc._animBubble:hide()
    self._machine:findChild("jackpot_classic"):hide()
end

function CashOrConkDF11:playClick(index,jackpot,cnt)
    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_30)

    local spine = self._list_select[index]
    local node_shuzi = self._list_shuzi[index]
    spine:stopActionByTag(6)
    util_spinePlayAction(spine, "actionframe_dj",false,function()
        util_spinePlayAction(spine, "idleframe",true)
    end)

    self:levelPerformWithDelay(spine,20/30,function()
        self:playFlyTo(index,jackpot,cnt)
    end)

    self:levelPerformWithDelay(spine,12/30,function()
        self:setPickIdleStatus(index,jackpot)
    end)
end

function CashOrConkDF11:playFlyTo(index,jackpot,cnt)
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local anim = util_createAnimation("CashOrConk_DF11_xuanxiang_cm.csb")
    anim:playAction("fly",false)
    for k,v in pairs(anim:findChild("hou_caijin"):getChildren()) do
        v:setVisible(v:getName() == jackpot)
    end

    local targetNode = self._machine:findChild("Node_top")
    targetNode:addChild(anim)

    local wp1 = self:findChild("xuanxiang_"..index):convertToWorldSpace(cc.p(0,0))
    local np1 = targetNode:convertToNodeSpace(cc.p(wp1))

    local node_2 = self._panel_jackpot:findChild(string.format("jindu_%s_%d",jackpot,cnt))
    local wp2 = node_2:convertToWorldSpace(cc.p(0,0))
    local np2 = targetNode:convertToNodeSpace(cc.p(wp2))

    np1.x = np1.x + 24
    np1.y = np1.y + 12
    anim:setPosition(cc.p(np1))
    anim:runAction(cc.Sequence:create(
        cc.EaseQuarticActionIn:create(cc.MoveTo:create(48/60,np2)),
        cc.CallFunc:create(function()
            gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_36)
            anim:removeFromParent()
            local sp = self._panel_jackpot_uis[jackpot2index[jackpot]][cnt]["spine"]
            sp:show()
            util_spinePlayAction(sp, "actionframe",false,function()
                if cnt == 3 then
                    self._blockClick = true
                    gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_54)
                    self._machine._node_reward:playStart(function()
                        
                        local haskIndex2reward = {}
                        local jackpot1seq = extra.jackpot1seq or {}
                        local other1 = extra.other1
                        local index_yaan = 1
                        local funcPlayYaan = function(spine,index,jkp)
                            if not jkp then
                                self:setPickIdleStatus(index,other1[index_yaan])
                                index_yaan = index_yaan + 1
                            else
                                self:setPickIdleStatus(index,jkp)
                            end
                            util_spinePlayAction(spine, "idleframe",false,function()
                                local spine = util_spineCreate("CashOrConk_DF11_xuanxiang",true,true)
                                self:findChild("xuanxiang_"..index):addChild(spine)
                                util_spinePlayAction(spine, "idleframe_yaan",false)
                            end)
                        end

                        for _,data in pairs(jackpot1seq) do
                            local index = data[1]
                            haskIndex2reward[index] = true
                            local spine = self._list_select[index]
                            if data[2] == jackpot then
                                util_spinePlayAction(spine, "actionframe_cf",false)
                            else
                                funcPlayYaan(spine,index,data[2])
                            end
                        end

                        for i=1,12 do
                            if not haskIndex2reward[i] then
                                local spine = self._list_select[i]
                                funcPlayYaan(spine,i)
                            end
                        end

                        gLobalSoundManager:playSound(CashOrConkPublicConfig.sound_CashOrConk_7)
                        local animCeleb = util_createAnimation("CashOrConk_jackpot_DF11_jackpot_zjtx.csb")
                        self._panel_jackpot:findChild("Node_zj_"..jackpot):addChild(animCeleb)
                        animCeleb:playAction("actionframe",true,function()
                            -- animCeleb:removeFromParent()
                            self:levelPerformWithDelay(self,2,function()
                                local view = GD.util_createView("Pick.CashOrConkDF11WinView",{
                                    index = jackpot2index[jackpot] + 1,
                                    coins = extra.jackpot1[3]
                                })
                                view:findChild("z"):setScale(self._machine.m_machineRootScale)
                                view:popView()
                                view:setOverAniRunFunc(function()
                                    self._machine._node_reward:playAddCoins(extra.jackpot1[3])
                                    self:levelPerformWithDelay(self,2,function()
                                        self:checkEndAndGotoNext()
                                    end)
                                end)
                                self._machine:addChild(view,GAME_LAYER_ORDER.LAYER_ORDER_GAME_MAIN_LAYER + 1)
                            end)
                        end)
                    end)
                end
            end)
            self:levelPerformWithDelay(sp,4/30,function()
                local node = self._panel_jackpot_uis[jackpot2index[jackpot]][cnt]["node"]
                node:show()

                if cnt == 2 then
                    local sp = self._panel_jackpot_uis[jackpot2index[jackpot]][3]["spine"]
                    sp:show()
                end
            end)
        end)
    ))
end

function CashOrConkDF11:playCelebrate(index,jackpot)
    local spine = self._list_select[index]
    util_spinePlayAction(spine, "actionframe_cf",false)
end

function CashOrConkDF11:setPickIdleStatus(index,jackpot)
    local spine = self._list_select[index]
    local node_shuzi = self._list_shuzi[index]
    spine:setSkin(jackpot)
    node_shuzi:findChild("hou_shuzi"):show()
    node_shuzi:findChild("qian_shuzi"):hide()
    node_shuzi:retain()
    node_shuzi:removeFromParent()
    spine:stopAllActions()
    util_bindNode(spine, "shuzi2", node_shuzi,nil,nil,true)
end

function CashOrConkDF11:refreshStatus()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData

    local extra = selfData.bonus.extra
    local jackpot1seq = extra.jackpot1seq or {}

    self._machine._node_reward:setCoinLabelAndCount(extra.bonus1_win or 0)

    local hask_jackpot2cnt = {}
    --picks
    for _,data in pairs(jackpot1seq) do
        local index = data[1]
        local jackpot = data[2]
        local spine = self._list_select[index]
        self:setPickIdleStatus(index,jackpot)
        util_spinePlayAction(spine, "idleframe",true)
        if not hask_jackpot2cnt[jackpot] then
            hask_jackpot2cnt[jackpot] = 0
        end
        hask_jackpot2cnt[jackpot] = hask_jackpot2cnt[jackpot] + 1
    end
    --panel
    for jackpot,cnt in pairs(hask_jackpot2cnt) do
        for i=1,cnt do
            local sp = self._panel_jackpot_uis[jackpot2index[jackpot]][i]["node"]
            sp:show()
        end
        if cnt == 2 then
            local sp = self._panel_jackpot_uis[jackpot2index[jackpot]][3]["spine"]
            sp:show()
        end
    end

    self:checkEndAndGotoNext()
end

function CashOrConkDF11:clickFunc(sender)
    if self._blockClick then
        return
    end
    local name = sender:getName()
    local tag = sender:getTag()
    
    local name_parent = sender:getParent():getName()

    local list_str = string.split(name_parent,"_")

    local index = tonumber(list_str[2])

    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local jackpot1seq = extra.jackpot1seq or {}

    for k,v in pairs(jackpot1seq) do
        if v[1] == index then
            return
        end
    end
    
    self:sendData(index)
end

function CashOrConkDF11:checkEndAndGotoNext()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    if extra.jackpot1 and #extra.jackpot1 > 0 then
        self._blockClick = true
        self:levelPerformWithDelay(self,1.5,function()
            self._machine:changePickToState("1_2",function()
                self._machine._npc:show()
                self._machine._npc._animBubble:show()
                self._machine:findChild("jackpot_classic"):show()
                self:removeFromParent()
            end)
            -- self:showSurePop({
            --     coins = extra.bonus1_win
            -- },function(isContinue)
            --     if isContinue then
            --         self._machine:changePickToState("1_2",function()
            --             self._machine._npc:show()
            --             self._machine._npc._animBubble:show()
            --             self._machine:findChild("jackpot_classic"):show()
            --             self:removeFromParent()
            --         end)
            --     else
            --         self:showDFEndView(extra.bonus1_win,"1_1",nil,function()
            --             self._machine._npc:show()
            --             self._machine._npc._animBubble:show()
            --             self._machine:findChild("jackpot_classic"):show()
            --         end)
            --     end
            -- end) 
        end)
    else
        self:levelPerformWithDelay(self,1,function()
            self:setLockClick(false)
        end)
    end
end

function CashOrConkDF11:featureResultCallFun(param)
    CashOrConkDF11.super.featureResultCallFun(self,param)

    local spinData = param[2]
    if spinData.action == "SPIN" then
        self:removeFromParent()
        return
    end

    if param[1] == true then
        local selfData = self._machine.m_runSpinResultData.p_selfMakeData
        local extra = selfData.bonus.extra
        local jackpot1seq = extra.jackpot1seq or {}
        local data = jackpot1seq[#jackpot1seq]
        local jackpot = data[2]
        local index = data[1]
        local hask_jackpot2cnt = {}
        for _,data in pairs(jackpot1seq) do
            local index = data[1]
            local jackpot = data[2]
            if not hask_jackpot2cnt[jackpot] then
                hask_jackpot2cnt[jackpot] = 0
            end
            hask_jackpot2cnt[jackpot] = hask_jackpot2cnt[jackpot] + 1
            if hask_jackpot2cnt[jackpot] == 3 then
                self._blockClick = true
            end
        end
        self:playClick(index,jackpot,hask_jackpot2cnt[jackpot])
    else

    end
end


function CashOrConkDF11:onEnter()
    CashOrConkDF11.super.onEnter(self)
    util_setCascadeOpacityEnabledRescursion(self, true)
    schedule(
        self,
        function()
            self:updateJackpotInfo()
        end,
        0.08
    )
end

local GrandName = "m_lb_coins_grand"
local MegaName = "m_lb_coins_mega"
local MajorName = "m_lb_coins_major"
local MinorName = "m_lb_coins_minor"
local MiniName = "m_lb_coins_mini"

function CashOrConkDF11:updateJackpotInfo()
    if not self._machine then
        return
    end
    local data = self.m_csbOwner

    -- self:changeNode(self:findChild(GrandName), 1, true)
    self:changeNode(self._panel_jackpot:findChild(MegaName), 2, true)
    self:changeNode(self._panel_jackpot:findChild(MajorName), 3, true)
    self:changeNode(self._panel_jackpot:findChild(MinorName), 4)
    self:changeNode(self._panel_jackpot:findChild(MiniName), 5)

    self:updateSize()
end

function CashOrConkDF11:updateSize()
    -- local label1 = self.m_csbOwner[GrandName]
    local label2 = self._panel_jackpot.m_csbOwner[MegaName]
    local label3 = self._panel_jackpot.m_csbOwner[MajorName]
    local label4 = self._panel_jackpot.m_csbOwner[MinorName]
    local label5 = self._panel_jackpot.m_csbOwner[MiniName]

    -- local info1 = {label = label1, sx = 0.52,sy = 0.52}
    local info2 = {label = label2, sx = 0.66,sy = 0.66}
    local info3 = {label = label2, sx = 0.66,sy = 0.66}
    local info4 = {label = label3, sx = 0.66,sy = 0.66}
    local info5 = {label = label4, sx = 0.66,sy = 0.66}

    -- self:updateLabelSize(info1, 367)
    self:updateLabelSize(info2, 364)
    self:updateLabelSize(info3, 364)
    self:updateLabelSize(info4, 364)
    self:updateLabelSize(info5, 364)
end

function CashOrConkDF11:changeNode(label, index, isJump)
    local value = self._machine:BaseMania_updateJackpotScore(index)
    label:setString(util_formatCoinsLN(value, 12, nil, nil, true))
end

return CashOrConkDF11