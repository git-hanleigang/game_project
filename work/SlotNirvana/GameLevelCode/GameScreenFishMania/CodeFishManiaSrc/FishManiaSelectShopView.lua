---
--island
--2018年4月12日
--FishManiaSelectShopView.lua
local SendDataManager = require "network.SendDataManager"
local FishManiaSelectShopView = class("FishManiaSelectShopView", util_require("base.BaseView"))

FishManiaSelectShopView.BTN_SELECT_1 = "btn_1" 
FishManiaSelectShopView.BTN_SELECT_2 = "btn_2" 
FishManiaSelectShopView.BTN_SELECT_3 = "btn_3" 

FishManiaSelectShopView.m_isCanTouch = true


function FishManiaSelectShopView:onEnter()
    gLobalNoticManager:addObserver(self,function(self,params)
        self:featureResultCallFun(params)
    end,ViewEventType.NOTIFY_GET_SPINRESULT)
    
    --解决进入横版活动时再切换回关卡 弹板位置不对问题
    local _isPortrait = globalData.slotRunData.isPortrait
    local _isPortraitMachine = globalData.slotRunData:isMachinePortrait()
    if _isPortrait ~= _isPortraitMachine then
        gLobalNoticManager:addObserver(
            self,
            function(self)
                local csbNodeName = self.m_csbNode:getName()
                if csbNodeName == "Layer" then
                    self:changeVisibleSize(display.size)
                else
                    if not self.m_isUserDefPos then
                        -- 使用的屏幕大小换算的坐标
                        local posX, posY = self:getPosition()
                        self:setPosition(cc.p(posY, posX))
                    end
                end
            end,
            ViewEventType.NOTIFY_RESET_SCREEN
        )
    end

    FishManiaSelectShopView.super.onEnter(self)
end 

function FishManiaSelectShopView:initUI(data)
    self.m_machine = data[1]

    local resourceFilename = "FishMania/BonusChoose.csb"
    self:createCsbNode(resourceFilename)

    local p_shopData = globalMachineController.p_fishManiaShopData
    for _shopIndex=1,3 do
        local curSpend,allSpend = p_shopData:getShopSpend(_shopIndex)
        
        local lab_coins = self:findChild(string.format("m_lb_coins_%d", _shopIndex))
        if lab_coins then
            lab_coins:setString(util_formatCoins(allSpend, 3))
        end
    end
    self:playStartAnim()

    self:addClick(self:findChild(self.BTN_SELECT_1))
    self:addClick(self:findChild(self.BTN_SELECT_2))
    self:addClick(self:findChild(self.BTN_SELECT_3))
end

function FishManiaSelectShopView:playStartAnim()
    gLobalSoundManager:playSound("FishManiaSounds/FishMania_selectShop_start.mp3")
    self:runCsbAction("start", false, function()
        self:runCsbAction("idle", true)
    end)
end

function FishManiaSelectShopView:playOverAnim(_shopIndex)
    self.m_playOverAnim = true

    gLobalSoundManager:playSound("FishManiaSounds/FishMania_selectShop_choose.mp3")
    local actName = string.format("actionframe%d", _shopIndex)
    self:runCsbAction(actName, false, function()
        self:removeFromParent()
    end)
end

--设置界面按钮是否可点击
function FishManiaSelectShopView:setIsCanTouch(isCan)
    self.m_isCanTouch = isCan
end
--点击回调
function FishManiaSelectShopView:clickFunc(sender)
    if not self.m_isCanTouch or self.m_playOverAnim then
        return
    end

    local name = sender:getName()

    if name == FishManiaSelectShopView.BTN_SELECT_1 then
        self:onSelectBtnClick(1)
    elseif name == FishManiaSelectShopView.BTN_SELECT_2 then
        self:onSelectBtnClick(2)
    elseif name == FishManiaSelectShopView.BTN_SELECT_3 then
        self:onSelectBtnClick(3)
    end
end

function FishManiaSelectShopView:onSelectBtnClick(_selectIndex)
    self:setIsCanTouch(false)

    --发送数据包
    local httpSendMgr = SendDataManager:getInstance()
    local messageData = {
        msg = MessageDataType.MSG_BONUS_SPECIAL,
        data = {
            selectSuperFree = _selectIndex,
        }
    }
    httpSendMgr:getNetWorkSlots():requestFeatureData(messageData)
end

--接收返回消息
function FishManiaSelectShopView:featureResultCallFun(param)
    if not self:isVisible() then
        return
    end

    if  param[1] == true then
        local spinData = param[2]
        local selfData = spinData.result.selfData

        if selfData.shopIndex and selfData.selectSuperFree then
            local p_shopData = globalMachineController.p_fishManiaShopData
            --保存数据
            self.m_machine:operaSpinResultData(param)
            
            local data = {
                shopIndex = selfData.shopIndex,
                selectSuperFree = selfData.selectSuperFree,
            }
            p_shopData:parseShopData(data)
            self.m_machine:checkSwitchFishBox()

            self:playOverAnim(selfData.selectSuperFree)
        end
    else
        gLobalViewManager:showReConnect(true)
    end

    
end


return FishManiaSelectShopView

