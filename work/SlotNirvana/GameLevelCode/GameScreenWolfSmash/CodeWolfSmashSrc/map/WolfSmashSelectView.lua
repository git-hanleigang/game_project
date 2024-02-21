---
--xcyy
--2018年5月23日
--WolfSmashSelectView.lua

local WolfSmashSelectView = class("WolfSmashSelectView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"

local CURCLICKTYPE = {
    PLAY = 1,
    RANDOM = 2,
    RESET = 3,
    PIG = 4,
    STOP = 5,
}

function WolfSmashSelectView:initUI(machine)

    self:createCsbNode("WolfSmash/FreeSpinStart.csb")
    self.m_machine = machine
    self.m_Click = false
    self.pigMultipleList = {}
    self.selectList = {}
    self.randomTempList = {}
    self.curClickIndexList = {}         --当前点击过的小猪顺序
    self.curClickIndex = 0
    self.curClickType = 0
    self.totalClickIndex = 0
    self.randomShowIndex = 1
    
    self.endCall1 = nil
    self.endCall2 = nil

    --引导相关
    self:findChild("Panel_yd"):setVisible(true)
    self:addClick(self:findChild("Panel_yd")) -- 非按钮节点得手动绑定监听
    --
    self.isShowGuide = self.m_machine.isFirstInGame or false        --是否引导
    self.curGuideIndex = 1       --当前引导进度
    self.guidePointList = {}
    self.guideTipsList = {}
    self.guideBtnList = {}
    self.guideBlack = nil
    self.guideNode = cc.Node:create()
    self:addChild(self.guideNode)
    self.m_guideClick = false

    self.smallMap = util_createView("CodeWolfSmashSrc.map.WolfSmashSmallMapView",self)
    self:findChild("Node_11"):addChild(self.smallMap)

    self.selectBtnList = {}
    self:addSelectBtn()

    self:addPigForView()
    
    self:runCsbAction("start",false,function ()
        self:showClickBottomEnabled(2,false)
        self:showClickBottomEnabled(3,false)
        -- self:setPlayBottom(false)
        -- self:setResetBottom(false)
        if self.isShowGuide then
            self:delayCallBack(0.5,function ()
                self:showClickBottomEnabled(1,false)
                self:addGuideDimmingEffect()
                self:addNewBtnForIndex()
                self:addPointAndTipsForIndex()
            end)
            self:delayCallBack(1,function ()
                
                self:showGuideEffectForIndex()
                self:delayCallBack(20/60,function ()
                    self.m_guideClick = true
                end)
                
            end)
        else
            self:findChild("Panel_yd"):setVisible(false)
            self.m_Click = true
            
        end
        
        self:runCsbAction("idle",true)
        
    end)
    
    self:delayCallBack(6/60,function ()
        self.m_machine:changeBgShow(1)
    end)

    self.randomNode = cc.Node:create()
    self:addChild(self.randomNode)

    

    self.isRandomNow = false

    self.flyParticleNode = cc.Node:create()
    self:addChild(self.flyParticleNode,1000)
end


function WolfSmashSelectView:setEndCall(EndCall1,EndCall2)
    self.endCall1 = EndCall1
    self.endCall2 = EndCall2
end

function WolfSmashSelectView:setCurClickType(type)
    self.curClickType = type
end

function WolfSmashSelectView:addSelectBtn()
    self.selectBtnList = {}
    for i=1,3 do
        local btnItem = util_createView("CodeWolfSmashSrc.map.WolfSmashSelectBtnView",self,i)
        self:findChild("bottomSe_"..i):addChild(btnItem)
        btnItem.index = i
        self.selectBtnList[#self.selectBtnList + 1] = btnItem
    end
end

function WolfSmashSelectView:showClickBottomEnabled(index,isEnabled)
    if self.selectBtnList[index] and self.selectBtnList[index].index == index then
        self.selectBtnList[index]:setBottomEnabled(isEnabled)
    end
end

--默认按钮监听回调
function WolfSmashSelectView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if self.isShowGuide then
        self:guideClickPanel(name)
    else
        -- if not self.m_Click or self.curClickType == CURCLICKTYPE.PLAY then
        --     return
        -- end
        -- gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_click)
        -- if name == "Button_play" then
        --     self:showPlayClick()
        -- elseif name == "Button_random" then         --点击随机按钮
        --     self:showRandomClick()
        -- elseif name == "Button_reset" then          --点击重置按钮
        --     self:showResetClick()
        -- end
    end

    

    
end

function WolfSmashSelectView:guideClickPanel(name)
    if not self.m_guideClick then
        return
    end
    if self.isShowGuide then
        if name == "Panel_yd" then
            if self.curGuideIndex == 1 then
                self.guideTempPig:showClickEffect()
            elseif self.curGuideIndex == 2 then
                self:showGuideTwoClick()
            elseif self.curGuideIndex == 3 then
                self:showGuideThreeClick()
            elseif self.curGuideIndex == 4 then
                self:showGuideFourClick()
            end
        end
    end
end

--------------点击相关
function WolfSmashSelectView:showPlayClick()
    if self.curClickType == CURCLICKTYPE.PLAY then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_free_select_hide)
    if self.curClickIndex == self.totalClickIndex then
        self.curClickType = CURCLICKTYPE.PLAY
        self.m_Click = false
        self.m_machine.m_selectList = self.selectList
        self:showClickBottomEnabled(2,false)
        -- self:setPlayBottom(false)
        self:runCsbAction("over",false)
        self:delayCallBack(2/60,function ()
            if type(self.endCall2) == "function" then
                self.endCall2()
            end
        end)
        self:delayCallBack(12/60,function ()
            self.smallMap:setVisible(false)
            for i,v in ipairs(self.pigMultipleList) do
                if v then
                    v:setVisible(false)
                end
                
            end
        end)
        self:delayCallBack(15/60,function ()
            self:removeAllFlyNode()
            
            if type(self.endCall1) == "function" then
                self.endCall1()
                
                
            end
            self:removeFromParent()
        end)
    end
end

function WolfSmashSelectView:showResetClick()
    if self.curClickType == CURCLICKTYPE.RESET then
        return
    end
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_bonus_shuaxin)
    -- self:setPlayBottom(false)
    self:showClickBottomEnabled(2,false)
    if self.curClickType == CURCLICKTYPE.RANDOM and self.isRandomNow then           --当前状态：随机中
        self.curClickType = CURCLICKTYPE.STOP
        
        self:setClickForStop()
        self.randomNode:stopAllActions()

        self:removeAllFlyNode()
        self:randomStopForEffect()
        self.isRandomNow = false
        if self.curClickIndex == self.totalClickIndex then
            self:showClickBottomEnabled(2,true)
            self:showClickBottomEnabled(1,false)
            -- self:setPlayBottom(true)
            -- self:findChild("Button_random"):setEnabled(false)
        end
        if self.curClickIndex == 0 then
            self:showClickBottomEnabled(3,false)
        end
        
    elseif self.curClickType == CURCLICKTYPE.STOP then          --当前状态：随机停止
        self.curClickType = CURCLICKTYPE.RESET
        self:resetAllMapPig()
        self:showClickBottomEnabled(1,true)
        self:showClickBottomEnabled(3,false)
        -- self:findChild("Button_random"):setEnabled(true)
        -- self:setResetBottom(false)
    elseif self.curClickType == CURCLICKTYPE.PIG then           --当前状态：点击小猪
        self.curClickType = CURCLICKTYPE.STOP
        self.randomNode:stopAllActions()
        self:resetAllMapPig()
        self:showClickBottomEnabled(1,true)
        self:showClickBottomEnabled(3,false)
        -- self:findChild("Button_random"):setEnabled(true)
        -- self:setResetBottom(false)
        self.curClickType = CURCLICKTYPE.RESET
    else
        self.curClickType = CURCLICKTYPE.RESET
        self:resetAllMapPig()
        self:showClickBottomEnabled(1,true)
        self:showClickBottomEnabled(3,false)
        -- self:findChild("Button_random"):setEnabled(true)
        -- self:setResetBottom(false)
    end
end

function WolfSmashSelectView:showRandomClick()
    if self.curClickType == CURCLICKTYPE.RANDOM then
        return
    end
    -- self:setResetBottom(true)
    self:showClickBottomEnabled(3,true)
    self.isRandomNow = true
    self.randomTempList = self:getListForMultiple()
    local multiple = {}
    self.randomShowIndex = 1
    local pigMultipleNum = 0
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    
    if self.curClickType == CURCLICKTYPE.PIG then       --当前是点击小猪状态
        self.curClickType = CURCLICKTYPE.RANDOM
        self:getListForClick()
        randomShuffle(self.randomTempList)
        if selfData and selfData.multiple then
            multiple = clone(selfData.multiple)
        end
        pigMultipleNum = #self.randomTempList
    elseif self.curClickType == CURCLICKTYPE.STOP then      --当前是随机暂停状态
        self.curClickType = CURCLICKTYPE.RANDOM
        self:getListForClick()
        randomShuffle(self.randomTempList)
        if selfData and selfData.multiple then
            multiple = clone(selfData.multiple)
        end
        pigMultipleNum = #self.randomTempList
    else
        randomShuffle(self.randomTempList)
        self.curClickType = CURCLICKTYPE.RANDOM
        if selfData and selfData.multiple then
            multiple = clone(selfData.multiple)
            pigMultipleNum = #multiple
        end
    end
    
    for i,v in ipairs(self.pigMultipleList) do
        v:setClick(false)
    end
    self:randomSelectPigMutiple(multiple,pigMultipleNum)

end

function WolfSmashSelectView:randomSelectPigMutiple(multiple,pigMultipleNum)

    if self.randomShowIndex > pigMultipleNum then
        if self.curClickIndex == self.totalClickIndex then
            -- self:setPlayBottom(true)
            self:showClickBottomEnabled(2,true)
        end
        --是否引导
        if self.isShowGuide then
            self:delayCallBack(1,function ()
                --播放下一轮
                self.curGuideIndex = 4
                self:showGuideEffectForIndex()
            end)
            
        else
            
            -- self:findChild("Button_random"):setEnabled(false)
            self:showClickBottomEnabled(1,false)
            self.randomShowIndex = 1
            self.randomTempList = {}
            
        end
        self:delayCallBack(0.5,function ()
            self.isRandomNow = false
        end)
        
        return
    end
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        if self.curClickType == CURCLICKTYPE.STOP then
            return
        end
        local index = self.randomTempList[self.randomShowIndex]
        local pigItem = self.pigMultipleList[index]
        local curmultiple = multiple[pigItem.index]
        self.selectList[#self.selectList + 1] = curmultiple
        self.curClickIndexList[#self.curClickIndexList + 1] = index
        util_spinePlay(pigItem.pigSpine, "shouji", false)
        gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_free_select_clickPig)
        local clickPigIndex = pigItem.index
        self.curClickIndex = self.curClickIndex + 1
        local curIndex = self.curClickIndex
        local startPos = util_convertToNodeSpace(pigItem,self.flyParticleNode)
        
        self:FlyParticle(startPos,function ()
            if self.curClickType == CURCLICKTYPE.STOP then
                return
            end
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_free_select_clickPig_fankui)
            self:clickPigForMapShow(curIndex,curmultiple,clickPigIndex)
        end)
    end)
    actList[#actList + 1] = cc.DelayTime:create(0.3)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        
        if self.curClickType == CURCLICKTYPE.STOP then
            return
        end
        self.randomShowIndex = self.randomShowIndex + 1
        self:randomSelectPigMutiple(multiple,pigMultipleNum)
    end)
    local sq = cc.Sequence:create(actList)
    self.randomNode:runAction(sq)
end

--[[
    @desc: 点击猪展示地图猪相关
    author:{author}
    time:2023-02-06 17:36:11
    --@sender: 
    @return:
]]
function WolfSmashSelectView:clickPigForMapShow(index,multiple,clickPigIndex)
    
    if self.curClickType == CURCLICKTYPE.STOP then
        return
    end
    self.smallMap:createPigForMap(index,multiple,clickPigIndex)
    if self.curClickIndex >= self.totalClickIndex then
        self:showClickBottomEnabled(1,false)
        -- self:findChild("Button_random"):setEnabled(false)
    end
end

--[[
    @desc: 重置相关
    author:{author}
    time:2023-02-06 17:37:04
    @return:
]]
function WolfSmashSelectView:resetAllMapPig()
    self.selectList = {}
    self.curClickIndexList = {}
    self:removeAllFlyNode()
    self.smallMap:restAllPig()
    self.curClickIndex = 0
    if not self.isShowGuide then
        self.m_Click = true
    end
    
    for i,v in ipairs(self.pigMultipleList) do
        if v then
            v:setClick(true)
            v:setIdle()
        end
        
    end
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.multiple then
        local multiple = clone(selfData.multiple)
        self.totalClickIndex = #multiple
    end
end

function WolfSmashSelectView:getListForMultiple()
    local tempList = {}
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.multiple then
        local multiple = clone(selfData.multiple)
        for i,v in ipairs(multiple) do
            tempList[#tempList + 1] = i
        end
    end
    return tempList
end

function WolfSmashSelectView:getListForClick()
    for i,v in ipairs(self.curClickIndexList) do
        for j,k in ipairs(self.randomTempList) do
            if tonumber(v) == tonumber(k) then
                table.remove(self.randomTempList,j)
            end
        end
    end
end


function WolfSmashSelectView:setClickForStop()
    for i,v in ipairs(self.pigMultipleList) do
        v:setClick(true)
    end
    for i,v in ipairs(self.curClickIndexList) do
        
        for j,k in ipairs(self.pigMultipleList) do
            local pigItem = self.pigMultipleList[j]
            if pigItem then
                if pigItem.index == v then
                    pigItem:setClick(false)
                end
            end
            
            
        end
    end
    
    
end

--[[
    @desc: 随机相关
    author:{author}
    time:2023-02-06 17:35:32
    @return:
]]

--随机暂停重置相关数据
function WolfSmashSelectView:randomStopForEffect()
    local mapPigList = self.smallMap.pigMultipleList       --小地图上的猪
    --同步选择列表
    self.selectList  = {}
    for i,v in ipairs(mapPigList) do
        self.selectList[#self.selectList + 1] = v.multiple
    end
    self.curClickIndex = #self.selectList
    self.curClickIndexList = {}
    for i,node in ipairs(mapPigList) do
        self.curClickIndexList[#self.curClickIndexList + 1] = node.clickPigIndex
    end

    --未选择的小猪重置
    for i,v in ipairs(self.pigMultipleList) do
        util_spinePlay(v.pigSpine, "idleframe2", true)
        v:setClick(true)
    end
    
    for i,v in ipairs(mapPigList) do
        local pigNode = self.pigMultipleList[v.clickPigIndex]
        if pigNode then
            util_spinePlay(pigNode.pigSpine, "shouji_idle", false)
            pigNode:setClick(false)
        end
    end
    self:showClickBottomEnabled(1,true)
    -- self:findChild("Button_random"):setEnabled(true)
end



--[[
    @desc: 添加可点击猪相关
    author:{author}
    time:2023-02-06 17:35:54
    --@coinsView:
	--@multiple: 
    @return:
]]
function WolfSmashSelectView:changeChengBeiShow(coinsView,multiple)
    local curChild = {
        "Node_X2",
        "Node_X3",
        "Node_X5",
        "Node_X10",
    }
    for i,v in ipairs(curChild) do
        coinsView:findChild(v):setVisible(false)
    end
    if multiple == 2 then
        coinsView:findChild(curChild[1]):setVisible(true)
    elseif multiple == 3 then
        coinsView:findChild(curChild[2]):setVisible(true)
    elseif multiple == 5 then
        coinsView:findChild(curChild[3]):setVisible(true)
    elseif multiple == 10 then
        coinsView:findChild(curChild[4]):setVisible(true)
    end
end

function WolfSmashSelectView:getPigMultiple(index,multiple)
    local pigSpine = util_spineCreate("Socre_WolfSmash_Bonus",true,true)
    if multiple == 10 then
        pigSpine:setSkin("gold")
    else
        pigSpine:setSkin("red")
    end
    local cocosName = "WolfSmash_chengbei.csb"
    local coinsView = util_createAnimation(cocosName)
    self:changeChengBeiShow(coinsView,multiple)
    util_spinePushBindNode(pigSpine,"cb",coinsView)
    coinsView:runCsbAction("idle")
    local pigCsb = util_createView("CodeWolfSmashSrc.map.WolfSmashBonusForSelectView",self,index)
    pigCsb:addPigSpine(pigSpine)
    pigCsb:setMultiple(multiple)
    pigCsb.pigSpine = pigSpine
    pigCsb.index = index
    util_spinePlay(pigSpine, "idleframe2", true)
    return pigCsb
end

-- function WolfSmashSelectView:setPlayBottom(isEnabled)
--     self:findChild("Button_play"):setEnabled(isEnabled)
-- end

-- function WolfSmashSelectView:setResetBottom(isEnabled)
--     self:findChild("Button_reset"):setEnabled(isEnabled)
-- end

function WolfSmashSelectView:addPigForView()
    self.pigMultipleList = {}
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.multiple then
        local multiple = clone(selfData.multiple)
        self.totalClickIndex = #multiple
        for i,v in ipairs(multiple) do
            local pigItem = self:getPigMultiple(i,v)
            pigItem.index = i
            self.pigMultipleList[#self.pigMultipleList + 1] = pigItem
            pigItem.isFly = false
            self:findChild("Node_"..i.."_"..self.totalClickIndex):addChild(pigItem)
        end
    end
end

function WolfSmashSelectView:removeAllFlyNode()
    self.flyParticleNode:removeAllChildren()
end

---飞行粒子相关
function WolfSmashSelectView:FlyParticle(startPos,func)
    -- -- 创建粒子
    local flyNode =  util_createAnimation("Socre_WolfSmash_tv.csb")
    self.flyParticleNode:addChild(flyNode,100)
    flyNode:setPosition(startPos)
    local endPosNode = self.smallMap:getEndNode(self.curClickIndex)
    local endPos = util_convertToNodeSpace(endPosNode,self)
    local particle1 = flyNode:findChild("Particle_3")
    local particle2 = flyNode:findChild("Particle_1")
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if self.curClickType == CURCLICKTYPE.STOP then
            -- flyNode:removeFromParent()
            return
        end
        particle1:setDuration(-1)     --设置拖尾时间(生命周期)
        particle1:setPositionType(0)   --设置可以拖尾
        particle1:resetSystem()

        particle2:setDuration(-1)
        particle2:setPositionType(0)
        particle2:resetSystem()
    end)
    actList[#actList + 1] = cc.MoveTo:create(0.5, endPos)
    
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if self.curClickType == CURCLICKTYPE.STOP then
            -- flyNode:removeFromParent()
            return
        end
        particle1:stopSystem()--移动结束后将拖尾停掉
        particle2:stopSystem()
    end) 
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        if self.curClickType == CURCLICKTYPE.STOP then
            -- flyNode:removeFromParent()
            return
        end
        if func then
            func()
        end
    end) 
    actList[#actList + 1] = cc.DelayTime:create(1)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        -- flyNode:removeFromParent()
    end) 
    flyNode:runAction(cc.Sequence:create( actList))
end

-- -----------------------------------------新手引导相关

--根据流程下标走对应引导
--最后修改：先点猪 --然后点击reset功能 重置 --然后点击random --随机 --然后同时亮 play 和 reset ，点play就进去，点reset就重置回去（压暗取消）
function WolfSmashSelectView:showGuideEffectForIndex()
    if self.curGuideIndex == 1 then         --先点猪
        self:showGuideOneEffect()
    elseif self.curGuideIndex == 2 then      --重置
        self:showGuideTwoEffect()
    elseif self.curGuideIndex == 3 then       --重置
        self:delayCallBack(0.5,function ()
            self:showGuideThreeEffect()
        end)
    elseif self.curGuideIndex == 4 then         --play
        self:showGuideFourEffect()
    end
end

--点击小猪引导
--创建一个临时小猪（固定第二只小猪），点击之后压暗，对应的真小猪也压暗，飞粒子，地图上创建小猪，飞粒子结束干掉临时小猪
function WolfSmashSelectView:showGuideOneEffect()
    self:showGuideDimmingEffect(true)
    self:createTempPig()
    self:showPointAndTipsForIndex(true,1)
    self:delayCallBack(20/60,function ()
        self.m_guideClick = true
    end)
    
    --三秒后自动展示
    self:delayCallBackForGuide(function ()
        self.guideTempPig:showClickEffect()
    end)
end

--点击重置引导
--其他两个按钮不能点击
function WolfSmashSelectView:showGuideTwoEffect()
    self:showPointAndTipsForIndex(true,3)
    self:showNewBtnForIndex(true,2)
    -- self:showGuideDimmingEffect(false)
    self:delayCallBack(20/60,function ()
        self.m_guideClick = true
    end)
    self:delayCallBackForGuide(function ()
        self:showGuideTwoClick()
    end)
end
--点击重置按钮后
function WolfSmashSelectView:showGuideTwoClick()
    self.m_guideClick = false
    self.guideNode:stopAllActions()
    self:showPointAndTipsForIndex(false,3)
    self:showNewBtnForIndex(false,2)
    -- self:showGuideDimmingEffect(false)
    
    self:delayCallBack(20/60,function ()
        self:showResetClick()
        self.curGuideIndex = 3
        self:showGuideEffectForIndex()
    end)
    
end

--点击重置引导showGuideFourEffect
function WolfSmashSelectView:showGuideThreeEffect()
    self:showPointAndTipsForIndex(true,2)
    self:showNewBtnForIndex(true,1)
    -- self:showGuideDimmingEffect(true)
    self:delayCallBack(20/60,function ()
        self.m_guideClick = true
    end)
    self:delayCallBackForGuide(function ()
        self:showGuideThreeClick()
    end)
end
--点击reset后，压暗消失，走正常重置流程showGuideFourClick
function WolfSmashSelectView:showGuideThreeClick()
    self.guideNode:stopAllActions()
    self:showPointAndTipsForIndex(false,2)
    self:showNewBtnForIndex(false,1)
    self.m_guideClick = false
    self:showGuideDimmingEffect(false)
    self:delayCallBack(20/60,function ()
        self:showRandomClick()
    end)
    
end

--点击重置引导showGuideThreeEffect
function WolfSmashSelectView:showGuideFourEffect()
    self:findChild("Panel_yd"):setVisible(false)
    self:showPointAndTipsForIndex(true,4)
    self:showNewBtnForIndex(true,4)
    self:showGuideDimmingEffect(true)
    self:delayCallBack(20/60,function ()
        self.m_guideClick = true
    end)
    self:delayCallBackForGuide(function ()
        self:showGuideFourClick()
    end)
end
--点击play后继续展示resetshowGuideThreeClick
function WolfSmashSelectView:showGuideFourClick()
    self.guideNode:stopAllActions()
    self:showPointAndTipsForIndex(false,4)
    self:showNewBtnForIndex(false,4)
    self:showGuideDimmingEffect(false)
    self.m_guideClick = false
    self:delayCallBack(20/60,function ()
        self:hideAllGuideChild()
    end)
end

function WolfSmashSelectView:showGuideFourClickForPlay()
    self:showPlayClick()
end

function WolfSmashSelectView:showGuideFourClickForReset()
    self:showResetClick()
end

--创建临时小猪
function WolfSmashSelectView:createTempPig()
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.multiple then
        local multiple = clone(selfData.multiple)
        local multipleIndex = multiple[2]
        local pigSpine = util_spineCreate("Socre_WolfSmash_Bonus",true,true)
        if multipleIndex == 10 then
            pigSpine:setSkin("gold")
        else
            pigSpine:setSkin("red")
        end
        local cocosName = "WolfSmash_chengbei.csb"
        local coinsView = util_createAnimation(cocosName)
        self:changeChengBeiShow(coinsView,multipleIndex)
        util_spinePushBindNode(pigSpine,"cb",coinsView)
        coinsView:runCsbAction("idle")
        self.guideTempPig = util_createView("CodeWolfSmashSrc.map.WolfSmashBonusForTempView",self,2)
        -- self.guideTempPig:setScale(self.m_machine.m_machineRootScale)
        self.guideTempPig:addPigSpine(pigSpine)
        self.guideTempPig:setMultiple(multipleIndex)
        self.guideTempPig.pigSpine = pigSpine
        util_spinePlay(pigSpine, "idleframe2", true)
        local pos = util_convertToNodeSpace(self.pigMultipleList[2],self:findChild("Node_guide"))
        self:findChild("Node_guide"):addChild(self.guideTempPig,10)
        self.guideTempPig:setPosition(pos)
        self.guideTempPig:setScaleX(0.67)
        self.guideTempPig:setScaleY(0.67)
    end
    
end


--添加手指和文本
function WolfSmashSelectView:addPointAndTipsForIndex()
    for i=1,4 do
        
        local tipsItem = util_createView("CodeWolfSmashSrc.map.WolfSmashSelectTipsView",i)
        local pointItem = util_createView("CodeWolfSmashSrc.map.WolfSmashSelectPointView")
        --第一个阶段的猪没有挂点
        if i == 1 then
            local pos = util_convertToNodeSpace(self.pigMultipleList[2],self:findChild("Node_guide"))
            self:findChild("Node_guide"):addChild(pointItem,11)
            pointItem:setPosition(cc.p(pos.x + 20 ,pos.y - 70))
            tipsItem:setPosition(cc.p(pos.x - 80 ,pos.y + 100))
            self:findChild("Node_guide"):addChild(tipsItem,11)
            
            

        else
            self:findChild("Node_shouzhi_"..i):addChild(pointItem)
            self:findChild("Node_tips_"..i):addChild(tipsItem)
        end
        pointItem:setVisible(false)
        tipsItem:setVisible(false)

        self.guidePointList[#self.guidePointList + 1] = pointItem
        self.guideTipsList[#self.guideTipsList + 1] = tipsItem
    end
end

--展示手指和文本
--小猪：1 随机：2  重置：3  play:4
function WolfSmashSelectView:showPointAndTipsForIndex(isShow,index)
    if index == 4 then
        local pointItem3 = self.guidePointList[3]
        local pointItem4 = self.guidePointList[4]

        if pointItem3 and pointItem4 then
            if isShow then

                pointItem3:setVisible(true)
                pointItem4:setVisible(true)

                pointItem3:showPointStartEffect()
                pointItem4:showPointStartEffect()
            else
                pointItem3:showPointOverEffect(function ()
                    pointItem3:setVisible(false)
                end)
                pointItem4:showPointOverEffect(function ()
                    pointItem4:setVisible(false)
                end)

            end
            
        end
    else
        local tipsItem = self.guideTipsList[index]
        local pointItem = self.guidePointList[index]
        if tipsItem and pointItem then
            if isShow then
                pointItem:setVisible(true)
                tipsItem:setVisible(true)
                pointItem:showPointStartEffect()
                tipsItem:showGuideTipsStartForIndex()
            else
                tipsItem:showGuideTipsOverForIndex(function ()
                    tipsItem:setVisible(false)
                end)
                pointItem:showPointOverEffect(function ()
                    pointItem:setVisible(false)
                end)
            end
            
        end
    end
    
end


--添加按钮 随机：1  重置：2  play：3
function WolfSmashSelectView:addNewBtnForIndex()
    for i=1,3 do
        local btnItem = util_createView("CodeWolfSmashSrc.map.WolfSmashGuideBtnView",self,i)
        self:findChild("Button_yd_"..i):addChild(btnItem)
        self.guideBtnList[#self.guideBtnList + 1] = btnItem
    end
end

function WolfSmashSelectView:showNewBtnForIndex(isShow,index)
    if index == 4 then
        local btnItem3 = self.guideBtnList[2]
        local btnItem4 = self.guideBtnList[3]
        if btnItem3 and btnItem4 then
            if isShow then
                btnItem3:setVisible(true)
                btnItem3:showBtnForIndex()
                btnItem4:setVisible(true)
                btnItem4:showBtnForIndex()
            else
                btnItem3:hideBtnForIndex(function ()
                    btnItem3:setVisible(false)
                end)
                btnItem4:hideBtnForIndex(function ()
                    btnItem4:setVisible(false)
                end)
            end
            
        end
    else
        local btnItem = self.guideBtnList[index]
        if btnItem then
            if isShow then
                btnItem:setVisible(true)
                btnItem:showBtnForIndex()
            else
                btnItem:hideBtnForIndex(function ()
                    btnItem:setVisible(false)
                end)
            end
            
        end
    end
    
end

function WolfSmashSelectView:hideAllNewBtn()
    for i,v in ipairs(self.guideBtnList) do
        if v then
            v:setVisible(false)
        end
    end
end


function WolfSmashSelectView:addGuideDimmingEffect()
    self.guideBlack = util_createAnimation("Socre_WolfSmash_tbzz.csb")
    self:findChild("zhezhao_yd"):addChild(self.guideBlack)
end

--展示压暗
function WolfSmashSelectView:showGuideDimmingEffect(isShow,func)
    if self.guideBlack then
        if isShow then
            self.guideBlack:runCsbAction("start",false,function ()
                self.guideBlack:runCsbAction("idleframe")
            end)
        else
            self.guideBlack:runCsbAction("over")
            
        end
    end
end


function WolfSmashSelectView:isShowGuide(isShow)
    self.isShowGuide = isShow
end

function WolfSmashSelectView:setRealBtnClick()
    
end

--两秒不点击自动走下一轮
function WolfSmashSelectView:delayCallBackForGuide(_func)
    self.guideNode:stopAllActions()
    performWithDelay(self.guideNode,function ()
        if type(_func) == "function" then
            _func()
        end
    end,5)
end

--隐藏所有引导相关，恢复点击
function WolfSmashSelectView:hideAllGuideChild()
    for i,v in ipairs(self.guidePointList) do
        if v then
            v:setVisible(false)
        end
    end
    for i,v in ipairs(self.guideTipsList) do
        if v then
            v:setVisible(false)
        end
    end
    self.isShowGuide = false
    self:hideAllNewBtn()
    self.m_Click = true
    self:findChild("Panel_yd"):setVisible(false)
    self.m_machine.isFirstInGame = false
end

--[[
    延迟回调
]]
function WolfSmashSelectView:delayCallBack(time, func)
    local waitNode = cc.Node:create()
    self:addChild(waitNode)
    performWithDelay(
        waitNode,
        function()
            waitNode:removeFromParent(true)
            waitNode = nil
            if type(func) == "function" then
                func()
            end
        end,
        time
    )

    return waitNode
end

return WolfSmashSelectView