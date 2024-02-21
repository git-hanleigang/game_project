local KoiBlissPickGame = class("KoiBlissPickGame",util_require("base.BaseView"))
local PublicConfig  = require("KoiBlissPublicConfig")

KoiBlissPickGame.m_ItemDarkList = {
    Grand = {"red_dark","grang_dark"},
    Major = {"purple_dark","major_dark"},
    Minor = {"blue_dark","minor_dark"},
    Mini = {"green_dark","mini_dark"},
    Pick = {"special_dark","extragame_dark"}
}

function KoiBlissPickGame:initUI(machine)
    self:createCsbNode("KoiBliss/GameScreenKoiBliss_dfdc.csb")
    self.m_machine = machine
    --添加jackpot条
    self.m_jackpotBar = util_createAnimation("KoiBliss_dfdc_jackpotbar.csb")
    self:findChild("Node_jackpotbar"):addChild(self.m_jackpotBar)
    local ratio = display.height / display.width
    if ratio == 1530/768 then
        self.m_jackpotBar:setPosition(cc.p(0,70))
    elseif ratio == 1970/768 then
        self.m_jackpotBar:setPosition(cc.p(0,140))
    end
    --添加jackpot条上的进度标识
    self.m_jackProgressBiaoshiTab = {}
    for i = 1,4 do
        local jpTy = {"red","purple","blue","green"}
        local biaoshiTab = {}
        for j = 1,3 do
            local biaoshi = util_createAnimation("KoiBliss_dfdc_jackpotbar_amount.csb")
            self.m_jackpotBar:findChild("node_"..jpTy[i].."_"..j):addChild(biaoshi)
            table.insert(biaoshiTab,biaoshi)
            for ii=1,#jpTy do
                local img = biaoshi:findChild(jpTy[ii])
                img:setVisible(jpTy[i] == jpTy[ii])
            end
        end
        table.insert(self.m_jackProgressBiaoshiTab,biaoshiTab)
    end
    --添加选项
    self.m_itemTab = {}
    for i = 1,13 do
        local item = util_createAnimation("KoiBliss_dfdc_pick.csb")
        self:findChild("Node_"..i):addChild(item)
        self:addClick(item:findChild("Panel_1"))
        item:findChild("Panel_1"):setTag(i)
        item.light = util_createAnimation("KoiBliss_dfdc_pick_g.csb")
        item:findChild("ef_g"):addChild(item.light)
        item.light:setVisible(false)
        table.insert(self.m_itemTab,item)
    end

    self.m_chongzhi = util_createAnimation("KoiBliss_dfdc_pick_chzh.csb")
    self:findChild("KoiBliss_dfdc_pick_chzh"):addChild(self.m_chongzhi)
    self.m_chongzhi:setVisible(false)

    self.m_delayNode = cc.Node:create()
    self:addChild(self.m_delayNode)
end

function KoiBlissPickGame:resetItemZOrder()
    for i = 1,13 do
        self:findChild("Node_"..i):setLocalZOrder(i)
    end
end

function KoiBlissPickGame:updateItemLightVisible(_item)
    local childs = _item.light:findChild("Node_3"):getChildren()
    for i=1,#childs do
        childs[i]:setVisible(false)
    end
    _item.light:findChild("Node_".._item.m_openType):setVisible(true)
    _item.light:setVisible(true)
    _item.light:runCsbAction("idle",true)
end

function KoiBlissPickGame:initView()
    self.m_jackpotBar.m_idleState = 1
    self:changeJackpotBarState(1)
    for i,baoshiTab in ipairs(self.m_jackProgressBiaoshiTab) do
        for j,biaoshi in ipairs(baoshiTab) do
            biaoshi:playAction("idle")
        end
    end
    for i,item in ipairs(self.m_itemTab) do
        item.m_isOpen = false
        item.light:setVisible(false)
        for _,darkList in pairs(self.m_ItemDarkList) do
            for ii=1,#darkList do
                local name = darkList[ii]
                item:findChild(name):setVisible(false)
            end
        end

        item:findChild("Pick"):setVisible(false)
        item:findChild("Grand"):setVisible(false)
        item:findChild("Major"):setVisible(false)
        item:findChild("Minor"):setVisible(false)
        item:findChild("Mini"):setVisible(false)
        item:findChild("Panel_1"):setTouchEnabled(true)
        item:getParent():setLocalZOrder(i)
        item:playAction("idle",true)
    end

    local winTypeList  = {"Grand","Major","Minor","Mini"}
    for i=1,#winTypeList do
        local node = self.m_jackpotBar:findChild("zhongjiang_"..winTypeList[i])
        node:setVisible(false)
    end

    self.m_openIndex = 0--已经打开的选项数量
    self.m_progressTab = {0,0,0,0}--当前的收集进度 grand->mini
    self.m_collectEndProgressTab = {0,0,0,0}--当前收集完的进度
    self.m_isCanClick = false--小游戏是否可以点击
    self.m_isEnd = false--本轮小游戏是否结束

    schedule(self.m_jackpotBar,function()
        self:updateJackpotCoinsNum(0.08)
    end,0.08)
end
function KoiBlissPickGame:startGame()
    self.m_isCanClick = true
    self:randomPlayItemIdle()

end
function KoiBlissPickGame:randomPlayItemIdle()
    local temItemTab = {}
    for i,item in ipairs(self.m_itemTab) do
        if item.m_isOpen == false then
            table.insert(temItemTab,item)
        end
    end
    local randomNum = math.random(1,3)
    randomNum = math.min(randomNum,#temItemTab)
    for i = 1,randomNum do
        local rand = math.random(1,#temItemTab)
        temItemTab[rand]:playAction("idle1",false)
        table.remove(temItemTab,rand)
    end
    performWithDelay(self.m_delayNode,function ()
        self:randomPlayItemIdle()
    end,75/30)

end
function KoiBlissPickGame:hideLayer()
    self.m_jackpotBar:stopAllActions()
    self:setVisible(false)
end
function KoiBlissPickGame:updateJackpotCoinsNum(dt)
    if not self.m_machine then
        return
    end
    local infoTab = {
        {name = "m_lb_coins_1",labelwidth = 299,sx = 0.94,sy = 1},
        {name = "m_lb_coins_2",labelwidth = 299,sx = 0.94,sy = 1},
        {name = "m_lb_coins_3",labelwidth = 255,sx = 0.94,sy = 1},
        {name = "m_lb_coins_4",labelwidth = 255,sx = 0.94,sy = 1}
    }
    for i,info in ipairs(infoTab) do
        local label = self.m_jackpotBar:findChild(info.name)
        local value = self.m_machine:BaseMania_updateJackpotScore(i)
        label:setString(util_formatCoins(value,20,nil,nil,true))
        self:updateLabelSize({label = label,sx = info.sx,sy = info.sy},info.labelwidth)
    end
end

--默认按钮监听回调
function KoiBlissPickGame:clickFunc(sender)
    if self.m_isCanClick == false then
        return
    end
    self:resetItemZOrder()
    self.m_isCanClick = false
    local name = sender:getName()
    local tag = sender:getTag()

    local item = self.m_itemTab[tag]
    sender:setTouchEnabled(false)
    item:getParent():setLocalZOrder(100)
    self.m_openIndex = self.m_openIndex + 1

    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local openType = selfData.pickRound[1][self.m_machine.m_currPickProgress].process[self.m_openIndex]
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_click)
    if openType == "Grand" then
        self:openItem(item,openType,false)
        local curJcakpotProgress = self.m_progressTab[1]
        self.m_progressTab[1] = self.m_progressTab[1] + 1
        if self.m_progressTab[1] < 3 then
            self.m_isCanClick = true
        end
        performWithDelay(self,function ()
            local baoshi = self.m_jackProgressBiaoshiTab[1][curJcakpotProgress + 1]
            --cc.Node:create()
            local flyNode = util_createAnimation("KoiBliss_dfdc_pick_lizi.csb")
            self:addChild(flyNode)
            local startWorldPos = item:getParent():convertToWorldSpace(cc.p(item:getPosition()))
            local startPos = flyNode:getParent():convertToNodeSpace(startWorldPos)
            flyNode:setPosition(startPos)

            local endWorldPos = baoshi:getParent():convertToWorldSpace(cc.p(baoshi:getPosition()))
            local endPos = flyNode:getParent():convertToNodeSpace(endWorldPos)
            local particle1 = flyNode:findChild("Particle_3")
            local particle2 = flyNode:findChild("Particle_1_0")
            local particle3 = flyNode:findChild("Particle_1")
            local callFunc2 = cc.CallFunc:create(function ()
                if particle1 and particle2 and particle3 then
                    
                    particle1:setDuration(-1)
                    particle2:setDuration(-1)
                    particle3:setDuration(-1)
                    particle1:setPositionType(0)
                    particle2:setPositionType(0)
                    particle3:setPositionType(0)
                    particle1:resetSystem()
                    particle2:resetSystem()
                    particle3:resetSystem()
                end
                
            end)
            local delay = cc.DelayTime:create(5/30)
            local callFunc3 = cc.CallFunc:create(function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_collect_jp )
            end)
            local moveto = cc.MoveTo:create(10/30,endPos)
            local callFunc = cc.CallFunc:create(function ()
                if particle1 and particle2 and particle3 then
                    particle1:stopSystem()
                    particle2:stopSystem()
                    particle3:stopSystem()
                end
                self.m_collectEndProgressTab[1] = self.m_collectEndProgressTab[1] + 1
                local curCollectEndProgress = self.m_collectEndProgressTab[1]
                baoshi:playAction("actionframe_fankui",false,function ()
                    if self.m_collectEndProgressTab[1] == 2 then
                        if self.m_collectEndProgressTab[1] == 2 and self.m_isEnd == false then
                            self.m_jackProgressBiaoshiTab[1][3]:playAction("idle2",true)
                        end
                    end
                    if curCollectEndProgress >= 3 then
                        self:gameEnd()
                    end
                end)

            end)
            local delay1 = cc.DelayTime:create(0.5)
            local callFunc1 = cc.CallFunc:create(function ()
                flyNode:removeFromParent()
            end)
            --delay
            local seq = cc.Sequence:create(callFunc2,callFunc3,moveto,callFunc,delay1,callFunc1)
            flyNode:runAction(seq)
            -- item:playAction("shouji")

        end,40/60)
    elseif openType == "Major" then
        self:openItem(item,openType,false)
        local curJcakpotProgress = self.m_progressTab[2]
        self.m_progressTab[2] = self.m_progressTab[2] + 1
        if self.m_progressTab[2] < 3 then
            self.m_isCanClick = true
        end
        performWithDelay(self,function ()
            local baoshi = self.m_jackProgressBiaoshiTab[2][curJcakpotProgress + 1]
            --cc.Node:create()
            local flyNode = util_createAnimation("KoiBliss_dfdc_pick_lizi.csb")
            self:addChild(flyNode)
            local startWorldPos = item:getParent():convertToWorldSpace(cc.p(item:getPosition()))
            local startPos = flyNode:getParent():convertToNodeSpace(startWorldPos)
            flyNode:setPosition(startPos)

            local endWorldPos = baoshi:getParent():convertToWorldSpace(cc.p(baoshi:getPosition()))
            local endPos = flyNode:getParent():convertToNodeSpace(endWorldPos)
            local particle1 = flyNode:findChild("Particle_3")
            local particle2 = flyNode:findChild("Particle_1_0")
            local particle3 = flyNode:findChild("Particle_1")
            local callFunc2 = cc.CallFunc:create(function ()
                if particle1 and particle2 and particle3 then
                    
                    particle1:setDuration(-1)
                    particle2:setDuration(-1)
                    particle3:setDuration(-1)
                    particle1:setPositionType(0)
                    particle2:setPositionType(0)
                    particle3:setPositionType(0)
                    particle1:resetSystem()
                    particle2:resetSystem()
                    particle3:resetSystem()
                end
                
            end)
            local delay = cc.DelayTime:create(5/30)
            local callFunc3 = cc.CallFunc:create(function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_collect_jp )
            end)
            local moveto = cc.MoveTo:create(10/30,endPos)
            local callFunc = cc.CallFunc:create(function ()
                if particle1 and particle2 and particle3 then
                    particle1:stopSystem()
                    particle2:stopSystem()
                    particle3:stopSystem()
                end
                self.m_collectEndProgressTab[2] = self.m_collectEndProgressTab[2] + 1
                local curCollectEndProgress = self.m_collectEndProgressTab[2]
                baoshi:playAction("actionframe_fankui",false,function ()
                    if self.m_collectEndProgressTab[2] == 2 then
                        if self.m_collectEndProgressTab[2] == 2 and self.m_isEnd == false then
                            self.m_jackProgressBiaoshiTab[2][3]:playAction("idle2",true)
                        end
                    end
                    if curCollectEndProgress >= 3 then
                        self:gameEnd()
                    end
                end)

            end)
            local delay1 = cc.DelayTime:create(0.5)
            local callFunc1 = cc.CallFunc:create(function ()
                flyNode:removeFromParent()
            end)
            --delay
            local seq = cc.Sequence:create(callFunc2,callFunc3,moveto,callFunc,delay1,callFunc1)
            flyNode:runAction(seq)
            -- item:playAction("shouji")

        end,40/60)
    elseif openType == "Minor" then
        self:openItem(item,openType,false)
        local curJcakpotProgress = self.m_progressTab[3]
        self.m_progressTab[3] = self.m_progressTab[3] + 1
        if self.m_progressTab[3] < 3 then
            self.m_isCanClick = true
        end
        performWithDelay(self,function ()

            local baoshi = self.m_jackProgressBiaoshiTab[3][curJcakpotProgress + 1]
            --cc.Node:create()
            local flyNode = util_createAnimation("KoiBliss_dfdc_pick_lizi.csb")
            self:addChild(flyNode)
            local startWorldPos = item:getParent():convertToWorldSpace(cc.p(item:getPosition()))
            local startPos = flyNode:getParent():convertToNodeSpace(startWorldPos)
            flyNode:setPosition(startPos)

            local endWorldPos = baoshi:getParent():convertToWorldSpace(cc.p(baoshi:getPosition()))
            local endPos = flyNode:getParent():convertToNodeSpace(endWorldPos)
            local particle1 = flyNode:findChild("Particle_3")
            local particle2 = flyNode:findChild("Particle_1_0")
            local particle3 = flyNode:findChild("Particle_1")
            local callFunc2 = cc.CallFunc:create(function ()
                if particle1 and particle2 and particle3 then
                    
                    particle1:setDuration(-1)
                    particle2:setDuration(-1)
                    particle3:setDuration(-1)
                    particle1:setPositionType(0)
                    particle2:setPositionType(0)
                    particle3:setPositionType(0)
                    particle1:resetSystem()
                    particle2:resetSystem()
                    particle3:resetSystem()
                end
                
            end)
            local delay = cc.DelayTime:create(5/30)
            local callFunc3 = cc.CallFunc:create(function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_collect_jp )
            end)
            local moveto = cc.MoveTo:create(10/30,endPos)
            local callFunc = cc.CallFunc:create(function ()
                if particle1 and particle2 and particle3 then
                    particle1:stopSystem()
                    particle2:stopSystem()
                    particle3:stopSystem()
                end
                self.m_collectEndProgressTab[3] = self.m_collectEndProgressTab[3] + 1
                local curCollectEndProgress = self.m_collectEndProgressTab[3]
                baoshi:playAction("actionframe_fankui",false,function ()
                    if self.m_collectEndProgressTab[3] == 2 then
                        if self.m_collectEndProgressTab[3] == 2 and self.m_isEnd == false then
                            self.m_jackProgressBiaoshiTab[3][3]:playAction("idle2",true)
                        end
                    end
                    if curCollectEndProgress >= 3 then
                        self:gameEnd()
                    end
                end)

            end)
            local delay1 = cc.DelayTime:create(0.5)
            local callFunc1 = cc.CallFunc:create(function ()
                flyNode:removeFromParent()
            end)
            --delay
            local seq = cc.Sequence:create(callFunc2,callFunc3,moveto,callFunc,delay1,callFunc1)
            flyNode:runAction(seq)
            -- item:playAction("shouji")
 
        end,40/60)
    elseif openType == "Mini" then
        self:openItem(item,openType,false)
        local curJcakpotProgress = self.m_progressTab[4]
        self.m_progressTab[4] = self.m_progressTab[4] + 1
        if self.m_progressTab[4] < 3 then
            self.m_isCanClick = true
        end
        performWithDelay(self,function ()
            local baoshi = self.m_jackProgressBiaoshiTab[4][curJcakpotProgress + 1]
            --cc.Node:create()
            local flyNode = util_createAnimation("KoiBliss_dfdc_pick_lizi.csb")
            self:addChild(flyNode)
            local startWorldPos = item:getParent():convertToWorldSpace(cc.p(item:getPosition()))
            local startPos = flyNode:getParent():convertToNodeSpace(startWorldPos)
            flyNode:setPosition(startPos)

            local endWorldPos = baoshi:getParent():convertToWorldSpace(cc.p(baoshi:getPosition()))
            local endPos = flyNode:getParent():convertToNodeSpace(endWorldPos)
            local particle1 = flyNode:findChild("Particle_3")
            local particle2 = flyNode:findChild("Particle_1_0")
            local particle3 = flyNode:findChild("Particle_1")
            local callFunc2 = cc.CallFunc:create(function ()
                if particle1 and particle2 and particle3 then
                    
                    particle1:setDuration(-1)
                    particle2:setDuration(-1)
                    particle3:setDuration(-1)
                    particle1:setPositionType(0)
                    particle2:setPositionType(0)
                    particle3:setPositionType(0)
                    particle1:resetSystem()
                    particle2:resetSystem()
                    particle3:resetSystem()
                end
                
            end)
            local delay = cc.DelayTime:create(5/30)
            local callFunc3 = cc.CallFunc:create(function ()
                gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_collect_jp )
            end)
            local moveto = cc.MoveTo:create(10/30,endPos)
            local callFunc = cc.CallFunc:create(function ()
                if particle1 and particle2 and particle3 then
                    particle1:stopSystem()
                    particle2:stopSystem()
                    particle3:stopSystem()
                end
                self.m_collectEndProgressTab[4] = self.m_collectEndProgressTab[4] + 1
                local curCollectEndProgress = self.m_collectEndProgressTab[4]
                baoshi:playAction("actionframe_fankui",false,function ()
                    if self.m_collectEndProgressTab[4] == 2 then
                        if self.m_collectEndProgressTab[4] == 2 and self.m_isEnd == false then
                            self.m_jackProgressBiaoshiTab[4][3]:playAction("idle2",true)
                        end
                    end
                    if curCollectEndProgress >= 3 then
                        performWithDelay(self,function()
                            self:gameEnd()
                        end,0.5)
                        
                    end
                end)

            end)
            local delay1 = cc.DelayTime:create(0.5)
            local callFunc1 = cc.CallFunc:create(function ()
                flyNode:removeFromParent()
            end)
            --delay
            local seq = cc.Sequence:create(callFunc2,callFunc3,moveto,callFunc,delay1,callFunc1)
            flyNode:runAction(seq)
            -- item:playAction("shouji")

        end,40/60)
    else
        self:openItem(item,openType,false)
        self.m_isCanClick = true
    end
end
function KoiBlissPickGame:changeJackpotBarState(state)
    if self.m_jackpotBar.m_state == state then
        return
    end
    self.m_jackpotBar.m_state = state
    if state == 1 then
        self.m_jackpotBar:playAction("idleframe",true)
    elseif state == 2 then
        self.m_jackpotBar:playAction("actionframe",true)
    end
end

--打开选项币
function KoiBlissPickGame:openItem(item,_openType,isEnd)
    local openType = _openType
    if item.m_isOpen == true then
        openType = item.m_openType
    end

    if isEnd == true then
        item:findChild(openType):setVisible(true)

        local darkList = self.m_ItemDarkList[openType]
        for ii=1,#darkList do
            local name = darkList[ii]
            item:findChild(name):setVisible(true)
        end

        item:playAction("actionframe1")
        item.m_openType = openType
    else
        item.m_isOpen = true
        item:findChild(openType):setVisible(true)
        item:playAction("dianji")
        item.m_openType = openType
    end

    self:updateItemLightVisible(item)
end
--小游戏结束
function KoiBlissPickGame:gameEnd()
    self.m_isEnd = true
    self.m_delayNode:stopAllActions()
    for i,v in ipairs(self.m_progressTab) do
        if v == 2 then
            self.m_jackProgressBiaoshiTab[i][3]:playAction("idle")
        end
    end
    --翻开未开的罐子
    local jackpotType = {"Mini","Mini","Mini","Minor","Minor","Minor","Major","Major","Major","Grand","Grand","Grand","Pick"}
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local winType = selfData.pickRound[1][self.m_machine.m_currPickProgress].winJackpot[1]

    for i,openType in ipairs(selfData.pickRound[1][self.m_machine.m_currPickProgress].process) do
        for j,v in ipairs(jackpotType) do
            if v == openType then
                table.remove(jackpotType,j)
                break
            end
        end
    end
    jackpotType = util_randomTable(jackpotType)
    local delayTim = 0
    if #jackpotType > 0 then
        local endIndex = 1
        for i,item in ipairs(self.m_itemTab) do
            if item.m_isOpen == false then
                self:openItem(item,jackpotType[endIndex],true)
                endIndex = endIndex + 1
            end
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_Noclick_show)
        for i,item in ipairs(self.m_itemTab) do
          if item.m_isOpen == true and item.m_openType ~= winType and  item.m_openType ~= "Pick" then
                item:playAction("dark")
                local darkList = self.m_ItemDarkList[item.m_openType]
                for ii=1,#darkList do
                    local name = darkList[ii]
                    item:findChild(name):setVisible(true)
                end
            end
         
        end
        delayTim = 30/30
    end

    

    performWithDelay(self,function ()
        self:resetItemZOrder()
        for i,item in ipairs(self.m_itemTab) do
            if item.m_openType == winType then
                item:getParent():setLocalZOrder(100)
                item:playAction("actionframe")
            end
        end
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_jackpot)
        self.m_jackpotBar:findChild("zhongjiang_"..winType):setVisible(true)
        self:changeJackpotBarState(2)
        self.m_machine.shouji_bd:stopAllActions()
        self.m_machine.shouji_bd:setVisible(true)
        util_spinePlay(self.m_machine.shouji_bd,"actionframe_pick")
        local bdTime = self.m_machine.shouji_bd:getAnimationDurationTime("actionframe_pick") 
        performWithDelay(self.m_machine.shouji_bd,function ()
            self.m_machine.shouji_bd:setVisible(false)
        end,bdTime)
        PublicConfig.fishRippleActionForJackpot(self.m_machine.m_fishJuese1.p_gridNode, self.m_machine.m_fishJuese1.p_grid3D, cc.p(self.m_machine.m_fishJuese1.worldPos))
        util_spinePlay(self.m_machine.m_fishJuese2,"jackpot_actionframe",true)
        util_spinePlay(self.m_machine.m_fishJuese1,"jackpot_actionframe",true)
        performWithDelay(self,function()
            util_spinePlay(self.m_machine.m_fishJuese2,"jackpot_idle",true)
            util_spinePlay(self.m_machine.m_fishJuese1,"jackpot_idle",true)
            gLobalNoticManager:postNotification("CodeGameScreenKoiBlissMachine_pickGameShowJackpotView")
        end,120/30)
        
    end,delayTim)
end
function KoiBlissPickGame:playPickAni(func)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    local winType = selfData.pickRound[1][self.m_machine.m_currPickProgress].winJackpot[1]
    for i,item in ipairs(self.m_itemTab) do
        if item.m_isOpen == true and item.m_openType == "Pick" then
            item:getParent():setLocalZOrder(200 + item:getParent():getLocalZOrder())
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_again)
            item:playAction("actionframe",false,function ()
                if func then
                    func()
                end
            end)
        elseif item.m_openType == winType then
            item:playAction("dark")
        end
    end

end
function KoiBlissPickGame:createFlyNode(flyType)
    local flyNode = util_createAnimation("KoiBliss_dfdc_pick.csb")
    flyNode:findChild("Panel_1"):setVisible(false)

    -- flyNode.m_spine = util_spineCreate("Socre_GoldCauldron_Bonus",true,true)
    -- flyNode:addChild(flyNode.m_spine)

    -- flyNode.m_label = util_createAnimation("GoldCauldron_pick_xuanxiang.csb")
    flyNode:findChild("Pick"):setVisible(false)
    flyNode:findChild("Grand"):setVisible(false)
    flyNode:findChild("Major"):setVisible(false)
    flyNode:findChild("Minor"):setVisible(false)
    flyNode:findChild("Mini"):setVisible(false)
    flyNode:findChild(flyType):setVisible(true)
    -- util_spinePushBindNode(flyNode.m_spine,"shuzi",flyNode.m_label)


    return flyNode
end

function KoiBlissPickGame:playItemResetAinm(_func)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_KoiBliss_pick_reset)
    self.m_chongzhi:setVisible(true)
    self.m_chongzhi:runCsbAction("actionframe",false,function()
        self.m_chongzhi:setVisible(false)
        performWithDelay(self,function()
            if _func then
                _func()
            end
        end,0.5)
    end)

    local resetAnim = {
        [1] = {["7"] = "reset3"},
        [2] = {["2"] = "reset1",["3"] = "reset3",["6"] = "reset1", ["8"] = "reset3",["11"] = "reset1",["12"] = "reset3"},
        [3] = {["1"] = "reset2",["4"] = "reset4" ,["5"] = "reset2",["9"] = "reset4",["10"] = "reset2",["13"] = "reset4"}
    }
    local isPlay = false
    local cutTime = 8/30
    for i=1,#resetAnim do
        local data = resetAnim[i]
        performWithDelay(self,function()
            for index,animName in pairs(data) do
                local item = self.m_itemTab[tonumber(index)]
                item:playAction(animName)
            end
        end,cutTime * (i-1))
    end
    
end

return KoiBlissPickGame