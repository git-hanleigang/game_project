import { _decorator, Component, EditBox, Node, UITransform, Sprite } from 'cc';
const { ccclass, property } = _decorator;
import Singleton from './Singleton';
import { symbolNode } from './symbolNode';

@ccclass('reelRoll')
export class reelRoll extends Component {
    public singleton: Singleton = Singleton.getInstance()
    public symbolList: Node[] = []
    public reelRowNum: number = null; // 真实创建行
    public currMoveLength: number = 0
    public colNum: number = null; // 行配置
    public rollStates: boolean = false
    public quickStop: boolean = false
    public rollSymbolTypes: number[] = []
    public rollPoint: number = 0; // 滚动指针
    public rollListLength: number = null; // 滚动指针
    public rowNum: number = null; // 行配置
    @property(Number)
    public curColIndex: number = 0
    public moveLength: any = 0;
    @property({ type: Number, tooltip:"小块高度"})
    public symbolHeight: any = 160;
    @property({ type: Number, tooltip:"reel条宽度度"})
    public reelWidth: any = 210;
    @property({ type: Number, tooltip:"总共移动的小块个数" })
    public moveIndex: any = 20;
    @property({ type: Number, tooltip:"移动速度 1 pix/update",min:1,max:4000  })
    public moveSpeed: number = 1000;  

    start() {
        // this.curColIndex = Number(this.node.name)
        this.colNum = this.singleton.reelColAndRow.length
        this.rowNum = this.singleton.reelColAndRow[this.curColIndex]
        this.rollSymbolTypes = this.singleton.rollList[this.curColIndex]
        this.rollListLength = this.rollSymbolTypes.length
        this.rollPoint = this.singleton.getRandomInt(0,(this.rollListLength-1))
        this.reelRowNum = this.rowNum+3
        
        this.moveLength = this.moveIndex * this.symbolHeight

        this.initReel()
    }

    public setReelIndex(curColIndex: number){
        this.curColIndex = curColIndex
    }

    moveDownSymol(){

        let symbolListLength = this.symbolList.length
        for (let index = 0; index < symbolListLength; index++) {
            let node = this.symbolList[index];
            if (node.active = true) {
                let pos = node.getPosition()
                let scrip = node.getComponent(symbolNode)
                if (pos.y <= scrip.removePosY) {
                    node.active = false // 移除就隐藏吧
                }
            }
        } 
    }

    update(deltaTime: number) {
        if (this.rollStates) {

            // 判断移除
            this.moveDownSymol()

            // 开始刷新小块位置
            let moveY = deltaTime * this.moveSpeed
            let symbolListLength = this.symbolList.length
            for (let index = 0; index < symbolListLength; index++) {
                let node = this.symbolList[index];
                if (node.active) {
                    let scrip = node.getComponent(symbolNode)
                    // 刷新位置
                    if (node.active) {
                        let pos = node.getPosition()
                        node.setPosition(pos.x,pos.y - moveY)
                    }  
                }
            }

            this.updateAllActiveSymbolRow()

            // 该隐藏的隐藏了现在需要补块了
            this.moveDownAddSymol()

            this.hideBigSymbolCoverImg()
            this.currMoveLength = this.currMoveLength + moveY // 更新总体移动距离
            if (Math.abs(this.currMoveLength)  >= this.moveLength || this.quickStop) {
                this.stopReel()
            }
        } 
    }

    hideBigSymbolCoverImg(){
        let bigSymbols = []
        let symbolListLength = this.symbolList.length
        for (let index = 0; index < symbolListLength; index++) {
            let node = this.symbolList[index];
            let isActive = node.active
            let scrip = node.getComponent(symbolNode)
            if (isActive == true) {
                let isbig = this.singleton.checkIsSameKey(this.singleton.bigSymbols,scrip.symbolType)
                if (isbig == true) {
                    bigSymbols[bigSymbols.length] = node
                }
            }
        }

        for (let index = 0; index < bigSymbols.length; index++) {
            const bigNode = bigSymbols[index];
            let scrip = bigNode.getComponent(symbolNode)
            let bigRow =  this.singleton.getBigRow(scrip.symbolType)
            for (let bigRowNum = 1; bigRowNum < bigRow; bigRowNum++) {
                let hideRow = scrip.iRow + bigRowNum
                let hideNode = this.getActiveSymbol(hideRow)
                if (hideNode != null ) {
                    let img = hideNode.getComponent(Sprite)
                    img.enabled = false
                } 
            }
        }
    }

    getActiveSymbol(row: number): any{
        let symbolListLength = this.symbolList.length
        for (let index = 0; index < symbolListLength; index++) {
            let node = this.symbolList[index];
            let isActive = node.active
            let scrip = node.getComponent(symbolNode)
            if (isActive ==  true && row == scrip.iRow) {
                return node
            }
        }
        return null
    }

    getActiveSymbolNum(): any{
        let num = 0
        let symbolListLength = this.symbolList.length
        for (let index = 0; index < symbolListLength; index++) {
            let node = this.symbolList[index];
            let isActive = node.active
            let scrip = node.getComponent(symbolNode)
            if (isActive ==  true ) {
                num = num + 1
            }
        }
        return num
    }

    moveDownAddSymol(){

        let num = this.getActiveSymbolNum()
        if (num >= this.reelRowNum) {
            return 
        }

        let addNum = this.reelRowNum - num
        for (let index = 0; index < addNum; index++) {
            
            let nearNode = this.getOneNearSymbol()
            if (nearNode == null) {
                // 当速度非常大的时候是有可能整列都被隐藏的
                let row = 0
                let addNode = this.getUnActiveSymbol()
                if (addNode != null) {
                    addNode.active = true
                    let symbolType = this.getSmbolType()
                    this.updateSymbolNodeinfo(addNode,row,symbolType)
                }else{
                    let symbolType = this.getSmbolType()
                    addNode = this.createSymbol(symbolType,row)
                    this.symbolList[this.symbolList.length] = addNode
                }
                addNode.setPosition(this.reelWidth/2,this.symbolHeight)
            } else {
                let scrip = nearNode.getComponent(symbolNode)
                let addNode = this.getUnActiveSymbol()
                if (addNode != null) {
                    addNode.active = true
                    let symbolType = this.getSmbolType()
                    this.updateSymbolNodeinfo(addNode,scrip.iRow,symbolType)
                }else{
                    let symbolType = this.getSmbolType()
                    addNode = this.createSymbol(symbolType,scrip.iRow)
                    this.symbolList[this.symbolList.length] = addNode
                }
                addNode.setPosition(this.reelWidth/2,nearNode.getPosition().y + this.symbolHeight)
            }
        }
    }

    createSymbol(symbolType: number,iRow: number): Node{

        let newNode = new Node();
        this.node.addChild(newNode);

        let uiTra = newNode.addComponent(UITransform)
        uiTra.anchorX = 0.5
        uiTra.anchorY = 0 
        let scrip = newNode.addComponent(symbolNode)
        scrip.init()
        this.updateSymbolNodeinfo(newNode,iRow,symbolType)
        return newNode
    }

    updateSymbolNodeinfo(node: Node,iRow: number,symbolType: number){
        node.setSiblingIndex(symbolType)  
        let scrip = node.getComponent(symbolNode)
        scrip.iRow  = iRow
        scrip.symbolType = symbolType
        let isbig = this.singleton.checkIsSameKey(this.singleton.bigSymbols,symbolType)
        if (isbig == true) {
            let bigRow =  this.singleton.getBigRow(symbolType)
            scrip.removePosY = - (bigRow -1) * this.symbolHeight
        }else{
            scrip.removePosY = - this.symbolHeight
        }
        scrip.changeSymbolNode(symbolType)
    }

    getOneNearSymbol(): any{

        let nearNode = null
        let symbolListLength = this.symbolList.length
        for (let index = 0; index < symbolListLength; index++) {
            let node = this.symbolList[index]
            if (node.active == true) {
                let posY = node.getPosition().y 
                if ( nearNode == null ){
                    nearNode = node
                } else {
                    if (posY > nearNode.getPosition().y  ) {
                        nearNode = node
                    }
                }

            } 
        }
        return nearNode
    }

    initReel(){
        for (let iRow = 0; iRow < this.reelRowNum; iRow++){
            let addNode = this.getUnActiveSymbol()
            let symbolType = this.getSmbolType()
            if (addNode != null){
                addNode.active = true
            }else{
                addNode = this.createSymbolNode(symbolType, iRow)
                this.symbolList[this.symbolList.length] = addNode
            }
            addNode.setPosition(this.reelWidth/2, iRow*this.symbolHeight)
        }
    }

    updateAllActiveSymbolRow( ){
        let symbolListLength = this.symbolList.length
        for (let index = 0; index < symbolListLength; index++) {
            let node = this.symbolList[index];
            let isActive = node.active
            if (isActive) {
                let scrip = node.getComponent(symbolNode)
                let posY = node.getPosition().y
                let rowIndex = this.reelRowNum
                while (true) {
                    let posYConfine = rowIndex * this.symbolHeight
                    if (posY <= posYConfine) {
                        scrip.iRow = rowIndex 
                    }else {
                        break
                    }
                    rowIndex = rowIndex -1
                }
            }
        }
    }

    public createSymbolNode(symbolType: number, iRow: number): Node {
        let newNode = new Node()
        this.node.addChild(newNode)

        let uiTra = newNode.addComponent(UITransform)
        uiTra.anchorX = 0.5
        uiTra.anchorY = 0 

        let script = newNode.addComponent(symbolNode)
        script.init()

        this.updateSymbolNodeInfo(newNode, iRow, symbolType)
        return newNode
    }

    updateSymbolNodeInfo(node: Node, iRow: number, symbolType: number) {
        node.setSiblingIndex(symbolType)
        let script = node.getComponent(symbolNode)
        script.iRow = iRow
        script.symbolType = symbolType

        script.removePosY = -this.symbolHeight
        script.changeSymbolNode(symbolType)
    }

    public getSmbolType(): number{
        let symbolType = this.rollSymbolTypes[this.rollPoint] 
        this.rollPoint = this.rollPoint + 1
        if (this.rollPoint >= this.rollListLength ) {
            this.rollPoint = 0
        }
        return symbolType
    }

    public getUnActiveSymbol(): any{
        let symbolListLength = this.symbolList.length
        for (let index = 0; index < symbolListLength; index++){
            let node = this.symbolList[index]
            if (node.active == false){
                return node
            }
        }
        return null
    }

    quickStopResetSymbol(){
        let symbolListLength = this.symbolList.length
        for (let index = 0; index < symbolListLength; index++){
            let node = this.symbolList[index]
            node.active = false
        }
        this.initReel()
    }

    normalResetSymbol(){
        let symbolListLength = this.symbolList.length
        for (let index = 0; index < symbolListLength; index++){
            let node = this.symbolList[index]
            if (node.active == true){
                let script = node.getComponent(symbolNode)
                node.setPosition(this.reelWidth/2, script.iRow*this.symbolHeight)
            }
        }
    }

    public beginReel(){
        this.currMoveLength = 0
        this.rollStates = true
        this.quickStop = false
    }

    public stopReel(){
        this.rollStates = false
        if (this.quickStop == true){
            this.quickStopResetSymbol()
        }else
        {
            this.normalResetSymbol()
        }
        this.singleton.machineScript.reelStopFunc(1)
    }
}

