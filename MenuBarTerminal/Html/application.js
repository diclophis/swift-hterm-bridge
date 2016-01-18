var terminalSingelton = null;
var outgoingBuffer = null;


var Rutty = function(argv, terminal) {
  this.terminalForm = terminal;
  this.socket = terminal.dataset.socket;
  this.consoleUid = terminal.dataset.console;
  
  this.argv_ = argv;

  this.io = null;

  this.sendingSweep = null;
  this.pendingString = [];

  this.sendingResize = null;
  this.pendingResize = [];

  this.connected = true;
};


Rutty.prototype.run = function() {
  this.io = this.argv_.io.push();

  this.io.onVTKeystroke = this.sendString_.bind(this);
  this.io.sendString = this.sendString_.bind(this);
};


Rutty.prototype.sendString_ = function(str) {
  if (!this.connected) {
    return;
  }

  outgoingBuffer = outgoingBuffer || ''
  outgoingBuffer = outgoingBuffer.concat(str);
};


var initTerminal = function(command, terminalElement) {
    var child = null;
    while(terminalElement.firstChild) {
      child = terminalElement.removeChild(terminalElement.firstChild);
    }

    var term = null;
    var ws = null;

    lib.init(function() {
      terminalSingelton = term = new hterm.Terminal();
      term.decorate(terminalElement);

      term.setWidth(85);
      term.setHeight(26);

      term.setCursorPosition(0, 0);
      term.setCursorVisible(true);
      term.prefs_.set('ctrl-c-copy', true);
      term.prefs_.set('use-default-window-copy', true);

      var aRutty = function(argv) {
        return new Rutty(argv, terminalElement);
      };

      term.runCommandClass(aRutty);
    });
};

window.addEventListener('load', function(documentLoadedEvent) {
  var terminal = document.getElementById("terminal");
  initTerminal("", terminal);
});

var terminalReady = function() {
  if (terminalSingelton) {
    return "ready";
  } else {
    return null;
  }
};

var appendStdout = function(inboundJson) {
  var msg = JSON.parse(inboundJson);
  if (msg.raw && msg.raw.length > 0) { // see: https://github.com/flori/json for discussion on `to_json_raw_object`
    terminalSingelton.io.writeUTF16(msg.raw);
  }
};

var fetchStdin = function() {
  var copy = outgoingBuffer.slice(0);
  outgoingBuffer = null;
  return copy;
};
