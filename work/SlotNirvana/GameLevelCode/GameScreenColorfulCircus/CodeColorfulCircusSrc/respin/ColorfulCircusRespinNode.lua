

local ColorfulCircusNode = class("ColorfulCircusNode",
                                    util_require("Levels.RespinNode"))
ColorfulCircusNode.m_animState = 1
local NODE_TAG = 10
local MOVE_SPEED = 2600     --滚动速度 像素/每秒
local RES_DIS = 20

ColorfulCircusNode.SYMBOL_FIX_ALL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 14--107
ColorfulCircusNode.SYMBOL_FIX_GRAND = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 13--106
ColorfulCircusNode.SYMBOL_FIX_MAJOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 12 -- 105
ColorfulCircusNode.SYMBOL_FIX_MINOR = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 11 --104
ColorfulCircusNode.SYMBOL_FIX_MINI = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 10 --103
ColorfulCircusNode.SYMBOL_FIX_SYMBOL = TAG_SYMBOL_TYPE.SYMBOL_INVALID_TYPE + 1  --94
ColorfulCircusNode.SYMBOL_BLANCK = 100  --空信号
--初始化子类可以重写
function ColorfulCircusNode:initUI(rsView)
    self.m_moveSpeed = MOVE_SPEED
    self.m_resDis = RES_DIS
    self.m_rsView = rsView
    self:initBaseData()
end
function ColorfulCircusNode:checkRemoveNextNode()
    return true
end

--裁切区域
function ColorfulCircusNode:initClipNode(clipNode,opacity)
    if not clipNode then
        local nodeHeight = self.m_slotReelHeight / self.m_machineRow
        local size = cc.size(self.m_slotNodeWidth,nodeHeight + 1)
        local pos = cc.p(-math.ceil( self.m_slotNodeWidth / 2 ),- nodeHeight / 2)
        self.m_clipNode = util_createOneClipNode(RESPIN_CLIPMODE.RECT,size,pos)
        self:addChild(self.m_clipNode)
        --设置裁切块属性
        local originalPos = cc.p(0,0)
        util_setClipNodeInfo(self.m_clipNode,RESPIN_CLIPTYPE.SINGLE,RESPIN_CLIPMODE.RECT,size,originalPos)
  else
        self.m_clipNode = clipNode
  end
  self:initClipOpacity(opacity)
end

function ColorfulCircusNode:setAnimaState(state)
    self.m_animState = state
end

--子类继承修改节点显示内容
function ColorfulCircusNode:changeNodeDisplay(node)

    local isShowNode = self:isFixSymbol(node.p_symbolType)
    if isShowNode then
        if node.p_symbolType == self.SYMBOL_BLANCK then
            node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER)
        else
            node:setLocalZOrder(SHOW_ZORDER.LIGHT_ORDER + 10)
        end
        
    else
        if node.p_symbolType ~= self.SYMBOL_BLANCK then
            self:hideNodeShow(node)
        end
        node:setLocalZOrder(SHOW_ZORDER.SHADE_ORDER)
    end
end

function ColorfulCircusNode:hideNodeShow(symbol_node)
    if(not symbol_node)then
        return
    end

    local blankType = self.SYMBOL_BLANCK
    local ccbName = self.m_machine:getSymbolCCBNameByType(self.m_machine, blankType)
    symbol_node:changeCCBByName(ccbName, blankType)
    symbol_node:changeSymbolImageByName( ccbName )
end

-- 是不是 respinBonus小块
function ColorfulCircusNode:isFixSymbol(symbolType)
    if symbolType == self.SYMBOL_FIX_SYMBOL or
        symbolType == self.SYMBOL_FIX_MINI or
        symbolType == self.SYMBOL_FIX_MINOR or
        symbolType == self.SYMBOL_FIX_MAJOR or
        symbolType == self.SYMBOL_FIX_ALL or
        symbolType == self.SYMBOL_FIX_GRAND or
        symbolType == self.SYMBOL_BLANCK then
        return true
    end
    return false
end

--裁切遮罩透明度
function ColorfulCircusNode:initClipOpacity(opacity)
    if self.m_colorNodeBg and not tolua.isnull(self.m_colorNodeBg) then
        self.m_colorNodeBg:removeFromParent()
        self.m_colorNodeBg = nil
    end
    if opacity and opacity>0 then

        self.m_colorNodeBg = util_createAnimation("Socre_ColorfulCircus_Blanck.csb")
        self.m_clipNode:addChild(self.m_colorNodeBg, SHOW_ZORDER.SHADE_LAYER_ORDER)
        self.m_colorNodeBg:setScale(1.02)
    end
end


return ColorfulCircusNode