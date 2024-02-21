--
-- 沙盘收集页面
-- Author:{author}
-- Date: 2018-12-22 16:34:48
--
local MiracleEgyptCollectView = class("MiracleEgyptCollectView", util_require("base.BaseView"))

MiracleEgyptCollectView.m_freespinInfo = nil
MiracleEgyptCollectView.m_Callfunc = nil

MiracleEgyptCollectView.m_clickIndex = 1

MiracleEgyptCollectView.m_clickTimes = 0
MiracleEgyptCollectView.m_freespinTimes = 0

function MiracleEgyptCollectView:initUI( data )

    self.m_freespinInfo = data

     

    self:createCsbNode("MiracleEgypt/GameScreenMiracleEgyptBg1.csb")

    print("----------"..display.width)
    dump(self:findChild("Sprite_2"):getContentSize(),"------------------")

    -- self:findChild("tab3"):setPositionX(display.width *0.1)
    -- self:findChild("tab4"):setPositionX(display.width *0.8)

    self.m_CollectLabViewPick = util_createView("CodeMiracleEgyptSrc.MiracleEgyptCollectCollectTimes")
    self:findChild("tab3"):addChild(self.m_CollectLabViewPick)
    self.m_CollectLabViewPick:setVisible(false)
    self.m_CollectLabViewPick:setLabStr("0")

    self.m_CollectLabViewFs = util_createView("CodeMiracleEgyptSrc.MiracleEgyptCollectFreeSpinTimes")
    self:findChild("tab4"):addChild(self.m_CollectLabViewFs)
    self.m_CollectLabViewFs:setVisible(false)
    self.m_CollectLabViewFs:setLabStr("0")

    self.m_shaPan = util_createView("CodeMiracleEgyptSrc.MiracleEgyptShaPan")
    self:findChild("shapan"):addChild(self.m_shaPan)
    self.m_shaPan:showAction(nil,true )

    self:initClickTimes( )

    self:updateClickTimes(0 )
    self:updateFreeSpinTimes( 0 )

    
    self:showViewAction(function( )

        self.m_CollectLabViewPick:setVisible(true)
        self.m_CollectLabViewFs:setVisible(true)

        self.m_CollectLabViewPick:showAction("start")
        self.m_CollectLabViewFs:showAction("start")

        self:showBonusStart( )
    end )

    self:findChild("Node_2"):setVisible(false)
    

end

function MiracleEgyptCollectView:initClickTimes( )
    local giveTimes = 0
   for k,v in pairs(self.m_freespinInfo) do
       if v > 100 then -- 100 以上是获得了点击次数
            
            giveTimes = giveTimes + v/100
       end
   end

   self.m_clickTimes = #self.m_freespinInfo - giveTimes

end

function MiracleEgyptCollectView:updateClickTimes(num )
    
    self.m_clickTimes = self.m_clickTimes + num

    self.m_CollectLabViewPick:setLabStr(self.m_clickTimes)
end

function MiracleEgyptCollectView:updateFreeSpinTimes( num )
    
    self.m_freespinTimes = self.m_freespinTimes + num
    self.m_CollectLabViewFs:setLabStr(self.m_freespinTimes)
end

function MiracleEgyptCollectView:showViewAction(func )


    local actFunc = function(  )
        if func then
            func()
        end
    end
    
    self:runCsbAction("bonus_start",false,actFunc,30)
end

function MiracleEgyptCollectView:setCallFunc( func,machine )
    self.m_Callfunc = func
    self.m_machine = machine
end

function MiracleEgyptCollectView:removeSelf(  )
    self:removeFromParent()
end

function MiracleEgyptCollectView:schedulecCreateClickView( )
   -- 实时更新游戏状态
    schedule(self,function()

        self:createClickView()

    end,2.5)
end

function MiracleEgyptCollectView:checkInArray(array,num )
    local isIN = false
    for k,v in pairs(array) do
        if num == v then
            isIN = true
        end
    end
    return isIN
end

function MiracleEgyptCollectView:getRemoveNum( )
    local removeGear= {10,30,20,10,5} -- 对应权重
    local addNum = 0
    local sumNum = 0
    local gearList = {1,2,3,4,5} -- 对应档位列表
    local gear = 1


    for k=1,#removeGear do
        sumNum = sumNum + removeGear[k]
    end

    if sumNum > 1 then
        local roundNum = math.random( 1, sumNum )

        for i=1,#removeGear do
            addNum = removeGear[i] + addNum
            if addNum >= roundNum   then
                gear = i

                break
            end
        end
    end
    
    return gearList[gear]


end

function MiracleEgyptCollectView:createClickView( )

        local posList = {1,2,3,4,5}
        local removeNum =  self:getRemoveNum() -- math.random( 1, 5 )
        if removeNum ~= 0 then
            for i=1,removeNum do
                local index = math.random( 1, #posList )
                table.remove( posList, index )
            end
        end


        for i=1,5 do
            if self:checkInArray(posList,i ) then

                print("在被删除的数组里的话不创建")

            else
                local clickView = util_createView("CodeMiracleEgyptSrc.MiracleEgyptShaqiuClickView",self)
                self:findChild("Node_2"):addChild(clickView)
                clickView:setScale(0.1)
                local shapanPos = cc.p(self:findChild("shapan"):getPosition())
                clickView:setPosition(shapanPos)
                clickView:setCallFunc( function(  )
                    self:removeAllClickView( )

                    performWithDelay(self,function()           
                        if self.m_Callfunc then
                            self.m_Callfunc()
                        end
                    end, 1)   
                    
                end)
                local endPos = cc.p(self:findChild("Node_pos_"..i):getPosition())

                local func = function(  )
                    clickView:removeSelf()
                end

                self:runMoveAct( clickView,endPos ,func)
            end
            
        end

end

function MiracleEgyptCollectView:removeAllClickView( )
    self:findChild("Node_2"):setVisible(false)
    self:findChild("Node_2"):removeAllChildren()
end
function MiracleEgyptCollectView:runMoveAct( node,endPos,func )
    local movetime = 0.5
    local ranPosX = math.random( 0, 100 ) -120
    local ranPosBezierNegative = 1 -- math.random( 0, 1 )
    local ranPosBezierX = 100 - math.random( 0, 80 )
    local Bezier = 10 
    local actionList = {}
    node.BubbleNode:findChild("MiracleEgypt_shaqiu_1"):setOpacity(0)
    node.BubbleNode:findChild("MiracleEgypt_shaqiu_idle_01_7"):setOpacity(0)

    actionList[#actionList+1] = cc.CallFunc:create(function()
        

        local actionList2 = {}
        actionList2[#actionList2 + 1] = cc.FadeIn:create(movetime)
        local seq2 = cc.Sequence:create(actionList2)
        node.BubbleNode:findChild("MiracleEgypt_shaqiu_1"):runAction(seq2)

        local actionList3 = {}
        actionList3[#actionList3 + 1] = cc.FadeIn:create(movetime)
        local seq3 = cc.Sequence:create(actionList3)
        node.BubbleNode:findChild("MiracleEgypt_shaqiu_idle_01_7"):runAction(seq3)

        local actionList1 = {}
        actionList1[#actionList1 + 1] = cc.ScaleTo:create(movetime,0.7)
        local seq1 = cc.Sequence:create(actionList1)
        node:runAction(seq1)
    end)
    actionList[#actionList + 1] = cc.MoveTo:create(movetime,cc.p(endPos.x,ranPosX))

    local bezier1 = {        
        cc.p(endPos.x  + (ranPosBezierNegative * -1 ) * ranPosBezierX ,(ranPosX + endPos.y) * 1/2),
        cc.p(endPos.x +  (ranPosBezierNegative * -1 ) * ranPosBezierX ,(ranPosX+ endPos.y) * 1/2),            
        cc.p( endPos.x ,endPos.y )
    }

    actionList[#actionList + 1] = cc.BezierTo:create(Bezier,bezier1)

    -- local bezier2 = {        
    --     cc.p(endPos.x  + (ranPosBezierNegative * -1  ) * ranPosBezierX ,(ranPosX + endPos.y) * 4/9),
    --     cc.p(endPos.x +  (ranPosBezierNegative * -1 ) * ranPosBezierX ,(ranPosX+ endPos.y) * 5/9),            
    --     cc.p( endPos.x ,endPos.y* 6/9)
    -- }

    -- actionList[#actionList + 1] = cc.BezierTo:create(Bezier*2/5,bezier2)

    -- local bezier3 = {        
    --     cc.p(endPos.x  + (ranPosBezierNegative * -1  ) * ranPosBezierX ,(ranPosX + endPos.y) * 7/9),
    --     cc.p(endPos.x +  (ranPosBezierNegative * -1 ) * ranPosBezierX ,(ranPosX + endPos.y) * 8/9),            
    --     cc.p( endPos.x ,endPos.y)
    -- }

    -- actionList[#actionList + 1] = cc.BezierTo:create(Bezier*1/5,bezier3)


    actionList[#actionList+1] = cc.CallFunc:create(function()
        if func then
            func()
        end
        
    end)
    local seq = cc.Sequence:create(actionList)
    node:runAction(seq)
end

function MiracleEgyptCollectView:showBonusStart(  )

    gLobalSoundManager:playSound("MiracleEgyptSounds/music_MiracleEgypt_View_Start.mp3")

    local func = function(  )

        self:findChild("Node_2"):setVisible(true)

        self:createClickView()
        self:schedulecCreateClickView()
        
    end
    local ownerlist={}
    self.m_machine:showDialog("Extragame",ownerlist,func)
end



return  MiracleEgyptCollectView