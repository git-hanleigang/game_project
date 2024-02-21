---
--xcyy
--2018年5月23日
--FourInOneChooseMainView.lua

local FourInOneChooseMainView = class("FourInOneChooseMainView",util_require("base.BaseView"))

FourInOneChooseMainView.m_ChoosedReelsList = {}

FourInOneChooseMainView.m_notCanTouch = false

local imgTypeList = {"HowlingMoon", "Pomi", "ChilliFiesta", "Charms"}

function FourInOneChooseMainView:initUI(machine)

    local ChooseCsb = "FourInOne_Choose"
    if display.height > 1535 then
        ChooseCsb = "FourInOne_Choose_BigSize"
    end

    self:createCsbNode("ChooseView/" .. ChooseCsb ..".csb")


    -- self.m_btnLight = util_createAnimation("ChooseView/FourInOne_Choose_atn.csb")
    -- self:findChild("btnLight"):addChild(self.m_btnLight)
    -- self.m_btnLight:runCsbAction("idleframe",true)
    
    self.m_Kuang = util_createView("CodeFourInOneSrc.ChooseView.FourInOneChoose_Kuang")
    self:findChild("4in1_kuang_di"):addChild(self.m_Kuang)
    self.m_Kuang:runCsbAction("idleframe",true)
    self.m_notCanTouch = false
    self.m_machine = machine
    -- 作为选择界面维护的 base轮盘list
    self.m_ChoosedReelsList = self.m_machine.m_reelsTypeList
    self:initActView()


end

function FourInOneChooseMainView:onEnter()
 

end

function FourInOneChooseMainView:getImgTypeId( CurType )
    for i=1,#imgTypeList do
        local imgType = imgTypeList[i]
        if CurType == imgType then
            return i
        end
    end
    
end

function FourInOneChooseMainView:initActView()

    

    for i=1,4 do

        local reelId = self:getImgTypeId( self.m_ChoosedReelsList[i] )
        local actView = util_createView("CodeFourInOneSrc.ChooseView.FourInOneChooseActView",reelId,self,i)
        self:findChild("4in1_"..i):addChild(actView)

    end
    

end

function FourInOneChooseMainView:updateChoosedReelsList( index,reelType)
    self.m_ChoosedReelsList[index] = reelType
end

function FourInOneChooseMainView:onExit()
 
end

--默认按钮监听回调
function FourInOneChooseMainView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name ==  "Button" then
        -- 切换轮盘
        if self.m_notCanTouch then
            return 
        end

        gLobalSoundManager:playSound("FourInOneSounds/music_FourInOnes_Click_Collect.mp3")
        
        self.m_machine:updateBaseReelsView(  self.m_ChoosedReelsList ) 

    end

end


return FourInOneChooseMainView