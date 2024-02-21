---
--xcyy
--2018年5月23日
--MermaidBonusPaoView.lua

local MermaidBonusPaoView = class("MermaidBonusPaoView",util_require("base.BaseView"))

MermaidBonusPaoView.m_clickedPao = nil

function MermaidBonusPaoView:initUI(machine)


    self.m_machine = machine
    self.m_clickedPao = nil

    self:createCsbNode("Mermaid/BonusGamePaoView.csb")

    self.m_winBarView = util_createAnimation("Mermaid_BONUSWIN.csb") 
    self:findChild("BONUSWIN"):addChild(self.m_winBarView)
    self:findChild("BONUSWIN"):setLocalZOrder(100)
    -- self:runCsbAction("actionframe") -- 播放时间线
    -- self:findChild("xxxx") -- 获得子节点
    -- self:addClick("xxx") -- 非按钮节点得手动绑定监听


    -- performWithDelay(节点（必须传入）, function ()
	    -- 延时函数
	    -- xxx 对应延时时间
    -- end, xxx)

    -- schedule(view,function ()
        -- 定时器
    	-- xxx 对应定时器调用时间间隔
    -- end,xxxx)

    self.m_actNode = cc.Node:create()
    self:addChild(self.m_actNode)

end


function MermaidBonusPaoView:onEnter()
 

end

function MermaidBonusPaoView:onExit()
    self.m_clickedPao = nil
end

function MermaidBonusPaoView:beginPaoAct( isFirst )
    local createNum = math.random(2,3)
    local beginWith = {- display.width/4 - 10,0,display.width * 1/4 + 10}
    if isFirst then
        createNum = 3
    end
    for i=1,createNum do
        
        local roIndex = math.random( 1 , #beginWith)
        local roundPos = beginWith[roIndex] 
        table.remove(beginWith,roIndex)

        local startPos = cc.p(roundPos,-display.height/2 - 400)

        if isFirst then
            startPos = cc.p(roundPos,-display.height / 2 - 100)
        end

        local endPos = cc.p(roundPos,display.height / 2 + 400)
        local scale = math.random(8,9) / 10
        local speed = math.random(100,110)  
        local time = display.height / speed
        local waitTime = math.random(8,12) * 25 / speed  

        self:createOnePao(startPos,endPos,scale,time,waitTime )
    end
end

function MermaidBonusPaoView:startPaoPaoAction( )

    self:beginPaoAct( true )

    schedule(self.m_actNode,function( )

        self:beginPaoAct( )

    end,2.5)

    
    
end

function MermaidBonusPaoView:createOnePao(startPos,endPos,scale,time,waitTime )

    local node = util_createView("CodeMermaidSrc.MermaidBonusQiPaoBtn",self) 
    self:findChild("root"):addChild(node)
    node:setPosition(startPos)
    node:setScale(scale)
    node:setVisible(false)
    local actList = {}
    actList[#actList + 1] = cc.DelayTime:create(waitTime)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(true)
        local widthNum = math.round(2,5) 
        local actList2 = {}
        local widthTimes = time / widthNum
        for i=1,widthNum do
            local roundWitdh = math.round(1,3) * 50 * scale
            actList2[#actList2 + 1] = cc.MoveTo:create(widthTimes,cc.p(-roundWitdh  ,0))
            actList2[#actList2 + 1] = cc.MoveTo:create(widthTimes,cc.p(roundWitdh  ,0))
        end
        local sq_1 = cc.Sequence:create(actList2)
        node:findChild("root"):runAction(sq_1)
    end)
    actList[#actList + 1] = cc.MoveTo:create(time,endPos)
    actList[#actList + 1] = cc.CallFunc:create(function(  )
        node:setVisible(false)
        node:stopAllActions()
        node:removeFromParent()
    end)
    local sq = cc.Sequence:create(actList)
    node:runAction(sq)
end

function MermaidBonusPaoView:clickOnePao( pao )
    
    if self.m_machine:isTouch() then
       
        gLobalSoundManager:playSound("MermaidSounds/music_Mermaid_Click_QiPao.mp3")
        
        pao:findChild("click_pao"):setVisible(false)
        pao:stopAllActions()
        pao:findChild("root"):stopAllActions()
        print("  点击气泡哈哈哈哈")
        self.m_clickedPao = pao
        
        self.m_machine:sendPaoPaoViewData()

    end
        

end



return MermaidBonusPaoView