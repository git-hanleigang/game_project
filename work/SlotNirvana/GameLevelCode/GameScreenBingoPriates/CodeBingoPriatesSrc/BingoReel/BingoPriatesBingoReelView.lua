---
--xcyy
--2018年5月23日
--BingoPriatesBingoReelView.lua

local BingoPriatesBingoReelView = class("BingoPriatesBingoReelView",util_require("base.BaseView"))

BingoPriatesBingoReelView.TextMaxNum = 25

local NodeZorder = {
    GoldBone = 10,
    Txt = 100,
    PurpleBone = 200,
}

function BingoPriatesBingoReelView:initUI(machine)

    self.m_machine = machine
    self:createCsbNode("BingoPriates_bingoReel.csb")

    self:initBingoText( )
    self:initPurpleBone( )
    self:initGoldBone( )
    self:initCoinsPool()

    self.m_BetLock = util_createAnimation("BingoPriates_bingoReel_suo.csb")
    self:findChild("betLock"):addChild(self.m_BetLock)
    self.m_BetLock:setVisible(false)

    self:findChild("OnePosWinAll"):setVisible(false)

end


function BingoPriatesBingoReelView:onEnter()
 

end

function BingoPriatesBingoReelView:onExit()
 
end

--默认按钮监听回调
function BingoPriatesBingoReelView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

    if name == "Button_i" then
        
        self.m_machine:checkShowTipView()
    end

end

function BingoPriatesBingoReelView:initPurpleBone( )
    
    for i=1,self.TextMaxNum do

        local PurpleBone = util_createAnimation("BingoPriates_bingoReel_kuloutou.csb")
        PurpleBone.index = i
        local nodeName = "Node_" .. i
        self:findChild(nodeName):addChild(PurpleBone,NodeZorder.PurpleBone)
        self["PurpleBone_" .. i] = PurpleBone
        self["PurpleBone_" .. i]:setVisible(false)
    end

end

function BingoPriatesBingoReelView:initGoldBone( )
    
    for i=1,self.TextMaxNum do

        local GoldBone = util_createAnimation("BingoPriates_baoxiang_BingoReel.csb")
        GoldBone.index = i
        local nodeName = "Node_" .. i
        self:findChild(nodeName):addChild(GoldBone,NodeZorder.GoldBone)
        self["GoldBone_" .. i] = GoldBone
        self["GoldBone_" .. i]:setVisible(false)
    end

end

function BingoPriatesBingoReelView:initCoinsPool( )
    for i=1,self.TextMaxNum do

        local CoinsPool = util_createAnimation("BingoPriates_bingoReel_jinbi.csb")
        CoinsPool.index = i
        local nodeName = "Node_" .. i
        self:findChild(nodeName):addChild(CoinsPool,NodeZorder.GoldBone)
        self["CoinsPool_" .. i] = CoinsPool
        self["CoinsPool_" .. i]:setVisible(false)
    end

end

function BingoPriatesBingoReelView:initBingoText( )
    
    for i=1,self.TextMaxNum do

        local Text = util_createAnimation("BingoPriates_bingoReel_shuzi.csb")
        Text.index = i
        Text:findChild("BitmapFontLabel_1"):setString("")
        local nodeName = "Node_" .. i
        self:findChild(nodeName):addChild(Text,NodeZorder.Txt)
        self["Text_" .. i] = Text

        Text:findChild("BitmapFontLabel_2"):setString("")
        Text:findChild("BitmapFontLabel_2"):setVisible(false)
        Text:findChild("BingoPriates_BINGO_huoyan_1"):setVisible(false)
        
    end

end

function BingoPriatesBingoReelView:getBingoReelPosIdx(iRow, iCol)
    local index = ( 5 - iRow) * 5 + (iCol - 1)
    return index 
end

---
-- 根据pos位置 获取 对应 行列信息
--@return {iX,iY}
function BingoPriatesBingoReelView:getBingoReelRowAndColByPos(posData)
    -- 列的长度， 这个取决于返回数据的长度， 可能包括不需要的信息，只是为了计算位置使用
    local colCount = 5

    local rowIndex = 5 - math.floor(posData / colCount)
    local colIndex = posData % colCount + 1

    return {iX = rowIndex,iY = colIndex}
end

function BingoPriatesBingoReelView:updateBingoTextNum( numList )
    
    local  stcValidSymbolMatrix = table_createTwoArr(5,5,TAG_SYMBOL_TYPE.SYMBOL_WILD)

    local rowCount = #numList
    for rowIndex=1,rowCount do
        local rowDatas = numList[rowIndex]
        local colCount = #rowDatas

        for colIndex=1,colCount do
            local symbolType = rowDatas[colIndex]
           stcValidSymbolMatrix[rowCount - rowIndex + 1][colIndex] = symbolType
        end
        
    end

    for iCol = 1, 5 do 
        for iRow = 1, 5 do
            local index =  self:getBingoReelPosIdx(iRow, iCol) + 1
            local score = stcValidSymbolMatrix[iRow][iCol] 
            local txtNode =  self[ "Text_" .. index ]
            if txtNode then
                txtNode:setVisible(true)
                local lab = txtNode:findChild("BitmapFontLabel_1")
                if lab then
                    lab:setString(score)
                    lab:setVisible(true)
                end
                local lab1 = txtNode:findChild("BitmapFontLabel_2")
                if lab1 then
                    lab1:setString(score)
                    lab1:setVisible(false)
                end
                local img = txtNode:findChild("BingoPriates_BINGO_huoyan_1")
                if img then
                    img:setVisible(false)
                end

            end
                
        end
    end

   
end

function BingoPriatesBingoReelView:changeColRowToPurpleBone( col,row )
    for iCol = 1, 5 do 
        for iRow = 1, 5 do
            local index =  self:getBingoReelPosIdx(iRow, iCol) 
            if col == iCol or iRow == row then
                self:collectOneBingoReel( index )
            end
        end
    end

end

function BingoPriatesBingoReelView:updateBingoMulNum( bingoMul  )
    
    
    local lab = self:findChild("BingoMulNum")
    if lab then
        lab:setString("x" .. bingoMul )
    end
end

function BingoPriatesBingoReelView:updateBingoCoinsPoolPos( CoinsPoolHit )
    
    

    for i=1,self.TextMaxNum do

        local CoinsPool = self["CoinsPool_" .. i]
        if CoinsPool then
            CoinsPool:setVisible(false)
        end
    end

    for i=1,#CoinsPoolHit do
        local pos = CoinsPoolHit[i] + 1
        local CoinsPool = self["CoinsPool_" .. pos]
        if CoinsPool then
            CoinsPool:setVisible(true)
        end
    end

end

function BingoPriatesBingoReelView:updateBingoGoldBonePos(goldenBoneHit )
    
    for i=1,self.TextMaxNum do

        local GoldBone = self["GoldBone_" .. i]
        if GoldBone then
            GoldBone:setVisible(false)
        end
    end

    for i=1,#goldenBoneHit do
        local pos = goldenBoneHit[i] + 1
        local GoldBone = self["GoldBone_" .. pos]
        if GoldBone then
            GoldBone:setVisible(true)
        end
    end
   

end

function BingoPriatesBingoReelView:updateBingoPurpleBonePos(bingoHit )


    for i=1,self.TextMaxNum do

        local PurpleBone = self["PurpleBone_" .. i]
        if PurpleBone then
            PurpleBone:setVisible(false)
        end
    end

    for i=1,#bingoHit do
        local pos = bingoHit[i] + 1
        local PurpleBone = self["PurpleBone_" .. pos]
        if PurpleBone then
            PurpleBone:setVisible(true)
        end
    end
end

function BingoPriatesBingoReelView:collectOneBingoReel( pos )
    
    for iCol = 1, 5 do 
        for iRow = 1, 5 do
            local index =  pos + 1
            
            local CoinsPool = self["CoinsPool_" .. index]
            if CoinsPool then
                CoinsPool:setVisible(false)
            end

            local GoldBone = self["GoldBone_" .. index]
            if GoldBone then
                GoldBone:setVisible(false)
            end
            local txtNode =  self[ "Text_" .. index ]
            if txtNode then
                txtNode:setVisible(false)
            end

            local PurpleBone = self["PurpleBone_" .. index]
            if PurpleBone then
                PurpleBone:setVisible(true)
            end
                
        end
    end

end


function BingoPriatesBingoReelView:setBingoWinAllLab( bingoReelIndex , func )
    
    for iCol = 1, 5 do 
        for iRow = 1, 5 do
            local index =  self:getBingoReelPosIdx(iRow, iCol) + 1
            if bingoReelIndex == index then
            
                gLobalSoundManager:playSound("BingoPriatesSounds/music_BingoPriates_show_BingoWinAll_Lab.mp3")

                local txtNode =  self[ "Text_" .. index ]
                if txtNode then
                    local lab = txtNode:findChild("BitmapFontLabel_1")
                    if lab then
                        lab:setVisible(false)
                    end
                    local lab1 = txtNode:findChild("BitmapFontLabel_2")
                    if lab1 then
                        lab1:setVisible(true)
                    end

                    local img = txtNode:findChild("BingoPriates_BINGO_huoyan_1")
                    if img then
                        img:setVisible(true)
                    end

                end

                if func then
                    func()
                end

                break

            end
           
                
        end
    end

end

--获取bingo轮盘
function BingoPriatesBingoReelView:getTextNumForContrast()
    local tempList = table_createTwoArr(5,5,TAG_SYMBOL_TYPE.SYMBOL_WILD)
    for iRow = 1, 5 do 
        for iCol = 1, 5 do
            local index =  self:getBingoReelPosIdx(iRow, iCol) + 1
            local txtNode =  self[ "Text_" .. index ]
            if txtNode then
                local lab = txtNode:findChild("BitmapFontLabel_1")
                local labVal = 0
                if lab then
                    labVal = lab:getString()
                end
                tempList[iRow][iCol] = tonumber(labVal)
            end
        end
    end
    local tempList2 = {}
    for i=#tempList,1,-1 do
        tempList2[#tempList2 + 1] = tempList[i]
    end
    return tempList2
end

function BingoPriatesBingoReelView:getBingoWinAllLabForContrast()
    local tempList = {}
    for iCol = 1, 5 do 
        for iRow = 1, 5 do
            local index =  self:getBingoReelPosIdx(iRow, iCol) + 1
            local txtNode =  self[ "Text_" .. index ]
            if txtNode then
                local img = txtNode:findChild("BingoPriates_BINGO_huoyan_1")
                if img then
                    local imgFire = img:isVisible()
                    if imgFire then
                        tempList[#tempList + 1] = index - 1
                    end
                    
                end
            end  
        end
    end
    return tempList
end

function BingoPriatesBingoReelView:getBingoMulForContrast()
    local function tempStringSplit(x)
        x = x:gsub("(%d)(%a)","%1,%2")
        x = x:gsub("(%a)(%d)","%1,%2")
        local table = string.split(x,",")
        return table
    end
    local lab = self:findChild("BingoMulNum")
    local labVal = 0
    local numList = {}
    if lab then
        labVal = lab:getString()
        local numList = tempStringSplit(labVal)
        local numStr = ""
        for i,v in ipairs(numList) do
            if i > 1 then
                numStr = numStr .. v
            end
            
        end
        labVal = tonumber(numStr) or 0
    end
    return labVal
end

function BingoPriatesBingoReelView:getPosNameForContrast(index)
    if index == 1 then
        return "GoldBone_"
    elseif index == 2 then
        return "CoinsPool_"
    elseif index == 3 then
        return "PurpleBone_"
    end
end

function BingoPriatesBingoReelView:getPosForContrast(index)
    local tempList = {}
    local posName = self:getPosNameForContrast(index)
    for i=1,self.TextMaxNum do

        local GoldBone = self[posName .. i]
        if GoldBone then
            local GoldBoneShow = GoldBone:isVisible()
            if GoldBoneShow then
                tempList[#tempList + 1] = i - 1
            end
        end
    end
    return tempList
end


return BingoPriatesBingoReelView