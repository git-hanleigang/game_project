---
--xcyy
--2018年5月23日
--BingoPriatesGoldBoneBarView.lua

local BingoPriatesGoldBoneBarView = class("BingoPriatesGoldBoneBarView",util_require("base.BaseView"))

BingoPriatesGoldBoneBarView.BarMaxNum = 5
BingoPriatesGoldBoneBarView.BatProcess = 0

function BingoPriatesGoldBoneBarView:initUI()

    self:createCsbNode("BingoPriates_bingo_jindutiao.csb")

    self.BatProcess = 0

    self:initLoadingBar( )

   

end


function BingoPriatesGoldBoneBarView:onEnter()
 

end


function BingoPriatesGoldBoneBarView:onExit()
 
end

--默认按钮监听回调
function BingoPriatesGoldBoneBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function BingoPriatesGoldBoneBarView:initLoadingBar( )
    
    for i = 1,self.BarMaxNum do
        local csbName = "BingoPriates_bingo_jindutiao_ladBar1.csb"
        if i == 1 then
            csbName = "BingoPriates_bingo_jindutiao_ladBar5.csb"
        end
        local LoadingBar = util_createAnimation(csbName)
        LoadingBar.index = i
        LoadingBar.isOpen = false
        local nodeName = "Node_" .. i
        self:findChild(nodeName):addChild(LoadingBar)
        self["LoadingBar_" .. i] = LoadingBar
        self["LoadingBar_" .. i]:setVisible(false)
     
    end

end

function BingoPriatesGoldBoneBarView:updateBingoGoldenBoneProcess( goldenBoneProcess )

    if goldenBoneProcess == 0 then
        self.BatProcess = 0
        for i=1,self.BarMaxNum do

            local bar =  self["LoadingBar_" .. i]
            if bar then
                bar.isOpen = false
                bar:setVisible(false)
                bar:runCsbAction("idle1")
            end
               
        end

        return 
    end

    for i=1,self.BarMaxNum do
        if i <= goldenBoneProcess then
            local bar =  self["LoadingBar_" .. i]
            if bar then
                self.BatProcess = i
                bar.isOpen = true
                bar:setVisible(true)
                bar:runCsbAction("idleframe2")
            end
           
        end
    end
end

function BingoPriatesGoldBoneBarView:restGoldenBonebar( )

    self.BatProcess = 0

    for i=1,self.BarMaxNum do

        local bar =  self["LoadingBar_" .. i]
        if bar then
            bar.isOpen = false
            bar:setVisible(false)
            bar:runCsbAction("idleframe1")
        end
           

    end
end

function BingoPriatesGoldBoneBarView:runOneProcessAct( goldenBoneProcess , func , showIdleUi )

    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_GoldBoneBarCollect+1.mp3")

    self:runCsbAction("actionframe")

    for i=1,self.BarMaxNum do
        local bar =  self["LoadingBar_" .. i]
        if bar then

            if i == goldenBoneProcess then
            
                bar.isOpen = true
                bar:setVisible(true)
                self.BatProcess = i
                if showIdleUi then
                    
                    bar:runCsbAction("idleframe2")
                    
                    if func then
                        func()
                    end
                else
                    bar:runCsbAction("actionframe",false,function(  )
                        if func then
                            func()
                        end
                    end) 
                end
                
                
               
            elseif i > goldenBoneProcess then
                bar.isOpen = false
                bar:setVisible(false)
            elseif i < goldenBoneProcess then
                bar.isOpen = true
                bar:setVisible(true)
                bar:runCsbAction("idleframe2")
            end
            
        end

        
    end
    
end

function BingoPriatesGoldBoneBarView:beginProcessAct( goldenBoneProcess , func   )
    

    self.m_goldenBoneProcess = goldenBoneProcess
    self.m_goldenBoneProcessFunc = function(  )
        if func then
            func()
        end
    end
    self:runProcessAct()
end

function BingoPriatesGoldBoneBarView:runProcessAct( )
    
    self.BatProcess = self.BatProcess + 1

    if self.BatProcess > self.m_goldenBoneProcess  then
        self.BatProcess = self.m_goldenBoneProcess

        if self.m_goldenBoneProcessFunc then
            self.m_goldenBoneProcessFunc()
        end

        return
    end

    gLobalSoundManager:playSound("BingoPriatesSounds/sound_BingoPriates_GoldBoneBarCollect+1.mp3")
    self:runCsbAction("actionframe")
    local bar = self["LoadingBar_" .. self.BatProcess]
    bar.isOpen = true
    bar:setVisible(true)
    bar:runCsbAction("actionframe",false,function(  )

        self:runProcessAct( )

    end) 

end

function BingoPriatesGoldBoneBarView:getGoldenBoneProcessForContrast()
    local num = 0
    for i=1,self.BarMaxNum do
        local bar =  self["LoadingBar_" .. i]
        if bar then
            local barShow = bar:isVisible()
            if barShow then
                num = num + 1
            end
        end
           
    end
    return num
end

return BingoPriatesGoldBoneBarView