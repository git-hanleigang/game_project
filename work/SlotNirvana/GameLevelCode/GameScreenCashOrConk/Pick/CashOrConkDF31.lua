local CashOrConkDFBase = util_require("Pick.CashOrConkDFBase")
local SpinFeatureData = require "data.slotsdata.SpinFeatureData"

local CashOrConkDF31 = class("CashOrConkDF31",CashOrConkDFBase)
local CashOrConkPublicConfig = require "CashOrConkPublicConfig"

function CashOrConkDF31:initUI(data)
    self:setDelegate(data.machine)
    self:resetMusicBg(true,CashOrConkPublicConfig["sound_COC_baseLineFrame_stage"..1])
    self:createCsbNode("CashOrConk/GameCashOrConk_DF31.csb")

    
    self._machine._node_reward:playStart(function()end)

    
    self._label_cnt = util_createAnimation("CashOrConk_DF31_cishukuang.csb")
    self:findChild("cishukuang"):addChild(self._label_cnt)

    local spine_eff1 = util_spineCreate("CashOrConk_chuanglian",true,true)
    self:findChild("Node_chuanglian"):addChild(spine_eff1)
    util_spinePlayAction(spine_eff1, "idle",true)

    self._machine._npc:playDFNromal("3_1")

    self._list_wait = {}
end

function CashOrConkDF31:setLeftCntLabel(left,total)
    left = left or 10
    total = total or 10
    left = total - left
    self._label_cnt:findChild("m_lb_num"):setString(string.format("%d/%d",left,total))
end

function CashOrConkDF31:refreshStatus()
    local status1,status2 = self:getSubStatus()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    local bonus2reward = extra.bonus2reward
    local roll2sec = extra.roll2sec

    self._machine._node_reward:setCoinCnt(extra.bonus3_win or 0)
    self._machine._node_reward:setCoinLabel(extra.bonus3_win or 0)

    self:setLeftCntLabel(extra.SpinsLeftCount,extra.SpinsTotalCount)

    local index = 1
    if extra.SpinsLeftCount == 0 then
        self._blockClick = true
        self:checkEndAndGotoNext()
    else
        local action = cc.RepeatForever:create(
            cc.Sequence:create(
                cc.CallFunc:create(function()
                    local len = 5
                    for i=1,len do
                        self:levelPerformWithDelay(self,math.random(1,20)/20,function()
                            if self._stop_fire then
                                return
                            end
                            local bubble = util_require("Pick.CashOrConkDF31Bubble",true):create()
                            if bubble.initData_ then
                                bubble:initData_({delegate = self})
                            end
                            bubble:runCsbAction("idle",true)
                            self:findChild("Panel_1"):addChild(bubble)
                            bubble:setPosition(cc.p(110 + 980/5*(index - 1) + (math.random(1,100) - 50),math.random(0,500)-600))
                            index = index + 1
                            if index > 5 then
                                index = 1
                            end
                            local act = cc.Sequence:create(
                                cc.MoveBy:create(math.random(40,80)/5,cc.p(0,2000)),
                                cc.DelayTime:create(0.1),
                                cc.CallFunc:create(function()
                                    bubble:removeFromParent()
                                end)
                            )
                            act = cc.Speed:create(act,1)
                            act:setTag(0xff)
                            bubble:runAction(act)
                        end)
                    end
                end),
                cc.DelayTime:create(math.random(6,8)/3)
            )
        )
        self:runAction(action)
        action:setTag(0xf1)
        self._blockClick = false
    end
end

function CashOrConkDF31:checkEndAndGotoNext()
    local selfData = self._machine.m_runSpinResultData.p_selfMakeData
    local extra = selfData.bonus.extra
    if extra.SpinsLeftCount == 0 then
        self._blockClick = true
        self:levelPerformWithDelay(self,1,function()
            self._machine:changePickToState("3_2",function()
                self:removeFromParent()
            end)
        end)
        -- self:showSurePop({
        --     coins = extra.bonus3_win
        -- },function(isContinue)
        --     if isContinue then
        --         self._machine:changePickToState("3_2",function()
        --             self:removeFromParent()
        --         end)
        --     else
        --         self:showDFEndView(extra.bonus3_win,"3_1")
        --     end
        -- end) 
    else
        self:levelPerformWithDelay(self,1,function()
            self:setLockClick(false)
        end)
    end
end

function CashOrConkDF31:addWaitList(bubble)
    self._list_wait[#self._list_wait + 1] = bubble
end

function CashOrConkDF31:getFrontWait()
    if self._list_wait[1] then
        return table.remove(self._list_wait,1)
    end
end

function CashOrConkDF31:getWaitListCnt()
    return #self._list_wait
end

function CashOrConkDF31:playBubbleBoom(bubble,data)
    if bubble and bubble.playBoom then
        bubble:playBoom(data)
    end
end

function CashOrConkDF31:featureResultCallFun(param)
    CashOrConkDF31.super.featureResultCallFun(self,param)
    local spinData = param[2]
    if spinData.action == "SPIN" then
        self:removeFromParent()
        return
    end
    if param[1] == true then
        local selfData = clone(self._machine.m_runSpinResultData.p_selfMakeData)
        local extra = selfData.bonus.extra
        local bonus3winseq = extra.bonus3winseq

        self:setLeftCntLabel(extra.SpinsLeftCount,extra.SpinsTotalCount)

        local bubble = self:getFrontWait()
        if bubble then
            self:playBubbleBoom(bubble,bonus3winseq[#bonus3winseq][1])
        end
        if #bonus3winseq == extra.SpinsTotalCount then
            self._blockClick = true
            self:levelPerformWithDelay(self,3,function()
                self:checkEndAndGotoNext()
            end)
            self._stop_fire = true
            self:stopActionByTag(0xf1)
            self:levelPerformWithDelay(self,0.5,function()
                for k,v in pairs(self:findChild("Panel_1"):getChildren()) do
                    if v:getActionByTag(0xff) then
                        v:getActionByTag(0xff):setSpeed(4)
                    end
                end
            end)
        end
    else
        if self and self._list_wait and #self._list_wait > 0 then
            table.remove(self._list_wait,#self._list_wait)
        end
    end
end


return CashOrConkDF31