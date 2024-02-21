local ChilliFiestaRespinChose = class("ChilliFiestaRespinChose", util_require("base.BaseView"))
function ChilliFiestaRespinChose:initUI(data,callback)
    local resourceFilename = "ChilliFiesta/ExtraTimes.csb"
    self:createCsbNode(resourceFilename)
    self.m_data = data
    self.m_callFun = callback
    self:initView()
    self:runCsbAction("start",false,function()
        self:runCsbAction("idle",true)
    end)
    -- gLobalSoundManager:setBackgroundMusicVolume(0.4)
    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_respinChoose.mp3",false)
end

function ChilliFiestaRespinChose:initView()
    self.m_chooseNumList = {}
    self.m_chooseSpinList = {}
    self.m_chooseBgList = {}
    self.m_chooseBgSmallList = {}
    self.m_BgList = {}
    self.m_UnBgList = {}

    for i=1,3 do
        self.m_chooseNumList[i] = self:findChild("chooseNum"..i)
        self.m_chooseNumList[i]:setVisible(false)
        self.m_chooseSpinList[i] = self:findChild("chooseSpin"..i)
        self.m_chooseSpinList[i]:setVisible(false)
        self.m_chooseBgList[i] = self:findChild("chooseBg"..i)
        self.m_chooseBgSmallList[i] = self:findChild("chooseBgSmall"..i)
        self:addClick(self:findChild("Button"..i))

        self.m_BgList[i] = self:findChild("di_select"..i)
        self.m_UnBgList[i] = self:findChild("di_unselect"..i)

    end

    self.m_title_select = self:findChild("title_select")
    self.m_title_youwin = self:findChild("title_youwin")
    self.m_title_youwin:setVisible(false)
end

function ChilliFiestaRespinChose:onEnter()
    gLobalSoundManager:setBackgroundMusicVolume(0)

end

function ChilliFiestaRespinChose:onExit()
    gLobalSoundManager:setBackgroundMusicVolume(1)

end

function ChilliFiestaRespinChose:enableBtn(isEnable)
    self:findChild("Button1"):setTouchEnabled(isEnable)
    self:findChild("Button2"):setTouchEnabled(isEnable)
    self:findChild("Button3"):setTouchEnabled(isEnable)
end



function ChilliFiestaRespinChose:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_respinChooseClick.mp3")

    self:enableBtn(false)

    local type = 0
    if name == "Button1" then
        type = 1
    elseif name == "Button2" then
        type = 2
    elseif name == "Button3" then
        type = 3
    end
    self:initEffect()

    self:runCsbAction("result")
    self.m_title_select:setVisible(false)
    self.m_title_youwin:setVisible(true)
    local sp = self:findChild("Sprite_10")
    if sp then
        sp:setVisible(false)
    end
    


    local temp = self:getFormatList(type)
    for i=1,#temp do
        local num = temp[i]
        if i == type then
            self["m_effect"..i]:setVisible(true)
            self["m_effect"..i]:playAction("actionframe")
            self.m_chooseBgList[i]:setVisible(false)
            self.m_chooseBgSmallList[i]:setVisible(false)
            self:changeSprite(self.m_chooseNumList[i],"#ChilliFiesta/Common/ChiliFiesta_respin_"..num..".png")
            if num > 1 then
                self:changeSprite(self.m_chooseSpinList[i],"#ChilliFiesta/Common/ChiliFiesta_respin_spins"..".png")
            else
                self:changeSprite(self.m_chooseSpinList[i],"#ChilliFiesta/Common/ChiliFiesta_respin_spin"..".png")
            end
            self.m_BgList[i]:setVisible(true)
            self.m_UnBgList[i]:setVisible(false)
            self.m_chooseNumList[i]:setVisible(true)
            self.m_chooseSpinList[i]:setVisible(true)
        end
    end

    performWithDelay(self,function()
        for i=1,#temp do
            local num = temp[i]
            if i ~= type then
                self["m_effect"..i]:setVisible(true)
                self["m_effect"..i]:playAction("actionframe")
                self.m_chooseBgList[i]:setVisible(false)
                self.m_chooseBgSmallList[i]:setVisible(false)
                self:changeSprite(self.m_chooseNumList[i],"#ChilliFiesta/Common/ChiliFiesta_respin_"..num..num..".png")
                if num > 1 then
                    self:changeSprite(self.m_chooseSpinList[i],"#ChilliFiesta/Common/ChiliFiesta_respin_spinsUn2"..".png")
                else
                    self:changeSprite(self.m_chooseSpinList[i],"#ChilliFiesta/Common/ChiliFiesta_respin_spinUn2"..".png")
                end
                self.m_BgList[i]:setVisible(false)
                self.m_UnBgList[i]:setVisible(true)
                self.m_chooseNumList[i]:setVisible(true)
                self.m_chooseSpinList[i]:setVisible(true)
            end
        end
        performWithDelay(self,function()
            self:runCsbAction("over",false,function()
                if self.m_callFun then
                    self.m_callFun()
                end
                self:removeFromParent()
            end)
        end,2)
    end,0.33)
end

function ChilliFiestaRespinChose:changeSprite(sprite,url)
    local frame = display.newSpriteFrame(url)
    if frame then
        sprite:setSpriteFrame(frame)
    end
end


function ChilliFiestaRespinChose:getFormatList(type)
    local temp = {-1,-1,-1}
    temp[type] = self.m_data.options[self.m_data.select + 1]

    table.remove( self.m_data.options, self.m_data.select + 1 )
    for i=1,#temp do
        if temp[i] == -1 then
            temp[i] = self.m_data.options[#self.m_data.options]
            table.remove( self.m_data.options, #self.m_data.options )
        end
    end
    return temp
end

function ChilliFiestaRespinChose:initEffect()
    self.m_effect1 = util_createAnimation("ChilliFiesta_ExtraTimes_xuanzhong.csb")
    self.m_effect1:playAction("idle")
    self:findChild("effNode_1"):addChild(self.m_effect1)
    self.m_effect1:setVisible(false)
    self.m_effect2 = util_createAnimation("ChilliFiesta_ExtraTimes_xuanzhong.csb")
    self.m_effect2:playAction("idle")
    self:findChild("effNode_2"):addChild(self.m_effect2)
    self.m_effect2:setVisible(false)
    self.m_effect3 = util_createAnimation("ChilliFiesta_ExtraTimes_xuanzhong.csb")
    self.m_effect3:playAction("idle")
    self:findChild("effNode_3"):addChild(self.m_effect3)
    self.m_effect3:setVisible(false)
end


return ChilliFiestaRespinChose