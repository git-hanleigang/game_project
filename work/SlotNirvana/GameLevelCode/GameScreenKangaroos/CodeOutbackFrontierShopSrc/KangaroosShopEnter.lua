--
-- 袋鼠商店入口
--
local KangaroosShopData = util_require("CodeOutbackFrontierShopSrc.KangaroosShopData")
local KangaroosShopEnter = class("KangaroosShopEnter", util_require("base.BaseView"))
KangaroosShopEnter.m_num = 0

function KangaroosShopEnter:initUI(baseMachine)

    local resourceFilename = "OutbackFrontierShop/Socre_Kangaroos_daishu.csb"
    self:createCsbNode(resourceFilename)
    util_setCascadeOpacityEnabledRescursion(self.m_csbNode,true)

    self.m_count = self:findChild("BitmapFontLabel_2")
    self.m_touch = self:findChild("touch")
    self:addClick(self.m_touch)

    self.m_baseMachine = baseMachine
    self:runCsbAction("idleframe", true)
    KangaroosShopData:setEnterFlag(false)
end

function KangaroosShopEnter:initMachine(machine)
    self.m_machine = machine
end

function KangaroosShopEnter:onEnter()
    util_setCascadeOpacityEnabledRescursion(self,true)

    gLobalNoticManager:addObserver(self,function(self,params)
        local old = false
        if params.val and params.val > 0 then
            old = true
            self.m_num = self.m_num + params.val
        else
            self.m_num = KangaroosShopData:getShopCollectCoins()            
        end
        self:updateUI(old)
    end,ViewEventType.NOTIFY_KANGAROOS_SHOP_ENTER_UPDATE)

    self.m_num = KangaroosShopData:getShopCollectCoins()
    self:updateUI()
end

function KangaroosShopEnter:onExit()

    gLobalNoticManager:removeAllObservers(self)
end

function KangaroosShopEnter:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()
    
    if name == "touch" then
        if self:canClick() then
            if KangaroosShopData:getEnterFlag() == true then
                return
            end
            KangaroosShopData:setEnterFlag(true)
            local view = util_createView("CodeOutbackFrontierShopSrc.KangaroosShop")
            if globalData.slotRunData.machineData.p_portraitFlag then
                view.getRotateBackScaleFlag = function(  ) return false end
            end
            gLobalViewManager:showUI(view)
        end
    end
end

function KangaroosShopEnter:canClick()
    local isFreespin = self.m_baseMachine.m_bProduceSlots_InFreeSpin == true
    local isNormalNoIdle = self.m_baseMachine:getCurrSpinMode() == NORMAL_SPIN_MODE and self.m_baseMachine:getGameSpinStage() ~= IDLE 
    local isFreespinOver = self.m_baseMachine:checkHasGameEffectType(GameEffect.EFFECT_FREE_SPIN_OVER) == true and self.m_baseMachine:getGameSpinStage() ~= IDLE
    local isRunningEffect = self.m_baseMachine.m_isRunningEffect == true
    local isAutoSpin = self.m_baseMachine:getCurrSpinMode() == AUTO_SPIN_MODE
    if self.m_machine.m_waitEnter == true then
        return false
    end
    if isFreespin or isNormalNoIdle or isFreespinOver or isRunningEffect or isAutoSpin then
        return false
    end
    return true
end

function KangaroosShopEnter:getFlyEndLabel()
    return self:findChild("Kangaroos_dsicon_3")
end

function KangaroosShopEnter:updateUI(oldData,currNum)
    local num = nil
    if oldData then
        num = self.m_num
    else
        num = KangaroosShopData:getShopCollectCoins()
    end
    num = currNum or num
    if num and num >= 0 then
        self:updateCount(num)
    end
end

function KangaroosShopEnter:updateCount(num)
    --第一次加载
    local oldNum = tonumber(self.m_count:getString()) or 0
    if(oldNum<=0)then
        self.m_count:setString(tostring(num))
        return
    end

    --上次增加还没结束时
    self.m_count:stopAllActions()

    local endNum = tonumber(num)
    local jumpTime = 0.5
    local jumpTmes = jumpTime /(1/30)
    local addNum =  (endNum - oldNum)/jumpTmes
    if addNum < 1 then
        addNum = 1
    end
    print("########### 121 "..endNum)
    schedule(self.m_count,function()
        oldNum = tonumber(self.m_count:getString())
        local tempNum = oldNum + addNum

        if(tempNum >= endNum)then
            tempNum = endNum
            print("########### 128 "..tempNum)
            self.m_count:setString(tostring( math.floor(tempNum) ))
            self.m_count:stopAllActions()
        else
            self.m_count:setString(tostring( math.floor(tempNum) ))
        end
        
    end,1/30)
end

function KangaroosShopEnter:playLighting(callFunc,_num)
    self:runCsbAction("light", false, function()
        self:runCsbAction("idleframe", true)
        if callFunc then
            callFunc()
        end
    end)
    self:updateUI(nil,_num)
    
    -- local act1 = cc.ScaleTo:create(1.5, 0.4)
    -- local act2 = cc.ScaleTo:create(1, 0.2)
    -- local act = cc.Spawn:create(act1, act2)
    -- local call = cc.CallFunc:create(function()
    --     self:updateUI()
    --     if callFunc then
    --         callFunc()
    --     end
    -- end)
    -- local seq = cc.Sequence:create(act, call)
    -- local logo = self:findChild("Kangaroos_dsicon_3")
    -- logo:runAction(seq)
end



return KangaroosShopEnter