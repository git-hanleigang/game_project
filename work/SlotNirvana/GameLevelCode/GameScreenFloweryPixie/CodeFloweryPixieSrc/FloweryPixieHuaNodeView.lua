---
--xcyy
--2018年5月23日
--FloweryPixieHuaNodeView.lua

local FloweryPixieHuaNodeView = class("FloweryPixieHuaNodeView",util_require("base.BaseView"))


function FloweryPixieHuaNodeView:initUI()

    self:createCsbNode("FloweryPixie_hua_node.csb")

    for i=1,3 do
        self:createrOneFlower( i )
    end

end

function FloweryPixieHuaNodeView:createrOneFlower(index )

    if index > 0 and index < 4 then
        
        self["m_flower_"..index] = util_createAnimation("FloweryPixie_hua.csb") 
        self:findChild("hua"..index):addChild(self["m_flower_"..index])

        self["m_flower_"..index]["bigHua"] = util_spineCreate("Socre_FloweryPixie_UI_BigFlower",true,true) 
        self["m_flower_"..index]:findChild("bigflower"):addChild(self["m_flower_"..index]["bigHua"])
        util_spinePlay(self["m_flower_"..index]["bigHua"],"idleframe5",true)
        self["m_flower_"..index]["bigHua"].m_isClose = true

        for i=1,8 do
            
            self["m_flower_"..index]["smallHua"..i] = util_spineCreate("Socre_FloweryPixie_UI_SmallFlower",true,true) 
            self["m_flower_"..index]:findChild("Node_"..i):addChild(self["m_flower_"..index]["smallHua"..i])
            util_spinePlay(self["m_flower_"..index]["smallHua"..i],"idleframe3",true)
            self["m_flower_"..index]["smallHua"..i].m_isClose = true
        end

        self["m_flower_"..index]:runCsbAction("idleframe1")
        self["m_flower_"..index].m_labShow = false

        self["m_flower_"..index]["bigYeZi"] = util_spineCreate("Socre_FloweryPixie_UI_YeZi",true,true) 
        self["m_flower_"..index]:findChild("Node_leaves"):addChild(self["m_flower_"..index]["bigYeZi"])
        util_spinePlay(self["m_flower_"..index]["bigYeZi"],"idleframe",true)
        self["m_flower_"..index]["bigYeZi"].m_yeZiShow = true


        self["m_flower_"..index]["flash"] = util_createAnimation("Socre_FloweryPixie_Bonus_Lab_guang.csb")
        self["m_flower_"..index]:findChild("Node_10"):addChild(self["m_flower_"..index]["flash"],3)
        self["m_flower_"..index]["flash"]:runCsbAction("idleframe",true)
        util_setCascadeOpacityEnabledRescursion(self["m_flower_"..index]:findChild("Node_10"),true)


    end

end


function FloweryPixieHuaNodeView:onEnter()
 

end


function FloweryPixieHuaNodeView:onExit()
 
end

--默认按钮监听回调
function FloweryPixieHuaNodeView:clickFunc(sender)
    local name = sender:getName()
    local tag = sender:getTag()

end

function FloweryPixieHuaNodeView:updateBigSingleFlowers(machine, index,isclose ,isLock,isBtnClickUpdate )
    local selfdata = machine.m_runSpinResultData.p_selfMakeData or {}
    local collectdata = selfdata.collect or {}
    local singleData = collectdata[index] or {collectChangeCount = 0,collectCoinsPool = 0,collectLeftCount = 0,collectTotalCount = 0}

    if isclose then

            if index == 1 then
                gLobalSoundManager:playSound("FloweryPixieSounds/music_FloweryPixie_BigHua_Close.mp3")
            end
            
        -- if self["m_flower_"..index]["bigHua"].m_isClose ~= true then
            self["m_flower_"..index]["bigHua"].m_isClose = true
            util_spinePlay(self["m_flower_"..index]["bigYeZi"],"yahei")
            self["m_flower_"..index]["bigYeZi"].m_yeZiShow = false
            util_spinePlay(self["m_flower_"..index]["bigHua"],"yahei") 
        -- end
       
    else

        if self["m_flower_"..index]["bigYeZi"].m_yeZiShow ~= true then
            util_spinePlay(self["m_flower_"..index]["bigYeZi"],"idleframe",true)
            self["m_flower_"..index]["bigYeZi"].m_yeZiShow = true
        end
        

        local collectLeftCount = singleData.collectLeftCount

        if  collectLeftCount > 0 or  isLock then

            if not isBtnClickUpdate then
                if self["m_flower_"..index]["bigHua"].m_isClose == true then
                    gLobalSoundManager:playSound("FloweryPixieSounds/music_FloweryPixie_BigHua_Open.mp3")
                    util_spinePlay(self["m_flower_"..index]["bigHua"],"kai2")
                    self["m_flower_"..index]["bigHua"].m_isClose = false
                    util_spineEndCallFunc(self["m_flower_"..index]["bigHua"], "kai2", function ()
                        util_spinePlay(self["m_flower_"..index]["bigHua"],"idleframe6",true)
                    end)
                    
                end
            end 

            

        else
            util_spinePlay(self["m_flower_"..index]["bigHua"],"idleframe5",true)

            if self["m_flower_"..index]["bigHua"].m_isClose ~= true then
                gLobalSoundManager:playSound("FloweryPixieSounds/music_FloweryPixie_BigHua_Close.mp3")
                util_spinePlay(self["m_flower_"..index]["bigHua"],"he") 
                self["m_flower_"..index]["bigHua"].m_isClose = true
            end
        end
        
    end
end



function FloweryPixieHuaNodeView:updateBigFlowers( machine ,isBtnClickUpdate )
    

    


    local betid = machine.m_betLevel

    if betid == 0 then
     
        

        for index = 1,3 do
            self:updateBigSingleFlowers( machine , index,true , true,isBtnClickUpdate  ) 

            self:updateSmallFlower( machine ,index , true ,isBtnClickUpdate  )
        end
        
        
    elseif betid == 1 then

        self:updateBigSingleFlowers(machine, 1,false,nil,isBtnClickUpdate  ) 
        self:updateBigSingleFlowers(machine, 2,true ,nil,isBtnClickUpdate) 
        self:updateBigSingleFlowers(machine, 3,true ,nil,isBtnClickUpdate) 

        self:updateSmallFlower( machine ,1 , false ,isBtnClickUpdate  )
        self:updateSmallFlower( machine ,2 , true  ,isBtnClickUpdate )
        self:updateSmallFlower( machine ,3 , true ,isBtnClickUpdate )
        
    elseif betid == 2 then

        self:updateBigSingleFlowers(machine, 1,false ,nil,isBtnClickUpdate) 
        self:updateBigSingleFlowers(machine, 2,false,nil,isBtnClickUpdate ) 
        self:updateBigSingleFlowers(machine, 3,true ,nil,isBtnClickUpdate) 

        self:updateSmallFlower( machine ,1 , false ,isBtnClickUpdate )
        self:updateSmallFlower( machine ,2 , false ,isBtnClickUpdate )
        self:updateSmallFlower( machine ,3 , true ,isBtnClickUpdate )

    elseif betid == 3 then

        self:updateBigSingleFlowers(machine , 1,false,nil,isBtnClickUpdate ) 
        self:updateBigSingleFlowers( machine ,2,false ,nil,isBtnClickUpdate) 
        self:updateBigSingleFlowers(machine ,  3,false ,nil,isBtnClickUpdate) 

        self:updateSmallFlower( machine ,1 , false ,isBtnClickUpdate )
        self:updateSmallFlower( machine ,2 , false ,isBtnClickUpdate )
        self:updateSmallFlower( machine ,3 , false ,isBtnClickUpdate )
    end

    
   
    
end



function FloweryPixieHuaNodeView:updateSmallFlower( machine ,index , isclose ,isBtnClickUpdate,isLock ,notUpdate )

    local selfdata = machine.m_runSpinResultData.p_selfMakeData or {}
    local collectdata = selfdata.collect or {}
    local singleData = collectdata[index] or {collectChangeCount = 0,collectCoinsPool = 0,collectLeftCount = 0,collectTotalCount = 0}

    if isclose then

        for i=1,8 do
            local smallFlower = self["m_flower_"..index]["smallHua"..i]
            -- if self["m_flower_"..index]["smallHua"..i].m_isClose ~= true then
                util_spinePlay(smallFlower,"yahei")
                smallFlower.m_isClose = true
            -- end
        end

    else


        local collectLeftCount = singleData.collectLeftCount

        if isBtnClickUpdate and collectLeftCount > 0 then
            collectLeftCount = collectLeftCount - 1
        end

        for i=1,8 do
            
            if i > collectLeftCount or isLock then

                local smallFlower = self["m_flower_"..index]["smallHua"..i]

                util_spinePlay(smallFlower,"idleframe3",true)

                if smallFlower.m_isClose ~= true then
                    util_spinePlay(smallFlower,"xiaohe")
                    smallFlower.m_isClose = true
                end
            else


                local smallFlower = self["m_flower_"..index]["smallHua"..i]
                if smallFlower.m_isClose == true then
                    util_spinePlay(smallFlower,"xiaokai")
                    smallFlower.m_isClose = false
                end
            end
            
        end
        
    end
    

    if not notUpdate then
        self:updateFlowersCoins(machine ,index , isclose ,isBtnClickUpdate )
    end

    

end


function FloweryPixieHuaNodeView:updateFlowersCoins(machine ,index , isclose , isBtnClickUpdate )
    local selfdata = machine.m_runSpinResultData.p_selfMakeData or {}
    local collectdata = selfdata.collect or {}
    local singleData = collectdata[index] or {collectChangeCount = 0,collectCoinsPool = 0,collectLeftCount = 0,collectTotalCount = 0}

    local collectCoinsPool = singleData.collectCoinsPool

    if not isBtnClickUpdate then
        self["m_flower_"..index]:findChild("BitmapFontLabel_2_0"):setString(util_formatCoins(collectCoinsPool, 3))
    end
    
    
    if collectCoinsPool and collectCoinsPool == 0 then
        if not isBtnClickUpdate then
            self["m_flower_"..index]:findChild("BitmapFontLabel_2_0"):setString("")
        end

        
        self["m_flower_"..index]:runCsbAction("idleframe1")
    end

    if not isclose and collectCoinsPool and collectCoinsPool > 0 then


        if not isBtnClickUpdate then
            if self["m_flower_"..index].m_labShow ~= true then
                self["m_flower_"..index]:runCsbAction("actionframe")
                self["m_flower_"..index].m_labShow = true
            end
        end
        
        

    else
        if self["m_flower_"..index].m_labShow == true then
            self["m_flower_"..index]:runCsbAction("idleframe1")
            self["m_flower_"..index].m_labShow = false
        end
        
    end

end

function FloweryPixieHuaNodeView:updateForAct(machine,index,Bnonus_1_collectdata )
    
    self:updateBigSingleFlowers(machine, index,nil,nil ) 
    -- self:updateSmallFlower( machine ,index,nil,nil,nil  )
    self:updateFlowersCoins_Act(machine,index,Bnonus_1_collectdata )
end

function FloweryPixieHuaNodeView:updateFlowersCoins_Act(machine,index,Bnonus_1_collectdata )
    local selfdata = machine.m_runSpinResultData.p_selfMakeData or {}
    local collectdata = selfdata.collect or {}

    if Bnonus_1_collectdata then
        collectdata = Bnonus_1_collectdata or {}
    end

    local singleData = collectdata[index] or {collectChangeCount = 0,collectCoinsPool = 0,collectLeftCount = 0,collectTotalCount = 0}

    local collectCoinsPool = singleData.collectCoinsPool

    self["m_flower_"..index]:findChild("BitmapFontLabel_2_0"):setString(util_formatCoins(collectCoinsPool, 3))
    self["m_flower_"..index]:runCsbAction("idleframe2")
    self["m_flower_"..index].m_labShow = true

    if collectCoinsPool and collectCoinsPool == 0 then
        self["m_flower_"..index]:findChild("BitmapFontLabel_2_0"):setString("")
        self["m_flower_"..index]:runCsbAction("idleframe1")
    end

end

return FloweryPixieHuaNodeView