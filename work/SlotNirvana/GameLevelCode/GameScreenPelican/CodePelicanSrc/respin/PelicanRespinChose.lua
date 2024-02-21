local PelicanRespinChose = class("PelicanRespinChose", util_require("base.BaseView"))
function PelicanRespinChose:initUI(data,callback)
    local resourceFilename = "Pelican/ExtraTimes.csb"
    self:createCsbNode(resourceFilename)
    self:initShow()
    self.m_data = data
    self.m_callFun = callback
    self.isClick = true
    self.chooseNum = 0
    -- self:initView()
    self:runCsbAction("start")
    util_spinePlay(self.m_spineTanban,"start",false)
    performWithDelay(self,function (  )
        self.isClick = false
        self:runCsbAction("idle",true)
        util_spinePlay(self.m_spineTanban,"idle",true)
    end,3.5/3)
    self:addClick(self:findChild("Button1")) -- 非按钮节点得手动绑定监听
    self:addClick(self:findChild("Button2")) -- 非按钮节点得手动绑定监听
    self:addClick(self:findChild("Button3")) -- 非按钮节点得手动绑定监听
    -- globalMachineController:playSound("PelicanSounds/music_Pelican_respinChoose.mp3",false)
end

function PelicanRespinChose:initShow( )
    self.m_spineTanban  = util_spineCreate("Pelican_ExtraTimes",true,true)
    self:findChild("bg"):addChild(self.m_spineTanban,10000)
end

function PelicanRespinChose:clickFunc(sender)
    local name = sender:getName()

    
    if self.isClick then
        return
    end
    local randomNum = math.random(1,2)
    if randomNum == 1 then
        gLobalSoundManager:playSound("PelicanSounds/music_Pelican_respin_choose1.mp3")
    else
        gLobalSoundManager:playSound("PelicanSounds/music_Pelican_respin_choose2.mp3")
    end
    self.isClick = true
    local type = 0
    local pickName = "pick1"
    if name == "Button1" then
        type = 1
        pickName = "pick1"
    elseif name == "Button2" then
        type = 2
        pickName = "pick2"

    elseif name == "Button3" then
        type = 3
        pickName = "pick3"

    end


    local temp = self:getFormatList(type)
    for i=1,#temp do
        local num = temp[i]
        local coinsView = util_createAnimation("Pelican/FreeSpinOver_num.csb")
        if num == self.chooseNum then
            coinsView:runCsbAction("idle")
        else
            coinsView:runCsbAction("dark")
        end
        coinsView:findChild("m_lb_coins"):setString(num)
        coinsView:findChild("m_lb_coins2"):setString(num)
        util_spinePushBindNode(self.m_spineTanban,"shuzi"..i , coinsView)
    end
    util_spinePlay(self.m_spineTanban,pickName,false)
    self.m_spineFanKui  = util_spineCreate("Pelican_ExtraTimes_glow",true,true)
    self:findChild("effNode_2"):addChild(self.m_spineFanKui,10000)
    util_spinePlay(self.m_spineFanKui,pickName,false)
    self:runCsbAction("pick")
    performWithDelay(self,function()
        if self.m_callFun then
            self.m_callFun()
        end
        self:removeFromParent()
    end,2)

end


function PelicanRespinChose:getFormatList(type)
    self.chooseNum = 0
    local temp = {-1,-1,-1}
    temp[type] = self.m_data.options[self.m_data.select + 1]
    self.chooseNum = self.m_data.options[self.m_data.select + 1]
    table.remove( self.m_data.options, self.m_data.select + 1 )
    for i=1,#temp do
        if temp[i] == -1 then
            temp[i] = self.m_data.options[#self.m_data.options]
            table.remove( self.m_data.options, #self.m_data.options )
        end
    end
    return temp
end

return PelicanRespinChose