---
--xcyy
--2018年5月23日
--BingoPriatesChestBarView.lua

local BingoPriatesChestBarView = class("BingoPriatesChestBarView",util_require("base.BaseView"))

BingoPriatesChestBarView.ChestMaxNum = 5
BingoPriatesChestBarView.ChestProcess = 0

BingoPriatesChestBarView.m_OldAvgBet = 0

function BingoPriatesChestBarView:initUI()

    self:createCsbNode("BingoPriates_bingo_baoxiangshouji.csb")

    self:initChest( )
    self.ChestProcess = 0
    self.m_OldAvgBet = 0
   

end


function BingoPriatesChestBarView:onEnter()
 

end

function BingoPriatesChestBarView:onExit()
 
end

--默认按钮监听回调
function BingoPriatesChestBarView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end


function BingoPriatesChestBarView:initChest( )
    
    for i=1,self.ChestMaxNum do
        local Chest = util_createAnimation("BingoPriates_baoxiang.csb")
        Chest.index = i
        local nodeName = "baoxiang_" .. i
        self:findChild(nodeName):addChild(Chest)
        Chest:runCsbAction("idle1")
        Chest.isOpen = false
        self["Chest_" .. i] = Chest
        self["Chest_" .. i]:setVisible(false)
    end

end

function BingoPriatesChestBarView:updateBingoAvgBetNum( avgBet )

    self.m_OldAvgBet = avgBet

    local lab  = self:findChild("BitmapFontLabel_1")

    if lab then
        lab:setString(util_formatCoins(avgBet,12))
        self:updateLabelSize({label=lab,sx=0.65,sy=0.65},267)
    end
    
    
end

function BingoPriatesChestBarView:updateBingoChestBoxProcess( boxProcess )
    
    if boxProcess == 0 then
        self.ChestProcess = 0
        for i=1,self.ChestMaxNum do

            local bar =  self["Chest_" .. i]
            if bar then
                bar.isOpen = false
                bar:setVisible(false)
                bar:runCsbAction("idle1")
            end
               
        end

        return 
    end

    for i=1,self.ChestMaxNum do
        if i <= boxProcess then
            local bar =  self["Chest_" .. i]
            if bar then
                self.ChestProcess = i
                bar.isOpen = true
                bar:setVisible(true)
                bar:runCsbAction("idle1")
            end
           
        end
    end


end

-- 
function BingoPriatesChestBarView:runOneProcessAct( chestProcess , func ,showIdleUi )

    for i=1,self.ChestMaxNum do
        local bar =  self["Chest_" .. i]
        if bar then
            if i == chestProcess then
            
            
                bar.isOpen = true
                bar:setVisible(true)
                self.ChestProcess = i
                local bar_1 = bar

                if showIdleUi then
                    
                    bar:runCsbAction("idleframe2")
                    
                    if func then
                        func()
                    end
                else
                    bar:runCsbAction("shoujifankui",false,function(  )
                        bar_1:runCsbAction("idle1")
                        
                        if func then
                            func()
                        end
                    end)
                end
                
                

            elseif i > chestProcess then
                bar.isOpen = false
                bar:setVisible(false)
            elseif i < chestProcess then
                bar.isOpen = true
                bar:setVisible(true)
            end
        end
        
    end
    
end

function BingoPriatesChestBarView:runProcessAct( chestProcess , func   )
    
end

--获取平均betUI
function BingoPriatesChestBarView:getAvgBetNumForContrast()
    local lab  = self:findChild("BitmapFontLabel_1")
    local labVal = 0
    local avgBet = 0
    if lab then
        labVal = lab:getString()
        local numList = util_string_split(labVal,",")
        local numStr = ""
        for i,v in ipairs(numList) do
            numStr = numStr .. v
        end
        avgBet = tonumber(numStr) or 0
    end
    return avgBet
end

function BingoPriatesChestBarView:getChestBoxProcessForContrast()
    local num = 0
    for i=1,self.ChestMaxNum do
        local bar =  self["Chest_" .. i]
        if bar then
            local barShow = bar:isVisible()
            if barShow then
                num = num + 1
            end
        end
           
    end
    return num
end

return BingoPriatesChestBarView