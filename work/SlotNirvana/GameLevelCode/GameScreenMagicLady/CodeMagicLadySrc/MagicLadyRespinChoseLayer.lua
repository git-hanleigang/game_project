local MagicLadyRespinChoseLayer = class("MagicLadyRespinChoseLayer", util_require("base.BaseView"))
function MagicLadyRespinChoseLayer:initUI(data,callback)
    self:createCsbNode("MagicLady/ExtraSpins.csb")
    self.m_data = data
    self.m_callFun = callback
    self:initView()
    self:enableBtn(false)
    self:runCsbAction("start",false,function ()
        self:enableBtn(true)
    end)
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_chooseLayer_start.mp3")
end

function MagicLadyRespinChoseLayer:initView()
    self.m_kapaiNodeTab = {}
    for i = 1,3 do
        local kapai = util_createAnimation("MagicLady_ExtraSpins_kapai1.csb")
        kapai:playAction("start",false,function ()
            kapai:playAction("idleframe",true)
        end)
        self:findChild("kapai"..i):addChild(kapai)
        table.insert(self.m_kapaiNodeTab,kapai)
        self:addClick(self:findChild("Button"..i))
    end
end

function MagicLadyRespinChoseLayer:onEnter()
    --关闭本界面
    gLobalNoticManager:addObserver(self,function(self,params)  
        self:chooseEndToOver()
    end,"MagicLadyRespinChoseLayer_chooseEndToOver")
 
    --开始飞特效
    gLobalNoticManager:addObserver(self,function(self,params)  
        self:startFly(params[1],params[2])
    end,"MagicLadyRespinChoseLayer_startFly")

    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_last_win_5.mp3")
    gLobalSoundManager:setBackgroundMusicVolume(0.0)
    
end

function MagicLadyRespinChoseLayer:onExit()
    gLobalNoticManager:removeAllObservers(self)
    gLobalSoundManager:setBackgroundMusicVolume(1)
end

function MagicLadyRespinChoseLayer:enableBtn(isEnable)
    self:findChild("Button1"):setTouchEnabled(isEnable)
    self:findChild("Button2"):setTouchEnabled(isEnable)
    self:findChild("Button3"):setTouchEnabled(isEnable)
end

function MagicLadyRespinChoseLayer:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_chooseLayer_click.mp3")
    local clicked = 0
    if name == "Button1" then
        clicked = 1
    elseif name == "Button2" then
        clicked = 2
    elseif name == "Button3" then
        clicked = 3
    end

    self:enableBtn(false)
    self:runCsbAction("idle")
    
    local resultNumTab = self.m_data.options
    local resultNumIdx = self.m_data.select + 1
    
    local numTab = {}
	for i,v in ipairs(resultNumTab) do
		if i ~= resultNumIdx and v > 0 then
			table.insert(numTab,v)
		end
	end
	table.sort(numTab,function ()
		return math.random(0,9)%2 == 1
	end)
	for i,kapaiNode in ipairs(self.m_kapaiNodeTab) do
		if i == clicked then
            kapaiNode:findChild("addNum"..resultNumTab[resultNumIdx]):setVisible(true)
            if resultNumTab[resultNumIdx] > 1 then
                kapaiNode:findChild("addSpins"):setVisible(true)
            else
                kapaiNode:findChild("addSpin"):setVisible(true)
            end
            kapaiNode:playAction("actionframe",false,function ()
                kapaiNode:playAction("idleframe4",true)
            end)
        else
            kapaiNode:findChild("num"..numTab[1]):setVisible(true)
            if numTab[1] > 1 then
                kapaiNode:findChild("spins"):setVisible(true)
            else
                kapaiNode:findChild("spin"):setVisible(true)
            end
            table.remove(numTab,1)
            kapaiNode:playAction("actionframe2")
		end
	end

    performWithDelay(self,function()
        local pos = cc.p(sender:getPositionX(),sender:getPositionY() - sender:getContentSize().height/2)
        local worldPos = sender:getParent():convertToWorldSpace(pos)
        gLobalNoticManager:postNotification("CodeGameScreenMagicLadyMachine_addRespinNumFlyEffect",{worldPos})
    end,1.2)
end
--开始飞特效，endWorldPos特效飞行目的地世界坐标
function MagicLadyRespinChoseLayer:startFly(startWorldPos,endWorldPos)
    local addNumFlyEffect = util_createAnimation("MagicLady_xiaoqiuTW.csb")
    self:findChild("kapai1"):addChild(addNumFlyEffect,-1)
    
    local startPos = self:findChild("kapai1"):convertToNodeSpace(startWorldPos)
    local endPos = self:findChild("kapai1"):convertToNodeSpace(endWorldPos)

    addNumFlyEffect:setPosition(startPos)
    local hudu = math.atan2(endPos.x - startPos.x, endPos.y - startPos.y)
    local jiaodu = math.deg(hudu)
    addNumFlyEffect:setRotation(jiaodu)

    addNumFlyEffect:playAction("actionframe5")
    addNumFlyEffect:setScale(0.5)

    local move = cc.MoveTo:create(10/30,endPos)
    local fun = cc.CallFunc:create(function()
        gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_addrespinnum.mp3")
        gLobalNoticManager:postNotification("CodeGameScreenMagicLadyMachine_changeReSpinUpdateUI")
    end)
    local seq = cc.Sequence:create(move,fun)
    addNumFlyEffect:runAction(seq)

    performWithDelay(self,function()
        addNumFlyEffect:removeFromParent()
        self:chooseEndToOver()
    end,0.5)
end

function MagicLadyRespinChoseLayer:chooseEndToOver()
    gLobalSoundManager:playSound("MagicLadySounds/music_MagicLady_chooseLayer_over.mp3")
    util_setCascadeOpacityEnabledRescursion(self:findChild("rootNode"),true)
    self:runCsbAction("over",false,function()
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end)
end
return MagicLadyRespinChoseLayer