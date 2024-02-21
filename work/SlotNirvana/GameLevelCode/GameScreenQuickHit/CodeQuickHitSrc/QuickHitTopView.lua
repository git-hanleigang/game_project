---
--xhkj
--2018年6月11日
--QuickHitTopView.lua

local QuickHitTopView = class("QuickHitTopView", util_require("base.BaseView"))

QuickHitTopView.run = 1 -- 正常滚动状态
QuickHitTopView.stop = 0 -- 特殊玩法出发后不滚动
QuickHitTopView.state = nil

QuickHitTopView.runNorBarName = {"top_act_1","top_act_2","top_act_3","top_act_4","top_act_5","top_act_6"}
QuickHitTopView.runGameName = {"top_act_Wild","top_act_FreeSpin","top_act_Dollar","top_act_QuickHit"} -- ,"",""

QuickHitTopView.aniName = {"hide","idleframe","show"}

QuickHitTopView.norindex = 1


function QuickHitTopView:initUI()

    local resourceFilename = "QuickHit_Top.csb"
    self:createCsbNode(resourceFilename)

    self:setActionState(self.run)
    self:chooseOneTipshow()
    self:updataNorAction()

    self.m_FreeSpinChangeBet = util_createView("CodeQuickHitSrc.QuickHitTopViewCHangeFSBet")
    self:findChild("top_act_FreeSpin"):addChild(self.m_FreeSpinChangeBet)
    
    self:findChild("Freespinbet"):setVisible(false)
    self.m_FreeSpinChangeBet:setPosition(cc.p(self:findChild("Freespinbet"):getPosition()))
    

end

function QuickHitTopView:updataNorAction( )
    -- 八秒刷新一次动态栏
    schedule(self,function()
        if self.state ==  self.run then
           self:runCsbAction("hide",false,function(  )
                self:chooseOneTipshow() 
           end)

        end

    end,8)
end

-- 普通状态下显示
function QuickHitTopView:chooseOneTipshow( )
    self:hideAllNorNode()
    self:hideAllGameNode()   
                
    local tableArray = {}

    for i,v in ipairs(self.runNorBarName) do
        table.insert( tableArray, v )
    end

   for i = #tableArray,1,-1 do
       if self.norindex == i then
           table.remove( tableArray, i )
           break
       end
   end

   local index = math.random(1, #tableArray )

   for ii,vv in ipairs(self.runNorBarName) do
       if tableArray[index] == vv then
            self.norindex = ii
            break
       end
   end

   
    local showNodeName = tableArray[index] 
    self:findChild(showNodeName):setVisible(true)
    self:runCsbAction("show")
end

function QuickHitTopView:hideAllNorNode( )
    for k,v in pairs(self.runNorBarName) do
        self:findChild(v):setVisible(false)
    end
end

-- --- 触发玩法时显示
function QuickHitTopView:hideAllGameNode( )
    for k,v in pairs(self.runGameName) do
        self:findChild(v):setVisible(false)
    end
end

function QuickHitTopView:chooseOneGameTipshow( index )
    self:updateQuickHitNum(  )
    self:updateDollarbet(  )

    local pos = index + 1
    self:runCsbAction("hide",false,function(  )

        self:hideAllNorNode()
        self:hideAllGameNode()     

        local showNodeName = self.runGameName[pos] 
        self:findChild(showNodeName):setVisible(true)
        self:runCsbAction("show")
           
    end)
    
end

-- 设置滚动状态
function QuickHitTopView:setActionState(type)

    self.state = type
end


function QuickHitTopView:onEnter()
    gLobalNoticManager:addObserver(self,function(params)  -- 显示 freespin count
        self:changeFreeSpinByCount(params)
    end,ViewEventType.SHOW_FREE_SPIN_NUM)


    -- gLobalNoticManager:addObserver(self,function(params,num)  -- 改变 freespin count显示
    --     self:changeFreeSpinByCountOutLine(params,num)
    -- end,ViewEventType.CHANGE_OUTLINE_FREE_SPIN_NUM)

end



---
-- 更新freespin 剩余次数
--
function QuickHitTopView:changeFreeSpinByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateFreespinCount(leftFsCount,totalFsCount)
end

-- 更新并显示FreeSpin剩余次数
function QuickHitTopView:updateFreespinCount( curtimes ,totalFsCount)
    
    self:updateTimes( curtimes,totalFsCount )
    
end

-- 更新并显示FreeSpin剩余次数
function QuickHitTopView:updateFreespinBet( )
    
    if self.m_machine.m_runSpinResultData.p_fsExtraData then
        if self.m_machine.m_runSpinResultData.p_fsExtraData.mutiple then
             local mutiple =  self.m_machine.m_runSpinResultData.p_fsExtraData.mutiple
            --  self:findChild("Freespinbet"):setString("X"..mutiple)
             self.m_FreeSpinChangeBet:updatelab(true , mutiple)
        else
            --  self:findChild("Freespinbet"):setString("")
             self.m_FreeSpinChangeBet:runSelfCsbAction("hide")
             
        end 
     end
    
end

-- 更新并显示FreeSpin剩余次数
function QuickHitTopView:restFreeSpinBet( )
    

    -- self:findChild("Freespinbet"):setString("")
    self.m_FreeSpinChangeBet:runSelfCsbAction("hide")
    -- self:findChild("Wildnum"):setString("")
    
end



function QuickHitTopView:updateTimes( curtimes,totalFsCount )
    
    --self:updateLabelSize({label=self:findChild("lab_cur_time"),sx=0.8,sy=0.8},590)
    
    
    self:findChild("leafFreespinCount"):setString(totalFsCount - curtimes)
    self:findChild("totalFreespinCount"):setString(totalFsCount)

    -- self:findChild("Freespinbet"):setString("")

end

function QuickHitTopView:initWildByCount( )
    local leftFsCount = globalData.slotRunData.freeSpinCount 
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateWildTimes(leftFsCount,totalFsCount,true)
end
function QuickHitTopView:changeWildByCount()
    local leftFsCount = globalData.slotRunData.freeSpinCount - 1
    local totalFsCount = globalData.slotRunData.totalFreeSpinCount
    self:updateWildTimes(leftFsCount,totalFsCount)


end

function QuickHitTopView:restWildTimes(  )
    
   self:findChild("Wildnum"):setString("")


end

function QuickHitTopView:updateWildTimes( curtimes,totalFsCount,isOutLine )
    

    self:findChild("leafWildCount"):setString(totalFsCount - curtimes)
    self:findChild("totalWildCount"):setString(totalFsCount)

    if self.m_machine.m_runSpinResultData.p_fsExtraData then
        if self.m_machine.m_runSpinResultData.p_fsExtraData.wilds then
            local allWilds = self.m_machine.m_runSpinResultData.p_fsExtraData.allWilds or 0
             local wilds = self.m_machine.m_runSpinResultData.p_fsExtraData.wilds + allWilds  
             if isOutLine then
                wilds = self.m_machine.m_runSpinResultData.p_fsExtraData.allWilds or 0
             end
             self:findChild("Wildnum"):setString(wilds)
             self:updateLabelSize({label=self:findChild("Wildnum"),sx=1,sy=1},892)
        else
            self:findChild("Wildnum"):setString("")
        end 
    end
       

end

function QuickHitTopView:updateDollarbet(  )
    if self.m_machine.m_runSpinResultData.p_selfMakeData then
        if self.m_machine.m_runSpinResultData.p_selfMakeData.mutiple then
            local bet = self.m_machine.m_runSpinResultData.p_selfMakeData.mutiple
            self:findChild("dollarBet"):setString("X"..bet)
        end
    end
end

function QuickHitTopView:updateQuickHitNum(  )
    if self.m_machine.m_runSpinResultData.p_selfMakeData then
        if self.m_machine.m_runSpinResultData.p_selfMakeData.quickhits then
            local num = self.m_machine.m_runSpinResultData.p_selfMakeData.quickhits
            self:findChild("QuickHitNum"):setString(num)
        end
    end 
end

function QuickHitTopView:onExit()

    gLobalNoticManager:removeAllObservers(self)
end

function QuickHitTopView:initMachine(machine)
    self.m_machine = machine
end


return QuickHitTopView