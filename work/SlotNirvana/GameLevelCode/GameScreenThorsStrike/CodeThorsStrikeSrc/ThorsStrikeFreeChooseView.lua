local BaseGame = util_require("base.BaseGame")
local ThorsStrikeChooseView = class("ThorsStrikeChooseView",BaseGame)
local GameNetDataManager = require "network.SendDataManager"
local Sounds  = require "CodeThorsStrikeSrc.ThorsSounds"

ThorsStrikeChooseView.m_freespinCurrtTimes = 0

local freecfg = {}
freecfg[3] = {15,10,5}
freecfg[4] = {30,20,10}
freecfg[5] = {45,30,15}
freecfg[6] = {60,40,20}

function ThorsStrikeChooseView:initUI(params)
  self.m_machine = params.machine
  self:createCsbNode("ThorsStrike/Choose.csb")
  self.m_spines = {}
  self.m_csbnodes = {}

  self.bgNode = GD.util_createAnimation('ThorsStrike/GameScreenThorsStrikeBg_1.csb'):hide()
  self:findChild('bg'):addChild(self.bgNode)

  local scw = display.width / 1370
  local sch = display.height / 768
  local sc = math.min(scw,sch)
  self:findChild('root'):setScale( sc < 0.8 and 0.8 or sc )

  for i=1,3 do
    local btn = self:findChild('choose_button'..i)
    btn:setTag(i)
    self:addClick(btn)
    local spine = GD.util_spineCreate('Socre_ThorsStrike_reel',false,true):hide()
    self:findChild('Free_'..(i-1)):addChild(spine)
    local numNode = GD.util_csbCreate("Node_num.csb"):hide()
    local h0Node = GD.util_csbCreate("Node_chuizi.csb"):hide()
    GD.util_spinePushBindNode(spine,'sztp',numNode)
    GD.util_spinePushBindNode(spine,'cztp',h0Node)
    h0Node:getChildByName('Image_1'):setVisible(i==1)
    h0Node:getChildByName('Image_2'):setVisible(i==2)
    h0Node:getChildByName('Image_3'):setVisible(i==3)
    spine.labelnum = numNode:getChildByName('label'):setString('0')
    self.m_spines[i] = spine
    self.m_csbnodes[i] = {numNode = numNode, h0Node = h0Node}
  end
end


function ThorsStrikeChooseView:onEnter()
end

function ThorsStrikeChooseView:onExit()
  gLobalNoticManager:removeAllObservers(self)
end

function ThorsStrikeChooseView:showChooseBG()
  self.bgNode:show()
  self.bgNode:runCsbAction("idle",true)
end


function ThorsStrikeChooseView:openViewAnimation(count)
  self:show()
  if(count > 6)then
    count = 6
  end
  local t = freecfg[count]
  for i = 1,3 do
    self.m_spines[i].labelnum:setString(t[i])
    local btn = self:findChild('choose_button'..i)
    btn:setTouchEnabled(true)
  end
  self:runCsbAction('idle',true)
  for i,sp in ipairs(self.m_spines) do
    sp:show()
    GD.util_spinePlay(sp,'actionframe_start',false)
    GD.util_spineEndCallFunc(sp, 'actionframe_start',function()
      GD.util_spinePlay(sp,'idle_blue',true)
    end)
  end
  performWithDelay(self,function()
    for i,v in ipairs(self.m_csbnodes) do
      v.numNode:show()
      v.h0Node:show()
    end
    self.m_currentMusicId = gLobalSoundManager:playBgMusic(Sounds.freeChooseMusic.sound)
  end,0.4)
end

function ThorsStrikeChooseView:closeViewAnimation()
  self.bgNode:hide()
  self:hide()
  for i,sp in ipairs(self.m_spines) do
    sp:hide()
  end
end

function ThorsStrikeChooseView:clickFunc(pSender)
  local name,index = pSender:getName(),pSender:getTag()

  local key = 'freeChoose_'..index
  gLobalSoundManager:playSound(Sounds[key].sound)

  if(name == 'choose_button1' or name == 'choose_button2' or name == 'choose_button3')then
    print('--------click-eventName',name,index)
    GD.util_spinePlay(self.m_spines[index],'actionframe_dj',false)
    GD.util_spineEndCallFunc(self.m_spines[index], 'actionframe_dj',function()
      GD.util_spinePlay(self.m_spines[index],'idle_golden',false)
        self:sendChooseOper(index - 1)
    end)
    for i=1,3 do
      local btn = self:findChild('choose_button'..i)
      btn:setTouchEnabled(false)
    end
    for i,sp in ipairs(self.m_spines) do
      if(i~=index)then
        GD.util_spinePlay(sp,'dark',false)
        GD.util_spineEndCallFunc(sp, 'dark',function()
          GD.util_spinePlay(sp,'dark_idle',true)
        end)
      end
    end
  end
end

function ThorsStrikeChooseView:sendChooseOper(select)
  local httpSendMgr = GameNetDataManager:getInstance()
  local gameName = self.m_machine:getNetWorkModuleName()

  local actionData = httpSendMgr:getNetWorkSlots():getSendActionData(ActionType.TeamMissionOption, gameName)
  local params = {}
  params.action = 2
  actionData.data.params = json.encode(params)
  -- httpSendMgr:getNetWorkSlots():sendMessageData(actionData)

  local message = {}
  message.msg = MessageDataType.MSG_BONUS_SELECT
  message.data = select
  --0-2个叠堆 1-3个叠堆 2-4个叠堆
  httpSendMgr:getNetWorkSlots():requestFeatureData(message, true)
  self.m_machine.m_bFreeChoose = true
  self.m_machine.m_nFreeChooseIdx = select
end

function ThorsStrikeChooseView:changeFreeEffect()
  local index = self.m_machine.m_nFreeChooseIdx+1
  performWithDelay(self,function()
    for i,sp in ipairs(self.m_spines) do
      if(i~=index)then
        GD.util_spinePlay(sp,'actionframe_over',false)
      end
    end
    GD.util_spinePlay(self.m_spines[index],'actionframe_over1',false)
    GD.util_spineEndCallFunc(self.m_spines[index], 'actionframe_over',function()
    end)
    gLobalSoundManager:playSound(Sounds.freeChooseChangeFree.sound)
    self:runCsbAction('over',false,function()
      self.bgNode:runCsbAction('actionframe',false,function()
        self.m_machine:enterFree()
        self:closeViewAnimation()
        gLobalSoundManager:stopAudio(self.m_currentMusicId)
      end)
      performWithDelay(self, function()
        self.m_machine:freeTransitionEffect()
      end, 0.8)
    end)
  end,0.5)
  performWithDelay(self,function()
    for i,v in ipairs(self.m_csbnodes) do
      v.numNode:hide()
      v.h0Node:hide()
    end
  end,0.8)
end



return ThorsStrikeChooseView