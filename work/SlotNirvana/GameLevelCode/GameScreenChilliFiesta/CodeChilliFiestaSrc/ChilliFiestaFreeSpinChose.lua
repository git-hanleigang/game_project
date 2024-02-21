---
--island
--2018年4月12日
--ChilliFiestaFreeSpinChose.lua
---- respin 玩法结算时中 mini mijor等提示界面
local ChilliFiestaFreeSpinChose = class("ChilliFiestaFreeSpinChose", util_require("Levels.BaseLevelDialog"))


function ChilliFiestaFreeSpinChose:initUI(data,callback,machine)
    self.m_machine = machine
    local resourceFilename = "ChilliFiesta/FreeSpinChose.csb"
    self:createCsbNode(resourceFilename)
    self.m_click = false
    self.m_callFun = callback
    self:initData(data)

    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_freespin_choose.mp3")

    self:runCsbAction("start",false,function()
        if self.m_click == false then
            self:runCsbAction("idle",true)
        end
    end)
end
function ChilliFiestaFreeSpinChose:initData(data)

    local logo = util_createView("CodeChilliFiestaSrc.ChilliFiestaLogoView",true)
    self:findChild("logo"):addChild(logo)

    self:addClick(self:findChild("Button1"))
    self:addClick(self:findChild("Button2"))
    self:addClick(self:findChild("Button3"))

    local temp = {data["0"],data["1"],data["2"]}
    for i=1,#temp do
        self:findChild("lbs_freespinNum"..i):setString(temp[i].times)
        for j=1,#temp[i].wildMultiples do
            self:findChild("lbs_mul"..i..j):setString("X"..temp[i].wildMultiples[j])
        end
    end
end

-- function ChilliFiestaFreeSpinChose:onEnter()
--     gLobalNoticManager:addObserver(self,function(self,params)
--         local isSucc = params[1]
--         if isSucc then
--             -- util_playScaleToAction(self,1,0.01,function()
--                 self:removeFromParent()
--             -- end)
--         else
--             self:enableBtn(true)
--             self:runCsbAction("start",false,function()
--                 if self.m_click == false then
--                     self:runCsbAction("idle",true)
--                 end
--             end)
--         end

--     end,ViewEventType.NOTIFY_GET_SPINRESULT)
-- end

-- function ChilliFiestaFreeSpinChose:onExit()
--     gLobalNoticManager:removeAllObservers(self)
-- end

function ChilliFiestaFreeSpinChose:enableBtn(isEnable)
    self:findChild("Button1"):setTouchEnabled(isEnable)
    self:findChild("Button2"):setTouchEnabled(isEnable)
    self:findChild("Button3"):setTouchEnabled(isEnable)
end

function ChilliFiestaFreeSpinChose:clickFunc(sender)
    local name = sender:getName()
    -- gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    gLobalSoundManager:playSound("ChilliFiestaSounds/music_ChilliFiesta_freespin_chooseTimes.mp3")

    self:enableBtn(false)
    local type = 0
    self.m_click = true

    if name == "Button1" then
        type = 0
        self:runCsbAction("show1",false,function()
            self:requestServer(type)
            self:runCsbAction("idle1",function()
            end)
        end)
    elseif name == "Button2" then
        type = 1

        self:runCsbAction("show2",false,function()
            self:requestServer(type)
            self:runCsbAction("idle2",false,function()
            end)
        end)
    elseif name == "Button3" then
        type = 2
        self:runCsbAction("show3",false,function()
            self:requestServer(type)
            self:runCsbAction("idle3",function()
            end)
        end)
    end
    performWithDelay(self,function()
        self:removeFromParent()
    end,2.53)
end
function ChilliFiestaFreeSpinChose:requestServer(type)
    if self.m_callFun then
        self.m_callFun(type)
    end
end

function ChilliFiestaFreeSpinChose:onEnter()
    ChilliFiestaFreeSpinChose.super.onEnter(self)
    gLobalSoundManager:setBackgroundMusicVolume(0)
end

function ChilliFiestaFreeSpinChose:onExit()
    ChilliFiestaFreeSpinChose.super.onExit(self)
    gLobalSoundManager:setBackgroundMusicVolume(1)
end
return ChilliFiestaFreeSpinChose