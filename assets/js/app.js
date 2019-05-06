// We need to import the CSS so that webpack will load it.
// The MiniCssExtractPlugin is used to separate it out into
// its own CSS file.
import css from "../css/app.css";

// webpack automatically bundles all modules in your
// entry points. Those entry points can be configured
// in "webpack.config.js".
//
// Import dependencies
//
import "phoenix_html";

// Import local files
//
// Local files can be imported directly using relative paths, for example:
// import socket from "./socket"

import LiveSocket from "phoenix_live_view";

let liveSocket = new LiveSocket("/live");
liveSocket.connect();

const target = document.querySelector("#log code");

if (target) {
  window.logObserver = new MutationObserver(function(mutationsList, observer) {
    // const lastMutation = mutationsList[mutationsList.length - 1];
    // const lastNode =
    //   lastMutation.addedNodes[lastMutation.addedNodes.length - 1];
    // lastNode.scrollIntoView({ behavior: "smooth", block: "end" });

    target.scrollTop = target.scrollHeight;
  });

  window.logObserver.observe(target, {
    attributes: false,
    childList: true,
    subtree: true
  });

  console.log("Observing");

  target.scrollTop = target.scrollHeight;
}

import * as monaco from "monaco-editor/esm/vs/editor/editor.api.js";
import "monaco-editor/esm/vs/editor/browser/controller/coreCommands.js";
// import "monaco-editor/esm/vs/editor/contrib/find/findController.js";

import { registerRulesForLanguage } from "monaco-ace-tokenizer";
import ElixirHighlightRules from "monaco-ace-tokenizer/lib/ace/definitions/elixir";

monaco.languages.register({
  id: "elixir"
});
registerRulesForLanguage("elixir", new ElixirHighlightRules());

monaco.editor.create(document.getElementById("code-editor"), {
  value: `@environment "elixir",
  version: "1.7"

step "Basic test" do
  format "test.ex"
  help
end

step "Advanced test" do
  command "echo 'yolo dyd'"
end`,
  language: "elixir"
});
