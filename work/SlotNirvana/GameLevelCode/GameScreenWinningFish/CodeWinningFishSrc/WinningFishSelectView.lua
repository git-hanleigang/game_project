---
--smy
--2018年4月26日
--WinningFishSelectView.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local WinningFishSelectView = class("WinningFishSelectView",BaseGame )

local BTN_TAG_FREESPIN      =       1           --freespin按钮
local BTN_TAG_RESPIN        =       2           --respin按钮

function WinningFishSelectView:initUI()
    self:createCsbNode("WinningFish/FreeSpinChoice.csb")
    
    --respin按钮
    self.btn_respin = util_createAnimation("WinningFish/FreeSpinChoice_zhenzhu.csb")
    self.btn_respin:findChild("WinningFish_freegame"):setVisible(false)
    self:addClick(self.btn_respin:findChild("panel"))
    self.btn_respin:findChild("panel"):setTag(BTN_TAG_RESPIN)
    self:findChild("Node_zhenzhu"):addChild(self.btn_respin)

    --freegame按钮
    self.btn_freeGame = util_createAnimation("WinningFish/FreeSpinChoice_zhenzhu.csb")
    self.btn_freeGame:findChild("WinningFish_reelrespin"):setVisible(false)
    self:addClick(self.btn_freeGame:findChild("panel"))
    self.btn_freeGame:findChild("panel"):setTag(BTN_TAG_FREESPIN)
    self:findChild("Node_zhenzhu2"):addChild(self.btn_freeGame)

    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_zhenzhu"),true)
    util_setCascadeOpacityEnabledRescursion(self:findChild("Node_zhenzhu2"),true)

    

    self.m_callBack = nil
    self.m_isWaiting = false
end

function WinningFishSelectView:onEnter()
    BaseGame.onEnter(self)
end
function WinningFishSelectView:onExit()
    BaseGame.onExit(self)
end

function WinningFishSelectView:showView(callBack)
    self:setVisible(true)
    self.m_isWaiting = true
    self.m_callBack = callBack
    self.m_machine:showCollectionRes(false)
    -- self:findChild("Node_lizi"):setPositionY(0)
    
    util_runAnimations({
        {
            type = "delay",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            delayTime = 0.8,
            callBack = function (  )
                -- self:findChild("Particle_1"):resetSystem()
                -- self:findChild("Particle_3"):resetSystem()
                -- self:findChild("Particle_1"):setPositionType(0)
                -- self:findChild("Particle_3"):setPositionType(0)
            end
        },
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "start", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
            keyFrameList = {  --骨骼动画用 关键帧列表 可选参数
                {
                    keyFrameIndex = 49,    --关键帧数  帧动画用
                    callBack = function (  )
                        self.btn_respin:runCsbAction("idle",true)
                        self.btn_freeGame:runCsbAction("idle",true)
                    end,
                },       --关键帧回调
                {
                    keyFrameIndex = 80,    --关键帧数  帧动画用
                    callBack = function (  )
                        -- self:findChild("Particle_1"):setVisible(false)
                        -- self:findChild("Particle_3"):setVisible(false)
                    end,
                }       --关键帧回调
            },   
            callBack = function (  )
                -- self:findChild("Particle_1"):setPositionType(1)
                -- self:findChild("Particle_3"):setPositionType(1)
                self:runCsbAction("idle",true)
                self.m_isWaiting = false
            end
        }
    })
        
end

--[[
    隐藏界面
]]
function WinningFishSelectView:hideView()
    util_runAnimations({
        {
            type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
            node = self,   --执行动画节点  必传参数
            actionName = "over", --动作名称  动画必传参数,单延时动作可不传
            fps = 60,    --帧率  可选参数  
            callBack = function (  )
                self:setVisible(false)
            end
        }
    })
    
end

--[[
    按钮回调
]]
function WinningFishSelectView:clickFunc(sender)
    if self.m_isWaiting then
        return
    end
    gLobalSoundManager:playSound("WinningFishSounds/sound_winningFish_select_click.mp3")
    --防止连续点击
    self.m_isWaiting = true
    self:stopAllActions()
    
    local btn_tag = sender:getTag()
    local function func()
        self.m_curChoose = btn_tag
        self:sendData(btn_tag - 1)
        if self.m_curChoose == 1 then
            self:hideView()
        end
        
    end
    

    if btn_tag == BTN_TAG_FREESPIN then
        util_runAnimations({
            {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self.btn_freeGame,   --执行动画节点  必传参数
                actionName = "start", --动作名称  动画必传参数,单延时动作可不传
                fps = 60,    --帧率  可选参数  
                callBack = function (  )
                    self:runCsbAction("idle",true)
                    func()
                end
            }
        })

        util_runAnimations({
            {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self.btn_respin,   --执行动画节点  必传参数
                actionName = "over", --动作名称  动画必传参数,单延时动作可不传
                fps = 60,    --帧率  可选参数  
                callBack = function (  )
                    
                end
            }
        })
    else
        util_runAnimations({
            {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self.btn_respin,   --执行动画节点  必传参数
                actionName = "start", --动作名称  动画必传参数,单延时动作可不传
                fps = 60,    --帧率  可选参数  
                callBack = function (  )
                    self:runCsbAction("idle",true)
                    func()
                end
            }
        })

        util_runAnimations({
            {
                type = "animation",   --"animation":帧动画 "spine":骨骼动画 "delay":延时动作 "seq":序列动作 必传参数
                node = self.btn_freeGame,   --执行动画节点  必传参数
                actionName = "over", --动作名称  动画必传参数,单延时动作可不传
                fps = 60,    --帧率  可选参数  
                callBack = function (  )

                end
            }
        })
    end
end

-------------------子类继承-------------------
--处理数据 子类可以继承改写
--:calculateData(featureData)
--子类调用
--:getZoomScale(width)获取缩放比例
--:isTouch()item是否可以点击
--:sendStep(pos)item点击回调函数
--.m_otherTime=1      --其他宝箱展示时间
--.m_rewardTime=3     --结算界面弹出时间

function WinningFishSelectView:initViewData(callBackFun, gameSecen)
    self:initData()
    
end


function WinningFishSelectView:resetView(featureData, callBackFun, gameSecen)
    self:initData()
end

function WinningFishSelectView:initData()
    self:initItem()
end

function WinningFishSelectView:initItem()
    
end

--数据发送
function WinningFishSelectView:sendData(choose)
    self.m_action=self.ACTION_SEND
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT , data = choose}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end


function WinningFishSelectView:uploadCoins(featureData)
    
end

--数据接收
function WinningFishSelectView:recvBaseData(featureData)
    self.m_action=self.ACTION_RECV
    
    if type(self.m_callBack) == "function" then
        self.m_callBack(self.m_curChoose)
    end
end

function WinningFishSelectView:sortNetData(data)
    -- 服务器非得用这种结构 只能本地转换一下结构
    local localdata = {}
    if data.bonus then
        if data.bonus then
            data.choose = data.bonus.choose
            data.content = data.bonus.content
            data.extra = data.bonus.extra
            data.status = data.bonus.status

        end
    end 


    localdata = data

    return localdata
end

--[[
    接受网络回调
]]
function WinningFishSelectView:featureResultCallFun(param)
    local selfData = self.m_machine.m_runSpinResultData.p_selfMakeData
    if selfData and selfData.bonusType and selfData.bonusType == "select" then
        BaseGame.featureResultCallFun(self,param)
    end
end
return WinningFishSelectView