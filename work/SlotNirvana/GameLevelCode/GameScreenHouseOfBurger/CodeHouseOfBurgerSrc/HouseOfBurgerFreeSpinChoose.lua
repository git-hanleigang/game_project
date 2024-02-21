
local HouseOfBurgerFreeSpinChoose = class("HouseOfBurgerFreeSpinChoose", util_require("base.BaseView"))

function HouseOfBurgerFreeSpinChoose:initUI(data,callback,machine)
    self.m_machine = machine
    local resourceFilename = "HouseOfBurger/GameChoose.csb"
    self:createCsbNode(resourceFilename)
    self.m_click = false
    self.m_callFun = callback
    self:initData(data)
    self:runCsbAction("start",false,function()
        if self.m_click == false then
            self:runCsbAction("idle",true)
        end
    end)
end
function HouseOfBurgerFreeSpinChoose:initData(data)

    self:addClick(self:findChild("Button_1"))
    self:addClick(self:findChild("Button_2"))
    self:addClick(self:findChild("Button_3"))
    --lbs_mulMax2  lbs_mulMin3  lbs_times3
    local temp = {data.triggerTimes_0,data.triggerTimes_1,data.triggerTimes_2}
    for i=1,#temp do
        self:findChild("lbs_times"..i):setString(temp[i].times)
        self:findChild("lbs_mulMin"..i):setString(temp[i].minMultiplier)
        self:findChild("lbs_mulMax"..i):setString(temp[i].maxMultiplier)
    end
end

function HouseOfBurgerFreeSpinChoose:onExit()
    gLobalNoticManager:removeAllObservers(self)
end

function HouseOfBurgerFreeSpinChoose:enableBtn(isEnable)
    self:findChild("Button_1"):setTouchEnabled(isEnable)
    self:findChild("Button_2"):setTouchEnabled(isEnable)
    self:findChild("Button_3"):setTouchEnabled(isEnable)
end

function HouseOfBurgerFreeSpinChoose:clickFunc(sender)
    local name = sender:getName()
    gLobalSoundManager:playSound(SOUND_ENUM.MUSIC_BTN_CLICK)
    self:enableBtn(false)
    local type = 0
    self.m_click = true
    if name == "Button_1" then
        type = 0
        self:runCsbAction("show1",false,function()
            if self.m_callFun then
                self.m_callFun(type)
            end
            self:removeFromParent()
        end)
    elseif name == "Button_2" then
        type = 1
        self:runCsbAction("show2",false,function()
            if self.m_callFun then
                self.m_callFun(type)
            end
            self:removeFromParent()
        end)
    elseif name == "Button_3" then
        type = 2
        self:runCsbAction("show3",false,function()
            if self.m_callFun then
                self.m_callFun(type)
            end
            self:removeFromParent()

        end)
    end

end

return HouseOfBurgerFreeSpinChoose