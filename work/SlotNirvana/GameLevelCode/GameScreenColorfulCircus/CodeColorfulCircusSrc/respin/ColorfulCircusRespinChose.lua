local ColorfulCircusRespinChose = class("ColorfulCircusRespinChose", util_require("Levels.BaseLevelDialog"))
function ColorfulCircusRespinChose:initUI(data,callback)
    local resourceFilename = "ColorfulCircus/ReSpinChoose.csb"
    self:createCsbNode(resourceFilename)
    self:initShow()
    self.m_data = data
    self.m_callFun = callback
    self.isClick = true
    self.m_canTurn = true
    self.chooseNum = 0
    -- self:initView()
    self:runCsbAction("start")
    -- util_spinePlay(self.m_spineTanban,"start",false)
    self.m_result_view = util_createAnimation("ColorfulCircus_respin_choose.csb")
    self:findChild("Node_ban"):addChild(self.m_result_view)
    self.m_result_view:setVisible(false)

    

    local lock = util_createAnimation("ColorfulCircus_tanban_shanshuo3.csb")
    self:findChild("shanshuo"):addChild(lock)
    lock:playAction("animation0", true)

    self.spine_ball = {}
    self.spine_ball_effect = {}
    for i=1,3 do
        self.spine_ball[i] = util_spineCreate("ColorfulCircus_respin_qiqiu",true,true)
        self:findChild("qiqiu1"):addChild(self.spine_ball[i], 1)
        util_spinePlay(self.spine_ball[i],"idleframe",true)

        self.spine_ball_effect[i] = util_createAnimation("ColorfulCircus_collect_qiqiu_caidai.csb")
        self.spine_ball_effect[i]:setVisible(false)
        util_spinePushBindNode(self.spine_ball[i],"guang", self.spine_ball_effect[i])
        util_setCascadeOpacityEnabledRescursion(self.spine_ball[i], true)
        if i ~= 1 then
            local nodePos = util_convertToNodeSpace(self:findChild("qiqiu" .. i), self:findChild("qiqiu1"))
            self.spine_ball[i]:setPosition(cc.p(nodePos))
        end
        
    end
    -- util_spinePushBindNode(self.m_spineTanban,"anniu",btnView)

    self:addClick(self:findChild("Panel_1")) -- 非按钮节点得手动绑定监听
    self:addClick(self:findChild("Panel_2")) -- 非按钮节点得手动绑定监听
    self:addClick(self:findChild("Panel_3")) -- 非按钮节点得手动绑定监听
    -- globalMachineController:playSound("ColorfulCircusSounds/music_ColorfulCircus_respinChoose.mp3",false)

    performWithDelay(self,function (  )
        self.isClick = false
        self:runCsbAction("idle",true)

        

        -- util_spinePlay(self.m_spineTanban,"idle",true)
    end,35/60)

    self.m_result_view:setVisible(true)
    self.m_result_view:runCsbAction("start", false, function()
        self.m_result_view:runCsbAction("idle", true)

        self:beginTurn( )
    end)
    
end

function ColorfulCircusRespinChose:onEnter()
    ColorfulCircusRespinChose.super.onEnter(self)
end

function ColorfulCircusRespinChose:onExit()
    ColorfulCircusRespinChose.super.onExit(self)
end

function ColorfulCircusRespinChose:beginTurn( )
    if self.m_canTurn then
        local idx = math.random(1, 3)
        local j = 1
        for i = 1, 3 do
            if idx ~= i then
                j = i
            end
        end
        for i = 1, 3 do
            if idx ~= i then
                if self.spine_ball[i] then
                    util_spinePlay(self.spine_ball[i],"idleframe2",false)
                    util_spineEndCallFunc(self.spine_ball[i],"idleframe2", function()
                        util_spinePlay(self.spine_ball[i],"idleframe",false)
                        if j == i then
                            performWithDelay(self, function()
                                self:beginTurn( )
                            end, 0.2)
                        end
                    end)
                end
            end
        end
        
    else
        return
    end
end

function ColorfulCircusRespinChose:initShow( )
    -- self.m_spineTanban  = util_spineCreate("ColorfulCircus_ExtraTimes",true,true)
    -- self:findChild("bg"):addChild(self.m_spineTanban,10000)
end

function ColorfulCircusRespinChose:clickFunc(sender)
    local name = sender:getName()

    
    if self.isClick then
        return
    end
    -- local randomNum = math.random(1,2)
    -- if randomNum == 1 then
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respin_choose1.mp3")
    -- else
        -- gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respin_choose2.mp3")
    -- end
    self.isClick = true
    local type = 0
    local pickName = "pick1"
    if name == "Panel_1" then
        type = 1
        pickName = "pick1"
    elseif name == "Panel_2" then
        type = 2
        pickName = "pick2"

    elseif name == "Panel_3" then
        type = 3
        pickName = "pick3"

    end


    self.m_canTurn = false
    local temp = self:getFormatList(type)
    for i=1,#temp do
        local num = temp[i]
        local coinsView = util_createAnimation("ColorfulCircus_respin_qiqiu_wenzi.csb")
        if num == self.chooseNum then
            -- coinsView:runCsbAction("idle")
            
            util_spinePlay(self.spine_ball[i],"dianji",false)
            self.m_result_view:runCsbAction("over", false, function()
                self.m_result_view:setVisible(false)
            end)

            if self.spine_ball_effect[i] then
                self.spine_ball_effect[i]:setVisible(true)
                self.spine_ball_effect[i]:runCsbAction("actionframe", false, function (  )
                    self.spine_ball_effect[i]:setVisible(false)
                end)
            end
            


            self.spine_ball[i]:setLocalZOrder(2)

        else
            -- coinsView:runCsbAction("dark")
            util_spinePlay(self.spine_ball[i],"yaan",false)
        end
        coinsView:findChild("m_lb_num"):setString(num)
        
        -- coinsView:findChild("m_lb_coins2"):setString(num)

        if num == 1 then
            local spin = util_createAnimation("ColorfulCircus_respin_spin.csb")
            spin:runCsbAction("idleframe")
            util_spinePushBindNode(self.spine_ball[i],"spin", spin)
        else
            local spins = util_createAnimation("ColorfulCircus_respin_spins.csb")
            spins:runCsbAction("idleframe")
            util_spinePushBindNode(self.spine_ball[i],"spins", spins)
        end

        coinsView:runCsbAction("idleframe")
        util_spinePushBindNode(self.spine_ball[i],"wenzi", coinsView)
        util_setCascadeOpacityEnabledRescursion(self.spine_ball[i], true)
    end
    -- util_spinePlay(self.m_spineTanban,pickName,false)
    -- self.m_spineFanKui  = util_spineCreate("ColorfulCircus_ExtraTimes_glow",true,true)
    -- self:findChild("effNode_2"):addChild(self.m_spineFanKui,10000)
    -- util_spinePlay(self.m_spineFanKui,pickName,false)
    -- self:runCsbAction("pick")
    performWithDelay(self,function()
        gLobalSoundManager:playSound("ColorfulCircusSounds/music_ColorfulCircus_respin_choose_over.mp3")
        self:runCsbAction("over", false, function()
            if self.m_callFun then
                self.m_callFun()
            end
            self:removeFromParent()
        end)
        
    end,2)

end


function ColorfulCircusRespinChose:getFormatList(type)
    if self.m_data.options == nil then
        return {-1,-1,-1}
    end
    self.chooseNum = 0
    local temp = {-1,-1,-1}
    temp[type] = self.m_data.options[self.m_data.select + 1]
    self.chooseNum = self.m_data.options[self.m_data.select + 1]
    table.remove( self.m_data.options, self.m_data.select + 1 )

    local randTimeDir = math.random(1,100) --为了随机性 正向取还是逆向取
    local isTimeDir = randTimeDir < 50
    for i=1,#temp do
        if temp[i] == -1 then
            if #self.m_data.options > 0 then
                if isTimeDir then
                    temp[i] = self.m_data.options[1]
                    table.remove( self.m_data.options, 1 )
                else
                    temp[i] = self.m_data.options[#self.m_data.options]
                    table.remove( self.m_data.options, #self.m_data.options )
                end
            end
        end
    end
    return temp
end

return ColorfulCircusRespinChose