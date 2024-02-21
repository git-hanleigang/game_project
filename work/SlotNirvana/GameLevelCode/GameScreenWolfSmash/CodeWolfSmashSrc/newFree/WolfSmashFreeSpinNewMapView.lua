---
--xcyy
--2018年5月23日
--WolfSmashFreeSpinNewMapView.lua

local WolfSmashFreeSpinNewMapView = class("WolfSmashFreeSpinNewMapView",util_require("Levels.BaseLevelDialog"))
local PublicConfig = require "WolfSmashPublicConfig"


function WolfSmashFreeSpinNewMapView:initUI(machine)
    self.m_machine = machine
    self:createCsbNode("Socre_WolfSmash_xiugai_freejiemian.csb")

    self.curChoose = 1
    self.isAuto = false
    self.m_beginReelFunc = nil
    self.darkZOrder = nil
    self.viewPigList = {}  
    self.zhiZhenList = {}     
    self:createFourPigForNewMap()
    self:createDarkView()
    self:createBottomAndTips()
    self:createWolfNode()
    self:createZhiZhenNode()
    self:createDaojishiNode()
end


function WolfSmashFreeSpinNewMapView:onEnter()

    WolfSmashFreeSpinNewMapView.super.onEnter(self)

end

function WolfSmashFreeSpinNewMapView:onExit()

    WolfSmashFreeSpinNewMapView.super.onExit(self)
    self:stopUpdate()

end

function WolfSmashFreeSpinNewMapView:createFourPigForNewMap()

    for i = 1, 4 do
        local pig = util_createView("CodeWolfSmashSrc.newFree.WolfSmashNewPigBtnView",{machine = self , index = i,isFreeStart = false})
        local guaDianName = self:getPigGuaDianName(i)
        self:findChild(guaDianName):addChild(pig)
        pig:setVisible(false)
        self.viewPigList[#self.viewPigList + 1] = pig
    end
end

function WolfSmashFreeSpinNewMapView:createDarkView()
    self.darkView = util_createAnimation("Socre_WolfSmash_xiugai_pickapiggy.csb")
    self:findChild("Node_biaoti"):addChild(self.darkView)
    self.darkView:setVisible(false)
end

function WolfSmashFreeSpinNewMapView:createBottomAndTips()
    self.m_bottonNode = util_createView("CodeWolfSmashSrc.newFree.WolfSmashNewFreeBtnView",self)
    self:findChild("Node_anniu"):addChild(self.m_bottonNode)
    self.m_bottonNode:setVisible(false)

    self.m_tipsView = util_createAnimation("Socre_WolfSmash_xiugai_anniu_wenan.csb")
    self:findChild("Node_anniu_wenan"):addChild(self.m_tipsView)
    self.m_tipsView:setVisible(false)
end

function WolfSmashFreeSpinNewMapView:createWolfNode()
    self.m_wolfNode = util_createAnimation("WolfSmash_jiaobiao_lang.csb")
    self:findChild("wolfShowNode"):addChild(self.m_wolfNode)
    self.m_wolfNode:runCsbAction("idle2")
    local wolfJveSe = util_spineCreate("Socre_WolfSmash_juese",true,true)
    self.m_wolfNode:findChild("juese"):addChild(wolfJveSe)
    self.m_wolfNode.m_wolfJvse = wolfJveSe
    self.m_wolfNode.curChoose = 1
    self.m_wolfNode:setScale(0.95)
    self.m_wolfNode:setVisible(false)
end

function WolfSmashFreeSpinNewMapView:createZhiZhenNode()
    for i = 1, 4 do
        local point = util_createAnimation("Socre_WolfSmash_xiugai_zhizhen.csb")
        local guaDianName = self:getPointGuaDianName(i)
        self:findChild(guaDianName):addChild(point)
        point.isShow = false
        point:setVisible(false)
        self.zhiZhenList[#self.zhiZhenList + 1] = point
    end
end

function WolfSmashFreeSpinNewMapView:createDaojishiNode()
    self.daojishi = util_createAnimation("Socre_WolfSmash_xiugai_daojishi.csb")
    self:findChild("Node_daojishi"):addChild(self.daojishi)
    self.daojishi:setVisible(false)
end

function WolfSmashFreeSpinNewMapView:setChoosePigIndex(index)
    self.curChoose = index
end

function WolfSmashFreeSpinNewMapView:resetViewShow(initIndex)
    self:setChoosePigIndex(initIndex)
    for i, pigNode in ipairs(self.viewPigList) do
        if not tolua.isnull(pigNode) then
            pigNode:setVisible(true)
            pigNode:hideSmashPigAct()
        end
    end
    if initIndex then
        self:setWolfNodePosition(true)
    end
    self.m_bottonNode:setVisible(true)
    self.m_tipsView:setVisible(true)
    self:showAutoAllUi(false)
    self.isAuto = false
    self.m_beginReelFunc = nil
    self.daojishi:setVisible(false)
end

function WolfSmashFreeSpinNewMapView:setWolfNodePosition(isInit)
    if isInit then
        local wolfGuaDianName = self:getWolfGuaDianName(self.curChoose)
        local pos = util_convertToNodeSpace(self:findChild(wolfGuaDianName),self:findChild("wolfShowNode"))
        self.m_wolfNode:setVisible(true)
        self.m_wolfNode.curChoose = self.curChoose
        self.m_wolfNode:setPosition(pos)
        if not tolua.isnull(self.m_wolfNode) and self.m_wolfNode.m_wolfJvse then
            util_spinePlay(self.m_wolfNode.m_wolfJvse, "idle_zuo",true) 
        end
        
    else
        --移动
        local beforeIndex = self.m_wolfNode.curChoose
        local beforeWolfGuaDianName = self:getWolfGuaDianName(beforeIndex)
        local afterWolfGuaDianName = self:getWolfGuaDianName(self.curChoose)
        local afterPos = util_convertToNodeSpace(self:findChild(afterWolfGuaDianName),self:findChild("wolfShowNode"))
        self.m_wolfNode.curChoose = self.curChoose
        local actList = {}
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            --weiyi
        end)
        actList[#actList + 1] = cc.DelayTime:create(17/60)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_wolf_move)
        end)
        actList[#actList + 1] = cc.MoveTo:create(0.2,afterPos)
        actList[#actList + 1] = cc.CallFunc:create(function (  )
            -- if not self.isAuto then
                if self.m_beginReelFunc then
                    self.m_beginReelFunc()
                    self.m_beginReelFunc = nil
                end
            -- end
            --可点击按钮
        end)
        self.m_wolfNode:stopAllActions()
        self.m_wolfNode:runAction(cc.Sequence:create(actList))
    end
end

--砸
function WolfSmashFreeSpinNewMapView:showWolfStrikePig(data,func)
    local actList = {}
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        --砸（40帧）
        if not tolua.isnull(self.m_wolfNode) and self.m_wolfNode.m_wolfJvse then
            gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_wolf_smash_pig)
            util_spinePlay(self.m_wolfNode.m_wolfJvse, "jida_xia",false) 
            util_spineEndCallFunc(self.m_wolfNode.m_wolfJvse, "jida_xia", function()
                util_spinePlay(self.m_wolfNode.m_wolfJvse, "idle_zuo", true)
            end)
        end
    end)
    actList[#actList + 1] = cc.DelayTime:create(19/30)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        local pigNode = self.viewPigList[self.curChoose]
        --猪砸开 Socre_WolfSmash_zkz
        pigNode:showSmashPigAct()
    end)
    actList[#actList + 1] = cc.DelayTime:create(21/30)
    actList[#actList + 1] = cc.CallFunc:create(function (  )
        
        local pigNode = self.viewPigList[self.curChoose]
        --砸开的猪复原
        local _data = self:getDataForCurPig(data)
        if _data[2] > 0 then
            pigNode:hideSmashPigAct()
        else
            pigNode:hideSmashPigAct2()
        end
        if func then
            func()
        end
    end)
    self.m_wolfNode:stopAllActions()
    self.m_wolfNode:runAction(cc.Sequence:create(actList))
end

function WolfSmashFreeSpinNewMapView:getDataForCurPig(data)
    for i, v in ipairs(data) do
        if i == self.curChoose then
            return v
        end
    end
end

--改变猪的数量，数量为0的压暗
function WolfSmashFreeSpinNewMapView:changePigNum(_data)
    for i, v in ipairs(_data) do
        local pig = self.viewPigList[i]
        if not tolua.isnull(pig) and pig:findChild("m_lb_num") then
            pig:findChild("m_lb_num"):setString(v[2])
            if v[2] == 0 then
                self:setPigSpineDark(i,true)
            else
                self:setPigSpineDark(i,false)
            end
        end
    end
end

--数量为0的猪压暗
function WolfSmashFreeSpinNewMapView:setPigSpineDark(index,isDark)
    local pig = self.viewPigList[index]
    if isDark then
        if not tolua.isnull(pig) and pig.m_pigSpine then
            pig:showDarkForPig()
        end
    else
        if not tolua.isnull(pig) and pig.m_pigSpine then
            pig:hideDarkForPig()
        end
    end
    
end

--对应猪播反馈
function WolfSmashFreeSpinNewMapView:showPigFankui(index)
    local pig = self.viewPigList[index]
    pig:showPigFankui()
end

function WolfSmashFreeSpinNewMapView:getPigGuaDianName(index)
    if index == 1 then
        return "Node_X2piggy"
    elseif index == 2 then
        return "Node_X3piggy"
    elseif index == 3 then
        return "Node_X5piggy"
    elseif index == 4 then
        return "Node_X10piggy"
    end
end

function WolfSmashFreeSpinNewMapView:getWolfGuaDianName(index)
    if index == 1 then
        return "Node_X2wolf"
    elseif index == 2 then
        return "Node_X3wolf"
    elseif index == 3 then
        return "Node_X5wolf"
    elseif index == 4 then
        return "Node_X10wolf"
    end
end

function WolfSmashFreeSpinNewMapView:getPointGuaDianName(index)
    if index == 1 then
        return "Node_X2zhizhen"
    elseif index == 2 then
        return "Node_X3zhizhen"
    elseif index == 3 then
        return "Node_X5zhizhen"
    elseif index == 4 then
        return "Node_X10zhizhen"
    end
end

function WolfSmashFreeSpinNewMapView:getEndNode()
    local name = self:getPigGuaDianName(self.curChoose)
    return self:findChild(name)
end

function WolfSmashFreeSpinNewMapView:getEndNode2(index)
    local name = self:getPigGuaDianName(index)
    return self:findChild(name)
end

function WolfSmashFreeSpinNewMapView:getCurPigMultiple()
    if self.curChoose == 1 then
        return 2
    elseif self.curChoose == 2 then
        return 3
    elseif self.curChoose == 3 then
        return 5
    elseif self.curChoose == 4 then
        return 10
    end
end
------------------------------------------选择相关
--设置是否自动
function WolfSmashFreeSpinNewMapView:setAutoState(isAuto)
    self.isAuto = isAuto
end

function WolfSmashFreeSpinNewMapView:setChooseIndexForABTest()
    self.m_machine:setChooseIndexForABTest(self.curChoose)
end

function WolfSmashFreeSpinNewMapView:setBeginReelFunc(func)
    self.m_beginReelFunc = func
end

function WolfSmashFreeSpinNewMapView:showAllPoint(isShow,_date)
    for i, _node in ipairs(self.zhiZhenList) do
        if not tolua.isnull(_node) then
            if isShow then
                local dataInfo = _date[i] or {"2" , 0}
                if dataInfo[2] > 0 then
                    _node:setVisible(true)
                    _node.isShow = true
                    _node:runCsbAction("start",false,function ()
                        _node:runCsbAction("idle",true)
                    end)
                end
                
            else
                if _node.isShow then
                    _node:runCsbAction("over",false,function ()
                        _node.isShow = false
                        _node:setVisible(false)
                    end)
                end
            end
            
        end
    end
end

--选择文案显示
function WolfSmashFreeSpinNewMapView:showDarkAct(func,_date)
    --所有的猪设置可点击
    self:setPigNodeClick(false)
    self.m_bottonNode:setClickState(false)
    self:setBeginReelFunc(func)
    local pos = util_convertToNodeSpace(self.darkView,self)
    util_changeNodeParent(self,self.darkView,1000)
    self.darkView:setPosition(pos)
    
    -- self.darkZOrder = self:findChild("Node_biaoti"):getLocalZOrder()
    -- self:findChild("Node_biaoti"):setLocalZOrder(1000)
    self.darkView:setVisible(true)
    self.m_machine.m_newMap:findChild("Panel_click"):setVisible(true)
    gLobalSoundManager:playSound(PublicConfig.SoundConfig.sound_WolfSmash_fg_smash_gold_lighting)
    self.darkView:runCsbAction("auto",false,function ()
        self:showAllPoint(true,_date)
        local pos = util_convertToNodeSpace(self.darkView,self:findChild("Node_biaoti"))
        util_changeNodeParent(self:findChild("Node_biaoti"),self.darkView)
        self.darkView:setPosition(pos)
        self.darkView:runCsbAction("idle",true)
        --所有的猪设置可点击
        self:setPigNodeClick(true,_date)
        --10s未点击则自动选择服务器发的index
        self:startUpdate()
    end)
    self:runCsbAction("darkstart",false,function ()
        self:runCsbAction("darkidle",true)
    end)
end

--选择文案隐藏后继续走free的spin
function WolfSmashFreeSpinNewMapView:hideDarkAct()
    self:showAllPoint(false)
    self:stopUpdate()
    --15帧
    self.darkView:runCsbAction("over",false,function ()
        self.darkView:setVisible(false)
        self.m_machine.m_newMap:findChild("Panel_click"):setVisible(false)
        --所有的猪设置可点击
        self:setPigNodeClick(false)
        self.m_bottonNode:setClickState(true)
    end)
    self:runCsbAction("darkover")
end

--是否自动
function WolfSmashFreeSpinNewMapView:showAutoAllUi(isAuto)
    if isAuto then
        self.m_bottonNode:setBottomEnabled(2)
        self:setAutoState(true)
        self:setPigNodeClick(false)
    else
        self.m_bottonNode:setBottomEnabled(1)
        self:setAutoState(false)
        -- self:setPigNodeClick(true)
    end
    self.m_tipsView:findChild("WolfSmash_xiugai_wenzi_1_4"):setVisible(isAuto == false)
    self.m_tipsView:findChild("WolfSmash_xiugai_wenzi_2_5"):setVisible(isAuto == true)
    
end

function WolfSmashFreeSpinNewMapView:setPigNodeClick(isClick,_date)
    for i, pigNode in ipairs(self.viewPigList) do
        if not tolua.isnull(pigNode) then
            -- pigNode:setIsAuto(isAuto)
            if _date then
                local dataInfo = _date[i] or {"2" , 0}
                if dataInfo[2] > 0 then
                    pigNode:setIsClick(isClick)
                else
                    pigNode:setIsClick(false)
                end
            else
                pigNode:setIsClick(isClick)
            end
            
        end
    end
end

--停止刷帧
function WolfSmashFreeSpinNewMapView:stopUpdate()
    if self.m_expireALLHandlerId ~= nil then
        scheduler.unscheduleGlobal(self.m_expireALLHandlerId)
        self.m_expireALLHandlerId = nil
    end
end

--开启刷帧：倒计时10秒
function WolfSmashFreeSpinNewMapView:startUpdate()
    self:stopUpdate()
    local time = 10
    self.daojishi:setVisible(true)
    self.daojishi:findChild("BitmapFontLabel_1"):setString(time)
    self.daojishi:runCsbAction("idle",true)
    self.m_expireALLHandlerId =
        scheduler.scheduleGlobal(
        function()
            time = time - 1
            self.daojishi:findChild("BitmapFontLabel_1"):setString(time)
            if time <= 0 then
                self:stopUpdate()
                self:setChooseIndexForFree(3)
                self.daojishi:runCsbAction("over",false,function ()
                    self.daojishi:setVisible(false)
                end)
                self:hideDarkAct()
                self:setChooseIndexForABTest()            --主类选中的下标赋值
                self:setWolfNodePosition(false)
            end
            if self.isAuto then--点击了自动
                self:stopUpdate()
                self:setChooseIndexForFree(2)
                self.daojishi:runCsbAction("over",false,function ()
                    self.daojishi:setVisible(false)
                end)
                self:hideDarkAct()
                -- self:setChoosePigIndex(self.m_pigIndex)   --选中下标赋值
                self:setChooseIndexForABTest()            --主类选中的下标赋值
                self:setWolfNodePosition(false)
            end
        end,
        1
    )
end


function WolfSmashFreeSpinNewMapView:setChooseIndexForFree(index)
    self.m_machine.chooseIndexForFree = index
end

return WolfSmashFreeSpinNewMapView