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
