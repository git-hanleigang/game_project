System.register(["__unresolved_0", "cc", "__unresolved_1"], function (_export, _context) {
  "use strict";

  var _reporterNs, _cclegacy, __checkObsolete__, __checkObsoleteInNamespace__, _decorator, Component, Singleton, _dec, _class, _crd, ccclass, property, reelRoll;

  function _reportPossibleCrUseOfSingleton(extras) {
    _reporterNs.report("Singleton", "./Singleton", _context.meta, extras);
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
    }, function (_unresolved_2) {
      Singleton = _unresolved_2.default;
    }],
    execute: function () {
      _crd = true;

      _cclegacy._RF.push({}, "858abUChTBNHaP6k9Bvm8dt", "reelRoll", undefined);

      __checkObsolete__(['_decorator', 'Component', 'Node']);

      ({
        ccclass,
        property
      } = _decorator);

      _export("reelRoll", reelRoll = (_dec = ccclass('reelRoll'), _dec(_class = class reelRoll extends Component {
        constructor() {
          super(...arguments);
          this.singleton = (_crd && Singleton === void 0 ? (_reportPossibleCrUseOfSingleton({
            error: Error()
          }), Singleton) : Singleton).getInstance();
          this.symbolList = [];
          this.currMoveLength = 0;
          this.reelRowNum = 0;
          this.colNum = null;
          // 行配置
          this.rollStates = false;
          this.quickStop = false;
          this.curColIndex = 0;
        }

        start() {
          this.colNum = this.singleton.reelColAndRow.length; // this.reelRowNum = rowNum
        }

        update(deltaTime) {}

        initReel() {// for
        }

        beginReel() {
          this.currMoveLength = 0;
          this.rollStates = true;
          this.quickStop = false;
        }

        stopReel() {
          this.rollStates = false;
        }

      }) || _class));

      _cclegacy._RF.pop();

      _crd = false;
    }
  };
});
//# sourceMappingURL=5434f7a4443512e9f275f6307bb7b11096880795.js.map