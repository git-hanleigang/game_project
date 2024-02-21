

local TrainYourDragonDragonGrowView = class("TrainYourDragonDragonGrowView", util_require("base.BaseView"))

function TrainYourDragonDragonGrowView:initUI()
    local resourceFilename = "TrainYourDragon/JindutiaoZhongjiang.csb"
    self:createCsbNode(resourceFilename)
end
-- growState成长阶段，1为变小龙，2为变大龙
function TrainYourDragonDragonGrowView:initViewData(growState)
    self.m_growState = growState
    --添加变身特效
    self.m_changeEff = util_createAnimation("TrainYourDragon_long_bg_eff.csb")
    self:findChild("rootNode"):addChild(self.m_changeEff)
    self.m_changeEff:setVisible(false)
    --添加箭头
    self.m_jiantou1 = util_createAnimation("Socre_TrainYourDragon_jiantou.csb")
    self:findChild("jiantou1"):addChild(self.m_jiantou1)
    self.m_jiantou2 = util_createAnimation("Socre_TrainYourDragon_jiantou.csb")
    self:findChild("jiantou2"):addChild(self.m_jiantou2)
    --添加金蛋图标
    self.m_jindanTubiao = util_createAnimation("TrainYourDragon_jindutiao_base_dan.csb")
    self:findChild("jindantubiao"):addChild(self.m_jindanTubiao)
    --添加小龙图标
    self.m_xiaolongTubiao = util_createAnimation("TrainYourDragon_jindutiao_base_xiaolong.csb")
    self:findChild("xiaolongtubiao"):addChild(self.m_xiaolongTubiao)
    --添加大龙图标
    self.m_dalongTubiao = util_createAnimation("TrainYourDragon_jindutiao_base_dalong.csb")
    self:findChild("dalongtubiao"):addChild(self.m_dalongTubiao)

    if self.m_growState == 1 then
        --添加金蛋
        self.m_jindan = util_createAnimation("TrainYourDragon_long_dan.csb")
        self:findChild("jindanNode"):addChild(self.m_jindan)
        --添加小龙
        self.m_xiaolong = util_createAnimation("TrainYourDragon_long_xiao.csb")
        self:findChild("xiaolongNode"):addChild(self.m_xiaolong)
        self.m_xiaolong:setVisible(false)
        self.m_xiaolongSpine = util_spineCreate("TrainYourDragon_long_xiao",true,true)
        self.m_xiaolong:findChild("Node_long"):addChild(self.m_xiaolongSpine)

        self.m_jindanTubiao:playAction("idle")
        self.m_xiaolongTubiao:playAction("huiidle")
        self.m_dalongTubiao:playAction("huiidle")
        self.m_jiantou1:playAction("huiidle")
        self.m_jiantou2:playAction("huiidle")
    elseif self.m_growState == 2 then
        --添加小龙
        self.m_xiaolong = util_createAnimation("TrainYourDragon_long_xiao.csb")
        self:findChild("xiaolongNode"):addChild(self.m_xiaolong)
        self.m_xiaolongSpine = util_spineCreate("TrainYourDragon_long_xiao",true,true)
        self.m_xiaolong:findChild("Node_long"):addChild(self.m_xiaolongSpine)
        util_spinePlay(self.m_xiaolongSpine,"idleframe",true)
        --添加大龙
        self.m_dalong = util_spineCreate("TrainYourDragon_long_da",true,true)
        self:findChild("dalongNode"):addChild(self.m_dalong)
        self.m_dalong:setVisible(false)

        self.m_jindanTubiao:playAction("idle")
        self.m_xiaolongTubiao:playAction("liangidle")
        self.m_dalongTubiao:playAction("huiidle")
        self.m_jiantou1:playAction("liangidle")
        self.m_jiantou2:playAction("huiidle")
    end

    gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_DragonGrowView.mp3")
    self:runCsbAction("start",false,function ()
        self:runCsbAction("idle",true)
        self:startGrow()
    end)
end
function TrainYourDragonDragonGrowView:startGrow()
    if self.m_growState == 1 then
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_jiantoubianliang.mp3")
        self.m_jiantou1:playAction("huibianbai",false,function ()
            gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_tubiaobianliang.mp3")
            self.m_xiaolongTubiao:playAction("huibianbai",false,function ()
                self.m_xiaolongTubiao:playAction("liangidle",true)
    
                gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_longdandakai.mp3")
                self.m_jindan:playAction("jinhua",false)
                self.m_changeEff:setVisible(true)
    
                self.m_changeEff:playAction("change1",false,function ()
                    --弹出给钱弹框
                    gLobalNoticManager:postNotification("CodeGameScreenTrainYourDragonMachine_showTrainYourDragonDragonGrowWinCoinView",{1}) 
                end)
                performWithDelay(self.m_changeEff,function ()
                    self.m_xiaolong:setVisible(true)
                    util_spinePlay(self.m_xiaolongSpine,"idleframe",true)
                    self.m_xiaolong:playAction("idle")
                end,35/30)
            end)
        end)
        
    elseif self.m_growState == 2 then
        gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_jiantoubianliang.mp3")
        self.m_jiantou2:playAction("huibianbai",false,function ()
            gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_tubiaobianliang.mp3")
            self.m_dalongTubiao:playAction("huibianbai",false,function ()
                self.m_dalongTubiao:playAction("liangidle",true)
    
                gLobalSoundManager:playSound("TrainYourDragonSounds/music_TrainYourDragon_xiaolongbianda.mp3")
                util_spinePlay(self.m_xiaolongSpine,"jinhua",false)
                self.m_xiaolong:playAction("jinhua")
                self.m_changeEff:setVisible(true)
    
                self.m_changeEff:playAction("change2",false,function ()
                    self.m_dalong:setAnimation(0, "actionframe1", false)
                    self.m_dalong:addAnimation(0, "actionframe3", false)
    
                    local bonusguochangEye = util_createAnimation("TrainYourDragon_guochang.csb")
                    self:getParent():addChild(bonusguochangEye,1)
                    bonusguochangEye:setPosition(display.center)
                    bonusguochangEye:playAction("actionframe",false,function ()
                        bonusguochangEye:removeFromParent()
                        gLobalNoticManager:postNotification("TrainYourDragonChooseGameView_enableBtn",{true})
                    end)
                    performWithDelay(self,function ()
                        gLobalNoticManager:postNotification("CodeGameScreenTrainYourDragonMachine_showTrainYourDragonChooseGameView")
                        self:removeFromParent()
                    end,50/30)
                end)
                performWithDelay(self.m_changeEff,function ()
                    self.m_dalong:setVisible(true)
                    util_spinePlay(self.m_dalong,"idleframe")
                end,20/30)
            end)
        end)
        
    end
end
function TrainYourDragonDragonGrowView:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)
        self:colseSelfView()
    end,"TrainYourDragonDragonGrowView_colseSelfView")
end

function TrainYourDragonDragonGrowView:onExit()
    gLobalNoticManager:removeAllObservers(self)
end
--关闭界面
function TrainYourDragonDragonGrowView:colseSelfView()
    self:runCsbAction("over",false,function ()
        self:removeFromParent()
    end)
end
return TrainYourDragonDragonGrowView