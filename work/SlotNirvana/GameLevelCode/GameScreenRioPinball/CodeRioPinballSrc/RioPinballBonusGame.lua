---
--smy
--2018年4月26日
--RioPinballBonusGame.lua


local SpinFeatureData = require "data.slotsdata.SpinFeatureData"
local SendDataManager = require "network.SendDataManager"
local BaseDialog = require "Levels.BaseDialog"
local BaseGame = util_require("base.BaseGame")
local RioPinballBonusGame = class("RioPinballBonusGame",BaseGame )



function RioPinballBonusGame:initUI(params)
    self.m_machine = params.machine

    self.m_miniMachine = util_createView("CodeRioPinballSrc.RioPinballMiniMachine",{machine = self.m_machine,parentView = self})
    self:addChild(self.m_miniMachine)

    self.m_curRound = 1
    self.m_callBack = nil
    self.m_bonusData = nil
end

function RioPinballBonusGame:onEnter()
    BaseGame.onEnter(self)
end
function RioPinballBonusGame:onExit()
    BaseGame.onExit(self)
end

--[[
    设置bonus数据
]]
function RioPinballBonusGame:setBonusData(data)
    self.m_curRound = data.round or 1
    self.m_bonusData = data
    self.m_miniMachine:setBonusData(data)
end

--[[
    刷新轮盘
]]
function RioPinballBonusGame:refreshReels(isBonusOver,func)
    if not isBonusOver and self.m_bonusData.ballProcess[self.m_curRound] == 0 then
        self.m_curRound = self.m_curRound + 1
        self.m_miniMachine:updateCurRound()
        self.m_miniMachine:updateBallCount(true,function()
            self.m_miniMachine:changeBonusSymbol(function()
                self.m_miniMachine:changeNewReel()
                -- self.m_miniMachine:hideAllSymbol()
                self.m_miniMachine:changeSymbolByRound(func)
            end)
        end)
        
        
    else
        self.m_miniMachine:refreshReelsByData()
        if type(func) == "function" then
            func()
        end
    end
end

--[[
    显示界面
]]
function RioPinballBonusGame:showView(callBack)
    self.m_callBack = callBack

    if self.m_bonusData.ballProcess[self.m_curRound] == 0 then
        self.m_curRound = self.m_curRound + 1
        self.m_miniMachine:changeNewReel()
    end
    self.m_miniMachine:refreshReelsByData()
    self.m_miniMachine:hideAllSymbol()
    self.m_miniMachine:startAction(function()

        self.m_miniMachine:changeBonusSymbol(function()
            self.m_miniMachine:changeSymbolByRound(function()
                self:sendData()
            end)
        end)
    end)
    
end

--[[
    关闭界面
]]
function RioPinballBonusGame:hideView()
    if type(self.m_callBack) == "function" then
        self.m_callBack()
        self.m_callBack = nil
    end
end

--

--[[
    按钮回调
]]
function RioPinballBonusGame:clickFunc(sender)
    
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

function RioPinballBonusGame:initViewData(callBackFun, gameSecen)
    self:initData()
    
end


function RioPinballBonusGame:resetView(featureData, callBackFun, gameSecen)
    self:initData()
end

function RioPinballBonusGame:initData()
    self:initItem()
end

function RioPinballBonusGame:initItem()
    
end

--数据发送
function RioPinballBonusGame:sendData()

    if self.m_isWaiting then
        return
    end
    self.m_action=self.ACTION_SEND
    self.m_isWaiting = true
    local httpSendMgr = SendDataManager:getInstance()
    -- 拼接 collect 数据， jackpot 数据
    local messageData = {msg=MessageDataType.MSG_BONUS_SELECT}
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end


function RioPinballBonusGame:uploadCoins(coins)
    self.m_bsWinCoins = coins
    
    self.m_miniMachine:resetWinCoins(self.m_bsWinCoins)
end


--数据接收
function RioPinballBonusGame:recvBaseData(featureData)
    self.m_action=self.ACTION_RECV
    self.m_isWaiting = false

    self:setBonusData(featureData.p_bonus.extra)
    self.m_bsWinCoins = featureData.p_bonus.bsWinCoins
    

    local isBonusOver = false
    if featureData.p_bonus.status ~= "OPEN" then
        isBonusOver = true
    end

    self.m_miniMachine:updateBallCount()
    self.m_miniMachine:showRouteList(function()
        
        self.m_miniMachine:ballMoveAction(function()
            self:refreshReels(isBonusOver,function()
                if isBonusOver then
                    self.m_machine:clearCurMusicBg()
                    self.m_miniMachine:changeParentToNormal()
                    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_The_gift_of_the_jungle.mp3")
                    gLobalSoundManager:playSound("RioPinballSounds/sound_RioPinball_fs_over_short_music.mp3")
                    self.m_machine:showBonusOverView(self.m_bsWinCoins,function()
                        self:hideView()
                    end)
                    
                else
                    self:sendData()
                end
            end)
        end)
    end)
    
end

function RioPinballBonusGame:sortNetData(data)
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
function RioPinballBonusGame:featureResultCallFun(param)
    if self:isVisible() then
        BaseGame.featureResultCallFun(self,param)
    end
end
return RioPinballBonusGame