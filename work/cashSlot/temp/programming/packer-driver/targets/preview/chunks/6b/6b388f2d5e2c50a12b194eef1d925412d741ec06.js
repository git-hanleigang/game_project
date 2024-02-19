System.register(["__unresolved_0", "cc", "__unresolved_1", "__unresolved_2"], function (_export, _context) {
  "use strict";

  var _reporterNs, _cclegacy, __checkObsolete__, __checkObsoleteInNamespace__, _decorator, Component, Node, UITransform, Sprite, Singleton, symbolNode, _dec, _dec2, _dec3, _dec4, _dec5, _dec6, _class, _class2, _descriptor, _descriptor2, _descriptor3, _descriptor4, _descriptor5, _crd, ccclass, property, reelRoll;

  function _initializerDefineProperty(target, property, descriptor, context) { if (!descriptor) return; Object.defineProperty(target, property, { enumerable: descriptor.enumerable, configurable: descriptor.configurable, writable: descriptor.writable, value: descriptor.initializer ? descriptor.initializer.call(context) : void 0 }); }

  function _applyDecoratedDescriptor(target, property, decorators, descriptor, context) { var desc = {}; Object.keys(descriptor).forEach(function (key) { desc[key] = descriptor[key]; }); desc.enumerable = !!desc.enumerable; desc.configurable = !!desc.configurable; if ('value' in desc || desc.initializer) { desc.writable = true; } desc = decorators.slice().reverse().reduce(function (desc, decorator) { return decorator(target, property, desc) || desc; }, desc); if (context && desc.initializer !== void 0) { desc.value = desc.initializer ? desc.initializer.call(context) : void 0; desc.initializer = undefined; } if (desc.initializer === void 0) { Object.defineProperty(target, property, desc); desc = null; } return desc; }

  function _initializerWarningHelper(descriptor, context) { throw new Error('Decorating class property failed. Please ensure that ' + 'transform-class-properties is enabled and runs after the decorators transform.'); }

  function _reportPossibleCrUseOfSingleton(extras) {
    _reporterNs.report("Singleton", "./Singleton", _context.meta, extras);
  }

  function _reportPossibleCrUseOfsymbolNode(extras) {
    _reporterNs.report("symbolNode", "./symbolNode", _context.meta, extras);
  }

  return {
    setters: [function (_unresolved_) {
      _reporterNs = _unresolved_;
    }, function (_cc) {
      _cclegacy = _cc.cclegacy;
      __checkObsolete__ = _cc.__checkObsolete__;
      __checkObsoleteInNamespace__ = _cc.__checkObsoleteInNamespace__;
      _decorator = _cc._decorator;
      Component = _cc.Component;
      Node = _cc.Node;
      UITransform = _cc.UITransform;
      Sprite = _cc.Sprite;
    }, function (_unresolved_2) {
      Singleton = _unresolved_2.default;
    }, function (_unresolved_3) {
      symbolNode = _unresolved_3.symbolNode;
    }],
    execute: function () {
      _crd = true;

      _cclegacy._RF.push({}, "858abUChTBNHaP6k9Bvm8dt", "reelRoll", undefined);

      __checkObsolete__(['_decorator', 'Component', 'EditBox', 'Node', 'UITransform', 'Sprite']);

      ({
        ccclass,
        property
      } = _decorator);

      _export("reelRoll", reelRoll = (_dec = ccclass('reelRoll'), _dec2 = property(Number), _dec3 = property({
        type: Number,
        tooltip: "小块高度"
      }), _dec4 = property({
        type: Number,
        tooltip: "reel条宽度度"
      }), _dec5 = property({
        type: Number,
        tooltip: "总共移动的小块个数"
      }), _dec6 = property({
        type: Number,
        tooltip: "移动速度 1 pix/update",
        min: 1,
        max: 4000
      }), _dec(_class = (_class2 = class reelRoll extends Component {
        constructor() {
          super(...arguments);
          this.singleton = (_crd && Singleton === void 0 ? (_reportPossibleCrUseOfSingleton({
            error: Error()
          }), Singleton) : Singleton).getInstance();
          this.symbolList = [];
          this.reelRowNum = null;
          // 真实创建行
          this.currMoveLength = 0;
          this.colNum = null;
          // 行配置
          this.rollStates = false;
          this.quickStop = false;
          this.rollSymbolTypes = [];
          this.rollPoint = 0;
          // 滚动指针
          this.rollListLength = null;
          // 滚动指针
          this.rowNum = null;

          // 行配置
          _initializerDefineProperty(this, "curColIndex", _descriptor, this);

          this.moveLength = 0;

          _initializerDefineProperty(this, "symbolHeight", _descriptor2, this);

          _initializerDefineProperty(this, "reelWidth", _descriptor3, this);

          _initializerDefineProperty(this, "moveIndex", _descriptor4, this);

          _initializerDefineProperty(this, "moveSpeed", _descriptor5, this);
        }

        start() {
          this.curColIndex = Number(this.node.name);
          this.colNum = this.singleton.reelColAndRow.length;
          this.rowNum = this.singleton.reelColAndRow[this.curColIndex];
          this.rollSymbolTypes = this.singleton.rollList[this.curColIndex];
          this.rollListLength = this.rollSymbolTypes.length;
          this.rollPoint = this.singleton.getRandomInt(0, this.rollListLength - 1);
          this.reelRowNum = this.rowNum + 3;
          this.moveLength = this.moveIndex * this.symbolHeight;
          this.initReel();
        }

        moveDownSymol() {
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];

            if (node.active = true) {
              var pos = node.getPosition();
              var scrip = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
                error: Error()
              }), symbolNode) : symbolNode);

              if (pos.y <= scrip.removePosY) {
                node.active = false; // 移除就隐藏吧
              }
            }
          }
        }

        update(deltaTime) {
          if (this.rollStates) {
            // 判断移除
            this.moveDownSymol(); // 开始刷新小块位置

            var moveY = deltaTime * this.moveSpeed;
            var symbolListLength = this.symbolList.length;

            for (var index = 0; index < symbolListLength; index++) {
              var node = this.symbolList[index];

              if (node.active) {
                var scrip = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
                  error: Error()
                }), symbolNode) : symbolNode); // 刷新位置

                if (node.active) {
                  var pos = node.getPosition();
                  node.setPosition(pos.x, pos.y - moveY);
                }
              }
            }

            this.updateAllActiveSymbolRow(); // 该隐藏的隐藏了现在需要补块了

            this.moveDownAddSymol();
            this.hideBigSymbolCoverImg();
            this.currMoveLength = this.currMoveLength + moveY; // 更新总体移动距离

            if (Math.abs(this.currMoveLength) >= this.moveLength || this.quickStop) {
              this.stopReel();
            }
          }
        }

        hideBigSymbolCoverImg() {
          var bigSymbols = [];
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];
            var isActive = node.active;
            var scrip = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
              error: Error()
            }), symbolNode) : symbolNode);

            if (isActive == true) {
              var isbig = this.singleton.checkIsSameKey(this.singleton.bigSymbols, scrip.symbolType);

              if (isbig == true) {
                bigSymbols[bigSymbols.length] = node;
              }
            }
          }

          for (var _index = 0; _index < bigSymbols.length; _index++) {
            var bigNode = bigSymbols[_index];

            var _scrip = bigNode.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
              error: Error()
            }), symbolNode) : symbolNode);

            var bigRow = this.singleton.getBigRow(_scrip.symbolType);

            for (var bigRowNum = 1; bigRowNum < bigRow; bigRowNum++) {
              var hideRow = _scrip.iRow + bigRowNum;
              var hideNode = this.getActiveSymbol(hideRow);

              if (hideNode != null) {
                var img = hideNode.getComponent(Sprite);
                img.enabled = false;
              }
            }
          }
        }

        getActiveSymbol(row) {
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];
            var isActive = node.active;
            var scrip = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
              error: Error()
            }), symbolNode) : symbolNode);

            if (isActive == true && row == scrip.iRow) {
              return node;
            }
          }

          return null;
        }

        getActiveSymbolNum() {
          var num = 0;
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];
            var isActive = node.active;
            var scrip = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
              error: Error()
            }), symbolNode) : symbolNode);

            if (isActive == true) {
              num = num + 1;
            }
          }

          return num;
        }

        moveDownAddSymol() {
          var num = this.getActiveSymbolNum();

          if (num >= this.reelRowNum) {
            return;
          }

          var addNum = this.reelRowNum - num;

          for (var index = 0; index < addNum; index++) {
            var nearNode = this.getOneNearSymbol();

            if (nearNode == null) {
              // 当速度非常大的时候是有可能整列都被隐藏的
              var row = 0;
              var addNode = this.getUnActiveSymbol();

              if (addNode != null) {
                addNode.active = true;
                var symbolType = this.getSmbolType();
                this.updateSymbolNodeinfo(addNode, row, symbolType);
              } else {
                var _symbolType = this.getSmbolType();

                addNode = this.createSymbol(_symbolType, row);
                this.symbolList[this.symbolList.length] = addNode;
              }

              addNode.setPosition(this.reelWidth / 2, this.symbolHeight);
            } else {
              var scrip = nearNode.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
                error: Error()
              }), symbolNode) : symbolNode);

              var _addNode = this.getUnActiveSymbol();

              if (_addNode != null) {
                _addNode.active = true;

                var _symbolType2 = this.getSmbolType();

                this.updateSymbolNodeinfo(_addNode, scrip.iRow, _symbolType2);
              } else {
                var _symbolType3 = this.getSmbolType();

                _addNode = this.createSymbol(_symbolType3, scrip.iRow);
                this.symbolList[this.symbolList.length] = _addNode;
              }

              _addNode.setPosition(this.reelWidth / 2, nearNode.getPosition().y + this.symbolHeight);
            }
          }
        }

        createSymbol(symbolType, iRow) {
          var newNode = new Node();
          this.node.addChild(newNode);
          var uiTra = newNode.addComponent(UITransform);
          uiTra.anchorX = 0.5;
          uiTra.anchorY = 0;
          var scrip = newNode.addComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
            error: Error()
          }), symbolNode) : symbolNode);
          scrip.init();
          this.updateSymbolNodeinfo(newNode, iRow, symbolType);
          return newNode;
        }

        updateSymbolNodeinfo(node, iRow, symbolType) {
          node.setSiblingIndex(symbolType);
          var scrip = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
            error: Error()
          }), symbolNode) : symbolNode);
          scrip.iRow = iRow;
          scrip.symbolType = symbolType;
          var isbig = this.singleton.checkIsSameKey(this.singleton.bigSymbols, symbolType);

          if (isbig == true) {
            var bigRow = this.singleton.getBigRow(symbolType);
            scrip.removePosY = -(bigRow - 1) * this.symbolHeight;
          } else {
            scrip.removePosY = -this.symbolHeight;
          }

          scrip.changeSymbolNode(symbolType);
        }

        getOneNearSymbol() {
          var nearNode = null;
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];

            if (node.active == true) {
              var posY = node.getPosition().y;

              if (nearNode == null) {
                nearNode = node;
              } else {
                if (posY > nearNode.getPosition().y) {
                  nearNode = node;
                }
              }
            }
          }

          return nearNode;
        }

        initReel() {
          for (var iRow = 0; iRow < this.reelRowNum; iRow++) {
            var addNode = this.getUnActiveSymbol();
            var symbolType = this.getSmbolType();

            if (addNode != null) {
              addNode.active = true;
            } else {
              addNode = this.createSymbolNode(symbolType, iRow);
              this.symbolList[this.symbolList.length] = addNode;
            }

            addNode.setPosition(this.reelWidth / 2, iRow * this.symbolHeight);
          }
        }

        updateAllActiveSymbolRow() {
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];
            var isActive = node.active;

            if (isActive) {
              var scrip = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
                error: Error()
              }), symbolNode) : symbolNode);
              var posY = node.getPosition().y;
              var rowIndex = this.reelRowNum;

              while (true) {
                var posYConfine = rowIndex * this.symbolHeight;

                if (posY <= posYConfine) {
                  scrip.iRow = rowIndex;
                } else {
                  break;
                }

                rowIndex = rowIndex - 1;
              }
            }
          }
        }

        createSymbolNode(symbolType, iRow) {
          var newNode = new Node();
          this.node.addChild(newNode);
          var uiTra = newNode.addComponent(UITransform);
          uiTra.anchorX = 0.5;
          uiTra.anchorY = 0;
          var script = newNode.addComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
            error: Error()
          }), symbolNode) : symbolNode);
          script.init();
          this.updateSymbolNodeInfo(newNode, iRow, symbolType);
          return newNode;
        }

        updateSymbolNodeInfo(node, iRow, symbolType) {
          node.setSiblingIndex(symbolType);
          var script = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
            error: Error()
          }), symbolNode) : symbolNode);
          script.iRow = iRow;
          script.symbolType = symbolType;
          script.removePosY = -this.symbolHeight;
          script.changeSymbolNode(symbolType);
        }

        getSmbolType() {
          var symbolType = this.rollSymbolTypes[this.rollPoint];
          this.rollPoint = this.rollPoint + 1;

          if (this.rollPoint >= this.rollListLength) {
            this.rollPoint = 0;
          }

          return symbolType;
        }

        getUnActiveSymbol() {
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];

            if (node.active == false) {
              return node;
            }
          }

          return null;
        }

        quickStopResetSymbol() {
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];
            node.active = false;
          }

          this.initReel();
        }

        normalResetSymbol() {
          var symbolListLength = this.symbolList.length;

          for (var index = 0; index < symbolListLength; index++) {
            var node = this.symbolList[index];

            if (node.active == true) {
              var script = node.getComponent(_crd && symbolNode === void 0 ? (_reportPossibleCrUseOfsymbolNode({
                error: Error()
              }), symbolNode) : symbolNode);
              node.setPosition(this.reelWidth / 2, script.iRow * this.symbolHeight);
            }
          }
        }

        beginReel() {
          this.currMoveLength = 0;
          this.rollStates = true;
          this.quickStop = false;
        }

        stopReel() {
          this.rollStates = false;

          if (this.quickStop == true) {
            this.quickStopResetSymbol();
          } else {
            this.normalResetSymbol();
          }

          this.singleton.machineScript.reelStopFunc(1);
        }

      }, (_descriptor = _applyDecoratedDescriptor(_class2.prototype, "curColIndex", [_dec2], {
        configurable: true,
        enumerable: true,
        writable: true,
        initializer: function initializer() {
          return 0;
        }
      }), _descriptor2 = _applyDecoratedDescriptor(_class2.prototype, "symbolHeight", [_dec3], {
        configurable: true,
        enumerable: true,
        writable: true,
        initializer: function initializer() {
          return 160;
        }
      }), _descriptor3 = _applyDecoratedDescriptor(_class2.prototype, "reelWidth", [_dec4], {
        configurable: true,
        enumerable: true,
        writable: true,
        initializer: function initializer() {
          return 210;
        }
      }), _descriptor4 = _applyDecoratedDescriptor(_class2.prototype, "moveIndex", [_dec5], {
        configurable: true,
        enumerable: true,
        writable: true,
        initializer: function initializer() {
          return 20;
        }
      }), _descriptor5 = _applyDecoratedDescriptor(_class2.prototype, "moveSpeed", [_dec6], {
        configurable: true,
        enumerable: true,
        writable: true,
        initializer: function initializer() {
          return 1000;
        }
      })), _class2)) || _class));

      _cclegacy._RF.pop();

      _crd = false;
    }
  };
});
//# sourceMappingURL=6b388f2d5e2c50a12b194eef1d925412d741ec06.js.map