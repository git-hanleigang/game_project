System.register(["cc"], function (_export, _context) {
  "use strict";

  var _cclegacy, Singleton, _crd;

  _export("default", void 0);

  return {
    setters: [function (_cc) {
      _cclegacy = _cc.cclegacy;
    }],
    execute: function () {
      _crd = true;

      _cclegacy._RF.push({}, "0352eXDmUpGLJ6ivnCso0mp", "Singleton", undefined);

      _export("default", Singleton = class Singleton {
        constructor() {
          this.machineScript = null;
          this.reelColAndRow = [3, // col_1 行数
          3, // col_2 行数
          3, // col_3 行数
          3, // col_4 行数
          3 // col_5 行数
          ];
        }

        static getInstance() {
          if (!this.instance) {
            this.instance = new Singleton();
          }

          return this.instance;
        }

        setMachineScript(script) {
          this.machineScript = script;
        }

      });

      Singleton.instance = void 0;

      _cclegacy._RF.pop();

      _crd = false;
    }
  };
});
//# sourceMappingURL=9e83f1d10c3c10e3dab7e270595dd8236c1cfcfe.js.map