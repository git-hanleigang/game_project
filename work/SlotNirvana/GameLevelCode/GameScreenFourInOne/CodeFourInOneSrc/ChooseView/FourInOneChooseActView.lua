---
--xcyy
--2018年5月23日
--FourInOneChooseActView.lua

local FourInOneChooseActView = class("FourInOneChooseActView",util_require("base.BaseView"))

FourInOneChooseActView.m_ImgTypeList = {"HowlingMoon", "Pomi", "ChilliFiesta", "Charms"}

FourInOneChooseActView.m_ImgId = 1

function FourInOneChooseActView:initUI( id ,parent,posId)

    self:createCsbNode("ChooseView/FourInOne_Choose_Act.csb")

    self.m_PosId = posId
    self.m_ImgId = id
    self.m_parent = parent

    local sizeX = self:findChild("Panel_1"):getContentSize().width

    self.m_idlePos = cc.p(0,0)
    self.m_startPos = cc.p(-sizeX,0)
    self.m_endPos = cc.p(sizeX,0)

    self:initImgPos( )

    self:addClick(self:findChild("Click1"))
    self:addClick(self:findChild("Click2"))
    self:addClick(self:findChild("Click3"))
    

    self.m_JinaTou = util_createView("CodeFourInOneSrc.ChooseView.FourInOneChoose_JinaTou")
    self:addChild(self.m_JinaTou)
    self.m_JinaTou:runCsbAction("idleframe",true)

   

end

function FourInOneChooseActView:initImgPos( )

    for i=1,#self.m_ImgTypeList do
        local name = self.m_ImgTypeList[i]
        if  i == self.m_ImgId  then
            self:findChild(name):setVisible(true)
            self:findChild(name):setPosition(self.m_idlePos)
        else
            self:findChild(name):setVisible(false)
        end
        
    end
    
end

function FourInOneChooseActView:hideAllImg( )
    for i=1,#self.m_ImgTypeList do
        local name = self.m_ImgTypeList[i]
        self:findChild(name):setVisible(false)
    end
end

function FourInOneChooseActView:onEnter()
 

end

function FourInOneChooseActView:updateImgPos( )
    
end

function FourInOneChooseActView:beginMove( id , func )
    
    self:hideAllImg( )

    

    self:runAct(  self.m_ImgId ,  self.m_endPos ,self.m_idlePos)

    self.m_ImgId = id
    self:runAct( id , self.m_idlePos,self.m_startPos, func )

    self.m_parent.m_machine:changeOneBaseReelsBg(self.m_ImgTypeList[id], self.m_PosId,0.2 )

    self.m_parent:updateChoosedReelsList( self.m_PosId,self.m_ImgTypeList[id])

end

function FourInOneChooseActView:beginMove2( id , func )
    
    self:hideAllImg( )

    self:runAct(  self.m_ImgId ,  self.m_startPos ,self.m_idlePos)

    self.m_ImgId = id
    self:runAct( id , self.m_idlePos,self.m_endPos, func )

    self.m_parent.m_machine:changeOneBaseReelsBg(self.m_ImgTypeList[id], self.m_PosId,0.2 )

    self.m_parent:updateChoosedReelsList( self.m_PosId,self.m_ImgTypeList[id])

end

function FourInOneChooseActView:runAct( id , pos , startPos, func )
    
    local time = 0.3

    local actionList = {}
    actionList[#actionList + 1] = cc.EaseInOut:create(cc.MoveTo:create(time, pos ),2)
    actionList[#actionList + 1] = cc.CallFunc:create(function(  )
        
            if func then
                func()
            end
    end)

    self:findChild( self.m_ImgTypeList[id]):setVisible(true)
    self:findChild( self.m_ImgTypeList[id]):setPosition(startPos)
    self:findChild( self.m_ImgTypeList[id]):runAction(cc.Sequence:create(actionList))

end

function FourInOneChooseActView:onExit()
 
end

--默认按钮监听回调
function FourInOneChooseActView:clickEndFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()


    if name == "Click2" then

        self:touchRightAct( sender )

    elseif name == "Click1" then

        self:touchLeftAct( sender )

    elseif name == "Click3" then 

        self:touchMoveAct( sender )

    end

end

function FourInOneChooseActView:touchRightAct( sender )
    
    if self.m_parent.m_notCanTouch then
        return
    end

    self.m_parent.m_notCanTouch = true

    if self.m_Lock then
        return
    end

    

    self.m_Lock = true

    gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_HuaDong.mp3")
    

    local id = self.m_ImgId + 1
    if id > 4 then
        id = 1
    end
    self:beginMove( id , function(  )
        self.m_Lock = false
        self.m_parent.m_notCanTouch = false
    end)
  
end

function FourInOneChooseActView:touchLeftAct( sender )

    if self.m_parent.m_notCanTouch then
        return
    end

    self.m_parent.m_notCanTouch = true

    if self.m_Lock then
        return
    end

    

    self.m_Lock = true

    gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_HuaDong.mp3")
    
    local id = self.m_ImgId -1
    if id < 1 then
        id = 4
    end
    self:beginMove2( id , function(  )
        self.m_Lock = false
        self.m_parent.m_notCanTouch = false
    end)


        
end


function FourInOneChooseActView:touchMoveAct( sender )
    
        
    local beganPos = sender:getTouchBeganPosition()
    local endPos = sender:getTouchEndPosition()

    if endPos.x == beganPos.x  then
        return
    end
     
    if self.m_parent.m_notCanTouch then
        return
    end

    self.m_parent.m_notCanTouch = true

    if self.m_Lock then
        return
    end

    

    self.m_Lock = true

    gLobalSoundManager:playSound("FourInOneSounds/music_FourInOne_HuaDong.mp3")
    

    
    if endPos.x - beganPos.x > 0 then
        local id = self.m_ImgId + 1
        if id > 4 then
            id = 1
        end
        self:beginMove( id , function(  )
            self.m_Lock = false
            self.m_parent.m_notCanTouch = false
        end)
    elseif endPos.x - beganPos.x < 0 then
        local id = self.m_ImgId -1
        if id < 1 then
            id = 4
        end
        self:beginMove2( id , function(  )
            self.m_Lock = false
            self.m_parent.m_notCanTouch = false
        end)

    end
end


return FourInOneChooseActView