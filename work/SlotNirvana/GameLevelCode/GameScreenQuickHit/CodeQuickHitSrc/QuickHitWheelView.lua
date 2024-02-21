---
--smy
--2018年4月18日
--QuickHitWheelView.lua


local QuickHitWheelView = class("QuickHitWheelView", util_require("base.BaseView"))
QuickHitWheelView.randBigWheelIndex = nil
QuickHitWheelView.randSmallWheelIndex = nil
QuickHitWheelView.WheelSumIndex = 10 -- 轮盘有多少块
QuickHitWheelView.m_bigWheelData = {} -- 大轮盘信息
QuickHitWheelView.m_smallWheelData = {} -- 小轮盘有信息
QuickHitWheelView.m_smallWheelNode = {} -- 小轮盘Node
QuickHitWheelView.m_bigWheelNode = {} -- 大轮盘Node
QuickHitWheelView.playSmallWheelSound = nil --是否播放小轮盘音效

QuickHitWheelView.wheelBgName = {"QuickHit_lunpan_lan1_4","QuickHit_lunpan_lan2_6","QuickHit_lunpan_lv_7","QuickHit_lunpan_huang_5"} 

function QuickHitWheelView:initUI(data)
    

    self:createCsbNode("Socre_QuickHit_Lunpan.csb")

    self:findChild("QuickHit_lunpan_heise_3"):setVisible(false) 
    self:findChild("QuickHit_lunpan_heise_3"):setLocalZOrder(-100)
    self:findChild("QuickHit_lunpan_heise_3_0"):setVisible(false) 

    self:changeBtnEnabled(false)

    self.m_controlBig = require("CodeQuickHitSrc.QuickHitWheelAction"):create(self:findChild("QuickHit_lunpan_di"),10,function()
        -- 滚动结束调用
       
     end,function(distance,targetStep,isBack)
         -- 滚动实时调用
     end)
     self:addChild(self.m_controlBig)

    self.m_controlSmall = require("CodeQuickHitSrc.QuickHitWheelAction"):create(self:findChild("QuickHit_lunpan_panxiao"),10,function()
        -- 滚动结束调用
    end,function(distance,targetStep,isBack)
        -- 滚动实时调用
    end)
    self:addChild(self.m_controlSmall)

    self.playSmallWheelSound = false
    self:setSmallWheelRotModel()
    self:setWheelRotModel()

    self:BonusWheelBoneAnimal() 

    self:setBigWheelData(data.m_BigWheelData )
    self:CreateBigWheelSymbol()

    self.m_WheelPointAction = util_createView("CodeQuickHitSrc.QuickHitWheelPointAction")
    self:findChild("QuickHit_lunpan_zhizhen"):addChild(self.m_WheelPointAction)
    self.m_WheelPointAction:setLocalZOrder(-1)

    self:findChild("QuickHit_lunpan_zhongjiang_2"):setVisible(false) 
    self.m_WheelPointAction:setPosition(cc.p(self:findChild("QuickHit_lunpan_zhongjiang_2"):getPosition()))
    

    self.m_Wheel2WinAction = util_createView("CodeQuickHitSrc.QuickHitWheel2WinAction")
    self:findChild("Wheel2WinAction"):addChild(self.m_Wheel2WinAction)
    
end


function QuickHitWheelView:initViewData(_bigcallBackFun,_smallcallBackFun)
    self.m_bigcallFunc = _bigcallBackFun
    self.m_smallcallFunc = _smallcallBackFun
    self.m_clicked = false  --点击状态
end

function QuickHitWheelView:onEnter()

    self.m_smallWheelNode = {}
end

function QuickHitWheelView:onExit()

end

function QuickHitWheelView:changeBtnEnabled( isCanTouch)
    self:findChild("QuickHit_lunpan_zhizhen_1"):setTouchEnabled(isCanTouch)
end
--点击回调
function QuickHitWheelView:clickFunc(sender)
    -- if self.m_clicked == true then
    --     return 
    -- end
    -- self.m_clicked = true
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    -- local name = sender:getName()
    -- local tag = sender:getTag()
    -- -- self:runCsbAction("remove")
    -- self:changeBtnEnabled(false)

    -- -- if self.m_callFunc then
    -- --     self.m_callFunc()
    -- -- end
    -- -- self:removeFromParent()

    -- if name ==  "QuickHit_lunpan_zhizhen_1" then
    --     self:initBigWheelAction(self.randBigWheelIndex)
    --     self:initSmallWheelAction(self.randSmallWheelIndex)
    -- end
    
end

function QuickHitWheelView:beginBigWheelAction( endindex )

    local wheelData = {}
    wheelData.m_startA = 300 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 2 --匀速时间
    wheelData.m_slowA = 150 --动态减速度
    wheelData.m_slowQ = 1 --减速圈数
    wheelData.m_stopV = 110 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_bigcallFunc

    self.m_controlBig:changeWheelRunData(wheelData)

    self.randBigWheelIndex = endindex

    self.m_controlBig:beginWheel()
    self.m_controlBig:recvData(self.randBigWheelIndex)

    
end

function QuickHitWheelView:beginSmallWheelAction( endindex )
    local wheelData = {}
    wheelData.m_startA = 150 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 3--匀速时间
    wheelData.m_slowA = 120 --动态减速度
    wheelData.m_slowQ = 2 --减速圈数
    wheelData.m_stopV = 110 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_smallcallFunc
    self.m_controlSmall:changeWheelRunData(wheelData)

    self.randSmallWheelIndex = endindex

    self.distance_pre = 0
    self.distance_now = 0
    self.distance_pre_1 = 0
    self.distance_now_1 = 0
    self.m_controlSmall:beginWheel()
    self.m_controlSmall:recvData(self.randSmallWheelIndex)
end 

function QuickHitWheelView:beginSmallWheelAction_wildOrFreespin( endindex )
    local wheelData = {}
    wheelData.m_startA = 400 --加速度
    wheelData.m_runV = 500--匀速
    wheelData.m_runTime = 0--匀速时间
    wheelData.m_slowA = 300 --动态减速度
    wheelData.m_slowQ = 2 --减速圈数
    wheelData.m_stopV = 150 --停止时速度
    wheelData.m_backTime = 0 --回弹前停顿时间
    wheelData.m_stopNum = 0 --停止圈数
    wheelData.m_randomDistance = 0
    wheelData.m_func = self.m_smallcallFunc
    self.m_controlSmall:changeWheelRunData(wheelData)

    self.randSmallWheelIndex = endindex

    self.distance_pre = 0
    self.distance_now = 0
    self.distance_pre_1 = 0
    self.distance_now_1 = 0
    self.m_controlSmall:beginWheel()
    self.m_controlSmall:recvData(self.randSmallWheelIndex)
end 

-- 返回上轮轮盘的停止位置
function QuickHitWheelView:getLastEndIndex( )
   return self.randBigWheelIndex , self.randSmallWheelIndex
    
end

function QuickHitWheelView:setWheelRotModel( )
   
    self.m_controlBig:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setRotionAction(distance,targetStep,isBack)
    end)
end

function QuickHitWheelView:setSmallWheelRotModel( )
   
    self.m_controlSmall:setWheelRotFunc( function(distance,targetStep,isBack)
        self:setSmallRotionAction(distance,targetStep,isBack)
    end)
end

function QuickHitWheelView:setRotionAction( distance,targetStep,isBack )

    self.distance_now = distance / targetStep
    
    if self.distance_now < self.distance_pre then
        self.distance_pre = self.distance_now 
    end
    local floor = math.floor(self.distance_now - self.distance_pre)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre = self.distance_now 

        self:runCsbAction("animation0") 
        gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_big_run.mp3")       
    end
end

function QuickHitWheelView:setSmallRotionAction( distance,targetStep,isBack )

    self.distance_now_1 = distance / targetStep
    
    if self.distance_now_1 < self.distance_pre_1 then
        self.distance_pre_1 = self.distance_now_1 
    end
    local floor = math.floor(self.distance_now_1 - self.distance_pre_1)
    if floor > 0 then
        -- print("self.distance_now:  "..self.distance_now)
        self.distance_pre_1 = self.distance_now_1 

        if self.playSmallWheelSound then
            gLobalSoundManager:playSound("QuickHitSounds/music_QuickHit_wheel_Small_run.mp3")
        end

          
         
    end
end

function QuickHitWheelView:getBigWheelSymbolName( type )
    return "Socre_QuickHit_Wheel"..type..".csb"
end

function QuickHitWheelView:getSmallWheelLabName( num ,isTrigger)
   local typeNum =  self.m_machine.m_runSpinResultData.p_selfMakeData.type + 1
    if typeNum == 4 then -- 如果是jackPot lab
        return "Socre_QuickHit_Wheel_lab" .. typeNum.. ".csb"
    else
        return "Socre_QuickHit_Wheel_lab".. self:getMaxToSmallLab( typeNum,num ,isTrigger) .. ".csb" 
    end

    

end
function QuickHitWheelView:isInArray(array,num )
    for i,v in ipairs(array) do
        if num == v then
            return true
        end
    end

    return false
end

function QuickHitWheelView:getMaxToSmallLab( typeNum,num,isTrigger )
    local labIndex = 1
    local tableCopy = {}

    local data = self.m_machine["m_WheelData_"..self.m_machine.m_WheelType[typeNum]]
    if isTrigger then
        data = self.m_machine["m_WheelData_TRIGGER_"..self.m_machine.m_WheelType[typeNum]]
    end
   
    for i,v in ipairs(data) do
        if not self:isInArray(tableCopy,v) then
            table.insert( tableCopy, v)
        end 
    end

    table.sort( tableCopy, function(a,b  )
        return a < b
    end )

    local symbolIndex = 1
    for ii,vv in ipairs(tableCopy) do
        if num == vv then
            symbolIndex = ii
            break
        end
    end

    local pro = symbolIndex/#tableCopy

    if pro<= 0.3 then
        labIndex = 1
    elseif pro > 0.3 and pro <= 0.6 then
        labIndex = 2
    else
        labIndex = 3
    end

    return labIndex 
end


function QuickHitWheelView:setBigWheelData(data )
    self.m_bigWheelData = {}
    self.m_bigWheelData = data -- 大轮盘信息
end
function QuickHitWheelView:setSmallWheelData(data )
    self.m_smallWheelData = {}
    self.m_smallWheelData = data
    -- for k,v in pairs(data) do
    --     self.m_smallWheelData[#self.m_smallWheelData + 1] = v
    -- end
    
end
function QuickHitWheelView:CreateBigWheelSymbol(  )
    -- self:removeAllBigWheelSymbol( )
    self.m_bigWheelNode = {}

    for k,v in pairs(self.m_bigWheelData) do
        local sp =  util_createView("CodeQuickHitSrc.QuickHitWheelSymbol",self:getBigWheelSymbolName(v)) 
        table.insert( self.m_bigWheelNode, sp )
        self:findChild("wheel_symbol_"..k):addChild(sp)
    end
end
function QuickHitWheelView:CreateSmallWheelLab( isTrigger )
    ---self:removeAllSmallWheelLab()

    if #self.m_smallWheelNode == 0 then
        for k,v in pairs(self.m_smallWheelData) do
            local lab = util_createView("CodeQuickHitSrc.QuickHitWheelLab",self:getSmallWheelLabName(v,isTrigger))
            
            lab:findChild("BitmapFontLabel_1"):setString(v)

            local typeNum =  self.m_machine.m_runSpinResultData.p_selfMakeData.type + 1
            if typeNum == 4 then -- 如果是jackPot lab
                self:findChild("wheel_lab_jp_"..k):addChild(lab)
                self:findChild("wheel_lab_jp_"..k):setVisible(true)
            else
                self:findChild("wheel_lab_"..k):addChild(lab)
                self:findChild("wheel_lab_"..k):setVisible(true)
            end
            
            

            
            if isTrigger or typeNum == 1 then
                lab:findChild("BitmapFontLabel_1_0"):setVisible(false)
            end
            
            table.insert( self.m_smallWheelNode, lab )
        end
    else
        for kk,vv in pairs(self.m_smallWheelData) do
            self.m_smallWheelNode[kk]:findChild("BitmapFontLabel_1"):setString(vv)
            self:findChild("wheel_lab_"..kk):setVisible(true)
            self:findChild("wheel_lab_jp_"..kk):setVisible(true)
            
        end
    end
    
end

function QuickHitWheelView:removeAllBigWheelSymbol( )
    for i=1,self.WheelSumIndex do
        self:findChild("wheel_symbol_"..i):setVisible(false)
    end
end

function QuickHitWheelView:removeAllSmallWheelLab( )
    for i=1,self.WheelSumIndex do
        self:findChild("wheel_lab_"..i):setVisible(false)
        self:findChild("wheel_lab_jp_"..i):setVisible(false)
        
    end
    for k,v in pairs(self.m_smallWheelNode) do
       v:removeFromParent()
    end
    self.m_smallWheelNode = {}
end

function QuickHitWheelView:BonusWheelBoneAnimal( )
 
    -- self.m_BonusWheelBoneAnimal = util_spineCreate("Bone/BONUSWHEEL", true,true)

    -- self.m_BonusWheelBoneAnimal:setPosition(cc.p(self:findChild("QuickHit_bonus_wheel_4"):getPosition()))
    
    -- self:findChild("QuickHit_lunpan_zhizhen"):addChild(self.m_BonusWheelBoneAnimal)

    -- util_spinePlay(self.m_BonusWheelBoneAnimal, "QuickHit_BONUS_luodi", true)
    -- util_spinePlay(self.m_BonusWheelBoneAnimal, "QuickHit_BONUS_WILD", true)
    -- util_spinePlay(self.m_BonusWheelBoneAnimal, "QuickHit_BONUS_zhongjiang", true)
end

function QuickHitWheelView:initMachine( machine )
    self.m_machine = machine
end

function QuickHitWheelView:setWheelBgZorder( gameType )
    local index = gameType + 1

    for k,v in pairs(self.wheelBgName) do
       if k == index then
            self:findChild(v):setVisible(true)
       else
            self:findChild(v):setVisible(false)
       end
    end

end

return QuickHitWheelView